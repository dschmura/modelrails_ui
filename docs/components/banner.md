# Banner

Styled announcement strip for notices, warnings, and status messages.

## Installation

```bash
rails g modelrails_ui:add banner
```

Creates `app/components/ui/banner_component.rb`.

## Usage

```erb
<%# Positional message %>
<%= ui :banner, "We just released version 2.0!" %>

<%# Keyword message %>
<%= ui :banner, message: "Scheduled maintenance on Sunday." %>

<%# Block content with a link %>
<%= ui :banner, variant: :info do %>
  New components are available.
  <a href="/changelog" class="ml-1 font-medium underline underline-offset-4">View changelog</a>
<% end %>
```

## Variants

| Variant | Description |
|---------|-------------|
| `default` | Neutral, matches the page background |
| `info` | Blue tones |
| `warning` | Yellow tones |
| `destructive` | Red tones |
| `success` | Green tones |

```erb
<%= ui :banner, "Trial expires in 3 days.",          variant: :warning %>
<%= ui :banner, "Payment failed. Update billing.",   variant: :destructive %>
<%= ui :banner, "Deployment succeeded.",             variant: :success %>
<%= ui :banner, "Read the updated privacy policy.",  variant: :info %>
```

`default` · `info` · `success` · `warning` · `destructive`
Signal variants use the tinted-surface treatment (`bg-<signal>-surface` +
`border-<signal>-border` + `text-<signal>`), never a solid signal fill.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | String | `nil` | Banner text — positional, `message:`, or `label:` keyword, alternative to block |
| `variant` | Symbol | `:default` | Visual style |
| `**html_attrs` | Hash | — | Forwarded to the `<div>` element |

## When to use

- A standalone, page-level announcement: "We just shipped 2.0", a cookie
  consent strip, a scheduled-maintenance heads-up.

## When not to use

- It's an inline message tied to surrounding content (a form-error summary, an
  empty-state notice) — use `alert`, which carries `role="alert"`/`status`.
- It's an ephemeral flash — use the app's toast system.

## Accessibility contract

- **Guarantees:** a `role="region"` landmark named by an i18n `aria-label` (so
  assistive tech can find and skip it), AAA-contrast text, and — when
  `dismissible:` — a real focusable `<button>` with an i18n accessible name
  ("Dismiss") and the `focus-ring` utility. A banner is NOT a live region: it
  is present on load, not announced, so it carries no `role="alert"`/`status`.
- **You supply:** the message (positional, `message:`/`label:`, or slot) and a
  valid `variant` (an unknown one raises in development).

## Dismiss behavior

When `dismissible:`, the banner root carries `data-controller="banner"` and the
trailing close button fires `banner#dismiss`, which removes the strip (immediate,
so it behaves under prefers-reduced-motion). The controller ships co-located
(`banner_controller.js`) and is auto-registered by the generator. Persistence
across page loads (a stable id + storage policy) is the host app's call — extend
the controller if you need it.
