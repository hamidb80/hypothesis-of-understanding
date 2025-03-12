# GoT (Graph of Thought) is a DAG (Direct Acyclic Graph)
# colors stolen from https://colorhunt.co/
# ----------- debugging
(defn inspect (a) 
  (pp a)
  a)

(defn inspects (a) 
  (print a)
  a)

# ------------ files 
(defn file/put (path content)
  (def        f (file/open path :w))
  (file/write f content)
  (file/close f))

(defn file/exists (path) 
  (not (nil? (os/stat path))))

# ---------- vector arithmatic
# (defn zip (a b) (map tuple a b))
(defn v+    (v1 v2) 
  (map + v1 v2))

(defn v-    (v1 v2) 
  (map - v1 v2))

(defn v* (scalar v) 
  (map (fn (x) (* x scalar)) v))

(defn v-mag     (v) 
  (math/sqrt (reduce + 0 (map * v v))))

(defn v-norm    (a) 
  (v* (/ 1 (v-mag a)) a))

# ---------- JSON
(defn join-map (lst f)
  (string/join (map f lst)))

(defn to-js (data)
  (defn table-like (t) (string 
      `{` 
      (join-map (keys t) (fn (k) (string (to-js k) `: ` (to-js (t k)) `,`))) 
      `}`))

  (defn array-like (t) (string `[` 
      (join-map data (fn (v) (string (to-js v) `,`))) 
    `]`))

  (match (type data)
    :table  (table-like data)
    :struct (table-like data)
    :array  (array-like data)
    :tuple  (array-like data)

    :keyword (string `"` data `"`)
    :string  (string `"` data `"`)
    :number  (string     data)
    :boolean (string     data)
    :nil     "null"
    ))

# ---------- pure svg thing
(defn svg/normalize (c)
  (match (type c)
          :array  (string/join c " ")
          :string              c))

(defn to-xml-attrs (attrs)
  (let [acc @[]]
    (eachp [k v] attrs
      (array/push acc (string k `="` v `"`)))
    (string/join acc " ")))

(defn svg/rect [x y w h c]
   (string `<rect 
      x="`x`" 
      y="`y`" 
      width="`w`" 
      height="`h`" 
      fill="`c`" 
    />`))

(defn svg/wrap [ox oy w h b content]
  (string 
    `<svg 
      xmlns="http://www.w3.org/2000/svg"
      viewBox="`ox` `oy` ` w ` ` h `"
      width="` w`"
      height="`h`"
    >`
      (if b (svg/rect 0 0 w h b))
      (svg/normalize content)
    `</svg>`))

(defn svg/group [content]
  (string 
    `<g` `>` 
      (svg/normalize content) 
    `</g>`))

(defn svg/circle [x y r fill &opt attrs]
  (string 
    `<circle 
      r="` r`" 
      cx="`x`" 
      cy="`y`" 
      fill="`fill`" `
      (if attrs (to-xml-attrs attrs))
      `/>`))

(defn svg/line [p g w fill &opt attrs]
  (string 
    `<line 
      x1="` (first p) `" 
      y1="` (last  p) `" 
      x2="` (first g) `" 
      y2="` (last  g) `" 
      stroke-width="` w `"
      stroke="` fill `"
      ` (if attrs (to-xml-attrs attrs)) `/>`))

# ----------- random helpers
(defn not-nil-indexes (row)
  (let [acc @[]]
    (eachp [i n] row
      (if n (array/push acc i)))
    acc))

(defn keep-ends (lst) 
    [(first lst) (last lst)])

(defn range-len (indicies)
  (+ 1 (- (last indicies) (first indicies))))

(defn to-table (lst key-generator)
  (let [acc @{}]
      (each n lst (put acc (key-generator n) n))
      acc))

(defn avg (lst)
  (/ (reduce + 0 lst) (length lst)))

# ---------- matrix 
(defn matrix-size (rows)
  [ (length rows) 
    (reduce max 0 (map length (values rows)))])

(defn matrix-of (rows cols val)
  (map (fn [_] (array/new-filled cols)) (range rows)))

(defn get-cell [grid y x]
  ((grid y) x))

(defn put-cell [grid y x val]
  (put (grid y) x val))

# ---------- domain
(defn node-class (id)
  (string "node-" id))

(defn positioned-item (n r c rng rw) 
  {:node n :row r :col c :row-range rng :row-width rw})

(defn GoT/to-svg-impl (got) # extracts nessesary information for plotting
  (let [acc @[]]
    (eachp [l nodes] (got :grid)
      (eachp [i n] nodes
        (let [idx (not-nil-indexes nodes)]
          (if n (array/push acc (positioned-item n l i (keep-ends idx) (range-len idx)))))))
    acc))

(defn GoT/svg-calc-pos (item got cfg ctx)
    [(+ (cfg :padx) (* (cfg :spacex)    (got :width)  (* (/ 1 (+ 1 (item :row-width))) (+ 1 (- (item :col) (first (item :row-range))))) ) (* -1 (ctx :cutx))) 
     (+ (cfg :pady) (* (cfg :spacey) (- (got :height) (item :row) 1)))])

(defn GoT/to-svg [got cfg]
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
          (array/push acc (svg/circle (first pos) (last pos) (cfg :radius) ((cfg :color-map) (((got :nodes) (item :node)) :class)) {:class (string "node " (node-class (item :node)))}))))
      
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
          (array/push acc (svg/line h t (cfg :stroke) (cfg :stroke-color) {:class (string "edge " (node-class to))}))))
    
      (reverse acc))))

(defn rev-table [tab]
  (def acc @{})
  (eachp (k v) tab
    (let [lst (acc v)]
         (if (nil? lst)
              (put acc v @[k])
              (array/push lst k))))
  acc)

