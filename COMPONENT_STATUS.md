# Component Status

Tier ledger for the modelrails_ui hardening program (see
`docs/design/2026-06-03-component-hardening-program-design.md`). Keeps the library
honest mid-program: only `proven`/`hardened` components are safe to adopt downstream
without extra verification.

- **proven** — render test + real app browser-axe AAA proof (0a + 0b).
- **hardened** — meets the 10-point DoD with a render test (0a); app adoption in progress.
- **experimental** — structurally present but unverified. Adopt at your own risk.
- **broken** — known generation/runtime bug. Do not adopt.

| Component | Tier | Render test | App-adopted (axe) | Notes |
| --- | --- | --- | --- | --- |
| button | proven | ✅ | ✅ | SP1 exemplar |
| alert | proven | ✅ | ✅ | Wave 1 exemplar (gem #4 + app #222 merged) |
| select | proven | ✅ | ✅ | Wave 1 (native AAA select; id fallback; invalid/describedby) — app #223 merged |
| checkbox | proven | ✅ | ✅ | Wave 1 form-control pattern-setter — app #223 merged |
| radio_group | proven | ✅ | ✅ | Wave 1 (group aria-label; per-option ids; invalid on group) — app #223 |
| switch | proven | ✅ | ✅ | Wave 1 (aria-checked bug fixed; peer-sibling track; 44px) — app #223 |
| toggle | proven | ✅ | ✅ | Wave 1 (fail-loud size guard; 44px sizes; sm≈default nit deferred) — app #223 |
| badge | proven | ✅ | ✅ | Wave 1 (fail-loud guard; destructive dark-AAA fix; href polymorphism) — app #224 |
| data_table | proven | ✅ | ✅ | Wave 1 (kbd-sort + aria-sort; live region; 44px; i18n; sort-reorder bug fixed #7) — app #224 |
| input | proven | ✅ | ✅ | Wave 2 (full form-control API; SP2-adopted) — render test added |
| textarea | proven | ✅ | ✅ | Wave 2 (form-control API; SP2-adopted) — render test added |
| file_input | proven | ✅ | ✅ | Wave 2 (form-control API + a11y; SP2-adopted) — render test added |
| label | proven | ✅ | ✅ | Wave 2 (explicit AAA token; for-assoc; decorative required `*`) |
| search_input | proven | ✅ | ✅ | Wave 2 (form-control API; aria-label accessible name; 44px) |
| number_input | proven | ✅ | ✅ | Wave 2 (form-control API; id fallback; 44px; spinners hidden) |
| range | proven | ✅ | ✅ | Wave 2 (native slider; invalid/describedby; id fallback) |
| floating_label | proven | ✅ | ✅ | Wave 2 (sets aria-invalid/required/describedby; always-on id/for; peer float) |
| rating_input | proven | ✅ | ✅ | Wave 2 (semantic warning-icon token, was raw yellow-400; group aria-label; 44px stars; i18n) |
| kbd | proven | ✅ | ✅ | Wave 3 display-primitive exemplar (doc + 0a + template-backed preview + 0b). text-text-muted is AAA here (same neutral as body) — no contrast change |
| separator | proven | ✅ | ✅ | Wave 3 (aria-orientation only when semantic; role none/separator) |
| skeleton | proven | ✅ | ✅ | Wave 3 (aria-hidden decorative placeholder; motion-reduce:animate-none) |
| spinner | proven | ✅ | ✅ | Wave 3 (i18n sr-only loading text via t default; role=status; sizes) |
| progress | proven | ✅ | ✅ | Wave 3 (optional label: → aria-label accessible name; clamp; valuenow/min/max) |
| indicator | proven | ✅ | ✅ | Wave 3 (raw palette → semantic success/warning + text-on-interactive; fail-loud variant) |
| image | proven | ✅ | ✅ | Wave 3 (required alt; loading-mode validation; conditional srcset/sizes/width/height) |
| figure | proven | ✅ | ✅ | Wave 3 (figcaption only when caption given; text-text-muted is AAA here) |
| dialog | hardened | ✅ | ⏳ | Wave 4 overlays exemplar (native <dialog>; 0a + JS-behavior 0b: open/escape/aria-modal + AAA on live modal). Was adopted unverified; now has render test + 0b. App 0b CI-pending |
| alert_dialog | hardened | ✅ | ⏳ | native `<dialog role=alertdialog>` (Wave 4); shared `modal` controller; 0a render test + role/labelledby/describedby + 44px i18n close; app 0b CI-pending |
| drawer | hardened | ✅ | ⏳ | native bottom `<dialog>` slide-up (Wave 4); shared `modal` controller (translateY); decorative drag-handle + 44px close; 0a; app 0b CI-pending |
| sheet | hardened | ✅ | ⏳ | native side `<dialog>` per-side slide (Wave 4); fail-loud `coerce_side`; shared `modal` controller; 0a; app 0b CI-pending |

All other gem components: **experimental** (unverified) unless listed above.

**Sibling templates to copy:** `alert` is the canonical Wave 1 reference. Copy its render test
(`test/render/alert_render_test.rb`), template-backed preview, and — for 0b — its preview-host
axe-AAA system spec shape (`spec/system/ui/alert_component_spec.rb` in the app: visit the preview
URL, scope axe to the component subtree by role, assert `axe_clean_in_both_themes?` with **no**
color-contrast exclude). `button` predates the preview-host 0b convention (its 0b was proven via
in-page adoption), so follow `alert` for the system-spec pattern, not `button`.
