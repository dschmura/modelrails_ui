// Quill is an OPT-IN dependency — pin it only if you use `adapter: "quill"`:
//   pin "quill", to: "https://cdn.jsdelivr.net/npm/quill@2/+esm"
// Also add Quill's stylesheet to your CSS entry point:
//   @import url("https://cdn.jsdelivr.net/npm/quill@2/dist/quill.snow.css");
// It is imported lazily (only when the quill adapter is active), so the default
// Trix adapter never pulls it in and an unpinned app gets a hint, not an error.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor", "input"]
  static values  = {
    adapter:     { type: String,  default: "trix" },
    placeholder: { type: String,  default: "" },
    height:      { type: Number,  default: 200 },
    toolbar:     { type: Boolean, default: true }
  }

  #quill = null

  connect() {
    if (this.adapterValue === "quill") this.#initQuill()
  }

  disconnect() {
    this.#quill = null
  }

  async #initQuill() {
    let Quill
    try {
      ({ default: Quill } = await import("quill"))
    } catch {
      console.info(
        '[ui:wysiwyg] Quill is not pinned — the editor will not initialize. Add to config/importmap.rb:\n' +
        '  pin "quill", to: "https://cdn.jsdelivr.net/npm/quill@2/+esm"\n' +
        'and import its stylesheet in your CSS:\n' +
        '  @import url("https://cdn.jsdelivr.net/npm/quill@2/dist/quill.snow.css");'
      )
      return
    }

    this.#quill = new Quill(this.editorTarget, {
      theme: "snow",
      placeholder: this.placeholderValue,
      modules: { toolbar: this.toolbarValue }
    })
    if (this.inputTarget.value) {
      this.#quill.root.innerHTML = this.inputTarget.value
    }
    this.#quill.on("text-change", () => {
      this.inputTarget.value = this.#quill.root.innerHTML
    })
  }
}
