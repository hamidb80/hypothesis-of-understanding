"
integration of GoT and Notes
"

(use 
  ./helper/debug
  ./helper/io
  ./helper/path
  ./helper/tab
  ./helper/str)

(use
  ./locales
  ./markup
  ./graph-of-thought
  ./html-gen)

# ------------------------------------------------------
(def markup-ext ".mu.janet") # markup language in Janet lisp format
(def got-ext    ".got.janet") # graph of thought representation in Janet lisp format
(def private-suffix "_")

(defn got/scan-events (db events ref-count)
  # count only private ones, because public notes must be accessible from root note somehow
  (each e events
    (let [id     (e :content)
          entity (db id)]
      (assert entity (string "the entity " id " does not exist"))
      (if (entity :private) 
        (put+ ref-count id)))))

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
      (let [zero-refs (count-tab/zeros ref-count)]
        (assert (empty? zero-refs) (string "there are notes that are not referenced at all: " (string/join zero-refs ", "))))))

    (let [zero-refs (count-tab/zeros assets-db)]
      (assert (empty? zero-refs) (string "there are assets that are not referenced at all: " (string/join zero-refs ", "))))

    acc))

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
              :content (let [file-content (try (slurp p)            ([e] (error (string "error while reading from file: "                       p "\n >>> " e))))
                             lisp-code    (try (parse file-content) ([e] (error (string "error while parseing lisp code from file: "            p "\n >>> " e))))
                             result       (try (eval  lisp-code)    ([e] (error (string "error while evaluating parseing lisp code from file: " p "\n >>> " e))))]
                          result)}))))
    acc))

(defn req-files (project-dir output-dir)
  (each f ["page.js" "style.css"]
    (file/copy (path/join project-dir "src" f) (path/join output-dir f))))

(defn solution-paths (project-dir notes-dir assets-dir output-dir base-route)
  {:project-dir (path/dir project-dir)
   :notes-dir   (path/dir notes-dir)
   :assets-dir  (path/dir assets-dir)
   :output-dir  (path/dir output-dir)
   :base-route  base-route })

(defn solution (solution-paths app-config got-style-config)
  (let [ 
         raw-db  (load-deep (solution-paths :notes-dir))
     has-assets  (not (nil? (solution-paths :assets-dir)))
      assets-db  (if has-assets 
                    (load-assets (solution-paths :assets-dir)) 
                    {})
             db  (finalize-db raw-db :index assets-db)
         router  (fn  (n) (string (solution-paths :base-route) n))]
    
    (eachp [id entity] db
      (let [
        path-parts (path/split (entity :path))
        new-path   (path/join (solution-paths :output-dir) (string (string/remove-prefix (solution-paths :notes-dir) (path-parts :dir)) (path-parts :name) ".html"))]

        (unless (entity :private)
          (print ">> " id)
          (match (entity :kind)
            :got 
              (let [ggg       (GoT/init (entity :content))
                    svg-repr  (GoT/to-svg       ggg                       got-style-config)
                    html-repr (GoT/html-page id ggg (string "GoT of " (path-parts :name)) svg-repr got-style-config db router app-config)]
                (file/put new-path html-repr))
                
            :note
              (let [compiled (mu/to-html (entity :content) router)]
                  (file/put new-path (mu/html-page db id |(string "note " $) entity compiled router app-config)))
                  
            (error "invalid kind")))))
      
      
    (req-files (solution-paths :project-dir) (solution-paths :output-dir))
    
    (if has-assets
      (dir/copy (solution-paths :assets-dir) (path/join (solution-paths :output-dir) "assets")))))
