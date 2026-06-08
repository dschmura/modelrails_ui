# Context Menu (Menu-Band, Component 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `context_menu` to the WAI-ARIA APG menu pattern — a right-click/Shift+F10-opened menu on a focusable host region — by **reusing the shared `menu` Stimulus controller** (extended additively with `openAt`/`openContextKey`) and mirroring `dropdown_menu`'s item model, minus the trigger button and `side`/`align`.

**Architecture:** Two repos, two PRs (the proven groove). **Gem** (`modelrails_ui`, branch `harden/context-menu` off `modelrails/harden`): add `openAt`/`openContextKey`/`positionAt` to the shared `dropdown_menu/menu_controller.js` (additive — dropdown_menu never calls them), register `context_menu → menu` in `EXTRA_STIMULUS`, delete the old `context_menu_controller.js`, rewrite the component, add a 0a render test, update doc + ledger. **App** (`modelrails_base`, branch `feat/ui-context-menu` off `main`): re-vendor (which re-copies the shared `menu_controller.js` that dropdown_menu also uses), add a preview, and a 0b system spec that drives `contextmenu` + Shift+F10 + keyboard + AAA — **and re-proves the dropdown_menu 0b** (shared controller changed).

**Tech Stack:** Ruby 4.0.5 (gem) / 4.0.4 (app), Rails 8.1, ViewComponent 4, Stimulus (importmap), TailwindCSS 4 (OKLCH semantic tokens), RSpec + Capybara + Playwright + axe-core (WCAG 2.2 AAA, CI-only 7:1 hook).

**Design contract:** `docs/design/2026-06-07-menu-widgets-band-design.md` §1 (context_menu: opens on `contextmenu` **and** Shift+F10 / ContextMenu key while the host has focus, positioned near the focused element; identical menu semantics), §3 (JS pointer positioning; `openAt` sets fixed `top`/`left`; Shift+F10 falls back to the focused host's rect), §-DoD (**context_menu has NO `side` prop** — pointer-positioned; 0b drives Shift+F10 parity). This plan implements **`context_menu` only**; `menubar` is a later, separate wave.

**Sibling references (read to match house style):** `dropdown_menu` (the just-shipped exemplar) — `lib/generators/modelrails_ui/add/templates/dropdown_menu/{dropdown_menu_component.rb.tt,menu_controller.js}`, `test/render/dropdown_menu_render_test.rb`, and in the app `spec/system/ui/dropdown_menu_component_spec.rb` + `spec/components/previews/ui/dropdown_menu_component_preview*`.

**Toolchain (exact):**
- **Gem** (`/Users/dschmura/Documents/code/modelrails_ui`): `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …`. Render-test load path is **`-Itest/render`**.
- **App** (`/Users/dschmura/Documents/code/modelrails_base`): `mise exec -- bundle exec …`.

---

## File Structure

**Gem (`modelrails_ui`):**

| File | Responsibility | Action |
|---|---|---|
| `lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js` | Shared `menu` controller — gains `openAt`/`openContextKey`/`positionAt` (additive) | Modify |
| `lib/generators/modelrails_ui/components.rb` | `EXTRA_STIMULUS` registry — add `context_menu → menu` | Modify |
| `lib/generators/modelrails_ui/add/templates/context_menu/context_menu_controller.js` | Old thin controller — superseded by shared `menu` | Delete |
| `lib/generators/modelrails_ui/add/templates/context_menu/context_menu_component.rb.tt` | Hardened component: focusable host trigger + `role=menu` panel + `with_item` slots | Rewrite |
| `test/render/context_menu_render_test.rb` | 0a structure-only render test | Create |
| `docs/components/context_menu.md` | Component usage doc | Create/Rewrite |
| `COMPONENT_STATUS.md` | Ledger row → `hardened` then `proven` | Modify |

**App (`modelrails_base`):**

| File | Responsibility | Action |
|---|---|---|
| `Gemfile` | (no change — already pinned to `modelrails/harden`; the gem work must be merged there before app adoption, OR temp-pin to `harden/context-menu`) | See Task 5 |
| `app/components/ui/context_menu_component.rb` | Vendored component | Create (generator) |
| `app/javascript/controllers/menu_controller.js` | Re-vendored shared controller (now with `openAt`) | Update (generator) |
| `app/javascript/controllers/context_menu_controller.js` | Stale (if present) — superseded | Delete if present |
| `spec/components/previews/ui/context_menu_component_preview.rb` + templates | Preview | Create |
| `spec/system/ui/context_menu_component_spec.rb` | 0b browser-axe + keyboard/right-click/Shift+F10 proof | Create |

---

## Task 1: Extend the shared `menu` controller + register + delete old controller

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js`
- Modify: `lib/generators/modelrails_ui/components.rb`
- Delete: `lib/generators/modelrails_ui/add/templates/context_menu/context_menu_controller.js`

> The additions are **purely additive** — `openAt`/`openContextKey`/`positionAt` are new methods context_menu wires; dropdown_menu never references them, so its behavior is unchanged (re-proven by its 0b in Task 7). No gem-side JS test exists; behavior is proven in the app 0b.

- [ ] **Step 1: Add the three methods to the shared controller**

In `lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js`, the class currently ends with the `activate(event) { … }` method then `}`. Insert these three methods immediately **after** `activate` (before the final class-closing `}`):

```js

  // --- context_menu: pointer / keyboard positioning -----------------------
  // (used by context_menu via EXTRA_STIMULUS; dropdown_menu never wires these)

  // Right-click: open the menu at the pointer. Re-opens at the new point if
  // already open (a second right-click moves the menu).
  openAt(event) {
    event.preventDefault()
    this.positionAt(event.clientX, event.clientY)
    this.openValue ? this.focusFirst() : this.open()
  }

  // Keyboard parity (Shift+F10 or the ContextMenu key) while the host has focus —
  // right-click is pointer-only, so this is required (WCAG 2.1.1). No pointer
  // coordinates, so position near the host (the trigger target's rect).
  openContextKey(event) {
    if (!((event.shiftKey && event.key === "F10") || event.key === "ContextMenu")) return
    event.preventDefault()
    const rect = this.triggerTarget.getBoundingClientRect()
    this.positionAt(rect.left, rect.bottom)
    this.openValue ? this.focusFirst() : this.open()
  }

  positionAt(x, y) {
    this.menuTarget.style.left = `${x}px`
    this.menuTarget.style.top = `${y}px`
  }
