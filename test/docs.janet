(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/markup)
(use ../src/graph-of-thought)
(use ../src/solution)

# --------------------------------------------

(use ../src/markup)

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

(cnt
  (b `Cookies Wanted`)_(i `Chocolate chip preferred!`))

(p `and see if anyone brings you more.`)

(cnt (b `Notice to Mice`))

(ul 
  `We have cookies for you.`
  `If you want to eat a cookie, you must bring your own straw.`
)
])
(pp raw-article)

# -------------------------------------

"./test/notes/circular-deps"
"./test/notes/asset-load"
"./test/notes/resolve-recursive"
"./test/notes/simple-doc/"

(let [raw-db   (load-deep subdir)
      db       (finalize-db raw-db nil @{})
      id       :root
      article  ((db id) :content)
      res      (mu/to-html article |(string "/dist/" $))]
  (file/put "./play.html" res))
