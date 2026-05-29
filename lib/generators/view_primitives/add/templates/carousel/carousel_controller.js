import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "dots"]
  static values = { loop: { type: Boolean, default: true }, autoplay: { type: Number, default: 0 } }

  connect() {
    this._index = 0
    this._count = this.trackTarget.children.length
    if (this.autoplayValue > 0) {
      this._timer = setInterval(() => this.next(), this.autoplayValue)
    }
  }

  disconnect() {
    clearInterval(this._timer)
  }

  next() {
    this._go(this._index + 1)
  }

  prev() {
    this._go(this._index - 1)
  }

  goTo({ params: { index } }) {
    this._go(index)
  }

  _go(index) {
    if (this.loopValue) {
      index = ((index % this._count) + this._count) % this._count
    } else {
      index = Math.max(0, Math.min(index, this._count - 1))
    }
    this._index = index
    this.trackTarget.style.transform = `translateX(-${index * 100}%)`
    this._updateDots()
  }

  _updateDots() {
    if (!this.hasDotsTarget) return
    Array.from(this.dotsTarget.children).forEach((dot, i) => {
      dot.dataset.active = String(i === this._index)
    })
  }
}
