# Menubar (Menu-Band #3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `menubar` + `menubar_menu` to the WAI-ARIA APG menubar pattern — a `role="menubar"` of top-level items, each opening a vertical submenu that reuses the proven `menu` controller — with a new thin `menubar` coordinator controller using Stimulus outlets.

**Architecture:** Two repos, two PRs. **Gem** (`modelrails_ui`, branch `harden/menubar` off `modelrails/harden`): rewrite `menubar_controller.js` (the coordinator), register `menubar_menu → menu` in `EXTRA_STIMULUS`, rewrite both component templates, add a 0a render test, update structural tests + doc + ledger. **App** (`modelrails_base`, branch `feat/ui-menubar` off `main`): re-vendor, add a preview, and a 0b system spec that drives the full menubar keyboard. The `menu` controller stays FROZEN (pure reuse). Key-routing is implicit: the open submenu's `menu#navigate` preventDefaults the keys it owns; `menubar#navigate` skips them via `event.defaultPrevented`; `←/→` (never claimed by `menu`) bubble to the bar.

**Tech Stack:** Ruby 4.0.5 (gem) / 4.0.4 (app), Rails 8.1, ViewComponent 4, Stimulus (importmap, **outlets**), TailwindCSS 4 (OKLCH semantic tokens, CSS anchor positioning), RSpec + Capybara + Playwright + axe-core (WCAG 2.2 AAA, CI-only 7:1 hook).

**Design contract:** `docs/design/2026-06-07-menubar-design.md` (§1 architecture, §2 key-routing, §3 a11y contract, §4 positioning, §5 files, §6 DoD, §7 risks). Single-level submenus only (nested deferred).

**Toolchain (exact):** Gem — `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …`, render load path `-Itest/render`. App — `mise exec -- bundle exec …`.

**Sibling references:** `dropdown_menu` (the item model + `bottom_start` anchor placement + render-test/preview/0b shape) and `context_menu` (the EXTRA_STIMULUS reuse + the structural-test update pattern — `test_sheet_has_js_controller`).

---

## File Structure

**Gem (`modelrails_ui`):**

| File | Responsibility | Action |
|---|---|---|
| `lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js` | The thin `menubar` coordinator (roving + `←/→`/Home/End/type-ahead + outlet coordination) | Rewrite |
| `lib/generators/modelrails_ui/add/templates/menubar/menubar_component.rb.tt` | `role=menubar` bar; `renders_many :menus`; `BAR`; outlet + keydown/focusin wiring | Rewrite |
| `lib/generators/modelrails_ui/add/templates/menubar/menubar_menu_component.rb.tt` | A `menu`-controller submenu: bar-item button (`role=menuitem`) + `role=menu` anchor-positioned panel + `with_item` slots | Rewrite |
| `lib/generators/modelrails_ui/components.rb` | `EXTRA_STIMULUS`: add `menubar_menu → menu` | Modify |
| `test/render/menubar_render_test.rb` | 0a structure-only render test | Create |
| `test/test_generator_components.rb` | menubar_menu EXTRA_STIMULUS assertion | Modify |
| `docs/components/menubar.md` | Usage doc | Create/Rewrite |
| `COMPONENT_STATUS.md` | menubar + menubar_menu rows → hardened then proven | Modify |

**App (`modelrails_base`):** `Gemfile` (temp-pin), `app/components/ui/menubar_component.rb` + `menubar_menu_component.rb` + `app/javascript/controllers/menubar_controller.js` (vendored), `spec/components/previews/ui/menubar_component_preview.rb` + template, `spec/system/ui/menubar_component_spec.rb` (0b).

---

## Task 1: The `menubar` coordinator controller + EXTRA_STIMULUS

**Files:**
- Rewrite: `lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js`
- Modify: `lib/generators/modelrails_ui/components.rb`

> No gem-side JS test; behavior is proven in the app 0b (Task 7). The `menu` controller is NOT touched (frozen — pure reuse).

- [ ] **Step 1: Rewrite the controller**

Overwrite `lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js` with EXACTLY:

```js
import { Controller } from "@hotwired/stimulus"

// Coordinator for the WAI-ARIA APG menubar. Each menubar item's submenu is its OWN `menu`
// controller (reused via EXTRA_STIMULUS, like dropdown_menu/context_menu); THIS controller
// owns only the horizontal layer — roving tabindex across the bar items, ←/→/Home/End/
// type-ahead, and opening/closing adjacent submenus via Stimulus outlets.
//
// Key-routing is implicit (no mode flag): keys the open submenu's `menu#navigate` claims are
// preventDefaulted, so we skip them via `event.defaultPrevented`; ←/→ are NEVER claimed by
// `menu` (no ArrowLeft/Right case there) so they bubble here.
// INVARIANT: never add an ArrowLeft/ArrowRight case to `menu#navigate` — the menubar relies
// on ←/→ bubbling unclaimed.
export default class extends Controller {
  static targets = ["item"]   // the bar-item buttons (each is also a `menu` trigger)
  static outlets = ["menu"]   // the per-item submenu `menu` controllers (one per item)

  connect() {
    this.typeBuffer = ""
    this.typeTimer = null
    this.resetRovingTabindex()
  }

  disconnect() {
    if (this.typeTimer) clearTimeout(this.typeTimer)
  }

  // --- roving tabindex across bar items -----------------------------------

  get enabledIndexes() {
    return this.itemTargets
      .map((el, i) => (el.getAttribute("aria-disabled") === "true" ? -1 : i))
      .filter((i) => i >= 0)
  }

  resetRovingTabindex() {
    const first = this.enabledIndexes[0] ?? 0
    this.itemTargets.forEach((el, i) => el.setAttribute("tabindex", i === first ? "0" : "-1"))
  }

