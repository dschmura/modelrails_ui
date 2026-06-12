# Wave 5 Floating Overlays — Design (popover / tooltip / hover_card)

**Status:** Approved design. The task-by-task implementation plan is produced
separately by `superpowers:writing-plans` (`…-plan.md`).

**Goal:** Harden `popover`, `tooltip`, and `hover_card` to the 10-point DoD as
the **floating-overlays** band of the component hardening program (see
`2026-06-03-component-hardening-program-design.md`). These are anchored,
trigger-attached overlays — distinct from the dialog band's modal `<dialog>`
overlays. All three currently exist but fail keyboard/focus/ARIA basics.

## Why this band is not "formalize-only"

The three components ship real accessibility defects today:

| Component | Defect today |
|---|---|
| `popover` | trigger is a non-focusable `<span>` (no Enter/Space); no `aria-expanded`/`haspopup`/`controls`; no Escape; no focus management; panel has no role |
| `tooltip` | `group-hover` **only** — invisible to keyboard focus; not dismissible (WCAG 2.2 1.4.13); `role="tooltip"` present but no `aria-describedby` wiring |
| `hover_card` | hover-only, no focus path; no role/ARIA; interactive card content is keyboard-unreachable |

## Architecture

**Decision: CSS in-flow positioning + one shared `floating` Stimulus
controller for behavior.** Positioning stays as today (a `relative` wrapper +
`absolute` panel, author picks `side`/`align`); the controller supplies the
behavior CSS structurally cannot.

### Alternatives considered and rejected

