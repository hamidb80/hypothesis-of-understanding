# input/output utilities

(use 
  ./path
  ./str
  ./debug
  ./system
  ./macros)

(defn file/exists 
  "checks whether file/dir exist"
  (path) 
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

(defn os/mkdir-rec (path)
  (each p (dirname/split-rec path)
    (os/mkdir p)))

(defn file/put (path content)
  (os/mkdir-rec ((path/split path) :dir))
  (def        f (file/open path :w))
  (file/write f content)
  (file/close f))

(defn os/copy 
  "copies both file and directory"
  (src dest)
  
  (exec ["powershell.exe"  "-Command"  "Copy-Item"  "-Path"  src  "-Destination"  dest "-Recurse"]))


(defn os/rmdir-rec
  "removes both file and directory"
  (src)
  
  (exec ["powershell.exe"  "-Command"  "Remove-Item"  "-Path"  src  "-Recurse"]))