(defn rand/int (a b)
  (+ a (math/floor (* (- b a) (math/random)))))
