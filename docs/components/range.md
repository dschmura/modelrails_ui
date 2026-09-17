# Range

Styled range slider (`<input type="range">`) with a custom thumb and focus ring.

## Installation

```bash
rails g modelrails_ui:add range
```

Creates `app/components/ui/range_component.rb`.

## Usage

```erb
<%= ui :range, name: "volume" %>
```

## Custom bounds

```erb
<%= ui :range, name: "price", min: 0, max: 500, step: 10, value: 100 %>
```

## In a form

```erb
<%= ui :form_field, label: "Volume" do %>
  <%= ui :range, name: "settings[volume]", id: "volume", min: 0, max: 100, value: 50 %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `min` | Numeric | `0` | Minimum value |
| `max` | Numeric | `100` | Maximum value |
| `step` | Numeric | `1` | Increment step |
| `value` | Numeric | `nil` | Initial value |
| `**html_attrs` | Hash | — | Forwarded to the `<input type="range">` element |

## When to use

- The user picks a value from a continuous, bounded numeric range and an
  approximate position is acceptable (volume, brightness, zoom).

## When not to use

- An exact value matters or the range is unbounded — use a number input.
- The choice is a small set of discrete options — use a select or radio_group.

## Accessibility contract

- **Guarantees:** AAA accent/focus-ring tokens, an `id` ALWAYS emitted on the
  `<input>`, `aria-invalid="true"` when `invalid: true`, and `aria-describedby`
  wired when `describedby:` is supplied. The thumb target size is UA-controlled
  (native range), so the app's axe gate is the AAA target-size authority here.
- **You supply:** the visible label as an EXTERNAL `<label for="<id>">` — a native
  slider is conventionally labeled by a separate form label. On error, pass
  `invalid: true` and point `describedby:` at the error element's id.

## Optional value readout (`show_value: true`)

By default this renders a bare native slider. Pass `show_value: true` to also
render an associated `<output for="<id>">` that mirrors the current value. The
`<output>` is an implicit `role="status"` live region, kept in sync with the
slider by the tiny `range` Stimulus controller (`range_controller.js`): the
input carries `data-action="input->range#sync"` and both elements are
`data-range-target`s. The SSR text starts at `value:` (or the native midpoint
when `value:` is nil) and the controller resyncs on connect.

No fail-loud guard — there's no enum axis to validate.
