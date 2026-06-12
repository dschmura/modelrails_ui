# Wave 5b Tooltip + Hover Card — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Harden `tooltip` and `hover_card` to the DoD as the hover/focus half of the floating band — fixing their hover-only (keyboard-invisible) defect, wiring `aria-describedby` (tooltip), and adding Escape-dismiss (WCAG 1.4.13) by extending the shared `floating` controller. Both reuse `floating` via `EXTRA_STIMULUS`.

**Architecture:** CSS owns show/hide (`group-hover` **and** `group-focus-within` — the fix), so they degrade gracefully with no JS. The `floating` controller (from Wave 5a) gains `dismiss`/`clearDismissed`: Escape sets `data-dismissed` (CSS force-hides via an `!important` override that beats the hover/focus rules); `mouseleave`/`focusout` clear it so the next hover/focus re-shows. See `2026-06-06-wave5-floating-overlays-design.md`. Per the updated DoD item 10, both get a `@param` playground.

**Tech Stack:** Ruby 4.0.5 (gem), ViewComponent, Stimulus, Minitest (0a), RSpec+Capybara+Playwright+axe (app 0b), TailwindCSS v4.

**Toolchain:** Gem — `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake` (NOT `mise exec`). App — `cd …/modelrails_base && mise exec -- bundle exec rspec …`.

**Branches:** Gem `harden/wave5b-tooltip-hovercard` (off `modelrails/harden`, already created). App `feat/ui-tooltip-hovercard`.

**Exemplar to mirror (read first):** Wave 5a popover — `popover_component.rb.tt`, `popover_render_test.rb`, `popover_component_preview.rb` (+ playground), app `spec/system/ui/popover_component_spec.rb`. The 0a/preview/0b artifact *shapes* are identical; only the component bodies differ.

---

## File Structure

**Gem** (`harden/wave5b-tooltip-hovercard`):

| File | Change |
|---|---|
| `…/popover/floating_controller.js` | Add `dismiss` + `clearDismissed`. Do FIRST. |
| `…/tooltip/tooltip_component.rb.tt` | Rewrite (focus-within + describedby + dismiss). |
| `…/hover_card/hover_card_component.rb.tt` | Rewrite (focus-within + interactive content + dismiss). |
| `…/components.rb` | Add `tooltip` + `hover_card` `EXTRA_STIMULUS` entries → `floating`. |
| `test/render/{tooltip,hover_card}_render_test.rb` | New 0a render tests. |
| `…/previews/ui/{tooltip,hover_card}_component_preview.rb` (+ scenarios) | New previews **with `@param` playground**. |
| `COMPONENT_STATUS.md` + `docs/components/{tooltip,hover_card}.md` | Rows + doc refresh. |

**App** (`feat/ui-tooltip-hovercard`): pin to the gem branch; vendor both (+ re-vendor `floating_controller.js`); 0b specs for each.

**Orchestration:** Task 1 (controller) first. Gem tasks → one gem PR into `modelrails/harden`; app → one app PR. Land sequence (Task 9) re-pins app to `modelrails/harden` after the gem PR merges.

---

### Task 1: Extend the `floating` controller (do FIRST)

**Files:** Modify `lib/generators/modelrails_ui/add/templates/popover/floating_controller.js`

- [ ] **Step 1:** Add two methods (after `closeOnClickOutside`), leaving the popover methods untouched:

```js
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
```

