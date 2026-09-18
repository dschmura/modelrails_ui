# Separator

Thin divider line for horizontal or vertical layout separation. It is decorative by
default (`role="none"`); mark it semantic when the divide conveys real grouping that
assistive tech must perceive.

## Installation

```bash
rails g modelrails_ui:add separator
```

Creates `app/components/ui/separator_component.rb`.

## Usage

```erb
<%# Horizontal (default) %>
<%= ui :separator %>

<%# Vertical %>
<%= ui :separator, orientation: :vertical %>

<%# Non-decorative (semantic separator for screen readers) %>
<%= ui :separator, decorative: false %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orientation` | Symbol | `:horizontal` | `:horizontal` or `:vertical` |
| `decorative` | Boolean | `true` | When `true`, sets `role="none"`; when `false`, sets `role="separator"` |
| `**html_attrs` | Hash | — | Forwarded to the `<div>` element |

## When to use

- You need a visual rule between sections, list items, or toolbar groups.
- The divide carries meaning (a real boundary between groups) — pass
  `decorative: false` so the separator is announced.

## When not to use

- The boundary is purely cosmetic *and* already implied by layout — a decorative
  separator is fine, but don't leave a meaningful grouping divide as decorative
  (AT users then lose the boundary).

## Accessibility contract

- **Guarantees:** `aria-orientation` is emitted ONLY on a semantic separator
  (`role="separator"`); it is omitted on a decorative one (`role="none"`), where
  `aria-orientation` is invalid.
- **You supply:** `decorative: false` when the divide conveys grouping; otherwise
  the default decorative treatment is correct.
