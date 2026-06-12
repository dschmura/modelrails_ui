# Navbar

A responsive top navigation bar (a `<nav>` landmark) — a brand, inline desktop links, an
optional right-aligned action area, and a mobile disclosure (a hamburger toggles a stacked
menu). The disclosure follows the WAI-ARIA APG disclosure pattern.

Requires `navbar_controller.js` (copied by the generator).

## Installation

```bash
rails g modelrails_ui:add navbar
```

## Usage

```erb
<%= render(UI::NavbarComponent.new(
  brand: "Acme",
  brand_href: root_path,
  label: "Main",
  items: [
    { label: "Dashboard", href: "/dashboard", active: true },
    { label: "Pricing", href: "/pricing" }
  ]
)) do %>
  <%= link_to "Sign in", "/login", class: "btn-primary" %>
<% end %>
```

`label:` is the `<nav>` accessible name (i18n; defaults to `t("ui.navbar.label", default: "Main")`).
`items:` are the links (`active: true` → `aria-current="page"`). Block content goes in the
right-aligned action area (desktop). On narrow screens the inline links collapse behind a
hamburger that discloses a stacked menu.

## Keyboard

| Key | Action |
|-----|--------|
| `Enter` / `Space` on the hamburger | Toggle the mobile menu (syncs `aria-expanded`) |
| `Escape` | Close the mobile menu, return focus to the hamburger |
| click outside | Close the mobile menu |

## Accessibility

WCAG 2.2 AAA. `<nav>` named by `label:`; the hamburger is a `<button>` with synced
`aria-expanded` + `aria-controls`; the active link is `aria-current="page"`. Proven by
`spec/system/ui/navbar_component_spec.rb` in the host app (at a mobile viewport).
