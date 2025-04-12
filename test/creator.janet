(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(if (< (length (dyn *args*)) 2)
  (error "invalid number of arguments, required at least 2")
  (let [
    app-config {:title "Konkur Computer" :root-title "home"}
    # s-conf     (solution-paths "./play/notes/" "./play/assets/" "./konkur-comp/" "/konkur-comp/")
    s-conf     (solution-paths ;(slice (dyn *args*) 1))
    got-style-config {
      :radius   16
      :spacex  100
      :spacey   80
      :padx    100
      :pady     50
      :stroke    4
      :node-pad  6
      :background nil
      :stroke-color             "#424242"
      :color-map {:problem      "#545454"
                  :quite        "transparent"
                  :goal         "#545454"
                  :recall       "#864AF9"
                  :calculate    "#E85C0D"
                  :reason       "#5CB338" }}]
  (solution s-conf app-config got-style-config)))
