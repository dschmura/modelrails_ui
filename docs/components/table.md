# Table

A **server-rendered** data table: caption, toolbar, header, body and footer slots
around a plain `<table>`. Sorting, filtering and paging are the caller's — a GET
form, pagy, your own links.

This is the counterpart to [`data_table`](data_table.md), not a replacement for
it. `data_table` sorts and filters **in the browser** over rows already on the
page. `table` assumes the browser never has the whole set, so every change is a
request you own.

## Installation

```bash
bin/rails g modelrails_ui:add table
```

`scroll_area` is installed with it — `table` renders it for `scroll: :horizontal`.

## Usage

```erb
<%= ui :table, caption: "Widgets in this workspace" do |t| %>
  <% t.with_header do %>
    <th scope="col" class="<%= UI::TableComponent::TH %>">Name</th>
    <th scope="col" class="<%= UI::TableComponent::TH %>">Owner</th>
  <% end %>
  <% t.with_body do %>
    <% @widgets.each do |widget| %>
      <tr class="border-t border-border">
        <td class="px-4 py-3 text-text-body"><%= widget.name %></td>
        <td class="px-4 py-3 text-text-body"><%= widget.owner_name %></td>
      </tr>
    <% end %>
  <% end %>
<% end %>
```

You write the `<th>` and `<tr>` cells yourself. That is the point: the component
owns the card, the caption and the scroll contract, and stays out of the way of
however your rows are built.

## The caption is required

`caption:` is the table's accessible name, and a blank or nil one raises
`ArgumentError` rather than falling back to anything. A table with no accessible
name leaves a screen-reader user with a grid of values and no statement of what
they are — that is the defect this component exists to prevent, so it fails at
development time instead of shipping.

It renders visually hidden (`sr-only`) by default. Pass `caption_visible: true`
to show it as real text above the rows.

## Toolbar and footer

Both are the card's own bands: the toolbar sits inside the top border, the footer
below the table. Put the summary line, the filters-applied state and a Clear link
in the toolbar, and the pager in the footer, so the table's context lives inside
the card instead of floating above and below it.

```erb
<% t.with_toolbar do %>
  <p class="text-sm text-text-body"><%= @pagy.count %> widgets</p>
  <%= link_to "Clear filters", widgets_path, class: "text-sm underline focus-ring" %>
<% end %>
<% t.with_footer do %>
  <div class="border-t border-border px-4 py-3"><%== pagy_nav(@pagy) %></div>
<% end %>
```

The footer deliberately carries no top border of its own, so a pagination partial
that draws one does not double it.

## Turbo Frames

This component owns no frame, deliberately. Put the `turbo_frame_tag` **around**
it, in the page:

```erb
<%= render "filters" %>

<p id="results_status" class="sr-only" role="status" aria-live="polite"></p>

<%= turbo_frame_tag "results" do %>
  <%= render "results" %>   <%# the ui :table lives in here %>
<% end %>
```

Three things about that shape are load-bearing, and all three are why the frame
cannot live inside the component:

**The frame has to wrap the empty-state branch too.** Your results partial
usually reads `if @rows.any? … else … end`, and a filter matching nothing must
still return the frame — otherwise Turbo has nothing to swap into and renders
"Content missing" instead of your empty state. A component-owned frame only
exists when there is a table, which is exactly the wrong time.

**Links inside the frame usually want `_top`.** A sort link or a pager link has
to re-render the filter band with the new state, and a frame-local swap cannot
reach outside the frame to do it:

```erb
<%= link_to "Next", path, data: { turbo_frame: "_top" } %>
```

Pagy's `series_nav` takes `anchor_string:` for the same reason:

```erb
<%== @pagy.series_nav(anchor_string: 'data-turbo-frame="_top"') %>
```

Getting this wrong is the most common way to break a framed table: a link that
navigates to a page with no matching frame id renders "Content missing". Reserve
the frame swap for control CHANGES (a filter form), where it keeps focus on the
control the user just operated, and let navigation go to `_top`.

**A live region belongs outside the frame.** A swap replaces everything inside
the frame, and a live region replaced wholesale announces nothing. Keep the
status node in the page, present and empty from first render, and update it from
the frame response:

```erb
<% if turbo_frame_request? %>
  <%= turbo_stream.update "results_status", "#{@pagy.count} results" %>
<% end %>
```

## Scrolling a wide table

`scroll: :horizontal` wraps **only the `<table>`** in a focusable, named scroll
region — not the whole component.

