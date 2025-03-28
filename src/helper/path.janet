(defn path/mode (path)
  (if (string/has-suffix? "/" path) :directory :file))

(defn is-dir (path) 
  (= (path/mode path) :directory))

(defn path/join (a b)
  (if (is-dir a) (string a b)
                 (string a "/" b)))
