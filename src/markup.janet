(use ./helper/debug)
(use ./helper/types)
(use ./helper/iter)
(use ./helper/str)
(use ./helper/tab)
(use ./helper/io)
(use ./helper/path)
(use ./helper/macros)

(use ./com)


# ------------------------------------------------------

(def markup-ext ".mu.janet") # markup language in Janet lisp format

# ------------------------------------------------------

# TODO keep a lookup table and to not resolve again what is resolved before, also solved deep resovaltion problem

(defn finalize-article (db resolvers article)
  (map 
    (fn [vv]
      (match (type/reduced vv)
        :keyword  (let [ref (db vv)]
                    (assert (not (nil? ref)) (string "the key :" vv " has failed to reference."))
                    (ref :content))
        
        :struct   (match (vv :node)
                    :local-ref (do 
                      (assert (not (nil? (db (vv :data)))) " reference does not exists")
                      vv)
                    vv)

        :tuple    (finalize-article db resolvers vv)
                     vv))
    (article :content)))


(defn finalize-db (db resolvers)
  (let-acc @{}
    (eachp [id entity] db
      (put acc id (assoc entity :content 
        (match (entity :kind)
          :note (finalize-article db resolvers entity)
          :got                                 (entity :content)))))))


# ------------------------------------------------------

(defn- simple-wrapper (start-fn end-fn)
  (fn [resolver ctx data args] 
    (let-acc @""
      (buffer/push acc (start-fn data))
      (each c args (buffer/push acc (resolver ctx c)))
      (buffer/push acc (end-fn data)))))

(defn- const1 (ret) 
  (fn [_] ret))

(def- r/wrap           (simple-wrapper (const1 "")               (const1 "")))
(def- r/paragraph      (simple-wrapper (const1 `<p dir="auto">`) (const1 `</p>`)))
(def- r/italic         (simple-wrapper (const1 `<i>`)            (const1 `</i>`)))
(def- r/bold           (simple-wrapper (const1 `<b>`)            (const1 `</b>`)))
(def- r/underline      (simple-wrapper (const1 `<u>`)            (const1 `</u>`)))
(def- r/strikethrough  (simple-wrapper (const1 `<s>`)            (const1 `</s>`)))
(def- r/latex          (simple-wrapper (const1 `<math>`)         (const1 `</math>`)))
(def- r/header         (simple-wrapper |(string "<h" $ ">")      |(string "</h" $ ">")))

(def base-addr "/dist/")

(defn- r/local-ref [resolver ctx data args] 
  (string 
    `<a up-follow href="` base-addr data `.html">` 
      (resolver ctx args)
    `</a>`))


(def- html-resolvers {
  :wrap            r/wrap
  
  :bold            r/bold
  :italic          r/italic
  :underline       r/underline
  :strikethrough   r/strikethrough
  
  :header          r/header
  :paragraph       r/paragraph
  
  :latex           r/latex
  :local-ref       r/local-ref
  # :image           r/image
  # :video           r/video
  })


(defn mu/to-html (content)
  (defn resolver (ctx node)
    # (pp node)
    (match (type/reduced node)
      :string         node
      :number (string node)
      :struct ((html-resolvers (node :node)) resolver ctx (node :data) (node :body))
      :tuple  (string/join (map mu/to-html [node])) # for imports [ imported content placed as list ]
              (do 
                (pp node)
                (error (string "invalid kind: " (type node)))
                )))
  
  (resolver 
    {:inline false} 
    {:node :wrap 
     :body content})
)
(defn mu/wrap-html (key str)
  (flat-string `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title> ` key ` </title>` 
        common-head 
    `</head>
    <body>

    <div class="container my-5">

      <nav aria-label="breadcrumb">
        <ol class="breadcrumb">`
          (let [p (dirname/split key)] 
            (map
              (fn [n i]
                (string
                  `<li class="breadcrumb-item ` (if (= i (dec (length p))) `active`) `">` 
                    n 
                  `</li>`))
              p (range (length p))))
        `</ol>
      </nav>


      <div class="card">
        <div class="card-body"> ` str ` </div>
      </div>
      
    </div>
    </body>
    </html>`))

(defn h      (size & args) {:node :header      :body args :data size })
(defn h1     (& args)      (h 1 ;args))
(defn h2     (& args)      (h 2 ;args))
(defn h3     (& args)      (h 3 ;args))
(defn h4     (& args)      (h 4 ;args))
(defn h5     (& args)      (h 5 ;args))
(defn h6     (& args)      (h 6 ;args))
(defn alias  (& args)      {:node :alias       :body args}) # assign name to document, ignored at HTML compilation
(defn tags   (& args)      {:node :tags        :body args}) # 
(defn sec    (& args)      {:node :section     :body args})
(defn abs    (& args)      {:node :abstract    :body args})
(defn cnt    (& args)      {:node :center      :body args})
(defn b      (& args)      {:node :bold        :body args})
(defn i      (& args)      {:node :italic      :body args})
(defn ul     (& args)      {:node :list        :body args})
(defn sm     (& args)      {:node :small       :body args})
(defn lg     (& args)      {:node :large       :body args})
(defn p      (& args)      {:node :paragraph   :body args})
(defn ref    (kw & body)   {:node :local-ref   :body body  :data kw})

(def _ " ")
