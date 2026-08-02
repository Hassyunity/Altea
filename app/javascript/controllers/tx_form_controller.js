import { Controller } from "@hotwired/stimulus"

// A transfer needs a destination account but no category; an expense or income
// is the other way round. Show only what applies.
export default class extends Controller {
  static targets = ["kind", "transferField", "detailFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isTransfer = this.kindTarget.value === "transfer"
    this.transferFieldTarget.hidden = !isTransfer
    this.detailFieldsTarget.hidden = isTransfer
  }
}
