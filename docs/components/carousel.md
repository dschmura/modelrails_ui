# Carousel

Scrollable slide container with previous/next controls and optional dot indicators.
Autoplay (when > 0) is WCAG 2.2.2 compliant — a pause/play toggle, pause on
hover/focus, disabled under prefers-reduced-motion.

Requires `carousel_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add carousel
```

Creates `app/components/ui/carousel_component.rb`.

## Usage

```erb
<%= ui :carousel do |c| %>
  <% c.with_slide { image_tag "slide1.jpg", alt: "Slide 1", class: "w-full object-cover" } %>
  <% c.with_slide { image_tag "slide2.jpg", alt: "Slide 2", class: "w-full object-cover" } %>
  <% c.with_slide { image_tag "slide3.jpg", alt: "Slide 3", class: "w-full object-cover" } %>
<% end %>
```

## Autoplay

```erb
<%= ui :carousel, autoplay: 3000 do |c| %>
  <% c.with_slide { "Slide 1" } %>
  <% c.with_slide { "Slide 2" } %>
<% end %>
```

## No loop

```erb
<%= ui :carousel, loop: false do |c| %>
  <% c.with_slide { "First" } %>
  <% c.with_slide { "Last" } %>
<% end %>
```

## Without indicators

```erb
<%= ui :carousel, indicators: false do |c| %>
  <% c.with_slide { "Slide" } %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `loop` | Boolean | `true` | Wrap from the last slide to the first (and vice versa) |
| `indicators` | Boolean | `true` | Show dot indicators below the slides |
| `autoplay` | Integer | `0` | Auto-advance interval in milliseconds; `0` disables autoplay |
| `label` | String | `nil` | Accessible name for the carousel region (i18n default "Carousel") |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- The slides are peers and showing one at a time is acceptable: a product tour,
  a set of testimonials.

## When not to use

- The reader should see the set together, or enlarge one — use `gallery`.
- A slide holds something the reader must not miss — everything past the first
  slide is off screen until they page to it.
