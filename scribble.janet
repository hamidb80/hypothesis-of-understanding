(defn string/in (str ch)
  (var result false)
  (for i 0 (length str)
    (if (= ch (str i)) 
      (break (set result true))))
  result)

(defn is-whitespace (ch)
  (string/in "\n\v\r\f\t " ch))

(defn is-grouping (ch)
  (string/in "(){}[]" ch))

(defn is-ctx-changer (ch)
  (= (chr "@") ch))

# --------------------------

(defn parse-ident (str i)
  (var j i)
  (while (not= j (length str))
    (if (or (is-grouping   (str j)) 
            (is-whitespace (str j)))
        (break))
    (++ j))
  [j (string/slice str i j)])

# --------------------------

(defn lex-scribble (str)
  (var i            0)
  (var mode         :text-mode)
  (var state-stack [:init])
  
  (while (< i (length str))
    (when (is-ctx-changer (str i))
      (def cmd (parse-ident str i))
      (pp cmd)
      )
    (++ i))
  )

(defn parse-scribble-tokens (tokens)
  tokens)

(defn parse-scribble (txt)
  (parse-scribble-tokens (lex-scribble txt)))

(pp (parse-scribble (slurp "./play.scribble")))

# expected output
[
  [:cmd "title"]
  [:open-curly]
  [:txt "Children story"]
  [:close-curly]
  [:txt "if you give a mouse a cookie"]
]