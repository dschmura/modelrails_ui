# Navbar (Navigation-Band Arc 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `navbar` to a `<nav>` landmark with an APG **disclosure** mobile menu — rewrite the broken `nextElementSibling` controller to a target-based disclosure (`aria-expanded`/`aria-controls` sync + Escape + outside-click), **add the mobile menu panel that doesn't currently exist**, i18n the nav label + hamburger name, and add `aria-current="page"` on the active link.

**Architecture:** Two repos, two PRs. **Gem** (`modelrails_ui`, branch `harden/navbar` off `modelrails/harden`): rewrite `navbar_controller.js` (disclosure) + `navbar_component.rb.tt` (nav label, hamburger aria-expanded/controls/i18n, the new mobile menu panel, controller wiring, aria-current), add a 0a render test, update structural tests + doc + ledger. **App** (`modelrails_base`, branch `feat/ui-navbar` off `main`): re-vendor, add a preview, and a 0b system spec driving the disclosure (at a MOBILE viewport — the hamburger is `md:hidden`). navbar owns its controller (no `EXTRA_STIMULUS` reuse).

**Tech Stack:** Ruby 4.0.5 (gem) / 4.0.4 (app), Rails 8.1, ViewComponent 4, Stimulus (importmap), TailwindCSS 4 (OKLCH semantic tokens), RSpec + Capybara + Playwright + axe-core (WCAG 2.2 AAA, CI-only 7:1 hook).

**Design contract:** `docs/design/2026-06-08-navigation-band-design.md` §3 (navbar disclosure), §5 (DoD/verification).

**Toolchain (exact):** Gem — `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …`, render load path `-Itest/render`. App — `mise exec -- bundle exec …`.

**Sibling references:** `tabs` (the just-shipped exemplar — `call`-based component, `caller_data` extract-and-merge, render-test/preview/0b shape, structural-test update pattern). The disclosure controller mirrors the `menu`/`floating` controllers' close-on-escape/outside-click idioms.

**KEY CONSTRAINT (the 0b):** the hamburger is `md:hidden` (visible only below the `md` breakpoint, 768px). The 0b MUST resize the browser to a mobile viewport (e.g. 375×800) before exercising the disclosure, or the toggle is `display:none` and unclickable.

**KEY CONSTRAINT (i18n):** call `t(...)` only at RENDER time (in `call`/private render methods), NEVER in `initialize` — a ViewComponent has no view context during `initialize`, and the structural tests instantiate the component without rendering.

---

## File Structure

**Gem:**

| File | Responsibility | Action |
|---|---|---|
| `lib/generators/modelrails_ui/add/templates/navbar/navbar_controller.js` | Disclosure controller (toggle/open/close + aria-expanded sync + Escape + outside-click; target-based) | Rewrite |
| `lib/generators/modelrails_ui/add/templates/navbar/navbar_component.rb.tt` | `<nav>` landmark (i18n label); hamburger (aria-expanded/controls/i18n); the new mobile menu panel; aria-current; controller wiring | Rewrite |
| `test/render/navbar_render_test.rb` | 0a structure-only render test | Create |
| `test/test_components.rb` / `test/test_generator_components.rb` | structural assertions | Modify (as needed) |
| `docs/components/navbar.md` | Usage doc | Create/Rewrite |
| `COMPONENT_STATUS.md` | `navbar` row → hardened then proven | Modify |

**App:** `Gemfile` (temp-pin), generator-created `app/components/ui/navbar_component.rb` + `app/javascript/controllers/navbar_controller.js` (vendored), `spec/components/previews/ui/navbar_component_preview.rb` + template, `spec/system/ui/navbar_component_spec.rb` (0b).

---

## Task 1: The disclosure `navbar` controller

**Files:** Rewrite `lib/generators/modelrails_ui/add/templates/navbar/navbar_controller.js`

> No gem-side JS test; behavior is proven in the app 0b (Task 7).

- [ ] **Step 1: Rewrite the controller**

Overwrite `lib/generators/modelrails_ui/add/templates/navbar/navbar_controller.js` with EXACTLY:

