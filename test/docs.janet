(use ../src/helper/io)
(use ../src/helper/path)
(use ../src/lisp-docs)

# --------------------------------------------

(def subdir "./notes")

(defn k2p (k) 
  (string (path/join subdir k) format-extension))

(def db (finalize-db (compile-deep subdir) k2p nil))

(pp db)
(def res (jml/to-html (db (k2p :db/join))))
(file/put "./play.html" res)