```

- [ ] **Step 2: Register context_menu → menu in EXTRA_STIMULUS**

In `lib/generators/modelrails_ui/components.rb`, the `EXTRA_STIMULUS` hash currently ends:

```ruby
        "tooltip" => {source: "popover/floating_controller.js", name: "floating"},
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"}
      }.freeze
```

Add a `context_menu` entry (note the trailing comma added to the `hover_card` line):

```ruby
        "tooltip" => {source: "popover/floating_controller.js", name: "floating"},
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"},
        "context_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"}
      }.freeze
```

- [ ] **Step 3: Delete the old context_menu controller**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git rm lib/generators/modelrails_ui/add/templates/context_menu/context_menu_controller.js
```

- [ ] **Step 4: Syntax-check + confirm dropdown_menu render test still green**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
node --check lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js && echo "JS OK"
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/dropdown_menu_render_test.rb
```
Expected: `JS OK`; dropdown_menu render test still 14/14 (it asserts the controller's *wiring*, which is unchanged — the additions don't touch existing methods).

- [ ] **Step 5: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js lib/generators/modelrails_ui/components.rb
git commit -m "feat(menu): add openAt/openContextKey to shared menu controller for context_menu

Additive — context_menu (registered in EXTRA_STIMULUS → menu) opens the menu at the
pointer (contextmenu) or near the host (Shift+F10 / ContextMenu key, WCAG 2.1.1);
dropdown_menu never wires these. Drops the old context_menu_controller.js."
```

---

## Task 2: 0a render test (RED)

**Files:**
- Create: `test/render/context_menu_render_test.rb`

- [ ] **Step 1: Write the failing render test**

Create `test/render/context_menu_render_test.rb`:

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "context_menu", "context_menu_component.rb.tt"

