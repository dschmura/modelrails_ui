# Checkbox

Styled checkbox input with optional inline label.

## Installation

```bash
rails g modelrails_ui:add checkbox
```

Creates `app/components/ui/checkbox_component.rb`.

## Usage

```erb
<%# Standalone (no label) %>
<%= ui :checkbox, name: "agreed", id: "agreed" %>

<%# With inline label %>
<%= ui :checkbox, name: "agreed", id: "agreed", label: "I agree to the terms" %>
```

## Checked by default

```erb
<%= ui :checkbox, name: "subscribe", id: "subscribe",
                  label: "Subscribe to newsletter", checked: true %>
```

## States

```erb
<%# Disabled %>
<%= ui :checkbox, name: "locked", id: "locked", label: "Not available", disabled: true %>

<%# Invalid %>
<%= ui :checkbox, name: "agreed", id: "agreed", "aria-invalid": "true" %>
```

## In a form builder

```erb
<%= form_with model: @user do |f| %>
  <%= ui :checkbox, name: "user[newsletter]", id: "user_newsletter",
                    label: "Subscribe to newsletter",
                    checked: @user.newsletter %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | `nil` | Text shown next to the checkbox in a `<label>` |
| `checked` | Boolean | `false` | Pre-checked state |
| `**html_attrs` | Hash | — | Forwarded to the `<input type="checkbox">` element |

## Indeterminate (tri-state)

`indeterminate: true` marks a "some children selected" parent. There is no HTML attribute
for it — `indeterminate` is a DOM property — so the component ships an `indeterminate`
Stimulus controller that sets it on connect and clears it once the user acts.

```erb
<%= render(UI::CheckboxComponent.new(label: "Select all", indeterminate: true, name: "all")) %>
```

It deliberately does **not** also set `checked`: a partially-selected parent must not
submit as checked. Without JS the box renders unchecked, which is the honest degradation.

## When to use

- A single on/off choice tied to a label: "Accept terms", "Remember me",
  "Email me about updates".

## When not to use

- It's an immediate-effect setting toggle with no form submit — use `switch`.
- You have a mutually-exclusive set of options — use `radio_group`.

## Accessibility contract

- **Guarantees:** a labelled, keyboard-operable checkbox with an AAA focus ring.
  The control always carries an `id` (falling back from `id` → sanitized `name`
  → object-based id) so the `<label for=...>` association never breaks, and the
  clickable label provides the larger pointer target (AAA 2.5.5 target-size).
- **You supply:** a `label` and, on error, `invalid: true` (sets `aria-invalid`)
  plus `describedby:` pointing at the error message's id.

No variant axis (single appearance), so there is no `coerce_variant` fail-loud
guard here — unlike the enum-driven components (alert, button).
