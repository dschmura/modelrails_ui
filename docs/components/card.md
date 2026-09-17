# Card

Bordered container with composable header, title, description, content, and footer sub-components. The card itself is a plain `<div>` — it carries no document structure; any heading lives inside, supplied by `card_title` (or your own markup), so the card never hijacks the outline.

## Installation

```bash
rails g modelrails_ui:add card
```

Creates 6 files under `app/components/ui/`: `card_component.rb`, `card_header_component.rb`,
`card_title_component.rb`, `card_description_component.rb`, `card_content_component.rb`,
`card_footer_component.rb`.

## Usage

```erb
<%= ui :card do %>
  <%= ui :card_header do %>
    <%= ui :card_title, "Account Settings" %>
    <%= ui :card_description, "Manage your account preferences." %>
  <% end %>
  <%= ui :card_content do %>
    <p>Content goes here.</p>
  <% end %>
  <%= ui :card_footer do %>
    <%= ui :button, "Save" %>
  <% end %>
<% end %>
```

## Sub-components

| Component | Element | Description |
|-----------|---------|-------------|
| `card` | `<div>` | Outer container |
| `card_header` | `<div>` | Top area with padding |
| `card_title` | `<h3>` | Heading — positional, `label:`, or block |
| `card_description` | `<div>` | Muted subtitle text |
| `card_content` | `<div>` | Main body area |
| `card_footer` | `<div>` | Bottom action bar |

## API

All sub-components accept `**html_attrs` forwarded to their root element.
`CardTitleComponent` also accepts a positional `title` argument or `label:` / `title:` keywords.

## When to use

- Grouping related content into a bordered, raised surface (a settings panel,
  a summary tile, a media object).

## When not to use

- The whole card should be a link/button — a card is a static container by
  contract. Put a real focusable `link`/`button` inside it instead of making
  the `<div>` interactive (a clickable `<div>` is not keyboard-reachable).

## Accessibility contract

- **Guarantees:** AAA-contrast `text-text-body` on `bg-surface-raised`, a
  semantic `border-border` rule, and a system `shadow-sm` (no raw color/shadow).
  The container is non-interactive and adds no ARIA role — it is a neutral box.
- **You supply:** the heading (via `card_title`, whose level you set with
  `level:`) and any focusable controls inside `card_content` / `card_footer`.
