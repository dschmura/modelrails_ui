# Spinner

Animated loading indicator for in-progress states. Carries `role="status"` and an sr-only label so screen-reader users are told something is loading.

## Installation

```bash
rails g modelrails_ui:add spinner
```

Creates `app/components/ui/spinner_component.rb`.

## Usage

```erb
<%= ui :spinner %>
```

## Sizes

| Size | Class |
|------|-------|
| `sm` | `size-4` |
| `default` | `size-6` |
| `lg` | `size-10` |

```erb
<%= ui :spinner, size: :sm %>
<%= ui :spinner %>
<%= ui :spinner, size: :lg %>
```

## Loading button

```erb
<%= ui :button, variant: :outline, disabled: true do %>
  <%= ui :spinner, size: :sm, class: "mr-2" %>
  Saving…
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `size` | Symbol | `:default` | Spinner diameter — `:sm`, `:default`, `:lg` |
| `**html_attrs` | Hash | — | Forwarded to the outer `<span>` |

The component renders a `<span role="status">` with a visually hidden "Loading…" text for screen readers.

## When to use

- You need to signal an indeterminate, short-lived wait (a button submitting, a
  panel fetching). For determinate progress, use `progress` instead.

## When not to use

- The wait is determinate (you know the percentage) — use `progress`.
- You strip the sr-only text — without it the spin is invisible to AT.

## Accessibility contract

- **Guarantees:** `role="status"` plus an sr-only loading label (i18n via
  `t` with an English default), so the spin is announced, not silent.
- **You supply:** nothing required; override the label via the
  `modelrails_ui.spinner.loading` locale key. (The spin is intentionally NOT
  motion-reduce-suppressed — a spinner with no motion conveys nothing.)
