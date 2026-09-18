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

## Placement

Placement uses CSS anchor positioning: the bubble is `position: fixed` (viewport as
containing block) and tethered to the trigger via inline `anchor-name`/`position-anchor`
attributes; `position-area` sets the requested side and `position-try-fallbacks` keeps
it on-screen near viewport edges. Note that at an extreme edge Chromium clamps the
element on-screen rather than performing a full flip, because the bubble is nested inside
its trigger element. On browsers without anchor positioning (pre-Baseline 2026) the
component falls back to `absolute` offsets relative to the wrapper.

Placement uses CSS anchor positioning: the bubble is `position: fixed` (so its
containing block is the viewport, letting it float free of the wrapper) and tethered
to the wrapper via `anchor-name`/`position-anchor`; `position-area` places it and
`position-try-fallbacks` auto-flips it on viewport overflow — no JS.

## Dismiss on Escape

The tooltip hides automatically when the user presses `Escape`
(`group-data-[dismissed]/tooltip:opacity-0!`). The `floating` controller clears the
dismissed state on `mouseleave` and `focusout` so the tooltip can reappear on
the next interaction.

## Named group — nesting inside other `.group` containers

The wrapper is the **named** group `group/tooltip`, and the bubble's reveal
variants are `group-hover/tooltip:` / `group-focus-within/tooltip:` /
`group-data-[dismissed]/tooltip:`. Tailwind's unnamed `group-*:` variants match
ANY `.group` ancestor — a tooltip nested inside a grouped container (a `.group`
`<details>`, a card) had every bubble raised whenever hover or focus sat
anywhere inside that ancestor. The named group scopes the reveal to the
tooltip's own wrapper.

## Describing an existing interactive control

The component makes its own wrapper the focusable trigger, so don't wrap an
already-interactive control. Instead put `aria-describedby` on that control,
build your own `group/tooltip relative` wrapper, and reuse the bubble exactly
via the public API:

```erb
<span class="group/tooltip relative inline-flex">
  <button aria-describedby="save-tip" class="btn-ghost btn-icon">★</button>
  <span id="save-tip" role="tooltip"
        class="<%= UI::TooltipComponent.bubble_classes(side: :bottom) %>">
    Save to library
  </span>
</span>
```

`bubble_classes(side:)` returns the bubble's base classes plus the placement
classes for the given side (default `:top`); an unknown side raises `KeyError`.

## Accessibility contract

- **Guarantees:** shows on hover AND focus; `role="tooltip"` bubble wired via
  `aria-describedby`; Escape dismisses without moving focus; `pointer-events-none`
  so the bubble never traps the pointer. The outer `<span>` is focusable
  (`tabindex="0"`) and carries that `aria-describedby` pointing to the bubble's
  `id`; the hover/focus reveal is scoped to the tooltip's own named group,
  never another `.group` ancestor.
- **You supply:** `text:` (the hint) and the trigger content (icon/word, or
  any inline element).

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | String | required | Tooltip bubble text |
| `id` | String | auto `tooltip-<hex>` | Bubble element ID; wired to `aria-describedby` on the wrapper |
| `side` | Symbol | `:top` | `:top`, `:bottom`, `:left`, or `:right` |
| `**html_attrs` | Hash | — | Forwarded to the outer `<span>` wrapper |

## When to use

- You need a short, non-interactive hint describing a single focusable trigger
  (an icon button, a truncated label).

## When not to use

- The content is interactive or rich — use `hover_card`.
- You wrap an already-interactive control — put `aria-describedby` on that control
  instead (this component makes its own wrapper the focusable trigger).
