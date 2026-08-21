# Dropdown menu

A button that opens a menu of actions, implementing the WAI-ARIA APG menu-button
pattern. Open/close and the full keyboard model live in the `menu` Stimulus
controller shipped with this component; placement is CSS anchor positioning.

Requires `menu_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add dropdown_menu
```

Creates `app/components/ui/dropdown_menu_component.rb` and
`app/javascript/controllers/menu_controller.js`.

## Usage

```erb
<%= render(UI::DropdownMenuComponent.new) do |c| %>
  <% c.with_trigger { "Actions" } %>
  <% c.with_item { "Edit" } %>
  <% c.with_item(disabled: true) { "Archive" } %>
  <% c.with_item(separator: true) %>
  <% c.with_item(href: "/reports/new") { "New report" } %>
<% end %>
```

The `with_trigger` slot is required (omitting it raises `ArgumentError`). Each
`with_item` becomes a `role="menuitem"`:

| Option | Effect |
|--------|--------|
| `disabled: true` | `aria-disabled` — skipped by keyboard nav, activation rejected |
| `separator: true` | renders a divider (no content) in source order |
| `href: "/path"` | renders an `<a role="menuitem">` instead of a `<button>` |

Icon-only triggers MUST pass `aria_label:` (the menu button's accessible name):

```erb
<%= render(UI::DropdownMenuComponent.new(aria_label: "Row actions")) do |c| %>
  <% c.with_trigger { tag.svg(...) } %>
  ...
<% end %>
```

## Options

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `side` | Symbol | `:bottom` | `:bottom` or `:top` |
| `align` | Symbol | `:start` | `:start` or `:end` (edge-aligned to the trigger) |
| `id` | String | auto `dropdown-<hex>` | Menu element ID; wired to `aria-controls` on the trigger |
| `aria_label` | String | — | Trigger's accessible name. **Required for icon-only triggers** |
| `trigger_class` | String | `"btn-secondary"` | CSS classes **added to** the trigger's accessibility floor (focus ring + 44px target size), which cannot be replaced |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

> **`class:` targets the wrapper, not the trigger.** Passing `class:` styles the outer
> `<div>`; to restyle the button itself use `trigger_class:`. This is the most common
> point of confusion with this component.

`.btn-secondary` ships in `modelrails_ui.css`. A fork that strips or renames the `.btn-*`
layer should pass its own `trigger_class:`.

| Slot | Required | Description |
|------|----------|-------------|
| `with_trigger` | Yes | Visible content of the trigger button |
| `with_item` | — | A menu item; see [Items](#items) |

## Placement

| Arg | Values | Default |
|-----|--------|---------|
| `side` | `:bottom`, `:top` | `:bottom` |
| `align` | `:start`, `:end` (edge-aligned to the trigger) | `:start` |

Placement uses CSS anchor positioning with an `absolute`-offset fallback on
pre-Baseline-2026 browsers; `position-try-fallbacks: flip-block` keeps the menu
on-screen.

## Keyboard

| Key | Action |
|-----|--------|
| `Enter` / `Space` / `↓` (on trigger) | Open, focus first item |
| `↑` (on trigger) | Open, focus last item |
| `↓` / `↑` (in menu) | Move (wraps, skips disabled) |
| `Home` / `End` | First / last item |
| type a letter | Jump to the next item starting with it (1s buffer) |
| `Enter` / `Space` / click | Activate item, close |
| `Escape` | Close, return focus to trigger |
| `Tab` | Close, advance focus to the next page element |

## Accessibility

WCAG 2.2 AAA. The menu is named by its trigger (`aria-labelledby`); the trigger
exposes `aria-haspopup="menu"` and a synced `aria-expanded`. Roving tabindex keeps
exactly one item focusable at a time. Proven by `spec/system/ui/dropdown_menu_component_spec.rb`
in the host app (keyboard + axe AAA in both themes).
