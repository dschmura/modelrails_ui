# Alert

Informational banner for surfacing status messages, warnings, and errors. Accepts plain-text content via kwargs or rich HTML via slots.

## Installation

```bash
rails g modelrails_ui:add alert
```

Creates `app/components/ui/alert_component.rb`.

## Usage

```erb
<%# Kwargs — plain text, no block needed %>
<%= ui :alert, title: "Heads up!", description: "You can change this in your account settings." %>

<%# Slots — for rich HTML content %>
<%= ui :alert do |alert| %>
  <% alert.with_alert_title { "Heads up!" } %>
  <% alert.with_alert_description { "You can change this in your account settings." } %>
<% end %>
```

Slots take precedence over kwargs when both are provided.

## Tones

| Tone | Description |
|------|-------------|
| `neutral` | Default — raised surface, body text, no icon |
| `info` | Informational signal on the info-tinted surface |
| `success` | Confirmation on the success-tinted surface |
| `warning` | Warning on the warning-tinted surface |
| `danger` | Error — announced assertively (`role="alert"`) on the danger surface |

`variant:` is accepted as a deprecated alias for `tone:` (`default`→`neutral`, `destructive`→`danger`, the rest 1:1).

```erb
<%= ui :alert, tone: :info,
                title: "Note",
                description: "Your free trial expires in 3 days." %>

<%= ui :alert, tone: :danger,
                title: "Error",
                description: "Your session has expired. Please log in again." %>
```

## Slots

Use slots when the content contains HTML, links, or other components:

```erb
<%# Title only %>
<%= ui :alert, title: "Maintenance scheduled for Sunday 02:00 UTC." %>

<%# Rich description via slot %>
<%= ui :alert, title: "Action required" do |alert| %>
  <% alert.with_alert_description do %>
    Please <%= link_to "update your billing info", billing_path %> before Friday.
  <% end %>
<% end %>
```

## Icons

Each signal tone renders a matching severity icon automatically — info circle, success check circle, warning triangle, danger circle-x (the same glyphs the toaster uses, so an alert and a toast at the same level read the same). Distinct shapes keep severity legible without relying on color alone (WCAG 1.4.1). The icon is `aria-hidden` — decorative for screen readers, which already get the urgency-matched live region and your title/description. The `neutral` tone has no icon.

```erb
<%# Warning triangle renders automatically %>
<%= ui :alert, tone: :warning, title: "Storage almost full" %>

<%# Opt out with icon: false %>
<%= ui :alert, tone: :warning, icon: false, title: "Storage almost full" %>
```

## Persistent context — the `role:` override

An alert is a live region by default (see Tones). For **persistent context** that
should not be re-announced — a "viewing as" banner, an ambient notice that Turbo
re-renders with unchanged text — override the role. Any override (e.g. `:note`)
also drops `aria-live` entirely: persistent context is NOT a live region, and
re-announcing unchanged text on every re-render is a screen-reader bug, not a
feature.

```erb
<%= ui :alert, tone: :info, role: :note, title: "Viewing as a member" %>
```

## Flash messages

```erb
<%# app/views/shared/_flash.html.erb %>
<% flash.each do |type, message| %>
  <%= ui :alert, tone: flash_tone(type), description: message %>
<% end %>
```

```ruby
# app/helpers/flash_helper.rb
module FlashHelper
  FLASH_TONES = {
    "notice"  => :neutral,
    "success" => :success,
    "alert"   => :warning,
    "error"   => :danger,
    "warning" => :warning
  }.freeze

  def flash_tone(type)
    FLASH_TONES.fetch(type.to_s, :neutral)
  end
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<body>
  <div class="container mx-auto px-4 py-2 space-y-2">
    <%= render "shared/flash" %>
  </div>
  <%= yield %>
</body>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tone` | Symbol | `:neutral` | Severity level — see Tones table |
| `variant` | Symbol | `nil` | Deprecated alias for `tone:` (`default`→`neutral`, `destructive`→`danger`) |
| `icon` | Boolean | `true` | Render the tone's severity icon. `false` suppresses it |
| `role` | Symbol/String | `nil` | Override the tone's role (e.g. `:note` for persistent context); any override drops `aria-live` |
| `title` | String | `nil` | Plain-text title, alternative to `with_alert_title` slot |
| `description` | String | `nil` | Plain-text description, alternative to `with_alert_description` slot |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` (e.g. `data:` for Stimulus wiring, `id:`); `class:` merges via `cn` |

| Slot | Required | Description |
|------|----------|-------------|
| `alert_title` | No | Rich title — renders as `<h5>`. Takes precedence over `title:` kwarg |
| `alert_description` | No | Rich description — renders as `<div>`. Takes precedence over `description:` kwarg |
