# Dropdown Menu (Menu-Band Exemplar) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `dropdown_menu` to the 10-point DoD as the menu-band exemplar — replacing the old popover-shaped component with the full WAI-ARIA APG menu-button contract behind a new dedicated `menu` Stimulus controller (roving tabindex, type-ahead, Escape/Tab/outside-click dismissal), CSS anchor positioning, and a browser-axe AAA proof.

**Architecture:** Two repos, two PRs. **Gem** (`modelrails_ui`, branch `harden/menu-widgets-band` — already holds the band design + this plan): rewrite the component template, add `menu_controller.js` (delete the old `dropdown_controller.js`), add a structure-only 0a render test, update the doc + ledger. **App** (`modelrails_base`, new branch `feat/ui-dropdown-menu` off `main`): temp-pin the Gemfile to the gem branch, re-vendor, add a template-backed preview + `@param` playground, and a 0b system spec that drives the keyboard contract and proves AAA in both themes. The render harness can't run JS, so all keyboard/roving behavior is proven in the app 0b (per the `dialog`/`popover` precedent); axe proves *structural* AAA only.

**Tech Stack:** Ruby 4.0.5 (gem) / 4.0.4 (app), Rails 8.1, ViewComponent 4, Stimulus (importmap), TailwindCSS 4 (OKLCH semantic tokens), CSS anchor positioning (Baseline 2026), RSpec + Capybara + Playwright + axe-core (WCAG 2.2 AAA, CI-only 7:1 hook).

**Design contract:** `docs/design/2026-06-07-menu-widgets-band-design.md` (§1 a11y contract, §2 the `menu` controller, §3 positioning, §-DoD). This plan implements only the **`dropdown_menu` exemplar**; `context_menu` and `menubar` are later, separate plans.

**Toolchain (exact):**
- **Gem** (`/Users/dschmura/Documents/code/modelrails_ui`): `mise.toml` is untrusted, so prefix Ruby commands with the explicit Ruby on PATH:
  `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …`
- **App** (`/Users/dschmura/Documents/code/modelrails_base`): `mise exec -- bundle exec …`

---

## File Structure

**Gem (`modelrails_ui`):**

| File | Responsibility | Action |
|---|---|---|
| `lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js` | The shared `menu` Stimulus controller: open/close, roving tabindex, type-ahead, dismissal | Create |
| `lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_controller.js` | Old thin toggle controller — superseded by `menu` | Delete |
| `lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_menu_component.rb.tt` | The hardened component: trigger button + `role=menu` panel + `with_item` slots + anchor positioning | Rewrite |
| `test/render/dropdown_menu_render_test.rb` | 0a structure-only render test (asserts the static role/tabindex/data scaffolding the controller drives) | Create |
| `docs/components/dropdown_menu.md` | Component usage doc (menu-button shape) | Rewrite |
| `COMPONENT_STATUS.md` | Ledger row → `hardened` (gem) then `proven` (after app CI) | Modify |

**App (`modelrails_base`):**

| File | Responsibility | Action |
|---|---|---|
| `Gemfile` | Temp-pin `modelrails_ui` git branch → `harden/menu-widgets-band` for vendoring | Modify (temp) |
| `app/components/ui/dropdown_menu_component.rb` | Vendored component (owned by the app at runtime) | Create (via generator) |
| `app/javascript/controllers/menu_controller.js` | Vendored `menu` controller | Create (via generator) |
| `app/javascript/controllers/dropdown_controller.js` | Stale orphan (no matching component) — superseded | Delete |
| `spec/components/previews/ui/dropdown_menu_component_preview.rb` | Lookbook/ViewComponent preview class + `@param` playground | Create |
| `spec/components/previews/ui/dropdown_menu_component_preview/{basic,positioned,playground}.html.erb` | Preview templates the 0b visits | Create |
| `spec/system/ui/dropdown_menu_component_spec.rb` | 0b browser-axe + keyboard-contract proof | Create |

---

## Task 1: The `menu` Stimulus controller

**Files:**
- Create: `lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js`
- Delete: `lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_controller.js`

> **No gem-side JS test harness exists** — JS behavior is proven in the app 0b (Task 7), exactly as `floating_controller.js`/`modal_controller.js` are. This task's verification is a Node syntax check; the contract is exercised end-to-end in Task 7.

- [ ] **Step 1: Write the controller**

