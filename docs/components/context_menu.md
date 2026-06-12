# Context menu

A menu of actions opened by right-clicking (or Shift+F10 / the ContextMenu key on the
keyboard) a host region, implementing the WAI-ARIA APG menu pattern. Behavior is the
shared `menu` Stimulus controller (the same one `dropdown_menu` uses); positioning is JS
(the panel is `fixed`, placed at the pointer or near the host).

Requires `menu_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add context_menu
```

Creates `app/components/ui/context_menu_component.rb` and
`app/javascript/controllers/menu_controller.js`.

## Usage

```erb
<%= render(UI::ContextMenuComponent.new) do |c| %>
  <% c.with_trigger do %>
    <div class="rounded border border-border p-6">Right-click this card</div>
  <% end %>
  <% c.with_item { "Edit" } %>
  <% c.with_item(disabled: true) { "Archive" } %>
  <% c.with_item(separator: true) %>
  <% c.with_item(href: "/reports/new") { "New report" } %>
<% end %>
```

`with_trigger` (the right-clickable host) is required. The host region is made
focusable (`tabindex="0"`) so keyboard users can open the menu with Shift+F10 —
**avoid placing focusable elements (links, buttons, inputs) inside the trigger slot**,
since the host div is itself the focusable unit and nested focusables create redundant
tab stops. Each `with_item` becomes a `role="menuitem"`:

| Option | Effect |
|--------|--------|
| `disabled: true` | `aria-disabled` — skipped by keyboard nav, activation rejected |
| `separator: true` | renders a divider (no content) in source order |
| `href: "/path"` | renders an `<a role="menuitem">` instead of a `<button>` |

Pass `label:` to name the menu explicitly (`aria-label`); omit it to name the menu by
the host region (`aria-labelledby`) — prefer `label:` when the host is large.

## Keyboard

| Key | Action |
|-----|--------|
| right-click on host | Open at the pointer |
| `Shift+F10` / ContextMenu key (host focused) | Open near the host |
| `↓` / `↑` | Move (wraps, skips disabled) |
| `Home` / `End` | First / last item |
| type a letter | Jump to the next item starting with it (1s buffer) |
| `Enter` / `Space` / click | Activate item, close |
| `Escape` | Close, return focus to the host |
| `Tab` / outside-click | Close (focus is not returned to the host) |

## Accessibility

WCAG 2.2 AAA. Keyboard parity (Shift+F10) is mandatory — right-click is pointer-only
(WCAG 2.1.1). Roving tabindex keeps one item focusable at a time. Proven by
`spec/system/ui/context_menu_component_spec.rb` in the host app.