# STRUCTURE-only render specs. The behavior (right-click + Shift+F10 open, roving
# tabindex, type-ahead, Escape/Tab/outside-click dismissal) is proven by the app 0b
# browser spec (spec/system/ui/context_menu_component_spec.rb) — the render harness
# cannot exercise JS, so here we assert the static scaffolding the `menu` controller drives.
class ContextMenuRenderTest < ViewComponent::TestCase
  def render_menu(**opts)
    render_inline(UI::ContextMenuComponent.new(**opts)) do |c|
      c.with_trigger { "Right-click me" }
      c.with_item { "Edit" }
      c.with_item(disabled: true) { "Archive" }
      c.with_item(separator: true)
      c.with_item(href: "/x") { "Open in new tab" }
    end
  end

  def test_wrapper_wires_the_menu_controller_and_outside_click
    render_menu

    assert_selector "div[data-controller='menu']" \
                    "[data-action~='click@document->menu#closeOnClickOutside']", visible: :all
  end

  def test_trigger_region_is_a_focusable_menu_host
    render_menu(id: "c1")

    assert_selector "div[id='c1-trigger'][tabindex='0'][aria-haspopup='menu']" \
                    "[aria-expanded='false'][aria-controls='c1'][data-menu-target='trigger']" \
                    "[data-action~='contextmenu->menu#openAt'][data-action~='keydown->menu#openContextKey']",
                    text: "Right-click me", visible: :all
  end

  def test_menu_panel_is_a_fixed_labelled_menu_hidden_until_open
    render_menu(id: "c2")

    assert_selector "div#c2[role='menu'][aria-labelledby='c2-trigger'][tabindex='-1'][hidden]" \
                    "[data-menu-target='menu'][data-action~='keydown->menu#navigate']" \
                    ".fixed", visible: :all
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

  def test_explicit_label_sets_aria_label_and_drops_labelledby
    render_inline(UI::ContextMenuComponent.new(label: "Row actions")) do |c|
      c.with_trigger { "Row" }
      c.with_item { "Edit" }
    end

    assert_selector "[role='menu'][aria-label='Row actions']", visible: :all
    assert_no_selector "[role='menu'][aria-labelledby]", visible: :all
  end

  def test_item_merges_caller_data_without_clobbering_wiring
    render_inline(UI::ContextMenuComponent.new) do |c|
      c.with_trigger { "Right-click me" }
      c.with_item(data: { turbo_frame: "modal" }) { "Edit" }
    end

    assert_selector "button[role='menuitem'][data-menu-target='item']" \
                    "[data-action~='click->menu#activate'][data-turbo-frame='modal']",
                    text: "Edit", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) do
      render_inline(UI::ContextMenuComponent.new) { |c| c.with_item { "Edit" } }
    end
    assert_match(/with_trigger/, error.message)
  end
end
```

- [ ] **Step 2: Run the render test — verify it FAILS**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/context_menu_render_test.rb
```
Expected: FAIL — the current component has no `with_item`/`with_trigger` slots, no `data-controller='menu'`, no `role=menu` (it uses `renders_one :menu` + the old `context-menu` controller). The failures must be CONTRACT failures (`with_item`/`with_trigger` undefined), not a harness-load error. If the harness can't load, report BLOCKED.

- [ ] **Step 3: Commit the failing test**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add test/render/context_menu_render_test.rb
git commit -m "test(menu): 0a render scaffolding for hardened context_menu (RED)"
```

---

## Task 3: Rewrite the component (GREEN)

**Files:**
- Rewrite: `lib/generators/modelrails_ui/add/templates/context_menu/context_menu_component.rb.tt`
- Test: `test/render/context_menu_render_test.rb` (from Task 2)

- [ ] **Step 1: Replace the component template**

Overwrite `lib/generators/modelrails_ui/add/templates/context_menu/context_menu_component.rb.tt` with:

```ruby
# frozen_string_literal: true

