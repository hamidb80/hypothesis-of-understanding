[
  (n :root       1 :problem []      :index)
  (m :wtf                         :child)

  (n :sigma      1 :recall  [:root] :index)
  (n :project    1 :recall  [:root] :child)
  (n :div        1 :recall  [:root] :index)

  (n :op-1-final 1 :reason  [:div :project :sigma] :index)

  (n :join       1 :recall  [:root]                :child)

  (n :op-2-final 1 :reason  [:join :project :sigma] :index)
  (n :op-3-final 1 :reason  [:join :project :sigma] :index)
  (n :op-4-final 1 :reason  [:join :project :sigma] :index)
  
  (n :goal       1 :goal  [:op-4-final] :child)
]