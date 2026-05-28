import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "input", "list", "empty"]

  connect() {
    this._onKeydown = this._onKeydown.bind(this)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown)
  }

  _onKeydown(event) {
    if (event.key === "k" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.panelTarget.hidden ? this.open() : this.close()
    }
  }

  open() {
    this.panelTarget.hidden = false
    document.body.style.overflow = "hidden"
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.filter()
  }

  close() {
    this.panelTarget.hidden = true
    document.body.style.overflow = ""
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const items = this.listTarget.querySelectorAll("[data-command-value]")
    items.forEach(item => {
      item.hidden = query.length > 0 && !item.dataset.commandValue.toLowerCase().includes(query)
    })

    this.listTarget.querySelectorAll("[data-command-group]").forEach(group => {
      const hasVisible = Array.from(group.querySelectorAll("[data-command-value]")).some(i => !i.hidden)
      group.hidden = !hasVisible
    })

    const totalVisible = Array.from(items).filter(i => !i.hidden).length
    this.emptyTarget.hidden = totalVisible > 0
  }
}
