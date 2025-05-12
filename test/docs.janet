(use ../src/core/helper/io)
(use ../src/core/helper/path)

(use ../src/core/markup)
(use ../src/core/graph-of-thought)
(use ../src/core/solution)

# --------------------------------------------

(use ../src/core/markup)

# -------------------------------------

(def raw-article [
(h 1 `On the Cookie-Eating Habits of `(i `Mice`))

(abs `If you give a mouse a cookie, he's going to ask for a glass of milk `)

(sec `The Consequences of Milk `)

(p
`He's a `(sm `small mouse`)`. The glass is too `(lg `big`) 
`---`(b `way `(lg `too `(lg `big`)))`. 
So, he'll `(i `probably`)` ask you for a straw.`
`If a mouse eats all your cookies, put up a sign that says`)

(c
  (b `Cookies Wanted`)_(i `Chocolate chip preferred!`))

(p `and see if anyone brings you more.`)

(c (b `Notice to Mice`))

(ul 
  `We have cookies for you.`
  `If you want to eat a cookie, you must bring your own straw.`
)
])
(pp raw-article)

# -------------------------------------

(each subdir [
  "./test/docs/circular-deps/"
  "./test/docs/asset-load/"
  "./test/docs/resolve-recursive/"
  "./test/docs/simple-doc/"]

  (let [raw-db   (load-deep subdir)
      db       (finalize-db raw-db nil @{})
      id       :root
      article  ((db id) :content)
      res      (mu/to-html article |(string "/dist/" $))]
  (file/put "./play.html" res)))
