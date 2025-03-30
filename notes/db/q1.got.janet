[
  (m :focus)
  (n :root       :problem []      :init)
  
  (n :sigma      :recall  [:root] :sigma-operator)
  (n :project    :recall  [:root] :project-operator)
  (n :div        :recall  [:root] :div-operator)

  (n :op-1-final :reason  [:div :project :sigma] :op-1)

  (n :join        :recall  [:root] :join-operator)

  (n :op-2-final :reason  [:join :project :sigma] :op-2)
  (n :op-3-final :reason  [:join :project :sigma] :op-3)
  (n :op-4-final :reason  [:join :project :sigma] :op-4)
  
  (n :goal :goal  [:op-4-final] :op-4)
]
