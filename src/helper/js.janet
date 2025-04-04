# JavaScript utilities

(use ./types)
(use ./iter)
(use ./str)

(defn to-js 
  "Converts a Lisp data-structure into its corresponding JS data-structure"
  (data)

  (match (type/reduced data)
    :struct (flat-string `{` (map (fn [$ i][(if-not (= 0 i) `,`) (to-js $) `: ` (to-js (data $))]) (keys data) (range (length data))) `}`)
    :tuple  (flat-string `[` (map (fn [$ i][(if-not (= 0 i) `,`) (to-js $)                      ])       data  (range (length data))) `]`)
    :keyword (string `"` data `"`)
    :string  (string `"` data `"`)
    :number  (string     data)
    :boolean (string     data)
    :nil     "null"
    ))
