# iterating utilities

(use ./macros)

(defn map- (lst f) 
  (map f lst))

(defn not-nil-indexes (row)
  (let-acc @[]
    (eachp [i n] row
      (if n (array/push acc i)))))

(defn find-last-index (pred lst dflt)
  "reverse of `find-index`"

  (var i (dec (length lst)))
  (var j dflt)
  (while (<= 0 i)
    (if (pred (lst i)) 
      (break (set j i))
      (set i (dec i))))
  j)

(defn zip (& args)
  (map tuple ;args))