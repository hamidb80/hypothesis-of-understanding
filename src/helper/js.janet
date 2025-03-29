# JavaScript utilities

(use ./types)
(use ./iter)

(defn to-js (data)
  (match (type/reduced data)
    :struct (string 
      `{` 
      (join-map (keys data) (fn (k) (string (to-js k) `: ` (to-js (data k)) `,`))) 
      `}`)
    
    :tuple  (string 
      `[` 
      (join-map data (fn (v) (string (to-js v) `,`))) 
      `]`)

    :keyword (string `"` data `"`)
    :string  (string `"` data `"`)
    :number  (string     data)
    :boolean (string     data)
    :nil     "null"
    ))