(No target access — these operate on `this.element` — so they're safe for tooltip/hover_card, which have no `trigger`/`panel` targets.)

- [ ] **Step 2: Commit.**

```bash
git -C /Users/dschmura/Documents/code/modelrails_ui add lib/generators/modelrails_ui/add/templates/popover/floating_controller.js
git -C /Users/dschmura/Documents/code/modelrails_ui commit -m "feat(floating): add dismiss/clearDismissed for hover-focus overlays (1.4.13)"
```

---

### Task 2: Wire `EXTRA_STIMULUS`

**Files:** Modify `lib/generators/modelrails_ui/components.rb`

- [ ] **Step 1:** Add two entries to the `EXTRA_STIMULUS` hash (alongside the dialog-family rows):

```ruby
        "tooltip" => {source: "popover/floating_controller.js", name: "floating"},
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"}
```

- [ ] **Step 2: Commit.**

```bash
git -C /Users/dschmura/Documents/code/modelrails_ui add lib/generators/modelrails_ui/components.rb
git -C /Users/dschmura/Documents/code/modelrails_ui commit -m "feat(floating): share floating controller with tooltip + hover_card via EXTRA_STIMULUS"
```

---

### Task 3: Harden `tooltip` (0a TDD)

**Files:** Create `test/render/tooltip_render_test.rb`; Modify `…/tooltip/tooltip_component.rb.tt`

- [ ] **Step 1: Write the failing render test.**

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "tooltip", "tooltip_component.rb.tt"

class TooltipRenderTest < ViewComponent::TestCase
  def render_tooltip(**opts)
    render_inline(UI::TooltipComponent.new(**{ text: "Saved" }.merge(opts))) { "Status" }
  end

  def test_wrapper_is_focusable_and_describes_the_bubble
    render_tooltip(id: "t1")

    assert_selector "span.group[tabindex='0'][aria-describedby='t1'][data-controller='floating']", visible: :all
    assert_selector "span[data-action~='keydown.esc->floating#dismiss']", visible: :all
    assert_selector "span[data-action~='mouseleave->floating#clearDismissed']", visible: :all
    assert_selector "span[data-action~='focusout->floating#clearDismissed']", visible: :all
  end

  def test_bubble_is_a_tooltip_role_with_the_referenced_id
    render_tooltip(id: "t2", text: "Copied to clipboard")

    assert_selector "span#t2[role='tooltip']", text: "Copied to clipboard", visible: :all
  end

  def test_bubble_shows_on_hover_and_focus_and_force_hides_when_dismissed
    render_tooltip

    assert_selector "[role='tooltip'].group-hover\\:opacity-100", visible: :all
    assert_selector "[role='tooltip'].group-focus-within\\:opacity-100", visible: :all
    assert_selector "[role='tooltip'].group-data-\\[dismissed\\]\\:opacity-0\\!", visible: :all
  end

  def test_fail_loud_on_unknown_side
    error = assert_raises(ArgumentError) { UI::TooltipComponent.new(text: "x", side: :sideways) }
    assert_match(/unknown side/, error.message)
  end
end
```

- [ ] **Step 2: Run; verify FAIL.** `cd /Users/dschmura/Documents/code/modelrails_ui && PATH="…4.0.5/bin:$PATH" bundle exec ruby -Itest test/render/tooltip_render_test.rb` → FAIL (current tooltip is hover-only, no focus-within/describedby/dismiss).

- [ ] **Step 3: Rewrite the component** with EXACTLY:

```ruby
# frozen_string_literal: true

module UI
  # # Tooltip
  #
  # A small text bubble describing the element it wraps. Shows on hover **and**
  # keyboard focus; the wrapper is focusable and `aria-describedby` wires the bubble
  # to it. Escape dismisses (WCAG 1.4.13) via the shared `floating` controller.
  #
  # ## Use when
  # - You need a short, non-interactive hint describing a single focusable trigger
  #   (an icon button, a truncated label).
  #
  # ## Don't use when
  # - The content is interactive or rich — use `hover_card`.
  # - You wrap an already-interactive control — put `aria-describedby` on that control
  #   instead (this component makes its own wrapper the focusable trigger).
  #
  # ## Accessibility contract
  # - **Guarantees:** shows on hover AND focus; `role="tooltip"` bubble wired via
  #   `aria-describedby`; Escape dismisses without moving focus; `pointer-events-none`
  #   so the bubble never traps the pointer.
  # - **You supply:** `text:` (the hint) and the trigger content (icon/word).
  class TooltipComponent < ApplicationComponent
    BUBBLE_BASE = "absolute z-50 w-max max-w-xs rounded-md px-3 py-1.5 text-xs text-balance " \
                  "bg-text-heading text-surface-raised whitespace-normal " \
                  "pointer-events-none opacity-0 transition-opacity duration-200 " \
                  "group-hover:opacity-100 group-focus-within:opacity-100 " \
                  "group-data-[dismissed]:opacity-0!"

    POSITIONS = {
      top:    "bottom-full left-1/2 -translate-x-1/2 mb-2",
      bottom: "top-full left-1/2 -translate-x-1/2 mt-2",
      left:   "right-full top-1/2 -translate-y-1/2 mr-2",
      right:  "left-full top-1/2 -translate-y-1/2 ml-2"
    }.freeze

    # text: the hint (the bubble's content); id: bubble id (→ aria-describedby);
    # side: :top | :bottom | :left | :right
    def initialize(text:, id: nil, side: :top, **html_attrs)
      @text        = text
      @id          = id || "tooltip-#{SecureRandom.hex(4)}"
      @side        = coerce_enum(:side, side, POSITIONS)
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:span, **wrapper_attrs) do
        safe_join([content, bubble])
      end
    end

    private

    def wrapper_attrs
      {
        class: cn("group relative inline-flex", @extra_class),
        tabindex: "0",
        "aria-describedby": @id,
        data: {
          controller: "floating",
          action: "keydown.esc->floating#dismiss mouseleave->floating#clearDismissed focusout->floating#clearDismissed"
        }
      }.merge(@html_attrs)
    end

    def bubble
      content_tag(:span, @text, id: @id, role: "tooltip", class: cn(BUBBLE_BASE, POSITIONS.fetch(@side)))
    end

    def coerce_enum(name, value, map)
      key = value.to_sym
      return key if map.key?(key)

      raise ArgumentError, "UI::Tooltip unknown #{name}: #{value.inspect} (allowed: #{map.keys.join(", ")})"
    end
  end
