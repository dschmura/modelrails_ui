# Chip group

A multi-select group of chips backed by real checkboxes. The selection posts with
the form natively — there is no client-side state, so there is nothing that can
disagree with what will actually be submitted.

## Installation

```bash
bin/rails g modelrails_ui:add chip_group
```

## Usage

```erb
<%= ui :chip_group, name: "prefs[days]", label: "Active days",
       items: [
         { value: "mon", label: "Mon", aria_label: "Monday" },
         { value: "tue", label: "Tue", aria_label: "Tuesday", checked: true }
       ] %>
```

Persist each change by hanging your own auto-submit controller off the inputs:

```erb
<%= ui :chip_group, name: "prefs[days]", label: "Active days", items: days,
       data: { controller: "auto-submit" } %>
```

## chip_group or toggle_group?

They look alike and are not interchangeable.

| | `chip_group` | `toggle_group` |
|---|---|---|
| Control | real `<input type="checkbox">` | `<button aria-pressed>` |
| Form | posts natively | client state only |
| Reach for it when | the selection is **data** the server stores | the selection changes the **view**, like a filter or a text-style toggle |

If the choice survives a page reload, it is a `chip_group`.

## The empty sentinel

Unchecking every chip otherwise submits **nothing** for that key, and the server
reads "no change" where the user meant "none" — the classic checkbox-array bug. A
hidden `<input value="">` keeps the key present, so strip the blank server-side:

```ruby
Array(params.dig(:prefs, :days)).reject(&:blank?)
```

Pass `include_hidden: false` if your form already carries its own.

## Abbreviated chips

`aria_label:` is the spoken name when the visible text is an abbreviation — a chip
reading "Mon" that announces "Monday". Omit it whenever the label is already a
whole word; an empty `aria-label` would strip the accessible name entirely, which
is worse than no override.

## API

| Option | Type | Default | Description |
|---|---|---|---|
| `name` | String | required | Field name; `[]` is appended if you leave it off |
| `items` | Array | `[]` | `{ value:, label:, aria_label?:, checked?:, disabled?: }` |
| `label` | String | `nil` | The group's accessible name |
| `labelledby` | String | `nil` | Point at a visible heading instead of `label:` |
| `invalid` | Boolean | `false` | Sets `aria-invalid="true"` on the group |
| `describedby` | String | `nil` | Link the group to a hint or error element |
| `include_hidden` | Boolean | `true` | Emit the empty sentinel |

Any other attribute passes through to the group, but `role` and the `aria-*`
attributes above are applied last and cannot be overridden — they are the
component's contract, not styling.

## Accessibility contract

- **Guarantees:** a `role="group"` with an accessible name; every chip is a real
  focusable checkbox, `sr-only` rather than `hidden`, so the group is reachable and
  operable by keyboard with no key handling of our own; each chip meets the 44px
  target floor (WCAG 2.5.5); the checked and focus states key off the input's own
  state via `has-[]`, so what you see is what will post; focus is an offset
  **outline**, never a ring — a ring is clipped by an `overflow:hidden` ancestor and
  vanishes in forced-colors mode (2.4.7) — and it is scoped to `:focus-visible`, so
  a pointer press does not paint one.
- **You supply:** a group `label:` or `labelledby:`, an `aria_label:` on any chip
  whose visible text is an abbreviation, and on error `invalid:` plus
  `describedby:` pointing at the element holding the message.
