(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/markup)
(use ../src/graph-of-thought)
(use ../src/solution)

# --------------------------------------------

(let [subdir "./notes/"
      raw-db   (load-deep subdir)
      db       (finalize-db raw-db nil)
      id       :db/ra/join_
      article  ((db id) :content)
      res      (mu/to-html article)]
  (file/put "./play.html" res))
