import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cell"]

  onInput(event) {
    const cell = event.currentTarget
    const idx = this.cellTargets.indexOf(cell)
    if (cell.value && idx < this.cellTargets.length - 1) {
      this.cellTargets[idx + 1].focus()
    }
  }

  onKeydown(event) {
    const cell = event.currentTarget
    const idx = this.cellTargets.indexOf(cell)
    if (event.key === "Backspace" && !cell.value && idx > 0) {
      this.cellTargets[idx - 1].focus()
    }
    if (event.key === "ArrowLeft" && idx > 0) {
      this.cellTargets[idx - 1].focus()
    }
    if (event.key === "ArrowRight" && idx < this.cellTargets.length - 1) {
      this.cellTargets[idx + 1].focus()
    }
  }

  onPaste(event) {
    event.preventDefault()
    const text = (event.clipboardData || window.clipboardData).getData("text").replace(/\D/g, "")
    const start = this.cellTargets.indexOf(event.currentTarget)
    text.split("").forEach((char, i) => {
      const cell = this.cellTargets[start + i]
      if (cell) cell.value = char
    })
    const next = this.cellTargets[start + text.length]
    if (next) next.focus()
  }
}
