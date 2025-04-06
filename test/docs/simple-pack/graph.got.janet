[
  (n :root       :problem []      :index)
  (m :wtf                         :child)

  (n :sigma      :recall  [:root] :index)
  (n :project    :recall  [:root] :child)
  (n :div        :recall  [:root] :index)

  (n :op-1-final :reason  [:div :project :sigma] :index)

  (n :join       :recall  [:root]                :child)

  (n :op-2-final :reason  [:join :project :sigma] :index)
  (n :op-3-final :reason  [:join :project :sigma] :index)
  (n :op-4-final :reason  [:join :project :sigma] :index)
  
  (n :goal :goal  [:op-4-final] :child)
]