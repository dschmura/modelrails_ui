# DatePicker

Trigger button that opens a Calendar popover for selecting a date. Submits the chosen date via a hidden input.
The button is the accessible control (it carries the selected-date label);
the calendar grid itself is owned by `UI::CalendarComponent` (this component
does not re-implement it).

Requires `date_picker_controller.js` and `calendar_controller.js` (both copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add date_picker
```

Creates `app/components/ui/date_picker_component.rb`.

## Usage

```erb
<%= ui :date_picker, name: "event[date]" %>
```

## With initial date

```erb
<%= ui :date_picker, name: "event[date]", value: @event.date %>
```

## Custom placeholder

```erb
<%= ui :date_picker, name: "due_at", placeholder: "Choose a due date" %>
```

## Date bounds

```erb
<%= ui :date_picker,
       name: "appointment[date]",
       min: Date.today,
       max: Date.today + 60 %>
```

## How it works

The trigger button displays the selected date formatted as "Month D, YYYY". On click, a Calendar popover opens. When the user picks a day, the `calendar:change` event updates the trigger label and the hidden input value, then closes the popover.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | String | `nil` | Form field name for the hidden input |
| `value` | Date | `nil` | Initially selected date |
| `label` | String | `nil` | The field caption / popover name; defaults to an i18n string |
| `placeholder` | String | `"Pick a date"` | Text shown when no date is selected |
| `min` | Date | `nil` | Earliest selectable date |
| `max` | Date | `nil` | Latest selectable date |
| `format` | Symbol | `:long` | `:long`, `:short`, or `:iso` — Ruby strftime for the initial label AND the format hint shown to the user (fail-loud on an unknown key) |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- A form needs a single date and a month-grid affordance is friendlier than a bare
  `<input type="date">`.

## When not to use

- You only need a native date field with no custom calendar — use `input` with
  `type: "date"`.
- You need a range (two bounds) — compose two pickers or a range calendar.

## Accessibility contract

- **Guarantees:** a real `<button>` trigger with `aria-haspopup="dialog"`,
  `aria-expanded` (kept in sync by the controller), and `aria-controls` → the
  popover id; the popover is a `role="dialog"` named by `label:`; a visible caption
  `<label>`-style heading and a format hint wired via `aria-describedby`; the
  decorative calendar icon is `aria-hidden`; Escape and outside-click close the
  popover and return focus to the trigger. The trigger carries the offset
  `focus-ring` (never a box-shadow ring).
- **You supply:** an optional `label:` (the field caption / popover name; defaults
  to an i18n string) and a `name:` if the value must post back.
- `min/max:` Date bounds passed to the calendar
