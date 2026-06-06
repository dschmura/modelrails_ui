import { Controller } from "@hotwired/stimulus"

// Behavior for the floating-overlays band. Wave 5a wires popover (click toggle).
// Non-modal: CSS owns positioning; this owns open/close, aria-expanded sync,
// focus return, and Escape / outside-click dismissal. No focus trap (Tab may leave).
export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    if (this.openValue) this.open()
  }

  toggle() {
    this.openValue ? this.close() : this.open()
  }

  open() {
    if (this.openValue) return
    this.openValue = true
    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.panelTarget.focus()
  }

  close() {
    if (!this.openValue) return
    this.openValue = false
    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.triggerTarget.focus()
  }

  closeOnClickOutside(event) {
    if (this.openValue && !this.element.contains(event.target)) this.close()
  }

  // Hover/focus components (tooltip, hover_card) are CSS-shown; this is the only
  // thing CSS can't do — dismiss-while-hovered (WCAG 1.4.13). Escape sets
  // data-dismissed (CSS force-hides via group-data-[dismissed]); mouseleave/
  // focusout clear it so the next hover/focus shows it again.
  dismiss() {
    this.element.setAttribute("data-dismissed", "")
  }

  clearDismissed() {
    this.element.removeAttribute("data-dismissed")
  }
}
