[
  (m :explain    :db/ra/join_)
  (n :root       :problem []      :db/intro)

  (m :wtf        :db/ra/join_)

  (n :sigma      :recall  [:root] :db/intro)
  (n :project    :recall  [:root] :db/intro)
  (n :div        :recall  [:root] :db/intro)

  (n :op-1-final :reason  [:div :project :sigma] :db/intro)

  (n :join       :recall  [:root] :db/intro)

  (n :op-2-final :reason  [:join :project :sigma] :db/intro)
  (n :op-3-final :reason  [:join :project :sigma] :db/intro)
  (n :op-4-final :reason  [:join :project :sigma] :db/intro)
  
  (n :goal :goal  [:op-4-final] :db/intro)
]