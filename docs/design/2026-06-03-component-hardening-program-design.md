# Design: component-hardening program — make all 77 components downstream-ready

**Date:** 2026-06-03
**Status:** Proposed (design approved in brainstorming; pending written-spec review)
**Repo:** modelrails_ui (gem)
**Scope:** a multi-phase PROGRAM, not a single feature. This doc is the strategy; each phase gets its own implementation plan. The first plan is **Phase 0a** (the verification harness), because everything depends on it.

## Why

The gem ships **77 component `add`-templates** (phases 1-9), but quality is wildly uneven: ~5 are production-ready (button-tier: fail-loud guards + AAA semantic tokens + full ARIA + docs + previews), ~65 are "structurally there but unverified" (semantic tokens, basic ARIA, no guards), ~4 are rough stubs (`select`, `tooltip`, …), and 3 are outright broken (`form_field`, `qr_code`, `input_otp` — generation bugs). Only the 6 worked this session (button, input, textarea, file_input, avatar, dialog) have Lookbook teaching previews.

The goal: bring **all 77** up to the button-tier bar so they are genuinely downstream-ready — pulled via `rails g modelrails_ui:add <name>` with confidence.

## The decisive constraint

The gem's current test suite is **structural only**: it stubs ViewComponent so `.call` returns `""`, and the bare test env can't boot `Rails.env`. It **cannot verify rendering, ARIA, or AAA contrast** — the README defers that to "integration specs in the consuming app." Hardening 77 components without a render harness produces 77 components that *look* right and are *proven* nowhere. Therefore the program's long pole is **building gem-side verification first.**

## Decisions (from brainstorm)

- **Driver: roadmap-driven** — proactively harden all 77, not just on app demand.
- **Verification: two-tier** — (0a) render + ARIA + token-contrast, no browser; then (0b) full browser axe-AAA per component.
- **Sequence: app-need-first, then phase order** — Wave 1 = the modelrails_base gap-doc set (gets real app-gate proof); then phase 1→9 for the rest.

## Program phases

### Phase 0a — verification harness (FIRST; enabler)

Add a minimal `test/dummy` Rails app + `ViewComponent::TestCase` so the gem can `render_inline(UI::XComponent.new(...))` and assert real HTML/ARIA with Capybara matchers. Keep `test_aaa_contrast.rb` as the AAA-token guarantee (hardened components inherit AAA by using the verified semantic tokens). Wire the render tests into the existing Ruby 3.2-4.0 + Appraisal matrix. Outcome: the gem becomes render-verifiable without a browser.

### Phase 0b — browser axe-AAA (after the harness + early waves)

Capybara + Playwright + axe at WCAG AAA per component, in the dummy app. The deeper proof tier, layered on once the fast harness has proven its worth. Heavier (browser infra in CI), so deliberately sequenced after 0a + the first hardening waves.

### Phases 1…N — hardening waves

- **Wave 1 (app-need):** the gap-doc priorities — `select`, `checkbox`, `radio_group`, `switch`/`toggle`, submit-via-`button`; then `badge`; then `data_table`/`alert`. These are also adopted into modelrails_base, earning **real browser axe-AAA proof via the app's gate** immediately, and proving the DoD + pipeline before scaling.
- **Waves 2…N (phase order 1→9):** the remainder, folding in the 3 broken (`form_field`, `qr_code`, `input_otp`) and rough stubs (`tooltip`, …) as their phase comes up.

## Definition of Done (per component, testable with the Phase-0a harness)

A component is downstream-ready when, verified by the harness:

1. **Renders** without error via `render_inline`.
2. **AAA semantic tokens only** (`bg-interactive`, `text-text-*`, `focus:ring-interactive-focus`, `--form-input-height`) — no raw/guessed Tailwind; AAA inherited from the token-contrast tests.
3. **Correct ARIA** — `role`, `aria-*`, label association — asserted on the rendered DOM.
4. **Fail-loud guard** on enum props (raise in dev/test, fall back in prod) — the `coerce_variant` pattern.
5. **Focus management** + 44px minimum touch targets.
6. **Disabled / invalid** states.
7. **i18n** for any user-facing strings.
8. **Doc comment** — use-when + accessibility contract.
9. **Slot/content API** — `content || label`, not hardcoded markup.
10. **Template-backed Lookbook preview** — the copyable artifact, same treatment as the 6. **Plus a `@param` playground** when the component's variation is parameter-driven (enum / variant / size / boolean props) — live Lookbook controls, as on `button` / `toggle` / `badge` / `avatar` / `popover`. Slot-driven overlays whose real variation is *content*, not params (`dialog` / `alert_dialog` / `drawer` / `sheet`), stay static-only and are exempt.

## Per-component process

Repeatable pipeline (the SP-style loop proven this session, now with real render tests):

1. Read the rough template.
2. Harden to the DoD.
3. Write render + ARIA + token tests (Phase-0a harness).
4. Add the Lookbook teaching preview.
5. Run the harness (`rake` = test + rubocop) green.
6. Commit (atomic, per component).

**Parallelization:** components are independent files, so waves fan out across subagents/worktrees; the gem CI catches regressions. **Caution:** multi-file components (card, tabs, accordion, dialog: 2-6 `.rb.tt` + `.html.erb` + `_controller.js`) are larger units — JS-enabled ones need controller-wiring checks that the render harness alone can't fully cover (true interactive behavior lands in Phase 0b).

## Tier ledger (usable mid-program)

Maintain a status ledger (in `components.rb` metadata or `COMPONENT_STATUS.md`): `proven` / `hardened` / `experimental` / `broken`. A downstream dev pulling a component mid-program sees its real state — `checkbox` = `proven`, `tooltip` = `experimental` — so the library is honest and usable throughout, not just at the finish line.

## Decomposition into plans

This program is intentionally many plans, not one:

- **Plan 1 — Phase 0a** (the harness). The first and gating plan.
- **Plan 2 — Wave 1** (gap-doc components, ~7-8), once the harness exists.
- **Plans 3…N — phase-order waves.**
- **Plan (later) — Phase 0b** (browser axe-AAA).

Each plan produces working, tested gem state on its own. This doc is the umbrella; `writing-plans` runs per phase.

## Open items / risks

- **Dummy-app footprint:** keep the `test/dummy` minimal — enough to render ViewComponents, not a full app. Watch the Appraisal matrix (rails-7.2/8.1) compatibility.
- **JS components:** the render harness verifies markup/ARIA but not Stimulus behavior; interactive proof waits for Phase 0b (Playwright).
- **AAA-via-tokens assumption:** holds only if components use the semantic tokens; the DoD's token-only rule + the render-class assertions enforce it, but a component that hardcodes a color would pass render tests while failing real AAA — Phase 0b axe is the backstop.
- **Scale:** 77 components is a long program; the tier ledger + app-need-first sequencing keep value flowing throughout, but completion is measured in waves, not one pass.
