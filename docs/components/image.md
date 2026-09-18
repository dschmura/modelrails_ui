# Image

Responsive `<img>` with lazy loading, srcset/sizes support, and layout-shift prevention.

## Installation

```bash
rails g modelrails_ui:add image
```

Creates `app/components/ui/image_component.rb`.

## Usage

```erb
<%= ui :image, src: "/photos/hero.jpg", alt: "Hero photo" %>
```

## Responsive images

```erb
<%= ui :image,
       src:    "/photos/hero-1280.jpg",
       alt:    "Hero",
       srcset: "/photos/hero-640.jpg 640w, /photos/hero-1280.jpg 1280w",
       sizes:  "(max-width: 640px) 100vw, 1280px",
       width:  1280,
       height: 720 %>
```

## Eager loading

Pass `loading: :eager` for above-the-fold images to avoid the lazy-load delay:

```erb
<%= ui :image, src: "/photos/lcp.jpg", alt: "Main image", loading: :eager,
               width: 800, height: 600 %>
```

## Prevent layout shift

Always supply `width:` and `height:` for images with known dimensions:

```erb
<%= ui :image, src: "/avatar.png", alt: "User avatar",
               width: 48, height: 48, class: "rounded-full" %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `src` | String | required | Image URL |
| `alt` | String | required | Alternative text (use `""` for decorative images) |
| `srcset` | String | `nil` | Responsive image set |
| `sizes` | String | `nil` | Media conditions for srcset |
| `loading` | Symbol | `:lazy` | `:lazy`, `:eager`, or `:auto` |
| `width` | Integer | `nil` | Native width — prevents layout shift |
| `height` | Integer | `nil` | Native height — prevents layout shift |
| `**html_attrs` | Hash | — | Forwarded to the `<img>` element |

- `srcset:` responsive set, e.g. "img-sm.jpg 640w, img-lg.jpg 1280w"

## When to use

- You're rendering content imagery and want lazy-loading + responsive sources
  with the accessibility decision (alt text vs. decorative) made explicitly.

## When not to use

- The image is an icon inside a button/link — there the accessible name comes
  from the control, and an inline SVG/icon helper is the better fit.

## Accessibility contract

- **Guarantees:** `alt:` is REQUIRED, forcing an explicit decision at every call
  site; an invalid `loading:` falls back to `:lazy`.
- **You supply:** real `alt:` text for meaningful images, or `alt: ""` (the
  correct decorative signal) for purely decorative ones. `alt` is NOT a caption —
  keep it a terse equivalent; use `figure` for captions.
