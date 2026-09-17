# NumberInput

Numeric input with browser spin buttons hidden and consistent focus styling. Not what `f.number_field` renders — `UI::FormBuilder#number_field` renders `UI::InputComponent` with `type: "number"`, not this component. Reach for `ui :number_input` when composing a field by hand outside a `form_with`, or as the control a host form builder's own `number_field` override chooses to wrap.

## Installation

```bash
rails g modelrails_ui:add number_input
```

Creates `app/components/ui/number_input_component.rb`.

## Usage

```erb
<%= ui :number_input, name: "quantity" %>
```

## Bounds and step

```erb
<%= ui :number_input, name: "quantity", min: 1, max: 99, step: 1, value: 1 %>
```

## In a form

```erb
<%= ui :form_field, label: "Quantity" do %>
  <%= ui :number_input, name: "order[quantity]", id: "order_quantity",
                        min: 1, max: 100, value: @order.quantity %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `min` | Numeric | `nil` | Minimum allowed value |
| `max` | Numeric | `nil` | Maximum allowed value |
| `step` | Numeric | `nil` | Increment/decrement step |
| `value` | Numeric | `nil` | Initial value |
| `**html_attrs` | Hash | — | Forwarded to the `<input type="number">` element |

## When to use

- You need a numeric entry (quantity, price, age) with `min` / `max` / `step`
  constraints, outside a `form_with` block.
- You are assembling a custom form builder that wraps this component yourself.

## When not to use

- You are inside a `form_with` block — call `f.number_field :attr` instead so the
  label, error message, and ARIA associations come for free.
- You need a slider with a visible range — use `ui :range`.

## Accessibility contract

- **Guarantees:** AAA border and focus-ring tokens, a `min-h-[var(--form-input-height)]`
  44 px touch target, an `id` always emitted so an external `<label for=...>` can
  target it, `aria-invalid="true"` when `invalid: true`, `aria-describedby` wired
  when `describedby:` is supplied, and `required` + `aria-required="true"` when
  `required: true`.
- **You supply (when standalone):** a visible `<label>` associated via `for:/id:`,
  and a `name:` attribute. The form builder supplies both automatically.

The WebKit spin-buttons are intentionally hidden (`[appearance:textfield]` +
`::-webkit-*-spin-button`); there are NO custom +/- stepper buttons, so the only
interactive target is the field itself (held at the 44px floor above). With no
variant axis (single appearance) there is also no `coerce_variant` fail-loud guard
here, unlike the enum-driven components (alert, button).
