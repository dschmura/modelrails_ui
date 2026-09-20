# Footer

Site footer with optional link columns, block content area, and a copyright row.

## Installation

```bash
rails g modelrails_ui:add footer
```

Creates `app/components/ui/footer_component.rb`.

## Usage

```erb
<%= ui :footer,
       copyright: "© 2025 Acme Inc.",
       columns: [
         { title: "Product",  links: [{ label: "Features", href: "#" }, { label: "Pricing", href: "#" }] },
         { title: "Company",  links: [{ label: "About",    href: "#" }, { label: "Blog",    href: "#" }] },
         { title: "Legal",    links: [{ label: "Privacy",  href: "#" }, { label: "Terms",   href: "#" }] }
       ] %>
```

## Custom block content

Place any HTML inside the footer between the columns grid and the copyright row:

```erb
<%= ui :footer, copyright: "© 2025 Acme" do %>
  <p class="text-sm text-text-muted text-center mb-6">
    Built with ModelrailsUi.
  </p>
<% end %>
```

## Copyright only

```erb
<%= ui :footer, copyright: "© 2025 Acme Inc. All rights reserved." %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `copyright` | String | `nil` | Text shown in the bottom row below a divider |
| `columns` | Array | `[]` | Array of column hashes — see table below |
| `**html_attrs` | Hash | — | Forwarded to the `<footer>` element |

### Column hash

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `title` | String | Yes | Column heading |
| `links` | Array | Yes | Array of `{ label:, href: }` hashes |

## When to use

- Closing a page with site-wide navigation (product / company / legal columns),
  social/legal links, and a copyright line.

## When not to use

- You only need an inline list of links inside an article — that isn't the
  page's contentinfo landmark. Use a plain `<ul>`.

## Accessibility contract

- **Guarantees:** a `<footer>` (contentinfo landmark); each column is a real
  heading + `<ul>`/`<li>`/`<a>`; links carry the `focus-ring` utility (a visible
  AAA focus outline); AAA-contrast text on `bg-surface-raised`. Pass `label:`
  (i18n) to name the landmark when a page has more than one footer.
  The `<ul>` carries an explicit `role="list"`: Tailwind's preflight sets
  `list-style: none`, and Safari/VoiceOver drop the implicit list role once the
  marker is gone — taking the item count and per-item set position with it. No
  axe rule covers this.
- **You supply:** `columns:` (`[{ title:, links: [{ label:, href: }] }]`) and/or
  block content and/or `copyright:`. Every link needs a human-readable `label:`
  (its accessible name) and an `href:`.