```js
import { Controller } from "@hotwired/stimulus"

// Disclosure for the responsive navbar mobile menu. The hamburger (`toggle` target) controls
// the mobile menu panel (`menu` target): toggling syncs aria-expanded on the toggle; Escape
// closes it and returns focus to the toggle; an outside click closes it. The panel stays
// md:hidden (desktop shows the inline menu instead), so this only matters below the md breakpoint.
export default class extends Controller {
  static targets = ["menu", "toggle"]

  toggle() {
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close({ restoreFocus = false } = {}) {
    if (this.menuTarget.hidden) return
    this.menuTarget.hidden = true
    this.toggleTarget.setAttribute("aria-expanded", "false")
    if (restoreFocus) this.toggleTarget.focus()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close({ restoreFocus: true })
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
```

- [ ] **Step 2: Syntax-check**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
node --check lib/generators/modelrails_ui/add/templates/navbar/navbar_controller.js && echo "JS OK"
```
Expected: `JS OK`. (No other component shares this controller.)

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/navbar/navbar_controller.js
git commit -m "feat(navbar): disclosure controller (target-based toggle + aria-expanded + Escape + outside-click)

Replaces the broken nextElementSibling toggle: drives the mobile menu via a `menu`
target, syncs aria-expanded on the `toggle` target, closes on Escape (returns focus to
the toggle) and on an outside click. Behavior proven in the app 0b."
```

---

## Task 2: 0a render test (RED)

**Files:** Create `test/render/navbar_render_test.rb`

- [ ] **Step 1: Write the failing render test**

Create `test/render/navbar_render_test.rb`:

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "navbar", "navbar_component.rb.tt"

# STRUCTURE-only render specs. The disclosure behavior (toggle, aria-expanded sync, Escape +
# focus return, outside-click) is proven by the app 0b browser spec at a mobile viewport — the
# render harness cannot exercise JS, so here we assert the static scaffolding.
class NavbarRenderTest < ViewComponent::TestCase
  def render_navbar
    render_inline(UI::NavbarComponent.new(brand: "Acme", items: [
      {label: "Home", href: "/", active: true},
      {label: "Pricing", href: "/pricing"}
    ]))
  end

  def test_nav_is_a_landmark_wired_to_the_navbar_controller
    render_navbar

    assert_selector "nav[aria-label][data-controller='navbar']" \
                    "[data-action~='keydown->navbar#closeOnEscape']" \
                    "[data-action~='click@document->navbar#closeOnClickOutside']", visible: :all
  end

  def test_hamburger_is_a_disclosure_button
    render_navbar

    assert_selector "button[type='button'][aria-expanded='false'][aria-controls]" \
                    "[data-navbar-target='toggle'][data-action~='click->navbar#toggle'][aria-label]",
      visible: :all
  end

  def test_hamburger_controls_the_hidden_mobile_menu_panel
    render_navbar

    button = page.find("button[data-navbar-target='toggle']", visible: :all)
    menu_id = button["aria-controls"]
    assert_selector "div##{menu_id}[data-navbar-target='menu'][hidden]", visible: :all
  end

  def test_active_link_is_aria_current_page
    render_navbar

    assert_selector "a[aria-current='page']", text: "Home", visible: :all
    assert_no_selector "a[aria-current='page']", text: "Pricing", visible: :all
  end

  def test_caller_data_merges_without_clobbering_the_controller
    render_inline(UI::NavbarComponent.new(items: [{label: "Home", href: "/"}], data: {turbo_frame: "f"}))

    assert_selector "nav[data-controller='navbar'][data-turbo-frame='f']", visible: :all
  end

  def test_nav_label_can_be_overridden
    render_inline(UI::NavbarComponent.new(label: "Primary", items: [{label: "Home", href: "/"}]))

    assert_selector "nav[aria-label='Primary']", visible: :all
  end
