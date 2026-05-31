import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthLabel", "grid"]
  static values = { month: String }

  selectDay({ params: { date } }) {
    const selected = date
    this.element.dataset.selected = selected

    this.gridTarget.querySelectorAll("button[data-calendar-date-param]").forEach(btn => {
      const isSelected = btn.dataset.calendarDateParam === selected
      btn.dataset.state = isSelected ? "on" : "off"
      btn.setAttribute("aria-pressed", String(isSelected))
    })

    const hidden = this.element.querySelector("input[type=hidden]")
    if (hidden) hidden.value = selected

    this.element.dispatchEvent(new CustomEvent("calendar:change", {
      detail: { date: selected },
      bubbles: true
    }))
  }

  prevMonth() {
    this.#shiftMonth(-1)
  }

  nextMonth() {
    this.#shiftMonth(1)
  }

  #shiftMonth(delta) {
    const [year, month] = this.monthValue.split("-").map(Number)
    const d = new Date(year, month - 1 + delta, 1)
    this.monthValue = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-01`
  }

  monthValueChanged(value) {
    if (!value) return
    const [year, month] = value.split("-").map(Number)
    const date = new Date(year, month - 1, 1)

    this.monthLabelTarget.textContent = date.toLocaleString("default", {
      month: "long",
      year: "numeric"
    })

    this.#rebuildGrid(year, month)
  }

  #rebuildGrid(year, month) {
    const selected = this.element.dataset.selected || null
    const today = new Date()
    const todayIso = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`

    const first = new Date(year, month - 1, 1)
    const last = new Date(year, month, 0)
    const startOffset = first.getDay()
    const totalCells = 42

    const buttons = this.gridTarget.querySelectorAll("button[data-calendar-date-param]")
    const start = new Date(first)
    start.setDate(start.getDate() - startOffset)

    buttons.forEach((btn, i) => {
      const d = new Date(start)
      d.setDate(d.getDate() + i)
      const iso = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`

      btn.dataset.calendarDateParam = iso
      btn.setAttribute("aria-label", d.toLocaleDateString("default", { month: "long", day: "numeric", year: "numeric" }))
      btn.textContent = String(d.getDate())

      const isSelected = iso === selected
      const isToday = iso === todayIso
      const isOutside = d.getMonth() + 1 !== month

      btn.dataset.state = isSelected ? "on" : "off"
      btn.setAttribute("aria-pressed", String(isSelected))
      btn.dataset.today = String(isToday)
      btn.dataset.outside = String(isOutside)
    })
  }
}
