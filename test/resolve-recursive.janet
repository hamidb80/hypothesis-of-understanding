(use ../src/helper/io)
(use ../src/helper/path)
(use ../src/helper/str)

(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(def  output-dir  "./dist/")
(def  notes-dir   "./test/notes/resolve-recursive")
(def app-config {:title "Theory Of Understanding"})
(def raw-db  (load-deep notes-dir))
(def     db  (finalize-db raw-db :root))
(defn router (n) (string "/dist/" n))
(print (mu/to-html ((db :root) :content) router))
