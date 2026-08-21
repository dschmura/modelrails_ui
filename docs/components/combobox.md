# Combobox

Searchable select with a text input that filters the option list as the user types.

Requires `combobox_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g view_primitives:add combobox
```

Creates `app/components/ui/combobox_component.rb`.

## Usage

```erb
<%= ui :combobox,
       name: "country",
       options: [
         { value: "us", label: "United States" },
         { value: "ca", label: "Canada" },
         { value: "mx", label: "Mexico" }
       ] %>
```

## Pre-selected value

```erb
<%= ui :combobox,
       name: "country",
       value: "ca",
       options: [
         { value: "us", label: "United States" },
         { value: "ca", label: "Canada" },
         { value: "mx", label: "Mexico" }
       ] %>
```

## Custom placeholder

```erb
<%= ui :combobox,
       name: "category",
       placeholder: "Pick a category…",
       options: [
         { value: "news",   label: "News" },
         { value: "events", label: "Events" }
       ] %>
```

## How it works

The component renders a hidden `<input type="hidden">` (submitted with the form) and a visible text input for filtering. Selecting an option updates the hidden input's value and closes the dropdown. When no options match the search term, a "No results." message is displayed.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | String | required | Form field name for the hidden input |
| `options` | Array | `[]` | Array of `{ value:, label: }` hashes |
| `value` | String | `nil` | Currently selected value |
| `placeholder` | String | `"Select..."` | Text shown when nothing is selected |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## Placement

The panel is placed by CSS anchor positioning (`position: fixed`, tethered to the field
by `anchor-name`/`position-anchor`) and is promoted to the browser's **top layer** while
open. That lets it escape a stacking context — a `sticky` header or a `backdrop-blur`
navbar traps a `z-50` panel inside it, and no z-index fixes that from within.

Browsers without anchor positioning fall back to `absolute` offsets and are deliberately
**not** promoted, since the top layer would resolve those offsets against the viewport
rather than the trigger.
