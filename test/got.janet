(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/graph-of-thought)
(use ../src/lisp-docs)
(use ../src/solution)

# -------------------------------

(def  output-path "./play.html")
(def  subdir      "./notes")

(defn k2mu (k)  (string (path/join subdir k) markup-ext))
(defn k2go (k)  (string (path/join subdir k) got-ext))

(def  db       (finalize-db (compile-deep subdir) k2mu nil))
(defn reff (k) (mu/to-html (db (k2mu k))))

(def ggg (GoT/init (db (k2go :db/q1))))
(def got-style-config {
  :radius   16
  :spacex  100
  :spacey   80
  :padx    100
  :pady     50
  :stroke    4
  :node-pad  6
  :background nil
  :stroke-color          "#212121"
  :color-map {:problem   "#212121"
              :goal      "#212121"
              :recall    "#864AF9"
              :calculate "#E85C0D"
              :reason    "#5CB338" }})
(def svg-repr (GoT/to-svg ggg got-style-config))
(file/put output-path (GoT/to-html ggg svg-repr reff))