That distinction is the reason the option exists. Wrapping the entire component
in a scroll region carries the toolbar's controls and the footer's pager
off-screen along with the columns at phone width: the moment the table is wide
enough to need scrolling is the moment its own controls become unreachable.

```erb
<%= ui :table, caption: "Every column of the ledger", scroll: :horizontal do |t| %>
```

The region is a keyboard tab stop (WCAG 2.1.1 — otherwise the overflow is
mouse-only) and is named from
`modelrails_ui.table.scroll_region`, which interpolates the caption:

```yaml
en:
  modelrails_ui:
    table:
      scroll_region: "%{name}, scrolls sideways"
```

Its name is deliberately **not** the caption verbatim. An identical name makes a
screen reader announce the same words twice, once for the region and once for the
table it contains.

## Sizes

`size: :default | :compact` is exposed as `data-size` on the card, so your row
partials can key off it rather than taking a size argument of their own.

```erb
<tr class="<%= "py-1" if table_size == "compact" %>">
```

A caller's own `data:` hash is merged rather than replacing it, so passing
`data: { controller: "…" }` cannot silently drop `data-size`.

## At scale

The component renders exactly the rows you hand it, in one response. It adds no
cap of its own, so the ceiling is yours to set — and worth setting, because the
cost that bites first is usually the **page**, not the query: a few hundred rows
each carrying a disclosure or a menu is a large DOM before it is a slow SELECT.

Two habits keep a server-rendered table cheap as the table grows:

- **Don't re-count on every page.** A plain `COUNT(*)` per pager click is the
  usual first regression on a large table. Pagy's `countish` paginator counts
  once and carries the count in the page token.
- **Eager-load what a row renders.** Each row is your partial, so an association
  touched there is an N+1 per row. `includes`/`preload` the row's associations in
  the query, not in the view.

Neither is something this component can do for you — both live in the controller,
which is the point of the split: the component owns the card and the a11y
contract, and stays out of your query.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `caption` | String | **required** | The table's accessible name; blank or nil raises |
| `caption_visible` | Boolean | `false` | Render the caption as visible text rather than `sr-only` |
| `size` | Symbol | `:default` | `:default` or `:compact`; exposed as `data-size` |
| `scroll` | Symbol | `nil` | `nil` or `:horizontal` — wraps only the `<table>` in a scroll region |
| `**html_attrs` | Hash | — | Forwarded to the card `<div>` |

| Slot | Required | Description |
|------|----------|-------------|
| `with_header` | No | The `<th>` cells of the header row (wrapped in `<thead><tr>`) |
| `with_body` | No | The `<tr>` rows (wrapped in `<tbody>`) |
| `with_toolbar` | No | The card's top band, above the table |
| `with_footer` | No | Content below the table, inside the card |

`UI::TableComponent::TH` is public on purpose: use it for your header cells so a
sortable header matches a plain one instead of re-deriving the classes and
drifting. It carries the AAA 44px row height (`h-11`).

## When to use

- Rows are sorted, filtered or paged on the server and each change is a request.
- The set is larger than the page, so the browser never holds all of it.

## When not to use

- Every row is already on the page and you want in-browser sort/filter — use
  [`data_table`](data_table.md).
- The rows have no columns — use [`list_group`](list_group.md).

## Accessibility contract

- **Guarantees:** a required `caption:` as the table's accessible name, refused
  rather than defaulted when blank; a real `<table>`/`<thead>`/`<tbody>`
  structure; `scroll: :horizontal` wraps only the table in a focusable
  (`tabindex="0"`), named `role="region"` so the overflow is keyboard-reachable
  (WCAG 2.1.1), named distinctly from the caption so the same words are not
  announced twice; header cell classes on a shared constant at the AAA 44px row
  height; every user-facing string localized with an inline English default.
- **You supply:** the `<th>` cells — **including `scope="col"`**, which the
  component cannot add for you since you own the markup — the `<tr>` rows, and
  any toolbar or footer content.

## A note on the card surface

The wrapper is `bg-surface`, the same filled surface as
[`list_group`](list_group.md), so a table and a list sitting side by side read as
the same kind of container.

The gem's card surfaces do not currently agree — `card` is `bg-surface-raised`
and `data_table` has no background at all — and unifying them is a visual change
for every host app, out of scope here. This component follows the list rather
than adding a fourth answer. Override with `class:` if your page background calls
for something else; `cn` resolves the conflict in your favour.

## Related

- [`data_table`](data_table.md) — the client-side counterpart
- [`list_group`](list_group.md) — rows without columns
- [`scroll_area`](scroll_area.md) — the scroll region this component uses
