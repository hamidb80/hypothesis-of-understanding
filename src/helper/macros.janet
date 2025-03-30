(defmacro let-acc (val & body)
  "creates a temporary def named `acc` and returns it"
  ~(let [acc ,val]
    ,;body
    acc))

# (pp (macex '(let-acc @[] 
#   (array/push acc 2)
#   (array/push acc 2)
#   (array/push acc 2)))) 

