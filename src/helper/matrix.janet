# matrix is simply 2D array

(defn matrix-size (rows)
  "returns result as [rows cols]"
  [ (length rows) 
    (reduce max 0 (map length (values rows)))])

(defn matrix-of (rows cols val)
  "creates new matrix of size `rows`*`cols` with value of `val`"
  (map (fn [_] (array/new-filled cols)) (range rows)))

(defn get-cell [grid y x]
  ((grid y) x))

(defn put-cell [grid y x val]
  (put (grid y) x val))
