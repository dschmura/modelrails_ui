# Skeleton

Animated loading placeholder. Size is controlled entirely by classes passed by the caller.

## Installation

```bash
rails g modelrails_ui:add skeleton
```

Creates `app/components/ui/skeleton_component.rb`.

## Usage

```erb
<%# Text line placeholder %>
<%= ui :skeleton, class: "h-4 w-48" %>

<%# Avatar placeholder %>
<%= ui :skeleton, class: "size-10 rounded-full" %>

<%# Card placeholder %>
<div class="space-y-2">
  <%= ui :skeleton, class: "h-4 w-full" %>
  <%= ui :skeleton, class: "h-4 w-3/4" %>
  <%= ui :skeleton, class: "h-4 w-1/2" %>
</div>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `class` | String | `nil` | Required — sets the size and shape of the placeholder |
| `**html_attrs` | Hash | — | Forwarded to the `<div>` element |

## When to use

- You need a low-jank loading placeholder for text lines, avatars, or cards.
  Shape each skeleton with `class:` (e.g. `"h-4 w-48"`, `"size-10 rounded-full"`).

## When not to use

- There's no surrounding loading signal for AT. A skeleton is `aria-hidden`, so
  the region it fills must carry its own `aria-busy`/live-region status or
  screen-reader users get no indication anything is loading.

## Accessibility contract

- **Guarantees:** `aria-hidden="true"` (no empty-box announcements) and
  `motion-reduce:animate-none` (the pulse is suppressed for reduced-motion users).
- **You supply:** an `aria-busy` / live region on the surrounding container so AT
  users know content is loading; the size/shape via `class:`.
