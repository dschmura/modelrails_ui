# Breadcrumb + Pagination (Navigation-Band Arc 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close out the navigation band. **breadcrumb** → standard component hardening (i18n `<nav>` label + 0a + 0b + doc + ledger → proven). **pagination** → NOT a custom component: the app already uses Pagy's accessible `@pagy.series_nav`; we style it with design-system tokens, prove it AAA on a real paginated view, document the approach, and mark the experimental `PaginationComponent` superseded.

**Architecture:** Two repos, ONE bundled PR each. **Gem** (`modelrails_ui`, branch `harden/breadcrumb-pagination` off `modelrails/harden`): harden the `breadcrumb` component + 0a render test; rewrite the breadcrumb + pagination docs; update the ledger (breadcrumb → hardened; pagination → "Pagy series_nav, app-styled; experimental component superseded"). **App** (`modelrails_base`, branch `feat/ui-breadcrumb-pagination` off `main`): vendor + preview + 0b for breadcrumb; add design-system CSS styling Pagy's `.pagy.series-nav` + a system-spec AAA proof on the real (notifications) paginated view.

**Tech Stack:** Ruby 4.0.5 (gem) / 4.0.4 (app), Rails 8.1, ViewComponent 4, **Pagy 43.5.5** (`@pagy.series_nav` renders accessible markup: `aria-label`, `role="link" aria-current="page"`, `rel="prev"`/`rel="next"`, gap separators), TailwindCSS 4 (OKLCH semantic tokens), RSpec + Capybara + Playwright + axe-core (WCAG 2.2 AAA, CI-only 7:1 hook).

**Design contract:** `docs/design/2026-06-08-navigation-band-design.md` §4 (revised per the Pagy decision: pagination leans on `series_nav`, styled + proven; not a custom component).

**Toolchain (exact):** Gem — `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …`, render load path `-Itest/render`. App — `mise exec -- bundle exec …`.