end
```

- [ ] **Step 2: Run — verify FAIL (RED)**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/navbar_render_test.rb
```
Expected: FAIL — the current component has no `aria-label` on the nav, no `aria-expanded`/`aria-controls` on the hamburger, NO mobile menu panel, no `aria-current`, no `label:` param, no `closeOnEscape`/`closeOnClickOutside` actions. Failures must be CONTRACT failures, NOT a harness-load error. If the harness can't load, report BLOCKED.

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add test/render/navbar_render_test.rb
git commit -m "test(navbar): 0a render scaffolding for APG disclosure navbar (RED)"
```

---

## Task 3: Rewrite the component (GREEN)

**Files:** Rewrite `lib/generators/modelrails_ui/add/templates/navbar/navbar_component.rb.tt`; Modify structural tests as needed

- [ ] **Step 1: Replace `navbar_component.rb.tt` with EXACTLY:**

```ruby
# frozen_string_literal: true

module UI
  # # Navbar
  #
  # A responsive top navigation bar (a `<nav>` landmark) — a brand, inline desktop links, an
  # optional right-aligned action area (block content), and a mobile disclosure: a hamburger
  # toggles a stacked menu panel. The disclosure follows the WAI-ARIA APG disclosure pattern
  # (aria-expanded/controls + Escape + outside-click), driven by the `navbar` Stimulus controller.
  #
  # ## Accessibility contract
  # - **Guarantees:** `<nav>` named by `label:` (i18n default "Main"); the hamburger is a
  #   `<button>` with synced `aria-expanded` + `aria-controls`; the mobile panel toggles
  #   `hidden`; Escape closes it (focus returns to the toggle); an outside click closes it; the
  #   active link carries `aria-current="page"`.
  # - **You supply:** `items:` (`[{ label:, href:, active: }]`); optional `brand:`/`brand_href:`;
  #   optional block content for the right action area.
  class NavbarComponent < ApplicationComponent
    LINK_BASE   = "text-sm font-medium transition-colors hover:text-text-heading"
    LINK_IDLE   = "text-text-muted"
    LINK_ACTIVE = "text-text-heading"
    MOBILE_LINK = "block rounded-md px-3 py-2 text-sm font-medium hover:bg-surface-sunken hover:text-text-heading"

    # brand/brand_href: optional brand link. items: nav links. label: the <nav> accessible name
    # (i18n; defaults to t("ui.navbar.label", default: "Main")). Block content → right action area.
    def initialize(brand: nil, brand_href: "/", items: [], label: nil, **html_attrs)
      @brand       = brand
      @brand_href  = brand_href
      @items       = items
      @label       = label
      @menu_id     = "navbar-menu-#{SecureRandom.hex(4)}"
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    # rubocop:disable Layout/LineLength
    NAV = "sticky top-0 z-50 w-full border-b bg-surface-raised/95 backdrop-blur supports-[backdrop-filter]:bg-surface-raised/60"
    # rubocop:enable Layout/LineLength

    def call
      caller_data = @html_attrs.delete(:data) || {}
      content_tag(:nav, safe_join([top_row, mobile_menu]),
        "aria-label": nav_label,
        class: cn(NAV, @extra_class),
        data: {
          controller: "navbar",
          action: "keydown->navbar#closeOnEscape click@document->navbar#closeOnClickOutside"
        }.merge(caller_data),
        **@html_attrs)
    end

    private

    # t() is resolved at RENDER time (here, not in initialize — no view context there).
    def nav_label
      @label || t("ui.navbar.label", default: "Main")
    end

    def top_row
      content_tag(:div, safe_join([brand_link, desktop_menu, spacer, action_area, hamburger]),
        class: "container mx-auto flex h-14 items-center gap-4 px-4")
    end

    def brand_link
      return "" unless @brand

      content_tag(:a, @brand, href: @brand_href,
        class: "mr-2 flex items-center font-semibold text-text-heading")
    end

    def desktop_menu
      return "" if @items.empty?

      content_tag(:div, safe_join(@items.map { |item| nav_link(item) }),
        class: "hidden items-center gap-1 md:flex")
    end

    def nav_link(item)
      content_tag(:a, item[:label], href: item[:href],
        "aria-current": (item[:active] ? "page" : nil),
        class: cn(LINK_BASE, item[:active] ? LINK_ACTIVE : LINK_IDLE))
    end

    def spacer
      content_tag(:div, nil, class: "flex-1")
    end

    def action_area
      return "" unless content?

      content_tag(:div, content, class: "hidden items-center gap-2 md:flex")
    end

    def hamburger
      return "" if @items.empty?

      content_tag(:button, hamburger_icon,
        type: "button",
        "aria-label": t("ui.navbar.toggle", default: "Toggle menu"),
        "aria-expanded": "false",
        "aria-controls": @menu_id,
        class: "inline-flex items-center justify-center rounded-md p-2 text-text-muted hover:bg-surface-sunken hover:text-text-heading md:hidden",
        data: {navbar_target: "toggle", action: "click->navbar#toggle"})
    end

    def mobile_menu
      return "" if @items.empty?

      content_tag(:div, safe_join(@items.map { |item| mobile_link(item) }),
        id: @menu_id,
        hidden: true,
        class: "space-y-1 border-t px-4 py-2 md:hidden",
        data: {navbar_target: "menu"})
    end

    def mobile_link(item)
      content_tag(:a, item[:label], href: item[:href],
        "aria-current": (item[:active] ? "page" : nil),
        class: cn(MOBILE_LINK, item[:active] ? LINK_ACTIVE : LINK_IDLE))
    end

    def hamburger_icon
      raw(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <line x1="4" x2="20" y1="6" y2="6"/>
          <line x1="4" x2="20" y1="12" y2="12"/>
          <line x1="4" x2="20" y1="18" y2="18"/>
        </svg>
      SVG
    end
  end
end
```

- [ ] **Step 2: Update structural tests (JUDGMENT — read failures, don't guess)**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
grep -n "navbar\|Navbar" test/test_components.rb test/test_generator_components.rb
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test 2>&1 | tail -20
```
- `test_generator_components.rb`: `test_navbar_has_js_controller` (asserts the colocated controller exists) — STILL TRUE (we kept `navbar_controller.js`). Leave it.
- `test_components.rb` (`TestNavbarComponent`, ~line 1254): it instantiates `NavbarComponent.new(...)` with various args and likely asserts instance variables (`@brand`, `@items`, `@extra_class`, the data passthrough, etc.). The rewrite KEEPS all old params (`brand:`/`brand_href:`/`items:`/`class:`/`**html_attrs`) and ADDS `label:` + `@menu_id` + `@label`. So existing ivar assertions should still pass. The data-passthrough test (`new("data-testid": "main-nav")`) still works (it goes through `**@html_attrs`). If any assertion fails, read it and adapt to the new contract (e.g. if it asserted the OLD `LINK_BASE`-only constant set, the constants are unchanged; if it rendered and asserted old markup, update to the new markup). Do NOT guess — read the failing assertion. **CRITICAL: `t()` must NOT be called in `initialize`** — if a structural test does `NavbarComponent.new` (no render) and it raises about `t`/translate/view context, you put a `t()` call in `initialize` by mistake; move it to a render-time method (`nav_label`).

- [ ] **Step 3: Run the navbar render test — GREEN**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/navbar_render_test.rb
```
Expected: all 6 tests PASS. (The render harness renders the component, so `t()` IS available there — `nav_label` resolves to "Main".)

- [ ] **Step 4: Full gem suite + rubocop**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rubocop -A lib/generators/modelrails_ui/add/templates/navbar/navbar_component.rb.tt test/render/navbar_render_test.rb test/test_components.rb
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/navbar_render_test.rb
```
Expected: full suite 0 failures; rubocop clean (after `-A`); render test still GREEN. If `rake test` fails on a navbar structural assertion, return to Step 2.

- [ ] **Step 5: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/navbar/navbar_component.rb.tt test/test_components.rb test/test_generator_components.rb
git commit -m "feat(navbar): harden to APG disclosure navbar (GREEN)

<nav> landmark (i18n aria-label, default Main); hamburger is a real disclosure button
(aria-expanded/aria-controls, i18n label) controlling a NEW mobile menu panel (was
missing — the old hamburger toggled a non-existent nextElementSibling); active link gets
aria-current=page; caller data merges without clobbering the controller wiring."
```

---

## Task 4: Gem doc + ledger

**Files:** Create/Rewrite `docs/components/navbar.md`; Modify `COMPONENT_STATUS.md`

- [ ] **Step 1: Write the doc**

Write `docs/components/navbar.md`:

```markdown
# Navbar

A responsive top navigation bar (a `<nav>` landmark) — a brand, inline desktop links, an
optional right-aligned action area, and a mobile disclosure (a hamburger toggles a stacked
menu). The disclosure follows the WAI-ARIA APG disclosure pattern.

Requires `navbar_controller.js` (copied by the generator).

## Installation

```bash
rails g modelrails_ui:add navbar
```

## Usage

```erb
<%= render(UI::NavbarComponent.new(
  brand: "Acme",
  brand_href: root_path,
  label: "Main",
  items: [
    { label: "Dashboard", href: "/dashboard", active: true },
    { label: "Pricing", href: "/pricing" }
  ]
)) do %>
  <%= link_to "Sign in", "/login", class: "btn-primary" %>
<% end %>
```

`label:` is the `<nav>` accessible name (i18n; defaults to `t("ui.navbar.label", default: "Main")`).
`items:` are the links (`active: true` → `aria-current="page"`). Block content goes in the
right-aligned action area (desktop). On narrow screens the inline links collapse behind a
hamburger that discloses a stacked menu.

## Keyboard

| Key | Action |
|-----|--------|
| `Enter` / `Space` on the hamburger | Toggle the mobile menu (syncs `aria-expanded`) |
| `Escape` | Close the mobile menu, return focus to the hamburger |
| click outside | Close the mobile menu |

## Accessibility

WCAG 2.2 AAA. `<nav>` named by `label:`; the hamburger is a `<button>` with synced
`aria-expanded` + `aria-controls`; the active link is `aria-current="page"`. Proven by
`spec/system/ui/navbar_component_spec.rb` in the host app (at a mobile viewport).
```

- [ ] **Step 2: Ledger row → hardened**

In `COMPONENT_STATUS.md`, add ONE row immediately after the `tabs` row:

```markdown
| navbar | hardened | ✅ | ⏳ | Navigation band (Wave 7): `<nav>` landmark (i18n label) + APG disclosure mobile menu (hamburger aria-expanded/controls + Escape + outside-click, target-based controller; added the missing menu panel); aria-current on active link. 0a render test; app 0b CI-pending |
```

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add docs/components/navbar.md COMPONENT_STATUS.md
git commit -m "docs(navbar): usage doc + ledger row (hardened)"
```

> **Gem PR gate:** do NOT push/PR yet — the app 0b proves it first (Tasks 5–8). Gem branch: `harden/navbar`.

---

## Task 5: App — vendor

**Files:** `Gemfile` (temp-pin); generator-created `app/components/ui/navbar_component.rb`, `app/javascript/controllers/navbar_controller.js`.

- [ ] **Step 1: Branch + temp-pin + install**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git checkout main && git pull --ff-only
git checkout -b feat/ui-navbar
```
In `Gemfile`, replace:
```ruby
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "modelrails/harden"
```
with:
```ruby
  # TEMP-PIN: re-pin to "modelrails/harden" after the navbar gem PR merges.
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "harden/navbar"
```
Then:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle config set --local local.modelrails_ui /Users/dschmura/Documents/code/modelrails_ui
mise exec -- bundle install 2>&1 | tail -3
mise exec -- bundle info modelrails_ui 2>&1 | grep -i "Path" | head -1
```
Expected: Path → `/Users/dschmura/Documents/code/modelrails_ui` (the local override).

- [ ] **Step 2: Regenerate**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails g modelrails_ui:add navbar --force 2>&1 | tail -8
```
Expected: writes `app/components/ui/navbar_component.rb`, `app/javascript/controllers/navbar_controller.js`.

- [ ] **Step 3: Verify the vendored files**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
diff app/javascript/controllers/navbar_controller.js /Users/dschmura/Documents/code/modelrails_ui/lib/generators/modelrails_ui/add/templates/navbar/navbar_controller.js && echo "NAVBAR CONTROLLER MATCHES"
grep -q 'navbar_target: "menu"' app/components/ui/navbar_component.rb && echo "MOBILE MENU VENDORED"
grep -q '"aria-expanded": "false"' app/components/ui/navbar_component.rb && echo "DISCLOSURE VENDORED"
mise exec -- bundle exec rubocop -A app/components/ui/navbar_component.rb 2>&1 | tail -2
mise exec -- bundle exec rubocop app/components/ui/navbar_component.rb 2>&1 | tail -2
```
Expected: `NAVBAR CONTROLLER MATCHES`, `MOBILE MENU VENDORED`, `DISCLOSURE VENDORED`, rubocop clean after `-A`. (The `.rb` may be rubocop-reformatted — semantic parity. The `.js` must be byte-exact.) If the controller diff is NOT empty, STOP and report BLOCKED.

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add app/components/ui/navbar_component.rb app/javascript/controllers/navbar_controller.js Gemfile Gemfile.lock
git commit -m "feat(ui): vendor hardened navbar (APG disclosure mobile menu)"
```

---

## Task 6: App — preview

**Files:** Create `spec/components/previews/ui/navbar_component_preview.rb` + `…/navbar_component_preview/basic.html.erb`.

- [ ] **Step 1: Preview class**

```ruby
# frozen_string_literal: true

module UI
  # # Navbar
  #
  # A responsive nav. On a narrow viewport the links collapse behind a hamburger that discloses
  # a stacked menu (aria-expanded/controls + Escape + outside-click). Resize the Lookbook frame
  # narrow to see the mobile disclosure.
  class NavbarComponentPreview < ViewComponent::Preview
    include UIHelper

    # Brand + Dashboard/Pricing/Docs links + a Sign in action (Dashboard active).
    def basic
    end
  end
end
```

- [ ] **Step 2: basic.html.erb**

```erb
<div class="min-h-96">
  <%= render(UI::NavbarComponent.new(
    brand: "Acme",
    brand_href: "#",
    label: "Main",
    items: [
      { label: "Dashboard", href: "#", active: true },
      { label: "Pricing", href: "#" },
      { label: "Docs", href: "#" }
    ]
  )) do %>
    <a href="#" class="btn-primary">Sign in</a>
  <% end %>
  <div class="p-12 text-text-muted">
    <p>Page content. Resize narrow (&lt; 768px) to reveal the hamburger + mobile menu.</p>
  </div>
</div>
```

- [ ] **Step 3: Verify ERB syntax**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- ruby -e 'require "erb"; ERB.new(File.read("spec/components/previews/ui/navbar_component_preview/basic.html.erb")).src; puts "basic: syntax OK"'
```
Expected: `basic: syntax OK`.

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/components/previews/ui/navbar_component_preview.rb spec/components/previews/ui/navbar_component_preview/
git commit -m "test(ui): navbar preview (brand + links + Sign in action)"
```

---

## Task 7: App — 0b browser-axe + disclosure (MOBILE viewport)

**Files:** Create `spec/system/ui/navbar_component_spec.rb`.

The real gate. The hamburger is `md:hidden` — the spec resizes to a MOBILE viewport so it's visible.

- [ ] **Step 1: Write the system spec**

```ruby
# frozen_string_literal: true

require "rails_helper"

# Preview-host accessibility + behavior proof for the navbar component.
#
# The hamburger is `md:hidden` — visible only below the md breakpoint — so we resize the window
# to a MOBILE viewport (375×800) before exercising the disclosure: toggle opens the menu (syncs
# aria-expanded), Escape closes + returns focus to the toggle, an outside click closes. NOTE:
# per-spec axe runs AA locally; the AAA 7:1 audit is the CI-only wcag2aaa hook.
RSpec.describe "Navbar component accessibility", type: :system do
  before do
    visit "/rails/view_components/ui/navbar_component/basic"
    page.current_window.resize_to(375, 800)
  end

  def toggle
    find("button[data-navbar-target='toggle']")
  end

  it "renders the nav and the open mobile menu passes AAA in both themes" do
    expect(page).to have_css("nav[aria-label='Main']")
    expect(toggle["aria-expanded"]).to eq("false")
    expect(page).to have_css("[data-navbar-target='menu']", visible: :hidden)

    toggle.click
    expect(toggle["aria-expanded"]).to eq("true")
    expect(page).to have_css("[data-navbar-target='menu']", visible: :visible)

    scope = [ "nav" ]
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true),
      axe_violations_in_both_themes(include: scope).join("\n")
    )
  end

  it "the hamburger toggles the mobile menu and syncs aria-expanded" do
    expect(page).to have_css("[data-navbar-target='menu']", visible: :hidden)

    toggle.click
    expect(page).to have_css("[data-navbar-target='menu']", visible: :visible)
    expect(toggle["aria-expanded"]).to eq("true")

    toggle.click
    expect(page).to have_css("[data-navbar-target='menu']", visible: :hidden)
    expect(toggle["aria-expanded"]).to eq("false")
  end

  it "Escape closes the menu and returns focus to the hamburger" do
    toggle.click
    expect(page).to have_css("[data-navbar-target='menu']", visible: :visible)

    page.send_keys(:escape)
    expect(page).to have_css("[data-navbar-target='menu']", visible: :hidden)
    expect(toggle["aria-expanded"]).to eq("false")
    expect(page.evaluate_script("document.activeElement.getAttribute('data-navbar-target')")).to eq("toggle")
  end

  it "an outside click closes the menu" do
    toggle.click
    expect(page).to have_css("[data-navbar-target='menu']", visible: :visible)

    page.driver.with_playwright_page { |pw| pw.mouse.click(10, 760) }
    expect(page).to have_css("[data-navbar-target='menu']", visible: :hidden)
    expect(toggle["aria-expanded"]).to eq("false")
  end
