# Sheet

Slide-in panel attached to one edge of the viewport. Use for secondary content, filters, or navigation drawers on desktop.
Behavior lives in the `modal` Stimulus controller with per-side slide transform values.

Requires `sheet_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add sheet
```

Creates `app/components/ui/sheet_component.rb`.

## Usage

```erb
<%= ui :sheet, title: "Cart", side: :right do |sheet| %>
  <% sheet.with_trigger { ui :button, "Open cart" } %>

  <p>Your cart is empty.</p>

  <% sheet.with_footer do %>
    <%= ui :button, "Checkout", class: "w-full" %>
  <% end %>
<% end %>
```

## Sides

| Side | Description |
|------|-------------|
| `:right` | Slides in from the right (default) |
| `:left` | Slides in from the left |
| `:top` | Slides down from the top |
| `:bottom` | Slides up from the bottom |

```erb
<%= ui :sheet, side: :left, title: "Navigation" do |sheet| %>
  <% sheet.with_trigger { ui :button, "Menu", variant: :ghost } %>
  <nav>…</nav>
<% end %>
```

## Close on overlay click or Escape

Clicking the backdrop or pressing `Escape` closes the sheet.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | String | `nil` | Panel heading |
| `description` | String | `nil` | Muted subtext below the title |
| `side` | Symbol | `:right` | `:right`, `:left`, `:top`, or `:bottom` |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `trigger` | No | Element that opens the sheet on click |
| `footer` | No | Action buttons at the bottom of the panel |

## When to use

- A side panel is the right pattern for navigation, filters, or secondary
  forms that slide in from a screen edge.
- You need a supplemental overlay anchored to the left, right, top, or
  bottom edge of the viewport.

## When not to use

- A centered confirm gate is needed — use `dialog` with `role: :alertdialog`.
- A bottom sheet is the right pattern — use `drawer`.

## Accessibility contract

- **Guarantees:** native `<dialog>` with `role="dialog"` and `aria-modal="true"`,
  `aria-labelledby` wired to the heading, `aria-describedby` when `description:`
  is given, a 44px accessible close button (`btn-touch-target`), focus trap +
  restore via the `modal` controller, and native Escape via the controller's
  cancel handler.
- **You supply:** a `title:` (required — ViewComponent raises if omitted; it is
  the accessible name). Actions belong in the `footer` slot. With `wrapper: true`
  (default) the `trigger` slot is the open button; `wrapper: false` renders ONLY
  the `<dialog>` for embedding in an existing `data-controller="modal"` structure.

Chrome lives in UI::ModalChrome — single owner.
