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

## Form integration

Selecting an option dispatches a bubbling `change` event **on the hidden input**, so a form that submits on change hears a combobox selection the same way it hears every other control:

```erb
<%= form_with url: filters_path, method: :get,
              data: { controller: "search-form", action: "change->search-form#submit" } do %>
  <%= ui :combobox, name: "workspace", options: @workspace_options %>
<% end %>
```

The event has to be dispatched explicitly because the controller assigns the hidden input's value programmatically, and a programmatic assignment fires nothing on its own. Listen on the hidden input or on any ancestor — not on the visible text input, which only ever carries the typed filter text.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | String | required | Form field name for the hidden input |
| `options` | Array | `[]` | Array of `{ value:, label: }` hashes |
| `value` | String | `nil` | Currently selected value |
| `placeholder` | String | `"Select..."` | Text shown when nothing is selected |
| `input_id` | String | `"#{id}-input"` | Id of the visible text input (see below) |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

### Addressing the text input

`id:` names the outer `<div>`, not the text input — the input derives its own id
from it (`my-combobox` → `my-combobox-input`), so it can be targeted by a
`<label for>` and reached by Capybara's `fill_in` without enabling aria-label
matching:

```ruby
fill_in "my-combobox-input", with: "can"
```

Pass `input_id:` to name it yourself. The visible input deliberately has **no
`name`**: the hidden input carries the form value, and a name here would post
the typed label text alongside it.

## When to use

- You need a single-choice control over a long, known list where free-text
  filtering beats scrolling a native `<select>`.

## When not to use

- The list is short and needs no search — use a native `select`.
- It's a keyboard-first launcher for *actions* (the ⌘K pattern) — use `command`.

## Accessibility contract (WAI-ARIA APG combobox + listbox)

- **Guarantees:** the text input is a `role="combobox"` with `aria-expanded`,
  `aria-controls` (→ the list) and `aria-autocomplete="list"`, named by an i18n
  `aria-label` (override via `label:`). The popup is a named `role="listbox"`;
  each option is a `role="option"` with `aria-selected`. The controller tracks
  the highlighted option via `aria-activedescendant` (DOM focus stays on the
  input — ↑/↓/Home/End move the active option, Enter selects it, Escape closes).
  Options are `tabindex="-1"`, so Tab leaves the widget rather than walking the
  list, and focus leaving the widget by any route dismisses it; an option's
  `mousedown` is cancelled so a pointer selection keeps focus on the input and
  returns there once the panel closes.
  The input and options carry the AAA `focus-ring`. Filtering is announced: a
  visually hidden `role="status"` region sits on the wrapper — **outside** the
  panel, so it is in the accessibility tree from first render rather than being
  revealed with its text already in it — and the controller writes the remaining
  result count into it on every filter pass, or the empty message at zero matches.
  The visible empty state sits **beside** the listbox rather than inside it, so
  that at zero matches the listbox is hidden outright — an empty `role="listbox"`
  would advertise children it does not have. It is a visual affordance only; the
  status region is the single announcer, so nothing is spoken twice.
  The text input carries a per-instance `id` derived from the
  wrapper's, so a `<label for>` can point at the control a user actually types
  into.
- **You supply:** `name:` (hidden-field name), `options:` (array of
  `{ value:, label: }`), optional `value:` (pre-selected), `placeholder:`,
  `label:` (accessible name), and `size:`.

## Sizes

`sm` · `md` · `lg` — the input height.
