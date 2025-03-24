(def _  " ")

(defn title    (& args) args)
(defn abstract (& args) args)
(defn section  (& args) args)
(defn centered (& args) args)
(defn bold     (& args) args)
(defn italic   (& args) args)
(defn itemlist (& args) args)
(defn smaller  (& args) args)
(defn larger   (& args) args)


(pp [
(title `On the Cookie-Eating Habits of Mice`)

(abstract `If you give a mouse a cookie, he's going to ask for a glass of milk `)
 
(section `The Consequences of Milk `)

(p
`He's a `(smaller `small mouse`)`. The glass is too `(larger `big`) 
`---`(bold `way `(larger `too `(larger `big`)))`. 
So, he'll `(italic `probably`)` ask you for a straw.`
`If a mouse eats all your cookies, put up a sign that says`)

(centered
  (bold `Cookies Wanted`)_(italic `Chocolate chip preferred!`))

(p `and see if anyone brings you more.`)

(centered (bold `Notice to Mice`))
 
(itemlist 
  `We have cookies for you.`
  `If you want to eat a cookie, you must bring your own straw.`
)
])