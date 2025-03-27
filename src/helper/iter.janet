# iterating utilities

(defn join-map (lst f)
  (string/join (map f lst)))
