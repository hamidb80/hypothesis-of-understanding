(defn simple-wrapper (start end)
  (fn [resolver ctx data args] 
    (let [acc @""]
        (buffer/push acc start)
        (each c args (buffer/push acc (resolver ctx c)))
        (buffer/push acc end)
      acc)))

(def h/wrap      (simple-wrapper "" ""))
(def h/paragraph (simple-wrapper `<p dir="auto">` `</p>`))
(def h/italic    (simple-wrapper `<i>` `</i>`))
(def h/bold      (simple-wrapper `<b>` `</b>`))

(def resolvers {
  :wrap        h/wrap
  :title       h/paragraph
  :paragraph   h/paragraph
  :bold        h/bold
  :italic      h/italic
  # :u     h/underline
  # :s     h/strikethrough
  # :latex h/latex
  # :title h/h1
  # :img   h/image
  # :video h/video
  })

(defn to-html (content)
  (defn resolver (ctx obj)
    (match (type obj)
      :string         obj
      :number (string obj)
      :struct ((resolvers (obj :node)) resolver ctx (obj :data) (obj :body))
              (error (string `invalid kind: ` (type obj)))))
  
  (resolver {:inline false} {
    :node :wrap 
    :body content})
)

(defn title    (& args) {:node :title       :body args})
(defn abstract (& args) {:node :abstract    :body args})
(defn section  (& args) {:node :section     :body args})
(defn centered (& args) {:node :center      :body args})
(defn bold     (& args) {:node :bold        :body args})
(defn italic   (& args) {:node :italic      :body args})
(defn itemlist (& args) {:node :list        :body args})
(defn smaller  (& args) {:node :small       :body args})
(defn larger   (& args) {:node :large       :body args})
(defn p        (& args) {:node :paragraph   :body args})

(def _ ` `)


(def article [
(title `On the Cookie-Eating Habits of `(italic `Mice`))

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