**Sibling references:** `navbar` (the just-shipped arc — `<nav>` landmark + render-time `t()` label, the structural-test update pattern, render-test/preview/0b shape). The pagination CSS is new territory (styling a third-party gem's output).

**KEY CONSTRAINT (i18n):** call `t(...)` only at RENDER time (in render methods), NEVER in `initialize` — the structural tests instantiate without a view context.

---

## File Structure

**Gem (`modelrails_ui`):**

| File | Responsibility | Action |
|---|---|---|
| `lib/generators/modelrails_ui/add/templates/breadcrumb/breadcrumb_component.rb.tt` | `<nav>` breadcrumb (i18n label; ol/li; aria-current; aria-hidden separator; focus-visible links) | Rewrite |
| `test/render/breadcrumb_render_test.rb` | 0a structure-only render test | Create |
| `test/test_components.rb` | `TestBreadcrumbComponent` structural assertions | Modify (as needed) |
| `docs/components/breadcrumb.md` | Usage doc | Create/Rewrite |
| `docs/components/pagination.md` | "Use Pagy `@pagy.series_nav` + design-system styles" | Create/Rewrite |
| `COMPONENT_STATUS.md` | breadcrumb → hardened; pagination → series_nav note | Modify |

**App (`modelrails_base`):** `Gemfile` (temp-pin); vendored `app/components/ui/breadcrumb_component.rb`; `spec/components/previews/ui/breadcrumb_component_preview.rb` + template; `spec/system/ui/breadcrumb_component_spec.rb` (0b); `app/assets/tailwind/application.css` (pagination series_nav styles); `spec/system/ui/pagination_a11y_spec.rb` (pagination AAA on the notifications view).

---

## Task 1: breadcrumb 0a render test (RED)

**Files:** Create `test/render/breadcrumb_render_test.rb`

- [ ] **Step 1: Write the failing render test**

Create `test/render/breadcrumb_render_test.rb`:

```ruby
# frozen_string_literal: true

require "render_test_helper"
load_component "breadcrumb", "breadcrumb_component.rb.tt"

# STRUCTURE-only render specs. Breadcrumb is a static nav (no JS); the app 0b proves it renders
# + axe-AAA in a real browser. Here we assert the landmark + crumb scaffolding.
class BreadcrumbRenderTest < ViewComponent::TestCase
  def render_crumbs
    render_inline(UI::BreadcrumbComponent.new(items: [
      {label: "Home", href: "/"},
      {label: "Library", href: "/library"},
      {label: "Data"}
    ]))
  end

  def test_nav_is_a_breadcrumb_landmark_with_an_ordered_list
    render_crumbs

    assert_selector "nav[aria-label='Breadcrumb'] ol", visible: :all
  end

  def test_last_item_is_the_current_page
    render_crumbs

    assert_selector "[aria-current='page']", text: "Data", visible: :all
    assert_no_selector "a", text: "Data", visible: :all # current page is not a link
  end

  def test_non_last_items_are_links_with_decorative_separators
    render_crumbs

    assert_selector "a[href='/']", text: "Home", visible: :all
    assert_selector "a[href='/library']", text: "Library", visible: :all
    assert_selector "span[aria-hidden='true']", minimum: 2, visible: :all # separators
  end

  def test_label_can_be_overridden_for_i18n
    render_inline(UI::BreadcrumbComponent.new(label: "You are here", items: [{label: "Home", href: "/"}, {label: "X"}]))

    assert_selector "nav[aria-label='You are here']", visible: :all
  end
end
```

- [ ] **Step 2: Run — verify FAIL (RED)**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/breadcrumb_render_test.rb
```
Expected: FAIL — the current breadcrumb has a HARDCODED `aria-label: "Breadcrumb"` (so `test_label_can_be_overridden_for_i18n` fails — no `label:` param), and may differ on other assertions. Failures must be CONTRACT failures, not a harness-load error. (NOTE: the current component already renders most of the structure, so several assertions may PASS — that's fine; the RED is `test_label_can_be_overridden_for_i18n` + any wiring gap. As long as ≥1 assertion fails on the new contract and the harness loaded, it's a valid RED.)

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add test/render/breadcrumb_render_test.rb
git commit -m "test(breadcrumb): 0a render scaffolding (RED — i18n label override)"
```

---

## Task 2: harden breadcrumb component (GREEN)

**Files:** Rewrite `lib/generators/modelrails_ui/add/templates/breadcrumb/breadcrumb_component.rb.tt`; Modify `test/test_components.rb` as needed

- [ ] **Step 1: Replace `breadcrumb_component.rb.tt` with EXACTLY:**

```ruby
# frozen_string_literal: true

module UI
  # # Breadcrumb
  #
  # A breadcrumb trail (`<nav aria-label>` + ordered list). The last item is the current page
  # (`aria-current="page"`, not a link); earlier items are links separated by a decorative
  # (`aria-hidden`) separator.
  #
  # ## Accessibility contract
  # - **Guarantees:** `<nav>` named by `label:` (i18n, default "Breadcrumb"); an `<ol>` of crumbs;
  #   the current page is `aria-current="page"` and not a link; separators are `aria-hidden`;
  #   links get a visible `:focus-visible` ring.
  # - **You supply:** `items:` (`[{ label:, href: }, …, { label: }]` — the LAST item, with no
  #   `href`, is the current page).
  class BreadcrumbComponent < ApplicationComponent
    LINK = "rounded-sm text-text-muted transition-colors outline-none " \
           "hover:text-text-heading " \
           "focus-visible:ring-1 focus-visible:ring-interactive-focus focus-visible:text-text-heading"
    CURRENT = "font-medium text-text-heading"

    # items: [{ label:, href: }, ..., { label: }] — last item is the current page (no href).
    # separator: the visual divider between crumbs (decorative). label: the <nav> accessible
    # name (i18n; default t("ui.breadcrumb.label", default: "Breadcrumb")).
    def initialize(items: [], separator: "/", label: nil, **html_attrs)
      @items       = items
      @separator   = separator
      @label       = label
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:nav, ordered_list, "aria-label": nav_label, **@html_attrs)
    end

    private

    # t() is resolved at RENDER time (not in initialize — no view context there).
    def nav_label
      @label || t("ui.breadcrumb.label", default: "Breadcrumb")
    end

    def ordered_list
      content_tag(:ol,
        safe_join(@items.each_with_index.map { |item, i| crumb(item, i == @items.size - 1) }),
        class: cn("flex flex-wrap items-center gap-1.5 break-words text-sm text-text-muted sm:gap-2.5", @extra_class))
    end

    def crumb(item, is_last)
      content_tag(:li, class: "inline-flex items-center gap-1.5") do
        if is_last
          content_tag(:span, item[:label], class: CURRENT, "aria-current": "page")
        else
          safe_join([
            content_tag(:a, item[:label], href: item[:href], class: LINK),
            content_tag(:span, @separator, class: "select-none text-text-muted", "aria-hidden": "true")
          ])
        end
      end
    end
  end
end
```

- [ ] **Step 2: Update structural tests (JUDGMENT — read failures, don't guess)**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
grep -n "breadcrumb\|Breadcrumb" test/test_components.rb
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test 2>&1 | tail -20
```
- `TestBreadcrumbComponent` (~line 1034) instantiates `.new`, `.new(separator: "›")`, `.new(items:)`, `.new(class:)` and likely asserts ivars (`@items`, `@separator`, `@extra_class`). The rewrite KEEPS those params + ADDS `label:`. Existing ivar assertions should still pass. **If `.new` (no render) raises about `t`/translate/view context, a `t()` leaked into `initialize` — move it to `nav_label`.** If a test renders + asserts the old markup and the markup changed (it shouldn't materially — same ol/li/a/span structure), adapt it. Read each failure; adapt to the new contract; do not gut tests.

- [ ] **Step 3: Run the breadcrumb render test — GREEN**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/breadcrumb_render_test.rb
```
Expected: all 4 tests PASS.

- [ ] **Step 4: Full gem suite + rubocop**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rubocop -A lib/generators/modelrails_ui/add/templates/breadcrumb/breadcrumb_component.rb.tt test/render/breadcrumb_render_test.rb test/test_components.rb
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/breadcrumb_render_test.rb
```
Expected: full suite 0 failures; rubocop clean (after `-A`); render test still GREEN.

- [ ] **Step 5: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add lib/generators/modelrails_ui/add/templates/breadcrumb/breadcrumb_component.rb.tt test/test_components.rb
git commit -m "feat(breadcrumb): harden to <nav> landmark with i18n label + focus-visible links (GREEN)

i18n aria-label (label:, default t(ui.breadcrumb.label)); ol/li crumbs; current page
aria-current=page (not a link); decorative aria-hidden separators; focus-visible ring on links."
```

---

## Task 3: Gem docs + ledger

**Files:** Create/Rewrite `docs/components/breadcrumb.md` + `docs/components/pagination.md`; Modify `COMPONENT_STATUS.md`

- [ ] **Step 1: Write `docs/components/breadcrumb.md`:**

```markdown
# Breadcrumb

A breadcrumb trail — a `<nav aria-label>` landmark with an ordered list. The last item is the
current page (`aria-current="page"`, not a link); earlier items are links with a decorative
separator.

## Installation

```bash
rails g modelrails_ui:add breadcrumb
```

## Usage

```erb
<%= render(UI::BreadcrumbComponent.new(items: [
  { label: "Home", href: root_path },
  { label: "Library", href: "/library" },
  { label: "Data" }
])) %>
```

The LAST item (no `href`) is the current page. `label:` overrides the `<nav>` accessible name
(i18n; defaults to `t("ui.breadcrumb.label", default: "Breadcrumb")`). `separator:` changes the
divider (default `/`).

## Accessibility

WCAG 2.2 AAA. `<nav>` named by `label:`; an `<ol>` of crumbs; the current page is
`aria-current="page"` and not a link; separators are `aria-hidden="true"`; links carry a
`:focus-visible` ring. Proven by `spec/system/ui/breadcrumb_component_spec.rb` in the host app.
```

- [ ] **Step 2: Write `docs/components/pagination.md`:**

```markdown
# Pagination

**Use Pagy's built-in `@pagy.series_nav`.** This app paginates with [Pagy](https://ddnexus.github.io/pagy/)
(43.x), whose `series_nav` already renders an accessible navigation bar (`aria-label`,
`role="link" aria-current="page"` on the current page, `rel="prev"`/`rel="next"`, gap
separators). There is **no custom `PaginationComponent`** to adopt — building one would only
duplicate Pagy's windowing.

## Usage

In the controller:

```ruby
@pagy, @records = pagy(scope)            # or pagy(:offset, array)
```

In the view (wrap in a design-system container; the app ships a `shared/_pagination` partial):

```erb
<%== @pagy.series_nav(aria_label: t("pagination.aria_label", default: "Pages")) %>
```

`@pagy.page_url(page)` builds a URL for any page; `@pagy.series` is the raw page array
(`[1, 2, "3", 4, :gap, 50]`) if you ever need fully custom markup.

## Styling (design system)

`series_nav` emits `<nav class="pagy series-nav">…</nav>` with plain `<a>` children — **unstyled
by default**. The host app styles them to the design-system tokens (AAA in both themes) via a
`@layer components` block targeting `.pagy.series-nav` (see `app/assets/tailwind/application.css`
in `modelrails_base`, proven by `spec/system/ui/pagination_a11y_spec.rb`). Copy that block to
match your design system.

## Accessibility

WCAG 2.2 AAA. Pagy's `series_nav` provides the ARIA contract; the design-system CSS provides
the AAA-contrast styling in both themes (proven in the host app's CI `test` job).
```

- [ ] **Step 3: Ledger rows**

In `COMPONENT_STATUS.md`, add TWO rows immediately after the `navbar` row:

```markdown
| breadcrumb | hardened | ✅ | ⏳ | Navigation band (Wave 7): `<nav aria-label>` landmark (i18n label) + ol/li; current page aria-current=page (not a link); decorative aria-hidden separators; focus-visible links. 0a render test; app 0b CI-pending |
| pagination | proven | ➖ | ✅ | Navigation band (Wave 7): NOT a custom component — leans on Pagy 43 `@pagy.series_nav` (accessible: aria-label/aria-current/rel) + design-system CSS in the host app (`.pagy.series-nav`), AAA-proven on a real paginated view. The experimental `PaginationComponent` template is superseded (do not adopt). |
```
(The `➖` in the Render-test column for pagination signals "n/a — no component". Keep the other rows unchanged.)

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
git add docs/components/breadcrumb.md docs/components/pagination.md COMPONENT_STATUS.md
git commit -m "docs(nav): breadcrumb usage doc + pagination→Pagy series_nav guidance + ledger rows"
```

> **Gem PR gate:** do NOT push/PR yet — the app proves both first (Tasks 4–8). Gem branch: `harden/breadcrumb-pagination`.

---

## Task 4: App — vendor breadcrumb + preview

**Files:** `Gemfile` (temp-pin); vendored `app/components/ui/breadcrumb_component.rb`; `spec/components/previews/ui/breadcrumb_component_preview.rb` + template.

- [ ] **Step 1: Branch + temp-pin + install**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git checkout main && git pull --ff-only
git checkout -b feat/ui-breadcrumb-pagination
```
In `Gemfile`, replace the `modelrails_ui` line:
```ruby
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "modelrails/harden"
```
with:
```ruby
  # TEMP-PIN: re-pin to "modelrails/harden" after the breadcrumb/pagination gem PR merges.
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", branch: "harden/breadcrumb-pagination"
```
Then:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle config set --local local.modelrails_ui /Users/dschmura/Documents/code/modelrails_ui
mise exec -- bundle install 2>&1 | tail -3
mise exec -- bundle info modelrails_ui 2>&1 | grep -i "Path" | head -1
```
Expected: Path → the local gem checkout.

- [ ] **Step 2: Regenerate + verify**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails g modelrails_ui:add breadcrumb --force 2>&1 | tail -6
grep -q 'aria-current' app/components/ui/breadcrumb_component.rb && echo "BREADCRUMB VENDORED"
mise exec -- bundle exec rubocop -A app/components/ui/breadcrumb_component.rb 2>&1 | tail -2
mise exec -- bundle exec rubocop app/components/ui/breadcrumb_component.rb 2>&1 | tail -2
```
Expected: `BREADCRUMB VENDORED`; rubocop clean after `-A`. (breadcrumb has no controller — only the `.rb` is generated.)

- [ ] **Step 3: Preview class** — create `spec/components/previews/ui/breadcrumb_component_preview.rb`:

```ruby
# frozen_string_literal: true

module UI
  # # Breadcrumb
  #
  # A breadcrumb trail. The last item is the current page (aria-current=page, not a link).
  class BreadcrumbComponentPreview < ViewComponent::Preview
    include UIHelper

    # Home / Library / Data (Data = current page).
    def basic
    end
  end
end
```

- [ ] **Step 4: basic.html.erb** — create `spec/components/previews/ui/breadcrumb_component_preview/basic.html.erb`:

```erb
<div class="min-h-96 p-12">
  <%= render(UI::BreadcrumbComponent.new(items: [
    { label: "Home", href: "#" },
    { label: "Library", href: "#" },
    { label: "Data" }
  ])) %>
</div>
```

- [ ] **Step 5: Verify ERB + commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- ruby -e 'require "erb"; ERB.new(File.read("spec/components/previews/ui/breadcrumb_component_preview/basic.html.erb")).src; puts "basic: syntax OK"'
git add app/components/ui/breadcrumb_component.rb spec/components/previews/ui/breadcrumb_component_preview.rb spec/components/previews/ui/breadcrumb_component_preview/ Gemfile Gemfile.lock
git commit -m "feat(ui): vendor hardened breadcrumb + preview"
```

---

## Task 5: App — breadcrumb 0b

**Files:** Create `spec/system/ui/breadcrumb_component_spec.rb`.

- [ ] **Step 1: Write the system spec**

```ruby
# frozen_string_literal: true

require "rails_helper"

# Preview-host accessibility proof for the breadcrumb component. Static nav (no JS); we assert
# the landmark + aria-current + axe-AAA in both themes. NOTE: per-spec axe runs AA locally; the
# AAA 7:1 audit is the CI-only wcag2aaa hook.
RSpec.describe "Breadcrumb component accessibility", type: :system do
  before { visit "/rails/view_components/ui/breadcrumb_component/basic" }

  it "renders a breadcrumb landmark that passes AAA in both themes" do
    expect(page).to have_css("nav[aria-label='Breadcrumb'] ol")
    expect(page).to have_css("[aria-current='page']", text: "Data")
    expect(page).to have_link("Home")
    expect(page).to have_link("Library")
    expect(page).not_to have_link("Data") # current page is not a link

    scope = [ "nav[aria-label='Breadcrumb']" ]
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true),
      axe_violations_in_both_themes(include: scope).join("\n")
    )
  end
