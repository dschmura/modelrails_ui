# Combobox

Searchable select with a text input that filters the option list as the user types.
Filtering and keyboard navigation live in the `combobox` Stimulus controller shipped
alongside this component.

Requires `combobox_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add combobox
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

## When to use

- You need a single-choice control over a long, known list where free-text
  filtering beats scrolling a native `<select>`.

## When not to use

- The list is short and needs no search — use a native `select`.
- It's a keyboard-first launcher for *actions* (the ⌘K pattern) — use `command`.

## Accessibility contract

- **Guarantees:** the text input is a `role="combobox"` with `aria-expanded`,
  `aria-controls` (→ the list) and `aria-autocomplete="list"`, named by an i18n
  `aria-label` (override via `label:`). The popup is a named `role="listbox"`;
  each option is a `role="option"` with `aria-selected`. The controller tracks
  the highlighted option via `aria-activedescendant` (DOM focus stays on the
  input — ↑/↓/Home/End move the active option, Enter selects it, Escape closes).
  The input and options carry the AAA `focus-ring`; the empty state is an i18n
  live region.
- **You supply:** `name:` (hidden-field name), `options:` (array of
  `{ value:, label: }`), optional `value:` (pre-selected), `placeholder:`,
  `label:` (accessible name), and `size:`.

## Sizes

`sm` · `md` · `lg` — the input height.
