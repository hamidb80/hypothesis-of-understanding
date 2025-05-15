(use 
  ./helper/debug
  ./helper/stat
  ./helper/vector
  ./helper/matrix
  ./helper/io
  ./helper/js
  ./helper/str
  ./helper/random
  ./helper/iter
  ./helper/range
  ./helper/tab
  ./helper/svg
  ./helper/macros)

# public interface ------------------------

(def max-height 4)
(defn n [id height class parents content] # [n]ode
  # :problem :goal :recall :reason :calculate :quite
  {:kind     :node 
   :id       id
   :height   (do (assert (<= 1 height max-height) (string "the height of a node must be in range of 1.." max-height))
                 height)
   :class    class 
   :parents  parents
   :content  content})

(defn q [id nodes content] # [m]essge, question or hint
  {:kind    :message
   :id      id
   :nodes   nodes
   :content content})

# SVG Convertsion ------------------------
(defn got-node-class (id)
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
    [(+ (cfg :padx) (* (cfg :spacex)    (got :canvas-width)  (* (/ 1 (+ 1 (item :row-width))) (+ 1 (- (item :col) (first (item :row-range))))) ) (* -1 (ctx :cutx))) 
     (+ (cfg :pady) (* (cfg :spacey) (- (got :canvas-height) (item :row) 1)))])

(defn- chop-into (len slices max)
  (let [m (- max slices -1)
        a (flatten [m (dup [1 m] (- slices 1))])] 
    (v* (/ len (sum a)) a)))

(defn  GoT/to-svg [got cfg]
  (def cutx (/ (* (got :canvas-width) (cfg :spacex)) (+ 1 (got :canvas-width))))

  (svg/wrap 0 0
    (- (+ (* 2 (cfg :padx)) (* (+  0 (got :canvas-width))  (cfg :spacex))) (* 2 cutx))
    (- (+ (* 2 (cfg :pady)) (* (+ -1 (got :canvas-height)) (cfg :spacey))) 0) 
    
    (let [acc  @[]
          locs @{}
          ctx  {:cutx cutx}]
      
      (each item (GoT/to-svg-impl got)
        (let [pos (GoT/svg-calc-pos item got cfg ctx)]
          (put locs   (item :node) pos)
          (array/push acc (svg/inline :circle  {
              :cx     (first pos)
              :cy     (last pos)
              :r      (cfg :radius) 
              :fill   ((cfg :color-map) (((got :nodes) (item :node)) :class))
              :role    "button" 
              :node-id (item :node) 
              :type    "node"
              :class (string/join [
                "node" 
                (string "node-class-" (((got :nodes) (item :node)) :class)) 
                (got-node-class (item :node))] 
              " ")}))))
      
      (each me (got :events)
        (match (me :kind)
            :message 
              (let [gr @[
                "<g 
                  class='message " (got-node-class (me :id)) "'"
                  (string "node-id='" (me :id) "'") ">"
                  ]
                ]
                (each n (me :nodes)
                  (array/push gr (svg/inline :circle {
                      :cx           (first (locs  n)) 
                      :cy           (last (locs  n)) 
                      :r            (+ (cfg :radius) (* 2 (cfg :stroke)))
                      :fill         ((cfg :color-map) :thoughts) 
                      :role         "button" 
                      :type         "thought"
                      :stroke       (cfg :stroke-color)
                      :stroke-width (cfg :stroke) 
                      :stroke-dasharray "10,12"})))

                (array/push gr "</g>")
                  (array/insert acc 0 (svg/normalize gr)))))
      

      (each e (got :edges)
        (let [from (first e)
              to   (last  e)
              head (locs from)
              tail (locs to)
              vec  (v- tail head)
              nv   (v-norm vec)
              diff (v* (+ (cfg :node-pad) (cfg :radius)) nv)
              h    (v+ head diff)
              t    (v- tail diff)
              len  (v-mag (v- h t))
              lvl  (((got :nodes) to) :height)]
          (array/push acc (svg/inline :line {
              :x1 (first h) 
              :y1 (last  h) 
              :x2 (first t) 
              :y2 (last  t) 
              :stroke-width     (cfg :stroke) 
              :stroke           (cfg :stroke-color) 
              :stroke-dasharray (string/join (map string (chop-into len lvl max-height)) " ")
              :from-node-id from 
              :to-node-id   to 
              :class        (string "edge " (got-node-class to))
            }))))
    
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

  (let [levels                 (GoT/build-levels events)
        grid                   (GoT/fill-grid    events levels)
        nodes                  (to-table events (fn [e] (if (= :node (e :kind)) (e :id))) identity)]
        {:events               events
         :levels               levels
         :grid                 grid
         :nodes                nodes
         :anscestors           (GoT/all-anscestors (filter identity (flatten grid)) nodes)
         :edges                (GoT/extract-edges events)
         :nodes-height-range   (let [e (filter |(not (nil? $)) (map |($ :height) events))]
                                 [(min ;e) (max ;e)])
         :canvas-height        (length grid) 
         :canvas-width         (length (grid 0))}))
