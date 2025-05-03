(defn os/random 
  "get random number from Windows OS"
  ()

  (def [stdin-r stdin-w] (os/pipe))
  (def [stdout-r stdout-w] (os/pipe))

  (os/execute 
    ["powershell.exe"  "-Command"  "Get-Random"  "-Minimum"  "0.0"  "-Maximum"  "1.0"]
    :px
    {:in stdin-r :out stdout-w}
  )
  (scan-number (string/trim (:read stdout-r math/int32-max))))


(def alphanumberic "abcdefghijklmnopqrstuvwxyz0123456789")

(defn rand/int (a b)
  (+ a (math/floor (* (- b a) (os/random)))))


(defn rand/string (len)
  (string/from-bytes ;(map (fn (_) (alphanumberic (rand/int 0 (dec (length alphanumberic))))) (range len))))
