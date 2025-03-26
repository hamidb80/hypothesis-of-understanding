(use ./iter)

(defn to-js (data)
  (defn table-like (t) (string 
      `{` 
      (join-map (keys t) (fn (k) (string (to-js k) `: ` (to-js (t k)) `,`))) 
      `}`))

  (defn array-like (t) (string `[` 
      (join-map data (fn (v) (string (to-js v) `,`))) 
    `]`))

  (match (type data)
    :table  (table-like data)
    :struct (table-like data)
    :array  (array-like data)
    :tuple  (array-like data)

    :keyword (string `"` data `"`)
    :string  (string `"` data `"`)
    :number  (string     data)
    :boolean (string     data)
    :nil     "null"
    ))
