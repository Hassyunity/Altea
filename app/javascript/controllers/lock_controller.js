import { Controller } from "@hotwired/stimulus"

// Small dispatchers for the sidebar footer buttons.
export default class extends Controller {
  // "Déconnexion": puts Altea back to sleep; the intro controller replays.
  engage() {
    window.dispatchEvent(new CustomEvent("altea:lock"))
  }

  // Opens the command palette from a click instead of ⌘K.
  palette() {
    window.dispatchEvent(new CustomEvent("altea:palette"))
  }
}