end
```

- [ ] **Step 4: Run render test (PASS) + full `rake` (green incl. rubocop).** Fix rubocop style only if flagged.

- [ ] **Step 5: Verify the `!important` class actually compiles** (the precedence risk). Probe the *built* CSS in the app later (Task 8); in the gem, just assert the class string renders (Step 1 test).

- [ ] **Step 6: Commit.**

```bash
git -C /Users/dschmura/Documents/code/modelrails_ui add test/render/tooltip_render_test.rb lib/generators/modelrails_ui/add/templates/tooltip/tooltip_component.rb.tt
git -C /Users/dschmura/Documents/code/modelrails_ui commit -m "feat(tooltip): show on focus + aria-describedby + Escape-dismiss (0a)"
```

---

### Task 4: Harden `hover_card` (0a TDD)

**Files:** Create `test/render/hover_card_render_test.rb`; Modify `…/hover_card/hover_card_component.rb.tt`

- [ ] **Step 1: Write the failing render test** (mirror Task 3; key assertions): wrapper `span.group[data-controller='floating']` with the three dismiss actions; **required `with_trigger` slot** (raises `ArgumentError` if absent); card `div` carrying `group-hover:visible` / `group-focus-within:visible` / `group-data-[dismissed]:invisible!`; `role="group"` + `aria-label` ONLY when `label:` given; fail-loud `side`.

```ruby
# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "hover_card", "hover_card_component.rb.tt"

class HoverCardRenderTest < ViewComponent::TestCase
  def render_card(**opts)
    render_inline(UI::HoverCardComponent.new(**opts)) do |c|
      c.with_trigger { "@dave" }
      "Profile details"
    end
  end

  def test_wrapper_wires_floating_and_dismissal
    render_card

    assert_selector "span.group[data-controller='floating']" \
                    "[data-action~='keydown.esc->floating#dismiss']" \
                    "[data-action~='mouseleave->floating#clearDismissed']" \
                    "[data-action~='focusout->floating#clearDismissed']", visible: :all
  end

  def test_card_shows_on_hover_and_focus_within_and_hides_when_dismissed
    render_card

    assert_selector "div.group-hover\\:visible.group-focus-within\\:visible", visible: :all
    assert_selector "div.group-data-\\[dismissed\\]\\:invisible\\!", visible: :all
  end

  def test_label_sets_role_group_and_aria_label
    render_card(label: "User card")

    assert_selector "div[role='group'][aria-label='User card']", visible: :all
  end

  def test_omits_role_without_a_label
    render_card

    assert_no_selector "div[role='group']", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) { render_inline(UI::HoverCardComponent.new) }
    assert_match(/with_trigger/, error.message)
  end

  def test_fail_loud_on_unknown_side
    assert_raises(ArgumentError) { UI::HoverCardComponent.new(side: :diagonal) }
  end
end
```

- [ ] **Step 2: Run; verify FAIL.**

- [ ] **Step 3: Rewrite the component** with EXACTLY:

```ruby
# frozen_string_literal: true

