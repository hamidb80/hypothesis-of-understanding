(use ../src/graph-of-thought)
(use ../src/markup)
(use ../src/solution)

# -------------------------------

(let [
    app-config {:title "2 simple docs"}
    s-conf     (solution-paths "./test/docs/simple-pack" nil "./dist/")
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
                  :goal         "#545454"
                  :recall       "#864AF9"
                  :calculate    "#E85C0D"
                  :reason       "#5CB338" }}]
  (solution s-conf app-config got-style-config))
