function nodeClass(id, dot = true) {
  return (dot ? '.' : '') + 'node-' + id
}

function qa(sel) {
  return [...document.querySelectorAll(sel)]
}

function q(sel, parent = document) {
  return parent.querySelector(sel)
}

function clsx(el, cond, cls) {
  if (cond)
    el.classList.add(cls)
  else
    el.classList.remove(cls)
}

function clearDisplay(el) {
  el.classList.add("d-none")
}

function hide(el) {
  el.classList.add("invisible")
}

function show(el) {
  el.classList.remove("invisible")
  el.classList.remove("d-none")
}

function scrollToElement(wrapper, target, behavior = 'smooth') {
  switch (behavior) {
    case 'smooth':
      target.scrollIntoView({ behavior: 'smooth', block: 'start' })
      break
    case 'instant':
      target.scrollIntoView()
      break
    case 'center':
      const rect = target.getBoundingClientRect()
      const containerRect = wrapper.getBoundingClientRect()

      const offsetTop = rect.top + wrapper.scrollTop -
        (containerRect.height / 2 - rect.height / 2)

      wrapper.scrollTo({
        top: offsetTop,
        behavior: 'smooth'
      })
      break
  }
}

function highlightNode(el) {
  el.setAttribute("stroke", "black")
  el.setAttribute("stroke-width", "4")
}
function blurNode(el) {
  el.removeAttribute("stroke")
  el.removeAttribute("stroke-width")
}

function getParam(key, dflt) {
  const l = new URLSearchParams(window.location.search)
  return l.get(key) || dflt
}
function setParam(key, val) {
  let u = new URLSearchParams(window.location.search)
  u.set(key, val)
  up.history.replace(window.location.pathname + "?" + u.toString(), {})
}

function clamp(n, max, min) {
  return Math.min(max, Math.max(n, min))
}

function parseShallowJSON(json) {
  for (const key in json)
    json[key] = JSON.parse(json[key])
  return json
}

// ----------------------------------------      

function toggleClassImpl(el, cls, state) {
  if (state)
    el.classList.add(cls)
  else
    el.classList.remove(cls)

  return !state
}

function toggleClass(el, cls, cond) {
  return toggleClassImpl(el, cls, cond === undefined ? el.classList.contains(cls) : cond)
}

// ----------------------------------------

up.compiler('.latex', (el, data) => {
  katex.render(el.innerText, el, { displayMode: data.display == "true" })
})

up.compiler('.toggle-graph-message-btn', el => {
  el.onclick = () => {
    let p = el.closest('.card')
    let target = q(`.card-body`, p)
    toggleClass(target, 'd-none', !target.classList.contains('d-none'))
  }
})

up.compiler('[got]', (_, data) => {
  const cursorName = 'c'
  const { events, nodes, anscestors } = parseShallowJSON(data)
  let cursor
  let messageShouldHiddenByDefault

  function focusNode(el) {
    let id = el ? el.getAttribute("node-id") : ""
    let ans = el ? anscestors[id] : []

    qa(".node").forEach(e => {
      let pid = e.getAttribute("node-id")
      if (id == pid) highlightNode(e)
      else blurNode(e)
      clsx(e, id != pid && !ans.includes(pid), "opacity-25")
    })
    qa(".edge").forEach(e => {
      let pid = e.getAttribute("to-node-id")
      clsx(e, id != pid && !ans.includes(pid), "opacity-12")
    })
  }

  function unfocusAll() {
    qa(".content").forEach(e => clsx(e, false, "opacity-25"))
    qa(".node").forEach(e => { clsx(e, false, "opacity-25"); blurNode(e) })
    qa(".edge").forEach(e => clsx(e, false, "opacity-12"))
  }

  function unversalStep(step) {
    let sel
    let c

    for (let i = 0; i < events.length; i++) {
      let e = events[i]
      let sel = "[for='" + e.id + "']"
      let c = q(sel)

      clsx(c, step < i, "d-none")
      clsx(c, step != i, "opacity-25")

      if (step == i)
        scrollToElement(q(".content-bar"), c)

      if (e.kind == "node") {
        let n = q(nodeClass(e.id))
        clsx(n, step < i, "d-none")
        if (step == i) focusNode(n)

        let ed = qa("[to-node-id='" + e.id + "']")
        if (ed.length) ed.forEach(el => clsx(el, step < i, "d-none"))
      }
    }
  }

  function setCursor(c) {
    c = clamp(parseInt(c), events.length - 1, -1)
    setParam(cursorName, c)
    return cursor = c
  }

  function resetProgress() {
    unversalStep(setCursor(-1))
  }
  function skipTillEnd() {
    unversalStep(setCursor(events.length))
  }
  function nextStep() {
    unversalStep(setCursor(cursor + 1))
  }
  function prevStep() {
    unversalStep(setCursor(cursor - 1))
  }

  function prepare() {
    qa(".node").forEach(el => {

      el.onmouseenter = () => {
        focusNode(el)

        let id = el.getAttribute("node-id")
        let ans = anscestors[id]

        qa(".content").forEach(el =>
          clsx(el, el.getAttribute("for") != id, "opacity-25"))

        scrollToElement(q(".content-bar"), q("[for=" + id + "]"))
      }

      el.onmouseleave = () => {
        unfocusAll()
      }
    })

    qa(".content").forEach(el => {
      el.onmouseenter = () => {
        let nodeId = el.getAttribute("for")
        focusNode(q(nodeClass(nodeId)))
        qa(".content").forEach(e => clsx(e, e != el, "opacity-25"))
      }

      el.onmouseleave = () => {
        unfocusAll()
      }
    })

    q('#reset-progress-action').onclick = resetProgress
    q("#skip-till-end-action").onclick = skipTillEnd
    q("#prev-step-action").onclick = prevStep
    q("#next-step-action").onclick = nextStep
    q("#next-goto-got").onclick = () => scrollToElement(document.body, q(`[got]`))
  }

  function keyboardEvent(e) {
    if (e.key == "ArrowRight") nextStep()
    if (e.key == "ArrowLeft") prevStep()
  }

  function delayedInit() {
    window.addEventListener("keyup", keyboardEvent)
  }
  function run() {
    unversalStep(cursor)
  }
  function init() {
    setCursor(parseInt(getParam(cursorName, 0)))
    prepare()
    run()
  }
  function destructor() {
    window.removeEventListener("keyup", keyboardEvent)
  }

  // -----------------------------

  init()
  setTimeout(delayedInit, 150)
  return destructor
})

up.compiler('[got-svg]', el => {
  // position: fixed;
  // top: 0;
  // left: 0;
  // transform: rotate(90deg) translate(-140px, -115px) scale(0.7);
  // z-index: 5;
}) 