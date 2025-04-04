(use ../src/helper/io)
(use ../src/helper/path)
(use ../src/helper/str)

(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(def  output-dir  "./dist/")
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

(def raw-db (load-deep notes-dir))
# (pp raw-db)

(def  db (finalize-db raw-db :index))
# (pp db)

(defn router (n) 
  (string "/dist/" n))

# (defn reff (k)
#   (assert (not (nil? (db k))) (string "the reference " k " is invalid"))
#   (mu/to-html ((db k) :content) router))

(eachp [id entity] db
  (let [
    path-parts (path/split (entity :path))
    new-path   (path/join output-dir (string (string/remove-prefix notes-dir (path-parts :dir)) (path-parts :name) ".html"))]

    (if-not (entity :partial)
      (match (entity :kind)
        :got 
          (let [ggg       (GoT/init (entity :content))
                html-repr (GoT/to-html ggg (GoT/to-svg  ggg got-style-config) db router)]
            (file/put new-path html-repr))
            
        :note
          (file/put new-path (mu/wrap-html id (mu/to-html (entity :content) router) router))))))
