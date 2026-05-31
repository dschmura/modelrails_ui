import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "panel"]

  get openIndex() {
    return this.panelTargets.findIndex(p => !p.hidden)
  }

  toggle(event) {
    const menu = event.currentTarget.closest("[data-menubar-target='menu']")
    const index = this.menuTargets.indexOf(menu)
    const panel = this.panelTargets[index]
    const wasOpen = !panel.hidden
    this.closeAll()
    if (!wasOpen) panel.hidden = false
  }

  openOnHover(event) {
    if (this.openIndex === -1) return
    const menu = event.currentTarget.closest("[data-menubar-target='menu']")
    const index = this.menuTargets.indexOf(menu)
    this.closeAll()
    this.panelTargets[index].hidden = false
  }

  closeAll() {
    this.panelTargets.forEach(p => p.hidden = true)
  }

  closeOnClickOutside({ target }) {
    if (!this.element.contains(target)) this.closeAll()
  }
}
