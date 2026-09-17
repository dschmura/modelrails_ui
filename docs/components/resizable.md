# Resizable

Two-panel layout with a draggable handle that resizes the panels at runtime.
The handle is the APG window-splitter pattern: a focusable `role="separator"`
the user can grab with the mouse OR move with the keyboard.

Requires `resizable_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add resizable
```

Creates `app/components/ui/resizable_component.rb`.

## Usage

```erb
<%= ui :resizable do |r| %>
  <% r.with_panel(default: 30) do %>
    <div class="p-4">Left panel</div>
  <% end %>
  <% r.with_panel do %>
    <div class="p-4">Right panel</div>
  <% end %>
<% end %>
```

## Vertical split

```erb
<%= ui :resizable, direction: :vertical do |r| %>
  <% r.with_panel(default: 40) do %>
    <div class="p-4">Top panel</div>
  <% end %>
  <% r.with_panel do %>
    <div class="p-4">Bottom panel</div>
  <% end %>
<% end %>
```

## Panel constraints

```erb
<% r.with_panel(min: 20, max: 60, default: 35) do %>
  <div>Constrained panel</div>
<% end %>
```

## API

### ResizableComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `direction` | Symbol | `:horizontal` | `:horizontal` (side by side) or `:vertical` (stacked) |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

### PanelComponent (via `with_panel`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `min` | Integer | `10` | Minimum panel size as a percentage |
| `max` | Integer | `90` | Maximum panel size as a percentage |
| `default` | Integer | `nil` | Initial size as a percentage; unset panels share remaining space equally |

## Accessibility contract

- **Guarantees (WCAG 2.1.1 keyboard):** every handle is a focusable
  `role="separator"` tab stop carrying the `focus-ring` indicator (the offset
  outline, never `focus:ring-*`), a named splitter (`aria-label`, i18n default),
  the `aria-orientation` it splits across, and the `aria-valuenow/valuemin/
  valuemax` range its controller keeps in sync. Arrow keys (← → for a
  horizontal split, ↑ ↓ for a vertical one) resize it; Home/End jump to the
  min/max. Pointer users still drag it.
- **You supply:** panels (each with optional `min`/`max`/`default` percentages).
