(use ./macros)

(defn to-table (lst key-gen val-gen)
  (let-acc @{}
    (each n lst (put acc (key-gen n) (val-gen n)))))

(defn rev-table [tab]
  (let-acc @{}
    (eachp (k v) tab
      (let [lst (acc v)]
          (if (nil? lst)
                (put acc v @[k])
                (array/push lst k))))))
