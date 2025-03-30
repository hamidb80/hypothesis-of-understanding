# input/output utilities

(use ./path)
(use ./macros)

(defn file/put (path content)
  (def        f (file/open path :w))
  (file/write f content)
  (file/close f))

(defn file/exists (path) 
  (not (nil? (os/stat path))))

(defn os/diri (root)
  # os/dir [i]mproved
  # files first
  (sort-by is-dir (map 
    (fn [rel] (let [path (path/join root rel)] 
      (match ((os/stat path) :mode)
        :directory (string path "/")
        :file      path))) 
    (os/dir root))))

(defn os/list-files-rec-impl (root acc)
  (each relpath (os/diri root)
    (match (path/mode relpath)
          :directory (os/list-files-rec-impl relpath acc)
          :file      (array/push acc relpath))))

(defn os/list-files-rec (root)
  (let-acc @[] 
    (os/list-files-rec-impl root acc)))
