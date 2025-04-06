"
integration of GoT and Notes
"

(use ./helper/debug)
(use ./helper/io)
(use ./helper/path)
(use ./helper/tab)
(use ./helper/str)
(use ./helper/macros)
(use ./helper/iter)
(use ./helper/js)

(use ./locales)
(use ./markup)
(use ./graph-of-thought)

# ------------------------------------------------------
(defn common-head (router) (string `
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

  <link href=" https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css " rel="stylesheet">
  <script src=" https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js "></script>

  <script src="https://cdn.jsdelivr.net/npm/unpoly@3.8.0/unpoly.min.js"></script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/unpoly@3.8.0/unpoly.min.css">

  <script src="`(router "page.js")`"></script>
  <link   href="`(router "style.css")`" rel="stylesheet">
`))
(defn nav-bar (home-page app-title) (string `
  <nav class="navbar navbar-light bg-light px-3 d-flex justify-content-between">
    <div>
    </div>
    
    <a class="navbar-brand" up-follow href="` home-page `">`
      app-title
   `</a>
    
    <div>
    </div>
  </nav>`))

(defn html5 (router title app-config & body)
  (flat-string `<!DOCTYPE html>
    <html lang="en">
    <head>
      <title>` title `</title>` 
      (common-head router)
    `</head>
    <body>`
    (nav-bar (router "") (app-config :title))
    `<main>` body `</main>
    </body>
    </html>`))

(defn  mu/html-page (key title content router app-config)
  (html5 router title app-config `
    <div class="container my-4">
      <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
          <li class="breadcrumb-item"></li>`

          (let [p (dirname/split key)] 
            (map
              (fn [n i]
                (let [is-last (= i (dec (length p)))]
                  (string
                    `<li class="breadcrumb-item ` (if is-last `active`) `">` 
                      n
                    `</li>`)))
              p 
              (range (length p))))
        `</ol>
      </nav>

      <div class="card">
        <article class="card-body"> 
          ` content `
        </article>
      </div>
    </div>`))

(defn  GoT/html-page (got page-title svg svg-theme db router app-config)
  (html5 router page-title app-config `
    <div class="row gx-2 m-3" got 
      data-events='`(to-js (got :events))`'
      data-nodes='`(to-js (got :nodes))`'
      data-anscestors='`(to-js (got :anscestors))`'
    >
      <aside class="col col-5 pt-2">
        <div class="fs-6 mb-3">
          <i class="bi bi-share-fill"></i>
          ` (dict :graph-of-thought) `
        </div>

        <center>
          <div class="d-inline-block bg-light border rounded">
          ` svg `
          </div>
        </center>

        <div class="my-3 d-flex justify-content-center">
          <button class="mx-1 btn btn-outline-primary" id="reset-progress-action">
            ` (dict :reset) `
            <i class="bi bi-arrow-clockwise"></i>
          </button>
          <button class="mx-1 btn btn-outline-primary" id="skip-till-end-action">   
            ` (dict :skip) `
            <i class="bi bi-skip-forward"></i>
          </button>
          <button class="mx-1 btn btn-outline-primary" id="prev-step-action"> 
            ` (dict :prev) `
            <i class="bi bi-arrow-left"></i>
          </button>
          <button class="mx-1 btn btn-outline-primary" id="next-step-action"> 
            ` (dict :next) `
            <i class="bi bi-arrow-right"></i>
          </button>
        </div>
      </aside>

      <aside class="col col-7 pt-2 overflow-y-scroll content-bar" style="height: calc(100vh - 40px)">
        <div class="fs-6">
          <i class="bi bi-person-walking"></i>
          ` (dict :steps) `
        </div>

        <article class="my-3">`
          (map- (got :events) 
            (fn [e] 
              (let [key      (e     :content)
                    c        (e     :class)
                    article  (db key)
                    summ     (dict (or c :thoughts))
                    has-link (not (article :partial))]
                [
                `<div class="pb-3 content" content="` key `" for="` (e :id)`">
                  <div class="card">`
                    `<div class="card-header d-flex justify-content-between pe-2">
                        <div>`
                          (if summ [
                            `<small class="text-muted">` 
                              summ 
                            `</small>`])
                        `</div>
                        <div>`
                          (if has-link [
                            `<a class="text-muted" up-follow href="` (router key) `.html">`
                              key
                              `<i class="bi bi-hash"></i>`
                            `</a>`])
                        `</div>
                      </div>`

                    `<div class="card-body" dir="auto">`
                        (mu/to-html (article :content) router)
                    `</div>`

                  `</div>
                </div>`])))
        `</article>
      </aside>
    </div>`))



# TODO keep track of unreferenced assets
# ------------------------------------------------------
(def markup-ext ".mu.janet") # markup language in Janet lisp format
(def got-ext    ".got.janet") # graph of thought representation in Janet lisp format
(def partial-suffix "_")

(defn req-files (output-dir)
  (let [current-dir ((path/split (dyn *current-file*)) :dir)]
  (file/put (path/join output-dir "page.js")   (slurp  (path/join current-dir "./src/page.js")))
  (file/put (path/join output-dir "style.css") (slurp  (path/join current-dir "./src/style.css")))))

(defn load-deep (root)
  "
  find all markup/GoT files in the `dir` and load them.
  "
  (let [acc @{}
        root-dir (path/dir root)]
    
    (each p (os/list-files-rec root-dir)
      (let [pparts    (path/split p)
            kind (cond 
                  (string/has-suffix? markup-ext p) :note
                  (string/has-suffix?    got-ext p) :got
                  nil)]
        (if kind 
          (put acc 
            (keyword (string/remove-prefix root-dir (pparts :dir)) (pparts :name)) 
            @{:path    p
              :kind    kind
              :partial (string/has-suffix? partial-suffix (pparts :name))
              :content (let [file-content (try (slurp p)            ([e] (error (string "error while reading from file: " p))))
                             lisp-code    (try (parse file-content) ([e] (error (string "error while parseing lisp code from file: " p))))
                             result       (try (eval  lisp-code)    ([e] (error (string "error while evaluating parseing lisp code from file: " p))))]
                          result)}))))
    acc))

# TODO
(defn solution (notes-dir assets-dir output-dir)
  1)