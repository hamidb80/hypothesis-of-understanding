"""
integration of GoT and Notes
"""

(use ./helper/io)
(use ./helper/path)
(use ./helper/tab)
(use ./helper/macros)
(use ./helper/iter)

(use ./lisp-docs)
(use ./graph-of-thought)

# ------------------------------------------------------

(defn compile-deep (dir)
  "find all markup/got files in the `dir` and compile them"

  (to-table 
    (filter 
      |(or 
        (string/has-suffix? markup-ext $)
        (string/has-suffix?    got-ext $))
      (os/list-files-rec dir))
    identity
    |(eval-string (slurp $))))

# -----------------------------------------------
