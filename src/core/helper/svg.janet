# Scalable Vector Graphic (SVG) utilities

(defn svg/normalize (c)
  (match (type c)
          :array  (string/join c " ")
          :string              c))

(defn to-xml-attrs (attrs)
  (let [acc @[]]
    (eachp [k v] attrs
      (array/push acc (string k `="` v `"`)))
    (string/join acc " ")))

(defn svg/inline [tag attrs]
   (string `<` tag ` ` (to-xml-attrs attrs) `/>`))

(defn svg/wrap [ox oy w h content]
  (string 
    `<svg 
      xmlns="http://www.w3.org/2000/svg"
      viewBox="`ox` `oy` ` w ` ` h `"
      width="` w`"
      height="`h`"
    >`
      (svg/normalize content)
    `</svg>`))

(defn svg/group [content]
  (string 
    `<g` `>` 
      (svg/normalize content) 
    `</g>`))
