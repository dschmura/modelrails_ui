import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "popover", "label", "hidden", "hour", "minute", "ampm"]
  static values = {
    format: { type: String, default: "h24" },
    step:   { type: Number, default: 1 }
  }

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

  hourUp()   { this.#stepHour(1) }
  hourDown() { this.#stepHour(-1) }

  minuteUp()   { this.#stepMinute(this.stepValue) }
  minuteDown() { this.#stepMinute(-this.stepValue) }

  toggleAmPm() {
    if (!this.hasAmpmTarget) return
    const current = this.ampmTarget.textContent.trim()
    this.ampmTarget.textContent = current === "AM" ? "PM" : "AM"
    this.#commit()
  }

  hourChanged()   { this.#clampInput(this.hourTarget, 0, this.formatValue === "h12" ? 12 : 23); this.#commit() }
  minuteChanged() { this.#clampInput(this.minuteTarget, 0, 59); this.#commit() }

  #stepHour(delta) {
    const max = this.formatValue === "h12" ? 12 : 23
    let val = parseInt(this.hourTarget.value || "0", 10) + delta
    if (val > max) val = 0
    if (val < 0)   val = max
    this.hourTarget.value = String(val).padStart(2, "0")
    this.#commit()
  }

  #stepMinute(delta) {
    let val = parseInt(this.minuteTarget.value || "0", 10) + delta
    if (val > 59) val = 0
    if (val < 0)  val = 59
    this.minuteTarget.value = String(val).padStart(2, "0")
    this.#commit()
  }

  #clampInput(input, min, max) {
    let val = parseInt(input.value || "0", 10)
    if (isNaN(val)) val = min
    val = Math.min(max, Math.max(min, val))
    input.value = String(val).padStart(2, "0")
  }

  #commit() {
    const h = this.hourTarget.value.padStart(2, "0")
    const m = this.minuteTarget.value.padStart(2, "0")
    const ampm = this.hasAmpmTarget ? ` ${this.ampmTarget.textContent.trim()}` : ""
    const display = `${h}:${m}${ampm}`
    const hidden  = `${h}:${m}`

    this.labelTarget.textContent = display
    if (this.hasHiddenTarget) this.hiddenTarget.value = hidden

    this.element.dispatchEvent(new CustomEvent("timepicker:change", {
      detail: { time: hidden },
      bubbles: true
    }))
  }

  #outsideHandler = null
  isOpen = false
}