end
```

- [ ] **Step 2: Run (must PASS locally, AA)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/breadcrumb_component_spec.rb
```
Expected: 1 example, 0 failures. (IF axe fails on `text-text-muted` — note it resolves to the SAME neutral as `text-text-body` here, AAA; do NOT add a color-contrast exclude. Report DONE_WITH_CONCERNS if a genuine contrast question, human adjudicates via CI.)

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/system/ui/breadcrumb_component_spec.rb
git commit -m "test(ui): 0b breadcrumb (landmark + aria-current + AAA both themes)"
```

---

## Task 6: App — style Pagy's series_nav with design-system tokens

**Files:** Modify `app/assets/tailwind/application.css` (add a `@layer components` block).

- [ ] **Step 1: Inspect Pagy 43's actual `series_nav` output (so the selectors are correct)**

The exact class names / disabled-state markup must be verified, not assumed. Render it:
```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails runner '
  include Pagy::Method rescue nil
  pagy = Pagy::Offset.new(count: 95, page: 3, limit: 20, request: {path: "/items", params: {}, base_url: "http://x"})
  # render via an ActionView context so the frontend helper is available
  view = ApplicationController.new.view_context
  puts view.instance_exec(pagy) { |p| p.series_nav(aria_label: "Pages") } rescue puts("render needs different ctx: #{$!.message}")
