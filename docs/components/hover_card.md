# Hover Card

A rich supplemental card revealed on hover and keyboard focus of its trigger.
Unlike `tooltip`, the card may hold interactive content (links, buttons);
`focus-within` keeps it open while the user Tabs through that content. Escape
dismisses (WCAG 1.4.13) via the shared `floating` Stimulus controller.

Use for enhancement — the card's content should never be the only path to that
information. If you need a click-triggered panel, use `popover`. If the hint is
short and non-interactive, use `tooltip`.

Requires `floating_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add hover_card
```

Creates `app/components/ui/hover_card_component.rb`.

## Usage

```erb
<%= render(UI::HoverCardComponent.new) do |c| %>
  <% c.with_trigger do %>
    <%= link_to "@dave", profile_path, class: "underline" %>
  <% end %>
  <div class="space-y-1">
    <p class="font-medium text-text-heading">Dave Chmura</p>
    <p class="text-text-body">Building modelrails_ui.</p>
    <a href="#" class="text-text-body underline">View profile</a>
  </div>
<% end %>
```

The `with_trigger` slot is required — omitting it raises `ArgumentError`.

## Side

| Side | Description |
|------|-------------|
| `:bottom` | Below the trigger (default) |
| `:top` | Above the trigger |
| `:left` | Left of the trigger |
| `:right` | Right of the trigger |

```erb
<%= render(UI::HoverCardComponent.new(side: :right)) do |c| %>
  <% c.with_trigger { link_to "More info", "#" } %>
  <p class="text-text-body">Additional details appear here.</p>
<% end %>
```

Unknown values for `side:` raise `ArgumentError` (fail-loud).

## Accessible group label

Pass `label:` to wrap the card in `role="group"` with an `aria-label`. Use
this when the card contains multiple interactive elements that benefit from a
named region:

```erb
<%= render(UI::HoverCardComponent.new(label: "User card")) do |c| %>
  <% c.with_trigger { "@dave" } %>
  <p class="text-text-body">Profile preview.</p>
<% end %>
```

Omitting `label:` renders the card as a plain `<div>` without a role.

## Dismiss on Escape

The card hides automatically when the user presses `Escape`
(`group-data-[dismissed]:invisible! group-data-[dismissed]:opacity-0!`). The
`floating` controller clears the dismissed state on `mouseleave` and `focusout`
so the card can reappear on the next interaction.

## Accessibility contract

The component guarantees:

- Hover (`group-hover:opacity-100`) and keyboard focus-within
  (`group-focus-within:opacity-100`) both reveal the card.
- The card remains open while the user Tabs through its links or buttons
  (`focus-within` covers the trigger and all card descendants).
- `Escape` dismisses without moving focus (WCAG 1.4.13 — content on hover).
- When `label:` is given, the card element receives `role="group"` and
  `aria-label` for a named landmark region.

You supply:

- `with_trigger` slot — a focusable link or button (required).
- Block content — the card's body (text, links, arbitrary markup).
- `label:` — optional accessible name for the card region.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | String | auto `hovercard-<hex>` | Card element ID |
| `label` | String | `nil` | Accessible name → `role="group"` + `aria-label` on the card |
| `side` | Symbol | `:bottom` | `:bottom`, `:top`, `:left`, or `:right` |
| `**html_attrs` | Hash | — | Forwarded to the outer `<span>` wrapper |

| Slot | Required | Description |
|------|----------|-------------|
| `with_trigger` | Yes | Focusable element (link/button) that triggers the card — omitting raises `ArgumentError` |
