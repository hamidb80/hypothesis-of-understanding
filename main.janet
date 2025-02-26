"""
tiny mind-tree creator.
"""

(defn exec (cmd)
  (os/execute cmd :pe))

(defn file/put (path content)
  (def        f (file/open path :w))
  (file/write f content)
  (file/close f))

(defn file/exists (path) 
  (not (nil? (os/stat path))))

(defn join-map (lst f)
  (string/join (map f lst)))

(defn rand/int (a b)
       (+ a (math/floor (* (- b a) (math/random)))))

# props

(defn prop (kind data) 
  {:kind kind :data data })

(defn latex (code) 
  (prop :latex code))

(defn important () 
  (prop :important nil))

(defn web (url &opt text) 
  (prop :web-url {:url url 
                  :text (if (nil? text) url text)}))

(defn pdf-page-ref (path name) 
  (fn (page)
    (prop :pdf-reference {
          :file  path
          :name  name
          :page  page })))

(defn extract-page (pdf-file-path page-num out-path use-cache)
  (if (and use-cache (file/exists out-path))
    nil # cached
    (exec ["magick" "-density" "300" (string pdf-file-path "[" page-num "]") out-path]))
)

# ------------------

(defn int-val (d) (if (number? d) d 0))

(defn put+ (tab key) 
  (put tab key (+ 1 (int-val (tab key)))))

(defn mind-map/preprocess (data)
  (eachp [id node] (data :ids)
    (each p (node :properties)
      (match (p :kind)
             :important     (put  (node :meta) :important true)
             :pdf-reference (put+ (node :meta) :pdf-reference)
             :web-url       (put+ (node :meta) :web-url)
             )))
  data)

(defn mind-map/create-impl (sub-nodes ids)
  (def acc @[])
  (var cur nil)

  (defn init-node () 
    (var id nil)
    @{
      :id         (keyword "n-" (rand/int 1 64000000))
      :properties @[] 
      :children   @[]
      :meta       @{}})

  (defn done (node) 
    (if node (do
      (put        ids (cur :id) cur)
      (array/push acc cur))))

  (each d sub-nodes
    (match (type d)
      :keyword (put         cur :id          d)
      :struct  (array/push (cur :properties) d)
      :tuple   (put         cur :children    (mind-map/create-impl d ids))
      :string  (do
                  (done cur)
                  (set cur (init-node))
                  (put cur :label d))))
  
  (done cur)
  acc
)

(defn mind-map/create (mind-tree)
  (if (empty? mind-tree)
      (error "the mind-tree is empty")
      (do   
        (def ids @{})
        (mind-map/preprocess { 
          :root (mind-map/create-impl mind-tree ids)
          :ids  ids
        }))))


(defn html/card (color header content) (string 
  # add header customized for each kind
  `<div class="card border-` color ` mb-3">`
    header
   `<div class="card-body text-dark">`
      content   
   `</div>
  </div>`))

(defn html/badge (tag value click-event) (string 
    `<button class="btn btn-sm btn-light ms-1 px-1" onclick="` click-event `">` 
      tag " " value 
    `</button>`))

(defn html/props (u out-dir use-cache)
  (join-map (u :properties) 
            (fn (p) (match (p :kind)
                          :pdf-reference (let [ page-num      ((p :data) :page) 
                                                file-path     ((p :data) :file)
                                                book-name     ((p :data) :name)
                                                img-path      (string ((p :data) :page) ".png") 
                                                e             (extract-page file-path (- page-num 1) (string out-dir img-path) use-cache) ] 
                                          (html/card "danger" 
                                             (string
                                                `<div class="card-header">`
                                                  `📕 `
                                                  `<a target="_blank" href="file:///` file-path `#page=` page-num `">page ` page-num `</a>` 
                                                  `<span> from ` book-name `</span>`
                                                  `<br/>`
                                                `</div>`)

                                             (string 
                                                `<center class="w-100">
                                                  <img style="max-width: 100%;" src="./` img-path `"/>
                                                </center>` )))
                          :latex         (html/card "dark"    "" (string `<code>` (p :data) `</code>`))
                          :web-url       (html/card "primary" "" (string `<a target="_blank" href="` ((p :data) :url) `">` ((p :data) :text) `</a>`))
                                        "")))
)

(defn mind-map/html-impl (mm out-dir use-cache)
  (join-map mm
    (fn (u) (string
      `<details class="mind-tree-node" id="` (u :id) `">
        <summary class="mt-1">`
          `<span "clickable">`
            (u :label)
          `</span>`
          `<div class="d-inline-block features">`
            (if (not (empty?  (u :children)))           (html/badge "«"  ""                     "toggleNodes(this.parentElement.parentElement.parentElement, false)") "")
            (if (not (empty?  (u :children)))           (html/badge "»"  (length (u :children)) "toggleNodes(this.parentElement.parentElement.parentElement, true)") "")
            (if              ((u :meta) :important)     (html/badge "🌟" ""         "") "")
            (if              ((u :meta) :pdf-reference) (html/badge "📕" ((u :meta) :pdf-reference) (string `contentFor(event,'` (u :id) `')`))  "")
            (if              ((u :meta) :web-url)       (html/badge "🌐"  ((u :meta) :web-url      ) (string `contentFor(event,'` (u :id) `')`))  "")
          `</div>`
        `</summary>`
        `<div class="border-start border-gray my-1 ps-4">`
          (mind-map/html-impl (u :children) out-dir use-cache)
        `</div>`
      `</details>`))
))

