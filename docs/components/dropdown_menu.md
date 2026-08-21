# Dropdown menu

A button that opens a menu of actions, implementing the WAI-ARIA APG menu-button
pattern. Open/close and the full keyboard model live in the `menu` Stimulus
controller shipped with this component; placement is CSS anchor positioning.

Requires `menu_controller.js`, `submenu_controller.js` and the shared
`overlays/top_layer.js` module (all copied automatically by the generator, which
also adds the importmap pin).

## Installation

```bash
rails g modelrails_ui:add dropdown_menu
```

Creates `app/components/ui/dropdown_menu_component.rb`,
`app/javascript/controllers/{menu,submenu}_controller.js` and
`app/javascript/overlays/top_layer.js`, and pins `overlays` in your importmap.

## Usage

```erb
<%= render(UI::DropdownMenuComponent.new) do |c| %>
  <% c.with_trigger { "Actions" } %>
  <% c.with_item { "Edit" } %>
  <% c.with_item(disabled: true) { "Archive" } %>
  <% c.with_item(separator: true) %>
  <% c.with_item(href: "/reports/new") { "New report" } %>
<% end %>
```

The `with_trigger` slot is required (omitting it raises `ArgumentError`). Each
`with_item` becomes a `role="menuitem"`:

| Option | Effect |
|--------|--------|
| `disabled: true` | `aria-disabled` — skipped by keyboard nav, activation rejected |
| `separator: true` | renders a divider (no content) in source order |
| `href: "/path"` | renders an `<a role="menuitem">` instead of a `<button>` |
| `checkbox: true` | `role="menuitemcheckbox"` — toggles in place, menu stays open |
| `radio: "group"` | `role="menuitemradio"` — selecting one clears its group |
| `checked: true` | initial `aria-checked` (rendered server-side) |
| `tone: :danger` | destructive action — the label takes the danger signal colour |
| `submenu: "Label"` | nested menu; the block yields a builder (see below) |

Icon-only triggers MUST pass `aria_label:` (the menu button's accessible name):

```erb
<%= render(UI::DropdownMenuComponent.new(aria_label: "Row actions")) do |c| %>
  <% c.with_trigger { tag.svg(...) } %>
  ...
<% end %>
```

## Checkable items

`aria-checked` is rendered from server state, so the menu is correct before any JS
runs. Activating a checkable item toggles it **in place and leaves the menu open** —
what makes a multi-select view menu usable in one pass. Plain items still close.

```erb
<% c.with_item(checkbox: true, checked: @show_grid) { "Show grid" } %>
<% c.with_item(radio: "density", value: "compact", checked: true) { "Compact" } %>
<% c.with_item(tone: :danger) { "Delete view" } %>
```

Persisting the change is yours — wire the item's own `data-action`, or submit a form.

## Submenus

```erb
<% c.with_item(submenu: "Share") do |sub| %>
  <% sub.with_item { "Email" } %>
  <% sub.with_item(href: "/copy") { "Copy link" } %>
<% end %>
```

The sub-trigger is simultaneously an item of the parent menu (so it stays in the
parent's arrow-key rotation) and the trigger of its own submenu. That works because
the nested controller uses a distinct identifier — `data-menu-target="item"` binds
outward, `data-submenu-target="trigger"` binds inward.

## Placement

| Arg | Values | Default |
|-----|--------|---------|
| `side` | `:bottom`, `:top` | `:bottom` |
| `align` | `:start`, `:end` (edge-aligned to the trigger) | `:start` |

Placement uses CSS anchor positioning with an `absolute`-offset fallback on
pre-Baseline-2026 browsers; `position-try-fallbacks: flip-block` keeps the menu
on-screen. Submenus open to the side and flip inline near an edge.

Because the panel is `position: fixed` (tethered by `anchor-name`/`position-anchor`),
it is promoted to the browser's **top layer** when open. That is what lets it escape a
stacking context — a `sticky` header or a `backdrop-blur` navbar traps a `z-50` panel
inside it, and no z-index fixes that from within. On the pre-Baseline fallback the panel
stays `absolute` and is deliberately **not** promoted: the top layer re-parents an
element's containing block to the viewport, which would tear an offset-placed panel off
its trigger.

## Keyboard

| Key | Action |
|-----|--------|
| `Enter` / `Space` / `↓` (on trigger) | Open, focus first item |
| `↑` (on trigger) | Open, focus last item |
| `↓` / `↑` (in menu) | Move (wraps, skips disabled) |
| `Home` / `End` | First / last item |
| type a letter | Jump to the next item starting with it (1s buffer) |
| `Enter` / `Space` / click | Activate item, close |
| `→` / `Enter` (on a sub-trigger) | Open the submenu, focus its first item |
| `←` (in a submenu) | Close it, return focus to the sub-trigger |
| `Escape` | Close, return focus to trigger (a submenu closes first) |
| `Tab` | Close, advance focus to the next page element |

## Accessibility

WCAG 2.2 AAA. The menu is named by its trigger (`aria-labelledby`); the trigger
exposes `aria-haspopup="menu"` and a synced `aria-expanded`. Roving tabindex keeps
exactly one item focusable at a time. Proven by `spec/system/ui/dropdown_menu_component_spec.rb`
in the host app (keyboard + axe AAA in both themes).
