(use ./macros)
(use ./number)

# (defn assoc (tab & new-key-vals)
#   (let-acc @{}
#     (eachp [k v] tab
#       (put acc k v))
    
#     (each i (range 0 (length new-key-vals) 2)
#       (let [[k v] (slice new-key-vals i (+ 2 i))]
#         (put acc k v)))))

(defn put+ (tab key) 
  (put tab key (+ 1 (int-val (tab key)))))

(defn to-table (lst key-gen val-gen)
  (let-acc @{}
    (each n lst
      (let [k (key-gen n)]
        (put acc k (val-gen n))))))

(defn const-table (lst val)
  (zipcoll lst (array/new-filled (length lst) val)))

(defn rev-table [tab]
  "
  reveses a table from A->B to B->[A]
  
  since there can be multiple As pointing to the 
  same B, the result is saved as an array

  similar to Janet built-in `invert` function but keeps duplicated keys.
  "

  (let-acc @{}
    (eachp (k v) tab
      (let [lst (acc v)]
          (if (nil? lst)
                (put acc v @[k])
                (array/push lst k))))))