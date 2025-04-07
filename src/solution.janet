"
integration of GoT and Notes
"

(use ./helper/debug)
(use ./helper/io)
(use ./helper/path)
(use ./helper/tab)
(use ./helper/str)

(use ./locales)
(use ./markup)
(use ./graph-of-thought)
(use ./html-gen)

# TODO keep track of unreferenced assets
# ------------------------------------------------------
(def markup-ext ".mu.janet") # markup language in Janet lisp format
(def got-ext    ".got.janet") # graph of thought representation in Janet lisp format
(def private-suffix "_")

(defn got/scan-events (db events ref-count)
  # count only private ones, because public notes must be accessible from root note somehow
  (each e events
    (if ((db (e :content)) :private) 
      (put+ ref-count (e :content)))))

(defn finalize-db (db index-key assets-db)
  (let [acc        @{}
        resolved?  @{}
        ref-count (zipcoll (keys db) (array/new-filled (length db) 0))]
    
    (eachp [id entity] db
      (put acc id 
        (put entity :content 
          (match (entity :kind)
                  :note (mu/finalize-content db (entity :content) entity assets-db ref-count resolved?)
                  :got  (do
                          (got/scan-events   db (entity :content)                  ref-count)
                          (entity :content))))))

    (if index-key (do 
      (put+ ref-count index-key)
      (pp ref-count)
      (let [zero-refs (map |($ 0) (filter (fn [[k c]] (= 0 c)) (pairs ref-count)))]
        (assert (empty? zero-refs) (string "there are notes that are not referenced at all: " (string/join zero-refs ", "))))))

    acc))

(defn req-files (output-dir)
  (let [current-dir ((path/split (dyn *current-file*)) :dir)]
  (file/put (path/join output-dir "page.js")   (slurp  (path/join current-dir "./src/page.js")))
  (file/put (path/join output-dir "style.css") (slurp  (path/join current-dir "./src/style.css")))))

(defn load-deep (root)
  "
  find all markup/GoT files in the `dir` and load them.
  "
  (let [acc @{}
        root-dir (path/dir root)]
    
    (each p (os/list-files-rec root-dir)
      (let [pparts    (path/split p)
            kind (cond 
                  (string/has-suffix? markup-ext p) :note
                  (string/has-suffix?    got-ext p) :got
                  nil)]
        (if kind 
          (put acc 
            (keyword (string/remove-prefix root-dir (pparts :dir)) (pparts :name)) 
            @{:path    p
              :kind    kind
              :private (string/has-suffix? private-suffix (pparts :name))
              :meta    @{} # attributes that are computed after initial preprocessing
              :content (let [file-content (try (slurp p)            ([e] (error (string "error while reading from file: " p))))
                             lisp-code    (try (parse file-content) ([e] (error (string "error while parseing lisp code from file: " p))))
                             result       (try (eval  lisp-code)    ([e] (error (string "error while evaluating parseing lisp code from file: " p))))]
                          result)}))))
    acc))


(defn solution-paths (notes-dir assets-dir output-dir)
  {:notes-dir   (path/dir notes-dir)
   :assets-dir  (path/dir assets-dir)
   :output-dir  (path/dir output-dir)})

(defn solution (solution-paths app-config got-style-config)
  (def    raw-db  (load-deep   (solution-paths :notes-dir)))
  (def assets-db  (let [d (solution-paths :assets-dir)] (if d (load-assets d) {})))
  (def        db  (finalize-db raw-db :index assets-db))
  (defn router (n) (string "/dist/" n))

  (req-files (solution-paths :output-dir))

  (eachp [id entity] db
    (let [
      path-parts (path/split (entity :path))
      new-path   (path/join (solution-paths :output-dir) (string (string/remove-prefix (solution-paths :notes-dir) (path-parts :dir)) (path-parts :name) ".html"))]

      (if-not (entity :private)
        (match (entity :kind)
          :got 
            (let [ggg       (GoT/init (entity :content))
                  svg-repr  (GoT/to-svg ggg got-style-config)
                  html-repr (GoT/html-page ggg "GoT of ..." svg-repr got-style-config db router app-config)]
              (file/put new-path html-repr))
              
          :note
            (let [content (mu/to-html (entity :content) router)]
              (file/put new-path (mu/html-page id "some note" content router app-config))))))))