- **Native Popover API + CSS anchor positioning.** Most native (the literal
  sibling of the dialog band's `<dialog>`), gives Escape/light-dismiss/top-layer
  free. Rejected: `[popover]` always promotes to the top layer, which then
  *requires* CSS anchor positioning to place it — and anchor positioning is
  Chromium-only as of 2026-06. CI runs Playwright-Chromium only, so the
  Firefox/Safari gap would be invisible to our test gate. Unacceptable for an
  AAA-everywhere library.
- **Floating UI (`@floating-ui/dom`).** Best-in-class flip/shift in all
  browsers. Rejected: a new runtime JS dependency. The dialog band shipped zero
  positioning libraries; the project favors native / built-in. The actual
  defects here are accessibility, not positioning sophistication (the author
  already picks the side), so a positioning engine is YAGNI.

### Accepted limitation

No top layer: a popover inside an `overflow:hidden` / transformed ancestor can
be clipped. Documented in the component doc-comment; a future enhancement may
add CSS anchor positioning behind a feature check once it reaches Baseline.

## The shared `floating` controller

One Stimulus controller, `floating`, lives at
`…/add/templates/popover/floating_controller.js` (popover is the band exemplar,
hardened first — mirrors how `dialog/modal_controller.js` houses the dialog
band's shared controller). It **replaces** the current
`popover/popover_controller.js`; nothing depends on the old `popover` identity
yet, so the rename is free. Siblings reuse it via `EXTRA_STIMULUS` in
`lib/generators/modelrails_ui/components.rb`, never by copy:

```ruby
"tooltip"    => {source: "popover/floating_controller.js", name: "floating"},
"hover_card" => {source: "popover/floating_controller.js", name: "floating"}
```

Action surface, wired per component:

| Action | popover (click) | tooltip / hover_card (hover + focus) |
|---|---|---|
| `toggle` / `open` / `close` | click toggles; manages `aria-expanded`; focus-in on open, focus-return on close | — (CSS `:hover` / `:focus-within` shows it) |
| `closeOnClickOutside` | yes | — |
| `dismiss` (Escape) | yes (also returns focus) | yes — sets `data-dismissed`; CSS force-hides; cleared on blur/`mouseleave` so it can re-show |

Rationale: showing/hiding tooltips stays in **CSS** so it degrades gracefully
with no JS; the controller contributes only the one thing CSS cannot — Escape
dismissal (1.4.13). Non-modal popover means **no focus trap** (Tab may leave) —
the correct APG semantics for a non-modal popover.

## Component contracts

### popover (Wave 5a)

- **Trigger** → real `<button type="button">` with `aria-haspopup="dialog"`,
  `aria-expanded` (controller-managed), `aria-controls="{panel_id}"`,
  `data-action="click->floating#toggle"`. Minimum 44px target.
- **Panel** → `role="dialog"`, required label (new `label:` param →
  `aria-label`, or `aria-labelledby`), generated `id`,
  `data-floating-target="panel"`, retains `ALIGN`/`SIDE` positioning classes,
  hidden until open.
- **Behavior** → open moves focus into the panel; Escape and click-outside close
  and **return focus to the trigger**.
- **Fail-loud** `side`/`align` coercion (mirrors `sheet`'s `coerce_side`).

### tooltip (Wave 5b)

- Show on CSS `:hover` **and** `group-focus-within` (today: hover-only — the
  core bug). Bubble keeps `role="tooltip"` + `pointer-events-none`, gains a
  generated `id`.
- **Escape-dismiss** via the controller (1.4.13).
- **`aria-describedby` wiring (the one fiddly call):** for a screen reader to
  announce the tip, `aria-describedby` must sit on the *focusable* element, but
  the component wraps arbitrary trigger content. Resolution: `UI::Tooltip`
  annotates a **single focusable trigger** and applies
  `aria-describedby="{bubble_id}"` to the wrapper, made focusable
  (`tabindex="0"`) for the icon-trigger case; an already-focusable child still
  triggers the bubble via `:focus-within`. Flagged explicitly so adopters know
  the supported shape.

### hover_card (Wave 5b)

- Show on hover **and** `focus-within` (keyboard parity). Unlike tooltip, the
  card may hold **interactive content** → **no** `pointer-events-none`, and
  `focus-within` keeps it open while the user Tabs through that content
  (otherwise it is keyboard-unreachable). Escape dismisses. Optional `label:`
  → `aria-labelledby`.

## The 10-point DoD (each component)

renders · AAA semantic tokens only (no raw palette) · correct ARIA (role +
the wiring above) · fail-loud guard on any enum · focus management + 44px
targets on interactive triggers · disabled/invalid n/a · i18n (no hardcoded
strings) · doc-comment (Use when / Don't use when / Accessibility contract) ·
slot API · template-backed Lookbook preview. Plus: **0a** render test + **0b**
browser-axe spec.

## Wave split & file structure

Two gem-PR / app-PR pairs (smaller, logically-scoped). The design covers all
three so the controller is designed once.

### Wave 5a — popover + shared controller

**Gem** (branch `harden/wave5-floating-overlays` off `modelrails/harden`):

| File | Change |
|---|---|
| `…/popover/floating_controller.js` | New shared controller (replaces `popover_controller.js`). Do FIRST. |
| `…/popover/popover_component.rb.tt` | Rewrite: button trigger, `role="dialog"` panel, ARIA, `label:`, fail-loud coercion. |
| `…/popover/popover_controller.js` | **Delete** (superseded by `floating_controller.js`). |
| `test/render/popover_render_test.rb` | New 0a render test. |
| `…/lookbook/templates/previews/ui/popover_component_preview.rb` (+ scenarios) | New template-backed preview. |
| `COMPONENT_STATUS.md` | Add `popover` row (hardened). |
| `docs/components/popover.md` | Refresh. |

**App** (branch `feat/ui-popover`): vendor via `rails g modelrails_ui:add
popover`; vendor `floating_controller.js`; vendor preview; new
`spec/system/ui/popover_component_spec.rb` (0b).

### Wave 5b — tooltip + hover_card

**Gem** (branch off the updated `modelrails/harden`): rewrite
`tooltip_component.rb.tt` and `hover_card_component.rb.tt`; `EXTRA_STIMULUS`
entries for both; 0a render tests; previews; two `COMPONENT_STATUS` rows; doc
refreshes. **App**: vendor both; 0b specs for each.

## Testing (0b behavioral proofs)

- **popover:** opens on click; `aria-expanded` flips; Escape and click-outside
  close; focus returns to trigger; AAA on the live panel in both themes.
- **tooltip:** appears on keyboard **focus** (not just hover); Escape dismisses;
  `aria-describedby` resolves; AAA on the bubble (incl. inverted
  `bg-text-heading` color).
- **hover_card:** appears on `focus-within`; card content is Tab-reachable;
  Escape dismisses; AAA.

AAA contrast is **CI-only** (Playwright-Chromium, the `wcag2aaa` 7:1 after-hook);
a local 0b proves AA + behavior. CI is the authority of record.

## Toolchain

- **Gem:** Ruby 4.0.5 (gem `.ruby-version`); `mise.toml` is untrusted, so prefix
  Ruby commands with
  `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH"
  bundle exec …` (NOT `mise exec`). Default `rake` = `test:structural` +
  `test:render` + rubocop.
- **App:** `cd …/modelrails_base && mise exec -- bundle exec rspec …`.

## Exemplars to clone (read first)

- `…/add/templates/popover/popover_component.rb.tt` + `popover_controller.js` — current state to rewrite.
- `…/add/templates/dialog/dialog_component.rb.tt` + `modal_controller.js` — the hardened structural pattern + shared-controller idiom.
- `test/render/dialog_render_test.rb` — the 0a render-test pattern.
- (app) `spec/system/ui/dialog_component_spec.rb` — the 0b browser-spec pattern.
- `…/lookbook/templates/previews/ui/dialog_component_preview.rb` (+ scenario `.html.erb`) — the template-backed preview pattern.
