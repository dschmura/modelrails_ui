# ToggleGroup

Wrapper that coordinates a set of Toggle buttons as a single or multi-select group.

Requires `toggle_group_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add toggle_group
```

Creates `app/components/ui/toggle_group_component.rb`.

## Usage

Nest Toggle components inside the group:

```erb
<%# Single-select — only one item active at a time %>
<%= ui :toggle_group, type: :single, value: "center" do %>
  <%= ui :toggle, "Left",   value: "left" %>
  <%= ui :toggle, "Center", value: "center" %>
  <%= ui :toggle, "Right",  value: "right" %>
<% end %>

<%# Multi-select — several items can be active simultaneously %>
<%= ui :toggle_group, type: :multiple, value: ["bold", "italic"] do %>
  <%= ui :toggle, "Bold",   value: "bold" %>
  <%= ui :toggle, "Italic", value: "italic" %>
  <%= ui :toggle, "Under",  value: "underline" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | Symbol | `:single` | `:single` (one active) or `:multiple` (many active) |
| `value` | String or Array | `nil` | Currently active value(s) |
| `**html_attrs` | Hash | — | Forwarded to the `<div role="group">` wrapper |

## When to use

- You have a set of related on/off controls and want either one-active-at-a-time
  (`:single` — text alignment, view mode) or many-active (`:multiple` —
  bold/italic/underline) selection in a labelled cluster.

## When not to use

- It's a single standalone on/off control — use `ui :toggle` on its own.
- It's a form field that posts on submit — use a radio group or checkboxes.

## Accessibility contract

- **Guarantees:** the cluster is a named grouping (`role="group"` + an accessible
  name) so AT announces what the buttons control; `data-toggle-group-type-value`
  tells the controller how to enforce selection. Focus lives on each item (the
  caller-supplied `ui :toggle` carries the AAA `focus-ring`), never the wrapper.
- **You supply:** an accessible name via `aria_label:` OR `aria_labelledby:`
  (a nameless group of toggle buttons is unannounced — so this fails loud rather
  than ship an anonymous "group"), and the toggle items as block content. Each
  item's initial pressed state should reflect `item_pressed?(item_value)`.

## ARIA semantics: `role="group"` for BOTH single and multiple

The items are toggle BUTTONS (`<button aria-pressed>`), and the `toggle-group`
controller flips their `aria-pressed` — it never emits `role="radio"` /
`aria-checked`. A `role="radiogroup"` wrapper requires children with
`role="radio"` + `aria-checked`; pairing it with `aria-pressed` buttons would be
an ARIA lie that breaks AT. So `:single` keeps `role="group"` (a single-select
cluster of pressed buttons — APG toolbar-adjacent) rather than masquerading as a
radiogroup. FOLLOW-UP: a true radiogroup variant (role="radio" items +
arrow-key roving) is a larger change — out of scope for this hardening pass.

## Parameters

- `type:`            `:single` (one active) | `:multiple` (many active)
- `value:`           currently active value (String) for `:single`, or an array
                     of active values for `:multiple`
- `aria_label:`      accessible name for the group
- `aria_labelledby:` id of an existing element that names the group
- `**html_attrs`     forwarded to the `<div role="group">` wrapper
