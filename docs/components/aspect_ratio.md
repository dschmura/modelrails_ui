# Aspect Ratio

Constrains child content to a fixed aspect ratio using the CSS `aspect-ratio` property.

## Installation

```bash
rails g modelrails_ui:add aspect_ratio
```

Creates `app/components/ui/aspect_ratio_component.rb`.

## Usage

```erb
<%# 16:9 video embed %>
<%= ui :aspect_ratio, ratio: 16.0/9 do %>
  <iframe src="..." class="size-full"></iframe>
<% end %>

<%# Square image %>
<%= ui :aspect_ratio, ratio: 1 do %>
  <%= image_tag "photo.jpg", class: "size-full object-cover" %>
<% end %>

<%# 4:3 thumbnail %>
<%= ui :aspect_ratio, ratio: 4.0/3 do %>
  <%= image_tag "thumbnail.jpg", class: "size-full object-cover" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ratio` | Float / Integer | `1` | Width-to-height ratio (e.g. `16.0/9` for widescreen) |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- The child has no dimensions of its own — a raw `<iframe>`, a placeholder, an
  image cropped with `object-cover` — and the box must hold its shape.

## When not to use

- The child is an `image` whose dimensions you know — pass `width:` and `height:`
  and the browser reserves the space.
- The child is an `embed` — it sizes itself per provider.
