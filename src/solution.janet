"""
integration of GoT and Notes
"""

(use ./helper/io)
(use ./helper/path)
(use ./helper/tab)
(use ./helper/macros)

(use ./lisp-docs)
(use ./graph-of-thought)

# ------------------------------------------------------

(defn os/list-files-rec-impl (root pred acc)
  (each relpath (os/diri root)
    (match (path/mode relpath)
          :directory (os/list-files-rec-impl relpath pred acc)
          :file      (if (pred relpath) (array/push acc relpath)))))

(defn os/list-files-rec (root pred)
  (let-acc @[] 
    (os/list-files-rec-impl root pred acc)))

(defn compile-deep (dir)
  "find all doc files in the `dir` and compile them"

  (to-table 
    (os/list-files-rec dir |(or 
      (string/has-suffix? markup-ext $)
      (string/has-suffix?    got-ext $)))
    identity
    |(eval-string (slurp $))))

# -----------------------------------------------
