(use ./helper/io)

# ------------------------------------------------------

(defn init-article () @{})

(defn process-article (resolvers article)
  )

# ------------------------------------------------------

(defn simple-wrapper (start-fn end-fn)
  (fn [resolver ctx data args] 
    (let [acc @""]
        (buffer/push acc (start-fn data))
        (each c args (buffer/push acc (resolver ctx c)))
        (buffer/push acc (end-fn data))
      acc)))

(defn const1 (ret) 
  (fn [_] ret))

(def r/wrap           (simple-wrapper (const1 "")               (const1 "")))
(def r/paragraph      (simple-wrapper (const1 `<p dir="auto">`) (const1 `</p>`)))
(def r/italic         (simple-wrapper (const1 `<i>`)            (const1 `</i>`)))
(def r/bold           (simple-wrapper (const1 `<b>`)            (const1 `</b>`)))
(def r/underline      (simple-wrapper (const1 `<u>`)            (const1 `</u>`)))
(def r/strikethrough  (simple-wrapper (const1 `<s>`)            (const1 `</s>`)))
(def r/latex          (simple-wrapper (const1 `<math>`)         (const1 `</math>`)))
(def r/header         (simple-wrapper (fn [d] (string "<h" d ">")) 
                                      (fn [d] (string "</h" d ">"))))

(def html-resolvers {
  :wrap            r/wrap
  
  :bold            r/bold
  :italic          r/italic
  :underline       r/underline
  :strikethrough   r/strikethrough
  
  :header          r/header
  :paragraph       r/paragraph
  
  :latex           r/latex
  # :image           r/image
  # :video           r/video
  })

(defn to-html (content)
  (defn resolver (ctx obj)
    (match (type obj)
      :string         obj
      :number (string obj)
      :struct ((html-resolvers (obj :node)) resolver ctx (obj :data) (obj :body))
              (error (string `invalid kind: ` (type obj)))))
  
  (resolver {:inline false} {
    :node :wrap 
    :body content})
)

(defn h    (size & args) {:node :header      :body args :data size })
(defn abs  (& args)      {:node :abstract    :body args})
(defn sec  (& args)      {:node :section     :body args})
(defn cnt  (& args)      {:node :center      :body args})
(defn b    (& args)      {:node :bold        :body args})
(defn i    (& args)      {:node :italic      :body args})
(defn ul   (& args)      {:node :list        :body args})
(defn sm   (& args)      {:node :small       :body args})
(defn lg   (& args)      {:node :large       :body args})
(defn p    (& args)      {:node :paragraph   :body args})

(def _ ` `)

# ------------------------------------------------------

(defn simple-test ()
  (def article [
    (h 1 `On the Cookie-Eating Habits of `(i `Mice`))

    # (abs `If you give a mouse a cookie, he's going to ask for a glass of milk `)
    
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
  # (pp article)
  # (print (to-html article))
  (file/put "./play.html" (to-html article)))

(simple-test)