Create `lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Behavior for the menu-pattern band. dropdown_menu is the exemplar/home; context_menu
// and menubar reuse this via EXTRA_STIMULUS. CSS owns positioning (anchor positioning);
// this owns the WAI-ARIA APG menu-button contract: open/close + aria-expanded sync,
// roving-tabindex item navigation (arrows / Home / End / type-ahead, skipping
// aria-disabled), and Escape / Tab / outside-click dismissal with focus restoration.
// Activation is native: each item is a <button>/<a>, so Enter/Space/click fire its own
// action — `activate` only blocks disabled items and closes the menu.
export default class extends Controller {
  static targets = ["trigger", "menu", "item"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.typeBuffer = ""
    this.typeTimer = null
  }

  disconnect() {
    if (this.typeTimer) clearTimeout(this.typeTimer)
  }

  // --- open / close -------------------------------------------------------

  toggle(event) {
    if (event) event.preventDefault()
    this.openValue ? this.close() : this.open()
  }

  // Trigger keydown: Enter / Space / ArrowDown open and focus the first item;
  // ArrowUp opens and focuses the last.
  triggerKeydown(event) {
    if (["Enter", " ", "ArrowDown"].includes(event.key)) {
      event.preventDefault()
      this.open()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.open({ focus: "last" })
    }
  }

  open({ focus = "first" } = {}) {
    if (this.openValue) return
    this.openValue = true
    this.menuTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    focus === "last" ? this.focusLast() : this.focusFirst()
  }

  close({ restoreFocus = true } = {}) {
    if (!this.openValue) return
    this.openValue = false
    this.menuTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    if (restoreFocus) this.triggerTarget.focus()
  }

  closeOnClickOutside(event) {
    if (this.openValue && !this.element.contains(event.target)) {
      this.close({ restoreFocus: false })
    }
  }

  // --- roving navigation --------------------------------------------------

  get enabledItems() {
    return this.itemTargets.filter((el) => el.getAttribute("aria-disabled") !== "true")
  }

  focusItem(item) {
    this.itemTargets.forEach((el) => el.setAttribute("tabindex", el === item ? "0" : "-1"))
    item.focus()
  }

  focusFirst() {
    const items = this.enabledItems
    if (items.length) this.focusItem(items[0])
  }

  focusLast() {
    const items = this.enabledItems
    if (items.length) this.focusItem(items[items.length - 1])
  }

  // Menu keydown — delegated from items via bubbling.
  navigate(event) {
    const items = this.enabledItems
    if (!items.length) return
    const current = items.indexOf(document.activeElement)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.focusItem(items[(current + 1) % items.length])
        break
      case "ArrowUp":
        event.preventDefault()
        this.focusItem(items[(current - 1 + items.length) % items.length])
        break
      case "Home":
        event.preventDefault()
        this.focusItem(items[0])
        break
      case "End":
        event.preventDefault()
        this.focusItem(items[items.length - 1])
        break
      case "Escape":
        event.preventDefault()
        this.close()
        break
      case "Tab":
        // Let focus leave naturally to the next page element, but close the menu.
        this.close({ restoreFocus: false })
        break
      case "Enter":
      case " ":
        // Let the focused <button>/<a> activate natively (→ click → activate).
        break
      default:
        if (event.key.length === 1) this.typeAhead(event.key)
    }
  }

  typeAhead(char) {
    this.typeBuffer += char.toLowerCase()
    if (this.typeTimer) clearTimeout(this.typeTimer)
    this.typeTimer = setTimeout(() => { this.typeBuffer = "" }, 1000)

    const items = this.enabledItems
    const start = Math.max(0, items.indexOf(document.activeElement))
    for (let n = 1; n <= items.length; n++) {
      const item = items[(start + n) % items.length]
      if (item.textContent.trim().toLowerCase().startsWith(this.typeBuffer)) {
        this.focusItem(item)
        return
      }
    }
  }

  // --- activation ---------------------------------------------------------

  activate(event) {
    if (event.currentTarget.getAttribute("aria-disabled") === "true") {
      event.preventDefault()
      return
    }
    this.close()
  }
}
```

- [ ] **Step 2: Delete the old controller**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git rm lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_controller.js
```

- [ ] **Step 3: Syntax-check the new controller**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_ui
node --check lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js && echo "OK"
```
Expected: `OK` (no syntax errors).

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js
git commit -m "feat(menu): add shared menu Stimulus controller; drop old dropdown controller

APG menu-button behavior — open/close + aria-expanded sync, roving tabindex
(arrows/Home/End/type-ahead skipping aria-disabled), Escape/Tab/outside-click
dismissal with focus restoration. Activation is native (items are button/a);
activate() only blocks disabled and closes."
```

---

## Task 2: 0a render test (RED)

**Files:**
- Create: `test/render/dropdown_menu_render_test.rb`

The render test asserts only the **static scaffolding** the controller relies on (roles, tabindex, ids, `data-*` wiring, fail-loud guards). It is written first and MUST fail against the current (old) component.

- [ ] **Step 1: Write the failing render test**

Create `test/render/dropdown_menu_render_test.rb`:

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "dropdown_menu", "dropdown_menu_component.rb.tt"

# STRUCTURE-only render specs. The `menu` controller's BEHAVIOR (open/close, roving
# tabindex, type-ahead, Escape/Tab/outside-click dismissal + focus restoration) is
# proven by the app 0b browser spec (spec/system/ui/dropdown_menu_component_spec.rb) —
# the render harness cannot exercise JS, so here we assert the static scaffolding the
# controller drives.
class DropdownMenuRenderTest < ViewComponent::TestCase
  def render_menu(**opts)
    render_inline(UI::DropdownMenuComponent.new(**opts)) do |c|
      c.with_trigger { "Actions" }
      c.with_item { "Edit" }
      c.with_item(disabled: true) { "Archive" }
      c.with_item(separator: true)
      c.with_item(href: "/x") { "Open in new tab" }
    end
  end

  def test_wrapper_wires_the_menu_controller_and_outside_click
    render_menu(id: "m1")

    assert_selector "div[data-controller='menu']" \
                    "[data-action~='click@document->menu#closeOnClickOutside']" \
                    "[style*='anchor-name: --m1']", visible: :all
  end

  def test_trigger_is_a_real_button_with_menu_aria
    render_menu(id: "m2")

    assert_selector "button[type='button'][id='m2-trigger'][aria-haspopup='menu']" \
                    "[aria-expanded='false'][aria-controls='m2'][data-menu-target='trigger']" \
                    "[data-action~='click->menu#toggle'][data-action~='keydown->menu#triggerKeydown']",
                    text: "Actions", visible: :all
  end

  def test_menu_panel_is_labelled_by_the_trigger_and_hidden
    render_menu(id: "m3")

    assert_selector "div#m3[role='menu'][aria-labelledby='m3-trigger'][tabindex='-1'][hidden]" \
                    "[data-menu-target='menu'][data-action~='keydown->menu#navigate']" \
                    "[style*='position-anchor: --m3']", visible: :all
  end

  def test_items_are_menuitems_with_roving_tabindex_and_activate_action
    render_menu

    assert_selector "button[role='menuitem'][type='button'][tabindex='-1']" \
                    "[data-menu-target='item'][data-action~='click->menu#activate']",
                    text: "Edit", visible: :all
  end

  def test_disabled_item_is_aria_disabled
    render_menu

    assert_selector "[role='menuitem'][aria-disabled='true']", text: "Archive", visible: :all
  end

  def test_separator_item_renders_a_separator_role
    render_menu

    assert_selector "div[role='separator']", visible: :all
  end

  def test_href_item_renders_an_anchor_menuitem
    render_menu

    assert_selector "a[role='menuitem'][href='/x'][data-menu-target='item']",
                    text: "Open in new tab", visible: :all
  end

  def test_icon_only_trigger_takes_an_aria_label
    render_inline(UI::DropdownMenuComponent.new(aria_label: "Row actions")) do |c|
      c.with_trigger { "⋮" }
      c.with_item { "Edit" }
    end

    assert_selector "button[aria-haspopup='menu'][aria-label='Row actions']", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) do
      render_inline(UI::DropdownMenuComponent.new) { |c| c.with_item { "Edit" } }
    end
    assert_match(/with_trigger/, error.message)
  end

  def test_fail_loud_on_unknown_side
    assert_raises(ArgumentError) { UI::DropdownMenuComponent.new(side: :diagonal) }
  end

  def test_fail_loud_on_unknown_align
    assert_raises(ArgumentError) { UI::DropdownMenuComponent.new(align: :middle) }
  end
end
```

