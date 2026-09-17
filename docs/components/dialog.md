# Dialog

Accessible modal dialog with an overlay, title, description, body, and footer slot. The
native element is chosen over a div so focus-trapping and the inert background come for
free.

> **Migration note:** `alert_dialog` was folded into `dialog` — use
> `ui :dialog, role: :alertdialog` (v0.11.0 breaking change).

Requires `dialog_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add dialog
```

Creates `app/components/ui/dialog_component.rb`.

## Usage

```erb
<%= ui :dialog, title: "Edit profile", description: "Make changes to your profile here." do |dialog| %>
  <% dialog.with_trigger { ui :button, "Open dialog" } %>

  <%= ui :form_field, label: "Name" do %>
    <%= ui :input, name: "name", id: "name" %>
  <% end %>

  <% dialog.with_footer do %>
    <%= ui :button, "Cancel",       variant: :outline,
                    data: { action: "click->dialog#close" } %>
    <%= ui :button, "Save changes", type: "submit" %>
  <% end %>
<% end %>
```

## Without a trigger slot

Open programmatically by calling `dialog#open` from another Stimulus action:

```erb
<%= ui :dialog, title: "Confirmation" do |dialog| %>
  <p>Are you sure you want to proceed?</p>
  <% dialog.with_footer do %>
    <%= ui :button, "Confirm", variant: :destructive %>
  <% end %>
<% end %>
```

## Close on Escape

The dialog closes automatically when the user presses `Escape`.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | String | `nil` | Bold heading rendered inside the panel |
| `description` | String | `nil` | Muted subtext below the title |
| `role` | Symbol | `:dialog` | `:dialog` or `:alertdialog` — an assertive confirm gate announced immediately by screen readers, capped at `max-w-md` regardless of `size:` |
| `id` | String | `nil` | Element id; required (or `body_id:`) when `wrapper: true` in dev/test. `modal-{random}` is minted whenever `id:` is omitted, which under `wrapper: true` produces the silent-no-op bug described below. |
| `body_id` | String | `nil` | Turbo Stream target id for the dialog body; defaults to `"#{id}-body"`. Required (or `id:`) when `wrapper: true` in dev/test. |
| `wrapper` | Boolean | `true` | Wraps the dialog in a `data-controller="modal"` div with a trigger slot. Set `false` to render only the `<dialog>` and own the wrapper |
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `trigger` | No | Element that opens the dialog on click |
| `footer` | No | Action buttons shown at the bottom of the panel |

## Turbo Stream targeting

When using `wrapper: true` without an explicit `id:` or `body_id:`, the component raises an `ArgumentError` in development and test environments. This fail-loud rule surfaces a silent bug: Turbo Streams aimed at a randomly-generated body id silently no-op in production, leaving the page out of sync. Always provide an explicit `id:` when using `wrapper: true`; `body_id` then derives as `"#{id}-body"`.

## When to use

- You need a focus-trapped modal for a confirmation, form, or detail overlay.
- A choice must be confirmed before proceeding — pass `role: :alertdialog` for an
  assertive confirm gate that screen readers announce immediately (destructive or
  irreversible actions: delete, reset, revoke access).
- You are building a custom wrapper (pass `wrapper: false` and own the
  `data-controller="modal"` element + trigger).

## When not to use

- The action is a destructive non-GET — keep the submit in a `button_to` form;
  the dialog is the container, not the action mechanism.
- You need a non-blocking notification — use the toast / notification system.

## Accessibility contract

- **Guarantees:** native `<dialog>` semantics (`role="dialog"`, `aria-modal="true"`),
  `aria-labelledby` wired to the heading, `aria-describedby` when `description:` is
  given, an accessible close button, and focus trap + restore via the `modal`
  controller.
- **You supply:** a `title:` (required — it is the accessible name). With
  `wrapper: true` (default) the `trigger` slot is the open button; `wrapper: false`
  requires you to wire `data-controller="modal"` and a trigger yourself.

Chrome lives in UI::ModalChrome — single owner.
