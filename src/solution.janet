"
integration of GoT and Notes
"

(use ./helper/io)
(use ./helper/path)
(use ./helper/tab)
(use ./helper/macros)
(use ./helper/iter)

(use ./markup)
(use ./graph-of-thought)

# ------------------------------------------------------

(defn load-deep (dir)
  "find all markup/GoT files in the `dir` and load them"

  (to-table 
    (filter 
      |(or 
        (string/has-suffix? markup-ext $)
        (string/has-suffix?    got-ext $))
      (os/list-files-rec dir))
    identity
    |(eval-string (slurp $))))
