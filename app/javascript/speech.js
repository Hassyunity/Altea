// ALTEA's voice. Wraps the browser speech synthesis with a French voice,
// a persisted on/off preference, and detection of the autoplay block that
// browsers apply until the user has interacted with the page.

const STORAGE_KEY = "altea.voice"

// Broadcast so any hologram on the page can react to her speaking.
const emit = (name, detail = {}) => window.dispatchEvent(new CustomEvent(name, { detail }))

class Voice {
  constructor() {
    this.synth = window.speechSynthesis || null
    this.voice = null
    this.blocked = false
    this.current = null

    if (this.synth) {
      this.#loadVoice()
      this.synth.addEventListener?.("voiceschanged", () => this.#loadVoice())
    }
  }

  get available() {
    return Boolean(this.synth)
  }

  get enabled() {
    try {
      return localStorage.getItem(STORAGE_KEY) !== "off"
    } catch {
      return true
    }
  }

  set enabled(value) {
    try {
      localStorage.setItem(STORAGE_KEY, value ? "on" : "off")
    } catch {
      /* ignore */
    }
    if (!value) this.cancel()
  }

  toggle() {
    this.enabled = !this.enabled
    return this.enabled
  }

  // Resolves when the sentence has been spoken — or immediately when the voice
  // is unavailable, disabled or blocked, so the caller never stalls.
  speak(text) {
    if (!text || !this.available || !this.enabled) return Promise.resolve("skipped")

    return new Promise((resolve) => {
      const utterance = new SpeechSynthesisUtterance(text)
      utterance.lang = "fr-FR"
      utterance.rate = 0.97
      utterance.pitch = 1.05
      utterance.volume = 1
      if (this.voice) utterance.voice = this.voice

      let started = false
      let settled = false
      let guard = null
      let waited = 0

      // Network voices ("Google français") fetch their audio, so a slow start is
      // normal. Only call it blocked when the queue is empty too — that is the
      // signature of the browser refusing to play without a user gesture.
      const cap = Math.max(6000, text.split(/\s+/).length * 700)

      const finish = (reason) => {
        if (settled) return
        settled = true
        clearTimeout(guard)
        this.current = null
        resolve(reason)
      }

      const watch = () => {
        if (settled) return
        waited += 250

        if (!started) {
          const busy = this.synth.speaking || this.synth.pending
          if (!busy && waited >= 700) {
            this.blocked = true
            return finish("blocked")
          }
        }

        // Safety net: some browsers drop the end event and would stall the run.
        if (waited >= cap) return finish("timeout")

        guard = setTimeout(watch, 250)
      }

      utterance.onstart = () => {
        started = true
        this.blocked = false
        emit("altea:speech-start")
      }

      // Chrome reports every word as it is pronounced — that is what drives
      // the hologram's mouth-level movement.
      utterance.onboundary = (event) => {
        if (event.name === "word" || event.name === undefined) emit("altea:word")
      }

      utterance.onend = () => { emit("altea:speech-end"); finish("ended") }
      utterance.onerror = (event) => {
        const refused = event.error === "not-allowed"
        if (refused) this.blocked = true
        emit("altea:speech-end")
        finish(refused ? "blocked" : "error")
      }

      this.current = utterance
      this.synth.speak(utterance)
      guard = setTimeout(watch, 250)
    })
  }

  cancel() {
    if (this.available) this.synth.cancel()
    if (this.current) emit("altea:speech-end")
    this.current = null
  }

  // French voices, best sounding first: Google/Microsoft network voices are far
  // more natural than the local espeak fallback shipped on most Linux boxes.
  #loadVoice() {
    const voices = this.synth.getVoices() || []
    const french = voices.filter((v) => v.lang?.toLowerCase().startsWith("fr"))
    if (french.length === 0) return

    const natural = /google|microsoft|siri|amelie|amélie|audrey|virginie|julie|marie|denise|hortense/i
    const feminine = /amelie|amélie|audrey|virginie|julie|marie|denise|hortense|female|femme|f\b/i

    this.voice = french.find((v) => natural.test(v.name) && feminine.test(v.name)) ||
                 french.find((v) => natural.test(v.name)) ||
                 french.find((v) => feminine.test(v.name)) ||
                 french[0]
  }

  // What the browser actually gave us — useful when the voice sounds wrong.
  describe() {
    if (!this.available) return "synthèse vocale indisponible"

    const all = this.synth.getVoices() || []
    const french = all.filter((v) => v.lang?.toLowerCase().startsWith("fr"))
    return {
      total: all.length,
      french: french.map((v) => v.name),
      chosen: this.voice?.name || null
    }
  }
}

export const voice = new Voice()
