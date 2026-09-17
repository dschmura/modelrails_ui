# Rating

Read-only star rating display. For an *interactive* score the user sets, use
`rating_input` instead.

## Installation

```bash
rails g modelrails_ui:add rating
```

Creates `app/components/ui/rating_component.rb`.

## Usage

```erb
<%= ui :rating, value: 4 %>
```

## Custom max

```erb
<%# 7 out of 10 %>
<%= ui :rating, value: 7, max: 10 %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | Numeric | `0` | Number of filled stars. Clamped to `0..max`, rounded to nearest integer. |
| `max` | Integer | `5` | Total number of stars |
| `**html_attrs` | Hash | — | Forwarded to the wrapper `<div>` |

The wrapper renders with `role="img"` and an `aria-label` of `"Rating: N out of M"`.

## When to use

- You're displaying a fixed score the user can't change (a product's average
  rating, a past review's stars).

## When not to use

- The user picks the value — use `ui :rating_input` (labelled star buttons +
  a hidden input).

## Accessibility contract

- **Guarantees:** the whole control is a single labelled graphic
  (`role="img"` + an i18n `aria-label`, e.g. "3 out of 5 stars") so AT
  announces the *value*, not eleven mystery icons — color-filled stars alone
  carry no accessible meaning (a 1.1.1 / 1.4.1 failure). The individual star
  glyphs are decorative (`aria-hidden="true"`). Filled stars use the AAA-tuned
  semantic `text-warning-icon` token (was raw `text-yellow-400`); stars are
  GRAPHIC icons (WCAG 1.4.11 → 3:1, not 7:1 text) and the amber warning token
  clears 3:1. The app 0b axe spec verifies the graphic contrast in a real
  browser.
- **You supply:** the `value:` to display and the `max:` star count.
