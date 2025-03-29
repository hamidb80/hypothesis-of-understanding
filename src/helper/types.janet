(defn type/reduced (a)
  (match (type a)
    :string  :string
    :buffer  :string
    
    :table   :struct
    :struct  :struct
    
    :array   :tuple
    :tuple   :tuple
    
    (type a)))