- [ ] **Step 2: Run the render test — verify it FAILS**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest test/render/dropdown_menu_render_test.rb
```
Expected: FAIL — the current component has no `data-controller='menu'`, no `role=menu`, no `with_item` slot (it raises `NoMethodError`/assertion failures). This proves the test exercises the new contract.

- [ ] **Step 3: Commit the failing test**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add test/render/dropdown_menu_render_test.rb
git commit -m "test(menu): 0a render scaffolding for hardened dropdown_menu (RED)"
```

---

## Task 3: Rewrite the component (GREEN)

**Files:**
- Rewrite: `lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_menu_component.rb.tt`
- Test: `test/render/dropdown_menu_render_test.rb` (from Task 2)

- [ ] **Step 1: Replace the component template**

Overwrite `lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_menu_component.rb.tt` with:

```ruby
# frozen_string_literal: true

module UI
  # # Dropdown menu
  #
  # A button that opens a menu of actions, implementing the WAI-ARIA APG menu-button
  # pattern via the `menu` Stimulus controller shipped alongside this component.
  # Placement is CSS anchor positioning: the panel is `position: fixed` (so its
  # containing block is the viewport), tethered to the trigger via `anchor-name`/
  # `position-anchor`; `position-area` places it and `position-try-fallbacks` keeps it
  # on-screen. The controller owns open/close and the keyboard model (roving tabindex,
  # type-ahead, Escape/Tab/outside-click dismissal with focus restoration).
  #
  # ## Use when
  # - A trigger opens a list of *commands/actions* (Edit, Duplicate, Delete…).
  #
  # ## Don't use when
  # - You need *selection from a list* of values — use a listbox/`select`.
  # - The content is a non-menu overlay (a form, rich detail) — use `popover`.
  #
  # ## Accessibility contract
  # - **Guarantees:** a real `<button>` trigger with `aria-haspopup="menu"`,
  #   `aria-expanded` (kept in sync) and `aria-controls`; a `role="menu"` panel named by
  #   the trigger (`aria-labelledby`); items are `role="menuitem"` with roving tabindex;
  #   keyboard nav (↑/↓ wrap skipping disabled, Home/End, type-ahead, Enter/Space
  #   activate, Escape/Tab/outside-click close) with focus restored to the trigger.
  # - **You supply:** a `with_trigger` slot (the button's visible label) and one or more
  #   `with_item` slots. Icon-only triggers MUST pass `aria_label:` (the 0b axe proves
  #   the accessible name).
  class DropdownMenuComponent < ApplicationComponent
    renders_one :trigger

    # Each item is a real menuitem button (or an anchor when `href:` is given).
    # `disabled:` marks it `aria-disabled` (skipped by keyboard nav; activation
    # rejected). `separator: true` renders a non-interactive divider in source order
    # instead of an item. Pass-through `class:`/attrs land on the element.
    renders_many :items, ->(separator: false, disabled: false, href: nil, **attrs, &block) do
      next content_tag(:div, "", role: "separator", class: SEPARATOR) if separator

      tag_name = href ? :a : :button
      el = {
        role: "menuitem",
        tabindex: "-1",
        class: cn(ITEM, attrs.delete(:class)),
        data: { menu_target: "item", action: "click->menu#activate" }
      }
      el[:href] = href if href
      el[:type] = "button" unless href
      el[:"aria-disabled"] = "true" if disabled
      content_tag(tag_name, capture(&block), **el, **attrs)
    end

    PANEL_BASE = "z-50 min-w-[8rem] overflow-hidden rounded-md border border-border " \
                 "bg-surface-overlay p-1 text-text-body shadow-md outline-none"

    # Menu item: focus-visible AND hover share the same highlight (roving focus must be
    # visible — no bare outline-none). Disabled items are inert + de-emphasised on
    # semantic tokens. SVG sizing/colour normalised. AAA contrast of the focus highlight
    # is adjudicated by the app 0b CI axe (the 7:1 hook is CI-only), not locally.
    ITEM = "relative flex w-full cursor-pointer select-none items-center gap-2 rounded-sm " \
           "px-2 py-1.5 text-sm outline-none " \
           "hover:bg-surface-sunken hover:text-text-heading " \
           "focus-visible:bg-surface-sunken focus-visible:text-text-heading " \
           "aria-disabled:pointer-events-none aria-disabled:opacity-60 aria-disabled:cursor-not-allowed " \
           "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 " \
           "[&_svg:not([class*='text-'])]:text-text-muted"
    SEPARATOR = "-mx-1 my-1 h-px bg-border"

    SIDES  = %i[bottom top].freeze
    ALIGNS = %i[start end].freeze

    # Anchor-positioning placement — `side` (bottom/top) × `align` (start/end). Each value
    # carries the gap margin, the modern path (supports-[position-area]: `fixed` + a
    # `position-area` cell + `position-try-fallbacks: flip-block` to stay on-screen) and
    # the pre-Baseline `absolute` fallback offsets. `span-right`/`span-left` edge-align the
    # menu to the trigger (unlike a tooltip, which centres). One line per placement.
    # rubocop:disable Layout/LineLength
    PLACEMENTS = {
      bottom_start: "mt-1 supports-[position-area:bottom]:fixed supports-[position-area:bottom]:[position-area:bottom_span-right] supports-[position-area:bottom]:[position-try-fallbacks:flip-block] not-supports-[position-area:bottom]:absolute not-supports-[position-area:bottom]:top-full not-supports-[position-area:bottom]:left-0",
      bottom_end:   "mt-1 supports-[position-area:bottom]:fixed supports-[position-area:bottom]:[position-area:bottom_span-left] supports-[position-area:bottom]:[position-try-fallbacks:flip-block] not-supports-[position-area:bottom]:absolute not-supports-[position-area:bottom]:top-full not-supports-[position-area:bottom]:right-0",
      top_start:    "mb-1 supports-[position-area:bottom]:fixed supports-[position-area:bottom]:[position-area:top_span-right] supports-[position-area:bottom]:[position-try-fallbacks:flip-block] not-supports-[position-area:bottom]:absolute not-supports-[position-area:bottom]:bottom-full not-supports-[position-area:bottom]:left-0",
      top_end:      "mb-1 supports-[position-area:bottom]:fixed supports-[position-area:bottom]:[position-area:top_span-left] supports-[position-area:bottom]:[position-try-fallbacks:flip-block] not-supports-[position-area:bottom]:absolute not-supports-[position-area:bottom]:bottom-full not-supports-[position-area:bottom]:right-0"
    }.freeze
    # rubocop:enable Layout/LineLength

    # side:          :bottom | :top
    # align:         :start | :end (edge-aligned to the trigger)
    # id:            menu id (auto-generated if omitted; → aria-controls + anchor name)
    # aria_label:    trigger accessible name (REQUIRED for icon-only triggers)
    # trigger_class: CSS for the trigger button (default canonical .btn-secondary)
    def initialize(side: :bottom, align: :start, id: nil, aria_label: nil,
                   trigger_class: "btn-secondary", **html_attrs)
      @id            = id || "menu-#{SecureRandom.hex(4)}"
      @trigger_id    = "#{@id}-trigger"
      @side          = validate(:side, side, SIDES)
      @align         = validate(:align, align, ALIGNS)
      @aria_label    = aria_label
      @trigger_class = trigger_class
      @extra_class   = html_attrs.delete(:class)
      @html_attrs    = html_attrs
    end

    def call
      raise ArgumentError, "UI::DropdownMenuComponent requires a with_trigger slot" unless trigger?

      content_tag(:div, **wrapper_attrs) do
        safe_join([trigger_button, menu_panel])
      end
    end

    private

    def wrapper_attrs
      {
        class: cn("relative inline-block", @extra_class),
        style: "anchor-name: --#{@id}",
        data: {
          controller: "menu",
          action: "click@document->menu#closeOnClickOutside"
        }
      }.merge(@html_attrs)
    end

    def trigger_button
      content_tag(:button, trigger,
        type: "button",
        id: @trigger_id,
        "aria-haspopup": "menu",
        "aria-expanded": "false",
        "aria-controls": @id,
        "aria-label": @aria_label,
        data: { menu_target: "trigger", action: "click->menu#toggle keydown->menu#triggerKeydown" },
        class: @trigger_class)
    end

    def menu_panel
      content_tag(:div, safe_join(items),
        id: @id,
        role: "menu",
        "aria-labelledby": @trigger_id,
        tabindex: "-1",
        hidden: true,
        style: "position-anchor: --#{@id}",
        data: { menu_target: "menu", action: "keydown->menu#navigate" },
        class: cn(PANEL_BASE, PLACEMENTS.fetch(:"#{@side}_#{@align}")))
    end

    def validate(name, value, allowed)
      key = value.to_sym
      return key if allowed.include?(key)

      raise ArgumentError,
        "UI::DropdownMenu unknown #{name}: #{value.inspect} (allowed: #{allowed.join(", ")})"
    end
  end
end
```

