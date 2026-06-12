# Wave 4 Overlays — Dialog-Family Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Harden `alert_dialog`, `drawer`, and `sheet` to the 10-point DoD by re-basing all three onto the native-`<dialog>` pattern of the hardened `dialog` exemplar, reusing one generalized `modal_controller.js`.

**Architecture:** All three become native `<dialog role=…>` elements (deleting their hand-rolled `bg-black/*` overlay divs — they inherit the app's `dialog::backdrop` rule). They reuse `modal_controller.js`, which is generalized so the open/close *transform* is a Stimulus Value (`enterTransform`/`leaveTransform`) defaulting to `scale` — so `dialog` is byte-unchanged, `drawer` slides up (`translateY(100%)`), `sheet` slides from its side. drawer and sheet stay separate components.

**Tech Stack:** Ruby 4.0.5 (gem `.ruby-version`), ViewComponent, Stimulus, Minitest (gem render tests), RSpec+Capybara+Playwright+axe (app 0b specs), TailwindCSS v4.

**Toolchain (gem):** mise.toml is untrusted — prefix ruby cmds: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake` (NOT `mise exec`). Default `rake` = `test:structural` + `test:render` + rubocop. Render-test deps live in the GEMSPEC (Appraisal lane). **App toolchain:** `cd /Users/dschmura/Documents/code/modelrails_base && mise exec -- bundle exec rspec …`.

**The exemplar to clone (read these first):**
- `lib/generators/modelrails_ui/add/templates/dialog/dialog_component.rb.tt` — the component structure.
- `lib/generators/modelrails_ui/add/templates/dialog/modal_controller.js` — the reused controller.
- `test/render/dialog_render_test.rb` — the 0a render-test pattern.
- (app) `spec/system/ui/dialog_component_spec.rb` — the 0b browser-spec pattern.

**The 10-point DoD** (each component must satisfy): renders · AAA semantic tokens only (no raw `bg-black/*`) · correct ARIA (`role`, `aria-modal`, `aria-labelledby`→heading id, conditional `aria-describedby`) · fail-loud guard on any enum · focus + 44px targets (close button `btn-touch-target`) · disabled/invalid n/a · i18n (no hardcoded strings) · doc-comment (Use when / Don't use when / Accessibility contract) · slot API (`renders_one :trigger, :footer`) · template-backed Lookbook preview. Plus: 0a render test + 0b browser spec.

---

## File Structure

**Gem** (branch per component → bundle into `harden/wave4-overlays`):
| File | Change |
|---|---|
| `…/add/templates/dialog/modal_controller.js` | Generalize transform via Stimulus Values (scale defaults). Shared — do FIRST. |
| `…/add/templates/alert_dialog/alert_dialog_component.rb.tt` | Rewrite as native `<dialog role="alertdialog">`. |
| `…/add/templates/drawer/drawer_component.rb.tt` | Rewrite as native bottom `<dialog>`; **delete** `drawer/drawer_controller.js`. |
| `…/add/templates/sheet/sheet_component.rb.tt` | Rewrite as native side `<dialog>`; fail-loud `coerce_side`; **delete** `sheet/sheet_controller.js`. |
| `test/render/{alert_dialog,drawer,sheet}_render_test.rb` | New 0a render tests. |
| `…/lookbook/templates/previews/ui/{alert_dialog,drawer,sheet}_component_preview.rb` (+ scenario `.html.erb`) | New template-backed previews. |
| `COMPONENT_STATUS.md` | Add 3 rows (hardened). |

**App** (one branch `feat/ui-overlays-dialog-family`):
| File | Change |
|---|---|
| `app/components/ui/{alert_dialog,drawer,sheet}_component.rb` | Vendor via `rails g modelrails_ui:add`. |
| `app/javascript/controllers/modal_controller.js` | Re-vendor the generalized controller. |
| `spec/components/previews/ui/{…}_component_preview.rb` (+ scenarios) | Vendor previews. |
| `spec/system/ui/{alert_dialog,drawer,sheet}_component_spec.rb` | New 0b browser specs. |

**Orchestration:** worktree-parallel gem hardening (one worktree per component under `/private/tmp/mrui-wt/<name>`), but **Task 1 (controller) must land first** since all three depend on it. Then bundle the 3 component branches into `harden/wave4-overlays` → one gem PR. App adoption = one sequential branch. Cross-sibling consistency review before fan-out completes.

---

### Task 1: Generalize `modal_controller.js` (shared — do FIRST)

**Files:** Modify `lib/generators/modelrails_ui/add/templates/dialog/modal_controller.js`

- [ ] **Step 1: Add transform Values + use them in the animations.**

Change the `static values` block (line 5) to:
```js
  static values = {
    open: { type: Boolean, default: false },
    enterTransform: { type: String, default: "scale(1)" },
    leaveTransform: { type: String, default: "scale(0.95)" }
  }
```
In `animateIn()`: replace the reduced-motion branch's `this.panelTarget.style.transform = "scale(1)"` with `this.panelTarget.style.transform = this.enterTransformValue`; replace the pre-rAF `this.panelTarget.style.transform = "scale(0.95)"` with `this.leaveTransformValue`; and inside the `requestAnimationFrame` callback replace `this.panelTarget.style.transform = "scale(1)"` with `this.enterTransformValue`.
In `animateOut()`: replace `this.panelTarget.style.transform = "scale(0.95)"` with `this.leaveTransformValue`.
Leave everything else (open/close/handleCancel/handleClick/focus-restore/duration logic) unchanged.

- [ ] **Step 2: Verify `dialog` is unaffected (the default path).**

`dialog` passes no transform values → defaults are `scale(1)`/`scale(0.95)` → identical behavior. Run the gem render suite (dialog render test must stay green):
```bash
cd /Users/dschmura/Documents/code/modelrails_ui && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake
```
Expected: PASS (render + structural + rubocop). The render test is structure-only, so it doesn't exercise the JS — the real proof is the app's dialog 0b spec staying green after app adoption (Task 7).

- [ ] **Step 3: Commit** (on the shared base branch `harden/wave4-overlays` off `modelrails/harden`):
```bash
git commit -am "feat(overlays): parameterize modal_controller transform (scale default) for slide reuse"
```

---

### Task 2: Harden `alert_dialog` → native `<dialog role="alertdialog">`

**Files:** Modify `…/add/templates/alert_dialog/alert_dialog_component.rb.tt`; Create `test/render/alert_dialog_render_test.rb`

`alert_dialog` is a centered confirm dialog — structurally **dialog with `role="alertdialog"`, no slide** (uses the controller's scale default), and the actions live in the `footer` slot (the confirm/cancel buttons). `description:` is the alert message and MUST wire `aria-describedby`.

- [ ] **Step 1: Rewrite the component.** Clone `dialog_component.rb.tt`'s structure (`call`/`wrapper_attrs`/`trigger_area`/`dialog_tag`/`panel`/`header`/`close_button`/`body`/`description_tag`/`footer_area`/`close_label`/`close_icon`) with these deltas:
  - Class `AlertDialogComponent`. Doc-comment: Use when (a choice must be confirmed before proceeding — destructive/irreversible actions); Don't use when (a non-blocking notice → toast; a plain form → dialog); Accessibility contract (`role="alertdialog"`, `aria-modal`, `aria-labelledby`→title, `aria-describedby`→message, focus trap+restore via `modal`).
  - `initialize(title:, id: nil, description: nil, open: false, wrapper: true, **html_attrs)` — **no `size:`** (alert dialogs are a fixed `max-w-md`). `@id ||= "alertdialog-#{SecureRandom.hex(4)}"`.
  - `dialog_attrs`: `role: "alertdialog"` (not `"dialog"`), keep `aria-modal`, `aria-labelledby: "#{@id}-title"`, conditional `aria-describedby`, `data: { modal_target: "dialog" }`, same transparent class.
  - `panel`: same `PANEL` constant + `data: { modal_target: "panel" }`; fixed width `max-w-md` (no SIZES map).
  - **Delete** the old `OVERLAY`/`PANEL` raw constants and the `data-controller="dialog"` wiring — use `data-controller="modal"` (via the cloned `wrapper_attrs`).
  - `title:` is REQUIRED (raise if missing — it's the accessible name; ViewComponent raises on a missing required kwarg automatically).
  - Keep the `close_button` (44px `btn-touch-target`, i18n `close_label`) — even alert dialogs need an escape affordance.

- [ ] **Step 2: Write the render test** `test/render/alert_dialog_render_test.rb`. Clone `dialog_render_test.rb` with: `load_component "alert_dialog", "alert_dialog_component.rb.tt"`; assert `dialog[role='alertdialog'][aria-modal='true']`; `aria-labelledby` → `h2#…-title`; `description:` wires `aria-describedby` to `p#…-description`; omits `aria-describedby` without description; accessible close button `[aria-label='Close'][data-action~='click->modal#close']`; AAA tokens (`[data-modal-target='panel'].bg-surface-overlay`, `h2.text-text-heading`); `wrapper: false` renders only the dialog; footer slot renders.

- [ ] **Step 3: Run** `PATH=… bundle exec rake` (in the alert_dialog worktree) → PASS. **Commit** `feat(overlays): harden alert_dialog to native <dialog role=alertdialog> + 0a`.

---

### Task 3: Harden `drawer` → native bottom `<dialog>` (slide up)

**Files:** Modify `…/add/templates/drawer/drawer_component.rb.tt`; **Delete** `…/add/templates/drawer/drawer_controller.js`; Create `test/render/drawer_render_test.rb`

`drawer` = a bottom sheet: full-width native `<dialog>` pinned to the bottom edge, sliding up. Decorative drag-handle (`aria-hidden`) + a real 44px close button.

- [ ] **Step 1: Rewrite the component.** Clone the dialog structure with these deltas:
  - `initialize(title:, id: nil, description: nil, open: false, wrapper: true, **html_attrs)` (no enum).
  - `wrapper_attrs`: add the slide transform values to the controller data:
    ```ruby
    data = { controller: "modal", modal_enter_transform_value: "translateY(0)", modal_leave_transform_value: "translateY(100%)" }
    ```
  - `dialog_attrs`: `role: "dialog"`, `aria-modal`, `aria-labelledby`, conditional `aria-describedby`. The `<dialog>` is pinned to the bottom full-width — set classes `class: "bg-transparent backdrop:bg-transparent m-0 mt-auto w-full max-w-full p-0"` (override the centered default; the implementer confirms edge-pinning in the 0b/preview — native `<dialog>` shown via `showModal()` is fixed-positioned, so `mt-auto` + `m-0` pins it to the bottom; adjust if the preview shows otherwise).
  - `panel`: closed-state classes `opacity-0 translate-y-full` (instead of `opacity-0 scale-95`); rounded-top, full-width: `relative w-full rounded-t-xl bg-surface-overlay border-t border-border shadow-xl max-h-[calc(100vh-3rem)] flex flex-col opacity-0 translate-y-full`. `data: { modal_target: "panel" }`.
  - Add a **decorative** drag-handle as the first panel child: `content_tag(:div, content_tag(:div, nil, class: "h-1.5 w-12 rounded-full bg-surface-sunken"), class: "flex justify-center pt-3 pb-1", "aria-hidden": "true")`.
  - Keep `header` (with the 44px `close_button`, i18n) + `body` + `footer_area` from the clone.
  - **Delete** the old `OVERLAY`/`PANEL` raw constants, the `data-controller="drawer"` wiring, and the `drawer_controller.js` file.

- [ ] **Step 2: Write `test/render/drawer_render_test.rb`** — clone dialog's, `load_component "drawer", "drawer_component.rb.tt"`; assert native `dialog[role='dialog'][aria-modal='true']`; `aria-labelledby`/`aria-describedby` wiring; 44px close button wired to `modal#close`; AAA tokens (`.bg-surface-overlay`); the drag-handle is `[aria-hidden='true']`; the wrapper carries `data-modal-enter-transform-value='translateY(0)'`.

- [ ] **Step 3:** `rake` green → **Commit** `feat(overlays): harden drawer to native bottom <dialog> (slide) + 0a; drop drawer_controller`.

---

### Task 4: Harden `sheet` → native side `<dialog>` (per-side slide) + fail-loud `side`

**Files:** Modify `…/add/templates/sheet/sheet_component.rb.tt`; **Delete** `…/add/templates/sheet/sheet_controller.js`; Create `test/render/sheet_render_test.rb`

`sheet` = a side panel: native `<dialog>` pinned to `@side` (right/left/top/bottom), sliding in from that edge. `side:` becomes **fail-loud** (program lesson: silent `.fetch` → `coerce`).

- [ ] **Step 1: Rewrite the component.** Clone the dialog structure with these deltas:
  - `SIDES` (panel edge classes) and a `LEAVE_TRANSFORMS = { right: "translateX(100%)", left: "translateX(-100%)", top: "translateY(-100%)", bottom: "translateY(100%)" }.freeze`.
  - `initialize(title:, id: nil, description: nil, side: :right, open: false, wrapper: true, **html_attrs)`; `@side = coerce_side(side.to_sym)`.
  - `coerce_side(side)` — **fail-loud** like button's `coerce_variant`: `return side if SIDES.key?(side); raise ArgumentError, "UI::SheetComponent: unknown side #{side.inspect}. Expected: #{SIDES.keys.join(', ')}." unless Rails-production` then fallback `:right` in production. (Copy the exact `coerce_variant` guard shape from `button_component.rb.tt`.)
  - `wrapper_attrs`: `data = { controller: "modal", modal_enter_transform_value: side_enter_transform, modal_leave_transform_value: LEAVE_TRANSFORMS.fetch(@side) }` where `side_enter_transform` = `"translateX(0)"` for left/right, `"translateY(0)"` for top/bottom.
  - `dialog_attrs`: native `<dialog>` pinned to `@side` (set positioning classes per side; the panel's slid-out closed transform comes from the `leave_transform`). `role: "dialog"`, `aria-modal`, `aria-labelledby`, conditional `aria-describedby`.
  - `panel`: `bg-surface-overlay` + the per-side size class (`SIDES.fetch(@side)`) + closed-state `opacity-0` + the leave transform applied initially via a class or inline (closed state). `data: { modal_target: "panel" }`.
  - **Fix the close button**: the existing sub-44px `p-1` close → use the cloned dialog `close_button` (`btn-touch-target`, i18n `close_label`, `helpers.icon(:x_mark)`). Remove the hardcoded `"Close"`.
  - **Delete** the old `OVERLAY` raw constant, `data-controller="sheet"`, and `sheet_controller.js`.

- [ ] **Step 2: Write `test/render/sheet_render_test.rb`** — clone dialog's + add: `dialog[role='dialog']`; default `side: :right` → wrapper `data-modal-leave-transform-value='translateX(100%)'`; `side: :left` → `translateX(-100%)`; **fail-loud**: `assert_raises(ArgumentError) { render_inline(UI::SheetComponent.new(title: "T", side: :diagonal)) }`; 44px i18n close button; AAA tokens.

- [ ] **Step 3:** `rake` green → **Commit** `feat(overlays): harden sheet to native side <dialog> (per-side slide) + fail-loud side + 0a; drop sheet_controller`.

---

### Task 5: Template-backed Lookbook previews (all 3)

**Files:** Create `…/lookbook/templates/previews/ui/{alert_dialog,drawer,sheet}_component_preview.rb` (+ scenario `.html.erb` files), cloning `dialog_component_preview.rb`'s structure.

- [ ] Each preview defines scenarios that render the component **with a trigger slot** (so the 0b spec can open it) — at minimum `basic` and one component-specific scenario (alert_dialog: `confirm_destructive` with footer confirm/cancel; drawer: `with_footer`; sheet: `side_left`). Match dialog's template-backed style (a `.html.erb` per scenario). Run the gem suite green; **commit** on each component's branch.

---

### Task 6: Bundle gem PR + COMPONENT_STATUS

- [ ] Merge the 3 component branches (+ the Task-1 controller commit) into `harden/wave4-overlays` (off `modelrails/harden`). Resolve any cross-sibling drift (uniform a11y wiring, id-fallback, i18n). Add 3 `COMPONENT_STATUS.md` rows (alert_dialog/drawer/sheet → `hardened`, note "native `<dialog>`; 0a + 0b open/escape/slide + AAA; app 0b CI-pending"). Full `rake` green. Push → **one gem PR → `modelrails/harden`.** (Do not merge until the app 0b proves green — Task 7.)

---

### Task 7: App adoption + 0b browser specs (the real proof)

**Files (app `modelrails_base`, branch `feat/ui-overlays-dialog-family`):** vendor + 0b specs.

- [ ] **Step 1: Bump the app's gem ref** to the `harden/wave4-overlays` SHA (or keep `branch: modelrails/harden` and merge the gem PR first, then `bundle update modelrails_ui`). Vendor: `mise exec -- bin/rails g modelrails_ui:add alert_dialog drawer sheet` → copies the 3 components + the generalized `modal_controller.js` (review the diff; `modal_controller` updates the dialog's vendored copy — re-verify dialog). Commit the vendored files.

- [ ] **Step 2: Vendor previews + write 0b specs.** Clone `spec/system/ui/dialog_component_spec.rb` per component. Each 0b spec: visit `/rails/view_components/ui/<name>_component/<scenario>`, assert closed-DOM ARIA scaffolding, open via `[data-action~='click->modal#open']`, then `axe_clean_in_both_themes?(include: ["dialog[open]"])` (no contrast exclude), AND assert the native Escape path closes (`page.send_keys(:escape)` → `have_no_css("dialog[open]")`). **Behavioral OUTCOME assertions per the program's biggest lesson** — assert the slide actually happened: for drawer/sheet, after open, assert the panel's computed `transform` is the enter transform (e.g. not the leave `translate`), proving the controller drove the slide (not a no-op). For alert_dialog, assert `dialog[role='alertdialog'][open]` + the message is `aria-describedby`-linked.

- [ ] **Step 3: Run the app suite green.** `mise exec -- bundle exec rspec spec/system/ui spec/components/ui` then full `rspec`. **The dialog 0b spec MUST stay green** (proves the controller generalization didn't regress it). Commit; push (Lefthook full CI) → **app PR → main.**

---

## Self-Review

- **DoD coverage:** native `<dialog>` + ARIA + fail-loud (sheet `coerce_side`) + 44px i18n close + slot API + render test (0a) + preview + 0b — Tasks 2–7. alert_dialog `bg-black/80` removed (native backdrop) ✓. sheet sub-44px close fixed ✓. drawer close button added ✓.
- **Controller reuse without dialog regression:** Task 1 defaults to scale → dialog unchanged; re-proven by dialog's app 0b staying green (Task 7 Step 3). ✓
- **Behavioral 0b (the program's biggest lesson):** Task 7 Step 2 asserts the slide OUTCOME (computed transform), not just structure — catches a controller no-op the render harness can't see. ✓
- **Placeholder check:** the edge-positioning Tailwind classes (drawer `mt-auto`; sheet per-side) are specified as a starting point with the 0b/preview as the verification gate — the implementer finalizes exact classes against the rendered preview (native-`<dialog>` positioning is browser-verified, not assertable in the render harness). This is the one deliberately preview-finalized detail.
- **Cross-sibling consistency:** Task 6 bundles + reviews uniform a11y wiring before the gem PR.
