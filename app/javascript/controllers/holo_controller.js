import { Controller } from "@hotwired/stimulus"

// Makes ALTEA speak. Every word she pronounces pushes energy in; the envelope
// attacks fast and releases slowly, like a syllable. That level drives two
// things: --energy for the chamber around her, and the mouth itself.
//
// The mouth is not switched frame by frame — that reads as stop-motion. Two
// neighbouring frames are cross-faded every animation frame, and a fast wobble
// runs inside each word, so the lips keep moving while a word is being spoken
// instead of opening once and closing.
export default class extends Controller {
  static targets = ["mouth"]
  static values = {
    idle: { type: Number, default: 0.06 },
    // syllables per second — French runs around 6
    rate: { type: Number, default: 6.2 }
  }

  connect() {
    this.energy = 0
    this.target = 0
    this.bias = 1
    this.phase = 0
    this.opened = new Array(this.mouthTargets.length).fill(0)
    this.root = this.element.closest(".intro, .assistant") || this.element

    this.onStart = () => this.#talking(true)
    this.onEnd = () => { this.target = 0; this.#talking(false) }
    this.onWord = () => {
      this.target = 0.6 + Math.random() * 0.4
      // a different shape and a different rhythm on each syllable
      this.bias = 0.8 + Math.random() * 0.55
      this.phase = Math.random() * Math.PI * 2
      this.#talking(true)
    }

    window.addEventListener("altea:speech-start", this.onStart)
    window.addEventListener("altea:speech-end", this.onEnd)
    window.addEventListener("altea:word", this.onWord)

    if (this.#reducedMotion()) {
      this.#setMouth(0)
      return
    }

    this.#loop(performance.now())
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    window.removeEventListener("altea:speech-start", this.onStart)
    window.removeEventListener("altea:speech-end", this.onEnd)
    window.removeEventListener("altea:word", this.onWord)
    this.root.style.removeProperty("--energy")
    this.#setMouth(0)
  }

  #talking(state) {
    this.element.classList.toggle("is-talking", state)
    this.root.classList.toggle("is-talking", state)
  }

  #loop(now) {
    const rate = this.target > this.energy ? 0.45 : 0.09
    this.energy += (this.target - this.energy) * rate
    if (this.target > 0 && this.energy > this.target * 0.92) this.target = 0

    const level = Math.max(this.energy, this.idleValue)
    this.root.style.setProperty("--energy", level.toFixed(3))

    // articulation inside the word: the mouth never sits still while sound
    // is coming out, it keeps forming shapes
    const wobble = 0.66 + 0.34 * Math.sin((now / 1000) * Math.PI * 2 * this.rateValue + this.phase)
    this.#setMouth(this.energy * this.bias * wobble)

    this.frame = requestAnimationFrame((t) => this.#loop(t))
  }

  // level 0 leaves her lips closed (the portrait itself); above that the two
  // frames bracketing the level are blended, which reads as one continuous
  // movement rather than eight discrete poses.
  #setMouth(level) {
    const count = this.mouthTargets.length
    if (count === 0) return

    const position = Math.max(0, Math.min(count, level * count))
    const lower = Math.floor(position)
    const blend = position - lower

    for (let i = 0; i < count; i += 1) {
      const index = i + 1
      let opacity = 0
      if (index === lower) opacity = 1 - blend
      else if (index === lower + 1) opacity = blend

      // only touch the DOM when it actually changes
      if (Math.abs(opacity - this.opened[i]) > 0.01) {
        this.opened[i] = opacity
        this.mouthTargets[i].style.opacity = opacity === 0 ? "" : opacity.toFixed(2)
      }
    }
  }

  #reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
