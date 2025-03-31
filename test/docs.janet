(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/markup)
(use ../src/graph-of-thought)
(use ../src/solution)

# --------------------------------------------

(def subdir "./notes/")
(def db (finalize-db (load-deep subdir) nil))
(def res (mu/to-html ((db :db/ra/join) :content)))
(file/put "./play.html" res)
