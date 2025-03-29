(defn type/simple (a)
  (match (type a)
    :string  :string
    :buffer  :string
    
    :table   :struct
    :struct  :struct
    
    :array   :tuple
    :tuple   :tuple
    
    :number  :number
    :boolean :boolean
    :keyword :keyword))