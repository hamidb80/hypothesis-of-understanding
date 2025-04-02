(use ./debug)
(use ./types)
(use ./macros)

(defn string/remove-prefix (prefix str)
  (if (string/has-prefix? prefix str)
      (slice str (length prefix) (length str))))

(defn- flat-string-impl (lst acc)
  (each s lst
    (match (type/reduced s)
      :string  (buffer/push acc s)
      :keyword (buffer/push acc s)
      :tuple   (flat-string-impl s acc)
      :nil     nil
               (error (string `invalid type :` (type/reduced (inspect s)))))))

(defn  flat-string (& args) # args is nested list of string
  (let-acc @"" (flat-string-impl args acc)))
