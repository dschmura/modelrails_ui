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
| select | hardened | ✅ | ⏳ | Wave 1 sub-wave 1 (native AAA select; id fallback; invalid/describedby) |
| checkbox | hardened | ✅ | ⏳ | Wave 1 sub-wave 1 form-control pattern-setter |
| radio_group | hardened | ✅ | ⏳ | Wave 1 sub-wave 1 (group aria-label; per-option ids; invalid on group) |
| switch | hardened | ✅ | ⏳ | Wave 1 sub-wave 1 (aria-checked bug fixed; peer-sibling track; 44px target) |
| toggle | hardened | ✅ | ⏳ | Wave 1 sub-wave 1 (fail-loud size guard; 44px sizes; sm≈default nit deferred) |
| badge | hardened | ✅ | ⏳ | Wave 1 sub-wave 2 (fail-loud guard; destructive dark-AAA fix; href polymorphism) |
| data_table | hardened | ✅ | ⏳ | Wave 1 sub-wave 2 (kbd-sortable headers + aria-sort; live region; 44px; i18n) |

All other gem components: **experimental** (unverified) unless listed above.

**Sibling templates to copy:** `alert` is the canonical Wave 1 reference. Copy its render test
(`test/render/alert_render_test.rb`), template-backed preview, and — for 0b — its preview-host
axe-AAA system spec shape (`spec/system/ui/alert_component_spec.rb` in the app: visit the preview
URL, scope axe to the component subtree by role, assert `axe_clean_in_both_themes?` with **no**
color-contrast exclude). `button` predates the preview-host 0b convention (its 0b was proven via
in-page adoption), so follow `alert` for the system-spec pattern, not `button`.
