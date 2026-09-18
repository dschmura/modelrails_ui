# Figure

Semantic `<figure>` wrapper with an optional `<figcaption>`. Use to pair an image, code block, or diagram with a caption. The caption supplements the content; it does not replace the content's own accessible name.

## Installation

```bash
rails g modelrails_ui:add figure
```

Creates `app/components/ui/figure_component.rb`.

## Usage

```erb
<%= ui :figure, caption: "Tailwind CSS component library" do %>
  <%= image_tag "screenshot.png", alt: "Screenshot of the component library" %>
<% end %>
```

## Without caption

```erb
<%= ui :figure do %>
  <%= image_tag "chart.png", alt: "Revenue chart" %>
<% end %>
```

## Custom caption styles

```erb
<%= ui :figure, caption: "Figure 1: System architecture",
                caption_class: "text-center text-xs italic" do %>
  <%= image_tag "architecture.svg", alt: "Architecture diagram" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `caption` | String | `nil` | Text rendered in `<figcaption>` — omit to skip the caption |
| `caption_class` | String | `nil` | Additional CSS classes for `<figcaption>` |
| `**html_attrs` | Hash | — | Forwarded to the `<figure>` element |

- `caption:` text shown in `<figcaption>` (optional; omit to render none)

## When to use

- You have referenced/standalone content that benefits from a visible caption
  (a captioned image, a diagram, a quoted block).

## When not to use

- You're relying on the caption to describe an image that has no `alt`. The
  figcaption is a supplement, not a substitute — the image still needs its own
  `alt` (use `alt: ""` only if it is genuinely decorative).

## Accessibility contract

- **Guarantees:** semantic `<figure>`/`<figcaption>` association; the caption is
  rendered only when provided. The caption uses `text-text-muted`, which in this
  token system is the SAME neutral as body text (AAA 7:1) — de-emphasis is by
  size/weight, not lightness.
- **You supply:** real `alt` on any inner image (the figcaption does not replace it).
