# Picture

Renders a `<picture>` element with multiple `<source>` formats and a fallback `<img>`. Use to serve modern formats (AVIF, WebP) with a JPEG/PNG fallback.

## Installation

```bash
rails g modelrails_ui:add picture
```

Creates `app/components/ui/picture_component.rb`.

## Usage

```erb
<%= ui :picture, src: "/photos/hero.jpg", alt: "Hero image" do |p| %>
  <% p.with_source(srcset: "/photos/hero.avif", type: "image/avif") %>
  <% p.with_source(srcset: "/photos/hero.webp", type: "image/webp") %>
<% end %>
```

Sources are rendered in declaration order. Browsers use the first format they support; the `<img>` is the final fallback.

## Responsive sources

```erb
<%= ui :picture, src: "/img/banner.jpg", alt: "Banner",
                 width: 1200, height: 400 do |p| %>
  <% p.with_source(
       srcset: "/img/banner-sm.webp 640w, /img/banner-lg.webp 1200w",
       type: "image/webp",
       sizes: "(max-width: 640px) 100vw, 1200px"
     ) %>
<% end %>
```

## Eager loading

```erb
<%= ui :picture, src: "/img/lcp.jpg", alt: "Above-the-fold image", loading: :eager do |p| %>
  <% p.with_source(srcset: "/img/lcp.avif", type: "image/avif") %>
<% end %>
```

## API

### PictureComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `src` | String | required | Fallback `<img>` URL |
| `alt` | String | required | Alternative text on the fallback `<img>` |
| `loading` | Symbol | `:lazy` | `:lazy`, `:eager`, or `:auto` |
| `width` | Integer | `nil` | Width applied to the fallback `<img>` — native dimensions prevent layout shift |
| `height` | Integer | `nil` | Height applied to the fallback `<img>` — native dimensions prevent layout shift |
| `**html_attrs` | Hash | — | Forwarded to the `<picture>` element |

### SourceComponent (via `with_source`)

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `srcset` | String | Yes | Source URLs and/or descriptors |
| `type` | String | No | MIME type, e.g. `"image/avif"` |
| `media` | String | No | Media query, e.g. `"(max-width: 640px)"` |
| `sizes` | String | No | Sizes attribute |
| `width` | Integer | No | Source width |
| `height` | Integer | No | Source height |

## When to use

- You need format fallbacks (AVIF/WebP → JPEG) or art direction (a different
  crop per viewport) that `srcset`/`sizes` on a plain `<img>` can't express.

## When not to use

- You only need resolution switching — a single `image` with `srcset:`/`sizes:`
  is simpler and sufficient.

## Accessibility contract

- **Guarantees:** `alt:` is REQUIRED on the base `<img>`, forcing an explicit
  decision at every call site; an invalid `loading:` falls back to `:lazy`.
  `<source>`s carry no `alt` — a `<picture>`'s accessible name comes solely from
  its `<img>`, so the requirement lives there.
- **You supply:** real `alt:` text for meaningful images, or `alt: ""` (the
  correct decorative signal) for purely decorative ones. `alt` is NOT a caption —
  keep it a terse equivalent; use `figure` for captions.
