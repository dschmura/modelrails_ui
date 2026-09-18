# DataTable

Sortable, filterable data table with client-side search and pagination.
The markup is the static scaffold; all interaction (filter / sort / paginate)
lives in the `data-table` Stimulus controller that ships alongside.

Requires `data_table_controller.js` (copied automatically by the generator).

## Installation

```bash
rails g modelrails_ui:add data_table
```

Creates `app/components/ui/data_table_component.rb`.

## Usage

```erb
<%= ui :data_table,
       columns: [
         { key: :name,  label: "Name",   sortable: true },
         { key: :email, label: "Email",  sortable: true },
         { key: :role,  label: "Role" }
       ],
       rows: @users.map { |u| { name: u.name, email: u.email, role: u.role } } %>
```

## Pagination

```erb
<%= ui :data_table,
       columns: [...],
       rows: @products,
       per_page: 25 %>
```

Set `per_page: 0` to disable pagination and show all rows.

## Caption

```erb
<%= ui :data_table,
       caption: "Active users as of today",
       columns: [...],
       rows: @users %>
```

## Sorting

Columns with `sortable: true` are clickable. Clicking the same column twice reverses the sort direction. Sorting is client-side only.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `columns` | Array | required | Column definitions — see table below |
| `rows` | Array | required | Array of hashes with keys matching column `key:` values |
| `per_page` | Integer | `10` | Rows per page; `0` disables pagination |
| `caption` | String | `nil` | Optional `<caption>` element text |
| `**html_attrs` | Hash | — | Forwarded to the outer wrapper `<div>` |

### Column hash

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `key` | Symbol or String | Yes | Matches the key in each row hash |
| `label` | String | No | Column heading; defaults to `key.humanize` |
| `sortable` | Boolean | No | Enables client-side sort on this column |

## When to use

- You have a bounded, already-loaded set of rows the user benefits from
  searching, sorting, or paging through entirely on the client.

## When not to use

- The dataset is large or server-paginated — client-side filtering only sees
  the rows already in the DOM. Render a server-driven table instead.
- The "table" is really a layout grid — use semantic layout, not <table>.

## Accessibility contract

- **Guarantees:** sortable columns are real keyboard-operable `<button>`s
  (Enter/Space activate; the bare `<th>` is not focusable), each wrapped in a
  `th[aria-sort]` the controller flips to `ascending`/`descending`/`none`;
  a visually-hidden `role="status"` live region announces the result count
  after filtering; all controls (search, sort headers, pager) meet the AAA
  44px target floor; every header cell declares `scope="col"`, so a data cell's
  header association is stated rather than left to the browser's heuristic (axe
  passes either way, because the heuristic usually works); and every user-facing
  string is localized.
- **You supply:** a `caption:` — a table without an accessible name leaves
  screen-reader users without context. Pass one whenever practical.

No fail-loud variant guard: this component has no enum/variant axis. Its
inputs are open-ended data (`columns:`, `rows:`, `per_page:`), not a closed
set to validate against, so there is nothing to coerce.
