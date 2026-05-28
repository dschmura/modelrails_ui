import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "panel", "option", "empty"]

  open() {
    this.panelTarget.hidden = false
    this.filter()
  }

  close() {
    this.panelTarget.hidden = true
    const selected = this.optionTargets.find(o => o.dataset.comboboxValue === this.hiddenTarget.value)
    this.inputTarget.value = selected ? selected.dataset.comboboxLabel : ""
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    let visible = 0
    this.optionTargets.forEach(option => {
      const match = option.dataset.comboboxLabel.toLowerCase().includes(query)
      option.hidden = !match
      if (match) visible++
    })
    this.emptyTarget.hidden = visible > 0
  }

  select(event) {
    const { comboboxValue, comboboxLabel } = event.currentTarget.dataset
    this.hiddenTarget.value = comboboxValue
    this.inputTarget.value = comboboxLabel
    this.panelTarget.hidden = true
  }

  closeOnClickOutside({ target }) {
    if (!this.element.contains(target)) this.close()
  }
}
