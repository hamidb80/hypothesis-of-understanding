(defn h/wrap (resolver inline data args)
  (let [acc @""]
    (each c args
      (buffer/push acc 
        (match (type c) 
        :string c 
                (resolver inline c))))
    acc))

(defn h/paragraph (resolver inline data args)
  (let [acc @`<p dir="auto">`]
    (each c args
      (buffer/push acc 
        (match (type c) 
        :string c 
                (resolver inline c))))
    (buffer/push acc "</p>")
    acc))

(def resolvers {
  :wrap  h/wrap
  :p     h/paragraph
  # :b     h/bold
  # :i     h/italic
  # :u     h/underline
  # :s     h/strikethrough
  # :latex h/latex
  # :title h/h1
  # :img   h/image
  # :video h/video
  })

(defn to-html (& content)
  (defn resolver (inline obj)
    (pp obj)
    ((resolvers (obj :kind)) resolver inline (obj :data) (obj :args)))
  
  (resolver false {
    :kind :wrap 
    :data nil 
    :args content})
)

(defn p (data & args)
  {:kind :p
   :data data
   :args args})

(print (to-html 
  "salam" 
  (p nil "wow")
  (p nil "chetory?")
  ))