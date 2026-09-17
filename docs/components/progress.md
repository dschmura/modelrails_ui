# Progress

Horizontal progress bar with accessible ARIA attributes.

## Installation

```bash
rails g modelrails_ui:add progress
```

Creates `app/components/ui/progress_component.rb`.

## Usage

```erb
<%# 40% complete %>
<%= ui :progress, value: 40 %>

<%# Custom max %>
<%= ui :progress, value: 3, max: 10 %>

<%# Custom width %>
<%= ui :progress, value: 75, class: "w-64" %>
```

## Behaviour

- `value` is clamped between `0` and `max`
- The inner bar width is calculated as `(value / max) * 100%`
- Renders with `role="progressbar"` and `aria-valuenow` / `aria-valuemin` / `aria-valuemax`

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | Numeric | `0` | Current progress value |
| `max` | Numeric | `100` | Maximum value |
| `**html_attrs` | Hash | — | Forwarded to the outer track `<div>` |

## When to use

- You can express progress as a value between 0 and `max` (upload %, steps done).

## When not to use

- The wait is indeterminate — use `spinner`.
- The bar has no accessible name and no nearby text — pass `label:` so screen
  readers can announce what is progressing.

## Accessibility contract

- **Guarantees:** `role="progressbar"` with `aria-valuenow`/`min`/`max`, the
  value clamped to 0–100% so a bad value never overflows the track.
- **You supply:** `label:` when no visible text names the bar (it becomes the
  `aria-label` / accessible name).