end
```

- [ ] **Step 2: Run (must PASS locally, AA)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/navbar_component_spec.rb
```
Expected: **4 examples, 0 failures** (judge by the example line; SimpleCov may exit 2). If Playwright/Chromium/server fails to boot, that is infra.

### IF THE VIEWPORT RESIZE DOESN'T TAKE (hamburger not clickable / `md:hidden` still applies)
`page.current_window.resize_to(375, 800)` should work with the Capybara Playwright driver. If the toggle is reported not-visible (the `md:hidden` still hides it because the viewport didn't shrink), use the Playwright API directly in `before`:
```ruby
before do
  visit "/rails/view_components/ui/navbar_component/basic"
  page.driver.with_playwright_page { |pw| pw.set_viewport_size(width: 375, height: 800) }
end
```
Do NOT remove the `md:hidden` from the component to make the test pass — fix the viewport in the spec.

### IF A DISCLOSURE EXAMPLE FAILS (do NOT weaken the spec)
The bug is in the GEM `navbar_controller.js` or the component wiring. Fix the GEM, commit on `harden/navbar`, re-vendor (`mise exec -- bin/rails g modelrails_ui:add navbar --force`), confirm the `diff` matches, re-run. Likely suspects: the `menu`/`toggle` targets, `aria-expanded` sync, the Escape `restoreFocus`, or `closeOnClickOutside` (`this.element.contains`). Do NOT edit the vendored copy directly. If you fixed + re-vendored: gem fix on the gem branch; app commit `chore(ui): re-vendor navbar controller fix from gem`. If you cannot diagnose after a genuine attempt, report BLOCKED.

### IF ONLY THE AXE (AA) ASSERTION FAILS
Report `axe_violations_in_both_themes`; do NOT add a color-contrast exclude. If unresolvable, report DONE_WITH_CONCERNS (the human adjudicates via CI).

- [ ] **Step 3: Commit (once green)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/system/ui/navbar_component_spec.rb
git commit -m "test(ui): 0b navbar disclosure (mobile viewport: toggle/aria-expanded/Escape+focus/outside-click/AAA)"
```

---

## Task 8: App — full suite + handoff gate

- [ ] **Step 1: Full app suite**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec
```
Expected: 0 failures. Investigate any pending; classify any failure ours-vs-flake (re-run a flaky system-spec file up to 2x).

- [ ] **Step 2: Lint**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rubocop app/components/ui/navbar_component.rb spec/components/previews/ui/navbar_component_preview.rb spec/system/ui/navbar_component_spec.rb
mise exec -- bundle exec rake erb:check
```
Expected: no offenses; `erb:check` exits 0.

- [ ] **Step 3: Clean tree + branch commits (NO push)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git status --porcelain
git log --oneline main..HEAD
cd /Users/dschmura/Documents/code/modelrails_ui && git log --oneline modelrails/harden..HEAD
```

- [ ] **Step 4: STOP — human handoff**

Report: navbar complete. **Gem** (`harden/navbar`): disclosure controller + hardened component (nav label, hamburger aria-expanded/controls/i18n, the NEW mobile menu panel, aria-current) + 0a render test + structural-test update + doc + ledger (hardened). **App** (`feat/ui-navbar`): vendored + preview + 0b (disclosure at mobile viewport, AAA), full suite green. Browser review at `/rails/view_components/ui/navbar_component/basic` (resize narrow; click the hamburger; Escape; click outside) and `/lookbook`. On OK: push gem branch + PR into `modelrails/harden` → careful-merge (poll head==SHA + CI matrix; REST `gh api PUT /pulls/N/merge -f sha=<HEAD>`) → re-pin app `Gemfile` to `modelrails/harden` + drop the local override → push app branch + PR → after app AAA CI green + merge, flip the gem ledger `navbar` → proven.

---

## Self-Review

**1. Spec coverage** (design §3 → tasks):
- `<nav>` landmark + i18n `aria-label` → Task 3 `nav_label` (render-time `t()`); render-asserted Task 2. ✅
- Hamburger disclosure (`aria-expanded` synced, `aria-controls`, i18n name) → Task 3 `hamburger`; Task 1 controller `toggle`/`open`/`close`; render-asserted Task 2; behavior Task 7. ✅
- The NEW mobile menu panel (the disclosed region — was missing) → Task 3 `mobile_menu`; behavior Task 7. ✅
- Escape closes + focus return; outside-click closes → Task 1 `closeOnEscape`/`closeOnClickOutside`; Task 3 nav `data-action`; behavior Task 7. ✅
- Target-based controller (not `nextElementSibling`) → Task 1 (`menu`/`toggle` targets). ✅
- `aria-current="page"` on the active link → Task 3 `nav_link`/`mobile_link`; render-asserted Task 2. ✅
- DoD: 0a (Task 2) + 0b at mobile viewport (Task 7) + doc/ledger (Task 4) + preview (Task 6) + full suite (Task 8). ✅
- Attr-clobber-safe `caller_data` merge (applying the tabs lesson proactively) → Task 3 `call`; render-asserted Task 2. ✅

**2. Placeholder scan:** No TBD/TODO. Task 3 Step 2 has a "read the failing assertion" contingency for the pre-existing `TestNavbarComponent` structural tests — a known integration point (the exact assertions can't be known without running), with the concrete fix pattern + the explicit `t()`-not-in-initialize guard.

**3. Type/name consistency:** controller targets (`menu`/`toggle`) ↔ component wiring (`data-navbar-target=menu`/`toggle`); actions (`navbar#toggle`/`#closeOnEscape`/`#closeOnClickOutside`) match across controller, component, render test, 0b; the hamburger `aria-controls=@menu_id` ↔ the mobile menu `id=@menu_id` cross-reference; `t("ui.navbar.label"/"ui.navbar.toggle", default:)` resolved at render time only.

**Flagged for browser/CI review:** the `bg-surface-raised/95` + `backdrop-blur` nav background contrast on its links (`text-text-muted`/`text-text-heading`) and the mobile menu — AAA adjudicated by the app CI `test` job. The action content (block) stays desktop-only (`hidden md:flex`) — the mobile menu shows the `items:` links only (a deliberate scope choice; adding the action to the mobile panel is a future enhancement, noted not built).