module UI
  # # Context menu
  #
  # A menu of actions opened by right-clicking — or Shift+F10 / the ContextMenu key while
  # the host has keyboard focus — on a host region, implementing the WAI-ARIA APG menu
  # pattern via the shared `menu` Stimulus controller. Positioning is JS: the panel is
  # `fixed` and the controller's `openAt` sets `top`/`left` from the pointer (or the host's
  # rect for the keyboard path). The keyboard model (roving tabindex, type-ahead,
  # Escape/Tab/outside-click dismissal with focus restore) is identical to `dropdown_menu`.
  #
  # ## Use when
  # - A region (a row, a card, a canvas, a file tile) exposes contextual actions on right-click.
  #
  # ## Don't use when
  # - A visible trigger button should open the menu — use `dropdown_menu`.
  #
  # ## Accessibility contract
  # - **Guarantees:** the host is focusable (`tabindex="0"`) with `aria-haspopup="menu"`,
  #   `aria-expanded` (kept in sync) and `aria-controls`; opens on `contextmenu` AND
  #   Shift+F10 / the ContextMenu key (WCAG 2.1.1 keyboard parity); a `role="menu"` panel
  #   named by the host (or `label:`); `role="menuitem"` items with roving tabindex;
  #   Escape/Tab/outside-click close with focus restored to the host.
  # - **You supply:** a `with_trigger` slot (the right-clickable region) and one or more
  #   `with_item` slots.
  class ContextMenuComponent < ApplicationComponent
    renders_one :trigger

    # Each item is a real menuitem button (or an anchor when `href:` is given). `disabled:`
    # marks it `aria-disabled` (skipped by keyboard nav; activation rejected). `separator:`
    # renders a divider in source order. Caller `data:`/`class:` merge without clobbering
    # the menu wiring (el splats last). Identical to dropdown_menu's item model.
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
      content_tag(tag_name, capture(&block), **attrs, **el)
    end

    # Panel is `fixed` (positioned by the controller's `openAt`, not anchor positioning —
    # a context menu tethers to a point, not an element).
    PANEL_BASE = "fixed z-50 min-w-[8rem] overflow-hidden rounded-md border border-border " \
                 "bg-surface-overlay p-1 text-text-body shadow-md outline-none"

    # Menu item — focus-visible AND hover share the highlight (roving focus must be visible);
    # disabled items inert + de-emphasised on semantic tokens; SVG normalised. (Identical to
    # dropdown_menu; AAA contrast adjudicated by the app 0b CI axe, not locally.)
    ITEM = "relative flex w-full cursor-pointer select-none items-center gap-2 rounded-sm " \
           "px-2 py-1.5 text-sm outline-none " \
           "hover:bg-surface-sunken hover:text-text-heading " \
           "focus-visible:bg-surface-sunken focus-visible:text-text-heading " \
           "aria-disabled:pointer-events-none aria-disabled:opacity-60 aria-disabled:cursor-not-allowed " \
           "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 " \
           "[&_svg:not([class*='text-'])]:text-text-muted"
    SEPARATOR = "-mx-1 my-1 h-px bg-border"

    # id:         menu id (auto-generated if omitted; → aria-controls)
    # label:      explicit menu accessible name (aria-label). Omit to name the menu by the
    #             host region (aria-labelledby) — pass `label:` when the host is large/verbose.
    def initialize(id: nil, label: nil, **html_attrs)
      @id          = id || "context-menu-#{SecureRandom.hex(4)}"
      @trigger_id  = "#{@id}-trigger"
      @label       = label
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      raise ArgumentError, "UI::ContextMenuComponent requires a with_trigger slot" unless trigger?

      content_tag(:div, **wrapper_attrs) do
        safe_join([trigger_region, menu_panel])
      end
    end

    private

    def wrapper_attrs
      caller_data = @html_attrs.delete(:data) || {}
      {
        class: cn("relative", @extra_class),
        data: { controller: "menu", action: "click@document->menu#closeOnClickOutside" }.merge(caller_data)
      }.merge(@html_attrs)
    end

    def trigger_region
      content_tag(:div, trigger,
        id: @trigger_id,
        class: "select-none",
        tabindex: "0",
        "aria-haspopup": "menu",
        "aria-expanded": "false",
        "aria-controls": @id,
        data: { menu_target: "trigger", action: "contextmenu->menu#openAt keydown->menu#openContextKey" })
    end

    def menu_panel
      content_tag(:div, safe_join(items),
        id: @id,
        role: "menu",
        "aria-labelledby": (@trigger_id unless @label),
        "aria-label": @label,
        tabindex: "-1",
        hidden: true,
        style: "top: 0; left: 0",
        data: { menu_target: "menu", action: "keydown->menu#navigate" },
        class: PANEL_BASE)
    end
  end
end
```

- [ ] **Step 2: Run the render test — verify it PASSES**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/context_menu_render_test.rb
```
Expected: PASS — all 10 tests green.

- [ ] **Step 3: Full gem render suite + rubocop**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rubocop lib/generators/modelrails_ui/add/templates/context_menu/context_menu_component.rb.tt test/render/context_menu_render_test.rb
```
Expected: full suite 0 failures (incl. dropdown_menu unaffected); rubocop clean (autocorrect incidental offenses with `-A`, then re-run the render test to confirm still GREEN).

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/context_menu/context_menu_component.rb.tt
git commit -m "feat(menu): harden context_menu to APG menu (right-click + Shift+F10) (GREEN)

Focusable host (aria-haspopup=menu/expanded/controls; contextmenu->openAt +
keydown->openContextKey); role=menu fixed panel named by host or label:; with_item
slots → role=menuitem (roving tabindex), disabled/separator/href; reuses the shared
menu controller (no side/align; JS pointer positioning)."
```

---

## Task 4: Gem doc + ledger

**Files:**
- Create/Rewrite: `docs/components/context_menu.md`
- Modify: `COMPONENT_STATUS.md`

- [ ] **Step 1: Write the component doc**

Overwrite `docs/components/context_menu.md` with:

