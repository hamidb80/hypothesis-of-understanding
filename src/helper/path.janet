(use ./iter)

(defn path/mode (path)
  (if (string/has-suffix? "/" path) :directory :file))

(defn is-dir (path) 
  (= (path/mode path) :directory))

(defn path/join (a b)
  (if (is-dir a) (string a b)
                 (string a "/" b)))

(defn filename/split (path)
  (let [i (find-index |(= (chr ".") $) path (length path))]
    [(slice path 0 i) (slice path i (length path))]))

(defn dirname/split (path)
  (string/split "/" path))

(defn dirname/split-rec (path)
  (var cur "")
  (reduce 
    (fn [acc n] 
      (if (empty? n) acc 
          (array/push acc (set cur (string cur n "/"))))) 
    @[] 
    (dirname/split path)))

(defn path/split (path)
  (let [i          (find-last-index |(= (chr "/") $) path 0)
        dir        (slice path 0 (inc i))
        file       (slice path (inc i) (length path))
        [name ext] (filename/split file)]
    {:dir  dir
     :name name
     :ext  ext}))