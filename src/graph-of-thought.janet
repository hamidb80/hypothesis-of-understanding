(use ./helper/debug)

(use ./helper/stat)
(use ./helper/vector)
(use ./helper/matrix)
(use ./helper/io)
(use ./helper/js)
(use ./helper/str)
(use ./helper/iter)
(use ./helper/range)
(use ./helper/tab)
(use ./helper/svg)
(use ./helper/macros)

(use ./com)
(use ./locales)
(use ./markup)

# defs ------------------------

(def got-ext ".got.janet") # graph of thought representation in Janet lisp format

# public interface ------------------------
(defn n [id class parents content] # [n]ode
  # :problem :recall :reason :calculate
  {:kind     :node 
   :id       id
   :class    class 
   :parents  parents
   :content  content})

(defn m [id content] # [m]essge, question or hint
  {:kind    :message 
   :id       id
   :content content})

# SVG Convertsion ------------------------
(defn- node-class (id)
  (string "node-" id))

(defn- positioned-item (n r c rng rw) {
   :node      n 
   :row       r 
   :col       c 
   :row-range rng 
   :row-width rw})

(defn- GoT/to-svg-impl (got) # extracts nessesary information for plotting
  (let-acc @[]
    (eachp [l nodes] (got :grid)
      (eachp [i n] nodes
        (let [idx (not-nil-indexes nodes)]
          (if n (array/push acc (positioned-item n l i (keep-ends idx) (range-len idx)))))))))

(defn- GoT/svg-calc-pos (item got cfg ctx)
    [(+ (cfg :padx) (* (cfg :spacex)    (got :width)  (* (/ 1 (+ 1 (item :row-width))) (+ 1 (- (item :col) (first (item :row-range))))) ) (* -1 (ctx :cutx))) 
     (+ (cfg :pady) (* (cfg :spacey) (- (got :height) (item :row) 1)))])

(defn  GoT/to-svg [got cfg]
  (def cutx (/ (* (got :width) (cfg :spacex)) (+ 1 (got :width))))

  (svg/wrap 0 0
    (- (+ (* 2 (cfg :padx)) (* (+  0 (got :width))  (cfg :spacex))) (* 2 cutx))
    (- (+ (* 2 (cfg :pady)) (* (+ -1 (got :height)) (cfg :spacey))) 0) 

    (cfg :background)
    
    (let [acc  @[]
          locs @{}
          ctx  {:cutx cutx}]
      
      (each item (GoT/to-svg-impl got)
        (let [pos (GoT/svg-calc-pos item got cfg ctx)]
          (put locs   (item :node) pos)
          (array/push acc (svg/circle (first pos) (last pos) (cfg :radius) ((cfg :color-map) (((got :nodes) (item :node)) :class)) {:node-id (item :node) :class (string/join ["node" (string "node-class-" (((got :nodes) (item :node)) :class)) (node-class (item :node))] " ")}))))
      
      (each e (got :edges)
        (let [from (first e)
              to   (last  e)
              head (locs from)
              tail (locs to)
              vec  (v- tail head)
              nv   (v-norm vec)
              diff (v* (+ (cfg :node-pad) (cfg :radius)) nv)
              h    (v+ head diff)
              t    (v- tail diff)]
          (array/push acc (svg/line h t (cfg :stroke) (cfg :stroke-color) {:from-node-id from :to-node-id to :class (string "edge " (node-class to))}))))
    
      acc)))

# extract visual infos ------------------------
(defn- GoT/build-levels [events]
  (def  levels @{})
  (each e events 
    (match (e :kind)
           :message nil
           :node     (put levels (e :id) (+ 1 (reduce max 0 (map levels (e :parents)))))))
  levels)

(defn- GoT/extract-edges [events]
  (let-acc @[]
       (each e events
          (match (e :kind)
            :node (each a (e :parents)
                    (array/push acc [a (e :id)]))))))

(defn- GoT/init-grid [rows]
  (let [size (matrix-size rows)]
       (matrix-of (first size) (last size) nil)))

(defn- GoT/place-node (grid size levels node selected-row parents)
  # places and then returns the position
  (def height (first size))
  (def width  (last size))
  
  (def parents-col (map 
    (fn [p] 
      (let [row (dec (levels p))
            col (find-index (fn [y] (= y p)) (grid row))]
        col)) 
    parents))
 
  (def center (min (dec width) (/ (if (even? width) width (inc width)) 2)))
  (def avg-parents-col (if (empty? parents) center (avg parents-col)))

  (var i (math/floor avg-parents-col))
  (var j (math/ceil  avg-parents-col))

  (while true 
    (let [left  (max 0           i)
          right (min (dec width) j)]
      (cond
        (nil? (get-cell grid selected-row left )) (break (put-cell grid selected-row left  node))
        (nil? (get-cell grid selected-row right)) (break (put-cell grid selected-row right node))
              (do 
                (-- i)
                (++ j))))))

(defn- GoT/fill-grid (events levels)
  (let [rows  (rev-table   levels)
        shape (matrix-size rows)
        grid  (GoT/init-grid rows)]
    (each e events
      (match (e :kind)
        :node (GoT/place-node grid shape levels (e :id) (dec (levels (e :id))) (e :parents) )))
    grid))

(defn- GoT/all-anscestors (topological-sorted-node-ids nodes-tab)
  (let-acc @{}
    (each node topological-sorted-node-ids
      (let [ac @{}]
        (each a ((nodes-tab node) :parents)
          (put ac a 1)
          (each aa (acc a)
            (put ac aa 1)))
      (put acc node (keys ac))))))

(defn  GoT/init [events]
  (assert (= (length events) (length (distinct (map |($ :id) events))))
          "all events must have unique ids") 

  (let [levels            (GoT/build-levels events)
        grid              (GoT/fill-grid    events levels)
        nodes             (to-table events (fn [e] (if (= :node (e :kind)) (e :id))) identity)]
        {:events          events
         :levels          levels
         :grid            grid
         :nodes           nodes
         :anscestors      (GoT/all-anscestors (filter identity (flatten grid)) nodes)
         :edges           (GoT/extract-edges events)
         :height          (length grid) 
         :width           (length (grid 0))}))

# HTML Conversion ------------------------
(defn  GoT/to-html (got svg svg-theme db router app-config)
  (def title "graph of thought")

  (flat-string `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title> ` title ` </title>
        ` common-head `
    </head>
    <body>
    
    ` (nav-bar (router "") (app-config :title)) `

    <main class="row gx-2 m-3" got>
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
