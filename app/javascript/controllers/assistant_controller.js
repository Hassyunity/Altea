import { Controller } from "@hotwired/stimulus"
import { voice } from "speech"

// The sidebar HUD: live clock, and ALTEA typing out a rolling briefing built
// from the real state of the app. She stays silent here — the speaker button
// reads the current situation aloud on demand.
export default class extends Controller {
  static targets = ["status", "clock", "speak"]
  static values = { lines: Array, speech: String }

  connect() {
    this.timers = []
    this.index = 0
    this.talking = false

    this.#tickClock()
    this.clockTimer = setInterval(() => this.#tickClock(), 1000)

    if (this.hasSpeakTarget && !voice.available) this.speakTarget.hidden = true

    if (this.#reducedMotion()) {
      this.statusTarget.textContent = this.linesValue[0] || ""
      this.element.classList.add("assistant--idle")
    } else {
      this.#type()
    }
  }

  disconnect() {
    clearInterval(this.clockTimer)
    this.timers.forEach(clearTimeout)
    this.timers = []
    if (this.talking) voice.cancel()
  }

  // Reads the whole briefing out loud; a second click stops her.
  say() {
    if (this.talking) {
      voice.cancel()
      this.#stopTalking()
      return
    }

    if (!voice.enabled) voice.enabled = true

    this.talking = true
    this.element.classList.add("assistant--speaking")
    this.speakTarget.classList.add("is-active")

    voice.speak(this.speechValue).then(() => this.#stopTalking())
  }

  #stopTalking() {
    this.talking = false
    this.element.classList.remove("assistant--speaking")
    this.speakTarget?.classList.remove("is-active")
  }

  #type() {
    const text = this.linesValue[this.index % this.linesValue.length] || ""
    this.index += 1

    if (!this.talking) this.element.classList.add("assistant--speaking")
    this.statusTarget.textContent = ""

    let position = 0
    const step = () => {
      this.statusTarget.textContent = text.slice(0, position)
      position += 1

      if (position <= text.length) {
        this.timers.push(setTimeout(step, 26))
      } else {
        if (!this.talking) this.element.classList.remove("assistant--speaking")
        this.timers.push(setTimeout(() => this.#type(), 5200))
      }
    }

    step()
  }

  #tickClock() {
    this.clockTarget.textContent = new Date().toLocaleTimeString("fr-FR", {
      hour: "2-digit", minute: "2-digit", second: "2-digit"
    })
  }

  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
