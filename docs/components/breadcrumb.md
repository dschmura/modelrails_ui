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

## Accessibility

WCAG 2.2 AAA. `<nav>` named by `label:`; an `<ol>` of crumbs; the current page is
`aria-current="page"` and not a link; separators are `aria-hidden="true"`; links carry a
`:focus-visible` ring. Proven by `spec/system/ui/breadcrumb_component_spec.rb` in the host app.
