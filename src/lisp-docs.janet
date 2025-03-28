(use ./helper/debug)
(use ./helper/io)
(use ./helper/path)

# ------------------------------------------------------

(defn init-article () @{})

(defn process-article (resolvers article)
  )

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
  (defn resolver (ctx obj)
    (match (type obj)
      :string         obj
      :number (string obj)
      :struct ((html-resolvers (obj :node)) resolver ctx (obj :data) (obj :body))
      # TODO for imports [ imported content placed as list ]
      # :tuple  
      # :array  
              (error (string "invalid kind: " (type obj)))))
  
  (resolver {:inline false} {
    :node :wrap 
    :body content})
)

(defn h    (size & args) {:node :header      :body args :data size })
(defn h1   (& args)      (h 1 ;args))
(defn h2   (& args)      (h 2 ;args))
(defn h3   (& args)      (h 3 ;args))
(defn h4   (& args)      (h 4 ;args))
(defn h5   (& args)      (h 5 ;args))
(defn h6   (& args)      (h 6 ;args))
(defn sec  (& args)      {:node :section     :body args})
(defn abs  (& args)      {:node :abstract    :body args})
(defn cnt  (& args)      {:node :center      :body args})
(defn b    (& args)      {:node :bold        :body args})
(defn i    (& args)      {:node :italic      :body args})
(defn ul   (& args)      {:node :list        :body args})
(defn sm   (& args)      {:node :small       :body args})
(defn lg   (& args)      {:node :large       :body args})
(defn p    (& args)      {:node :paragraph   :body args})

(def _ " ")

# ------------------------------------------------------

(defn compile-deep-impl (root lookup)
  (each p (os/diri root)
    (match (path/mode p)
          :directory (compile-deep-impl p lookup)
          :file      (if (string/has-suffix? ".janet" p)
                          (put lookup p (eval-string (slurp p)))))))

(defn compile-deep (dir)
  "find all doc files in the `dir` and compile them"
  
  (let [acc @{}]
    (compile-deep-impl dir acc)
    acc))

# -----------------------------------------------

(pp (compile-deep "./notes"))
