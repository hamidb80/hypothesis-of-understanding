(def common-head (string `
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

  <link href=" https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.css " rel="stylesheet">
  <script src=" https://cdn.jsdelivr.net/npm/katex@0.16.21/dist/katex.min.js "></script>

  <script src="https://cdn.jsdelivr.net/npm/unpoly@3.8.0/unpoly.min.js"></script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/unpoly@3.8.0/unpoly.min.css">
`))


(defn nav-bar (home-page) (string `
  <nav class="navbar navbar-light bg-light px-3 d-flex justify-content-between">
    <div>
    </div>
    
    <a class="navbar-brand" up-follow href="` home-page `">
      nav bar
    </a>
    
    <div>
    </div>
  </nav>`))