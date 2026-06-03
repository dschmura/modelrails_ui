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
| alert | hardened | ✅ | ⏳ | Wave 1 exemplar (app adoption in `feat/ui-alert-exemplar`) |
| select | experimental | ❌ | ❌ | Wave 1 sub-wave 1 (native `<select>` target) |
| checkbox | experimental | ❌ | ❌ | Wave 1 sub-wave 1 |
| radio_group | experimental | ❌ | ❌ | Wave 1 sub-wave 1 |
| switch | experimental | ❌ | ❌ | Wave 1 sub-wave 1 (aria-checked sync bug) |
| toggle | experimental | ❌ | ❌ | Wave 1 sub-wave 1 (sub-44px target) |
| badge | experimental | ❌ | ❌ | Wave 1 sub-wave 2 |
| data_table | experimental | ❌ | ❌ | Wave 1 sub-wave 2 (kbd sort, 44px) |

All other gem components: **experimental** (unverified) unless listed above.

**Sibling templates to copy:** `alert` is the canonical Wave 1 reference. Copy its render test
(`test/render/alert_render_test.rb`), template-backed preview, and — for 0b — its preview-host
axe-AAA system spec shape (`spec/system/ui/alert_component_spec.rb` in the app: visit the preview
URL, scope axe to the component subtree by role, assert `axe_clean_in_both_themes?` with **no**
color-contrast exclude). `button` predates the preview-host 0b convention (its 0b was proven via
in-page adoption), so follow `alert` for the system-spec pattern, not `button`.
