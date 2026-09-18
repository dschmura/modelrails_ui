# ScrollArea

Scrollable container with a thin, themed scrollbar styled via CSS custom properties.

## Installation

```bash
rails g modelrails_ui:add scroll_area
```

Creates `app/components/ui/scroll_area_component.rb`.

## Usage

```erb
<%= ui :scroll_area do %>
  <% 50.times do |i| %>
    <p class="text-sm py-1">Item <%= i + 1 %></p>
  <% end %>
<% end %>
```

## Orientations

| Orientation | Scrolls |
|-------------|---------|
| `:vertical` | Up/down (default) |
| `:horizontal` | Left/right |
| `:both` | Both axes |

```erb
<%= ui :scroll_area, orientation: :horizontal, max_h: nil, max_w: "max-w-sm" do %>
  <div class="flex gap-4 w-max">…</div>
<% end %>
```

## Custom dimensions

```erb
<%= ui :scroll_area, max_h: "max-h-96" do %>
  <%# long content %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orientation` | Symbol | `:vertical` | `:vertical`, `:horizontal`, or `:both` |
| `max_h` | String | `"max-h-72"` | Tailwind `max-height` class (used for vertical/both) |
| `max_w` | String | `nil` | Tailwind `max-width` class (used for horizontal/both) |
| `**html_attrs` | Hash | — | Forwarded to the `<div>` |

## When to use

- Long content must live in a bounded box (a list, a code block, a panel) that
  the user scrolls within.

## When not to use

- The content is already focusable throughout (e.g. a list of links/buttons) —
  the browser scrolls to follow focus, so the region need not be a tab stop.
  Pass `focusable: false` to opt out of the extra tab stop in that case.

## Accessibility contract

- **Guarantees (WCAG 2.1.1 keyboard):** when the region is focusable (the
  default), the scroll container is a tab stop (`tabindex="0"`) so keyboard-only
  users can focus it and arrow-scroll, carries a visible focus indicator (the
  `focus-ring` utility, never `focus:ring-*`), and is a named landmark
  (`role="region"` + accessible name) so AT announces what scrolls.
- **You supply:** an accessible name via `aria_label:` OR `aria_labelledby:`.
  A focusable scroll region with no name is unannounced — so this fails loud
  rather than ship a nameless tab stop.
