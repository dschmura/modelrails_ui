# Drawer

Bottom sheet that slides up from the bottom of the viewport. Includes a drag handle and is suited for mobile actions.
Behavior lives in the `modal` Stimulus controller with slide-up/down transform values.

Requires `drawer_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add drawer
```

Creates `app/components/ui/drawer_component.rb`.

## Usage

```erb
<%= ui :drawer, title: "Share post" do |drawer| %>
  <% drawer.with_trigger { ui :button, "Share" } %>

  <p class="text-sm text-muted-foreground">Choose how you want to share this post.</p>

  <% drawer.with_footer do %>
    <%= ui :button, "Copy link", class: "w-full" %>
  <% end %>
<% end %>
```

## Close behaviour

Clicking the overlay or pressing `Escape` closes the drawer. The drag handle is decorative; it does not enable drag-to-close.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | String | `nil` | Bold heading inside the panel |
| `description` | String | `nil` | Muted subtext below the title |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `trigger` | No | Element that opens the drawer on click |
| `footer` | No | Action buttons at the bottom of the panel |

## When to use

- A bottom sheet is the right pattern for mobile-friendly secondary actions
  or content that slides in from the bottom edge.
- You need a supplemental overlay that doesn't require center-stage emphasis.

## When not to use

- A centered confirm gate is needed — use `dialog` with `role: :alertdialog`.
- A side panel is needed — use `sheet`.

## Accessibility contract

- **Guarantees:** native `<dialog>` with `role="dialog"` and `aria-modal="true"`,
  `aria-labelledby` wired to the heading, `aria-describedby` when `description:`
  is given, a 44px accessible close button (`btn-touch-target`), focus trap +
  restore via the `modal` controller, and native Escape via the controller's
  cancel handler. The drag handle is purely decorative (`aria-hidden`).
- **You supply:** a `title:` (required — ViewComponent raises if omitted; it is
  the accessible name). Actions belong in the `footer` slot. With `wrapper: true`
  (default) the `trigger` slot is the open button; `wrapper: false` renders ONLY
  the `<dialog>` for embedding in an existing `data-controller="modal"` structure.

Chrome lives in UI::ModalChrome — single owner.
