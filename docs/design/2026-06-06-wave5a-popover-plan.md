# Wave 5a Popover — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `popover` to the 10-point DoD — a real `<button>` trigger with `aria-haspopup`/`aria-expanded`/`aria-controls`, a `role="dialog"` panel named by `label:`, Escape + outside-click dismissal with focus return — driven by a new shared `floating` Stimulus controller.

**Architecture:** CSS in-flow positioning is retained (a `relative` wrapper + `absolute` panel, author picks `side`/`align`); a new `floating` controller (replacing `popover_controller.js`) owns open/close, `aria-expanded` sync, focus return, and dismissal. Non-modal — no focus trap. See `2026-06-06-wave5-floating-overlays-design.md`.

**Tech Stack:** Ruby 4.0.5 (gem), ViewComponent, Stimulus, Minitest (gem 0a render tests), RSpec + Capybara + Playwright + axe (app 0b spec), TailwindCSS v4.

**Toolchain:**

- **Gem:** `mise.toml` is untrusted — prefix Ruby commands: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake` (NOT `mise exec`). Default `rake` = `test:structural` + `test:render` + rubocop.
- **App:** `cd /Users/dschmura/Documents/code/modelrails_base && mise exec -- bundle exec rspec …`.

**Branches:** Gem work on `harden/wave5-floating-overlays` (already created off `modelrails/harden`, design doc committed). App work on `feat/ui-popover`.

---

## File Structure

**Gem** (`harden/wave5-floating-overlays`):

| File | Change |
|---|---|
| `lib/generators/modelrails_ui/add/templates/popover/floating_controller.js` | **Create** — shared controller. Do FIRST. |
| `lib/generators/modelrails_ui/add/templates/popover/popover_controller.js` | **Delete** — superseded. |
| `lib/generators/modelrails_ui/add/templates/popover/popover_component.rb.tt` | **Rewrite** — button trigger, `role="dialog"` panel, ARIA, `label:`, fail-loud coercion. |
| `test/render/popover_render_test.rb` | **Create** — 0a render test. |
| `lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview.rb` (+ `popover_component_preview/{basic,positioned}.html.erb`) | **Create** — template-backed preview. |
| `COMPONENT_STATUS.md` | Add `popover` row (hardened). |
| `docs/components/popover.md` | Refresh to the hardened contract. |

**App** (`feat/ui-popover`):

| File | Change |
|---|---|
| `Gemfile` / `Gemfile.lock` | Temp-pin `modelrails_ui` to `branch: "harden/wave5-floating-overlays"`. |
| `app/components/ui/popover_component.rb` | Vendor via `rails g modelrails_ui:add popover`. |
| `app/javascript/controllers/floating_controller.js` | Vendored with popover (colocated controller). |
| `spec/components/previews/ui/popover_component_preview.rb` (+ scenarios) | Vendor preview. |
| `spec/system/ui/popover_component_spec.rb` | **Create** — 0b browser spec. |

**Orchestration:** Task 1 (controller) lands first. Gem tasks 1–5 produce one gem PR into `modelrails/harden`; app Task 6 pins to the gem branch and produces one app PR. Task 7 is the land/re-pin sequence (avoids the dangling-pin trap from Wave 4).

---

### Task 1: Create the shared `floating` controller (do FIRST)

**Files:**

- Create: `lib/generators/modelrails_ui/add/templates/popover/floating_controller.js`
- Delete: `lib/generators/modelrails_ui/add/templates/popover/popover_controller.js`

- [ ] **Step 1: Write the controller.**

```js
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
}
```

- [ ] **Step 2: Delete the old controller.**

Run: `git rm lib/generators/modelrails_ui/add/templates/popover/popover_controller.js`

- [ ] **Step 3: Commit.**

```bash
git add lib/generators/modelrails_ui/add/templates/popover/floating_controller.js
git commit -m "feat(floating): shared floating controller for the overlays band (replaces popover_controller)"
```

---

### Task 2: Harden `popover_component.rb.tt` (0a TDD)

**Files:**

- Create: `test/render/popover_render_test.rb`
- Modify: `lib/generators/modelrails_ui/add/templates/popover/popover_component.rb.tt`

- [ ] **Step 1: Write the failing render test.**

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "popover", "popover_component.rb.tt"

# STRUCTURE-only render specs. The `floating` controller's BEHAVIOR (click toggle,
# Escape/outside close, focus return) is proven by the app 0b browser spec
# (spec/system/ui/popover_component_spec.rb) — the render harness cannot exercise
# JS, so here we assert the static scaffolding the controller relies on.
class PopoverRenderTest < ViewComponent::TestCase
  def render_popover(**opts)
    attrs = { label: "Account menu" }.merge(opts)
    render_inline(UI::PopoverComponent.new(**attrs)) do |c|
      c.with_trigger { "Open" }
      "Panel body"
    end
  end

  def test_wrapper_wires_the_floating_controller_and_dismissal_actions
    render_popover

    assert_selector "div[data-controller='floating']" \
                    "[data-action~='keydown.esc->floating#close']" \
                    "[data-action~='click@document->floating#closeOnClickOutside']", visible: :all
  end

  def test_trigger_is_a_real_button_with_popup_aria
    render_popover(id: "p1")

    assert_selector "button[type='button'][aria-haspopup='dialog'][aria-expanded='false']" \
                    "[aria-controls='p1'][data-floating-target='trigger']" \
                    "[data-action~='click->floating#toggle']", text: "Open", visible: :all
  end

  def test_panel_is_a_labelled_dialog_hidden_until_open
    render_popover(id: "p2", label: "Account menu")

    assert_selector "div#p2[role='dialog'][aria-label='Account menu'][tabindex='-1'][hidden]" \
                    "[data-floating-target='panel']", visible: :all
  end

  def test_panel_carries_aaa_tokens_and_positioning
    render_popover(side: :top, align: :end)

    assert_selector "[data-floating-target='panel'].bg-surface-overlay.text-text-body", visible: :all
    assert_selector "[data-floating-target='panel'].bottom-full.right-0", visible: :all
  end

  def test_fail_loud_on_unknown_side
    error = assert_raises(ArgumentError) do
      UI::PopoverComponent.new(label: "x", side: :sideways)
    end
    assert_match(/unknown side/, error.message)
  end

  def test_fail_loud_on_unknown_align
    assert_raises(ArgumentError) do
      UI::PopoverComponent.new(label: "x", align: :middle)
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails.**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest test/render/popover_render_test.rb`
Expected: FAIL — the current component renders a `<span>` trigger and has no `label:`/`role="dialog"`/fail-loud coercion.

