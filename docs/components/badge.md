# Badge

Small inline label for status, counts, or categories. Renders a `<span>` by
default, or an `<a>` when `href:` is given (a clickable tag/filter link).

## Installation

```bash
rails g modelrails_ui:add badge
```

Creates `app/components/ui/badge_component.rb`.

## Usage

```erb
<%# Positional label %>
<%= ui :badge, "New" %>

<%# Keyword label %>
<%= ui :badge, label: "Draft" %>

<%# Block content %>
<%= ui :badge do %>In Review<% end %>
```

## Cells (variant × tone)

Badge is a **two-axis** component: `variant:` (shape) × `tone:` (signal). Only
the 10 AAA-proven `(variant, tone)` cells below ship — pairings outside this
table are unproven and not guaranteed legible.

| Variant | Tone | Class recipe |
|---------|------|--------------|
| `solid` | `primary` | `bg-interactive text-text-on-interactive [a&]:hover:bg-interactive-hover` |
| `soft` | `primary` | `bg-interactive-subtle text-interactive [a&]:hover:bg-interactive-subtle` |
| `soft` | `info` | `bg-info-surface text-info border-info-border [a&]:hover:bg-info-hover` |
| `soft` | `success` | `bg-success-surface text-success border-success-border [a&]:hover:bg-success-hover` |
| `soft` | `warning` | `bg-warning-surface text-warning border-warning-border [a&]:hover:bg-warning-hover` |
| `soft` | `danger` | `bg-danger-surface text-danger border-danger-border [a&]:hover:bg-danger-hover` |
| `soft` | `neutral` | `bg-surface text-text-muted border-border [a&]:hover:bg-surface-sunken [a&]:hover:text-text-heading` |
| `outline` | `neutral` | `border-border text-text-heading [a&]:hover:bg-surface-sunken [a&]:hover:text-text-heading` |
| `ghost` | `neutral` | `[a&]:hover:bg-surface-sunken [a&]:hover:text-text-heading` |
| `link` | `primary` | `text-interactive underline-offset-4 [a&]:hover:underline` |

```erb
<%= ui :badge, "Active",  variant: :solid, tone: :primary %>
<%= ui :badge, "Note",    variant: :soft,  tone: :info %>
<%= ui :badge, "Error",   variant: :soft,  tone: :danger %>
<%= ui :badge, "Draft",   variant: :soft,  tone: :neutral %>
<%= ui :badge, "Pending", variant: :outline, tone: :neutral %>
```

Every signal (`info`/`success`/`warning`/`danger`) lives on the **soft**
variant as a tinted chip (soft `*-surface` background + saturated
`text-<level>` + `*-border`), matching the alert and toast cards — there is
**no solid-danger fill**; `variant: :solid, tone: :danger` is unproven.
`[:soft, :neutral]` is the one soft cell with no signal color: a muted chip
(`bg-surface` + `text-text-muted` + `border-border`) for draft-style pills
that shouldn't read as a status signal.

### Unproven cells: raise in dev, fall back in production

Passing a `(variant, tone)` pair outside the table above raises
`ArgumentError` in development/test, so a bad cell is caught immediately
rather than shipping a silently-wrong chip. In production the same call
falls back to `[:solid, :primary]` instead of raising, so a bad cell never
500s a page — check your logs/error tracker if a badge looks wrong in
production; it means a cell slipped through review.

## Link mode (`href:`)

Pass `href:` to render an `<a>` instead of a `<span>` — a clickable tag or
filter link, not an action (use `UI::ButtonComponent`, or `button_to`, for
actions):

```erb
<%= ui :badge, "Docs", variant: :link, tone: :primary, href: docs_path %>
```

A `<span>` badge is not focusable and carries neither `focus-ring` nor the
`aria-invalid` box-shadow ring. An `<a>` badge **is** focusable, so `href:`
mode adds `min-h-11` (AAA target size) and `focus-ring` (a 2px offset
outline, never a box-shadow ring) automatically — you don't need to pass
either yourself.

## Data hooks (`data-variant` / `data-tone`)

Every badge — span or link — emits `data-variant` and `data-tone` reflecting
the **post-shim** axes (i.e. after a legacy flat `variant:` value has been
resolved through `SHIM`). Host specs should assert on these hooks instead of
reaching into the component's private class internals:

```ruby
# spec/system/ui/badge_component_spec.rb (host app)
it "renders the draft badge as the soft/neutral cell" do
  visit project_path(project)

  expect(page).to have_css("span[data-variant='soft'][data-tone='neutral']", text: "Draft")
end
```

## Legacy shim

The historical flat `variant:` values (`default`, `secondary`, `info`,
`success`, `warning`, `danger`, `destructive`, `outline`, `ghost`, `link`)
still render byte-identical output via a deprecation shim that maps each to
its `[variant, tone]` cell — write the two axes in new code.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | required | Plain-text label — positional (`"text"`) or keyword (`label:`), alternative to block |
| `variant` | Symbol | `:solid` | Shape axis — see Cells table; also accepts a legacy flat value via the shim |
| `tone` | Symbol | `:primary` | Signal axis — see Cells table; ignored when `variant:` is a legacy flat value |
| `href` | String | `nil` | Renders `<a>` instead of `<span>`; sets `tag: :a`, adds `min-h-11 focus-ring` |
| `**html_attrs` | Hash | — | Forwarded to the rendered element |
