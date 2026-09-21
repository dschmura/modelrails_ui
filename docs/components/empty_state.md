# Empty state

The placeholder shown where a list, table or panel would be if it had anything in
it — an optional icon, a title, an optional supporting line, and an optional call
to action.

## Installation

```bash
bin/rails g modelrails_ui:add empty_state
```

## Usage

```erb
<%= ui :empty_state, title: "No projects yet" %>
```

With a supporting line and a call to action:

```erb
<%= ui :empty_state,
       title: "No projects yet",
       description: "Create your first project to get started." do |c| %>
  <% c.with_icon { icon(:folder_plus) } %>
  <% c.with_action { link_to "New project", new_project_path, class: "btn-primary" } %>
<% end %>
```

## Variants

| Variant | Chrome | Use for |
|---|---|---|
| `dashed` *(default)* | dashed border | the ordinary "nothing here yet" well |
| `outlined` | solid border on `bg-surface-raised` | an empty state sitting among other cards |
| `plain` | none | a no-results block inside a panel that already has chrome |

Each comes from a real call site rather than being invented. An unknown variant
raises in development and test and falls back to `dashed` in production.

> `outlined` is `bg-surface-raised`, never `bg-surface`. `bg-surface` is the
> **page**, so a container painted with it is the same colour as the ground
> beneath it — see [design-tokens.md](../design-tokens.md).

## The title is not a heading

It renders as a `<p>`, deliberately. An empty state is transient content that can
appear anywhere on a page, so emitting an `<h2>` or `<h3>` would inject a heading
at an arbitrary level and break the document outline for anyone navigating by
headings — a real cost for a screen-reader user, paid to gain nothing.

If a particular empty state genuinely *is* a section heading in its context, pass
the markup you want as the icon or action slot content rather than asking the
component to guess a level.

## API

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | String | `nil` | The primary message |
| `description` | String | `nil` | A supporting line below the title |
| `variant` | Symbol | `:dashed` | `:dashed`, `:outlined`, or `:plain` |
| `icon` | Slot | — | Your SVG, passed bare: the container centres it, sizes it, applies the muted token, and spaces it from the title |
| `action` | Slot | — | A link or button, rendered in its own region below the text |

Any other attribute passes through to the container, so a caller can attach a
Stimulus target or hide the block until a search returns nothing.

## When to use

- A list, table or panel has no rows and the page would otherwise look broken.
- A search or filter returned nothing and the user needs to know why.

## When not to use

- **Something failed.** An empty state says "there is nothing here"; an error says
  "something went wrong". Use `alert` so the tone and the ARIA role match.
- **The data is still loading.** Use `skeleton` — an empty state shown during a
  fetch tells the user the wrong thing.

## Accessibility contract

- **Guarantees:** AAA-contrast tokens throughout (`text-text-heading` for the
  title, `text-text-body` for the description, `text-text-muted` for the icon);
  the title is a `<p>`, so the component never injects a heading into a page's
  outline; slot regions carry `data-slot` so spacing and ARIA can key off role.
- **You supply:** a `title:` worth reading, an `aria-hidden="true"` on a purely
  decorative icon, and — if the empty state appears in response to a user action
  such as a search — a live region around it, since the component does not
  announce its own arrival.