- [ ] **Step 3: Rewrite the component.**

Replace the entire contents of `popover_component.rb.tt` with:

```ruby
# frozen_string_literal: true

module UI
  # # Popover
  #
  # A non-modal floating panel anchored to a trigger button. Behavior lives in the
  # `floating` Stimulus controller shipped alongside this component; positioning is
  # CSS (a `relative` wrapper + `absolute` panel — the author picks `side`/`align`).
  #
  # ## Use when
  # - You need a small interactive overlay (a menu of actions, a filter form, details)
  #   tied to a trigger that does NOT need to block the page.
  #
  # ## Don't use when
  # - The content must block interaction until dismissed — use `dialog`/`alert_dialog`.
  # - You only need a hint describing a control — use `tooltip`.
  # - The trigger sits inside an `overflow:hidden` / transformed ancestor that would
  #   clip the panel (there is no top layer) — restructure or use a `dialog`.
  #
  # ## Accessibility contract
  # - **Guarantees:** a real `<button>` trigger with `aria-haspopup="dialog"`,
  #   `aria-expanded` (kept in sync), and `aria-controls` to the panel; the panel is
  #   `role="dialog"` named by `label:`; Escape and outside-click close and return
  #   focus to the trigger. Non-modal — focus is NOT trapped.
  # - **You supply:** a `label:` (the panel's accessible name) and a `with_trigger`
  #   slot (the button's visible content).
  class PopoverComponent < ApplicationComponent
    renders_one :trigger

    PANEL_BASE = "absolute z-50 w-72 rounded-md border border-border bg-surface-overlay p-4 " \
                 "text-sm text-text-body shadow-md outline-none"

    ALIGN = {
      start:  "left-0",
      center: "left-1/2 -translate-x-1/2",
      end:    "right-0"
    }.freeze

    SIDE = {
      bottom: "top-full mt-2",
      top:    "bottom-full mb-2",
      left:   "right-full mr-2 top-0",
      right:  "left-full ml-2 top-0"
    }.freeze

    # label:         the panel's accessible name (required → aria-label on role=dialog)
    # id:            panel id (auto-generated if omitted; wired to aria-controls)
    # align:         :start | :center | :end
    # side:          :bottom | :top | :left | :right
    # trigger_class: CSS for the trigger button (default canonical .btn-secondary)
    def initialize(label:, id: nil, align: :start, side: :bottom, trigger_class: "btn-secondary", **html_attrs)
      @label         = label
      @id            = id || "popover-#{SecureRandom.hex(4)}"
      @align         = coerce(:align, align, ALIGN)
      @side          = coerce(:side, side, SIDE)
      @trigger_class = trigger_class
      @extra_class   = html_attrs.delete(:class)
      @html_attrs    = html_attrs
    end

    def call
      content_tag(:div, **wrapper_attrs) do
        safe_join([trigger_button, panel])
      end
    end

    private

    def wrapper_attrs
      {
        class: cn("relative inline-block", @extra_class),
        data: {
          controller: "floating",
          action: "keydown.esc->floating#close click@document->floating#closeOnClickOutside"
        }
      }.merge(@html_attrs)
    end

    def trigger_button
      content_tag(:button, trigger,
        type: "button",
        "aria-haspopup": "dialog",
        "aria-expanded": "false",
        "aria-controls": @id,
        data: { floating_target: "trigger", action: "click->floating#toggle" },
        class: @trigger_class)
    end

    def panel
      content_tag(:div, content,
        id: @id,
        role: "dialog",
        "aria-label": @label,
        tabindex: "-1",
        hidden: true,
        data: { floating_target: "panel" },
        class: cn(PANEL_BASE, ALIGN.fetch(@align), SIDE.fetch(@side)))
    end

    def coerce(name, value, map)
      key = value.to_sym
      return key if map.key?(key)

      raise ArgumentError,
        "UI::Popover unknown #{name}: #{value.inspect} (allowed: #{map.keys.join(", ")})"
    end
  end
end
```

