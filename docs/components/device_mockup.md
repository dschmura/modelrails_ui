# DeviceMockup

Decorative device frame — phone, tablet, or browser window — that wraps any content.

## Installation

```bash
rails g modelrails_ui:add device_mockup
```

Creates `app/components/ui/device_mockup_component.rb`.

## Usage

```erb
<%= ui :device_mockup do %>
  <%= image_tag "app-screenshot.png", alt: "App screenshot", class: "w-full" %>
<% end %>
```

## Variants

| Variant | Description |
|---------|-------------|
| `:phone` | Portrait phone frame with top notch (default) |
| `:tablet` | Landscape tablet frame |
| `:browser` | Browser window with macOS-style traffic-light dots |

```erb
<%= ui :device_mockup, variant: :browser do %>
  <%= image_tag "dashboard.png", alt: "Dashboard", class: "w-full" %>
<% end %>

<%= ui :device_mockup, variant: :tablet do %>
  <%= image_tag "tablet-app.png", alt: "Tablet view", class: "w-full h-full object-cover" %>
<% end %>
```

## Browser address bar

Pass `url:` when using `:browser` to display a fake address bar:

```erb
<%= ui :device_mockup, variant: :browser, url: "https://example.com/dashboard" do %>
  <%= image_tag "dashboard.png", alt: "Dashboard", class: "w-full" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `variant` | Symbol | `:phone` | `:phone`, `:browser`, or `:tablet` |
| `url` | String | `nil` | Address bar text (`:browser` variant only) |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- You're showing a product screenshot or demo inside a recognizable device
  shell for marketing/docs context.

## When not to use

- The frame would imply interactivity the content doesn't have — the mockup is
  a static decorative wrapper, not a live device.

## Accessibility contract

- **Guarantees:** the frame is a plain `<div>` (no bogus role), and every purely
  decorative chrome bit (notch, traffic-light dots, fake address bar) is
  `aria-hidden` so assistive tech sees ONLY the slotted content. AAA semantic
  tokens throughout (`bg-surface-sunken`/`border-border`/`text-text-*`) — no raw
  palette colors. A valid `variant` is required (an unknown one raises in dev).
- **You supply:** the framed content via the block, with its own a11y — real
  `alt` text on a meaningful screenshot, or `alt: ""` for a decorative one.
