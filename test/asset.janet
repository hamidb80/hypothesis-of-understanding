(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/markup)
(use ../src/graph-of-thought)
(use ../src/solution)

# --------------------------------------------

(let [subdir "./test/notes/asset-load"
      raw-db   (load-deep subdir)
      db       (finalize-db raw-db nil (load-assets "./test/assets/"))
      id       :root
      article  ((db id) :content)
      res      (mu/to-html article |(string "/dist/" $))]
  (file/put "./play.html" res))
