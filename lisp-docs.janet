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
  :wrap   h/wrap
  :title  h/paragraph
  :p      h/paragraph
  # :b     h/bold
  # :i     h/italic
  # :u     h/underline
  # :s     h/strikethrough
  # :latex h/latex
  # :title h/h1
  # :img   h/image
  # :video h/video
  })

(defn to-html (content)
  (defn resolver (inline obj)
    (print "-----------------")
    (pp obj)
    ((resolvers (obj :node)) resolver inline (obj :data) (obj :body)))
  
  (resolver false {
    :node :wrap 
    :body content})
)

(defn title    (& args) {:node :title    :body args})
(defn abstract (& args) {:node :abstract :body args})
(defn section  (& args) {:node :section  :body args})
(defn centered (& args) {:node :center   :body args})
(defn bold     (& args) {:node :bold     :body args})
(defn italic   (& args) {:node :title    :body args})
(defn itemlist (& args) {:node :list     :body args})
(defn smaller  (& args) {:node :small    :body args})
(defn larger   (& args) {:node :large    :body args})
(defn p        (& args) {:node :p        :body args})

(def _ ` `)


(def article [
(title `On the Cookie-Eating Habits of Mice`)

# (abstract `If you give a mouse a cookie, he's going to ask for a glass of milk `)
 
# (section `The Consequences of Milk `)

# (p
# `He's a `(smaller `small mouse`)`. The glass is too `(larger `big`) 
# `---`(bold `way `(larger `too `(larger `big`)))`. 
# So, he'll `(italic `probably`)` ask you for a straw.`
# `If a mouse eats all your cookies, put up a sign that says`)

# (centered
#   (bold `Cookies Wanted`)_(italic `Chocolate chip preferred!`))

(p `and see if anyone brings you more.`)

# (centered (bold `Notice to Mice`))
 
# (itemlist 
#   `We have cookies for you.`
#   `If you want to eat a cookie, you must bring your own straw.`
# )
])

(pp article)
(print (to-html article))