# Menubar

A horizontal application menubar (WAI-ARIA APG menubar) — a `role="menubar"` of top-level
items, each opening a submenu. Each submenu reuses the shared `menu` Stimulus controller; a
thin `menubar` controller coordinates the bar (roving tabindex + ←/→) and drives the submenus
via Stimulus outlets.

Requires `menubar_controller.js` and `menu_controller.js` (both copied by the generator).

## Installation

```bash
rails g modelrails_ui:add menubar
```

Creates `app/components/ui/menubar_component.rb`, `app/components/ui/menubar_menu_component.rb`,
`app/javascript/controllers/menubar_controller.js`, and `app/javascript/controllers/menu_controller.js`.

## Usage

```erb
<%= render(UI::MenubarComponent.new(label: "Main")) do |bar| %>
  <% bar.with_menu(label: "File") do |m| %>
    <% m.with_item { "New" } %>
    <% m.with_item { "Open" } %>
    <% m.with_item(separator: true) %>
    <% m.with_item(href: "/recent") { "Open recent" } %>
  <% end %>
  <% bar.with_menu(label: "Edit") do |m| %>
    <% m.with_item { "Undo" } %>
    <% m.with_item(disabled: true) { "Redo" } %>
  <% end %>
<% end %>
```

`label:` on the menubar is its accessible name. Each `with_menu(label:)` is a top-level item;
its `with_item` slots become the submenu's `role="menuitem"`s (same options as `dropdown_menu`:
`disabled:`, `separator:`, `href:`). Single-level submenus only.

`UI::MenubarMenuComponent` is always used inside `UI::MenubarComponent` via `with_menu`,
never standalone. The submenu is a `menu` controller (reused via `EXTRA_STIMULUS`) — same
item model and behavior as `dropdown_menu`; positioning is CSS anchor positioning, the panel
tethered to the bar item.

## Keyboard

| Key | Action |
|-----|--------|
| `Tab` into the bar | Lands on one bar item (the menubar is one tab stop) |
| `←` / `→` | Move between bar items (wraps); if a submenu is open, closes it and opens the adjacent |
| `Home` / `End` | First / last bar item |
| type a letter (bar) | Jump to the next bar item starting with it |
| `↓` / `Enter` / `Space` (bar item) | Open its submenu, focus first item |
| `↑` (bar item) | Open its submenu, focus last item |
| `↑` / `↓` (submenu) | Move (wraps, skips disabled); Home/End; type-ahead |
| `Enter` / `Space` / click | Activate submenu item, close |
| `Escape` | Close submenu, focus the bar item |

## Accessibility

WCAG 2.2 AAA. Proven by `spec/system/ui/menubar_component_spec.rb` in the host app.

## When to use

- An app-level command bar (File / Edit / View …) where one row exposes several menus.

## When not to use

- A single trigger opens one menu — use `dropdown_menu`.

## Accessibility contract

- **Guarantees:** `role="menubar"` (named by `label:`); bar items `role="menuitem"` +
  `aria-haspopup="menu"` + synced `aria-expanded` + `aria-controls`, roving tabindex (one
  tab stop); full keyboard (←/→ wrap, Home/End, type-ahead, ↓/Enter opens submenu,
  ↑ opens to last, Escape closes to the bar item, ←/→ from a submenu follows to the
  adjacent menu). Submenus are `role="menu"` with roving menuitems.
- **You supply:** one or more `with_menu(label:)` slots, each with `with_item` slots.
