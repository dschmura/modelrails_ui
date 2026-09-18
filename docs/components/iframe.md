# Iframe

Accessible `<iframe>` with sandboxing, lazy loading, and optional aspect-ratio wrapper.

## Installation

```bash
rails g modelrails_ui:add iframe
```

Creates `app/components/ui/iframe_component.rb`.

## Usage

```erb
<%= ui :iframe, src: "https://www.youtube.com/embed/dQw4w9WgXcQ",
                title: "YouTube video: Rick Astley — Never Gonna Give You Up",
                aspect: "16/9" %>
```

## Aspect ratio wrapper

Pass `aspect:` to wrap the iframe in a `<div>` with `aspect-ratio` inline style. This avoids the need for explicit `width` and `height` values.

```erb
<%= ui :iframe, src: "https://player.vimeo.com/video/123456",
                title: "Product demo video",
                aspect: "4/3" %>
```

## Explicit dimensions

```erb
<%= ui :iframe, src: "https://maps.google.com/...",
                title: "Store location map",
                width: 600, height: 450 %>
```

## Custom sandbox

The default sandbox permits scripts, same-origin, forms, and popups. Supply a string to restrict further, or pass `sandbox: false` to disable sandboxing (not recommended):

```erb
<%# Stricter sandbox — scripts only %>
<%= ui :iframe, src: "...", title: "Widget",
                sandbox: "allow-scripts" %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `src` | String | required | URL to embed |
| `title` | String | required | Accessible description of the embedded content |
| `loading` | Symbol | `:lazy` | `:lazy`, `:eager`, or `:auto` |
| `sandbox` | Boolean or String | `true` | `true` = default safe tokens; string = custom tokens; `false` = no sandbox |
| `aspect` | String | `nil` | CSS `aspect-ratio` value — wraps iframe in a `<div>` when present |
| `width` | Integer | `nil` | Explicit pixel width |
| `height` | Integer | `nil` | Explicit pixel height |
| `**html_attrs` | Hash | — | Forwarded to the `<iframe>` element |

- `sandbox:` space-separated token string, or `true` for strict defaults;
  pass `false` to disable sandboxing entirely (not recommended)
- `aspect:`  CSS aspect-ratio value, e.g. "16/9", "4/3" (wraps in a div);
  omit if you set explicit width/height

## When to use

- Embedding external content (a map, video, document, or third-party widget)
  and you want a responsive, sandboxed frame with an explicit accessible name.

## When not to use

- The content is first-party imagery or video you control — use `image` or a
  native `<video>`; an iframe is for cross-document/embedded content.

## Accessibility contract

- **Guarantees:** `title:` is REQUIRED and must be non-blank — every iframe
  carries an accessible name (a title-less iframe is a hard WCAG failure, and
  unlike an image there is no "decorative" exception). An invalid `loading:`
  falls back to `:lazy`.
- **You supply:** a real `title:` describing the embedded content (e.g.
  "Map of the office location", "Product demo video").
