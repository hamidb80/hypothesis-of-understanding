(use ../src/helper/io)
(use ../src/helper/path)
(use ../src/helper/str)

(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(def  output-dir  "./dist/")
(def  notes-dir   "./notes")

(def       app-config {:title "Theory Of Understanding"})
(def got-style-config {
  :radius   16
  :spacex  100
  :spacey   80
  :padx    100
  :pady     50
  :stroke    4
  :node-pad  6
  :background nil
  :stroke-color             "#424242"
  :color-map {:problem      "#545454"
              :goal         "#545454"
              :recall       "#864AF9"
              :calculate    "#E85C0D"
              :reason       "#5CB338" }})

(def raw-db  (load-deep notes-dir))
(def     db  (finalize-db raw-db :index))
(defn router (n) (string "/dist/" n))

# main ----------------------------------
(eachp [id entity] db
  (let [
    path-parts (path/split (entity :path))
    new-path   (path/join output-dir (string (string/remove-prefix notes-dir (path-parts :dir)) (path-parts :name) ".html"))]

    (if-not (entity :partial)
      (match (entity :kind)
        :got 
          (let [ggg       (GoT/init (entity :content))
                svg-repr  (GoT/to-svg ggg got-style-config)
                html-repr (GoT/to-html ggg svg-repr got-style-config db router app-config)]
            (file/put new-path html-repr))
            
        :note
          (let [content (mu/to-html (entity :content) router)]
            (file/put new-path (mu/wrap-html id content router app-config)))))))