' 2>&1 | head -20
```
Note the real markup: the nav class (`pagy series-nav`), each `<a>`, the current page (`a[aria-current="page"]` — a non-href anchor), the gap element (class/text), and the prev/next disabled state (at page 1 / last page — `a[aria-disabled]` or omitted). If `bin/rails runner` can't render the frontend helper, inspect the rendered HTML from the Task-7 system spec instead (visit the notifications page, read the pagination HTML) and return here to finalize selectors.

- [ ] **Step 2: Add the design-system CSS**

In `app/assets/tailwind/application.css`, add a `@layer components` block (place it near other component styles). Adjust the selectors to match the REAL markup from Step 1 (the block below assumes the documented `nav.pagy.series-nav > a` shape; the gap + disabled selectors may need tweaking):

```css
@layer components {
  /* Pagy series_nav, styled to the design system (AAA both themes). Pagy renders
     <nav class="pagy series-nav"> with <a> children; the current page is a[aria-current=page]. */
  .pagy.series-nav {
    @apply flex items-center gap-1;
  }
  .pagy.series-nav a {
    @apply inline-flex h-9 min-w-9 items-center justify-center rounded-md px-3 text-sm font-medium text-text-body outline-none transition-colors hover:bg-surface-sunken hover:text-text-heading focus-visible:ring-1 focus-visible:ring-interactive-focus;
  }
  .pagy.series-nav a[aria-current="page"] {
    @apply bg-interactive text-text-on-interactive hover:bg-interactive hover:text-text-on-interactive;
  }
  .pagy.series-nav a[aria-disabled="true"] {
    @apply pointer-events-none opacity-50;
  }
  .pagy.series-nav .gap {
    @apply px-1 text-text-muted;
  }
}
```

- [ ] **Step 3: Verify the CSS compiles + the utilities resolve (no phantom tokens)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails tailwindcss:build 2>&1 | tail -5
# positive control: the styled rule made it into the compiled CSS
grep -o "series-nav" app/assets/builds/tailwind.css | head -1 && echo "series-nav styled rule present"
```
Expected: build succeeds (no "Cannot apply unknown utility" errors — if `@apply bg-interactive`/`text-text-on-interactive`/`ring-interactive-focus` errors, the token isn't an `@apply`-able utility; switch that declaration to the raw token via `@apply bg-[--color-interactive]` or a `color: var(--color-...)` rule, and note it). The `series-nav` rule appears in the compiled output.

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add app/assets/tailwind/application.css
git commit -m "feat(ui): style Pagy series_nav to the design-system tokens (AAA both themes)"
```

---

## Task 7: App — pagination AAA proof (real notifications view)

**Files:** Create `spec/system/ui/pagination_a11y_spec.rb`.

> Pagy's `series_nav` needs a live Pagy + view context, so we prove it on a REAL paginated page
> (notifications, 25/page). Mirror the sign-in + seeding patterns from
> `spec/system/notifications_a11y_spec.rb` (sign-in helper) and
> `spec/requests/account/notifications_spec.rb` (the 30-notification seeding via `Noticed::Notification.create!`).

- [ ] **Step 1: Read the existing patterns**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
sed -n '1,40p' spec/system/notifications_a11y_spec.rb         # sign_in_via_form + visit + axe shape
sed -n '100,118p' spec/requests/account/notifications_spec.rb # the 30-notification seed
```

- [ ] **Step 2: Write the system spec**

Create `spec/system/ui/pagination_a11y_spec.rb` (adapt the user-factory + sign-in helper + seeding to MATCH what those two files use — the factory name, the `sign_in_via_form` helper, and the `Noticed::Event`/`Noticed::Notification.create!` seed):

```ruby
# frozen_string_literal: true

require "rails_helper"

# AAA proof for PAGINATION. The app paginates with Pagy's `@pagy.series_nav` (accessible markup),
# styled to the design system via app/assets/tailwind/application.css (.pagy.series-nav). Pagy's
# helper needs a live view context, so we prove it on the real notifications page (25/page) with
# 30 notifications → pagination renders. NOTE: per-spec axe runs AA locally; AAA 7:1 is CI-only.
RSpec.describe "Pagination accessibility (Pagy series_nav)", type: :system do
  # Use the SAME user factory + sign-in helper the existing notifications system spec uses.
  let(:user) { create(:user) } # adjust factory/traits to match notifications_a11y_spec.rb

  before do
    # Seed > 25 notifications so Pagy renders the nav (mirror notifications_spec.rb).
    event = Noticed::Event.create!(type: "PasswordChangedNotifier", params: {}, record: user)
    Array.new(30) do
      Noticed::Notification.create!(event: event, recipient: user, type: "PasswordChangedNotifier::Notification")
    end
    sign_in_via_form(user)
    visit account_notifications_path
  end

  it "renders the Pagy series_nav and it passes AAA in both themes" do
    expect(page).to have_css("nav.pagy.series-nav, nav.pagy", wait: 5) # Pagy's nav
    expect(page).to have_css("[aria-current='page']")                  # current page marked

    scope = [ "nav.pagy" ]
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true),
      axe_violations_in_both_themes(include: scope).join("\n")
    )
  end
end
```

- [ ] **Step 3: Run (must PASS locally, AA)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rspec spec/system/ui/pagination_a11y_spec.rb
```
Expected: 1 example, 0 failures. If the spec can't sign in / seed (factory or helper name mismatch), READ `spec/system/notifications_a11y_spec.rb` + the notifications request spec again and align the factory/helper/seed exactly — do NOT stub the pagination. If the pagination doesn't appear, confirm 30 notifications seeded for THIS user + the page paginates at 25 (so page 1 has a next link). If ONLY the axe assertion fails, that's the styling: report `axe_violations_in_both_themes`; the likely culprit is a dark-mode contrast on a series_nav element — fix the CSS in Task 6 (do NOT add a color-contrast exclude), re-run. If you cannot get the view to paginate after a genuine attempt, report BLOCKED with what you tried.

- [ ] **Step 4: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add spec/system/ui/pagination_a11y_spec.rb
git commit -m "test(ui): AAA proof for Pagy series_nav pagination (styled, both themes)"
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
mise exec -- bundle exec rubocop app/components/ui/breadcrumb_component.rb spec/components/previews/ui/breadcrumb_component_preview.rb spec/system/ui/breadcrumb_component_spec.rb spec/system/ui/pagination_a11y_spec.rb
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

Report: arc 3 complete (navigation band done). **Gem** (`harden/breadcrumb-pagination`): hardened breadcrumb + 0a render test + structural-test update + breadcrumb doc + **pagination→series_nav doc** + ledger (breadcrumb hardened; pagination proven via Pagy). **App** (`feat/ui-breadcrumb-pagination`): vendored breadcrumb + preview + 0b; **Pagy series_nav design-system CSS** + the pagination AAA system spec. Full suite green. Browser review: `/rails/view_components/ui/breadcrumb_component/basic` + a paginated page (e.g. `/account/notifications` with >25) for the styled series_nav, both themes; `/lookbook`. On OK: push gem branch + PR into `modelrails/harden` → careful-merge (REST `-f sha=`) → re-pin app `Gemfile` to `modelrails/harden` + drop local override → push app branch + PR → after app AAA CI green + merge, flip the gem ledger `breadcrumb` → proven (pagination already marked proven via series_nav).

---

## Self-Review

**1. Spec coverage** (design §4 revised → tasks):
- breadcrumb: i18n `<nav>` label + ol/li + aria-current + aria-hidden separators + focus-visible links → Task 2 component; render-asserted Task 1; behavior+AAA Task 5. ✅
- pagination leans on Pagy `series_nav` (not a custom component) → Task 3 doc/ledger; styled Task 6; AAA-proven Task 7. ✅
- DoD: breadcrumb 0a (Task 1) + 0b (Task 5) + doc (Task 3) + preview (Task 4); pagination styling (Task 6) + AAA proof (Task 7) + doc/ledger (Task 3); full suite (Task 8). ✅

**2. Placeholder scan:** No TBD/TODO. Two known integration points (NOT placeholders): Task 6 Step 1 (verify Pagy's REAL series_nav markup before finalizing CSS selectors — markup can't be known without rendering) and Task 7 Step 2 (align the factory/sign-in/seed to the existing notifications specs — app-specific). Both give the concrete approach + the file to read; this is the documented "read the existing pattern" contingency, as in prior arcs.

**3. Type/name consistency:** breadcrumb `label:`/`items:`/`separator:` params + `nav_label` render-time `t()`; the `.pagy.series-nav` CSS selectors ↔ Pagy's documented output (verified in Task 6 Step 1); the pagination spec targets `nav.pagy` ↔ Pagy's nav class.

**Flagged for browser/CI review:** the Pagy series_nav styling contrast (the `bg-interactive` active pill + `text-text-body` links + `text-text-muted` gap) in BOTH themes — adjudicated by the app CI `test` job (the Task-7 system spec runs axe; CI runs it at AAA 7:1). The `@apply` of design-system tokens in a `@layer components` block is the one novel risk (Task 6 Step 3 positive-controls the compile).
