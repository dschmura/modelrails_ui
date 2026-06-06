# Tooltip

A small text bubble that describes the element it wraps. Appears on hover and
keyboard focus. The wrapper span is made focusable (`tabindex="0"`) and
`aria-describedby` wires the `role="tooltip"` bubble to it. Escape dismisses
(WCAG 1.4.13) via the shared `floating` Stimulus controller.

Use for short, non-interactive hints on icon buttons or truncated labels. If
the content is rich or interactive, use `hover_card` instead.

Requires `floating_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add tooltip
```

Creates `app/components/ui/tooltip_component.rb`.

## Usage

```erb
<%= render(UI::TooltipComponent.new(text: "Save to library")) do %>
  <button class="btn-ghost btn-icon" aria-hidden="true">★</button>
<% end %>
```

The `text:` argument is required — it becomes the bubble's visible text and is
referenced via `aria-describedby` on the focusable wrapper.

## Side

| Side | Description |
|------|-------------|
| `:top` | Above the trigger (default) |
| `:bottom` | Below the trigger |
| `:left` | Left of the trigger |
| `:right` | Right of the trigger |

```erb
<%= render(UI::TooltipComponent.new(text: "Delete", side: :right)) do %>
  <button class="btn-ghost btn-icon"><svg ...></svg></button>
<% end %>
```

Unknown values for `side:` raise `ArgumentError` (fail-loud).

## Dismiss on Escape

The tooltip hides automatically when the user presses `Escape`
(`group-data-[dismissed]:opacity-0!`). The `floating` controller clears the
dismissed state on `mouseleave` and `focusout` so the tooltip can reappear on
the next interaction.

## Accessibility contract

The component guarantees:

- The outer `<span>` is focusable (`tabindex="0"`) and carries
  `aria-describedby` pointing to the bubble's `id`.
- The bubble has `role="tooltip"` and the `id` referenced above.
- The bubble is `pointer-events-none` — it never traps the pointer.
- Hover (`group-hover:opacity-100`) and keyboard focus
  (`group-focus-within:opacity-100`) both reveal the bubble.
- `Escape` dismisses without moving focus (WCAG 1.4.13 — content on hover).

You supply:

- `text:` — the hint string (required).
- Block content — the visible trigger (icon, word, or any inline element).

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | String | required | Tooltip bubble text |
| `id` | String | auto `tooltip-<hex>` | Bubble element ID; wired to `aria-describedby` on the wrapper |
| `side` | Symbol | `:top` | `:top`, `:bottom`, `:left`, or `:right` |
| `**html_attrs` | Hash | — | Forwarded to the outer `<span>` wrapper |
