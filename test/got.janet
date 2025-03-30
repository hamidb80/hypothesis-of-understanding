(use ../src/helper/io)
(use ../src/helper/path)

(use ../src/graph-of-thought)
(use ../src/lisp-docs)
(use ../src/solution)

# -------------------------------

(def subdir "./notes")

(defn k2p (k)
  (string (path/join subdir k) markup-ext))

(def db (finalize-db (compile-deep subdir) k2p nil))

(defn reff (k)
  (mu/to-html (db (k2p k))))

(def got1 (GoT/init [
  (m :hello)
  (n :root       :problem []      :hello)
  
  (n :sigma      :recall  [:root] :hello)
  (n :project    :recall  [:root] :hello)
  (n :div        :recall  [:root] :hello)

  (n :op-1-final :reason  [:div :project :sigma] :hello)

  (n :join        :recall  [:root] :hello)

  (n :op-2-final :reason  [:join :project :sigma] :hello)
  (n :op-3-final :reason  [:join :project :sigma] :hello)
  (n :op-4-final :reason  [:join :project :sigma] :hello)
  
  (n :goal :goal  [:op-4-final] :hello)
]))

# (pp got1)

(def svg-got1 
  (GoT/to-svg got1 {:radius   16
                  :spacex  100
                  :spacey   80
                  :padx    100
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

(file/put "./play.html" (GoT/to-html got1 svg-got1 reff))
