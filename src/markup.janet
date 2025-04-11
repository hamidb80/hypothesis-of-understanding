(use 
  ./helper/debug
  ./helper/types
  ./helper/functions
  ./helper/iter
  ./helper/str
  ./helper/tab
  ./helper/io
  ./helper/path
  ./helper/macros)

# Core elements ------------------------------------------------------

(defn h      (size & args) @{:node :header            :body args :data size })
(defn h1     (& args)      (h 1 ;args))
(defn h2     (& args)      (h 2 ;args))
(defn h3     (& args)      (h 3 ;args))
(defn h4     (& args)      (h 4 ;args))
(defn h5     (& args)      (h 5 ;args))
(defn h6     (& args)      (h 6 ;args))
(defn hr     ()            @{:node :horizontal_line    :body []    :data nil})

(defn sec    (& args)      @{:node :section           :body args :data nil})
(defn c      (& args)      @{:node :center            :body args :data nil})
(defn b      (& args)      @{:node :bold              :body args :data nil})
(defn u      (& args)      @{:node :underline         :body args :data nil})
(defn i      (& args)      @{:node :italic            :body args :data nil})
(defn ul     (& args)      @{:node :list              :body args :data nil})
(defn sm     (& args)      @{:node :small             :body args :data nil})
(defn lg     (& args)      @{:node :large             :body args :data nil})
(defn sp     (& args)      @{:node :span              :body args :data nil})
(defn p      (& args)      @{:node :paragraph         :body args :data nil})
(defn ul     (& body)      @{:node :unnumbered-list   :body body :data nil})
(defn ol     (& body)      @{:node :numbered-list     :body body :data nil})
(defn ltx    (& body)      @{:node :latex             :body body :data true })
(defn ltxi   (& body)      @{:node :latex             :body body :data false })

(defn tab    (style & body) @{:node :table            :body body :data style })
(defn th     (& body)       @{:node :table-head       :body body :data nil })
(defn tr     (& body)       @{:node :table-row        :body body :data nil })

(defn ref    (kw & body)   @{:node :local-ref         :body body  :data kw})
(defn a      (url & body)  @{:node :link              :body body  :data url})

(defn img    (src & body)  @{:node :image             :body body  :data src})

(defn tags   (& kws)       @{:node :tags              :body []    :data kws})
(defn abs    (body)        @{:node :abstract          :body body  :data body})
(defn title  (body)        @{:node :title             :body []    :data body})

(def _ " ")

# Resolvation -------------------------------------

(defn mu/finalize-content (db content parent-article assets-db ref-count resolved?)
  (map 
    (fn [vv]
      (match (type/reduced vv)
        :keyword  (do 
                    (match (resolved? vv) 
                      :done       nil # do nothing
                      :processing (error (string `circular dependency detected, articles involved: ` vv `, `  (string/join (filter |(= :processing (resolved? $)) (keys resolved?)) ", ")))
                      nil   (let [r (db vv)]
                              (assert r (string `key ` vv ` not found`))
                              (put resolved? vv :processing)
                              (put-in db    [vv :content] (mu/finalize-content db ((db vv) :content) (db vv) assets-db ref-count resolved?))
                              (put resolved? vv :done)))

                    (assert (not (nil? (db vv))) (string "the key :" vv " has failed to reference."))
                    (put+ ref-count vv)
                    ((db vv) :content))
      
        :struct   (do 
          (match (vv :node)
            :local-ref (do 
              (let [key (vv :data)
                    ref (db key)]
                (assert (not (nil? ref)) (string `reference ` key ` does not exist`))
                (assert (not (ref :private)) (string "the linked doc cannot be partial :" key)))

              (put+ ref-count (vv :data)))

            :image (do
              (assert (in assets-db (vv :data)) (string `referenced asset does not exists: ` (vv :data)))
              (put+ assets-db (vv :data))
              vv)

            :title    (put (parent-article :meta) :title    (vv :data))
            :tags     (put (parent-article :meta) :tags     (vv :data))
            :abstract (put (parent-article :meta) :abstract (vv :data)))
              
            (put vv :body (mu/finalize-content db (vv :body) parent-article assets-db ref-count resolved?)))


        :tuple    (mu/finalize-content db vv parent-article assets-db ref-count resolved?)
        :string    vv
        :number    vv
                   (error (string "kind " (type/reduced vv) " is not defined"))))
    content))

(defn load-assets (assets-dir)
  (const-table 
    (map |(string/remove-prefix assets-dir $) (os/list-files-rec assets-dir)) -1))