  // Whichever bar item gains focus becomes the single tabbable item (covers click,
  // Escape-return, Tab, and arrow moves uniformly). Focus inside a submenu leaves roving.
  syncRoving(event) {
    const i = this.itemTargets.indexOf(event.target)
    if (i < 0) return
    this.itemTargets.forEach((el, k) => el.setAttribute("tabindex", k === i ? "0" : "-1"))
  }

  focusItem(index) {
    this.itemTargets.forEach((el, i) => el.setAttribute("tabindex", i === index ? "0" : "-1"))
    this.itemTargets[index].focus()
  }

  // The "current" bar-item index: the open submenu's item if one is open, else the focused
  // bar button, else the first enabled item.
  currentIndex() {
    const open = this.menuOutlets.findIndex((o) => o.openValue)
    if (open >= 0) return open
    const focused = this.itemTargets.indexOf(document.activeElement)
    return focused >= 0 ? focused : (this.enabledIndexes[0] ?? 0)
  }

  // --- horizontal navigation (bar level) ----------------------------------

  navigate(event) {
    if (event.defaultPrevented) return // the open submenu's menu#navigate already handled it
    switch (event.key) {
      case "ArrowRight":
        event.preventDefault()
        this.moveBy(1)
        break
      case "ArrowLeft":
        event.preventDefault()
        this.moveBy(-1)
        break
      case "Home":
        event.preventDefault()
        this.focusItem(this.enabledIndexes[0])
        break
      case "End":
        event.preventDefault()
        this.focusItem(this.enabledIndexes[this.enabledIndexes.length - 1])
        break
      default:
        // Bar-level type-ahead ONLY when no submenu is open (an open submenu owns letters;
        // its menu#typeAhead runs without preventDefault, so guard against a double-match).
        if (
          event.key.length === 1 &&
          !event.ctrlKey && !event.metaKey && !event.altKey &&
          this.menuOutlets.every((o) => !o.openValue)
        ) {
          this.typeAhead(event.key)
        }
    }
  }

  // Move to the adjacent enabled bar item (wrapping). If a submenu was open, this is the
  // menubar "follow": close the current submenu and open the adjacent one (focus its first
  // item). Otherwise just move roving focus.
  moveBy(delta) {
    const n = this.itemTargets.length
    if (n === 0) return
    const wasOpen = this.menuOutlets.findIndex((o) => o.openValue)
    const cur = this.currentIndex()
    let next = cur
    do {
      next = (next + delta + n) % n
    } while (this.itemTargets[next].getAttribute("aria-disabled") === "true" && next !== cur)
    if (wasOpen >= 0 && this.hasMenuOutlet) {
      this.menuOutlets[wasOpen].close({ restoreFocus: false })
      this.focusItem(next)
      this.menuOutlets[next].open({ focus: "first" })
    } else {
      this.focusItem(next)
    }
  }

  typeAhead(char) {
    this.typeBuffer += char.toLowerCase()
    if (this.typeTimer) clearTimeout(this.typeTimer)
    this.typeTimer = setTimeout(() => { this.typeBuffer = "" }, 1000)
    const n = this.itemTargets.length
    const start = Math.max(0, this.itemTargets.indexOf(document.activeElement))
    for (let k = 1; k <= n; k++) {
      const i = (start + k) % n
      const el = this.itemTargets[i]
      if (el.getAttribute("aria-disabled") === "true") continue
      if (el.textContent.trim().toLowerCase().startsWith(this.typeBuffer)) {
        this.focusItem(i)
        return
      }
    }
  }
}
```

- [ ] **Step 2: Register menubar_menu → menu in EXTRA_STIMULUS**

In `lib/generators/modelrails_ui/components.rb`, the `EXTRA_STIMULUS` hash currently ends:

```ruby
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"},
        "context_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"}
      }.freeze
```

Change to (add a comma + the menubar_menu line):

```ruby
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"},
        "context_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"},
        "menubar_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"}
      }.freeze
```

- [ ] **Step 3: Syntax-check + confirm dropdown_menu/context_menu render tests unaffected**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
node --check lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js && echo "JS OK"
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/dropdown_menu_render_test.rb
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/context_menu_render_test.rb
```
Expected: `JS OK`; dropdown_menu 14/14 + context_menu 12/12 (the `menu` controller is untouched; only the menubar controller + registry changed).

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js lib/generators/modelrails_ui/components.rb
git commit -m "feat(menubar): coordinator controller (roving + ←/→ + outlets) + reuse menu

