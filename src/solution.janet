"
integration of GoT and Notes
"

(use ./helper/io)
(use ./helper/path)
(use ./helper/tab)
(use ./helper/str)
(use ./helper/macros)
(use ./helper/iter)

(use ./markup)
(use ./graph-of-thought)

# ------------------------------------------------------

(def partial-file-name-suffix "_")

(defn load-deep (root)
  "
  find all markup/GoT files in the `dir` and load them.
  "
  (let [acc @{}
        root-dir (path/dir root)]
    
    (each p (os/list-files-rec root-dir)
      (let [pparts    (path/split p)
            kind (cond 
                  (string/has-suffix? markup-ext p) :note
                  (string/has-suffix?    got-ext p) :got
                  nil)]
        (if kind 
          (put acc 
            (keyword (string/remove-prefix root-dir (pparts :dir)) (pparts :name)) 
            {:path    p
             :kind    kind
             :partial (string/has-suffix? partial-file-name-suffix (pparts :name))
             :content (eval-string (slurp p))}))))
    acc))
