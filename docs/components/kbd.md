# KBD

Keyboard shortcut key display. Renders a `<kbd>` element styled to look like a physical key.

## Installation

```bash
rails g modelrails_ui:add kbd
```

Creates `app/components/ui/kbd_component.rb`.

## Usage

```erb
<%# Positional key label %>
<%= ui :kbd, "⌘" %>

<%# Keyword label %>
<%= ui :kbd, label: "Enter" %>

<%# Block content %>
<%= ui :kbd do %>Ctrl<% end %>
```

## Shortcut combinations

Render multiple `KbdComponent`s inline with separator text:

```erb
<span class="text-sm text-muted-foreground">
  Press <%= ui :kbd, "⌘" %> + <%= ui :kbd, "K" %> to open search.
</span>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `key` | String | `nil` | Key label — positional or `label:` keyword, alternative to block |
| `**html_attrs` | Hash | — | Forwarded to the `<kbd>` element |

## When to use

- Documenting a keyboard shortcut inline ("Press ⌘K to search") or inside a
  menu item / tooltip.

## When not to use

- The text isn't a keyboard key — `<kbd>` misrepresents the semantics to
  assistive tech. Use plain text or a `badge` for non-key labels.
- You need it to be clickable — it is `pointer-events-none` by contract.

## Accessibility contract

- **Guarantees:** AAA-contrast text on `bg-surface-sunken`, non-interactive
  (`pointer-events-none` + `select-none`), and inline-SVG key icons auto-sized
  to match the text.
- **You supply:** the key text via the positional arg, `label:`, or slot content.
