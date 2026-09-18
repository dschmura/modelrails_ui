# RadioGroup

Group of radio inputs rendered from an array of items.

## Installation

```bash
rails g modelrails_ui:add radio_group
```

Creates `app/components/ui/radio_group_component.rb`.

## Usage

```erb
<%= ui :radio_group, name: "plan",
       items: [
         { value: "free",  label: "Free" },
         { value: "pro",   label: "Pro" },
         { value: "team",  label: "Team", checked: true }
       ] %>
```

## Pre-selected item

Mark one item with `checked: true`:

```erb
<%= ui :radio_group, name: "color",
       items: [
         { value: "red",   label: "Red" },
         { value: "green", label: "Green", checked: true },
         { value: "blue",  label: "Blue" }
       ] %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | String | required | Shared `name` attribute for all radio inputs |
| `items` | Array | `[]` | Array of `{ value:, label:, checked: }` hashes |
| `**html_attrs` | Hash | — | Forwarded to the wrapper `<div role="radiogroup">` |

### Item hash

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `value` | String | Yes | Submitted value |
| `label` | String | Yes | Visible label text |
| `checked` | Boolean | No | Pre-selects this option |

## When to use

- You need a single-choice control over a small, fixed set of options
  (a billing plan, a visibility level, a notification cadence).

## When not to use

- There are many options or they're loaded dynamically — use `ui :select`.
- The choice is binary on/off — use `ui :toggle` or `ui :checkbox`.

## Accessibility contract

- **Guarantees:** the group exposes an accessible name (`aria-label` from `label:`,
  or `aria-labelledby` from `labelledby:`), each option's `<label for>` matches its
  input `id`, and on error the group carries `aria-invalid="true"` plus an
  `aria-describedby` link to the error/hint element.
- **You supply:** a group `label:` (or `labelledby:`), `items:` as
  `[{ value:, label:, checked?:, disabled?: }]`, and on error `invalid:` +
  `describedby:` pointing at a sibling element that holds the message.

No fail-loud guard — there is no enum axis to validate.
