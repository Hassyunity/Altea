import { Controller } from "@hotwired/stimulus"
import { voice } from "speech"

// Welcome sequence: the portrait turns from its dormant pose to face the
// visitor, ALTEA speaks her briefing out loud while it types itself, lists the
// priorities, then "Réveiller" boots the platform.
// Plays once per browser session, and again whenever "Déconnexion" is used.
export default class extends Controller {
  static targets = ["line", "actions", "enter", "boot", "item", "voice", "voiceLabel", "voiceIcon"]
  static values = { storageKey: String }

  connect() {
    this.timers = []
    this.leaving = false

    this.onLock = () => this.replay()
    this.onKeydown = (event) => {
      if (event.key === "Escape" && !this.element.hidden) this.wake()
    }

    window.addEventListener("altea:lock", this.onLock)
    document.addEventListener("keydown", this.onKeydown)

    this.#paintVoiceButton()
    if (!this.#alreadySeen()) this.#start()
  }

  disconnect() {
    this.#clearTimers()
    voice.cancel()
    document.body.classList.remove("intro-open", "altea-booting")
    window.removeEventListener("altea:lock", this.onLock)
    document.removeEventListener("keydown", this.onKeydown)
  }

  // --- entry points ------------------------------------------------------

  // "Réveiller" (or Échap / Passer): boot the platform with the arrival sequence.
  wake() {
    if (this.leaving || this.element.hidden) return
    this.leaving = true
    this.#remember()
    this.#clearTimers()
    voice.cancel()

    if (this.#reducedMotion()) return this.#finish()

    this.element.classList.add("intro--waking")
    this.bootTarget.hidden = false
    document.body.classList.add("altea-booting")

    this.#after(1150, () => this.#finish())
    this.#after(2200, () => document.body.classList.remove("altea-booting"))
  }

  // "Déconnexion": back to the greeting screen.
  replay() {
    this.#clearTimers()
    this.#forget()
    voice.cancel()
    this.leaving = false

    this.element.classList.remove("intro--waking", "intro--turning", "intro--static")
    this.lineTargets.forEach((line) => { line.textContent = "" })
    this.itemTargets.forEach((item) => item.classList.remove("is-visible"))
    this.actionsTarget.hidden = true
    this.actionsTarget.classList.remove("is-visible")
    this.bootTarget.hidden = true

    this.#start()
  }

  // Jumping straight to a briefing item still counts as entering the app.
  follow() {
    this.#remember()
    this.#clearTimers()
    voice.cancel()
    document.body.classList.remove("intro-open")
  }

  // The click that toggles the voice is also the gesture browsers wait for,
  // so switching it back on resumes the briefing straight away.
  toggleVoice() {
    const enabled = voice.toggle()
    this.#paintVoiceButton()

    if (!enabled) {
      voice.cancel()
    } else if (!this.element.hidden && !this.leaving) {
      this.#speakFrom(this.spokenIndex || 0)
    }
  }

  // --- sequence ----------------------------------------------------------

  #start() {
    this.element.hidden = false
    document.body.classList.add("intro-open")
    this.spokenIndex = 0

    if (this.#reducedMotion()) return this.#showEverythingAtOnce()

    // Let the browser paint the dormant pose before she turns round.
    this.#after(300, () => this.element.classList.add("intro--turning"))
    this.#after(1750, () => this.#typeLine(0))
  }

  // Types a line and speaks it at the same time; moves on when both are done.
  #typeLine(index) {
    const line = this.lineTargets[index]
    if (!line) return this.#revealBriefing()

    this.spokenIndex = index
    const text = line.dataset.text || ""
    line.classList.add("intro__line--active")

    const spoken = voice.speak(line.dataset.speech || text)
    this.element.classList.add("intro--speaking")

    // With the voice off there are no word events, so the typing itself gives
    // the hologram its rhythm — she still moves while she "talks".
    const silent = !voice.enabled || !voice.available || voice.blocked
    if (silent) window.dispatchEvent(new CustomEvent("altea:speech-start"))

    const typed = new Promise((resolve) => {
      let position = 0
      const step = () => {
        line.textContent = text.slice(0, position)
        position += 1

        if (silent && text[position - 1] === " ") {
          window.dispatchEvent(new CustomEvent("altea:word"))
        }

        if (position <= text.length) {
          this.timers.push(setTimeout(step, 34))
        } else {
          if (silent) window.dispatchEvent(new CustomEvent("altea:speech-end"))
          resolve()
        }
      }
      step()
    })

    Promise.all([ typed, spoken ]).then(([ , reason ]) => {
      if (this.leaving || this.element.hidden) return

      line.classList.remove("intro__line--active")
      this.element.classList.remove("intro--speaking")
      if (reason === "blocked") this.#paintVoiceButton()

      // A silent run needs its own beat between lines; a spoken one already has it.
      const pause = reason === "ended" ? 220 : 420
      this.#after(pause, () => this.#typeLine(index + 1))
    })
  }

  // Resumes the spoken briefing from a given line without retyping anything.
  #speakFrom(index) {
    const line = this.lineTargets[index]
    if (!line) return

    voice.speak(line.dataset.speech || line.dataset.text || "")
  }

  // Her priorities land one after another, then the way in opens.
  #revealBriefing() {
    this.itemTargets.forEach((item, index) => {
      this.#after(index * 130, () => item.classList.add("is-visible"))
    })

    this.#after(this.itemTargets.length * 130 + 260, () => this.#revealActions())
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
    this.itemTargets.forEach((item) => item.classList.add("is-visible"))
    this.actionsTarget.hidden = false
    this.actionsTarget.classList.add("is-visible")
    if (this.hasEnterTarget) this.enterTarget.focus()
  }

  #finish() {
    this.element.hidden = true
    this.element.classList.remove("intro--waking", "intro--speaking")
    this.bootTarget.hidden = true
    document.body.classList.remove("intro-open")
    this.leaving = false
  }

  // --- voice button ------------------------------------------------------

  #paintVoiceButton() {
    if (!this.hasVoiceTarget) return

    if (!voice.available) {
      this.voiceTarget.hidden = true
      return
    }

    const enabled = voice.enabled
    this.voiceTarget.setAttribute("aria-pressed", String(enabled))
    this.voiceTarget.classList.toggle("is-muted", !enabled)

    if (!enabled) {
      this.voiceIconTarget.textContent = "🔇"
      this.voiceLabelTarget.textContent = "Muet"
    } else if (voice.blocked) {
      // The browser is waiting for a click before it will play anything.
      this.voiceIconTarget.textContent = "🔈"
      this.voiceLabelTarget.textContent = "Activer la voix"
      this.voiceTarget.classList.add("is-blocked")
    } else {
      this.voiceIconTarget.textContent = "🔊"
      this.voiceLabelTarget.textContent = "Voix"
      this.voiceTarget.classList.remove("is-blocked")
    }
  }

  // --- helpers -----------------------------------------------------------

  #after(delay, callback) {
    this.timers.push(setTimeout(callback, delay))
  }

  #clearTimers() {
    ;(this.timers || []).forEach(clearTimeout)
    this.timers = []
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

  #forget() {
    try {
      sessionStorage.removeItem(this.storageKeyValue)
    } catch {
      /* ignore */
    }
  }
}
