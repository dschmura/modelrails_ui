# Hover Card

A rich supplemental card revealed on hover and keyboard focus of its trigger.
Unlike `tooltip`, the card may hold interactive content (links, buttons). A short
hover-intent close-delay keeps the card reachable, so the pointer can move from the
trigger onto the card to click it — and `focus-within` / Tab keeps it open for
keyboard users. `Escape` closes the card and returns focus to the trigger (WCAG
1.4.13). All behavior lives in the shared `floating` Stimulus controller.

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

## Placement

Placement uses CSS anchor positioning: the card is `position: fixed` (viewport as
containing block) and tethered to the trigger via inline `anchor-name`/`position-anchor`
attributes; `position-area` sets the requested side and `position-try-fallbacks` keeps
it on-screen near viewport edges. Note that at an extreme edge Chromium clamps the
element on-screen rather than performing a full flip, because the card is nested inside
its trigger element. On browsers without anchor positioning (pre-Baseline 2026) the
component falls back to `absolute` offsets relative to the wrapper.

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

## Hover-intent & dismissal

The card is opened and closed by the `floating` controller, not by CSS `:hover`
alone — pure CSS can't keep an *interactive* card reachable across the small gap
between trigger and card. The controller opens on `mouseenter` / `focus` and
closes on `mouseleave` / `blur` **after a short delay** (`hideDelay`, default
`150`ms). The delay survives the gap crossing (and brief mouse-outs), so the
pointer can move onto the card and click its content. Opening sets
`data-state="open"` on the wrapper; `group-data-[state=open]` reveals the card.

`Escape` closes the card immediately and returns focus to the trigger.

## Accessibility contract

- **Guarantees:** opens on hover AND focus; the hover-intent close-delay keeps the
  card reachable, so its content is clickable and Tab-reachable; Escape closes and
  returns focus to the trigger; `role="group"` + `aria-label` when `label:` is given.
- **You supply:** a `with_trigger` slot (a focusable link/button) and the card content.

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

## When to use

- A link/avatar benefits from a supplemental preview (profile, definition) whose
  content is ALSO reachable elsewhere (the card is an enhancement, not the only path).

## When not to use

- The content is a primary interactive surface — use `popover` (click) or a `dialog`.
- It's a short text hint — use `tooltip`.
