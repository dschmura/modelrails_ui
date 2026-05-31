import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  show(event) {
    event.preventDefault()
    this.panelTarget.hidden = false
    this.panelTarget.style.top = `${event.clientY}px`
    this.panelTarget.style.left = `${event.clientX}px`
  }

  close() {
    this.panelTarget.hidden = true
  }

  closeOnClickOutside({ target }) {
    if (!this.panelTarget.contains(target)) this.close()
  }
}
