(use ../src/helper/io)
(use ../src/helper/path)
(use ../src/helper/str)

(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(def  output-dir  "./dist/")
(def  notes-dir   "./notes/")

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

(def raw-db (load-deep notes-dir))
# (pp raw-db)

(def  db (finalize-db raw-db nil))
# (pp db)

(defn reff (k)
  (assert (not (nil? (db k))) (string "the reference " k " is invalid"))
  (mu/to-html ((db k) :content)))

(eachp [id entity] db
  (let [path-parts (path/split (entity :path))]
    
    # (print ">>>>>>>>>>>>>>")
    # (pp path-parts)
    
    (match (entity :kind)
      :got (do 
        (def ggg (GoT/init (entity :content)))
        (def  svg-repr (GoT/to-svg  ggg got-style-config))
        (def html-repr (GoT/to-html ggg svg-repr reff))
        (def new-path (path/join output-dir (string (string/remove-prefix notes-dir (path-parts :dir)) (path-parts :name) ".html")))
        (pp new-path)
        (file/put new-path html-repr))
          
      :note (do 
        (def new-path (path/join output-dir (string (string/remove-prefix notes-dir (path-parts :dir)) (path-parts :name) ".html")))
        (pp new-path)
        (file/put new-path (mu/wrap-html (path-parts :name) (mu/to-html (entity :content))))))))
