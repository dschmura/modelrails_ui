# Popover

Non-modal floating panel anchored to a trigger button. Placement is CSS anchor
positioning — the panel is `position: fixed`, tethered to the trigger's wrapper by
`anchor-name`/`position-anchor`, with the author picking `side` and `align`.
Open/close behavior lives in the `floating` Stimulus controller shipped with this
component.

Requires `floating_controller.js` and the shared `overlays/top_layer.js` module
(both copied automatically by the generator, which also adds the importmap pin).

## Installation

```bash
rails g modelrails_ui:add popover
```

Creates `app/components/ui/popover_component.rb`.

## Usage

```erb
<%= render(UI::PopoverComponent.new(label: "Account options")) do |c| %>
  <% c.with_trigger { "Account" } %>
  <p class="text-sm">Manage your account settings here.</p>
<% end %>
```

The `label:` argument is required — it becomes the panel's accessible name
(`aria-label` on the `role="dialog"` panel). The `with_trigger` slot is also
required; omitting it raises `ArgumentError`.

## Alignment

| Align | Description |
|-------|-------------|
| `:start` | Left-aligned (default) |
| `:center` | Horizontally centered |
| `:end` | Right-aligned |

## Side

| Side | Description |
|------|-------------|
| `:bottom` | Below trigger (default) |
| `:top` | Above trigger |
| `:left` | Left of trigger |
| `:right` | Right of trigger |

```erb
<%= render(UI::PopoverComponent.new(label: "Quick settings", align: :end, side: :bottom)) do |pop| %>
  <% pop.with_trigger { "Settings" } %>
  <p class="text-sm">Quick settings panel.</p>
<% end %>
```

Unknown values for `align:` or `side:` raise `ArgumentError` (fail-loud).

## Close on Escape

The popover closes automatically when the user presses `Escape`. Focus returns
to the trigger button.

## Close on outside click

Clicking outside the popover closes it automatically. Focus returns to the
trigger button.

## Stacking contexts and the top layer

Because the panel is viewport-positioned, it is promoted to the browser's **top
layer** while open. That matters because a `sticky` header or a `backdrop-blur`
navbar establishes a stacking context, and a `z-50` panel inside one is trapped
there — no z-index escapes a stacking context from the inside. Promotion paints the
panel above the whole page while leaving it in the DOM, so the actions inside it
stay wired.

On browsers without CSS anchor positioning the panel falls back to `absolute`
offsets and is deliberately **not** promoted: the top layer re-parents an element's
containing block to the viewport, which would resolve those offsets against the
screen and tear the panel off its trigger. The fallback keeps today's behaviour —
correctly placed, but buriable by a stacking context.

An `overflow: hidden` or CSS-transformed ancestor can still clip the fallback path.

## Accessibility contract

The component guarantees:

- A real `<button>` trigger with `aria-haspopup="dialog"`, `aria-expanded`
  (kept in sync by the `floating` controller), and `aria-controls` pointing to
  the panel.
- A panel with `role="dialog"`, named by `label:` via `aria-label`, and
  `tabindex="-1"` so it receives focus on open.
- The panel is hidden (`hidden` attribute) until opened; `aria-expanded` is
  `"false"` on load.
- `Escape` and outside-click both close the panel and return focus to the
  trigger.
- Non-modal — focus is **not** trapped; Tab can leave the panel freely.

You supply:

- `label:` — the accessible name for the panel (required).
- `with_trigger` slot — the button's visible content (required).

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | required | Accessible name for the panel → `aria-label` on `role="dialog"` |
| `id` | String | auto `popover-<hex>` | Panel element ID; wired to `aria-controls` on the trigger |
| `align` | Symbol | `:start` | `:start`, `:center`, or `:end` |
| `side` | Symbol | `:bottom` | `:bottom`, `:top`, `:left`, or `:right` |
| `trigger_class` | String | `"btn-secondary"` | CSS classes applied to the trigger `<button>` |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `with_trigger` | Yes | Visible content of the trigger button — omitting raises `ArgumentError` |
