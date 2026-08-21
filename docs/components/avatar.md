# Avatar

Circular image or initials fallback for user representation.

## Installation

```bash
rails g view_primitives:add avatar
```

Creates `app/components/ui/avatar_component.rb`.

## Usage

```erb
<%# Image avatar %>
<%= ui :avatar, src: user.avatar_url, alt: user.name %>

<%# Fallback to initials when no image %>
<%= ui :avatar, fallback: "Jane Doe" %>

<%# Explicit fallback text (overrides alt for initials) %>
<%= ui :avatar, src: nil, alt: "John Smith", fallback: "John Smith" %>
```

## Sizes

| Size | Class | Description |
|------|-------|-------------|
| `sm` | `size-6` | Small (24px) |
| `default` | `size-8` | Standard (32px) |
| `lg` | `size-12` | Large (48px) |

```erb
<%= ui :avatar, src: url, size: :sm %>
<%= ui :avatar, src: url, size: :default %>
<%= ui :avatar, src: url, size: :lg %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `src` | String | `nil` | Image URL; renders `<img>` when present |
| `alt` | String | `""` | Alt text for the image, also used as initials source |
| `fallback` | String | `nil` | Overrides `alt` as the initials source |
| `size` | Symbol | `:default` | Size variant |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When the image fails to load

`fallback:` stands in for a **nil** `src`. It does not cover a `src` that 404s — that
leaves the browser's broken-image glyph, and the `error` event is the only signal for it.

Pass both a `src` and a `fallback` and the component wires an `avatar` controller that
swaps the initials in on failure. It **removes** the failed `<img>` rather than hiding it:
a hidden-but-present image keeps announcing a picture that never arrived.

A `src` with no `fallback` renders a bare `<img>`, unchanged.
