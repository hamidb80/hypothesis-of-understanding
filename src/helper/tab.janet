(defn to-table (lst key-generator)
  (let [acc @{}]
      (each n lst (put acc (key-generator n) n))
      acc))

(defn rev-table [tab]
  (def acc @{})
  (eachp (k v) tab
    (let [lst (acc v)]
         (if (nil? lst)
              (put acc v @[k])
              (array/push lst k))))
  acc)
