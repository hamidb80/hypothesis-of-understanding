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

(defn pdf-page-ref (path) 
  (fn (page)
    (prop :pdf-reference {
          :file  path 
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

(defn html/badge (tag value) 
  (string `<span class="badge bg-light ms-1 px-1">` tag " " value `</span>`))

(defn html/heading (node) (string 
  (node :label)
  (let [c (node :children)]
    (if (empty? c) ""            (html/badge "⧂" (length c))))
  (if ((node :meta) :important)     (html/badge "🌟" "") "")
  (if ((node :meta) :pdf-reference) (html/badge "📕" ((node :meta) :pdf-reference))  "")))

(defn mind-map/html-impl (mm out-dir use-cache)
  (join-map mm
    (fn (u) (string
      `<details class="mind-tree-node" id="` (u :id) `">
        <summary>` (html/heading u) `</summary>`
        `<div class="border-start border-gray my-1 ps-4">`
          (join-map (u :properties) 
                    (fn (p) (match (p :kind)
                                  :pdf-reference (let [ page-num      ((p :data) :page) 
                                                        file-path     ((p :data) :file) 
                                                        img-path      (string ((p :data) :page) ".png") 
                                                        e             (extract-page file-path (- page-num 1) (string out-dir img-path) use-cache) ] 
                                                  (string `<details>`
                                                          `<summary>`
                                                            `<a target="_blank" href="file:///` file-path `#page=` page-num `">page ` page-num `</a><br/>` 
                                                          `</summary>`
                                                          `<img style="max-width: 400px;" src="./` img-path `"/>`
                                                          `</details>`))
                                  :latex         (string "<li><code>" (p :data) "</li></code>")
                                  :web-url       (string `<li><a target="_blank" href="` ((p :data) :url) `">` ((p :data) :text) `</a></li>`)
                                                "")))

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
      <link rel="stylesheet" href="https://bootswatch.com/5/litera/bootstrap.min.css">
    </head>
    <body>

    <nav class="navbar navbar-expand-lg bg-body-tertiary">
      <div class="container-fluid">
        <a class="navbar-brand" href="#">` title `</a>
      </div>
    </nav>

    <script>
      function toggleNodes(opened) {
        [...document.querySelectorAll(".mind-tree-node")].forEach(a => a.open = opened)
      }
    </script>

    <div class="container my-4">
    
      <div class="my-2">  
        <button class="btn btn-sm btn-outline-primary" onclick="toggleNodes(true)">
          expand all
        </button>

        <button class="btn btn-sm btn-outline-primary" onclick="toggleNodes(false)">
          collapse all
        </button>
      </div>  
    `
    (mind-map/html-impl (mm :root) out-dir use-cache)
    `  
    </div>
    </body>
    </html>`))


# --------------

(def bk-path "C:/Users/home/Desktop/sec.pdf")
(def bk (pdf-page-ref bk-path))

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

    "One Time Pad" (bk 51)

    "Computational Security" (bk 53)

    "Linear Feedback Shift Registers" [
      "desc" (bk 58)
      "feedback coefficient vector" (bk 59)
      "Attack" (bk 61)
    ]
    
    "Trivium" [
      "def" (bk 61)
      "schema" (bk 62)

      "phases" [
        "init"
        "warm up"
        "Encryption"  
      ]
    ]
  ]

  "DES" (web "https://www.youtube.com/watch?v=kPBJIhpcZgE") [
    "Confusion and Diffusion" (bk 72)
  ]

  "AES" (web "https://www.youtube.com/watch?v=C4ATDMIz5wc") [
    
  ]
]))

# ---------------------- go

# (pp mm)

(let [build-dir  (1 (dyn *args*))
      index-page (string build-dir "index.html")]

  (file/put index-page (mind-map/html mm "network security 📝" build-dir true))
  (print "success: " index-page))