```markdown
# Context menu

A menu of actions opened by right-clicking (or Shift+F10 / the ContextMenu key on the
keyboard) a host region, implementing the WAI-ARIA APG menu pattern. Behavior is the
shared `menu` Stimulus controller (the same one `dropdown_menu` uses); positioning is JS
(the panel is `fixed`, placed at the pointer or near the host).

Requires `menu_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add context_menu
```

Creates `app/components/ui/context_menu_component.rb` and
`app/javascript/controllers/menu_controller.js`.

## Usage

```erb
<%= render(UI::ContextMenuComponent.new) do |c| %>
  <% c.with_trigger do %>
    <div class="rounded border border-border p-6">Right-click this card</div>
  <% end %>
  <% c.with_item { "Edit" } %>
  <% c.with_item(disabled: true) { "Archive" } %>
  <% c.with_item(separator: true) %>
  <% c.with_item(href: "/reports/new") { "New report" } %>
<% end %>
```

`with_trigger` (the right-clickable host) is required. Each `with_item` becomes a
`role="menuitem"`:

| Option | Effect |
|--------|--------|
| `disabled: true` | `aria-disabled` — skipped by keyboard nav, activation rejected |
| `separator: true` | renders a divider (no content) in source order |
| `href: "/path"` | renders an `<a role="menuitem">` instead of a `<button>` |

Pass `label:` to name the menu explicitly (`aria-label`); omit it to name the menu by
the host region (`aria-labelledby`) — prefer `label:` when the host is large.

## Keyboard

| Key | Action |
|-----|--------|
| right-click on host | Open at the pointer |
| `Shift+F10` / ContextMenu key (host focused) | Open near the host |
| `↓` / `↑` | Move (wraps, skips disabled) |
| `Home` / `End` | First / last item |
| type a letter | Jump to the next item starting with it (1s buffer) |
| `Enter` / `Space` / click | Activate item, close |
| `Escape` / `Tab` / outside-click | Close, return focus to the host |

## Accessibility

WCAG 2.2 AAA. Keyboard parity (Shift+F10) is mandatory — right-click is pointer-only
(WCAG 2.1.1). Roving tabindex keeps one item focusable at a time. Proven by
`spec/system/ui/context_menu_component_spec.rb` in the host app.
```

- [ ] **Step 2: Add the ledger row → `hardened`**

In `COMPONENT_STATUS.md`, add this row immediately AFTER the `dropdown_menu` row (and before the `All other gem components: …` line):

```markdown
| context_menu | hardened | ✅ | ⏳ | Menu-band (Wave 6): right-click + Shift+F10 APG menu; reuses the shared `menu` controller via EXTRA_STIMULUS (+ openAt); focusable host trigger; JS pointer positioning (no side/align). 0a render test; app 0b CI-pending |
```

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add docs/components/context_menu.md COMPONENT_STATUS.md
git commit -m "docs(menu): context_menu usage doc + ledger row (hardened)"
```

> **Gem PR gate:** do NOT push/PR yet — the app adoption (Tasks 5–8) proves the 0b first; pushing is user-gated. The human opens both PRs after the full app suite is green (Task 8). The gem branch is `harden/context-menu`.

---

## Task 5: App — vendor (with shared-controller update)

**Files:**
- Modify (temp): `Gemfile`
- Create (generator): `app/components/ui/context_menu_component.rb`, updated `app/javascript/controllers/menu_controller.js`
- Delete if present: `app/javascript/controllers/context_menu_controller.js`

- [ ] **Step 1: Create the app adoption branch**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git checkout main && git pull --ff-only
git checkout -b feat/ui-context-menu
```

- [ ] **Step 2: Temp-pin the Gemfile to the gem branch + local override**

The gem work is on `harden/context-menu` (unpushed). In `/Users/dschmura/Documents/code/modelrails_base/Gemfile`, find:

```ruby
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "modelrails/harden"
```

Replace with:

```ruby
  # TEMP-PIN: re-pin to "modelrails/harden" after the context_menu gem PR merges.
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "harden/context-menu"
```

Then point Bundler at the local checkout (no push needed):

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle config set --local local.modelrails_ui /Users/dschmura/Documents/code/modelrails_ui
mise exec -- bundle install
mise exec -- bundle info modelrails_ui   # expect Path: /Users/dschmura/Documents/code/modelrails_ui
```

- [ ] **Step 3: Regenerate context_menu (vendors component + re-copies shared menu_controller.js)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails g modelrails_ui:add context_menu --force
```
Expected: writes `app/components/ui/context_menu_component.rb` and (re)writes `app/javascript/controllers/menu_controller.js` (now with `openAt`/`openContextKey`/`positionAt`).

