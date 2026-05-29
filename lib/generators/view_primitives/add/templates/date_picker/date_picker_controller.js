import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "popover", "label", "hidden"]

  connect() {
    this.#outsideHandler = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.popoverTarget.dataset.open = "true"
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.#outsideHandler)
    this.isOpen = true
  }

  close() {
    this.popoverTarget.dataset.open = "false"
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.#outsideHandler)
    this.isOpen = false
  }

  dateSelected(event) {
    const iso = event.detail.date
    const [year, month, day] = iso.split("-").map(Number)
    const d = new Date(year, month - 1, day)

    this.labelTarget.textContent = d.toLocaleDateString("default", {
      month: "long",
      day: "numeric",
      year: "numeric"
    })

    if (this.hasHiddenTarget) this.hiddenTarget.value = iso

    this.close()
  }

  #outsideHandler = null
  isOpen = false
}
