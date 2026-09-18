# Label

Accessible form label that pairs with an input via `for:`. Binding it this way means clicking the caption focuses the control and a screen reader announces the control's name.

## Installation

```bash
rails g modelrails_ui:add label
```

Creates `app/components/ui/label_component.rb`.

## Usage

```erb
<%# Positional text %>
<%= ui :label, "Email address", for: "email" %>

<%# Keyword label %>
<%= ui :label, label: "Password", for: "password" %>

<%# Block content (for rich labels) %>
<%= ui :label, for: "terms" do %>
  I accept the <a href="/terms">terms of service</a>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | String | `nil` | Label text — positional or `label:` keyword |
| `for` | String | `nil` | The `id` of the associated input element |
| `**html_attrs` | Hash | — | Forwarded to the `<label>` element |

## When to use

- You're captioning any form control (`input`, `textarea`, `select`, the
  form-control components). Pair `for:` with the control's `id`.

## When not to use

- The control already self-labels (e.g. `checkbox`/`radio_group` render their
  own `<label>`) — don't wrap them a second time.

## Accessibility contract

- **Guarantees:** AAA-contrast caption text (`text-text-body`, a 7:1 token — no
  raw Tailwind color), and a `for=` association when you supply `for:`. A
  `required:` marker is a *decorative* `*` (`aria-hidden`): it never carries the
  requirement, which belongs on the input as `aria-required`/`required`.
- **You supply:** the caption text (arg or block) and, to bind it, the control's
  `id` via `for:`.

A label is not an input: it has NO `invalid`/`aria-invalid`/`describedby` axis.
