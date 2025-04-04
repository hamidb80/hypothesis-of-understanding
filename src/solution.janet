"
integration of GoT and Notes
"

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
(use ./com)

# ------------------------------------------------------

# TODO add tests
# TODO add asset manager and keep track of unreferenced assets
# FIXME cannot load specifit page script

(def partial-file-name-suffix "_")

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
              :partial (string/has-suffix? partial-file-name-suffix (pparts :name))
              :content (let [file-content (try (slurp p)            ([e] (error (string "error while reading from file: " p))))
                             lisp-code    (try (parse file-content) ([e] (error (string "error while parseing lisp code from file: " p))))
                             result       (try (eval  lisp-code)    ([e] (error (string "error while evaluating parseing lisp code from file: " p))))]
                          result)}))))
    acc))

# HTML Conversion ------------------------
(defn  mu/html-page (key str router app-config)
  (flat-string `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title>` key `</title>` 
        common-head 
    `</head>
    <body>

    ` (nav-bar (router "") (app-config :title)) `
    
    <main class="container my-4">

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
          ` str `
        </article>
      </div>
      
    </main>
    </body>
    </html>`))

(defn  GoT/html-page (got page-title svg svg-theme db router app-config)
  (flat-string `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title> ` page-title ` </title>
        ` common-head `
    </head>
    <body>
    
    ` (nav-bar (router "") (app-config :title)) `

    <main>
      <div class="row gx-2 m-3" got>
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
      </div>
    </main>

    </body>

    <script>

      function nodeClass(id, dot = true){
        return (dot ? '.' : '') + 'node-' + id
      }

      function qa(sel){
        return [...document.querySelectorAll(sel)]
      }

      function q(sel){
        return document.querySelector(sel)
      }

      function clsx(el, cond, cls){
        if (cond)
          el.classList.add(cls)
        else
          el.classList.remove(cls)
      } 
      
      function clearDisplay(el){
        el.classList.add("d-none")
      }
      
      function hide(el){
        el.classList.add("invisible")
      }
      
      function show(el){
        el.classList.remove("invisible")
        el.classList.remove("d-none")
      }

      function scrollToElement(wrapper, target, behavior = 'smooth') {
        switch (behavior) {
            case 'smooth':
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                break;
            case 'instant':
                target.scrollIntoView();
                break;
            case 'center':
                const rect = target.getBoundingClientRect();
                const containerRect = wrapper.getBoundingClientRect();
                
                const offsetTop = rect.top + wrapper.scrollTop - 
                              (containerRect.height / 2 - rect.height / 2);
                
                wrapper.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
                break;
          }
      }

      function highlightNode(el){
        el.setAttribute("stroke", "`(svg-theme :stroke-color)`")
        el.setAttribute("stroke-width", "4")
      }
      function blurNode(el){
        el.removeAttribute("stroke")
        el.removeAttribute("stroke-width")
      }

      function getParam(key, dflt) {
        const  l = new URLSearchParams(window.location.search)
        return l.get(key) || dflt
      }
      function setParam(key, val) {
        let u = new URLSearchParams(window.location.search)
        u.set(key, val)
        up.history.replace(window.location.pathname + "?" + u.toString(), {})
      }

      function clamp(n, max, min){
        return Math.min(max, Math.max(n, min))
      }

      // ----------------------------------------      

      up.compiler('[got]', _ => {
        console.log("hey")
        const cursorName = 'c' 

        const events     = `(to-js (got :events))`
        const nodes      = `(to-js (got :nodes))`
        const anscestors = `(to-js (got :anscestors))`
        let cursor
        
        function focusNode(el) {
          let id  = el ? el.getAttribute("node-id") : ""
          let ans = el ? anscestors[id] : []

          qa(".node").forEach(e => {
            let pid = e.getAttribute("node-id")
            if (id == pid) highlightNode(e)
            else           blurNode(e)
            clsx(e, id != pid  && !ans.includes(pid), "opacity-25")
          })
          qa(".edge").forEach(e => {
            let pid = e.getAttribute("to-node-id")
            clsx(e, id != pid  && !ans.includes(pid), "opacity-25")
          })
        }
        
        function unfocusAll(){
          qa(".content").forEach(e => clsx(e, false, "opacity-25"))
          qa(".node").forEach(e =>    {clsx(e, false, "opacity-25"); blurNode(e)})
          qa(".edge").forEach(e =>    clsx(e, false, "opacity-25"))
        }

        function unversalStep(step){
          let sel
          let c 

          for (let i = 0; i < events.length; i ++){
            let e = events[i]
            let sel = "[for='" + e.id + "']" 
            let c = q(sel)

            clsx(c, step <  i, "d-none")
            clsx(c, step != i, "opacity-25")
            
            if (step == i)
              scrollToElement(q(".content-bar"), c)

            if (e.kind == "node"){
              let n = q(nodeClass(e.id))
              clsx(n, step < i, "d-none")
              
              let ed = qa("[to-node-id='"+ e.id   +"']")
              if (ed.length) ed.forEach(el => clsx(el, step < i, "d-none"))
            }
          }
        }

        function setCursor(c){
          c = clamp(parseInt(c), events.length - 1, -1)
          setParam(cursorName, c)
          return cursor = c
        }

        function resetProgress(){
          unversalStep(setCursor(-1))
        }
        function skipTillEnd(){
          unversalStep(setCursor(events.length))
        }
        function nextStep(){
          unversalStep(setCursor(cursor + 1))
        }
        function prevStep(){
          unversalStep(setCursor(cursor - 1))
        }

        function prepare(){
          qa(".node").forEach(el => {

            el.onmouseenter = () => {
              focusNode(el)

              let id  = el.getAttribute("node-id")
              let ans = anscestors[id]
              
              qa(".content").forEach(el => 
                clsx(el, el.getAttribute("for") != id, "opacity-25"))

              scrollToElement(q(".content-bar"), q("[for="+id+"]"))
            }

            el.onmouseleave = () => {
              unfocusAll()
            }
          })

          qa(".content").forEach(el => {
            el.onmouseenter = () => {
              let nodeId = el.getAttribute("for")
              focusNode(q(nodeClass(nodeId)))
              qa(".content").forEach(e => clsx(e, e != el, "opacity-25"))
            }

            el.onmouseleave = () => {
              unfocusAll()
            }
          })

          q('#reset-progress-action').onclick = resetProgress
          q("#skip-till-end-action").onclick = skipTillEnd
          q("#prev-step-action").onclick = prevStep
          q("#next-step-action").onclick = nextStep
        }

        function keyboardEvent(e) {
          if (e.key == "ArrowRight") nextStep()
          if (e.key == "ArrowLeft")  prevStep()
        }

        function delayedInit () {
          window.addEventListener("keyup", keyboardEvent)
        }
        function run () {
          unversalStep(cursor)
        }
        function init () {
          setCursor(parseInt(getParam(cursorName, 0)))
          prepare()
          run()
        }
        function destructor () {
          window.removeEventListener("keyup", keyboardEvent)
        }

        // -----------------------------

        init()
        setTimeout(delayedInit, 150)
        return destructor
      })

      up.compiler('.latex', el => {
        katex.render(el.innerText, el, { displayMode: true })
      })

    </script>

    <style>
      button {
        cursor: pointer;
      }
      .node {
        cursor: pointer;
      }

    </style>
    </html>`))