module UI
  # # Hover Card
  #
  # A rich, supplemental card revealed on hover **and** keyboard focus of its trigger.
  # Unlike `tooltip`, the card may hold interactive content; `focus-within` keeps it
  # open while the user Tabs through that content. Escape dismisses (WCAG 1.4.13).
  #
  # ## Use when
  # - A link/avatar benefits from a supplemental preview (profile, definition) whose
  #   content is ALSO reachable elsewhere (the card is an enhancement, not the only path).
  #
  # ## Don't use when
  # - The content is a primary interactive surface — use `popover` (click) or a `dialog`.
  # - It's a short text hint — use `tooltip`.
  #
  # ## Accessibility contract
  # - **Guarantees:** shows on hover AND focus-within (card content is Tab-reachable while
  #   open); Escape dismisses; `role="group"` + `aria-label` when `label:` is given.
  # - **You supply:** a `with_trigger` slot (a focusable link/button) and the card content.
  class HoverCardComponent < ApplicationComponent
    renders_one :trigger

    CARD_BASE = "absolute z-50 w-64 rounded-lg border border-border bg-surface-overlay p-4 text-sm " \
                "text-text-body shadow-md " \
                "invisible opacity-0 transition-opacity duration-200 " \
                "group-hover:visible group-hover:opacity-100 " \
                "group-focus-within:visible group-focus-within:opacity-100 " \
                "group-data-[dismissed]:invisible! group-data-[dismissed]:opacity-0!"

    POSITIONS = {
      bottom: "top-full left-0 mt-2",
      top:    "bottom-full left-0 mb-2",
      left:   "right-full top-0 mr-2",
      right:  "left-full top-0 ml-2"
    }.freeze

    # id: card id; label: optional accessible name (→ role=group + aria-label);
    # side: :bottom | :top | :left | :right
    def initialize(id: nil, label: nil, side: :bottom, **html_attrs)
      @id          = id || "hovercard-#{SecureRandom.hex(4)}"
      @label       = label
      @side        = coerce_enum(:side, side, POSITIONS)
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      raise ArgumentError, "UI::HoverCardComponent requires a with_trigger slot" unless trigger?

      content_tag(:span, **wrapper_attrs) do
        safe_join([trigger, card])
      end
    end

    private

    def wrapper_attrs
      {
        class: cn("group relative inline-block", @extra_class),
        data: {
          controller: "floating",
          action: "keydown.esc->floating#dismiss mouseleave->floating#clearDismissed focusout->floating#clearDismissed"
        }
      }.merge(@html_attrs)
    end

    def card
      attrs = { id: @id, class: cn(CARD_BASE, POSITIONS.fetch(@side)) }
      if @label
        attrs[:role] = "group"
        attrs["aria-label"] = @label
      end
      content_tag(:div, content, **attrs)
    end

    def coerce_enum(name, value, map)
      key = value.to_sym
      return key if map.key?(key)

      raise ArgumentError, "UI::HoverCard unknown #{name}: #{value.inspect} (allowed: #{map.keys.join(", ")})"
    end
  end
end
```

- [ ] **Step 4: Run render test (PASS) + full `rake`.**
- [ ] **Step 5: Commit** `feat(hover_card): show on focus-within + Escape-dismiss + optional label (0a)`.

---

### Task 5: Previews (static + `@param` playground)

**Files:** Create `…/previews/ui/tooltip_component_preview.rb` (+ `tooltip_component_preview/basic.html.erb`); `…/previews/ui/hover_card_component_preview.rb` (+ `hover_card_component_preview/basic.html.erb`).

Mirror popover's preview. Each: a `basic` static scenario (stable 0b target) + a `playground` with `@param side select [...]` (+ `@param text` for tooltip; `@param label text` for hover_card). Example tooltip playground:

```ruby
    # @param text text
    # @param side select [top, bottom, left, right]
    def playground(text: "Saved to your library", side: :top)
      ui(:tooltip, text: text, side: side.to_sym) { "Hover or focus me" }
    end
