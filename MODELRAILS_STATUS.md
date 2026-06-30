# modelrails_base fork — status & maturity record

Fork of `view_primitives` (branch `modelrails/harden`) hardened to meet modelrails_base
standards (WCAG 2.2 AAA, I18n, the app's OKLCH semantic tokens, form_builder integration).
This file is the source of truth for **what is solid vs. what still needs work**.

Guiding rule: *when the app's implementation is superior, adopt ours into the gem; never regress.*

Quality gate = the **host app's own specs** (parity gates). Current: **820 app specs green**
(components + form_builder a11y + requests + helpers + views).

**AAA is now gem-verified:** `test/test_aaa_contrast.rb` resolves the core semantic token pairs
to their Tailwind v4 OKLCH values (primary=sky, neutral=slate) and computes contrast
(OKLCH to OKLab to linear sRGB to relative luminance), asserting >= 7:1 for text-heading,
text-body, and text-on-interactive on their surfaces in BOTH light and dark. Math validated
against anchors (white/black = 21:1; interactive+white ~ 7.56:1). A token remap that breaks AAA
now fails the build.

---

## ✅ SOLID — production-grade, hardened at source, parity-proven, adopted

These were rewritten in the gem templates to match the app exactly, are covered by app
parity specs, and are adopted in the app via zero-call-site adapters.

| Component | Hardening | Adopted in app via | Parity gate |
|---|---|---|---|
| `Input` | first-class a11y params (`required`/`invalid`/`describedby` → ARIA), app FIELD styling, semantic tokens, dual-mode (builder + standalone) | `TailwindFormBuilder` delegates text/email/password/url/tel/number/date/search | `spec/form_builders/*` + component specs |
| `Textarea` | same as Input + value-as-content | builder `text_area` | component specs |
| `FileInput` | app FILE styling + **added** ARIA wiring (app's plain file_field lacked it) | builder `file_field` | component spec |
| `Dialog` | **rewritten to native `<dialog>` + `showModal`** (focus-trap/restore/Esc/backdrop) — adopted the app's superior modal; ships app's `modal_controller.js` verbatim; `wrapper:`/`body_id:` for embedding | `_modal` is a thin adapter (`wrapper: false`, `body_id: "modal-body"` preserves Turbo contract) | `views/shared/confirm_dialog_spec` + component specs; behavior by `system/modal_spec` (controller unchanged) |
| `Button` | rewritten to app `.btn-*` taxonomy (primary/secondary/danger + text family), AAA, `--form-input-height` | available for new code; `.btn-*` CSS unchanged for existing call sites | component spec |
| `Avatar` | app `AVATAR_SIZES`, rounded-full, hue initials, role=img/aria-hidden semantics | `avatar_for` helper delegates (model logic stays) | `helpers/avatar_helper_spec` + view + component specs |

Generator: **fixed at source** (`source_root` instance-method bug + Thor public-method bug) →
`rails g view_primitives:add` works natively. *(Upstreamable PR.)*

Generator `agent_rules`: **solid** — writes `.modelrails_ui/agent-rules.md` (overwritten) + seeds
`.modelrails_ui/house-rules.md` (once), adds an idempotent marker-delimited `@`-import to
`CLAUDE.md`/`AGENTS.md`, and reports (never rewrites) conflicting directives.

---

## 🟡 PRE-RELEASE — token-ported, renders, NOT parity-audited or adopted

All other components (~66) had the shadcn→AAA semantic-token rewire ported into their gem
templates (62 templates changed; **0 residual shadcn tokens, 0 `dark:` leftovers**; all `.rb.tt`
still compile). They will generate with the app's token system and render, BUT:

- **Not** audited against an app counterpart (no parity spec, no visual review).
- **Not** adopted in the app.
- May have rough edges (spacing, structure, a11y depth) vs. the SOLID tier.

Treat as usable-but-uncertified. Promote to SOLID by: parity-audit vs. an app counterpart →
component/a11y spec → adopt via adapter.

---

## 🔴 BROKEN — do not use until fixed (upstream gem bugs)

| Component | Bug |
|---|---|
| `form_field` | template renders invalid Ruby (SyntaxError at generation) |
| `qr_code` | template renders invalid Ruby (SyntaxError at generation) |
| `input_otp` | template calls undefined `ui` helper at generation time |
| `embed` | calls `CGI.parse` without `require "cgi"` → raises on Ruby 4.0 |

---

## ⚪ KEPT APP-NATIVE — intentionally NOT gem components

The app's implementations are superior AND tightly integration-coupled; forcing them into a
general gem would drag app-specific coupling in (the opposite of easy adoption).

- **Toasts** — flash-driven two-tier (pill/card) subsystem (`config.toasts`, live regions, layout mount). App keeps it.
- **`select`** — the **form-builder** path stays native (Rails `choices` API — arrays/grouped/collections — doesn't map to the gem's `options:`). The gem's `UI::Select` component (`options:` API) *is* adopted in the app and, as of **v0.4.0**, styles its open picker via `appearance: base-select` where supported (design-system overlay + brand checkmark + flipping icon; untouched native fallback elsewhere) — 0b-axe parity-proven in both themes.
- **`check_box`** — needs Rails' paired hidden field (unchecked value).
- **`collection_check_boxes` / `collection_radio_buttons`** — fieldset iterators, no single-component equivalent.
- **(Not yet evaluated)** user_menu/dropdown, sidebar, footer — app-specific nav; likely adapter or keep-native.

---

## 🛠 NEEDS IMPROVEMENT — tracked

1. **Gem's own test suite (~18 tests) asserts pre-hardening behavior** — mechanical updates needed:
   - `TestAvatarComponent#test_initials_*` (×6) + `test_default_size` — component no longer derives initials (renders caller-supplied `fallback`); default size is `:md`.
   - `TestButtonComponent#test_default_variant`, `test_component_classes_default/destructive_variant/small_size` — variants are now primary/secondary/danger/text*; no SIZES scale.
   - `TestDialogComponent#test_title_stored/description_stored/nil_title_default/nil_description_default/class_extracted` — dialog internals changed (native-dialog rewrite).
   - `TestFigureComponent#test_caption_class_constant` — token-port changed a token string in the assertion.
   - `TestGeneratorComponents#test_dialog_has_js_controller` — **fixed** (now expects `modal_controller.js`).
2. **Token portability** — ✅ ADDRESSED. The install generator's `view_primitives.css` now ships
   the full modelrails_base AAA design system (primitives + semantic tokens + `@theme inline`
   registration + `.dark` variant + `.btn-*`/`.bg-hue-*` component classes). The gem is now
   self-contained: components render correctly standalone, and AAA contrast becomes gem-testable.
   On adoption, modelrails_base would get its tokens FROM the gem.
3. **Pre-release components not visually audited** after the mechanical token-port.
4. **3 broken templates + 1 runtime bug** (see BROKEN) — upstreamable fixes.

---

## 📦 Adoption guide for modelrails_base

1. Point the Gemfile at this fork (git ref or path).
2. `rails g view_primitives:install` then `rails g view_primitives:add <components>`.
3. Wire the adapters (existing call sites stay unchanged):
   - `TailwindFormBuilder` → delegates fields to `UI::Input`/`Textarea`/`FileInput` (already done in spike).
   - `shared/_modal` → renders `UI::DialogComponent(wrapper: false, body_id: "modal-body")`.
   - `AvatarHelper#avatar_for` → renders `UI::AvatarComponent`.
   - New buttons → `UI::ButtonComponent`; existing `.btn-*` CSS untouched.
4. Run the app suite — existing parity specs are the gate.
