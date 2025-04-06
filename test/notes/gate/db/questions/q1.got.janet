[
  (n :root       :problem []      :db/concepts/intro)
  (m :wtf        :db/concepts/ra/join_)

  (n :sigma      :recall  [:root] :db/concepts/intro)
  (n :project    :recall  [:root] :db/concepts/intro)
  (n :div        :recall  [:root] :db/concepts/intro)

  (n :op-1-final :reason  [:div :project :sigma] :db/concepts/intro)

  (n :join       :recall  [:root] :db/concepts/intro)

  (n :op-2-final :reason  [:join :project :sigma] :db/concepts/intro)
  (n :op-3-final :reason  [:join :project :sigma] :db/concepts/intro)
  (n :op-4-final :reason  [:join :project :sigma] :db/concepts/intro)
  
  (n :goal :goal  [:op-4-final] :db/concepts/intro)
]