- [ ] **Step 4: Remove any stale context_menu controller**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git rm app/javascript/controllers/context_menu_controller.js 2>/dev/null || echo "(none — fine)"
```

- [ ] **Step 5: Verify the vendored files (incl. the shared-controller update)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
diff app/javascript/controllers/menu_controller.js /Users/dschmura/Documents/code/modelrails_ui/lib/generators/modelrails_ui/add/templates/dropdown_menu/menu_controller.js && echo "CONTROLLER MATCHES (has openAt)"
grep -q "openAt" app/javascript/controllers/menu_controller.js && echo "openAt PRESENT"
grep -q 'role: "menu"' app/components/ui/context_menu_component.rb && echo "COMPONENT VENDORED"
```
Expected: `CONTROLLER MATCHES (has openAt)`, `openAt PRESENT`, `COMPONENT VENDORED`. (Component .rb may be rubocop-reformatted — semantic parity; the controller .js is byte-identical.)

- [ ] **Step 6: Sanity — dropdown_menu still works with the updated shared controller**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/dropdown_menu_component_spec.rb
```
Expected: 9 examples, 0 failures (the `openAt` additions are inert for dropdown_menu — this proves the shared-controller change didn't regress the existing consumer). Judge by the example line (SimpleCov may exit 2 on a single-file run).

- [ ] **Step 7: Commit the vendor**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add app/components/ui/context_menu_component.rb app/javascript/controllers/menu_controller.js Gemfile Gemfile.lock
git add -u app/javascript/controllers/context_menu_controller.js 2>/dev/null
git commit -m "feat(ui): vendor hardened context_menu + shared menu controller openAt"
```

---

## Task 6: App — preview

**Files:**
- Create: `spec/components/previews/ui/context_menu_component_preview.rb`
- Create: `spec/components/previews/ui/context_menu_component_preview/basic.html.erb`

