# Tabs

A set of layered sections (WAI-ARIA APG **tabs**, automatic activation) — one `role="tablist"`
of `role="tab"` buttons, each revealing a `role="tabpanel"`. The tablist is one tab stop
(roving tabindex); ←/→ move focus and reveal that tab's panel.

Requires `tabs_controller.js` (copied by the generator).

## Installation

```bash
rails g modelrails_ui:add tabs
```

Creates `app/components/ui/tabs_component.rb`, `app/components/ui/tabs_item_component.rb`, and
`app/javascript/controllers/tabs_controller.js`.

## Usage

```erb
<%= render(UI::TabsComponent.new(label: "Account settings")) do |t| %>
  <% t.with_tab(title: "Profile") do %>
    <p>Profile panel…</p>
  <% end %>
  <% t.with_tab(title: "Password") do %>
    <p>Password panel…</p>
  <% end %>
  <% t.with_tab(title: "Notifications", disabled: true) do %>
    <p>Notifications panel…</p>
  <% end %>
<% end %>
```

`label:` is the tablist's accessible name (required; pass a translated string). Each
`with_tab(title:)` is a tab; its block is the panel content. `disabled: true` makes a tab
`aria-disabled` (skipped by the keyboard). `selected:` (default `0`) sets the initially-active
tab.

## Keyboard

| Key | Action |
|-----|--------|
| `Tab` into the tablist | Lands on the active tab (one tab stop) |
| `←` / `→` | Move to the previous/next enabled tab and reveal its panel (wraps) |
| `Home` / `End` | First / last enabled tab (+ reveal) |
| click | Reveal that tab's panel |
| `Tab` again | Move into the active panel (it is `tabindex="0"`) |

## Accessibility

WCAG 2.2 AAA. `role="tablist"` named by `label:`; each `role="tab"` carries `aria-selected`,
`aria-controls`, and roving tabindex; each `role="tabpanel"` carries `aria-labelledby` and is
focusable. Proven by `spec/system/ui/tabs_component_spec.rb` in the host app.