- [ ] **Step 2: Run the render test — verify it PASSES**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest test/render/dropdown_menu_render_test.rb
```
Expected: PASS — all assertions green (11 tests).

- [ ] **Step 3: Run the full gem render suite (no regressions)**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test
```
Expected: all render tests pass (the new file included; no other component affected).

- [ ] **Step 4: Lint the generated Ruby (RuboCop omakase)**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rubocop lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_menu_component.rb.tt test/render/dropdown_menu_render_test.rb
```
Expected: no offenses (the `rubocop:disable Layout/LineLength` scopes the placement table). Autocorrect any incidental `SpaceInside*` offenses with `-A` and re-run.

- [ ] **Step 5: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/dropdown_menu/dropdown_menu_component.rb.tt
git commit -m "feat(menu): harden dropdown_menu to APG menu-button (GREEN)

Button trigger (aria-haspopup=menu/expanded/controls); role=menu panel named by
the trigger (aria-labelledby); with_item slots → role=menuitem (roving tabindex),
disabled→aria-disabled, separator + href variants; CSS anchor positioning
(side×align, span-* edge-aligned, flip-block fallback); fail-loud side/align."
```

---

## Task 4: Gem doc + ledger

**Files:**
- Rewrite: `docs/components/dropdown_menu.md`
- Modify: `COMPONENT_STATUS.md`

