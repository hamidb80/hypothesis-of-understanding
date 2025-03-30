[
  (m :explain    :db/ra/join)
  (n :root       :problem []      :hello)

  (m :wtf        :db/ra/join)

  (n :sigma      :recall  [:root] :hello)
  (n :project    :recall  [:root] :hello)
  (n :div        :recall  [:root] :hello)

  (n :op-1-final :reason  [:div :project :sigma] :hello)

  (n :join       :recall  [:root] :hello)

  (n :op-2-final :reason  [:join :project :sigma] :hello)
  (n :op-3-final :reason  [:join :project :sigma] :hello)
  (n :op-4-final :reason  [:join :project :sigma] :hello)
  
  (n :goal :goal  [:op-4-final] :hello)
]