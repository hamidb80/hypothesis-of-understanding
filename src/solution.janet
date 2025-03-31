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

(defn load-deep (dir)
  "
  find all markup/GoT files in the `dir` and load them.

  id -> {:kind    one of [:note :got]
         :content data-structure
         :path    str }
  "

  (let-acc @{}
    (each p (os/list-files-rec dir)
      (let [pparts    (path/split p)
            kind (cond 
                  (string/has-suffix? markup-ext p) :note
                  (string/has-suffix?    got-ext p) :got
                  nil)]
        (if kind 
          (put acc 
            (keyword (string/remove-prefix dir (pparts :dir)) (pparts :name)) 
            {:path    p
             :kind    kind
             :content (eval-string (slurp p))}))))))