- [ ] **Step 1: Rewrite the component doc**

Overwrite `docs/components/dropdown_menu.md` with:

```markdown
# Dropdown menu

A button that opens a menu of actions, implementing the WAI-ARIA APG menu-button
pattern. Open/close and the full keyboard model live in the `menu` Stimulus
controller shipped with this component; placement is CSS anchor positioning.

Requires `menu_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add dropdown_menu
```

Creates `app/components/ui/dropdown_menu_component.rb` and
`app/javascript/controllers/menu_controller.js`.

## Usage

```erb
<%= render(UI::DropdownMenuComponent.new) do |c| %>
  <% c.with_trigger { "Actions" } %>
  <% c.with_item { "Edit" } %>
  <% c.with_item(disabled: true) { "Archive" } %>
  <% c.with_item(separator: true) %>
  <% c.with_item(href: "/reports/new") { "New report" } %>
<% end %>
```

The `with_trigger` slot is required (omitting it raises `ArgumentError`). Each
`with_item` becomes a `role="menuitem"`:

| Option | Effect |
|--------|--------|
| `disabled: true` | `aria-disabled` — skipped by keyboard nav, activation rejected |
| `separator: true` | renders a divider (no content) in source order |
| `href: "/path"` | renders an `<a role="menuitem">` instead of a `<button>` |

Icon-only triggers MUST pass `aria_label:` (the menu button's accessible name):

```erb
<%= render(UI::DropdownMenuComponent.new(aria_label: "Row actions")) do |c| %>
  <% c.with_trigger { tag.svg(...) } %>
  ...
<% end %>
```

## Placement

| Arg | Values | Default |
|-----|--------|---------|
| `side` | `:bottom`, `:top` | `:bottom` |
| `align` | `:start`, `:end` (edge-aligned to the trigger) | `:start` |

Placement uses CSS anchor positioning with an `absolute`-offset fallback on
pre-Baseline-2026 browsers; `position-try-fallbacks: flip-block` keeps the menu
on-screen.

## Keyboard

| Key | Action |
|-----|--------|
| `Enter` / `Space` / `↓` (on trigger) | Open, focus first item |
| `↑` (on trigger) | Open, focus last item |
| `↓` / `↑` (in menu) | Move (wraps, skips disabled) |
| `Home` / `End` | First / last item |
| type a letter | Jump to the next item starting with it (1s buffer) |
| `Enter` / `Space` / click | Activate item, close |
| `Escape` | Close, return focus to trigger |
| `Tab` | Close, advance focus to the next page element |

## Accessibility

WCAG 2.2 AAA. The menu is named by its trigger (`aria-labelledby`); the trigger
exposes `aria-haspopup="menu"` and a synced `aria-expanded`. Roving tabindex keeps
exactly one item focusable at a time. Proven by `spec/system/ui/dropdown_menu_component_spec.rb`
in the host app (keyboard + axe AAA in both themes).
```

- [ ] **Step 2: Update the ledger row → `hardened`**

In `COMPONENT_STATUS.md`, the components table currently ends at the `hover_card` row. Add a new row immediately after it:

```markdown
| dropdown_menu | hardened | ✅ | ⏳ | Menu-band exemplar (Wave 6): APG menu-button via shared `menu` controller (roving tabindex, type-ahead, Escape/Tab/outside-click dismissal); CSS anchor positioning (side×align). 0a render test; app 0b CI-pending |
```

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add docs/components/dropdown_menu.md COMPONENT_STATUS.md
git commit -m "docs(menu): dropdown_menu usage doc + ledger row (hardened)"
```

> **Gem PR gate:** after this commit, the gem branch `harden/menu-widgets-band` holds the band design, this plan, and the exemplar implementation. Do NOT push or open the gem PR yet — the app adoption (Tasks 5–8) must prove the 0b first, and pushing is user-gated. Continue to the app tasks; the human opens both PRs together after the full app suite is green (Task 8).

---

## Task 5: App — temp-pin Gemfile + re-vendor

> **⚠️ CORRECTION (post-execution, 2026-06-07): do NOT delete the app's `dropdown_controller.js`.**
> This plan wrongly classified the host app's `app/javascript/controllers/dropdown_controller.js`
> as a "stale orphan." It is NOT — it powers the hand-rolled user menu and workspace switcher
> (`shared/_user_menu.html.erb`, `shared/_user_menu_avatar_button.html.erb`,
> `shared/_settings_sidebar_switcher.html.erb`) via `data-controller="dropdown"`, and is distinct
> from the new `menu_controller.js`. Deleting it (commit `8a14468`) broke 25 specs; it was restored
> in commit `9f8f93c`. Only the **gem template's** `dropdown_controller.js` was a true orphan (Task 1's
> `git rm` of it is correct). Skip Step 4 below; keep the app controller.

**Files:**
- Modify (temp): `/Users/dschmura/Documents/code/modelrails_base/Gemfile`
- Create (via generator): `app/components/ui/dropdown_menu_component.rb`, `app/javascript/controllers/menu_controller.js`
- ~~Delete: `app/javascript/controllers/dropdown_controller.js`~~ **(KEEP — see correction above; not an orphan)**

- [ ] **Step 1: Create the app adoption branch**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git checkout main && git pull --ff-only
git checkout -b feat/ui-dropdown-menu
```

