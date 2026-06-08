# Pagination

**Use Pagy's built-in `@pagy.series_nav`.** This app paginates with [Pagy](https://ddnexus.github.io/pagy/)
(43.x), whose `series_nav` already renders an accessible navigation bar (`aria-label`,
`role="link" aria-current="page"` on the current page, `rel="prev"`/`rel="next"`, gap
separators). There is **no custom `PaginationComponent`** to adopt — building one would only
duplicate Pagy's windowing.

## Usage

In the controller:

```ruby
@pagy, @records = pagy(scope)            # or pagy(:offset, array)
```

In the view (wrap in a design-system container; the app ships a `shared/_pagination` partial):

```erb
<%== @pagy.series_nav(aria_label: t("pagination.aria_label", default: "Pages")) %>
```

`@pagy.page_url(page)` builds a URL for any page; `@pagy.series` is the raw page array
(`[1, 2, "3", 4, :gap, 50]`) if you ever need fully custom markup.

## Styling (design system)

`series_nav` emits `<nav class="pagy series-nav">…</nav>` with plain `<a>` children — **unstyled
by default**. The host app styles them to the design-system tokens (AAA in both themes) via a
`@layer components` block targeting `.pagy.series-nav` (see `app/assets/tailwind/application.css`
in `modelrails_base`, proven by `spec/system/ui/pagination_a11y_spec.rb`). Copy that block to
match your design system.

## Accessibility

WCAG 2.2 AAA. Pagy's `series_nav` provides the ARIA contract; the design-system CSS provides
the AAA-contrast styling in both themes (proven in the host app's CI `test` job).
