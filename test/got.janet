(use ../src/helper/io)
(use ../src/graph-of-thought)

(def message-db {
  :welldone (c nil "به جواب رسیدیم")
  
  :focus (c nil `
    خب از سوال معلومه که در مورد 
    جبر رابطه ای هست
  `)

  :init (c nil `
    گزینه 1 رو بررسی میکنیم  
  `)

  :div-operator (c nil `
      یادته تقسیم چیکار میکرد؟
    ` )
  :project-operator (c nil `\prod_{}^{}`)
  :sigma-operator (c nil `
      سیگما
    ` )

  :join-operator (c nil `
      جوین
    ` )

  :op-1 (c nil `
      این گزینه بهمون همه کتاب هایی رو میده که توسط همه افراد بالای 18 سال به امانت گرفته شدن
      پس چیزی نیست که ما میخوایم
    `)
  :op-2 (c nil `
      این گزینه بهمون همه کتاب های آقای احمدی ای رو میده که توسط حداقل یک آدم 18 ساله وکوچکتر به امانت گرفته شده
      پس چیزی نیست که ما میخوایم
    `)
  :op-3 (c nil `پس چیزی نیست که ما میخوایم`)
  :op-4 (c nil `
      این گزینه بهمون همه کتاب های آقای احمدی رو میده که توسط هیچ 18 به بالا امانت گرفته نشده.
    `)
})

(def got1 (GoT/init [
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

(file/put "./play.html" (GoT/to-html got1 svg-got1 message-db))
