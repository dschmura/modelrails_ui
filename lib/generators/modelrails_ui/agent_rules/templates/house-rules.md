# Project house rules (UI)

Sensible defaults from modelrails_ui. This is *your* file — edit or delete freely;
the generator seeds it once and never overwrites it.

- **All UI text uses I18n locale keys** — no hardcoded strings.
- **No inline event handlers** (`onclick`, `onchange`, …). A strict Content Security
  Policy (CSP) blocks them, and system specs won't catch it (Playwright bypasses CSP) —
  use Stimulus actions: `data-action="click->controller#method"`.