Thin menubar coordinator: horizontal roving tabindex, ←/→/Home/End/type-ahead, and
opens/closes adjacent submenus via Stimulus outlets. Each submenu reuses the FROZEN
menu controller via EXTRA_STIMULUS (menubar_menu → menu). Implicit key-routing
(defaultPrevented skip; ←/→ bubble unclaimed; bar type-ahead suppressed while open)."
```

---

## Task 2: 0a render test (RED)

**Files:** Create `test/render/menubar_render_test.rb`

- [ ] **Step 1: Write the failing render test**

Create `test/render/menubar_render_test.rb`:

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "menubar", "menubar_menu_component.rb.tt"
load_component "menubar", "menubar_component.rb.tt"

# STRUCTURE-only render specs. The behavior (roving, ←/→ follow, submenu open/close, the
# outlet coordination) is proven by the app 0b browser spec — the render harness cannot
# exercise JS or Stimulus outlets, so here we assert the static scaffolding both controllers
# rely on.
class MenubarRenderTest < ViewComponent::TestCase
  def render_bar
    render_inline(UI::MenubarComponent.new(label: "Main")) do |bar|
      bar.with_menu(label: "File") do |m|
        m.with_item { "New" }
        m.with_item(disabled: true) { "Archive" }
        m.with_item(separator: true)
        m.with_item(href: "/x") { "Open recent" }
      end
      bar.with_menu(label: "Edit") do |m|
        m.with_item { "Undo" }
      end
    end
  end

  def test_bar_is_a_menubar_wired_to_the_menubar_controller_with_the_menu_outlet
    render_bar

    assert_selector "div[role='menubar'][aria-label='Main']" \
                    "[data-controller='menubar']" \
                    "[data-menubar-menu-outlet='[data-menubar-item]']" \
                    "[data-action~='keydown->menubar#navigate'][data-action~='focusin->menubar#syncRoving']",
                    visible: :all
  end

  def test_each_menu_is_a_menu_controller_outlet_target
    render_bar

    assert_selector "div[data-controller='menu'][data-menubar-item]", count: 2, visible: :all
  end

  def test_bar_item_is_a_menuitem_button_that_triggers_its_menu
    render_bar

    assert_selector "button[role='menuitem'][type='button'][aria-haspopup='menu'][aria-expanded='false']" \
                    "[tabindex='-1'][data-menu-target='trigger'][data-menubar-target='item']" \
                    "[data-action~='click->menu#toggle'][data-action~='keydown->menu#triggerKeydown']",
                    text: "File", visible: :all
  end

  def test_bar_item_controls_its_submenu_and_carries_an_anchor_name
    render_bar

    button = page.find("button", text: "File", visible: :all)
    panel_id = button["aria-controls"]
    assert_includes button["style"], "anchor-name: --#{panel_id}"
    assert_selector "div##{panel_id}[role='menu'][aria-labelledby='#{button['id']}'][hidden]" \
                    "[data-menu-target='menu'][data-action~='keydown->menu#navigate']" \
                    "[style*='position-anchor: --#{panel_id}']", visible: :all
  end

  def test_submenu_items_are_menuitems_with_roving_tabindex
    render_bar

    assert_selector "button[role='menuitem'][tabindex='-1'][data-menu-target='item']" \
                    "[data-action~='click->menu#activate']", text: "New", visible: :all
  end

  def test_submenu_disabled_separator_href_variants
    render_bar

    assert_selector "[role='menuitem'][aria-disabled='true']", text: "Archive", visible: :all
    assert_selector "div[role='separator']", visible: :all
    assert_selector "a[role='menuitem'][href='/x'][data-menu-target='item']", text: "Open recent", visible: :all
  end

  def test_submenu_panel_uses_anchor_positioning
    render_bar

    assert_selector "[data-menu-target='menu'].fixed", visible: :all
    assert_selector "[data-menu-target='menu'][class*='position-area:bottom_span-right']", visible: :all
  end

  def test_menubar_requires_label_default_and_extra_class
    c = UI::MenubarComponent.new(class: "w-full")
    assert_equal "w-full", c.instance_variable_get(:@extra_class)
  end

  def test_menubar_menu_stores_label
    c = UI::MenubarMenuComponent.new(label: "View")
    assert_equal "View", c.instance_variable_get(:@label)
  end
end
```

- [ ] **Step 2: Run — verify FAIL (RED)**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/menubar_render_test.rb
```
Expected: FAIL — the current components have no `role=menubar`, no `with_menu`/`with_item` slots with the new wiring, no `data-controller=menubar` outlet, no menu-controller-per-submenu. Failures must be CONTRACT failures (`with_item` undefined on the menu slot, missing roles/wiring), NOT a harness-load error. If the harness can't load (two `load_component` calls in one file is unusual — confirm both load), report BLOCKED.

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add test/render/menubar_render_test.rb
git commit -m "test(menubar): 0a render scaffolding for hardened menubar (RED)"
```

---

## Task 3: Rewrite both components (GREEN)

**Files:**
- Rewrite: `lib/generators/modelrails_ui/add/templates/menubar/menubar_component.rb.tt`
- Rewrite: `lib/generators/modelrails_ui/add/templates/menubar/menubar_menu_component.rb.tt`
- Modify: `test/test_generator_components.rb`

- [ ] **Step 1: Replace `menubar_component.rb.tt`**

```ruby
# frozen_string_literal: true

module UI
  # # Menubar
  #
  # A horizontal application menubar (WAI-ARIA APG menubar) — a `role="menubar"` of top-level
  # items, each opening a submenu. The bar is one tab stop (roving tabindex); ←/→ move between
  # items, ↓/Enter open a submenu. Each submenu reuses the shared `menu` Stimulus controller;
  # a thin `menubar` controller coordinates the bar and drives submenus via Stimulus outlets.
  #
  # ## Use when
  # - An app-level command bar (File / Edit / View …) where one row exposes several menus.
  #
  # ## Don't use when
  # - A single trigger opens one menu — use `dropdown_menu`.
  #
  # ## Accessibility contract
  # - **Guarantees:** `role="menubar"` (named by `label:`); bar items `role="menuitem"` +
  #   `aria-haspopup="menu"` + synced `aria-expanded` + `aria-controls`, roving tabindex (one
  #   tab stop); full keyboard (←/→ wrap, Home/End, type-ahead, ↓/Enter opens submenu,
  #   ↑ opens to last, Escape closes to the bar item, ←/→ from a submenu follows to the
  #   adjacent menu). Submenus are `role="menu"` with roving menuitems.
  # - **You supply:** one or more `with_menu(label:)` slots, each with `with_item` slots.
  class MenubarComponent < ApplicationComponent
    renders_many :menus, "UI::MenubarMenuComponent"

    BAR = "flex items-center gap-1 rounded-md border border-border bg-surface-raised p-1 shadow-xs"

    # label: the menubar's accessible name (aria-label), e.g. "Main".
    def initialize(label: "Menu", **html_attrs)
      @label       = label
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div, safe_join(menus),
        role: "menubar",
        "aria-label": @label,
        class: cn(BAR, @extra_class),
        data: {
          controller: "menubar",
          menubar_menu_outlet: "[data-menubar-item]",
          action: "keydown->menubar#navigate focusin->menubar#syncRoving"
        },
        **@html_attrs)
    end
  end
end
```

