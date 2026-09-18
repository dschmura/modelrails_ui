# Select

Native `<select>` element with consistent border, focus, and disabled styles.

## Installation

```bash
rails g modelrails_ui:add select
```

Creates `app/components/ui/select_component.rb`.

## Usage

```erb
<%# Array of strings (value = label) %>
<%= ui :select, name: "country",
       options: ["United States", "Canada", "Mexico"] %>

<%# Array of [value, label] pairs %>
<%= ui :select, name: "country",
       options: [["us", "United States"], ["ca", "Canada"], ["mx", "Mexico"]] %>

<%# Hash (value => label) %>
<%= ui :select, name: "country",
       options: { "us" => "United States", "ca" => "Canada", "mx" => "Mexico" } %>
```

## Pre-selected value

```erb
<%= ui :select, name: "role",
       options: [["admin", "Admin"], ["editor", "Editor"], ["viewer", "Viewer"]],
       selected: "editor" %>
```

## Blank option

```erb
<%= ui :select, name: "category",
       options: ["News", "Events", "Guides"],
       include_blank: true %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `options` | Array or Hash | `[]` | Strings, `[value, label]` pairs, or `{ value => label }` hash |
| `selected` | String | `nil` | Value of the pre-selected option |
| `include_blank` | Boolean | `false` | Prepends an empty `<option>` |
| `**html_attrs` | Hash | — | Forwarded to the `<select>` element |

## When to use

- You need a single-choice dropdown from a known, finite list of options.

## When not to use

- The control needs free-text entry or async search — that's a combobox, not a
  native `<select>`.

## Accessibility contract

- **Guarantees:** AAA border/focus-ring tokens, an `id` ALWAYS emitted on the
  `<select>`, `aria-invalid="true"` when `invalid: true`, and `aria-describedby`
  wired when `describedby:` is supplied.
- **You supply:** the visible label as an EXTERNAL `<label for="<id>">` — unlike
  checkbox, this component does NOT bundle a label (a `<select>` is conventionally
  labeled by a separate form label). On error, pass `invalid: true` and point
  `describedby:` at the error element's id.

## Customizable Select (progressive enhancement)

In browsers that support `appearance: base-select` (Chromium, Safari 26+) the
`.ui-select` hook restyles the OPEN picker to match the design system — the same
overlay/border/shadow as the combobox, a tinted checkmark on the selected row,
and a flipping picker-icon. Everywhere else it falls back to the untouched native
control. Pure CSS + one class; no JS, no markup change. See `modelrails_ui.css`.

No fail-loud guard — there's no enum axis to validate.
