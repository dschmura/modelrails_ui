# Button

Clickable element with variant and size support. Renders as a `<button>` by default and can be switched to any HTML tag via the `href:` shorthand or `tag:` option.

## Installation

```bash
rails g modelrails_ui:add button
```

Creates `app/components/ui/button_component.rb`.

## Usage

```erb
<%# Positional label — no block needed %>
<%= ui :button, "Save changes" %>

<%# Block — for icons or complex content %>
<%= ui :button do %>Save changes<% end %>
```

## Variants (variant × tone)

Two axes — `variant:` (shape) × `tone:` (signal). Only the AAA-proven cells ship; an
unproven combination raises in development and falls back to `[:solid, :primary]` in
production.

| Cell | Class | Reach for it when |
| --- | --- | --- |
| `variant: :solid, tone: :primary` (default) | `btn-primary` | the primary action |
| `variant: :solid, tone: :danger` | `btn-danger` | a destructive action |
| `variant: :outline, tone: :neutral` | `btn-secondary` | a secondary action |
| `variant: :text, tone: :primary` | `btn-touch-target btn-text btn-text-interactive` | a link-styled action |
| `variant: :text, tone: :danger` | `btn-touch-target btn-text btn-text-danger` | a link-styled destructive action |

```erb
<%= ui :button, "Save" %>
<%= ui :button, "Delete", variant: :solid, tone: :danger %>
<%= ui :button, "Cancel", variant: :outline, tone: :neutral %>
<%= ui :button, "Skip", variant: :text, tone: :primary %>
```

Legacy flat values still work via `SHIM` and ignore `tone:` — `primary`, `secondary`,
`danger`, `destructive`, `text`, `text_interactive`, `text_danger`. Write the two axes
in new code.

## Sizes

| Size | Description |
| --- | --- |
| `default` | standard horizontal padding; the 44px min-height comes from the `.btn-*` class |
| `icon` | a 44×44 square (`px-0 min-w-[var(--form-input-height)]`) for icon-only buttons — give it an `aria-label` |

```erb
<%= ui :button, "Normal" %>
<%= ui :button, size: :icon, "aria-label": "Close" do %><!-- svg --><% end %>
```

## Links

Pass `href:` to render an `<a>` tag automatically:

```erb
<%= ui :button, "Go home",      href: root_path %>
<%= ui :button, "Edit profile", href: edit_profile_path, variant: :ghost %>
<%= ui :button, "Delete",       href: item_path(@item), variant: :destructive,
                                 data: { turbo_method: :delete, turbo_confirm: "Are you sure?" } %>
```

To use a different element explicitly, use `tag:`:

```erb
<%= ui :button, tag: :a, href: root_path do %>Home<% end %>
```

## HTML attributes

Any extra keyword arguments are forwarded to the element:

```erb
<%= ui :button, "Submit", disabled: true %>
<%= ui :button, "Confirm", data: { turbo_confirm: "Are you sure?" } %>
<%= ui :button, "Submit", form: "my-form", type: "submit" %>
```

## API

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | String | `nil` | Plain-text label — positional (`"text"`) or keyword (`label: "text"`), alternative to block |
| `variant` | Symbol | `:solid` | Shape axis — `:solid`, `:outline`, `:text` (see Variants) |
| `tone` | Symbol | `:primary` | Signal axis — `:primary`, `:neutral`, `:danger` (see Variants) |
| `size` | Symbol | `:default` | `:default` or `:icon` (see Sizes) |
| `href` | String | `nil` | Renders `<a>` with this href; sets `tag: :a` automatically |
| `tag` | Symbol | `:button` | Override HTML element |
| `type` | String | `"button"` | Set automatically for `<button>`; pass `type: "submit"` for form submit |
| `**html_attrs` | Hash | — | Forwarded to the element |
