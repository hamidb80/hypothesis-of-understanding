(defn string/remove-prefix (prefix str)
  (if (string/has-prefix? prefix str)
      (slice str (length prefix) (length str))))