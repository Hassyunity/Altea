import { Controller } from "@hotwired/stimulus"

// ⌘K / Ctrl+K command palette: jump to any section or start any creation
// without leaving the keyboard.
export default class extends Controller {
  static targets = ["input", "list"]
  static values = { items: Array }

  connect() {
    this.cursor = 0
    this.matches = this.itemsValue

    this.onKeydown = (event) => {
      const combo = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k"
      if (combo) {
        event.preventDefault()
        this.element.hidden ? this.open() : this.close()
      } else if (event.key === "Escape" && !this.element.hidden) {
        this.close()
      }
    }

    document.addEventListener("keydown", this.onKeydown)
    this.onOpenRequest = () => this.open()
    window.addEventListener("altea:palette", this.onOpenRequest)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("altea:palette", this.onOpenRequest)
    document.body.classList.remove("palette-open")
  }

  open() {
    this.element.hidden = false
    document.body.classList.add("palette-open")
    this.inputTarget.value = ""
    this.cursor = 0
    this.#render(this.itemsValue)
    requestAnimationFrame(() => this.inputTarget.focus())
  }

  close() {
    this.element.hidden = true
    document.body.classList.remove("palette-open")
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    this.cursor = 0

    if (query === "") return this.#render(this.itemsValue)

    const terms = query.split(/\s+/)
    const matches = this.itemsValue.filter((item) => {
      const haystack = `${item.label} ${item.hint}`.toLowerCase()
      return terms.every((term) => haystack.includes(term))
    })

    this.#render(matches)
  }

  navigate(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.#move(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.#move(-1)
    } else if (event.key === "Enter") {
      event.preventDefault()
      this.#go(this.matches[this.cursor])
    }
  }

  pick(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.#go(this.matches[index])
  }

  // --- rendering ---------------------------------------------------------

  #render(matches) {
    this.matches = matches
    this.listTarget.innerHTML = ""

    if (matches.length === 0) {
      const empty = document.createElement("li")
      empty.className = "palette__empty"
      empty.textContent = "Aucun résultat."
      this.listTarget.append(empty)
      return
    }

    matches.forEach((item, index) => {
      const row = document.createElement("li")
      row.className = "palette__item"
      row.dataset.index = index
      row.dataset.action = "click->palette#pick"
      if (index === this.cursor) row.classList.add("is-active")

      const icon = document.createElement("span")
      icon.className = "palette__icon"
      icon.textContent = item.icon || "›"

      const label = document.createElement("span")
      label.className = "palette__label"
      label.textContent = item.label

      const hint = document.createElement("span")
      hint.className = "palette__hint"
      hint.textContent = item.hint || ""

      row.append(icon, label, hint)
      this.listTarget.append(row)
    })
  }

  #move(delta) {
    if (this.matches.length === 0) return

    this.cursor = (this.cursor + delta + this.matches.length) % this.matches.length
    this.listTarget.querySelectorAll(".palette__item").forEach((row, index) => {
      row.classList.toggle("is-active", index === this.cursor)
      if (index === this.cursor) row.scrollIntoView({ block: "nearest" })
    })
  }

  #go(item) {
    if (!item) return

    this.close()
    if (window.Turbo) {
      window.Turbo.visit(item.url)
    } else {
      window.location.href = item.url
    }
  }
}
