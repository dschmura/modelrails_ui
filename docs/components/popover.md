# Popover

Non-modal floating panel anchored to a trigger button. Positioning is CSS (a
`relative` wrapper + `absolute` panel — the author picks `side` and `align`);
open/close behavior lives in the `floating` Stimulus controller shipped with
this component. Placement is CSS anchor positioning: the panel is `position: fixed` (so
its containing block is the viewport), tethered to the trigger via
`anchor-name`/`position-anchor`; `position-area` places it and `position-try-fallbacks`
keeps it on-screen. Being viewport-positioned is also what lets it be promoted to the
browser top layer, so a `sticky`/`backdrop-blur` ancestor cannot bury it.

Requires `floating_controller.js` (copied automatically by the generator).

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

## Limitation

The panel has no top layer — it is `position: absolute` inside its wrapper. A
popover placed inside an `overflow: hidden` or CSS-transformed ancestor can be
clipped. Restructure the markup to avoid the clipping context, or use `dialog`
instead.

## Accessibility contract

- **Guarantees:** a real `<button>` trigger with `aria-haspopup="dialog"`,
  `aria-expanded` (kept in sync), and `aria-controls` to the panel; the panel is
  `role="dialog"` named by `label:`; Escape and outside-click close and return
  focus to the trigger. Non-modal — focus is NOT trapped. The `aria-expanded`
  sync is kept in sync by the `floating` controller; the panel also carries
  `tabindex="-1"` so it receives focus on open, and is hidden (`hidden`
  attribute) until opened, with `aria-expanded` `"false"` on load; Tab can
  leave the panel freely.
- **You supply:** a `label:` (the panel's accessible name) and a `with_trigger`
  slot (the button's visible content).

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | required | Accessible name for the panel → `aria-label` on `role="dialog"` |
| `id` | String | auto `popover-<hex>` | Panel element ID; wired to `aria-controls` on the trigger |
| `align` | Symbol | `:start` | `:start`, `:center`, or `:end` |
| `side` | Symbol | `:bottom` | `:bottom`, `:top`, `:left`, or `:right` |
| `trigger_class` | String | `"btn-secondary"` | CSS classes **added to** the trigger's accessibility floor (focus ring + 44px target size), which cannot be replaced |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `with_trigger` | Yes | Visible content of the trigger button — omitting raises `ArgumentError` |

## When to use

- You need a small interactive overlay (a menu of actions, a filter form, details)
  tied to a trigger that does NOT need to block the page.

## When not to use

- The content must block interaction until dismissed — use `dialog` (`role: :alertdialog` for a confirm gate).
- You only need a hint describing a control — use `tooltip`.