(defn GoT/build-levels [events]
  (def  levels @{})
  (each e events 
    (match (e :kind)
           :message nil
           :node     (put levels (e :id) (+ 1 (reduce max 0 (map levels (e :ans)))))))
  levels)

(defn GoT/extract-edges [events]
  (let [acc @[]]
       (each e events
          (match (e :kind)
            :node (each a (e :ans)
                    (array/push acc [a (e :id)]))))
       acc))

(defn GoT/init-grid [rows]
  (let [size (matrix-size rows)]
       (matrix-of (first size) (last size) nil)))


(defn GoT/place-node (grid size levels node selected-row parents)
  # places and then returns the position
  (def height (first size))
  (def width  (last size))
  
  (def parents-col (map (fn [p] (let [row (dec (levels p))
                        col (find-index (fn [y] (= y p)) (grid row))] 
                        col)) 
                    parents))
 
  (def center (/ (if (even? width) width (inc width)) 2))
  (def avg-parents-col (if (empty? parents) center (avg parents-col)))

  (var i (math/floor avg-parents-col))
  (var j (math/ceil avg-parents-col))

  (while true 
    (cond
      (nil? (get-cell grid selected-row i)) (break (put-cell grid selected-row i node))
      (nil? (get-cell grid selected-row j)) (break (put-cell grid selected-row j node))
            (do 
              (set i (max 0           (dec i)))
              (set j (min (dec width) (inc j)))))))

(defn GoT/fill-grid (events levels)
  (let [rows  (rev-table   levels)
        shape (matrix-size rows)
        grid  (GoT/init-grid rows)]
    (each e events
      (match (e :kind)
        :node (GoT/place-node grid shape levels (e :id) (dec (levels (e :id))) (e :ans) )))
    grid))


(defn GoT/init [events] 
  (let [levels   (GoT/build-levels events)
        grid     (GoT/fill-grid    events levels)]
        {:events events
         :levels levels
         :grid   grid
         :nodes  (to-table events (fn [e] (if (= :node (e :kind)) (e :id))))
         :edges  (GoT/extract-edges events)
         :height (length grid) 
         :width  (length (grid 0))}))

(defn GoT/to-html (got svg)
  (string `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title> Name </title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    </head>
    <body>
      <main class="container">
        <div class="my-4">
          <button class="btn btn-primary" onclick="init()">   init/reset </button>
          <button class="btn btn-primary" onclick="goPrev()"> prev </button>
          <button class="btn btn-primary" onclick="goNext()"> next </button>
        </div>
        <center>
        ` svg `
        </center>

        <div class="my-3">
          <div class="card">
            <div class="card-body">
              <p class="content p-0 m-0"></p>
            </div>
          </div>
        </div>

      </main>

    </body>

    <script>
      const events  = `(to-js (got :events))`
      let cursor

      // ------------------ states

      function qa(sel){
        return [...document.querySelectorAll(sel)]
      }

      function q(sel){
        return document.querySelector(sel)
      }

      function hide(el){
        el.style.visibility="hidden"
      }
      
      function show(el){
        el.style.visibility= "visible"
      }

      function init(){
        cursor = -1
        qa(".node").forEach(hide)
        qa(".edge").forEach(hide)
      }

      // -----------------------

      function nodeClass(id){
        return '.node-' + id
      }

      function goNext(){
        cursor ++
        let e = events[cursor]
        if (e){
          if (e.kind == 'node') {
            qa(nodeClass(e.id)).forEach(show)
          }
          else {
            q('.content').innerText = e.content
          }
        }
      }
      function goPrev(){
        qa(nodeClass(e.id)).forEach(hide)
        cursor --
      }
    </script>

    <style>
      button {
        cursor: pointer;
      }
      .node {
        cursor: pointer;
      }

      .node:hover {
        opacity: 0.5;
      }

      svg {
        border: 1px solid black;
      }
    </style>
    
    </html>`))

(defn n [id class anscestors contents] # node
  # :problem :recall :reason :calculate
  {:kind  :node 
   :id    id
   :class class 
   :ans   anscestors})

(defn m [content] # question or hint
  {:kind    :message 
   :content content})

# ---------- test
(def c {
  :hello    "hi"
  :h1    "h1"
  :h2    "h2"
  :h3    "h3"
  :h4    "h4"
  :h5    "h5"
  :h6    "h6"
  :welldone "well done"
})

(def p1 (GoT/init [
  (m  (c :hello))
  (n :root :problem [] [(c :hello)])
  (m  (c :h1))
  (n :t1 :recall [:root] [(c :hello)])
  (m  (c :h2))
  (n :t22 :calculate [:root] [(c :hello)])
  (m  (c :h3))
  (n :t2 :reason [:t1 :t22] [(c :hello)])
  (m  (c :h4))
  (n :t23 :recall [:root] [(c :hello)])
  (m  (c :h5))
  (n :t4 :reason [:t23] [(c :hello)])
  (m  (c :h6))
  (n :t5 :goal [:t4 :t2] [(c :hello)])
  (m  (c :welldone))
]))

(pp p1)

(def svg-p1 
  (GoT/to-svg p1 {:radius   16
                  :spacex  100
                  :spacey   80
                  :padx     50
                  :pady     50
                  :stroke    4
                  :node-pad  6
                  :background nil # "black"
                  :stroke-color          "#212121"
                  :color-map {:problem   "#212121"
                              :goal      "#212121"
                              :recall    "#864AF9"
                              :calculate "#E85C0D"
                              :reason    "#5CB338" }}))

(file/put "./play.html" (GoT/to-html p1 svg-p1))