- [ ] **Step 2: Replace `menubar_menu_component.rb.tt`**

```ruby
# frozen_string_literal: true

module UI
  # # Menubar menu
  #
  # One top-level menu of a `menubar`: a bar-item button (`role="menuitem"`,
  # `aria-haspopup="menu"`) plus its submenu (`role="menu"`). The submenu IS a `menu`
  # controller (reused via EXTRA_STIMULUS) — same item model + behavior as `dropdown_menu`;
  # positioning is CSS anchor positioning (the panel tethers to the bar item). Always used
  # inside `UI::MenubarComponent` (`with_menu`), never standalone.
  class MenubarMenuComponent < ApplicationComponent
    # Submenu items — identical model to dropdown_menu (menuitem button/anchor, disabled,
    # separator, href; caller data:/class: merge without clobbering wiring; el splats last).
    renders_many :items, ->(separator: false, disabled: false, href: nil, **attrs, &block) do
      next content_tag(:div, "", role: "separator", class: SEPARATOR) if separator

      tag_name = href ? :a : :button
      caller_data = attrs.delete(:data) || {}
      el = {
        role: "menuitem",
        tabindex: "-1",
        class: cn(ITEM, attrs.delete(:class)),
        data: { menu_target: "item", action: "click->menu#activate" }.merge(caller_data)
      }
      el[:href] = href if href
      el[:type] = "button" unless href
      el[:"aria-disabled"] = "true" if disabled
      # `el` splats LAST so the ARIA/Stimulus wiring (role/tabindex/class/data) always wins
      # over caller attrs — callers may add attrs but cannot break the menu contract.
      content_tag(tag_name, capture(&block), **attrs, **el)
    end

    # Bar-item button (also the submenu's `menu` trigger). `aria-expanded:` highlights it
    # while its submenu is open. Focus-visible ring; disabled-safe.
    TRIGGER = "flex cursor-pointer select-none items-center rounded-sm px-3 py-1.5 text-sm " \
              "font-medium outline-none " \
              "hover:bg-surface-sunken hover:text-text-heading " \
              "focus-visible:bg-surface-sunken focus-visible:text-text-heading " \
              "aria-expanded:bg-surface-sunken " \
              "aria-disabled:opacity-60 aria-disabled:cursor-not-allowed aria-disabled:pointer-events-none"

    # Submenu panel — CSS anchor positioning (bottom_start, below the bar item, start-aligned,
    # flip-to-stay-on-screen), the same shape as dropdown_menu's bottom_start placement.
    # rubocop:disable Layout/LineLength
    PANEL = "z-50 min-w-[12rem] overflow-hidden rounded-md border border-border bg-surface-overlay p-1 text-text-body shadow-md outline-none mt-1 supports-[position-area:bottom]:fixed supports-[position-area:bottom]:[position-area:bottom_span-right] supports-[position-area:bottom]:[position-try-fallbacks:flip-block] not-supports-[position-area:bottom]:absolute not-supports-[position-area:bottom]:top-full not-supports-[position-area:bottom]:left-0"
    # rubocop:enable Layout/LineLength

    # Submenu item — identical to dropdown_menu's ITEM (focus-visible highlight + aria-disabled
    # treatment + SVG normalisation).
    ITEM = "relative flex w-full cursor-pointer select-none items-center gap-2 rounded-sm " \
           "px-2 py-1.5 text-sm outline-none " \
           "hover:bg-surface-sunken hover:text-text-heading " \
           "focus-visible:bg-surface-sunken focus-visible:text-text-heading " \
           "aria-disabled:pointer-events-none aria-disabled:opacity-60 aria-disabled:cursor-not-allowed " \
           "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 " \
           "[&_svg:not([class*='text-'])]:text-text-muted"
    SEPARATOR = "-mx-1 my-1 h-px bg-border"

    # label: the bar item's visible text + accessible name.
    # id:    submenu id (auto-generated; → aria-controls + anchor name).
    def initialize(label:, id: nil, **html_attrs)
      @label       = label
      @id          = id || "menubar-menu-#{SecureRandom.hex(4)}"
      @trigger_id  = "#{@id}-trigger"
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div, safe_join([trigger_button, submenu_panel]),
        class: "relative",
        data: { controller: "menu", menubar_item: "" },
        **@html_attrs)
    end

    private

    def trigger_button
      content_tag(:button, @label,
        type: "button",
        id: @trigger_id,
        role: "menuitem",
        tabindex: "-1",
        "aria-haspopup": "menu",
        "aria-expanded": "false",
        "aria-controls": @id,
        style: "anchor-name: --#{@id}",
        data: {
          menu_target: "trigger",
          menubar_target: "item",
          action: "click->menu#toggle keydown->menu#triggerKeydown"
        },
        class: TRIGGER)
    end

    def submenu_panel
      content_tag(:div, safe_join(items),
        id: @id,
        role: "menu",
        "aria-labelledby": @trigger_id,
        tabindex: "-1",
        hidden: true,
        style: "position-anchor: --#{@id}",
        data: { menu_target: "menu", action: "keydown->menu#navigate" },
        class: cn(PANEL, @extra_class))
    end
  end
end
```

