# Timepicker

Trigger button that opens a clock popover with hour and minute spinners for selecting a time.
The button is the accessible control (it carries the selected-time label);
each spinbutton is a real `role="spinbutton"` whose `aria-valuenow`/
`aria-valuetext` the controller keeps in sync as the value steps.

Requires `timepicker_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add timepicker
```

Creates `app/components/ui/timepicker_component.rb`.

## Usage

```erb
<%= ui :timepicker, name: "event[starts_at]" %>
```

## With initial value

```erb
<%= ui :timepicker, name: "event[starts_at]", value: "14:30" %>
```

## 12-hour format

```erb
<%= ui :timepicker, name: "alarm[time]", format: :h12 %>
```

## Minute step

Common steps are 5, 15, and 30 minutes:

```erb
<%= ui :timepicker, name: "meeting[starts_at]", step: 15, value: "09:00" %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | String | `nil` | Form field name for the hidden input |
| `value` | String | `nil` | Initial time as `"HH:MM"` |
| `label` | String | `nil` | Visible trigger + popover accessible name (i18n default) |
| `format` | Symbol | `:h24` | `:h24` (24-hour) or `:h12` (12-hour with AM/PM); drives the hour spinbutton range AND the format hint shown to the user (fail-loud on an unknown key) |
| `step` | Integer | `1` | Minute increment, clamped to 1–60 |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- A form needs a single time-of-day and a stepper affordance is friendlier than a
  bare `<input type="time">`.

## When not to use

- You only need a native time field with no custom stepper — use `input` with
  `type: "time"`.
- You need a duration or a range (two bounds) — compose two pickers.

## Accessibility contract

- **Guarantees:** a real `<button>` trigger with `aria-haspopup="dialog"`,
  `aria-expanded` (kept in sync by the controller), `aria-controls` → the popover id,
  an i18n accessible name (`label:`) and a format hint wired via `aria-describedby`;
  the popover is a `role="dialog"` named by `label:`; the hour/minute/AM-PM fields
  are `role="spinbutton"` with `aria-valuemin`/`aria-valuemax`/`aria-valuenow`/
  `aria-valuetext` and an i18n `aria-label` announcing which unit they edit; the ▲/▼
  stepper buttons are decorative (`aria-hidden`, `tabindex=-1`) since the spinbutton
  inputs are the keyboard target; every focusable control carries the offset
  `focus-ring` (never a clipped box-shadow ring); the decorative clock icon is
  `aria-hidden`.
- **You supply:** an optional `label:` (the field caption / popover name; defaults to
  an i18n string) and a `name:` if the value must post back.
