# InputOtp

One-time-password digit input group. Renders N individual single-character inputs that auto-advance on entry and support paste. Each cell is `inputmode="numeric"` + `autocomplete="one-time-code"` so mobile keyboards stay numeric and the browser / OS can autofill an SMS code.

Requires `input_otp_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add input_otp
```

Creates `app/components/ui/input_otp_component.rb`.

## Usage

```erb
<%= ui :input_otp, name: "otp" %>
```

By default this renders 6 digit cells.

## Custom length

```erb
<%= ui :input_otp, name: "pin", length: 4 %>
```

## With separator

Pass an integer to add a separator character before a specific cell index:

```erb
<%# Separator before index 3 → renders "XXX - XXX" %>
<%= ui :input_otp, name: "otp", length: 6, separator: 3 %>

<%# Custom character and position %>
<%= ui :input_otp, name: "otp", length: 6, separator: { 3 => "—" } %>
```

## In a form

```erb
<%= form_with url: verify_path do %>
  <%= ui :input_otp, name: "otp", length: 6 %>
  <%= ui :button, "Verify", type: "submit" %>
<% end %>
```

Each digit is submitted as `otp[0]`, `otp[1]`, … `otp[5]`. The first cell sets `autocomplete="one-time-code"` for browser autofill.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `length` | Integer | `6` | Number of digit cells |
| `name` | String | `"otp"` | Base field name; cells submit as `name[0]`, `name[1]`, etc. |
| `separator` | Integer or Hash | `nil` | Position (Integer) or `{ position => char }` for a visual separator |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- You are confirming a code delivered out of band (SMS / email / authenticator)
  on a verification screen, posted as `name[0]…name[N-1]` inside a `form_with`.

## When not to use

- The secret is a free-form password — use `ui :input, type: "password"`.
- The value is a single field the user reads off, not digit-by-digit — a plain
  `ui :input` is simpler and announces better.

## Accessibility contract

- **Guarantees:** the cell group exposes an accessible name (`role="group"` +
  i18n `aria-label`, default "One-time passcode") so a screen-reader user knows
  what the row of fields is for; each cell carries a per-digit i18n label
  ("Digit N of total") so position-in-sequence is announced; and every cell is
  `inputmode="numeric"` + `autocomplete="one-time-code"` for numeric keypads and
  OS autofill. Focus is the AAA offset `focus-ring` (never a clipped box-shadow
  ring). `length` must be a positive integer — a non-positive value fails loud.
- **You supply:** the field `name:` (cells post as `name[0]…name[length-1]`),
  the digit `length:`, and an optional `separator:`.