- [ ] **Step 2: Temp-pin the Gemfile to the gem branch**

In `/Users/dschmura/Documents/code/modelrails_base/Gemfile`, change the `modelrails_ui` git dependency branch from `modelrails/harden` to the in-flight gem branch. Find:

```ruby
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "modelrails/harden"
```

Replace with:

```ruby
  # TEMP-PIN: re-pin to "modelrails/harden" after the dropdown_menu gem PR merges.
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "harden/menu-widgets-band"
```

> The gem branch is not yet pushed. For local vendoring, point Bundler at the local checkout instead by setting a local override (no push required):
> ```bash
> cd /Users/dschmura/Documents/code/modelrails_base
> mise exec -- bundle config set --local local.modelrails_ui /Users/dschmura/Documents/code/modelrails_ui
> ```
> Bundler will use the local working copy for the `harden/menu-widgets-band` branch. Remove this override before opening the PR (Step 6).

- [ ] **Step 3: Install + regenerate the component**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle install
mise exec -- bin/rails g modelrails_ui:add dropdown_menu --force
```
Expected: writes `app/components/ui/dropdown_menu_component.rb` and `app/javascript/controllers/menu_controller.js`.

- [ ] ~~**Step 4: Remove the stale orphan controller**~~ **— SKIP (see correction at the top of Task 5; the app's `dropdown_controller.js` is live, not an orphan).**

```bash
# DO NOT RUN — kept for the record of what the plan originally (wrongly) instructed:
# git rm app/javascript/controllers/dropdown_controller.js
```
(There is no `dropdown_menu` component using it; `menu_controller.js` supersedes it.)

- [ ] **Step 5: Verify the vendored files match the gem**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
diff <(sed 's/^/ /' app/javascript/controllers/menu_controller.js) <(sed 's/^/ /' /Users/dschmura/Documents/code/modelrails_ui/lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js) && echo "CONTROLLER MATCHES"
grep -q "role: \"menu\"" app/components/ui/dropdown_menu_component.rb && echo "COMPONENT VENDORED"
```
Expected: `CONTROLLER MATCHES` and `COMPONENT VENDORED`. (Per-repo RuboCop may normalise the component's formatting — that is the expected semantic-not-byte parity; the controller is copied verbatim.)

- [ ] **Step 6: Commit the vendor (keep the temp-pin note for now)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add app/components/ui/dropdown_menu_component.rb app/javascript/controllers/menu_controller.js Gemfile Gemfile.lock
git add -u app/javascript/controllers/dropdown_controller.js
git commit -m "feat(ui): vendor hardened dropdown_menu + menu controller; drop stale dropdown controller"
```

---

## Task 6: App — preview + `@param` playground

**Files:**
- Create: `spec/components/previews/ui/dropdown_menu_component_preview.rb`
- Create: `spec/components/previews/ui/dropdown_menu_component_preview/basic.html.erb`
- Create: `spec/components/previews/ui/dropdown_menu_component_preview/positioned.html.erb`
- Create: `spec/components/previews/ui/dropdown_menu_component_preview/playground.html.erb`

> DoD item 10: the playground uses `render_with_template(locals:)` + a `playground.html.erb` (a preview method must return a rendered result — a string-wrap `%(...).html_safe` raises `TypeError: no implicit conversion of Symbol into Integer`).

- [ ] **Step 1: Write the preview class**

Create `spec/components/previews/ui/dropdown_menu_component_preview.rb`:

```ruby
# frozen_string_literal: true

module UI
  # # Dropdown menu
  #
  # A button that opens a menu of actions (WAI-ARIA APG menu-button), driven by the
  # `menu` Stimulus controller. Open with the trigger; navigate with ↑/↓/Home/End or
  # type-ahead; Enter/Space/click activates; Escape/Tab/outside-click closes.
  #
  # ## Accessibility contract
  # - **Guarantees:** `aria-haspopup="menu"` + synced `aria-expanded`; `role="menu"`
  #   named by the trigger; `role="menuitem"` items with roving tabindex.
  # - **You supply:** a `with_trigger` slot and `with_item` slots; `aria_label:` for
  #   icon-only triggers.
  class DropdownMenuComponentPreview < ViewComponent::Preview
    include UIHelper

    # Standard menu: a button trigger and a labelled menu with items, a disabled item,
    # a separator, and a link item.
    def basic
    end

    # `side:` and `align:` edge-align the menu to the trigger.
    def positioned
    end

    # Edit `side` and `align` live to explore placement.
    # @param side select [bottom, top]
    # @param align select [start, end]
    def playground(side: :bottom, align: :start)
      render_with_template(locals: { side: side.to_sym, align: align.to_sym })
    end
  end
end
```

- [ ] **Step 2: Write `basic.html.erb`**

Create `spec/components/previews/ui/dropdown_menu_component_preview/basic.html.erb`:

```erb
<div class="p-24 flex justify-center">
  <%= render(UI::DropdownMenuComponent.new) do |c| %>
    <% c.with_trigger { "Actions" } %>
    <% c.with_item { "Edit" } %>
    <% c.with_item { "Duplicate" } %>
    <% c.with_item(disabled: true) { "Archive" } %>
    <% c.with_item(separator: true) %>
    <% c.with_item(href: "#") { "Open docs" } %>
  <% end %>
</div>
```

- [ ] **Step 3: Write `positioned.html.erb`**

Create `spec/components/previews/ui/dropdown_menu_component_preview/positioned.html.erb`:

```erb
<div class="p-24 flex justify-end">
  <%= render(UI::DropdownMenuComponent.new(side: :bottom, align: :end)) do |c| %>
    <% c.with_trigger { "Filters" } %>
    <% c.with_item { "Newest first" } %>
    <% c.with_item { "Oldest first" } %>
    <% c.with_item { "A–Z" } %>
  <% end %>
</div>
```

- [ ] **Step 4: Write `playground.html.erb`**

Create `spec/components/previews/ui/dropdown_menu_component_preview/playground.html.erb`:

```erb
<div class="p-24 flex justify-center">
  <%= render(UI::DropdownMenuComponent.new(side: side, align: align)) do |c| %>
    <% c.with_trigger { "Menu (#{side}/#{align})" } %>
    <% c.with_item { "First action" } %>
    <% c.with_item { "Second action" } %>
    <% c.with_item(disabled: true) { "Disabled action" } %>
    <% c.with_item(separator: true) %>
    <% c.with_item { "Last action" } %>
  <% end %>
</div>
```

- [ ] **Step 5: Verify the preview routes render**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails runner '
  %w[basic positioned].each do |s|
    html = ApplicationController.render(
      template: "ui/dropdown_menu_component_preview/#{s}",
      layout: false,
      prepend_views: ["spec/components/previews"]
    )
    raise "missing role=menu in #{s}" unless html.include?(%q{role="menu"})
    puts "#{s}: OK"
  end
'
```
Expected: `basic: OK` and `positioned: OK`. (If the runner path differs, the authoritative check is the 0b visiting the live preview URL in Task 7 — proceed and let the system spec be the gate.)

- [ ] **Step 6: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/components/previews/ui/dropdown_menu_component_preview.rb spec/components/previews/ui/dropdown_menu_component_preview/
git commit -m "test(ui): dropdown_menu previews + @param playground"
```

---

## Task 7: App — 0b browser-axe + keyboard-contract spec

**Files:**
- Create: `spec/system/ui/dropdown_menu_component_spec.rb`

This is the **real gate** for the keyboard/roving behavior and AAA. Mirror the popover 0b shape (`spec/system/ui/popover_component_spec.rb`): visit the preview URL, open via the real button, audit the live menu, and assert focus moves via `document.activeElement`.

- [ ] **Step 1: Write the system spec**

Create `spec/system/ui/dropdown_menu_component_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

# Preview-host accessibility + behavior proof for the dropdown_menu component.
#
# JS-BEHAVIOR pattern: the menu lives in the DOM but stays hidden until the trigger
# fires. We OPEN it via the real button and audit the LIVE menu.
#
# NOTE: the per-spec axe call runs axe's default (AA) rule set; the authoritative AAA
# 7:1 audit is the CI-only wcag2aaa after-hook (spec/support/playwright_accessibility.rb).
RSpec.describe "Dropdown menu component accessibility", type: :system do
  def open_menu
    find("button[aria-haspopup='menu']").click
    expect(page).to have_css("[role='menu']:not([hidden])")
  end

  def focused_text
    page.evaluate_script("document.activeElement.textContent.trim()")
  end

  %w[basic positioned].each do |scenario|
    it "#{scenario}: opens a menu that passes AAA in both themes" do
      visit "/rails/view_components/ui/dropdown_menu_component/#{scenario}"

      expect(page).to have_css("button[aria-haspopup='menu'][aria-expanded='false']")
      expect(page).to have_css("[role='menu'][aria-labelledby]", visible: :all)

      open_menu

      expect(page).to have_css("button[aria-haspopup='menu'][aria-expanded='true']")

      scope = [ "[role='menu']:not([hidden])" ]
      expect(axe_clean_in_both_themes?(include: scope)).to(
        be(true),
        axe_violations_in_both_themes(include: scope).join("\n")
      )
    end
  end

  it "opens from the keyboard (Enter on the trigger) and focuses the first item" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    find("button[aria-haspopup='menu']").send_keys(:enter)

    expect(page).to have_css("[role='menu']:not([hidden])")
    expect(focused_text).to eq("Edit")
  end

  it "ArrowUp on the trigger opens and focuses the last item" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    find("button[aria-haspopup='menu']").send_keys(:up)

    expect(focused_text).to eq("Open docs")
  end

  it "ArrowDown wraps and SKIPS the disabled item" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    open_menu # focus on "Edit"

    page.send_keys(:down) # Duplicate
    expect(focused_text).to eq("Duplicate")
    page.send_keys(:down) # skips disabled "Archive" → "Open docs"
    expect(focused_text).to eq("Open docs")
    page.send_keys(:down) # wraps → "Edit"
    expect(focused_text).to eq("Edit")
  end

  it "type-ahead focuses the next item starting with the typed letter" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    open_menu # focus on "Edit"

    page.send_keys("d") # → "Duplicate"
    expect(focused_text).to eq("Duplicate")
  end

  it "End focuses the last item, Home the first" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    open_menu

    page.send_keys(:end)
    expect(focused_text).to eq("Open docs")
    page.send_keys(:home)
    expect(focused_text).to eq("Edit")
  end

  it "closes on Escape and returns focus to the trigger" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    open_menu

    page.send_keys(:escape)

    expect(page).to have_css("[role='menu'][hidden]", visible: :all)
    expect(page).to have_css("button[aria-haspopup='menu'][aria-expanded='false']")
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-haspopup')")).to eq("menu")
  end

  it "closes on an outside click" do
    visit "/rails/view_components/ui/dropdown_menu_component/basic"
    open_menu

    page.driver.with_playwright_page { |pw| pw.mouse.click(5, 5) }

    expect(page).to have_css("[role='menu'][hidden]", visible: :all)
  end
end
```

- [ ] **Step 2: Run the system spec locally (AA gate)**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/dropdown_menu_component_spec.rb
```
Expected: all examples PASS locally (axe runs AA locally; the AAA 7:1 hook is CI-only). If a keyboard example fails, the bug is in `menu_controller.js` (Task 1) — fix there, re-vendor (`bin/rails g modelrails_ui:add dropdown_menu --force` + recopy the controller), and re-run. Do NOT weaken the spec.

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/system/ui/dropdown_menu_component_spec.rb
git commit -m "test(ui): 0b browser-axe + keyboard contract for dropdown_menu (open/roving/type-ahead/escape/AAA)"
```

---

## Task 8: App — full suite + handoff gate

**Files:** none (verification + handoff)

- [ ] **Step 1: Run the full app test suite**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec
```
Expected: 0 failures. Investigate any pending examples (do not relay "N pending" without a reason). If failures are unrelated infra transients, note them; otherwise fix before proceeding.

- [ ] **Step 2: Lint (herb-lint + rubocop, matching CI/Lefthook)**

Run:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rubocop app/components/ui/dropdown_menu_component.rb spec/components/previews/ui/dropdown_menu_component_preview.rb spec/system/ui/dropdown_menu_component_spec.rb
npx @herb-tools/linter spec/components/previews/ui/dropdown_menu_component_preview/*.html.erb
```
Expected: no offenses. (If herb-lint isn't pinned locally, Lefthook pre-push will run it; the ERB here uses no `raw`/inline handlers.)

- [ ] **Step 3: STOP — human handoff (do not push)**

Pushing and opening PRs are user-gated (visual UI changes need browser review; the gem branch isn't pushed yet). Report to the human:

> dropdown_menu exemplar complete. **Gem** (`harden/menu-widgets-band`): controller + hardened component + 0a render test + doc + ledger (`hardened`), committed locally. **App** (`feat/ui-dropdown-menu`): vendored component + controller, stale `dropdown_controller.js` removed, previews + playground, 0b spec (keyboard + axe), full suite green locally. Ready for browser review at `/rails/view_components/ui/dropdown_menu_component/playground` and `/lookbook`. On your OK I'll: (a) push the gem branch + open the gem PR into `modelrails/harden`; (b) after it merges, re-pin the app Gemfile `modelrails_ui` branch back to `modelrails/harden` + remove the local Bundler override; (c) push the app branch + open the app PR; (d) after app CI's AAA `test` job is green, flip the gem ledger row `dropdown_menu` → `proven ✅ ✅` in a follow-up gem commit (cross-repo ledger lag, per prior waves).

---

## Self-Review

**1. Spec coverage** (design §1/§2/§3/§-DoD → tasks):
- §1 trigger contract (button, aria-haspopup/expanded/controls) → Task 3 `trigger_button`; render-asserted Task 2; keyboard-proven Task 7. ✅
- §1 accessible-name guard (icon-only `aria_label:`) → Task 3 `@aria_label`; render Task 2 `test_icon_only_trigger_takes_an_aria_label`; axe Task 7. ✅
- §1 menu/menuitem/separator + `role=group` → menu/menuitem/separator covered (Tasks 2/3); `role=group` grouped-label structure is **not** exercised here (no grouped scenario) — acceptable: groups land with context_menu/menubar; flat menu is the exemplar. Noted as a deliberate scope edge, not a gap. ✅
- §1 disabled items (aria-disabled, skip nav/type-ahead, reject activate) → controller `enabledItems`/`activate` (Task 1); render Task 2; behavior Task 7 (`ArrowDown … SKIPS`). ✅
- §1 roving tabindex, ↑/↓ wrap, Home/End, type-ahead 1s, input-agnostic activation, focus edges (Tab advances, else restore), Escape, Shift+F10 → all in Task 1 controller + Task 7 specs, **except Shift+F10** which is a `context_menu` behavior (out of scope for the dropdown_menu exemplar). ✅
- §2 dedicated `menu` controller via colocated file (dropdown_menu is home) → Task 1. EXTRA_STIMULUS is NOT touched (only needed when context_menu/menubar reuse it — later plans). ✅
- §3 anchor positioning (side×align, span-* edge-aligned, fixed, flip-block, fallback) → Task 3 `PLACEMENTS`. ✅
- §-DoD: renders/tokens/ARIA/fail-loud/focus+44px/disabled/i18n/doc/slot/preview+playground + 0a + 0b → Tasks 2–7. **i18n:** the component renders no first-party strings (all text is author-supplied via slots), so there are no locale keys to add — consistent with popover/tooltip. **44px targets:** items are `px-2 py-1.5 text-sm` (~32px tall) — flag for browser review; if the AAA target-size check (2.5.5) fails in CI, bump item min-height (`min-h-11`) and re-run. ✅

**2. Placeholder scan:** No TBD/TODO. `{menu_id}`/`--#{@id}` are real interpolations. All code blocks are complete. ✅

**3. Type/name consistency:** controller targets (`trigger`/`menu`/`item`) ↔ component `data-menu-target` values match; actions (`menu#toggle`/`triggerKeydown`/`navigate`/`closeOnClickOutside`/`activate`) match between component wiring (Task 3), render assertions (Task 2), and the controller (Task 1); `PLACEMENTS` keys (`bottom_start`…) match the `:"#{@side}_#{@align}"` fetch; preview scenario names (`basic`/`positioned`/`playground`) match the 0b visits. ✅

**Two flagged-for-browser-review items** (CI/visual, not local): (a) AAA contrast of the `focus-visible:bg-surface-sunken` item highlight; (b) the 44px target-size of items. Both are adjudicated by the app CI `test` (AAA) job per the repo's CI-only axe hook — surfaced honestly rather than claimed.
