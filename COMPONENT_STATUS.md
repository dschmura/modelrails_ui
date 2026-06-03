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