```

Hover_card playground uses the block-with-slot form (`ui(:hover_card, side: side.to_sym) { |c| c.with_trigger { "@dave" }; "Profile…" }`). Commit `feat(tooltip,hover_card): template-backed previews + @param playgrounds`.

---

### Task 6: Ledger rows + docs

Add two `COMPONENT_STATUS.md` rows (`hardened`, `✅ ⏳`); refresh `docs/components/tooltip.md` + `docs/components/hover_card.md` to the hardened contracts (accurate to source — no fabrication). Commit `docs(tooltip,hover_card): hardened rows + refreshed docs`.

---

### Task 7: Gem PR

`rake` green → push `harden/wave5b-tooltip-hovercard` → `gh pr create --base modelrails/harden` (title: `feat(floating): harden tooltip + hover_card to button-tier (Wave 5b)`; body notes AAA proven by the companion app 0b).

---

### Task 8: App adoption + 0b specs (the precedence proof)

**Files:** `Gemfile` (pin to the gem branch), vendor both components + re-vendor `floating_controller.js` + previews; Create `spec/system/ui/{tooltip,hover_card}_component_spec.rb`.

- [ ] Pin app `modelrails_ui` to `branch: "harden/wave5b-tooltip-hovercard"`; `bundle update modelrails_ui`.
- [ ] **Write the 0b specs (the key proofs):**
  - **tooltip:** focusing the wrapper shows the bubble (`group-focus-within`); `aria-describedby` resolves to a `role="tooltip"`; **Escape hides the bubble while focus stays** (the `!important` precedence proof); moving focus away clears `data-dismissed`. AAA on the bubble in both themes (incl. the inverted `bg-text-heading`).
  - **hover_card:** focusing the trigger reveals the card; a link inside is Tab-reachable; Escape dismisses; AAA in both themes.

  Tooltip 0b skeleton:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tooltip component accessibility", type: :system do
  it "shows on focus, is described, dismisses on Escape, passes AAA" do
    visit "/rails/view_components/ui/tooltip_component/basic"

    trigger = find("[data-controller='floating'][tabindex='0']")
    desc_id = trigger[:"aria-describedby"]
    expect(page).to have_css("##{desc_id}[role='tooltip']", visible: :all)

    trigger.send_keys("") # focus the wrapper
    expect(page).to have_css("[role='tooltip']") # visible on focus

    scope = [ "[role='tooltip']" ]
    expect(axe_clean_in_both_themes?(include: scope)).to be(true), axe_violations_in_both_themes(include: scope).join("\n")

    page.send_keys(:escape)
    # data-dismissed set; the !important rule must force-hide despite focus-within
    expect(page).to have_css("[data-controller='floating'][data-dismissed]", visible: :all)
  end
end
```

  (If `send_keys("")` doesn't focus reliably, use `trigger.click` then assert, or `page.driver.with_playwright_page { |pw| pw.keyboard.press("Tab") }`. The executor verifies in-browser — this is the precedence-proof task.)

- [ ] Run each 0b with `-r rails_helper` (PASS), then full suite (0 failures).
- [ ] Commit `feat(ui): adopt hardened tooltip + hover_card + 0b proof (Wave 5b)`; push (Lefthook CI); open app PR.

---

### Task 9: Land sequence

Same as Wave 5a: both PRs green → merge gem PR → re-pin app to `modelrails/harden` + `bundle update` + suite + push → merge app PR. Then flip the two ledger rows to `proven`.

---

## Self-Review

- **Spec coverage:** §1 controller `dismiss` (T1); §3 tooltip focus+describedby+dismiss (T3/T8); §4 hover_card focus-within+interactive+dismiss (T4/T8); §5 artifacts (T3–T6); playgrounds per DoD item 10 (T5). ✅
- **The `!important` precedence is the one real risk** — render tests assert the class string exists, but only the app 0b proves it actually wins over `group-hover`/`group-focus-within` in the built CSS. T8 is explicitly the precedence proof; if it fails, the fallback is restructuring (e.g., `data-[dismissed]` on the bubble itself, or a `hidden` toggle in `dismiss`). Do NOT claim dismissal works from the render test alone.
- **Type consistency:** `floating` targets/methods (`dismiss`/`clearDismissed`), `data-floating-target` unused by these two (CSS-driven), `coerce_enum`, `group-data-[dismissed]` — consistent across controller, components, tests. ✅
- **No fabrication:** keep tooltip's inverted `bg-text-heading`/`text-surface-raised` (the design references it); let CI adjudicate AAA — don't pre-"fix" it.
