"""
integration of GoT and Notes
"""

(use ./helper/io)
(use ./helper/path)
(use ./helper/macros)

(use ./lisp-docs)
(use ./graph-of-thought)

# ------------------------------------------------------

(defn- compile-deep-impl (root lookup)
  (each p (os/diri root)
    (match (path/mode p)
          :directory (compile-deep-impl p lookup)
          :file      (cond 
                      (string/has-suffix? markup-ext p) (put lookup p (eval-string (slurp p)))
                      # (string/has-suffix?    got-ext p) nil 
                      ))))

(defn compile-deep (dir)
  "find all doc files in the `dir` and compile them"
  
  (let-acc @{} 
    (compile-deep-impl dir acc)))

# -----------------------------------------------
