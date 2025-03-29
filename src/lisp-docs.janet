(use ./helper/debug)
(use ./helper/types)
(use ./helper/iter)
(use ./helper/io)
(use ./helper/path)


# ------------------------------------------------------

(def format-extension ".jml") # janet markup language

# ------------------------------------------------------

(defn finalize-article (db key-to-path resolvers article)
  (map 
    (fn [node]
      (match (type/simple node)
        :keyword  (db (key-to-path node))
        :tuple    (finalize-article db key-to-path resolvers node)
                     node))
    article))

(defn finalize-db (db key-to-path resolvers)
  # TODO keep a lookup table and to not resolve again what is resolved before
  (let [acc @{}]
    (eachp [k v] db
      (put acc k (finalize-article db key-to-path resolvers v)))
    acc))


# ------------------------------------------------------

(defn simple-wrapper (start-fn end-fn)
  (fn [resolver ctx data args] 
    (let [acc @""]
        (buffer/push acc (start-fn data))
        (each c args (buffer/push acc (resolver ctx c)))
        (buffer/push acc (end-fn data))
      acc)))

(defn const1 (ret) 
  (fn [_] ret))

(def r/wrap           (simple-wrapper (const1 "")               (const1 "")))
(def r/paragraph      (simple-wrapper (const1 `<p dir="auto">`) (const1 `</p>`)))
(def r/italic         (simple-wrapper (const1 `<i>`)            (const1 `</i>`)))
(def r/bold           (simple-wrapper (const1 `<b>`)            (const1 `</b>`)))
(def r/underline      (simple-wrapper (const1 `<u>`)            (const1 `</u>`)))
(def r/strikethrough  (simple-wrapper (const1 `<s>`)            (const1 `</s>`)))
(def r/latex          (simple-wrapper (const1 `<math>`)         (const1 `</math>`)))
(def r/header         (simple-wrapper (fn [d] (string "<h" d ">")) 
                                      (fn [d] (string "</h" d ">"))))

(def html-resolvers {
  :wrap            r/wrap
  
  :bold            r/bold
  :italic          r/italic
  :underline       r/underline
  :strikethrough   r/strikethrough
  
  :header          r/header
  :paragraph       r/paragraph
  
  :latex           r/latex
  # :image           r/image
  # :video           r/video
  })

(defn to-html (content)
  (defn resolver (ctx node)
    (match (type/simple node)
      :string         node
      :number      (string node)
      :struct ((html-resolvers (node :node)) resolver ctx (node :data) (node :body))
      :tuple  (join-map [node] to-html) # for imports [ imported content placed as list ]
              (do 
                (pp node)
                (error (string "invalid kind: " (type node)))
                )))
  
  (resolver 
    {:inline false} 
    {:node :wrap 
     :body content})
)

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

(def _ " ")

# ------------------------------------------------------

(defn compile-deep-impl (root lookup)
  (each p (os/diri root)
    (match (path/mode p)
          :directory (compile-deep-impl p lookup)
          :file      (if (string/has-suffix? format-extension p)
                          (put lookup p (eval-string (slurp p)))))))

(defn compile-deep (dir)
  "find all doc files in the `dir` and compile them"
  
  (let [acc @{}]
    (compile-deep-impl dir acc)
    acc))

# -----------------------------------------------

(def subdir "./notes")

(defn k2p (k) 
  (string (path/join subdir k) format-extension))

(def db (finalize-db (compile-deep subdir) k2p nil))

(pp db)
(def res (to-html (db (k2p :db/join))))
(file/put "./play.html" res)
