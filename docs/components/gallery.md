# Gallery

Responsive image grid with an optional click-to-enlarge lightbox. With more
than one image, the lightbox gains prev/next buttons, a caption, and a
counter ("1 / 3"); Left/Right arrow keys navigate too.

Requires `gallery_controller.js` (copied automatically by the generator) when `lightbox: true`.

## Installation

```bash
rails g modelrails_ui:add gallery
```

Creates `app/components/ui/gallery_component.rb`.

## Usage

```erb
<%= ui :gallery do |g| %>
  <% g.with_image(src: "/photos/a.jpg", alt: "Mountain view") %>
  <% g.with_image(src: "/photos/b.jpg", alt: "Beach sunset", caption: "Malibu, 2024") %>
  <% g.with_image(src: "/photos/c.jpg", alt: "City at night") %>
<% end %>
```

## Column count

```erb
<%= ui :gallery, cols: 4 do |g| %>
  <% g.with_image(src: "/p/1.jpg", alt: "Photo 1") %>
  <% g.with_image(src: "/p/2.jpg", alt: "Photo 2") %>
  <% g.with_image(src: "/p/3.jpg", alt: "Photo 3") %>
  <% g.with_image(src: "/p/4.jpg", alt: "Photo 4") %>
<% end %>
```

## Disable lightbox

```erb
<%= ui :gallery, lightbox: false, cols: 2 do |g| %>
  <% g.with_image(src: "/thumb/a.jpg", alt: "A") %>
  <% g.with_image(src: "/thumb/b.jpg", alt: "B") %>
<% end %>
```

## Custom aspect ratio

```erb
<%= ui :gallery, aspect: "aspect-video" do |g| %>
  <% g.with_image(src: "/screens/1.png", alt: "Screenshot") %>
<% end %>
```

## Larger lightbox rendition (`full_src`)

The grid cell always renders `src` (the thumbnail), so a small grid image is
never upscaled full-screen. Pass `full_src` to swap in a larger rendition when
the lightbox opens:

```erb
<%= ui :gallery do |g| %>
  <% g.with_image(src: "/thumb/a.jpg", full_src: "/full/a.jpg", alt: "Mountain view") %>
<% end %>
```

## Prev/next navigation

With more than one image, the lightbox automatically gains prev/next buttons,
a caption region, and a counter ("1 / 3"). Left/Right arrow keys navigate as
well. With exactly one image, none of that nav renders.

## Trigger contract

Each grid cell is a `<button>` wired with `data-action="gallery#open modal#open"`
and four Stimulus params, read by the `gallery` controller in DOM order via
`[data-gallery-index-param]`:

| Param | Type | Description |
|---|---|---|
| `gallery-index-param` | Integer | Position among triggers (0-based) |
| `gallery-src-param` | String | Image src for the dialog swap (`full_src` if set, else `src`) |
| `gallery-alt-param` | String | Alt text for the dialog `<img>` |
| `gallery-caption-param` | String | Optional caption shown in the counter bar |

Any element with this shape — not just `GalleryComponent`'s own cells — is a
valid trigger, as long as it shares a `gallery modal` controller ancestor with
the dialog.

## Standalone `LightboxComponent`

`UI::GalleryComponent::LightboxComponent` is the dialog on its own, for
consumers that build their own triggers (e.g. a media stage that isn't a plain
grid):

```erb
<div data-controller="gallery modal">
  <% my_items.each_with_index do |item, i| %>
    <button type="button" data-action="gallery#open modal#open"
      data-gallery-index-param="<%= i %>" data-gallery-src-param="<%= item.full_src %>"
      data-gallery-alt-param="<%= item.alt %>" data-gallery-caption-param="<%= item.caption %>">
      <%= image_tag item.thumb %>
    </button>
  <% end %>

  <%= render(UI::GalleryComponent::LightboxComponent.new(count: my_items.size)) %>
</div>
```

`count` controls whether nav renders (`count > 1`); `label` sets an optional
`aria-label` on the `<dialog>`.

## `gallery:navigated` event

The `gallery` controller dispatches a bubbling `gallery:navigated` custom
event — `detail: { index }` — on every open, prev, and next. A host component
(e.g. a media stage keeping a larger frame in sync) can listen for it instead
of re-deriving the current index:

```javascript
document.addEventListener("gallery:navigated", (event) => {
  console.log(event.detail.index)
})
```

## API

### GalleryComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cols` | Integer | `3` | Grid columns (1–6) |
| `lightbox` | Boolean | `true` | Enable click-to-enlarge overlay |
| `aspect` | String | `"aspect-square"` | Tailwind aspect-ratio class applied to each cell |
| `**html_attrs` | Hash | — | Forwarded to the `<div>` grid |

### ImageComponent (via `with_image`)

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `src` | String | Yes | Image URL (also the lightbox image, unless `full_src` is set) |
| `alt` | String | Yes | Alternative text |
| `caption` | String | No | Text shown on hover over the image, and in the lightbox counter bar |
| `full_src` | String | No | Larger rendition swapped in when the lightbox opens |

### LightboxComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `count` | Integer | — | Total image count; nav/counter render only when `count > 1` |
| `label` | String | `nil` | Optional `aria-label` on the `<dialog>` |
