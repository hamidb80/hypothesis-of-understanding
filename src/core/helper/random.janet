(defn init-random ()
  (math/seedrandom (os/cryptorand 10)))

(def alphanumberic "abcdefghijklmnopqrstuvwxyz0123456789")

(defn rand/int (a b)
  (+ a (math/floor (* (- b a) (math/random)))))

(defn rand/string (len)
  (string/from-bytes ;(map (fn (_) (alphanumberic (rand/int 0 (dec (length alphanumberic))))) (range len))))

# ----------------------------

(init-random)
