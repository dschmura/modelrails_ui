# Calendar

Month-grid calendar with selectable days, today highlight, min/max bounds, and prev/next navigation.

Requires `calendar_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add calendar
```

Creates `app/components/ui/calendar_component.rb`.

## Usage

```erb
<%# Standalone (no form) %>
<%= ui :calendar %>

<%# With selected date %>
<%= ui :calendar, selected: Date.today %>
```

## With a form

Pass `name:` to add a hidden input that submits the selected date in ISO 8601 format (`YYYY-MM-DD`).

```erb
<%= form_with model: @booking do |f| %>
  <%= ui :calendar, name: "booking[date]", selected: @booking.date %>
  <%= ui :button, "Reserve", type: "submit" %>
<% end %>
```

## Specific month

```erb
<%= ui :calendar, month: Date.new(2025, 12, 1) %>
```

## Date bounds

```erb
<%= ui :calendar,
       name: "availability[date]",
       min: Date.today,
       max: Date.today + 90 %>
```

Days outside `min`/`max` are rendered as disabled.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selected` | Date | `nil` | Highlighted selected day |
| `month` | Date | `Date.today` | Month displayed on load |
| `name` | String | `nil` | Form field name for the hidden input |
| `min` | Date | `nil` | Earliest selectable date (earlier days are disabled) |
| `max` | Date | `nil` | Latest selectable date (later days are disabled) |
| `weekday_start` | Symbol | `:sunday` | `:sunday` or `:monday` — first column of the grid |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- You need an inline month picker the user navigates by mouse OR keyboard.

## When not to use

- You only need a native date field — use `<input type="date">` (the OS picker
  is already accessible and localized).

## Accessibility contract

- **Guarantees:** the month is a `role="grid"` with an accessible name (the
  month/year caption); the weekday header is a `role="row"` of
  `role="columnheader"` cells; each day is a `role="gridcell"` wrapping a real
  `<button>` whose accessible name is the full localized date ("15 June 2026");
  the selected day carries `aria-selected="true"`, today carries
  `aria-current="date"`; exactly one day is in the tab order (roving tabindex)
  and the controller moves focus with ←/→ (day), ↑/↓ (week), Home/End (row
  ends), PageUp/PageDown (month); prev/next are i18n-labelled `<button>`s (not
  icon-only-unlabelled); and every control carries the AAA offset `focus-ring`.
- **You supply:** `selected:`/`month:` Dates and optional `min:`/`max:` bounds.
