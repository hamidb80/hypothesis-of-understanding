# iterating utilities

(defn join-map (lst f)
  (string/join (map f lst)))

(defn not-nil-indexes (row)
  (let [acc @[]]
    (eachp [i n] row
      (if n (array/push acc i)))
    acc))