- [ ] **Step 3: Update the structural generator test for menubar_menu**

`test/test_generator_components.rb` may assert menubar_menu has its own colocated controller (it no longer does — it reuses `menu` via EXTRA_STIMULUS). Inspect:

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
grep -n "menubar" test/test_generator_components.rb
```
- `test_menubar_copies_two_rb_tt_files` (asserts menubar has 2 `.rb.tt`) — STILL TRUE (two components). Leave it.
- `menubar` keeps its OWN controller (`menubar_controller.js`) — any assertion of that stays TRUE. Leave it.
- IF there is a `test_menubar_menu_has_js_controller` (or similar) asserting a colocated `menubar_menu_controller.js`, REPLACE it with an EXTRA_STIMULUS assertion (mirror `test_sheet_has_js_controller`):
  ```ruby
  def test_menubar_menu_reuses_menu_controller
    cfg = ModelrailsUi::Generators::Components::EXTRA_STIMULUS["menubar_menu"]
    assert_equal({source: "dropdown_menu/menu_controller.js", name: "menu"}, cfg)
    assert_path_exists File.join(TEMPLATE_ROOT, "dropdown_menu", "menu_controller.js")
  end
  ```
  If no such test exists, ADD the above test method (so the reuse is pinned). Do NOT create a `menubar_menu_controller.js` stub.

- [ ] **Step 4: Run the menubar render test — GREEN**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/menubar_render_test.rb
```
Expected: PASS — all assertions green.

- [ ] **Step 5: Full gem suite + rubocop**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rubocop lib/generators/modelrails_ui/add/templates/menubar/menubar_component.rb.tt lib/generators/modelrails_ui/add/templates/menubar/menubar_menu_component.rb.tt test/render/menubar_render_test.rb test/test_generator_components.rb
```
Expected: full suite 0 failures (the structural `test_components.rb` checks `MenubarComponent::BAR`, `MenubarMenuComponent::TRIGGER`/`PANEL`, and `MenubarMenuComponent.new(label:)` — all preserved); rubocop clean (autocorrect incidental with `-A`, then re-run the render test). If `test_components.rb` fails on a constant it expects (e.g. it expects `MenubarComponent::ITEM`), read the failing assertion and either restore that constant or update the test the same way (assert the new contract) — do NOT guess.

- [ ] **Step 6: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/menubar/menubar_component.rb.tt lib/generators/modelrails_ui/add/templates/menubar/menubar_menu_component.rb.tt test/test_generator_components.rb
git commit -m "feat(menubar): harden menubar + menubar_menu to APG menubar (GREEN)

role=menubar bar (roving + outlet wiring); each menubar_menu is a role=menuitem bar
button (aria-haspopup/expanded/controls, menu trigger) + role=menu anchor-positioned
submenu reusing the menu controller (dropdown_menu item model). menubar_menu reuses
menu via EXTRA_STIMULUS (structural test updated)."
```

---

## Task 4: Gem doc + ledger

**Files:** Create/Rewrite `docs/components/menubar.md`; Modify `COMPONENT_STATUS.md`

- [ ] **Step 1: Write the doc**

Write `docs/components/menubar.md` (file starts at `# Menubar`, normal triple-backtick fences):

```markdown
# Menubar

A horizontal application menubar (WAI-ARIA APG menubar) — a `role="menubar"` of top-level
items, each opening a submenu. Each submenu reuses the shared `menu` Stimulus controller; a
thin `menubar` controller coordinates the bar (roving tabindex + ←/→) and drives the submenus
via Stimulus outlets.

Requires `menubar_controller.js` and `menu_controller.js` (both copied by the generator).

## Installation

```bash
rails g modelrails_ui:add menubar
```

Creates `app/components/ui/menubar_component.rb`, `app/components/ui/menubar_menu_component.rb`,
`app/javascript/controllers/menubar_controller.js`, and `app/javascript/controllers/menu_controller.js`.

## Usage

```erb
<%= render(UI::MenubarComponent.new(label: "Main")) do |bar| %>
  <% bar.with_menu(label: "File") do |m| %>
    <% m.with_item { "New" } %>
    <% m.with_item { "Open" } %>
    <% m.with_item(separator: true) %>
    <% m.with_item(href: "/recent") { "Open recent" } %>
  <% end %>
  <% bar.with_menu(label: "Edit") do |m| %>
    <% m.with_item { "Undo" } %>
    <% m.with_item(disabled: true) { "Redo" } %>
  <% end %>
<% end %>
```

`label:` on the menubar is its accessible name. Each `with_menu(label:)` is a top-level item;
its `with_item` slots become the submenu's `role="menuitem"`s (same options as `dropdown_menu`:
`disabled:`, `separator:`, `href:`). Single-level submenus only.

## Keyboard

| Key | Action |
|-----|--------|
| `Tab` into the bar | Lands on one bar item (the menubar is one tab stop) |
| `←` / `→` | Move between bar items (wraps); if a submenu is open, closes it and opens the adjacent |
| `Home` / `End` | First / last bar item |
| type a letter (bar) | Jump to the next bar item starting with it |
| `↓` / `Enter` / `Space` (bar item) | Open its submenu, focus first item |
| `↑` (bar item) | Open its submenu, focus last item |
| `↑` / `↓` (submenu) | Move (wraps, skips disabled); Home/End; type-ahead |
| `Enter` / `Space` / click | Activate submenu item, close |
| `Escape` | Close submenu, focus the bar item |

## Accessibility

WCAG 2.2 AAA. `role="menubar"` named by `label:`; bar items `role="menuitem"` +
`aria-haspopup="menu"` + synced `aria-expanded`; roving tabindex keeps one bar item tabbable.
Proven by `spec/system/ui/menubar_component_spec.rb` in the host app.
```

