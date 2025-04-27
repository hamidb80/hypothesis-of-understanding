(use 
  ./helper/str
  ./helper/path
  ./helper/js
  ./helper/iter)

(use 
  ./markup
  ./graph-of-thought
  ./locales)


(defn common-head (router) (string `
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@100..900&family=Titillium+Web:ital,wght@0,200;0,300;0,400;0,600;0,700;0,900;1,200;1,300;1,400;1,600;1,700&display=swap" rel="stylesheet">

  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"          rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">

  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js"></script>
  <link  href="https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css" rel="stylesheet">

  <script src="https://cdn.jsdelivr.net/npm/unpoly@3.8.0/unpoly.min.js"></script>
  <link  href="https://cdn.jsdelivr.net/npm/unpoly@3.8.0/unpoly.min.css" rel="stylesheet">

  <script src="`(router "page.js")`"></script>
  <link  href="`(router "style.css")`" rel="stylesheet">
`))

(defn nav-path (router app-config key db)
  [`<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
      <li class="breadcrumb-item">
        <a up-follow href="` (router "") `">`
          (app-config :root-title)
        `</a>
      </li>`

      (let [paths (zip (dirname/split key) (dirname/split-rec key))] 
        (map
          (fn [[n k] i]
            (let [is-last (= i (dec (length paths)))
                  key     (keyword k "index")
                  index   (in db key)]
              (string
                `<li class="breadcrumb-item ` (if is-last `active`) `">` 
                  (if index 
                    (string
                      `<a up-follow href="` (router key) `.html">`
                        n
                      `</a>`)
                    n
                )
                `</li>`)))
          paths 
          (range (length paths))))
    `</ol>
  </nav>`
])

(defn nav-bar (home-page app-title) [`
  <nav class="navbar navbar-light bg-light px-3 d-flex justify-content-between">
    <div>
    </div>
    
    <a class="navbar-brand" up-follow href="` home-page `">`
      app-title
   `</a>
    
    <div>
    </div>
  </nav>`])

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

(defn  mu/html-page (db key title-gen article content router app-config)
  (html5 router (title-gen ((article :meta) :title)) app-config `
    <div class="container my-4">
      ` (nav-path router app-config key db) `
      <div class="card">
        <article class="card-body"> 
          ` content `
        </article>
      </div>
    </div>`))

(defn  GoT/html-page (id got page-title svg svg-theme db router app-config)
  (html5 router page-title app-config 
    `<div class="container mt-4 mb-2 d-flex justify-content-center">
    `(nav-path router app-config id db) `
    </div>`
    `<nav class="d-flex justify-content-center">
      <ul class="pagination">
        <li class="page-item">
          <span class="page-link active" role="button">
            <i class="bi bi-layout-split"></i>
            `(dict :both)`
          </span>
        </li>
        <li class="page-item">
          <span class="page-link" role="button">
            <i class="bi bi-share"></i>
            `(dict :graph-first)`
          </span>
        </li>
        <li class="page-item">
          <span class="page-link" role="button">
            <i class="bi bi-card-text"></i>
            `(dict :notes-first)`
          </span>
        </li>
      </ul>
    </nav>

    
    <div class="row gx-2 m-3 mt-0" got 
      data-events='`(to-js (got :events))`'
      data-nodes='`(to-js (got :nodes))`'
      data-anscestors='`(to-js (got :anscestors))`'
    >
      <aside class="col col-5 pt-2">
        <div class="fs-6 mb-3">
          <i class="bi bi-share-fill"></i>
          ` (dict :graph-of-thought) `
        </div>

        <div class="d-flex justify-content-center">
          <div class="d-inline-block bg-light border rounded">
          ` svg `
          </div>
        </div>

        <div class="my-3 d-flex justify-content-center">
          <button role="button" class="mx-1 btn btn-outline-primary" id="reset-progress-action">
            ` (dict :reset) `
            <i class="bi bi-arrow-clockwise"></i>
          </button>
          <button role="button" class="mx-1 btn btn-outline-primary" id="skip-till-end-action">   
            ` (dict :skip) `
            <i class="bi bi-skip-forward"></i>
          </button>
          <button role="button" class="mx-1 btn btn-outline-primary" id="prev-step-action"> 
            ` (dict :prev) `
            <i class="bi bi-arrow-left"></i>
          </button>
          <button role="button" class="mx-1 btn btn-outline-primary" id="next-step-action"> 
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
                    article  (assert (db key) (string "invalid reference: " key))
                    t        (or c :thoughts)
                    summ     (dict t)
                    icon     ({:problem   `bi bi-question-circle`
                               :goal      `bi bi-bullseye`
                               :reason    `bi bi-lightbulb`
                               :recall    `bi bi-floppy`
                               :calculate `bi bi-calculator`
                               :thoughts  `bi bi-chat`
                              } t)
                    color     ((svg-theme :color-map) t)
                    has-link (not (article :private))]
                [
                `<div class="pb-3 content" content="` key `" for="` (e :id)`">
                  <div class="card">
                    <div class="card-header d-flex justify-content-between px-2">
                        <div>`
                          (if summ [
                            `<small class="text-muted d-flex align-items-center">
                              <span class="d-inline-block rounded-circle" style="width: 14px; height: 14px; background-color: ` color ` ;"></span>`

                              `<i class="mx-1 ` icon `"></i>`
                              summ 
                              
                              (if (e :height) 
                                [`<i class="bi bi-triangle ms-3 me-1"></i>`
                                  (e :height)])
                            `</small>`])
                        `</div>
                        <div>`
                          (if has-link [
                            `<a class="text-muted" up-follow href="` (router key) `.html">`
                              `<i class="bi bi-hash"></i>`
                              key
                            `</a>`])
                        `</div>
                      </div>`

                    `<div class="card-body" dir="auto">`
                        (mu/to-html (article :content) router)
                    `</div>`

                    `<div class="card-footer d-flex justify-content-between py-1">
                        <button role="button" class="fold btn btn-sm btn-outline-dark toggle-graph-message-btn">
                          <i class="bi bi-chevron-double-up"></i>
                        </button>
                        <small class="text-muted">`
                          ((article :meta) :title)
                       `</small>
                        <span></span>
                    </div>`

                  `</div>
                </div>`])))
        `</article>
      </aside>
    </div>`))



