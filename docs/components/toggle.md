# Toggle

Pressable button that tracks an on/off state via `aria-pressed` and a Stimulus controller.

Requires `toggle_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add toggle
```

Creates `app/components/ui/toggle_component.rb`.

## Usage

```erb
<%# Label as positional argument %>
<%= ui :toggle, "Bold" %>

<%# Pre-pressed %>
<%= ui :toggle, "Italic", pressed: true %>

<%# Block content (e.g. icon + label) %>
<%= ui :toggle do %>
  <svg ...></svg> Bold
<% end %>
```

## Sizes

| Size | Description |
|------|-------------|
| `default` | `h-9 min-w-9` |
| `sm` | `h-8 min-w-8` |
| `lg` | `h-10 min-w-10` |

```erb
<%= ui :toggle, "B", size: :sm %>
<%= ui :toggle, "B", size: :default %>
<%= ui :toggle, "B", size: :lg %>
```

`default` · `sm` · `lg` — all rendered >=44px tall (the AAA target-size floor).

## With a value

Use `value:` when toggling options in a group or form:

```erb
<%= ui :toggle, "Left",   value: "left" %>
<%= ui :toggle, "Center", value: "center" %>
<%= ui :toggle, "Right",  value: "right" %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | `nil` | Button text — positional or `label:` keyword, alternative to block |
| `pressed` | Boolean | `false` | Initial pressed state |
| `size` | Symbol | `:default` | `:default`, `:sm`, or `:lg` |
| `value` | String | `nil` | Value attribute passed to the `<button>` |
| `**html_attrs` | Hash | — | Forwarded to the `<button>` element |

## When to use

- You need a single, instantly-applied on/off action with no separate submit.

## When not to use

- It's a form field whose value posts on submit — use a checkbox/switch input.

## Accessibility contract

- **Guarantees:** a real interactive element with `aria-pressed` reflecting the
  pressed state, and a 44px-minimum touch target at every size (AAA 2.5.5).
- **You supply:** an accessible name — visible text/content, or an `aria-label:`
  for an icon-only toggle — and a valid `size` (an unknown one raises in development).
