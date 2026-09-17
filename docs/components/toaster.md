# Toaster

Fixed-position toast stack for transient notifications. Place once in your application layout.

Requires `toaster_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add toaster
```

Creates `app/components/ui/toaster_component.rb`.

## Setup

Add the component once to your application layout, inside `<body>`:

```erb
<%# app/views/layouts/application.html.erb %>
<body>
  <%= yield %>
  <%= ui :toaster %>
</body>
```

## Server-side toasts

Pass toasts via the slot when you want to render them from Rails (e.g. after a form submission):

```erb
<%= ui :toaster do |t| %>
  <% t.with_toast(message: "Profile saved", variant: :success) %>
<% end %>
```

## Client-side toasts

Dispatch the `toaster:add` window event from any Stimulus controller or JavaScript:

```javascript
window.dispatchEvent(new CustomEvent("toaster:add", {
  detail: { message: "Done!", variant: "success", duration: 3000 }
}))
```

## Toast variants

| Variant | Icon colour |
|---------|-------------|
| `:default` | None |
| `:success` | Green |
| `:warning` | Amber |
| `:destructive` | Red |
| `:info` | Blue |

## Position

| Position | Description |
|----------|-------------|
| `:bottom_right` | Fixed bottom-right (default) |
| `:bottom_left` | Fixed bottom-left |
| `:bottom_center` | Fixed bottom-center |
| `:top_right` | Fixed top-right |
| `:top_left` | Fixed top-left |
| `:top_center` | Fixed top-center |

```erb
<%= ui :toaster, position: :top_right %>
```

## API

### ToasterComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `position` | Symbol | `:bottom_right` | Corner to anchor the toast stack |
| `**html_attrs` | Hash | — | Forwarded to the container `<div>` |

### ToastComponent (via `with_toast` or `toaster:add` event)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | String | required | Toast body text |
| `title` | String | `nil` | Optional bold heading above the message |
| `variant` | Symbol | `:default` | Colour scheme — see Variants table |
| `duration` | Integer | `4000` | Auto-dismiss delay in milliseconds; `0` = no auto-dismiss |

## When to use

- You need a stack of transient, self-dismissing confirmations layered over the
  page ("Profile saved", "Copied to clipboard") — fired server-side via the
  `with_toast` slot or client-side via a `toaster:add` window event.

## When not to use

- It's an inline message tied to surrounding content — use `alert`.
- It's a standing page-level announcement — use `banner`.

## Accessibility contract

- **Guarantees:** the stack is a live region — `role="status"`/`aria-live="polite"`
  for ordinary toasts, `role="alert"`/`aria-live="assertive"` for the `danger`
  severity (so an error interrupts) — with each toast carrying AAA-contrast text on
  a tinted signal surface, and a real focusable dismiss `<button>` with a 44px
  target, an i18n accessible name ("Dismiss"), and the `focus-ring` utility.
- **You supply:** a `message` (and optional `title`) per toast, a valid `severity`
  (an unknown one raises in development), and the `toaster` Stimulus controller
  (ships co-located, auto-registered by the generator).

## Severity

The canonical signal axis — `default` · `info` · `success` · `warning` · `danger`.
Each signal severity uses the tinted-surface treatment shared with `alert` and
`banner` (`bg-<signal>-surface` + `border-<signal>-border` + `text-<signal>`),
never a solid signal fill (base signal tokens are TEXT colors).

### Severity-naming collision (vs the app toast pipeline)
The app's `shared/_toasts` flash pipeline names its severities after Rails flash
keys — there, `:alert` means *warning* and `:error`/`:alert` map to danger. This
gem component instead names severities after the canonical SIGNAL axis, so
`:warning` is warning and `:danger` is danger. To smooth that mismatch, the flash
names `:alert` (→ `:warning`) and `:error` (→ `:danger`) are accepted as aliases.
The legacy gem name `:destructive` is also accepted as an alias for `:danger`.
