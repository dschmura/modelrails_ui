# Switch

Toggle switch built from a styled checkbox. Thumb slides on check; no JavaScript required. The visually-hidden checkbox is the `peer`; a clickable track `<label>` and an `aria-hidden` thumb render the visual switch and react via `peer-checked:` / `peer-focus-visible:` / `peer-disabled:`.

## Installation

```bash
rails g modelrails_ui:add switch
```

Creates `app/components/ui/switch_component.rb`.

## Usage

```erb
<%# Standalone %>
<%= ui :switch, name: "notifications", id: "notifications" %>

<%# With label %>
<%= ui :switch, name: "dark_mode", id: "dark_mode", label: "Dark mode" %>
```

## Checked by default

```erb
<%= ui :switch, name: "emails", id: "emails", label: "Email notifications", checked: true %>
```

## In a form

```erb
<%= form_with model: @settings do |f| %>
  <%= ui :switch, name: "settings[dark_mode]", id: "settings_dark_mode",
                  label: "Dark mode", checked: @settings.dark_mode %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | `nil` | Visible label rendered beside the switch |
| `checked` | Boolean | `false` | Initial on/off state |
| `**html_attrs` | Hash | — | Forwarded to the hidden `<input type="checkbox">` |

## When to use

- You need an immediate on/off setting (notifications on, dark mode on) that takes
  effect on toggle — not a value collected for later form submission.

## When not to use

- The choice is part of a form the user submits, or it isn't strictly binary —
  use a checkbox or radio group instead.

## Accessibility contract

- **Guarantees:** a real `role="switch"` checkbox whose **native `checked` state**
  conveys on/off to assistive tech (no JS, no stale ARIA), and a >=44px clickable
  target (AAA 2.5.5) even though the visual track is smaller.
- **You supply:** an accessible name via `label:` (or `aria-label:` on a label-less
  switch), the initial `checked:` state, and a `name:` so the value posts.

## State

`checked:` (default `false`) sets the initial on/off; the native checkbox tracks
the rest. No variant axis, so no fail-loud guard is needed.
