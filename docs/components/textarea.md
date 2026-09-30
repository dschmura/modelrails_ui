# Textarea

Multi-line text input that grows to fit its content via CSS `field-sizing: content`. Styling matches the form builder's (`UI::FormBuilder`) field rendering (shared with `UI::InputComponent`) so `f.text_area` delegates to it invisibly.

## Installation

```bash
rails g modelrails_ui:add textarea
```

Creates `app/components/ui/textarea_component.rb`.

## Usage

```erb
<%= ui :textarea, name: "bio", placeholder: "Tell us about yourself…" %>
```

## With initial content

```erb
<%= ui :textarea, name: "message" do %>
  Initial text here.
<% end %>
```

## States

```erb
<%# Disabled %>
<%= ui :textarea, name: "notes", disabled: true %>

<%# Invalid %>
<%= ui :textarea, name: "content", "aria-invalid": "true" %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `**html_attrs` | Hash | — | Forwarded to the `<textarea>` element |

## When to use

- The user writes more than a line of plain text, outside a model-backed form or
  inside a `form_field` you are composing by hand.

## When not to use

- You are inside a `form_with` — `f.text_area` renders this component.
- The text needs formatting — use `wysiwyg`, or the editor your app already has.
- The text fits on one line — use `input`.