- [ ] **Step 4: Run the test to verify it passes, then the full gem suite.**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest test/render/popover_render_test.rb`
Expected: PASS (6 tests).

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake`
Expected: PASS (structural + render + rubocop, no offenses).

- [ ] **Step 5: Commit.**

```bash
git add test/render/popover_render_test.rb \
        lib/generators/modelrails_ui/add/templates/popover/popover_component.rb.tt
git commit -m "feat(popover): button trigger + role=dialog panel + fail-loud side/align (0a)"
```

---

### Task 3: Template-backed Lookbook preview

**Files:**

- Create: `lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview.rb`
- Create: `lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview/basic.html.erb`
- Create: `lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview/positioned.html.erb`

- [ ] **Step 1: Write the preview class.**

```ruby
# frozen_string_literal: true

module UI
  # # Popover
  #
  # A non-modal floating panel anchored to a trigger button, driven by the `floating`
  # Stimulus controller. Click the trigger to toggle; Escape or an outside click closes
  # it and returns focus to the trigger.
  #
  # ## Accessibility contract
  # - **Guarantees:** a real `<button>` trigger with `aria-haspopup="dialog"`,
  #   `aria-expanded`, and `aria-controls`; a `role="dialog"` panel named by `label:`.
  #   Non-modal — focus is not trapped.
  # - **You supply:** `label:` (the panel's accessible name) and a `with_trigger` slot.
  class PopoverComponentPreview < ViewComponent::Preview
    include UIHelper

    # Standard popover: a button trigger and a labelled dialog panel.
    def basic
    end

    # `side:` and `align:` place the panel relative to the trigger.
    def positioned
    end
  end
end
```

