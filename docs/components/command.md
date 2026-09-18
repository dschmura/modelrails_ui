# Command

Command palette dialog with a search input and filterable item list. Opens over an overlay on trigger click.
Opened on a `with_trigger` click or the global `⌘K` / `Ctrl+K` shortcut; filtering and
keyboard navigation live in the `command` Stimulus controller shipped alongside this
component.

Requires `command_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add command
```

Creates `app/components/ui/command_component.rb`.

## Usage

```erb
<%= ui :command do |cmd| %>
  <% cmd.with_trigger { ui :button, "⌘K", variant: :outline } %>

  <%# Group heading + items %>
  <div class="<%= UI::CommandComponent::GROUP_WRAPPER %>">
    <p class="<%= UI::CommandComponent::GROUP %>">Pages</p>
    <button class="<%= UI::CommandComponent::ITEM %>" type="button">
      Dashboard
      <span class="<%= UI::CommandComponent::SHORTCUT %>">⌘D</span>
    </button>
    <button class="<%= UI::CommandComponent::ITEM %>" type="button">Settings</button>
  </div>

  <hr class="<%= UI::CommandComponent::SEPARATOR %>">

  <div class="<%= UI::CommandComponent::GROUP_WRAPPER %>">
    <p class="<%= UI::CommandComponent::GROUP %>">Actions</p>
    <button class="<%= UI::CommandComponent::ITEM %>" type="button">New document</button>
  </div>
<% end %>
```

## Filtering

The search input filters visible items client-side. Any item whose text content does not match the query is hidden. When no items match, a "No results found." message is shown automatically.

## Panel CSS constants

| Constant | Use for |
|----------|---------|
| `GROUP_WRAPPER` | Container `<div>` for a group |
| `GROUP` | Group heading `<p>` |
| `ITEM` | Actionable `<button>` or `<a>` items |
| `SHORTCUT` | Keyboard shortcut hint placed inside an item |
| `SEPARATOR` | `<hr>` rule between groups |

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `**html_attrs` | Hash | — | Forwarded to the outer `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `trigger` | No | Element that opens the command palette on click |

## When to use

- You need a keyboard-first launcher to jump to pages or fire actions
  (the spotlight / ⌘K pattern).

## When not to use

- A trigger opens a short list of *actions* with no search — use
  `dropdown_menu` (the APG menu-button pattern).
- You're selecting a value to submit in a form — use a `select`/listbox.

## Accessibility contract (WAI-ARIA APG combobox + listbox)

- **Guarantees:** the search input is a `role="combobox"` with
  `aria-expanded`, `aria-controls` (→ the list) and `aria-autocomplete="list"`;
  the list is a named `role="listbox"`; the controller promotes each
  `[data-command-value]` item to `role="option"` with a stable id and tracks
  the highlighted option via `aria-activedescendant` (DOM focus stays on the
  input — ↑/↓ move the active option, Enter activates it, Escape closes).
  The input and items carry the AAA `focus-ring`; the empty-state message is
  an i18n-labelled live region.
- **You supply:** an optional `with_trigger` slot and the grouped item markup
  (use the exposed `GROUP_WRAPPER` / `GROUP` / `ITEM` / `SHORTCUT` /
  `SEPARATOR` constants). Each actionable item must carry a
  `data-command-value` (the text the filter matches on). Optional
  `data-command-keywords` adds synonyms an item can be found by without
  showing them in its label ("configuration" finding Settings).

## Sizes

`sm` · `md` · `lg` — the centered panel's max width.
