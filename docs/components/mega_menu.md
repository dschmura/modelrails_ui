# MegaMenu

Full-width dropdown panel anchored to a trigger button, organised into titled columns.

Requires `mega_menu_controller.js` (copied automatically by the generator). Open/close is
owned by the component's own `mega-menu` Stimulus controller (a simple disclosure toggle).

## Installation

```bash
rails g modelrails_ui:add mega_menu
```

Creates `app/components/ui/mega_menu_component.rb`.

## Usage

```erb
<%= ui :mega_menu, label: "Products" do |menu| %>
  <% menu.with_column(heading: "Design", items: [
    { title: "UI Kit",     description: "Tailwind component library", href: "/ui-kit" },
    { title: "Templates",  description: "Ready-to-use page templates", href: "/templates" }
  ]) %>
  <% menu.with_column(heading: "Developer", items: [
    { title: "CLI",        description: "Command-line generator",     href: "/cli" },
    { title: "API",        description: "Full API reference",         href: "/api" }
  ]) %>
<% end %>
```

## Fixed column count

By default the panel uses as many columns as slots. Override with `cols:`:

```erb
<%= ui :mega_menu, label: "Solutions", cols: 3 do |menu| %>
  <% menu.with_column(items: [...]) %>
  <% menu.with_column(items: [...]) %>
<% end %>
```

## API

### MegaMenuComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | required | Trigger button text |
| `cols` | Integer | `nil` | Grid column count; defaults to number of `with_column` slots |
| `**html_attrs` | Hash | — | Forwarded to the outer wrapper `<div>` |

### ColumnComponent (via `with_column`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `heading` | String | `nil` | Optional column heading shown in small uppercase text |
| `items` | Array | `[]` | Array of `{ title:, description:, href: }` hashes |

## Menu-vs-nav semantics (deliberate)

This is a **disclosure + navigation region**, NOT the WAI-ARIA `menu` pattern,
so it does NOT reuse the shared `menu` controller (which `dropdown_menu`/`menubar`
consume). `role="menu"`/`menuitem` is for a list of *commands* with a roving-tabindex
arrow-key model; this panel holds ordinary `<a>` navigation links that must keep
native Tab/anchor behavior. Forcing `role=menu` here would impose a keyboard model
the links don't honour and remove them from the link/landmark trees. So: a real
`<button>` disclosure (`aria-expanded` + `aria-haspopup` + `aria-controls`) reveals a
named `<nav>` region of links.

## Accessibility contract

- **Guarantees:** a real `<button>` trigger with `aria-haspopup`, synced
  `aria-expanded`, and `aria-controls` pointing at the panel; the panel is a named
  `<nav>` landmark (`aria-label` ← the trigger label); the AAA `focus-ring` on the
  trigger and every link; outside-click dismissal; the chevron is decorative
  (`aria-hidden`).
  The `<ul>` carries an explicit `role="list"`: Tailwind's preflight sets
  `list-style: none`, and Safari/VoiceOver drop the implicit list role once the
  marker is gone — taking the item count and per-item set position with it. No
  axe rule covers this.
- **You supply:** a `label:` (trigger text) and one or more `with_column` blocks.