- [ ] **Step 2: Write `basic.html.erb`.**

```erb
<div class="p-24 flex justify-center">
  <%= render(UI::PopoverComponent.new(label: "Account menu")) do |c| %>
    <% c.with_trigger { "Open popover" } %>
    <div class="space-y-2">
      <p class="font-medium text-text-heading">Signed in as Dave</p>
      <a href="#" class="block text-text-body underline">Account settings</a>
      <a href="#" class="block text-text-body underline">Sign out</a>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Write `positioned.html.erb`.**

```erb
<div class="p-24 flex justify-center">
  <%= render(UI::PopoverComponent.new(label: "Filters", side: :bottom, align: :end)) do |c| %>
    <% c.with_trigger { "Filters" } %>
    <p class="text-text-body">Filter options go here.</p>
  <% end %>
</div>
```

- [ ] **Step 4: Commit.**

```bash
git add lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview.rb \
        lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview
git commit -m "feat(popover): template-backed Lookbook preview (basic + positioned)"
```

---

### Task 4: Ledger row + doc refresh

**Files:**

- Modify: `COMPONENT_STATUS.md`
- Modify: `docs/components/popover.md`

- [ ] **Step 1: Add the `popover` row to `COMPONENT_STATUS.md`.**

Insert this row in the table (after the dialog-family overlay rows), matching the existing column shape `| name | tier | 0a | 0b | notes |`:

```markdown
| popover | hardened | ✅ | ⏳ | Wave 5a floating exemplar (CSS positioning + shared `floating` controller; real button trigger w/ aria-haspopup/expanded/controls; role=dialog panel named by label:; Escape + outside-click close w/ focus return; fail-loud side/align). 0a render test; app 0b CI-pending |
```

- [ ] **Step 2: Rewrite `docs/components/popover.md`** to document the hardened API (`label:` required, `with_trigger` slot, `align`/`side` enums, `trigger_class:`), the accessibility contract (button trigger ARIA, role=dialog panel, Escape/outside-click + focus return, non-modal), and the documented limitation (no top layer → can be clipped by `overflow:hidden`/transformed ancestors). Mirror the prose style of `docs/components/dialog.md`.

- [ ] **Step 3: Commit.**

```bash
git add COMPONENT_STATUS.md docs/components/popover.md
git commit -m "docs(popover): hardened tier row + refreshed component doc"
```

---

### Task 5: Gem PR

- [ ] **Step 1: Run the full gem suite one more time.**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake`
Expected: PASS.

- [ ] **Step 2: Push and open the PR into `modelrails/harden`.**

```bash
git push -u origin harden/wave5-floating-overlays
gh pr create --base modelrails/harden --head harden/wave5-floating-overlays \
  --title "feat(floating): harden popover to button-tier (Wave 5a) + shared floating controller" \
  --body "Wave 5a of the floating-overlays band. Real button trigger (aria-haspopup/expanded/controls), role=dialog panel named by label:, Escape + outside-click close with focus return, fail-loud side/align. New shared \`floating\` controller (replaces popover_controller). 0a render test green; AAA proven by the app 0b spec in the companion app PR. Design: docs/design/2026-06-06-wave5-floating-overlays-design.md"
```

---

