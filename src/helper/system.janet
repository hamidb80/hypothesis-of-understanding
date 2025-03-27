# System API utilities

(defn exec (cmd)
  (os/execute cmd :pe))
