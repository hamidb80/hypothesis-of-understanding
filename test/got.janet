(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(def  output-dir  "./dist")
(def  notes-dir   "./notes")

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

(defn k2mu (k)  (string (path/join notes-dir k) markup-ext))
(defn k2go (k)  (string (path/join notes-dir k) got-ext))

(def  db       (finalize-db (load-deep notes-dir) k2mu nil))
(defn reff (k) (mu/to-html (db (k2mu k))))


# TODO now do it for all of the files

(eachp [k v] db
  (cond 
    (string/has-suffix? got-ext k) (do 
        (def ggg (GoT/init v))

        (def  svg-repr (GoT/to-svg  ggg got-style-config))
        (def html-repr (GoT/to-html ggg svg-repr reff))
        (def new-path (path/join output-dir (string (path/file-name k) ".html")))

        # (pp new-path)
        (file/put new-path html-repr))
        
    (string/has-suffix? markup-ext k) (do 
      (def new-path (path/join output-dir (string (path/file-name k) ".html")))
      (pp new-path)
      (file/put new-path (mu/to-html v)))))