### Task 6: App adoption + 0b browser spec (behavioral TDD)

**Files:**

- Modify: `Gemfile`, `Gemfile.lock`
- Create: `spec/system/ui/popover_component_spec.rb`
- Vendor: `app/components/ui/popover_component.rb`, `app/javascript/controllers/floating_controller.js`, `spec/components/previews/ui/popover_component_preview.rb` (+ scenarios)

- [ ] **Step 1: Branch + temp-pin the gem to the Wave 5 branch.**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git switch -c feat/ui-popover origin/main
```

Edit `Gemfile` — change the `modelrails_ui` dev-group pin to:

```ruby
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "harden/wave5-floating-overlays"
```

Run: `mise exec -- bundle update modelrails_ui`
Expected: `Gemfile.lock` revision updates to the pushed branch HEAD.

- [ ] **Step 2: Write the failing 0b browser spec.**

Create `spec/system/ui/popover_component_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

# Preview-host accessibility + behavior proof for the popover component.
#
# JS-BEHAVIOR pattern: the panel lives in the DOM but stays hidden until the trigger
# fires. We OPEN it via the real button and audit the LIVE panel.
#
# NOTE: the per-spec axe call runs axe's default (AA) rule set; the authoritative AAA
# 7:1 audit is the CI-only wcag2aaa after-hook (spec/support/playwright_accessibility.rb).
RSpec.describe "Popover component accessibility", type: :system do
  def open_popover
    find("button[aria-haspopup='dialog']").click
    expect(page).to have_css("[role='dialog']:not([hidden])")
  end

  %w[basic positioned].each do |scenario|
    it "#{scenario}: opens a popover that passes AAA in both themes" do
      visit "/rails/view_components/ui/popover_component/#{scenario}"

      expect(page).to have_css("button[aria-haspopup='dialog'][aria-expanded='false']")
      expect(page).to have_css("[role='dialog'][aria-label]", visible: :all)

      open_popover

      expect(page).to have_css("button[aria-haspopup='dialog'][aria-expanded='true']")

      scope = [ "[role='dialog']:not([hidden])" ]
      expect(axe_clean_in_both_themes?(include: scope)).to(
        be(true),
        axe_violations_in_both_themes(include: scope).join("\n")
      )
    end
  end

  it "opens from the keyboard (real button — Enter)" do
    visit "/rails/view_components/ui/popover_component/basic"
    find("button[aria-haspopup='dialog']").send_keys(:enter)

    expect(page).to have_css("[role='dialog']:not([hidden])")
  end

  it "closes on Escape and returns focus to the trigger" do
    visit "/rails/view_components/ui/popover_component/basic"
    open_popover

    page.send_keys(:escape)

    expect(page).to have_css("[role='dialog'][hidden]", visible: :all)
    expect(page).to have_css("button[aria-haspopup='dialog'][aria-expanded='false']")
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-haspopup')")).to eq("dialog")
  end

  it "closes on an outside click" do
    visit "/rails/view_components/ui/popover_component/basic"
    open_popover

    page.driver.with_playwright_page { |pw| pw.mouse.click(5, 5) }

    expect(page).to have_css("[role='dialog'][hidden]", visible: :all)
  end