> **No `@param` playground:** `context_menu` has no enum params (no `side`/`align` — it's pointer-positioned), so there is nothing to sweep. A single `basic` scenario is the template-backed preview; this is a documented, deliberate deviation from DoD item 10's `@param` playground (which only applies to components with enum params).

- [ ] **Step 1: Write the preview class**

Create `spec/components/previews/ui/context_menu_component_preview.rb`:

```ruby
# frozen_string_literal: true

module UI
  # # Context menu
  #
  # A menu of actions opened by right-clicking — or Shift+F10 / the ContextMenu key while
  # the host has focus — on a host region, via the shared `menu` controller. No enum params
  # (pointer-positioned), so no @param playground.
  #
  # ## Accessibility contract
  # - **Guarantees:** focusable host (`aria-haspopup="menu"` + synced `aria-expanded`);
  #   `contextmenu` + Shift+F10 open; `role="menu"` named by the host; `role="menuitem"`
  #   items with roving tabindex.
  # - **You supply:** a `with_trigger` host slot and `with_item` slots.
  class ContextMenuComponentPreview < ViewComponent::Preview
    include UIHelper

    # Right-click (or focus + Shift+F10) the card to open the menu.
    def basic
    end
  end
end
```

- [ ] **Step 2: Write `basic.html.erb`**

Create `spec/components/previews/ui/context_menu_component_preview/basic.html.erb`:

```erb
<div class="flex min-h-96 items-center justify-center p-12">
  <%= render(UI::ContextMenuComponent.new(label: "Card actions")) do |c| %>
    <% c.with_trigger do %>
      <div class="rounded-md border border-border bg-surface p-10 text-text-body">
        Right-click me (or focus + Shift+F10)
      </div>
    <% end %>
    <% c.with_item { "Edit" } %>
    <% c.with_item { "Duplicate" } %>
    <% c.with_item(disabled: true) { "Archive" } %>
    <% c.with_item(separator: true) %>
    <% c.with_item(href: "#") { "Open docs" } %>
  <% end %>
</div>
```

- [ ] **Step 3: Verify ERB syntax (route render proven by the 0b in Task 7)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- ruby -e 'require "erb"; ERB.new(File.read("spec/components/previews/ui/context_menu_component_preview/basic.html.erb")).src; puts "basic: syntax OK"'
```
Expected: `basic: syntax OK`. (The authoritative render check is the Task-7 0b visiting `/rails/view_components/ui/context_menu_component/basic`.)

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/components/previews/ui/context_menu_component_preview.rb spec/components/previews/ui/context_menu_component_preview/
git commit -m "test(ui): context_menu preview (right-click + Shift+F10 host)"
```

---

## Task 7: App — 0b browser-axe + keyboard/right-click/Shift+F10 spec

**Files:**
- Create: `spec/system/ui/context_menu_component_spec.rb`

This is the real gate. Mirror the dropdown_menu 0b but drive the context-menu open paths (right-click + Shift+F10).

- [ ] **Step 1: Write the system spec**

Create `spec/system/ui/context_menu_component_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

# Preview-host accessibility + behavior proof for the context_menu component.
#
# The menu opens on right-click (contextmenu) at the pointer, AND on Shift+F10 / the
# ContextMenu key while the host has focus (WCAG 2.1.1 keyboard parity). We open it both
# ways and audit the LIVE menu.
#
# NOTE: the per-spec axe call runs axe's default (AA) rule set; the authoritative AAA 7:1
# audit is the CI-only wcag2aaa after-hook (spec/support/playwright_accessibility.rb).
RSpec.describe "Context menu component accessibility", type: :system do
  before { visit "/rails/view_components/ui/context_menu_component/basic" }

  def host
    find("[data-menu-target='trigger']")
  end

  def focused_text
    page.evaluate_script("document.activeElement.textContent.trim()")
  end

  def open_by_right_click
    host.right_click
    expect(page).to have_css("[role='menu']:not([hidden])")
  end

  it "right-click opens a menu that passes AAA in both themes" do
    expect(page).to have_css("[data-menu-target='trigger'][aria-haspopup='menu'][aria-expanded='false']")
    expect(page).to have_css("[role='menu'][aria-label]", visible: :all)

    open_by_right_click

    expect(page).to have_css("[data-menu-target='trigger'][aria-expanded='true']")
    scope = [ "[role='menu']:not([hidden])" ]
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true),
      axe_violations_in_both_themes(include: scope).join("\n")
    )
  end

  it "opens via the keyboard (Shift+F10 on the focused host) and focuses the first item" do
    page.evaluate_script("document.querySelector('[data-menu-target=trigger]').focus()")
    page.driver.with_playwright_page { |pw| pw.keyboard.press("Shift+F10") }

    expect(page).to have_css("[role='menu']:not([hidden])")
    expect(focused_text).to eq("Edit")
  end

  it "ArrowDown wraps and SKIPS the disabled item" do
    open_by_right_click # focus on "Edit"

    page.send_keys(:down) # Duplicate
    expect(focused_text).to eq("Duplicate")
    page.send_keys(:down) # skips disabled "Archive" → "Open docs"
    expect(focused_text).to eq("Open docs")
    page.send_keys(:down) # wraps → "Edit"
    expect(focused_text).to eq("Edit")
  end

  it "type-ahead focuses the next item starting with the typed letter" do
    open_by_right_click
    page.send_keys("d") # → "Duplicate"
    expect(focused_text).to eq("Duplicate")
  end

  it "closes on Escape and returns focus to the host" do
    open_by_right_click
    page.send_keys(:escape)

    expect(page).to have_css("[role='menu'][hidden]", visible: :all)
    expect(page).to have_css("[data-menu-target='trigger'][aria-expanded='false']")
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-haspopup')")).to eq("menu")
  end

  it "closes on an outside click" do
    open_by_right_click
    page.driver.with_playwright_page { |pw| pw.mouse.click(5, 5) }
    expect(page).to have_css("[role='menu'][hidden]", visible: :all)
  end
end
```

- [ ] **Step 2: Run the system spec (must PASS locally, AA)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/context_menu_component_spec.rb
```
Expected: 6 examples, 0 failures (judge by the example line; SimpleCov may exit 2 on a single-file run). **If a keyboard/open example fails, the bug is in the shared `menu_controller.js` (Task 1) — fix it IN THE GEM** (`/Users/dschmura/Documents/code/modelrails_ui/lib/.../dropdown_menu/menu_controller.js`), commit on the gem branch, re-vendor (`mise exec -- bin/rails g modelrails_ui:add context_menu --force`), confirm `diff` matches, and re-run. Do NOT edit the app's vendored copy directly or weaken the spec. After any controller fix, also re-run the dropdown_menu 0b (Task 5 Step 6) to confirm no regression.

- [ ] **Step 3: Commit (once green)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/system/ui/context_menu_component_spec.rb
git commit -m "test(ui): 0b context_menu (right-click + Shift+F10 + roving/type-ahead/escape/AAA)"
```

---

## Task 8: App — full suite + handoff gate

- [ ] **Step 1: Full app suite**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec
```
Expected: 0 failures. This re-proves BOTH `dropdown_menu` AND `context_menu` 0b (the shared `menu_controller.js` changed) plus everything else. Investigate any pending; classify any failure as ours-vs-flake (re-run a flaky system-spec file up to 2x). Do not paper over a real failure.

- [ ] **Step 2: Lint**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rubocop app/components/ui/context_menu_component.rb spec/components/previews/ui/context_menu_component_preview.rb spec/system/ui/context_menu_component_spec.rb
npx --yes @herb-tools/linter spec/components/previews/ui/context_menu_component_preview/basic.html.erb 2>&1 | tail -5 || echo "(herb-lint not local; Lefthook/CI runs it)"
```
Expected: no offenses.

- [ ] **Step 3: Confirm clean tree + branch commits (NO push)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git status --porcelain
git log --oneline main..HEAD
cd /Users/dschmura/Documents/code/modelrails_ui && git log --oneline -6
```

- [ ] **Step 4: STOP — human handoff**

Report: context_menu complete. **Gem** (`harden/context-menu`): shared-controller `openAt`/`openContextKey` + EXTRA_STIMULUS + hardened component + 0a render test + doc + ledger (`hardened`). **App** (`feat/ui-context-menu`): vendored component + re-vendored shared controller, preview, 0b (right-click + Shift+F10 + keyboard + axe), full suite green (incl. dropdown_menu re-proven). Ready for browser review at `/rails/view_components/ui/context_menu_component/basic` (right-click the card; also focus it + Shift+F10) and `/lookbook`. On OK: push gem branch + PR into `modelrails/harden` → merge → re-pin app Gemfile to `modelrails/harden` + drop the local override → push app branch + PR → after app AAA CI green + merge, flip the gem ledger `context_menu` → `proven`. **Merge carefully:** after pushing the app branch, wait until the PR `headRefOid` matches the pushed SHA AND checks are created+passed before merging (a prior wave's `--auto` merged a stale head).

---

## Self-Review

**1. Spec coverage** (band design context_menu requirements → tasks):
- §1 opens on `contextmenu` (right-click) → component `contextmenu->menu#openAt` (Task 3) + controller `openAt` (Task 1) + 0b right-click (Task 7). ✅
- §1 Shift+F10 / ContextMenu key keyboard parity → component `keydown->menu#openContextKey` + controller `openContextKey` (checks Shift+F10 / ContextMenu) + 0b Shift+F10 (Task 7). ✅
- §1 "positioned near the focused element" (keyboard path) → `openContextKey` positions at the trigger's `getBoundingClientRect()` (Task 1). ✅
- §1 identical menu semantics (roving tabindex, type-ahead, Escape/Tab/outside-click, focus restore) → reuses the shared controller; render-asserted (Task 2) + 0b-proven (Task 7). ✅
- §3 JS pointer positioning, `fixed` panel → `PANEL_BASE` `fixed` + controller `positionAt` (Tasks 1, 3). ✅
- §-DoD context_menu has NO `side` prop → `initialize` has no `side`/`align`; no PLACEMENTS (Task 3). ✅
- §-DoD per-component: focusable host with aria-haspopup/expanded/controls; role=menu/menuitem; disabled; i18n (no first-party strings — all author-supplied, like dropdown_menu); doc; slot API; preview (no @param — documented); 0a + 0b. ✅
- **Shared-controller risk:** the `menu_controller.js` change is re-proven for dropdown_menu (Task 5 Step 6 + Task 8 full suite). ✅
- **Out of scope:** `menubar` (its own wave); `role=group` grouping (deferred since the exemplar). ✅

**2. Placeholder scan:** No TBD/TODO. All code blocks complete. The `i,j`-style — none. ✅

**3. Type/name consistency:** controller targets (`trigger`/`menu`/`item`) ↔ component `data-menu-target` values match; new controller methods (`openAt`/`openContextKey`/`positionAt`) match the component's `data-action` (`contextmenu->menu#openAt`, `keydown->menu#openContextKey`) and the render test assertions; `EXTRA_STIMULUS` source path (`dropdown_menu/menu_controller.js`) matches where the controller lives; preview/0b scenario name (`basic`) matches. ✅

**Flagged-for-browser-review (CI/visual, not local):** AAA contrast of the focus highlight + 44px item targets (same as dropdown_menu — adjudicated by the app CI `test` job). The host region's `tabindex="0"` + nested interactive content (if any) is an authoring concern noted in the doc.
