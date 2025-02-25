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

(defn pdf-page-ref (path page-offset) 
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

(defn mind-map/preprocess (data)
  data)

(defn mind-map/create-impl (data ids)
  (def acc @[])
  (var id  (keyword "n-" (rand/int 1 64000000)))
  (var cur nil)

  (defn init-node () @{
      :properties @[] 
      :children   @[]
  })

  (each d data
    (match (type d)
      :keyword (set id d)
      :tuple   (put         cur :children    (mind-map/create-impl d ids))
      :struct  (array/push (cur :properties) d)
      :string  (do
                  (if (not (nil? cur)) (array/push acc cur))
                  (set cur (init-node))
                  (put cur :label d))
    ))
  
  (if (nil? (get ids id)) 
            (put ids id cur) # assign id
            (error (string "duplicated id :" id)))
  
  (array/push acc cur) # last iteration
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

(defn mind-map/html-impl (mm out-dir use-cache)
  (join-map mm
    (fn (u) (string
      "<details>
        <summary>" (u :label) "</summary>"
        "<div style=\"padding-left: 20px; padding-bottom: 4px\">"
          "<ul style=\"
            padding-left:16px; 
            padding-bottom: " (if (or (empty? (u :children)) (empty? (u :properties))) 0 6) "px;
          \">"
          
          (join-map (u :properties) 
                     (fn (p) (match (p :kind)
                                    :pdf-reference (let [ page-num      ((p :data) :page) 
                                                          file-path     ((p :data) :file) 
                                                          img-path      (string ((p :data) :page) ".png") 
                                                          e             (extract-page file-path (- page-num 1) (string out-dir img-path) use-cache) ] 
                                                   (string "<li>" "<a target='_blank' href='" "file:///" file-path "#page=" page-num "'>" "page " page-num "</a>" "<br/>" `<img style="max-width: 400px;" src="./` img-path `"/>` "</li>"))
                                    :latex         (string "<li><code>" (p :data) "</li></code>")
                                    :web-url       (string `<li><a target='_blank' href="` ((p :data) :url) `">` ((p :data) :text) `</a></li>`)
                                    :important     "<li>🌟 important</li>"
                                                   (error (string "the attr :" (p :kind) " not implemented")))))
          "</ul>"
          
          (mind-map/html-impl (u :children) out-dir use-cache)
        "</div>"
      "</details>"
    ))
))

(defn mind-map/html (mm out-dir use-cache) 
  (string
    "<style>*{padding:0;margin:0;}</style>"
    (mind-map/html-impl (mm :root) out-dir use-cache)))


# --------------

(def bk-path "C:/Users/HamidB80/Desktop/sec-net.pdf")
(def bk (pdf-page-ref bk-path 16))

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
        "Encription"  
      ]
    ]
  ]

  "Data Encryption Standard (DES)" [
    "Confusion and Diffusion" (bk 72)
    
  ]
]))

# ---------------------- go

# (pp mm)

(let [build-dir  (1 (dyn *args*))
      index-page (string build-dir "index.html")]

  (file/put index-page (mind-map/html mm build-dir true))
  (print "success: " index-page))