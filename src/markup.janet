(use ./helper/debug)
(use ./helper/types)
(use ./helper/functions)
(use ./helper/iter)
(use ./helper/str)
(use ./helper/tab)
(use ./helper/io)
(use ./helper/path)
(use ./helper/macros)

# Core elements ------------------------------------------------------

(defn h      (size & args) {:node :header            :body args :data size })
(defn h1     (& args)      (h 1 ;args))
(defn h2     (& args)      (h 2 ;args))
(defn h3     (& args)      (h 3 ;args))
(defn h4     (& args)      (h 4 ;args))
(defn h5     (& args)      (h 5 ;args))
(defn h6     (& args)      (h 6 ;args))

(defn sec    (& args)      {:node :section           :body args})
(defn cnt    (& args)      {:node :center            :body args})
(defn b      (& args)      {:node :bold              :body args})
(defn i      (& args)      {:node :italic            :body args})
(defn ul     (& args)      {:node :list              :body args})
(defn sm     (& args)      {:node :small             :body args})
(defn lg     (& args)      {:node :large             :body args})
(defn p      (& args)      {:node :paragraph         :body args})
(defn ul     (& body)      {:node :unnumbered-list   :body body})
(defn ol     (& body)      {:node :numbered-list     :body body})
(defn ltx    (& body)      {:node :latex             :body body })

(defn ref    (kw & body)   {:node :local-ref         :body body  :data kw})
(defn a      (url & body)  {:node :link              :body body  :data url})

(defn img    (src & body)  {:node :image             :body body  :data src})
(defn tags   (& kws)       {:node :tags              :body []    :data kws})
(defn abs    (body)        {:node :abstract          :body body  :data body})

(def _ " ")

# Resolvation -------------------------------------

(defn finalize-content (db content parent-article assets-db ref-count resolved?)
  (map 
    (fn [vv]
      (match (type/reduced vv)
        :keyword  (do 
                    (match (resolved? vv) 
                      :done       nil # do nothing
                      :processing (error (string `circular dependency detected, articles involved: ` vv `, `  (string/join (filter |(= :processing (resolved? $)) (keys resolved?)) ", ")))
                      nil   (do 
                              (put resolved? vv :processing)
                              (put-in db    [vv :content] (finalize-content db ((db vv) :content) (db vv) assets-db ref-count resolved?))
                              (put resolved? vv :done)))

                    (assert (not (nil? (db vv))) (string "the key :" vv " has failed to reference."))
                    (put+ ref-count vv)
                    ((db vv) :content))
      
        :struct   (do 
          (match (vv :node)
            :local-ref (do 
              (let [key (vv :data)
                    ref (db key)]
                (assert (not (nil? ref)) " reference does not exists")
                (assert (not (ref :partial)) (string "the linked doc cannot be partial :" key)))

              (put+ ref-count (vv :data)))

            :image (do
              (assert (in assets-db (vv :data)) (string `referenced asset does not exists: ` (vv :data)))
              (put+ assets-db (vv :data))
              vv)
            
            :tags     (put (parent-article :meta) :tags     (vv :data))
            :abstract (put (parent-article :meta) :abstract (vv :data))
              
            (finalize-content db (vv :body) parent-article assets-db ref-count resolved?))
          vv)

        :tuple    (finalize-content db vv parent-article assets-db ref-count resolved?)
        :string    vv))
    content))

(defn finalize-db (db index-key assets-db)
  (let [acc        @{}
        resolved?  @{}
        ref-count (zipcoll (keys db) (array/new-filled (length db) 0))]
    
    (eachp [id entity] db
      (put acc id 
        (put entity :content 
          (match (entity :kind)
                  :note (finalize-content db (entity :content) entity assets-db ref-count resolved?)
                  :got                       (entity :content)))))

    (if index-key (do 
      (put+ ref-count index-key)
      (pp ref-count)
      (let [zero-refs (map |($ 0) (filter (fn [[k c]] (= 0 c)) (pairs ref-count)))]
        (assert (empty? zero-refs) (string "there are notes that are not referenced at all: " (string/join zero-refs ", "))))))

    acc))

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
(def-  h/empty          (h/wrapper no-str                             no-str                 no-str           no-str))
(def-  h/wrap           (h/wrapper no-str                             no-str                 no-str           no-str))
(def-  h/paragraph      (h/wrapper (const1 `<p dir="auto">`)          (const1 `</p>`)        no-str           no-str))
(def-  h/italic         (h/wrapper (const1 `<i>`)                     (const1 `</i>`)        no-str           no-str))
(def-  h/bold           (h/wrapper (const1 `<b>`)                     (const1 `</b>`)        no-str           no-str))
(def-  h/underline      (h/wrapper (const1 `<u>`)                     (const1 `</u>`)        no-str           no-str))
(def-  h/strikethrough  (h/wrapper (const1 `<s>`)                     (const1 `</s>`)        no-str           no-str))
(def-  h/latex          (h/wrapper (const1 `<span class="latex">`)    (const1 `</span>`)     no-str           no-str))
(def-  h/header         (h/wrapper |(string `<h` $ ` dir="auto">`)    |(string `</h` $ `>`)  no-str           no-str))
(def-  h/link           (h/wrapper |(string `<a href="` $ `">`)       (const1 `</a>`)        no-str           no-str))
(def-  h/ul             (h/wrapper (const1 `<ul>`)                    (const1 `</ul>`)       (const1 `<li>`)  (const1 `</li>`)))
(def-  h/ol             (h/wrapper (const1 `<ol>`)                    (const1 `</ol>`)       (const1 `<li>`)  (const1 `</li>`)))
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

  :bold              h/bold
  :italic            h/italic
  :underline         h/underline
  :strikethrough     h/strikethrough

  :header            h/header
  :paragraph         h/paragraph

  :local-ref         h/local-ref
  :link              h/link

  :unnumbered-list   h/ul
  :numbered-list     h/ol

  :latex             h/latex

  :image             h/image
  # :video           h/video
  
  :tags              h/empty
  :abstract          h/empty
  })
# macro view --------
(defn  mu/to-html (content router)
  (defn resolver (router ctx node)
    (match (type/reduced node)
      :string         node
      :number (string node)
      :struct ((html-resolvers (node :node)) resolver router ctx (node :data) (node :body))
      :tuple  (string/join (map |(mu/to-html $ router) [node])) # for imports [ imported content placed as list ]
              (do 
                (pp node)
                (error (string "invalid kind: " (type node)))
                )))
  
  (resolver router 
    {:inline false} 
    {:node :wrap 
     :body content}))