# HTML ------------------------------------------------------
(def no-str (const1 ""))
(defn- h/wrapper (start-wrap-fn end-wrap-fn start-item-fn end-item-fn)
  (fn [resolver router ctx data args] 
    (let-acc @""
      (buffer/push acc (start-wrap-fn data))
      (each c args (buffer/push acc (start-item-fn data) (resolver router ctx c) (end-item-fn data)))
      (buffer/push acc (end-wrap-fn data)))))

# micro view --------
(def-  h/wrap           (h/wrapper no-str                                                              no-str                 no-str           no-str))
(def-  h/empty          (h/wrapper no-str                                                              no-str                 no-str           no-str))
(def-  h/paragraph      (h/wrapper (const1 `<p dir="auto">`)                                           (const1 `</p>`)        no-str           no-str))
(def-  h/span           (h/wrapper (const1 `<span>`)                                                   (const1 `</span>`)     no-str           no-str))
(def-  h/italic         (h/wrapper (const1 `<i>`)                                                      (const1 `</i>`)        no-str           no-str))
(def-  h/bold           (h/wrapper (const1 `<b>`)                                                      (const1 `</b>`)        no-str           no-str))
(def-  h/underline      (h/wrapper (const1 `<u>`)                                                      (const1 `</u>`)        no-str           no-str))
(def-  h/strikethrough  (h/wrapper (const1 `<s>`)                                                      (const1 `</s>`)        no-str           no-str))
(def-  h/latex          (h/wrapper |(string `<span class="latex" dir="ltr" data-display="`$`">`)       (const1 `</span>`)     no-str           no-str))
(def-  h/header         (h/wrapper |(string `<h` $ ` dir="auto">`)                                     |(string `</h` $ `>`)  no-str           no-str))
(def-  h/link           (h/wrapper |(string `<a href="` $ `">`)                                        (const1 `</a>`)        no-str           no-str))
(def-  h/table          (h/wrapper (const1 `<table class="table"><tbody>`)                             (const1 `</tbody></table>`)    no-str           no-str))
(def-  h/table-head     (h/wrapper (const1 `<tr>`)                                                     (const1 `</tr>`)       (const1 `<th>`)  (const1 `</th>`)))
(def-  h/table-row      (h/wrapper (const1 `<tr>`)                                                     (const1 `</tr>`)       (const1 `<td>`)  (const1 `</td>`)))
(def-  h/ul             (h/wrapper (const1 `<ul dir="auto">`)                                          (const1 `</ul>`)       (const1 `<li>`)  (const1 `</li>`)))
(def-  h/ol             (h/wrapper (const1 `<ol dir="auto">`)                                          (const1 `</ol>`)       (const1 `<li class="mb-2">`)  (const1 `</li>`)))
(def-  h/hr             (h/wrapper (const1 `<hr/>`)                                                     no-str no-str no-str ))
(def-  h/center         (h/wrapper (const1 `<center>`)                                                 (const1 `</center>`) no-str no-str ))

(defn- h/local-ref [resolver router ctx data args] 
  (string
    `<a up-follow href="` (router data) `.html">` 
      (resolver router ctx args)
    `</a>`))

(defn- h/image [resolver router ctx data args] 
  (string
    `<img src="` (router (string "assets/" data)) `.html">` 
      (resolver router ctx args)
    `</a>`))

(def-  html-resolvers {
  :wrap              h/wrap

  :paragraph         h/paragraph
  :span              h/span
  :header            h/header

  :bold              h/bold
  :italic            h/italic
  :underline         h/underline
  :strikethrough     h/strikethrough

  :local-ref         h/local-ref
  :link              h/link

  :unnumbered-list   h/ul
  :numbered-list     h/ol

  :latex             h/latex

  :image             h/image
  # :video           h/video
  
  :title             h/empty
  :tags              h/empty
  :abstract          h/empty

  :center            h/center
  
  :horizontal_line   h/hr

  :table             h/table
  :table-row         h/table-row
  :table-head        h/table-head
  })
# macro view --------
(defn  mu/to-html (content router)
  (defn resolver (router ctx node)
    (match (type/reduced node)
      :string         node
      :number (string node)
      :struct ((assert (html-resolvers (node :node)) "corresponding element is not defined") resolver router ctx (node :data) (node :body))
      :tuple  (string/join (map |(mu/to-html $ router) [node])) # for imports [ imported content placed as list ]
              (do 
                (pp node)
                (error (string "invalid kind: " (type node)))
                )))
  
  (resolver router 
    {:inline false} 
    @{:node :wrap 
     :body content}))
