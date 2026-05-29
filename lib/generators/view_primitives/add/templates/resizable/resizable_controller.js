import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["handle", "panel"]
  static values = { direction: { type: String, default: "horizontal" } }

  startDrag(event) {
    event.preventDefault()
    const isH = this.directionValue === "horizontal"
    const handle = event.currentTarget
    const idx = this.handleTargets.indexOf(handle)
    const a = this.panelTargets[idx]
    const b = this.panelTargets[idx + 1]
    const container = this.element

    const onMove = (e) => {
      const clientPos = (e.touches ? e.touches[0] : e)[isH ? "clientX" : "clientY"]
      const rect = container.getBoundingClientRect()
      const total = isH ? rect.width : rect.height
      const offset = clientPos - (isH ? rect.left : rect.top)
      const pct = Math.min(90, Math.max(10, (offset / total) * 100))
      a.style.flex = `0 0 ${pct}%`
      b.style.flex = `0 0 ${100 - pct}%`
    }

    const onUp = () => {
      document.removeEventListener("mousemove", onMove)
      document.removeEventListener("mouseup", onUp)
      document.removeEventListener("touchmove", onMove)
      document.removeEventListener("touchend", onUp)
    }

    document.addEventListener("mousemove", onMove)
    document.addEventListener("mouseup", onUp)
    document.addEventListener("touchmove", onMove, { passive: false })
    document.addEventListener("touchend", onUp)
  }
}