- [ ] **Step 2: Ledger rows → hardened**

In `COMPONENT_STATUS.md`, add TWO rows immediately after the `context_menu` row (before `All other gem components: …`):

```markdown
| menubar | hardened | ✅ | ⏳ | Menu-band (Wave 6) final: APG menubar (role=menubar, roving ←/→/Home/End/type-ahead) via a thin `menubar` coordinator + Stimulus outlets; single-level submenus. 0a render test; app 0b CI-pending |
| menubar_menu | hardened | ✅ | ⏳ | menubar sub-component: bar item (role=menuitem, aria-haspopup) + role=menu submenu reusing the shared `menu` controller via EXTRA_STIMULUS; CSS anchor positioning; dropdown_menu item model. Covered by the menubar 0a/0b |
```

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add docs/components/menubar.md COMPONENT_STATUS.md
git commit -m "docs(menubar): usage doc + ledger rows (hardened)"
```

> **Gem PR gate:** do NOT push/PR yet — the app 0b proves it first (Tasks 5–8); the human pushes after the full app suite is green. Gem branch: `harden/menubar`.

---

## Task 5: App — vendor

**Files:** `Gemfile` (temp-pin); generator-created `app/components/ui/menubar_component.rb`, `menubar_menu_component.rb`, `app/javascript/controllers/menubar_controller.js` (+ re-copied `menu_controller.js`, unchanged).

- [ ] **Step 1: Branch + temp-pin + install**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git checkout main && git pull --ff-only
git checkout -b feat/ui-menubar
```
In `Gemfile`, replace the `modelrails_ui` line:
```ruby
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "modelrails/harden"
```
with:
```ruby
  # TEMP-PIN: re-pin to "modelrails/harden" after the menubar gem PR merges.
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "harden/menubar"
```
Then:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle config set --local local.modelrails_ui /Users/dschmura/Documents/code/modelrails_ui
mise exec -- bundle install
mise exec -- bundle info modelrails_ui   # expect Path: /Users/dschmura/Documents/code/modelrails_ui
```

- [ ] **Step 2: Regenerate**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails g modelrails_ui:add menubar --force
```
Expected: writes both component .rb files + `menubar_controller.js`, and (re)writes `menu_controller.js` (unchanged from what's already vendored).

- [ ] **Step 3: Verify the vendored files**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
diff app/javascript/controllers/menubar_controller.js /Users/dschmura/Documents/code/modelrails_ui/lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js && echo "MENUBAR CONTROLLER MATCHES"
diff app/javascript/controllers/menu_controller.js /Users/dschmura/Documents/code/modelrails_ui/lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js && echo "MENU CONTROLLER UNCHANGED"
grep -q 'role: "menubar"' app/components/ui/menubar_component.rb && echo "MENUBAR VENDORED"
grep -q 'menu_target: "trigger"' app/components/ui/menubar_menu_component.rb && echo "MENUBAR_MENU VENDORED"
ls app/javascript/controllers/ | grep -i menubar_menu && echo "UNEXPECTED menubar_menu controller!" || echo "OK — no colocated menubar_menu controller"
```
Expected: `MENUBAR CONTROLLER MATCHES`, `MENU CONTROLLER UNCHANGED`, `MENUBAR VENDORED`, `MENUBAR_MENU VENDORED`, `OK — no colocated menubar_menu controller`. (Component .rb may be rubocop-reformatted — semantic parity.)

- [ ] **Step 4: Re-prove dropdown_menu + context_menu 0b (the shared `menu` controller is unchanged — sanity)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/dropdown_menu_component_spec.rb spec/system/ui/context_menu_component_spec.rb
```
Expected: 9 + 6 = 15 examples, 0 failures (the `menu` controller is byte-unchanged; this confirms the menubar vendor didn't disturb the shared file). Judge by the example line.

- [ ] **Step 5: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add app/components/ui/menubar_component.rb app/components/ui/menubar_menu_component.rb app/javascript/controllers/menubar_controller.js app/javascript/controllers/menu_controller.js Gemfile Gemfile.lock
git commit -m "feat(ui): vendor hardened menubar + menubar_menu (reuses menu controller)"
```

---

## Task 6: App — preview

**Files:** Create `spec/components/previews/ui/menubar_component_preview.rb` + `…/menubar_component_preview/basic.html.erb`.

> No `@param` playground (no enum params). A single `basic` scenario is the preview.

- [ ] **Step 1: Preview class**

```ruby
# frozen_string_literal: true

module UI
  # # Menubar
  #
  # An app menubar (WAI-ARIA APG). Tab to it (one stop), ←/→ between items, ↓/Enter to open a
  # submenu, ↑/↓ within, Escape to close. Submenus reuse the shared `menu` controller.
  class MenubarComponentPreview < ViewComponent::Preview
    include UIHelper

    # File / Edit / View menubar with submenus.
    def basic
    end
  end
end
```

- [ ] **Step 2: basic.html.erb**

```erb
<div class="min-h-96 p-12">
  <%= render(UI::MenubarComponent.new(label: "Main")) do |bar| %>
    <% bar.with_menu(label: "File") do |m| %>
      <% m.with_item { "New file" } %>
      <% m.with_item { "Open…" } %>
      <% m.with_item(disabled: true) { "Open recent" } %>
      <% m.with_item(separator: true) %>
      <% m.with_item(href: "#") { "Settings" } %>
    <% end %>
    <% bar.with_menu(label: "Edit") do |m| %>
      <% m.with_item { "Undo" } %>
      <% m.with_item { "Redo" } %>
      <% m.with_item(separator: true) %>
      <% m.with_item { "Cut" } %>
      <% m.with_item { "Copy" } %>
      <% m.with_item { "Paste" } %>
    <% end %>
    <% bar.with_menu(label: "View") do |m| %>
      <% m.with_item { "Zoom in" } %>
      <% m.with_item { "Zoom out" } %>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Verify ERB syntax**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- ruby -e 'require "erb"; ERB.new(File.read("spec/components/previews/ui/menubar_component_preview/basic.html.erb")).src; puts "basic: syntax OK"'
```
Expected: `basic: syntax OK`. (Authoritative render check is the Task-7 0b.)

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/components/previews/ui/menubar_component_preview.rb spec/components/previews/ui/menubar_component_preview/
git commit -m "test(ui): menubar preview (File/Edit/View)"
```

---

## Task 7: App — 0b browser-axe + full menubar keyboard

**Files:** Create `spec/system/ui/menubar_component_spec.rb`.

The real gate. Drives the two-level keyboard + the outlet coordination.

- [ ] **Step 1: Write the system spec**

```ruby
# frozen_string_literal: true

require "rails_helper"

# Preview-host accessibility + behavior proof for the menubar component.
#
# Two-level APG menubar: a horizontal bar (←/→ roving) + per-item submenus (the reused `menu`
# controller). The menubar coordinator drives submenus via Stimulus outlets; key-routing is
# implicit (defaultPrevented skip; ←/→ bubble). NOTE: per-spec axe runs AA locally; the AAA
# 7:1 audit is the CI-only wcag2aaa hook.
RSpec.describe "Menubar component accessibility", type: :system do
  before { visit "/rails/view_components/ui/menubar_component/basic" }

  def bar_item(text)
    find("button[role='menuitem']", text: text)
  end

  def focused_text
    page.evaluate_script("document.activeElement.textContent.trim()")
  end

  it "renders a menubar and opens a submenu that passes AAA in both themes" do
    expect(page).to have_css("[role='menubar'][aria-label='Main']")
    expect(page).to have_css("button[role='menuitem'][aria-haspopup='menu']", minimum: 3)

    bar_item("File").click
    expect(page).to have_css("[role='menu']:not([hidden])")
    expect(bar_item("File")["aria-expanded"]).to eq("true")

    scope = [ "[role='menu']:not([hidden])" ]
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true),
      axe_violations_in_both_themes(include: scope).join("\n")
    )
  end

  it "ArrowDown on a bar item opens its submenu and focuses the first item" do
    bar_item("File").send_keys(:down)
    expect(page).to have_css("[role='menu']:not([hidden])")
    expect(focused_text).to eq("New file")
  end

  it "ArrowRight/Left move between bar items (no submenu open)" do
    bar_item("File").send_keys(:right)
    expect(focused_text).to eq("Edit")
    page.send_keys(:right)
    expect(focused_text).to eq("View")
    page.send_keys(:right) # wraps
    expect(focused_text).to eq("File")
    page.send_keys(:left) # wraps back
    expect(focused_text).to eq("View")
  end

  it "ArrowRight from inside an open submenu follows to the adjacent menu" do
    bar_item("File").send_keys(:down) # File submenu open, focus "New file"
    expect(focused_text).to eq("New file")

    page.send_keys(:right) # close File, open Edit, focus its first item
    expect(focused_text).to eq("Undo")
    expect(page).to have_css("[role='menu']:not([hidden])", count: 1)
    expect(bar_item("File")["aria-expanded"]).to eq("false")
    expect(bar_item("Edit")["aria-expanded"]).to eq("true")
  end

  it "ArrowDown wraps and SKIPS the disabled submenu item" do
    bar_item("File").send_keys(:down) # New file
    page.send_keys(:down) # Open…
    expect(focused_text).to eq("Open…")
    page.send_keys(:down) # skips disabled "Open recent" → Settings
    expect(focused_text).to eq("Settings")
  end

  it "Escape closes the submenu and returns focus to the bar item" do
    bar_item("File").send_keys(:down)
    page.send_keys(:escape)
    expect(page).to have_css("[role='menu'][hidden]", visible: :all)
    expect(focused_text).to eq("File")
    expect(bar_item("File")["aria-expanded"]).to eq("false")
  end

  it "type-ahead at the bar level jumps to a matching item" do
    bar_item("File").send_keys("e") # → Edit
    expect(focused_text).to eq("Edit")
  end
end
```

- [ ] **Step 2: Run (must PASS locally, AA)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/menubar_component_spec.rb
```
Expected: 7 examples, 0 failures (judge by the example line; SimpleCov may exit 2).

### IF A KEYBOARD/COORDINATION EXAMPLE FAILS (do NOT weaken the spec)
The bug is in the GEM `menubar_controller.js` (the coordinator/outlet logic) — the `menu` controller is frozen. Fix the GEM (`/Users/dschmura/Documents/code/modelrails_ui/lib/generators/modelrails_ui/add/templates/menubar/menubar_controller.js`), commit on the gem branch (PATH prefix), re-vendor (`mise exec -- bin/rails g modelrails_ui:add menubar --force`), confirm the `diff` matches, and re-run BOTH this spec AND dropdown_menu+context_menu 0b (Task 5 Step 4 — the `menu` controller must stay green). Do NOT edit the app's vendored copy or the `menu` controller. Likely suspects: outlet timing (`hasMenuOutlet`), `currentIndex` when focus is in a submenu, the `defaultPrevented` guard, the type-ahead-while-open suppression, or the `←/→`-follow open/close order. If you cannot diagnose after a genuine attempt, report BLOCKED with the failure + what you tried.

### IF ONLY THE AXE (AA) ASSERTION FAILS
Report the `axe_violations_in_both_themes` output; do NOT add a color-contrast exclude. If it's an unresolvable token-contrast question, report DONE_WITH_CONCERNS (the human adjudicates via CI).

- [ ] **Step 3: Commit (once green)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/system/ui/menubar_component_spec.rb
git commit -m "test(ui): 0b menubar (roving/←→-follow/submenu open/escape/type-ahead/AAA)"
```
(If you fixed + re-vendored the controller: gem fix committed on the gem branch; in the app, separately commit the re-vendored `menubar_controller.js` + lock as `chore(ui): re-vendor menubar controller fix from gem`.)

---

## Task 8: App — full suite + handoff gate

- [ ] **Step 1: Full app suite**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec
```
Expected: 0 failures. Re-proves menubar (7/7), dropdown_menu (9/9), context_menu (6/6), + everything else. Investigate any pending; classify any failure ours-vs-flake (re-run a flaky system-spec file up to 2x). Do not paper over a real failure.

- [ ] **Step 2: Lint**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rubocop app/components/ui/menubar_component.rb app/components/ui/menubar_menu_component.rb spec/components/previews/ui/menubar_component_preview.rb spec/system/ui/menubar_component_spec.rb
npx --yes @herb-tools/linter spec/components/previews/ui/menubar_component_preview/basic.html.erb 2>&1 | tail -5 || echo "(herb-lint not local; Lefthook/CI runs it)"
```
Expected: no offenses.

- [ ] **Step 3: Clean tree + branch commits (NO push)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git status --porcelain
git log --oneline main..HEAD
cd /Users/dschmura/Documents/code/modelrails_ui && git log --oneline -8
```

- [ ] **Step 4: STOP — human handoff**

Report: menubar complete. **Gem** (`harden/menubar`): coordinator controller + EXTRA_STIMULUS + both hardened components + 0a render test + structural-test update + doc + ledger (hardened). **App** (`feat/ui-menubar`): vendored + preview + 0b (full menubar keyboard, AAA), full suite green (dropdown_menu + context_menu re-proven, `menu` controller unchanged). Browser review at `/rails/view_components/ui/menubar_component/basic` (Tab in; ←/→; ↓ to open; ←/→ across open submenus; Escape) and `/lookbook`. On OK: push gem branch + PR into `modelrails/harden` → merge carefully (poll head==SHA + checks-pass before merging) → re-pin app Gemfile to `modelrails/harden` + drop the local override → push app branch + PR → after app AAA CI green + merge, flip the gem ledger menubar + menubar_menu → proven.

---

## Self-Review

**1. Spec coverage** (design → tasks):
- §1 architecture (reuse `menu` per submenu via EXTRA_STIMULUS + thin `menubar` coordinator + outlets; `menu` frozen) → Task 1 (controller + registry) + Task 3 (components wire `data-controller=menu` per submenu, `data-menubar-menu-outlet`). ✅
- §2 key-routing (defaultPrevented skip; ←/→ bubble; bar type-ahead suppressed while open; invariant comment) → Task 1 controller `navigate` + the INVARIANT comment. ✅
- §3 a11y contract (role=menubar/menuitem/menu, roving tabindex, aria-haspopup/expanded/controls, focus-visible, disabled-skip) → Tasks 1+3; render-asserted Task 2; behavior Task 7. ✅
- §4 anchor positioning (bottom_start) → Task 3 `PANEL`; render-asserted Task 2. ✅
- §5 files / §6 DoD+0a+0b / §7 risks (outlet timing `hasMenuOutlet`, type-ahead guard, ←/→-follow as highest-risk) → all tasks; the 0b (Task 7) drives the ←/→-follow + Escape + type-ahead. ✅
- Scope: single-level submenus (no `aria-haspopup` on submenu items, no nesting). ✅
- **Structural tests** (`test_components.rb` BAR/TRIGGER/PANEL + label; `test_generator_components.rb` menubar_menu→menu) → Task 3 preserves the constants + Step 3 updates the generator test (the context_menu re-export-stub lesson applied). ✅

**2. Placeholder scan:** No TBD/TODO. `{focus}`/`{submenu_id}` are notation. All code complete. Task 3 Step 3 + Step 5 have a "read the failing assertion" contingency for the pre-existing structural tests — this is a known integration point, not a placeholder (the exact menubar assertions can't be fully known without running, per the context_menu precedent), with the concrete fix pattern given.

**3. Type/name consistency:** controller targets (`item`) + outlets (`menu`) ↔ component wiring (`data-menubar-target=item`, `data-controller=menu` + `data-menubar-item` matched by `data-menubar-menu-outlet="[data-menubar-item]"`); actions (`menubar#navigate`/`#syncRoving`, `menu#toggle`/`#triggerKeydown`/`#navigate`/`#activate`) match across controller, components, render test, 0b; `open({focus:"first"})`/`close({restoreFocus:false})`/`openValue` are the `menu` controller's real public surface (verified — `open({ focus = "first" } = {})`, `close({ restoreFocus = true } = {})`, Stimulus `openValue`). ✅

**Flagged for browser/CI review:** AAA contrast of the bar-item + submenu focus highlights + 44px targets (the bar `TRIGGER` is `px-3 py-1.5` ≈ 32px tall — may need `min-h-11` if the AAA target-size check flags it; adjudicated by the app CI `test` job). The `aria-expanded:bg-surface-sunken` bar-item-open highlight contrast is also a CI-axe call.