(defn mind-map/html (mm title out-dir use-cache) 
  (string
    `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>` title `</title>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    </head>
    <body>

    <nav class="navbar navbar-expand-lg bg-body-tertiary">
      <div class="container-fluid">
        <a class="navbar-brand" href="#">` title `</a>
      </div>
    </nav>

    <script>
      function toggleNodes(el, opened) {
        if (el.classList.contains("mind-tree-node")){
          el.open = opened
        }

        [...el.querySelectorAll(".mind-tree-node")]
           .forEach(el => el.open = opened)
      }

      function clsx(el, classConditionMap) {
        for (let cls in classConditionMap) {
          let cond = classConditionMap[cls]
          if (cond)
            el.classList.add(cls)
          else
            el.classList.remove(cls)
        }
      }

      function hideAllContent() {
        [...document.querySelectorAll(".content")]
            .forEach(el => el.classList.add("d-none"))
      }


      function toggleSidebar(open) {
        let el = document.getElementById("contentbar")

        if (!open) {
          hideAllContent()
        }

        clsx(document.body, {
          "overflow-none": open
        })
        clsx(el, {
          "d-none"  :  !open,

          "vh-100"  :  open,
          "top-0"   :  open,
        })
      }

      function contentFor(event, id) {
        event.preventDefault()
        let el = document.getElementById("content-" + id)
        el.classList.remove("d-none")
        toggleSidebar(true)
      }
    </script>

    <div class="container my-4">
    
      <div class="my-2">  
        <button class="btn btn-sm btn-outline-primary" onclick="toggleNodes(document.body, true)">
          expand all
        </button>

        <button class="btn btn-sm btn-outline-primary" onclick="toggleNodes(document.body, false)">
          collapse all
        </button>
      </div>`
      (mind-map/html-impl (mm :root) out-dir use-cache)
    `</div>
    
    <div class="pb-5"></div>
    <div class="pb-5"></div>

    <aside class="w-100 position-fixed d-none bg-light overflow-y-scroll" id="contentbar">
      <nav class="navbar navbar-expand-lg bg-body-tertiary">
        <div class="container-fluid">
          <span> content </span>
          <button class="btn btn-sm btn-outline-danger" onclick="toggleSidebar(false)"> × </button>
        </div>
      </nav>
      <div class="container py-3">`
        (join-map (values (mm :ids))
                  (fn [n] (string 
                      `<div id="content-` (n :id)  `" class="content d-none">`
                        (html/props n out-dir use-cache)
                      `</div>`)))

     `</div>`
   `</aside>
    </body>
    </html>`))


# --------------

(def bk (pdf-page-ref 
          "C:/Users/HamidB80/Desktop/sec-net.pdf" 
          "Understanding Cryptography by Christof Paar & Jan Pelzl"))

(def mm (mind-map/create [
  "Introduction :: Cryptology" [
    "Crypto-graphy  :: hiding " (bk 19) [
      "Symmetric Cipher"
      "Asymmetric Cipher"
      "Protocols"
    ]
    "Crypt-analysis :: breaking" (bk 26)

    "simple Ciphers" [
      "Substitution" (bk 22)
      "Shift"        (bk 34)
      "Affine"       (bk 35)  
    ]

    "Kerckhoffs’ Principle" (bk 27)
  ]

  "Stream VS Block Ciphers" (bk 45)

  "Stream Ciphers" [
    "Synchronous and Asynchronous" (bk 45)
    
    "random number generator" [
      "true"          (bk 50)
      "pseudo"        (bk 50)
      "secure pseudo" (bk 51)
    ]

    "One Time Pad" (bk 52)

    "Computational Security" (bk 53)

    "Linear Feedback Shift Registers" [
      "desc" (bk 58)
      "feedback coefficient vector" (bk 59)
      "Attack" (bk 61)
    ]
    
    "Trivium" [
      "def" (bk 61) (bk 62)
      "phases" [
        "init"
        "warm up"
        "Encryption"  
      ]
    ]
  ]

  "DES" [
    "Confusion and Diffusion" (bk 72)
  ]

  "AES" (web "https://www.youtube.com/watch?v=C4ATDMIz5wc" "AES: How to Design Secure Encryption by Spanning Tree") [
    
  ]
]))

# ---------------------- go

# (pp mm)

(let [build-dir  (1 (dyn *args*))
      index-page (string build-dir "index.html")]

  (file/put index-page (mind-map/html mm "network security 📝" build-dir true))
  (print "success: " index-page))