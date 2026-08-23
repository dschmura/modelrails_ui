# Breadcrumb

A breadcrumb trail — a `<nav aria-label>` landmark with an ordered list. The last item is the
current page (`aria-current="page"`, not a link); earlier items are links with a decorative
separator.

## Installation

```bash
rails g modelrails_ui:add breadcrumb
```

## Usage

```erb
<%= render(UI::BreadcrumbComponent.new(items: [
  { label: "Home", href: root_path },
  { label: "Library", href: "/library" },
  { label: "Data" }
])) %>
```

The LAST item (no `href`) is the current page. `label:` overrides the `<nav>` accessible name
(i18n; defaults to `t("ui.breadcrumb.label", default: "Breadcrumb")`). `separator:` changes the
divider (default `/`).

A **non-last** item without an `href` renders as plain text (never a dead `<a>`), so
"linked for some viewers, plain for others" crumbs — e.g. a parent page whose link is
policy-gated — stay expressible with the same `items:` array.

## Attributes

`class:` targets the `<nav>` root, like every other passthrough attribute on a `UI::*`
component. Use `list_class:` to style the `<ol>` (precedent: tabs' `tablist_class:`):

```erb
<%= render(UI::BreadcrumbComponent.new(items: trail, class: "mb-6", list_class: "gap-4")) %>
```

## Collapsing a long trail

`max_items:` keeps the root and the tail and stands one ellipsis in for the rest.

```erb
<%= render(UI::BreadcrumbComponent.new(items: trail, max_items: 3)) %>
```

The collapsed crumbs are dropped for **everyone** — there is no visually-hidden copy. A
trail that reads as four levels to a screen reader and two on screen describes a structure
neither audience can act on, so the rendered trail stays truthful to both.

## Accessibility

WCAG 2.2 AAA. `<nav>` named by `label:`; an `<ol>` of crumbs; the current page is
`aria-current="page"` and not a link; separators are `aria-hidden="true"`; links carry a
`:focus-visible` ring. Proven by `spec/system/ui/breadcrumb_component_spec.rb` in the host app.
