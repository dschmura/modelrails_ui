# Testing

`rake test` runs three lanes, in increasing cost and decreasing breadth. Each proves
something the others structurally cannot, so a component is only fully covered when the
right assertion sits in the right lane.

| Lane | Task | Boots | Proves |
|---|---|---|---|
| Structural | `test:structural` | nothing | the `.rb.tt` templates as text — registries, catalog completeness, conventions |
| Render | `test:render` | Rails + ViewComponent | real HTML and ARIA from a rendered component |
| Browser | `test:system` | Chrome over CDP | what happens once JavaScript runs |

## What each lane cannot prove

This is the part worth knowing **before** you write an assertion, because a test placed in
the wrong lane either fails confusingly or — worse — passes for the wrong reason.

### The render lane cannot see behaviour

It renders markup and stops. Anything a Stimulus controller does at runtime is invisible
to it: open/close, roving focus, `aria-expanded` kept in sync, ids minted by a controller,
`aria-activedescendant` actually resolving to an element, a DOM node removed on failure.

Every bug found in the 2026-08 overlay audit was of exactly this kind, which is why the
browser lane exists.

### The browser lane cannot see anything that needs compiled CSS

The harness serves the components and their JavaScript, **but no stylesheet**. The gem
ships CSS as Tailwind source, which needs a build step the harness does not run. Nothing
whose behaviour is decided by a stylesheet can be proven here. Three cases have come up
so far; treat them as examples of the rule, not as the whole list:

**1. Colour contrast.** `assert_axe_clean` disables the `color-contrast` rule. Against
unstyled defaults axe would report on the browser's own colours, so a green result would
mean nothing. Re-enabling it without first building the stylesheet produces a test that
looks strict and asserts nothing.

**2. Top-layer promotion.** `top_layer.js` promotes a panel only when it already computes
to `position: fixed` — the invariant that keeps an `absolute`-placed panel from being torn
off its trigger. With no stylesheet nothing computes to `fixed`, so the guard correctly
declines to promote, and `:popover-open` is never true here.

That is the guard working, not a harness bug. Do **not** inject a style to make it fire:
the assertion would then prove the injected style rather than the component.

**3. Escaping a clip.** The sidebar's collapsed-rail hint is `fixed` + anchor-positioned
precisely so it escapes the nav's `overflow-y-auto` clip. Unstyled it computes to
`static` and never moves, so its geometry here would prove nothing.

Note also that geometry alone is the wrong assertion for a clip even where CSS *is*
available: `getBoundingClientRect` reports the unclipped box either way, so such a test
passes just as happily on the broken version. Assert the computed `position` — the
mechanism that does the escaping.

All three are proven in **`modelrails_base`**, which generates the components into a real
app with compiled Tailwind. If an assertion would read a computed style — a colour, a
position, a stacking context, a size — it belongs in that repo's `spec/system/ui/`.

## Writing a browser test

```ruby
require "system_test_helper"
load_component "popover", "popover_component.rb.tt"

BrowserHarness.scenario("popover/basic",
  controllers: %w[floating],            # Stimulus identifiers to register
  modules: %w[overlays/top_layer]) do   # shared ES modules the controllers import
  view = ActionController::Base.new.view_context
  UI::PopoverComponent.new(label: "Account menu").render_in(view) { |c| c.with_trigger { "Open" } }
end

class PopoverSystemTest < BrowserTestCase
  def test_the_trigger_opens_it
    visit_scenario("popover/basic")
    find("[data-floating-target=trigger]").click

    assert_selector "[data-floating-target=panel]"
  end
end
```

The page is served with a **real importmap** wiring the gem's own controller templates and
shared modules. A controller importing a bare specifier that nothing pins fails here the
same way it would in a fork — which is the point.

### Helpers

- `visit_scenario(name)` — loads the page and waits for Stimulus to boot. Without the wait
  an action can be dispatched before the controller connects, and the test fails for the
  wrong reason.
- `press(:Escape)` — real key input. **Do not use Capybara's `send_keys`**: it resolves an
  element and *clicks it* to take focus, which on a menu activates an item and closes it
  before the key is ever sent. A spec written that way passes regardless of the handler.
- `assert_axe_clean(within: "body")` — structural audit, contrast excluded (above).
- `assert_no_stimulus_errors` — Stimulus catches errors thrown in lifecycle callbacks and
  routes them to `application.handleError` rather than `window.onerror`, so a controller
  that throws in `connect()` leaves the page looking fine and simply stops working. Assert
  this anywhere a controller's connect path matters.

## Non-vacuity

An assertion that cannot fail is worse than no assertion, because it reads as coverage.
Two habits the suite relies on:

- **Give every positive a control.** Horizontal tabs ignore ↑/↓ *and* vertical ignore ←/→;
  one checkbox is indeterminate *and* a sibling is not. Either alone can pass by reading a
  default.
- **Assert the fixture's shape first.** A "all ids are unique" check over a
  single-instance page is trivially true. `test_renders_two_instances` runs before the
  uniqueness assertion for exactly this reason.

When adding a guard for a bug, confirm it fails against the unfixed code before trusting
it.
