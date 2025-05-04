(use ./debug)
(use ./bool)
(use ./iter)

(defn  path/mode (path)
  (if (string/has-suffix? "/" path) :directory :file))

(defn  is-dir (path) 
  (= (path/mode path) :directory))

(defn  is-root (path)
  (string/has-prefix? "/" path))

(defn- path/join-impl [a b]
  (if (empty? a) b
      (match [(is-dir a) (is-root b)]
        [F F] (string a "/" b)
        [T F] (string a b)
        [F T] (string a b)
        [T T] (string a (slice b 1)))))

(defn  path/join (& chunks)
  (reduce path/join-impl "" chunks))

(defn  path/dir (p)
  (cond
    (nil? p)                   nil
    (string/has-suffix? "/" p) p 
                               (string p "/")))

(defn  filename/split (path)
  "convert file.long.ext -> file, .long.ext"

  (let [i (find-index |(= (chr ".") $) path (length path))]
    [(slice path 0 i) (slice path i (length path))]))

(defn  dirname/split (path)
  "normal path split: a/b/c -> [a, b, c]"
  
  (string/split "/" path))

(defn  dirname/split-rec (path)
  "canonical split a/b/c -> ./a, ./a/b, ./a/b/c"

  (var cur "")
  (reduce 
    (fn [acc n] 
      (if (empty? n)  acc 
          (array/push acc (set cur (string cur n "/"))))) 
    @[] 
    (dirname/split path)))

(defn  path/split (path)
  "converts a/b/c.d -> {:dir a/b/ :name c :ext d}"

  (let [i          (find-last-index |(= (chr "/") $) path 0)
        dir        (slice path 0 (inc i))
        file       (slice path (inc i) (length path))
        [name ext] (filename/split file)]
    {:dir  dir
     :name name
     :ext  ext}))