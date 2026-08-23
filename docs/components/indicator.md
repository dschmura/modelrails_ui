# Indicator

Status dot or count badge overlaid on another element. Wraps any content and renders a small badge in one corner.

## Installation

```bash
rails g modelrails_ui:add indicator
```

Creates `app/components/ui/indicator_component.rb`.

## Usage

```erb
<%# Online dot over an avatar %>
<%= ui :indicator, variant: :success do %>
  <%= ui :avatar, fallback: "Alice" %>
<% end %>

<%# Notification count on a button %>
<%= ui :indicator, count: 3 do %>
  <%= ui :button, "Inbox", variant: :outline %>
<% end %>
```

## Variants

| Variant | Colour |
|---------|--------|
| `default` | Primary (interactive fill) |
| `info` | Info blue |
| `success` | Green |
| `warning` | Amber |
| `danger` | Red (`destructive` is a non-breaking alias) |

## Positions

| Position | Placement |
|----------|-----------|
| `top_right` *(default)* | Top-right corner |
| `top_left` | Top-left corner |
| `bottom_right` | Bottom-right corner |
| `bottom_left` | Bottom-left corner |

```erb
<%= ui :indicator, variant: :danger, position: :bottom_right do %>
  <%= ui :avatar, fallback: "Bob" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `count` | Integer / nil | `nil` | When set, renders a numbered badge; otherwise renders a small dot |
| `variant` | Symbol | `:default` | Colour — `:default`, `:info`, `:success`, `:warning`, `:danger` (`:destructive` is a non-breaking alias for `:danger`) |
| `position` | Symbol | `:top_right` | Corner — `:top_right`, `:top_left`, `:bottom_right`, `:bottom_left` |
| `**html_attrs` | Hash | — | Forwarded to the outer wrapper `<span>` |
