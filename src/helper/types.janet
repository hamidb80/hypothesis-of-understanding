(defn type/reduced (a)
  "simplitied version of `type` function"

  (match (type a)
    :string  :string
    :buffer  :string
    
    :table   :struct
    :struct  :struct
    
    :array   :tuple
    :tuple   :tuple
    
    (type a)))