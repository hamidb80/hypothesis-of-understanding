"
a vector is simply stored as an array e.g. [x y z]
"

(defn v+ (v1 v2)
  (map + v1 v2))

(defn v- (v1 v2) 
  (map - v1 v2))

(defn v* (scalar v) 
  (map (fn (x) (* x scalar)) v))

(defn v-mag (v) 
  (math/sqrt (reduce + 0 (map * v v))))

(defn v-norm (a) 
  (v* (/ 1 (v-mag a)) a))
