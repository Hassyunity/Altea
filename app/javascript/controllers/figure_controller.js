import { Controller } from "@hotwired/stimulus"
import { AlteaFigure } from "altea_figure"

// Mounts ALTEA on a canvas and feeds her the speaking energy: every word she
// pronounces spikes it, and the figure answers — mouth, scatter, brightness.
export default class extends Controller {
  static values = {
    points: { type: Number, default: 900 },
    face: { type: Boolean, default: true },
    idle: { type: Number, default: 0.05 }
  }

  connect() {
    this.energy = 0
    this.target = 0
    this.root = this.element.closest(".intro, .assistant") || this.element

    this.figure = new AlteaFigure(this.element, {
      points: this.pointsValue,
      showFace: this.faceValue
    })

    this.onStart = () => this.#talking(true)
    this.onEnd = () => { this.target = 0; this.#talking(false) }
    this.onWord = () => { this.target = 0.55 + Math.random() * 0.45; this.#talking(true) }

    window.addEventListener("altea:speech-start", this.onStart)
    window.addEventListener("altea:speech-end", this.onEnd)
    window.addEventListener("altea:word", this.onWord)

    if (this.#reducedMotion()) {
      this.figure.setEnergy(this.idleValue)
      this.figure.drawOnce()
      return
    }

    this.figure.start()
    this.#loop()
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    this.figure?.stop()
    window.removeEventListener("altea:speech-start", this.onStart)
    window.removeEventListener("altea:speech-end", this.onEnd)
    window.removeEventListener("altea:word", this.onWord)
    this.root.style.removeProperty("--energy")
  }

  #talking(state) {
    this.root.classList.toggle("is-talking", state)
  }

  #loop() {
    // Attack fast, release slow — the shape of a spoken syllable.
    const rate = this.target > this.energy ? 0.45 : 0.09
    this.energy += (this.target - this.energy) * rate
    if (this.target > 0 && this.energy > this.target * 0.92) this.target = 0

    const level = Math.max(this.energy, this.idleValue)
    this.figure.setEnergy(level)
    // the chamber (beam, rings, platform) reads the same value
    this.root.style.setProperty("--energy", level.toFixed(3))

    this.frame = requestAnimationFrame(() => this.#loop())
  }

  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
