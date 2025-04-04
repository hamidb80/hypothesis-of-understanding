(use ./helper/debug)
(use ./helper/types)
(use ./helper/functions)
(use ./helper/iter)
(use ./helper/str)
(use ./helper/tab)
(use ./helper/io)
(use ./helper/path)
(use ./helper/macros)

(use ./com)


# def ------------------------------------------------------

(def markup-ext ".mu.janet") # markup language in Janet lisp format

# Core elements ------------------------------------------------------

(defn h      (size & args) {:node :header            :body args :data size })
(defn h1     (& args)      (h 1 ;args))
(defn h2     (& args)      (h 2 ;args))
(defn h3     (& args)      (h 3 ;args))
(defn h4     (& args)      (h 4 ;args))
(defn h5     (& args)      (h 5 ;args))
(defn h6     (& args)      (h 6 ;args))

(defn alias  (& args)      {:node :alias             :body args}) # assign name to document, ignored at HTML compilation
(defn tags   (& args)      {:node :tags              :body args}) # 
(defn sec    (& args)      {:node :section           :body args})
(defn abs    (& args)      {:node :abstract          :body args})
(defn cnt    (& args)      {:node :center            :body args})
(defn b      (& args)      {:node :bold              :body args})
(defn i      (& args)      {:node :italic            :body args})
(defn ul     (& args)      {:node :list              :body args})
(defn sm     (& args)      {:node :small             :body args})
(defn lg     (& args)      {:node :large             :body args})
(defn p      (& args)      {:node :paragraph         :body args})
(defn ul     (& body)      {:node :unnumbered-list   :body body})
(defn ol     (& body)      {:node :numbered-list     :body body})

(defn ref    (kw & body)   {:node :local-ref         :body body  :data kw})
(defn a      (url & body)  {:node :link              :body body  :data url})

(def _ " ")

# Resolvation -------------------------------------

(defn finalize-content (db content ref-count)
  (map 
    (fn [vv]
      (match (type/reduced vv)
        :keyword  (let [ref (db vv)]
                    (assert (not (nil? ref)) (string "the key :" vv " has failed to reference."))
                    (put+ ref-count vv)
                    (ref :content))
        
        :struct   (do 
          (match (vv :node)
            :local-ref (do 
              (let [key (vv :data)
                    ref (db key)]
                (assert (not (nil? ref)) " reference does not exists")
                (assert (not (ref :partial)) (string "the linked doc cannot be partial :" key)))

              (put+ ref-count (vv :data)))

            (finalize-content db (vv :body) ref-count))
          vv)

        :tuple    (finalize-content db vv ref-count)
        :string    vv))
    content))


(defn finalize-db (db index-key)
  (let [acc @{} 
        ref-count (zipcoll (keys db) (array/new-filled (length db) 0))]
    
    (eachp [id entity] db
      (put acc id (put entity :content 
        (match (entity :kind)
          :note (finalize-content db (entity :content) ref-count)
          :got                                 (entity  :content)))))

    (if index-key (do 
      (put+ ref-count index-key)
      (pp ref-count)
      (let [zero-refs (map |($ 0) (filter (fn [[k c]] (= 0 c)) (pairs ref-count)))]
        (assert (empty? zero-refs) (string "there are notes that are not referenced at all: " (string/join zero-refs ", "))))))

    acc))


# HTML ------------------------------------------------------

(defn- h/wrapper (start-wrap-fn end-wrap-fn start-item-fn end-item-fn)
  (fn [resolver router ctx data args] 
    (let-acc @""
      (buffer/push acc (start-wrap-fn data))
      (each c args (buffer/push acc (start-item-fn data) (resolver router ctx c) (end-item-fn data)))
      (buffer/push acc (end-wrap-fn data)))))


(def no-str (const1 ""))

(def- h/wrap           (h/wrapper no-str                             no-str                 no-str           no-str))
(def- h/paragraph      (h/wrapper (const1 `<p dir="auto">`)          (const1 `</p>`)        no-str           no-str))
(def- h/italic         (h/wrapper (const1 `<i>`)                     (const1 `</i>`)        no-str           no-str))
(def- h/bold           (h/wrapper (const1 `<b>`)                     (const1 `</b>`)        no-str           no-str))
(def- h/underline      (h/wrapper (const1 `<u>`)                     (const1 `</u>`)        no-str           no-str))
(def- h/strikethrough  (h/wrapper (const1 `<s>`)                     (const1 `</s>`)        no-str           no-str))
(def- h/latex          (h/wrapper (const1 `<math>`)                  (const1 `</math>`)     no-str           no-str))
(def- h/header         (h/wrapper |(string `<h` $ ` dir="auto">`)    |(string `</h` $ `>`)  no-str           no-str))
(def- h/link           (h/wrapper |(string `<a href="` $ `">`)       (const1 `</a>`)        no-str           no-str))
(def- h/ul             (h/wrapper (const1 `<ul>`)                    (const1 `</ul>`)       (const1 `<li>`)  (const1 `</li>`)))
(def- h/ol             (h/wrapper (const1 `<ol>`)                    (const1 `</ol>`)       (const1 `<li>`)  (const1 `</li>`)))
(defn- h/local-ref [resolver router ctx data args] 
  (string
    `<a up-follow href="` (router data) `.html">` 
      (resolver router ctx args)
    `</a>`))

(def- html-resolvers {
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

  # :latex             h/latex

  # :image           h/image
  # :video           h/video
  })


(defn mu/to-html (content router)
  (defn resolver (router ctx node)
    # (pp node)
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

(defn mu/wrap-html (key str router)
  (flat-string `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title>` key `</title>` 
        common-head 
    `</head>
    <body>

    ` (nav-bar (router "")) `
    
    <div class="container my-4">

      <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
          <li class="breadcrumb-item"></li>`

          (let [p (dirname/split key)] 
            (map
              (fn [n i]
                (let [is-last (= i (dec (length p)))]
                  (string
                    `<li class="breadcrumb-item ` (if is-last `active`) `">` 
                      n
                    `</li>`)))
              p 
              (range (length p))))
        `</ol>
      </nav>


      <div class="card">
        <div class="card-body"> ` str ` </div>
      </div>
      
    </div>
    </body>
    </html>`))
