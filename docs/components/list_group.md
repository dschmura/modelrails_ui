# List Group

Bordered list of items with optional active state, links, and muted variant. Copies two files: `ListGroupComponent` (the `<ul>` wrapper) and `ListGroupItemComponent` (each `<li>` or `<a>`).

## Installation

```bash
rails g modelrails_ui:add list_group
```

Creates:
- `app/components/ui/list_group_component.rb`
- `app/components/ui/list_group_item_component.rb`

## Usage

```erb
<%= ui :list_group do %>
  <%= ui :list_group_item, "Dashboard" %>
  <%= ui :list_group_item, "Settings" %>
  <%= ui :list_group_item, "Billing" %>
  <%= ui :list_group_item, "Help", variant: :muted %>
<% end %>
```

## With links

Pass `href:` to render each item as an `<a>` tag:

```erb
<%= ui :list_group do %>
  <%= ui :list_group_item, "Home",     href: "/" %>
  <%= ui :list_group_item, "Profile",  href: "/profile", active: true %>
  <%= ui :list_group_item, "Logout",   href: "/logout" %>
<% end %>
```

## Rich content via block

```erb
<%= ui :list_group do %>
  <%= ui :list_group_item do %>
    <span class="font-medium">Alice</span>
    <span class="text-muted-foreground text-xs">Online</span>
  <% end %>
<% end %>
```

## ListGroupItem variants

| Variant | Description |
|---------|-------------|
| `default` | Normal item |
| `active` | Filled with `bg-interactive` — also set via `active: true`, which **requires `href:`** |
| `muted` | Muted text colour |

**`active: true` needs an `href:`.** It marks the current page among navigable
rows, so it needs somewhere to navigate. On a static row it would paint the solid
interactive fill — the strongest "this is the current, actionable thing" signal in
the system — on an element that cannot be focused or activated, and that correctly
declines `aria-current`: current to the eye, silent to assistive technology. The
component raises in development and test, and falls back to `default` in production
rather than 500ing a page.

**Hover follows interactivity, not variant.** A row highlights on hover only when
it has an `href:`. A static row is a plain, non-focusable `<li>`, so a full-width
highlight on it would promise a click target that does not exist — including the
common shape where the row is static and only a small child (a button, a link) is
actionable.

An **active** link row does not highlight either: it already carries the solid
`bg-interactive` fill, and hovering it to `bg-surface-sunken` while it keeps
`text-text-on-interactive` would put white text on a near-white surface in the
light theme. That empty cell in the hover map is deliberate — see
`ListGroupItemComponent::HOVER`.

## API — ListGroupComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `role` | String | `"list"` | Role on the `<ul>`; pass your own to override |
| `**html_attrs` | Hash | — | Forwarded to the `<ul>` element |

`role:` and `"role" =>` are equivalent — keys are normalized before the merge,
so an override replaces the default instead of emitting a second `role`
attribute.

## API — ListGroupItemComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | `nil` | Item text — positional or `label:` keyword, alternative to block |
| `href` | String | `nil` | Renders an `<a>` tag instead of `<li>` when set |
| `active` | Boolean | `false` | Applies the active variant |
| `variant` | Symbol | `:default` | `:default`, `:active`, `:muted` |
| `**html_attrs` | Hash | — | Forwarded to the rendered element |

## Accessibility contract

- **Guarantees:** a semantic `<ul>` carrying an explicit `role="list"`, on a
  token surface (`bg-surface-raised`, `border-border`, `divide-border` between rows).
  The explicit role is load-bearing: Tailwind's preflight sets
  `list-style: none`, and Safari/VoiceOver drop the implicit list role once the
  marker is gone — taking "list, N items", per-row set position, and the rotor
  entry with it. In that degraded state the element computes as `generic`, which
  ARIA 1.2 prohibits from having a name, so a caller's `aria-label` is discarded
  too. No axe rule covers this, so a green audit is not evidence either way.
  Row semantics and focus handling live in `list_group_item`.
- **You supply:** the rows, via `list_group_item` (slot/block content).

## List group item: Accessibility contract

- **Guarantees:** AAA-contrast tokens (`text-text-heading`/`text-text-muted` on
  `bg-surface-raised`; the active row is a solid `bg-interactive` fill with adaptive
  `text-text-on-interactive`). Semantics follow interactivity: a static row is
  a plain `<li>`; a navigable row is an `<a>` wrapped in its `<li>` (an `<a>`
  is not a valid direct child of `<ul>`). Link rows are real `<a>` elements
  inside `<li>`, carry the `focus-ring` utility, and — when active —
  `aria-current="page"`. A clickable row is a real focusable element, never a
  `<div>` with a click handler; a non-interactive row is never made focusable.
  An unknown `variant` raises in development.
- **You supply:** the row text (positional arg, `label:`, or slot content); an
  `href:` to make the row a link; `active: true` to mark the current row.
