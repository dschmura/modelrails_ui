# SearchInput

Text input with a built-in search icon on the left. Renders `<input type="search">`.

## Installation

```bash
rails g modelrails_ui:add search_input
```

Creates `app/components/ui/search_input_component.rb`.

## Usage

```erb
<%= ui :search_input, name: "q" %>
```

## Custom placeholder

```erb
<%= ui :search_input, name: "q", placeholder: "Search products…" %>
```

## With Turbo form submission

```erb
<%= form_with url: search_path, method: :get, data: { turbo_frame: "results" } do %>
  <%= ui :search_input, name: "q", value: params[:q], autofocus: true %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `placeholder` | String | `"Search…"` | Placeholder text |
| `**html_attrs` | Hash | — | Forwarded to the `<input type="search">` element |

## When to use

- A standalone search / filter box: a list filter, a command palette trigger,
  a site-search field in a header.

## When not to use

- You are inside a `form_with` block — call `f.search_field :attr` so the label,
  error message, and ARIA associations come from the form builder for free.
- You need the full sortable/filterable table toolbar — use `data_table`, which
  embeds its own search control.

## Accessibility contract

- **Guarantees:** an accessible name on every instance. A placeholder is only a
  hint and is NOT an accessible name, so the control always carries an `aria-label`
  (defaulting to the i18n `modelrails_ui.search_input.label`). The magnifier icon
  is `aria-hidden` (decorative). The control sits at the AAA 44 px target floor
  (`h-11`, WCAG 2.5.5) with AAA border and focus-ring tokens.
- **You supply:** on error, `invalid: true` (sets `aria-invalid`) plus `describedby:`
  pointing at the hint/error message's id; a custom `label:` when "Search" is wrong.

This mirrors the form-control API of `input`/`checkbox` (`required:` -> required +
aria-required, `invalid:` -> aria-invalid, `describedby:` -> aria-describedby).

No variant axis (single appearance), so there is no `coerce_variant` fail-loud
guard here -- unlike the enum-driven components (alert, button).
