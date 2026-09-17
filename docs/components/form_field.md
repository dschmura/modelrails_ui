# FormField

Wrapper that composes a label, any input component, an optional hint, and an error message into a consistent vertical layout.

## Installation

```bash
rails g modelrails_ui:add form_field
```

Creates `app/components/ui/form_field_component.rb`.

## Usage

```erb
<%= ui :form_field, label: "Email" do %>
  <%= ui :input, type: "email", name: "user[email]", id: "user_email" %>
<% end %>
```

## With hint and error

```erb
<%= ui :form_field,
       label: "Username",
       hint:  "Letters and numbers only.",
       error: @user.errors[:username].first do %>
  <%= ui :input, name: "user[username]", id: "user_username",
                 value: @user.username,
                 "aria-invalid": @user.errors[:username].any? %>
<% end %>
```

Both the hint and error render; `aria-describedby` names the error first so assistive tech announces the error.

## Required field

```erb
<%= ui :form_field, label: "Password", required: true do %>
  <%= ui :input, type: "password", name: "user[password]", id: "user_password" %>
<% end %>
```

A red asterisk (`*`) is appended to the label when `required: true`.

## Composing with other inputs

FormField works with any input component:

```erb
<%# With select %>
<%= ui :form_field, label: "Country" do %>
  <%= ui :select, name: "user[country]", options: ["US", "CA", "MX"] %>
<% end %>

<%# With textarea %>
<%= ui :form_field, label: "Bio", hint: "Max 280 characters." do %>
  <%= ui :textarea, name: "user[bio]", id: "user_bio" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | `nil` | Label text shown above the input |
| `hint` | String | `nil` | Muted helper text shown below the input |
| `error` | String | `nil` | Red error message shown below the input |
| `required` | Boolean | `false` | Appends a red `*` to the label |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` wrapper |

## When to use

- You're composing a single labelled field by hand (a one-off form, or a control
  the form builder (`UI::FormBuilder`) doesn't cover). For model-backed forms,
  prefer the builder — it already does this wiring.

## Accessibility contract

- **Guarantees:** a `<label for=id>` bound to the control; hint/error rendered with
  ids `#{id}-hint`/`#{id}-error`; and `input_attrs` carrying `id` +
  `describedby` (**error-first**, then hint — `[error, hint]` — front-loading the
  correction for AT users now that the hint sits below the control) + `invalid`
  (on error) + `required`. The required marker is a decorative aria-hidden `*` on
  the Label — the caption never carries the requirement.
- **No live region:** the error `<p>` is plain markup, not `role="alert"`. A
  field-level live region never fires on a server-rendered response — the region
  has to exist before its content changes to announce anything. The focused
  `ErrorSummary` component is the actual announcement mechanism.
- **You supply:** the control inside the block, spread with `**f.input_attrs` so it
  adopts the field's id and aria wiring. Rendering a native (non-ViewComponent)
  control instead? Use `html_input_attrs`, which translates the same wiring into
  real `aria-*` attributes.
- **Id fallback:** without an explicit `id:`, the id is derived from `label` (so
  repeated renders of the same field agree, which Turbo morphing and HTML
  snapshot tests depend on) — pass explicit ids when two fields on one page share
  a label. `UI::FormBuilder` always supplies an id, so this only matters when
  composing a field by hand.
