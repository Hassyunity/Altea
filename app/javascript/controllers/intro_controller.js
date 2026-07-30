import { Controller } from "@hotwired/stimulus"

// Drives the welcome sequence: the portrait turns to face the visitor, then
// ALTEA types her greeting. Plays once per browser session.
export default class extends Controller {
  static targets = ["root", "portrait", "line", "actions", "enter"]
  static values = { storageKey: String }

  connect() {
    if (this.#alreadySeen()) return

    this.timers = []
    this.element.hidden = false
    document.body.classList.add("intro-open")

    this.onKeydown = (event) => { if (event.key === "Escape") this.dismiss() }
    document.addEventListener("keydown", this.onKeydown)

    if (this.#reducedMotion()) {
      this.#showEverythingAtOnce()
    } else {
      this.#play()
    }
  }

  disconnect() {
    this.#cleanup()
  }

  dismiss() {
    this.#remember()
    this.element.classList.add("intro--leaving")
    this.#after(420, () => {
      this.element.hidden = true
      this.#cleanup()
    })
  }

  // --- sequence ----------------------------------------------------------

  #play() {
    // Let the browser paint the "looking away" pose before turning her around.
    this.#after(260, () => this.element.classList.add("intro--turning"))
    this.#after(1500, () => this.#typeLine(0))
  }

  #typeLine(index) {
    const line = this.lineTargets[index]
    if (!line) return this.#revealActions()

    const text = line.dataset.text || ""
    line.classList.add("intro__line--active")

    let position = 0
    const step = () => {
      line.textContent = text.slice(0, position)
      position += 1

      if (position <= text.length) {
        this.timers.push(setTimeout(step, 34))
      } else {
        line.classList.remove("intro__line--active")
        this.#after(420, () => this.#typeLine(index + 1))
      }
    }

    step()
  }

  #revealActions() {
    this.actionsTarget.hidden = false
    this.#after(60, () => {
      this.actionsTarget.classList.add("is-visible")
      if (this.hasEnterTarget) this.enterTarget.focus()
    })
  }

  #showEverythingAtOnce() {
    this.element.classList.add("intro--turning", "intro--static")
    this.lineTargets.forEach((line) => { line.textContent = line.dataset.text || "" })
    this.actionsTarget.hidden = false
    this.actionsTarget.classList.add("is-visible")
    if (this.hasEnterTarget) this.enterTarget.focus()
  }

  // --- helpers -----------------------------------------------------------

  #after(delay, callback) {
    this.timers.push(setTimeout(callback, delay))
  }

  #cleanup() {
    ;(this.timers || []).forEach(clearTimeout)
    this.timers = []
    document.body.classList.remove("intro-open")
    if (this.onKeydown) document.removeEventListener("keydown", this.onKeydown)
  }

  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  // sessionStorage can throw in private/blocked contexts — never block the app for it.
  #alreadySeen() {
    try {
      return sessionStorage.getItem(this.storageKeyValue) === "1"
    } catch {
      return false
    }
  }

  #remember() {
    try {
      sessionStorage.setItem(this.storageKeyValue, "1")
    } catch {
      /* ignore */
    }
  }
}
