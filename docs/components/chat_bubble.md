# ChatBubble

Styled message bubble for chat or comment interfaces. Supports sent and received orientations, timestamps, and avatars. Purely presentational: it styles *one* message (sent vs received) and optionally shows the author, timestamp, and a decorative avatar. It is NOT the transcript itself — wrap a sequence of bubbles in your own log/list container (that container, not this bubble, would carry `role="log"`).

## Installation

```bash
rails g modelrails_ui:add chat_bubble
```

Creates `app/components/ui/chat_bubble_component.rb`.

## Usage

```erb
<%# Received message (default) %>
<%= ui :chat_bubble do %>
  Hello! How can I help you today?
<% end %>

<%# Sent message %>
<%= ui :chat_bubble, sent: true do %>
  I'd like to book an appointment.
<% end %>
```

## With timestamp

```erb
<%= ui :chat_bubble, sent: true, timestamp: "10:34 AM" do %>
  Sounds great, see you then!
<% end %>
```

## With avatar

The `avatar:` option only applies to received messages (`sent: false`).

```erb
<%= ui :chat_bubble, avatar: user_avatar_url(@agent), timestamp: "10:32 AM" do %>
  I'll check and get back to you shortly.
<% end %>
```

## In a conversation thread

```erb
<div class="flex flex-col gap-4 p-4">
  <% @messages.each do |msg| %>
    <%= ui :chat_bubble,
           sent: msg.mine?,
           timestamp: msg.sent_at.strftime("%H:%M"),
           avatar: msg.mine? ? nil : msg.sender.avatar_url do %>
      <%= msg.body %>
    <% end %>
  <% end %>
</div>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sent` | Boolean | `false` | `true` → right-aligned primary bubble; `false` → left-aligned muted bubble |
| `timestamp` | String | `nil` | Time string shown below the bubble |
| `avatar` | String | `nil` | Avatar image URL — rendered only for received messages |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

## When to use

- Rendering an individual message in a chat thread, comment list, or support inbox.

## When not to use

- You need who-spoke conveyed by alignment/color alone — pass `author:` (or rely
  on the sr-only direction label) so a screen-reader user knows the speaker.
- You want the bubble to be interactive — it is a presentational `<div>`.

## Accessibility contract

- **Guarantees:** the speaker is *always perceivable* in text, never by alignment
  or color alone — a visible `author:` when given, otherwise an sr-only
  "You said" / "They said" direction label (i18n via `t` with English defaults).
  AAA-contrast bubble fills (`bg-interactive` + `text-text-on-interactive` for
  sent; `bg-surface-sunken` + `text-text-body` for received), AAA `text-text-muted`
  timestamp, and a decorative avatar/tail that is `aria-hidden`.
- **You supply:** the message body via slot content; optionally `author:`,
  `timestamp:`, and an `avatar:` URL (received messages only).