end
```

- [ ] **Step 3: Run the spec to verify it fails.**

Run: `mise exec -- bundle exec rspec -r rails_helper spec/system/ui/popover_component_spec.rb`
Expected: FAIL — the popover component + preview are not vendored yet (no such preview route).

- [ ] **Step 4: Vendor the component, controller, and preview.**

Run: `mise exec -- bundle exec rails g modelrails_ui:add popover`
Expected: creates `app/components/ui/popover_component.rb` and `app/javascript/controllers/floating_controller.js`.

Verify the three files exist; if the generator does not copy the preview, copy it manually:

```bash
mkdir -p spec/components/previews/ui/popover_component_preview
cp "$(bundle show modelrails_ui)/lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview.rb" spec/components/previews/ui/
cp "$(bundle show modelrails_ui)"/lib/generators/modelrails_ui/lookbook/templates/previews/ui/popover_component_preview/*.html.erb spec/components/previews/ui/popover_component_preview/
```

- [ ] **Step 5: Run the spec to verify it passes, then the full app suite.**

Run: `mise exec -- bundle exec rspec -r rails_helper spec/system/ui/popover_component_spec.rb`
Expected: PASS (6 examples).

Run: `mise exec -- bundle exec rspec`
Expected: 0 failures.

- [ ] **Step 6: Commit and push (Lefthook pre-push runs full CI).**

```bash
git add Gemfile Gemfile.lock app/components/ui/popover_component.rb \
        app/javascript/controllers/floating_controller.js \
        spec/components/previews/ui/popover_component_preview.rb \
        spec/components/previews/ui/popover_component_preview \
        spec/system/ui/popover_component_spec.rb
git commit -m "feat(ui): adopt hardened popover + floating controller + 0b proof (Wave 5a)"
git push -u origin feat/ui-popover
```

- [ ] **Step 7: Open the app PR.**

```bash
gh pr create --base main --head feat/ui-popover \
  --title "feat(ui): adopt hardened popover (button trigger + role=dialog) + 0b proof" \
  --body "Vendors the Wave 5a popover + shared floating controller. 0b proves: click + keyboard (Enter) open, aria-expanded sync, Escape + outside-click close with focus return, AAA in both themes on the live panel. Gem PR: harden/wave5-floating-overlays."
```

---

### Task 7: Land sequence (avoid the dangling-pin trap)

This is the lesson from Wave 4 (the app merged while pinned to a soon-deleted gem branch). Order matters:

- [ ] **Step 1:** Wait for BOTH PRs green (app `test` job is the AAA authority).
- [ ] **Step 2:** Merge the **gem** PR into `modelrails/harden` (this deletes `harden/wave5-floating-overlays`).
- [ ] **Step 3:** Re-pin the app `Gemfile` back to `branch: "modelrails/harden"`, `bundle update modelrails_ui`, run the suite, push to `feat/ui-popover`.
- [ ] **Step 4:** Merge the **app** PR once its CI re-runs green.

---

## Self-Review

**Spec coverage** (against `2026-06-06-wave5-floating-overlays-design.md`, popover scope):

- §2 button trigger + `aria-haspopup`/`aria-expanded`/`aria-controls` → Task 2 component + render test + 0b keyboard test. ✅
- §2 `role="dialog"` panel + required `label:` → Task 2 `panel` + render test. ✅
- §2 focus-in on open / focus-return on close → Task 1 controller + 0b focus-return test. ✅
- §2 Escape + click-outside close → Task 1 + 0b Escape/outside tests. ✅
- §2 fail-loud `side`/`align` → Task 2 `coerce` + two render tests. ✅
- §5 artifacts: 0a (Task 2), preview (Task 3), 0b (Task 6), `COMPONENT_STATUS` + docs (Task 4). ✅
- Shared `floating` controller via colocated file (popover dir), `EXTRA_STIMULUS` deferred to Wave 5b. ✅

**Placeholder scan:** No TBD/TODO; all code blocks complete. The only prose step is Task 4 Step 2 (doc rewrite), which references an existing exemplar (`docs/components/dialog.md`) rather than leaving content blank. ✅

**Type/name consistency:** `floating` controller identity, targets `trigger`/`panel`, actions `toggle`/`close`/`closeOnClickOutside`, and `data-floating-target` match across the controller (Task 1), component (Task 2), render test (Task 2), and 0b spec (Task 6). Panel `id` ↔ `aria-controls` consistent. ✅

**Note for the executor:** local 0b runs axe at AA only; the AAA 7:1 verdict comes from the app CI `test` job. Do not claim AAA from a local pass.
