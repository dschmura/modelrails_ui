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

A **typeable text input** is the primary control; the calendar button beside it is
the secondary one. A hidden input holds the canonical value, so a caller reads one
value whichever way it was set.

Typing commits on **blur or Enter** — never per keystroke, which would rewrite the
box under someone still typing. On commit the value is parsed, bound-checked,
stored as ISO in the hidden input, and written back into the box in the display
format. Picking a day in the calendar does the same thing from the other side and
syncs the text.

Enter commits without submitting the surrounding form, so a date field inside a
filter form applies the date rather than sending the form.

## Typing a date

A date you already know should not require walking a month grid to reach — that is
slower for everyone and a real barrier with a screen reader or a switch.

Accepted, whatever `format:` says:

| Input | Parsed as |
|---|---|
| `2026-09-03` | ISO — always accepted, since it is what the hidden input stores |
| `2026-9-3` | ISO, unpadded |
| `9/3/2026` | M/D/YYYY |
| `September 3, 2026` | month name, from the browser's own locale data |

Three outcomes, each explicit:

- **Empty** clears the stored value.
- **A good date** is stored and normalised back into the box.
- **A bad one** — unparseable, a date that does not exist like `2026-02-31`, or
  outside `min:`/`max:` — sets `aria-invalid="true"`, announces why in the field's
  live region, and **changes nothing that was stored**. The text stays for
  correction: silently reverting what someone typed is how a field loses trust.

`min:`/`max:` are enforced on typed values as well as in the grid. A bound the
calendar honours would be worthless if typing walked straight past it.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | String | `nil` | Form field name for the hidden input |
| `value` | Date | `nil` | Initially selected date |
| `label` | String | `nil` | The field caption / popover name; defaults to an i18n string |
| `placeholder` | String | `"Pick a date"` | Placeholder for the text input |
| `min` | Date | `nil` | Earliest selectable date |
| `max` | Date | `nil` | Latest selectable date |
| `format` | Symbol | `:long` | `:long`, `:short`, or `:iso` — how the value is DISPLAYED in the text input and named in the format hint (fail-loud on an unknown key). It does not restrict what may be typed; see [Typing a date](#typing-a-date) |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- A form needs a single date and a month-grid affordance is friendlier than a bare
  `<input type="date">`.

## When not to use

- You only need a native date field with no custom calendar — use `input` with
  `type: "date"`. Two of those are a perfectly good range control.
- You need a range (two bounds) — compose two pickers or a range calendar.

## Accessibility contract

- **Guarantees:** the caption is a real `<label for>` bound to the **text input** —
  a `<label for>` may only name a labelable element, and pointing it at a `<button>`
  named nothing while leaving the typed control unlabelled; a typeable path to any
  date, so the month grid is never the only way in; a real `<button>` trigger with
  `aria-haspopup="dialog"`, `aria-expanded` (kept in sync by the controller) and
  `aria-controls` → the popover id, named for what it *does* (`Open calendar for
  <label>`) since the caption already names the field beside it; the popover is a
  `role="dialog"` named by `label:`; the format hint and an error region are wired
  via `aria-describedby`, and that region is present and **empty from first render**
  so an announcement lands (a live region inserted already carrying its text is
  dropped by assistive tech); a rejected value sets `aria-invalid="true"`; the
  decorative calendar icon is `aria-hidden`; Escape and outside-click close the
  popover and return focus to the trigger. Input and trigger carry the offset
  `focus-ring` (never a box-shadow ring), and the icon-only trigger holds the AAA
  44px target floor.
- **You supply:** an optional `label:` (the field caption / popover name; defaults
  to an i18n string) and a `name:` if the value must post back.
- `min/max:` Date bounds passed to the calendar
