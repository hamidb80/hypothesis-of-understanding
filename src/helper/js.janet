# JavaScript utilities

(use ./types)
(use ./iter)
(use ./str)

(defn to-js 
  "Converts a Lisp data-structure into its corresponding JS data-structure"
  (data)

  (match (type/reduced data)
    :struct (flat-string `{` (map |[(to-js $) `: ` (to-js (data $)) `,`] (keys data)) `}`)
    :tuple  (flat-string `[` (map |[(to-js $)                       `,`]       data)  `]`)
    :keyword (string `"` data `"`)
    :string  (string `"` data `"`)
    :number  (string     data)
    :boolean (string     data)
    :nil     "null"
    ))
