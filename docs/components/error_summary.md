# Error Summary

The form-level error panel — and the announcement mechanism for failed submits.

## Installation

```bash
rails g modelrails_ui:add error_summary
```

Creates `app/components/ui/error_summary_component.rb`.

Installed automatically as a dependency of `form_builder` — you rarely add it directly.

## Why it exists: the focus/announcement problem

`role="alert"` alone does **not** announce a server-rendered response. A live
region only fires on *mutation* — it needs to already be in the DOM, then
change. A form's 422 re-render delivers the alert region and its content in
the same response, so nothing "changes" for assistive tech to notice. Worse,
Turbo's frame/page replacement drops keyboard focus to `<body>`, so a sighted
keyboard user has no idea where they landed either.

The fix here is zero JavaScript: the container is focusable (`tabindex="-1"`)
and carries the `autofocus` attribute. Browsers honour `autofocus` on initial
page load, and **Turbo Drive re-honours it on every render** — including the
422 re-render after a failed submit. The failed submit becomes an actual
focus + announcement event, not a silent DOM swap.

The two roles are **separated**, which is GOV.UK's shape: `role="alert"` sits on
an inner element, never on the focused container. When the focused element and
the alert are the same element, a reader can announce it twice — once as the
alert, then again as the newly focused element. Splitting them lets focus land
on a role-less container that reads its contents once, while the alert inside
keeps its semantics for readers that use it.

The focus target is marked `data-slot="error-summary"`, so a host can style or
select it without depending on the role placement.

Each error additionally renders as a real link to `#<field_id>`, so the
summary doubles as a working task list: activate an item, land on the field.

## Usage

```erb
<%= ui :error_summary, items: [
  { message: "Title can't be blank", href: "#article_title" },
  { message: "Body is too short", href: "#article_body" }
] %>
```

Renders nothing (`render?` returns false) when `items` is empty — safe to
call unconditionally at the top of a form.

### The normal entry point: the form builder shim

You will not usually build `items` by hand. `UI::FormBuilder#error_summary`
walks the form's model errors and builds the `{message:, href:}` array for
you, wiring `href` to each field's rendered id:

```erb
<%= form_with model: @article, builder: UI::FormBuilder do |f| %>
  <%= f.error_summary %>
  <%# ... fields ... %>
<% end %>
```

## `items:` shape

`items` is an `Array` of hashes:

| Key | Type | Description |
|-----|------|-------------|
| `message` | String | The error text |
| `href` | String or `nil` | Anchor to the field's id (e.g. `"#article_title"`). Omit (`nil`) for object-level (`:base`) errors that have no single field. |

An item with `href: nil` renders as plain text inside its `<li>` — not a link.

## `heading_level:`

The heading defaults to `h2`. Pass `heading_level:` when the summary sits
under a deeper heading in the page outline (WCAG 1.3.1 / 2.4.10):

```erb
<%= ui :error_summary, items: @items, heading_level: 3 %>
```

Only `1..6` are accepted — an out-of-range value raises `ArgumentError` in
development, the same fail-loud posture as other components' invalid-tone
checks.

## I18n

The heading text is looked up at `modelrails_ui.error_summary.heading`,
count-pluralized (`one` / `other`):

```yaml
en:
  modelrails_ui:
    error_summary:
      heading:
        one: "1 error prevented this from being saved"
        other: "%{count} errors prevented this from being saved"
```

This key ships pre-filled in `config/locales/modelrails_ui.en.yml` (installed
by `rails g modelrails_ui:install`, alongside every other modelrails_ui
I18n key — the delegate-file pattern: gem-shipped, host-owned, host-edited).
The component also carries this text as an inline `default:`, so deleting
the key — or the whole file — degrades to the English default, never to
"translation missing".

## Accessibility contract

- **Guarantees:** a focusable, autofocused container (`data-slot="error-summary"`)
  wrapping a separate `role="alert"` block — never the same node, so a reader
  does not announce the summary twice; a
  count-pluralized heading at a configurable level (default h2 — pass
  `heading_level:` when the form sits under deeper headings, 1.3.1/2.4.10);
  items as real links to `#<field_id>` when `href` is given; a decorative
  severity icon marked `aria-hidden="true"` (WCAG 1.4.1 — color is never the
  only cue).
- **You supply:** `items` — `[{message:, href:}]`; omit `href` for
  object-level (`:base`) errors.

Each link is a target in its own right — it sits alone in its list item rather
than inside running text — so it carries `inline-flex min-h-11 items-center`.
Bare, an anchor here renders 17px tall and fails target-size at AA (24px) as well
as the AAA 44px floor.

Every other list-emitting component in this library carries an explicit
`role="list"`, because Tailwind's preflight sets `list-style: none` and
Safari/VoiceOver then drop the implicit list role. **This component is the one
exemption, deliberately:** its `<ul>` applies `list-disc list-inside`, which
overrides preflight, so the marker is present and the implicit role survives on
its own. Adding the role here would be redundant. Do not "fix" it in a future
sweep — the exemption and its reason are pinned by
`test/test_lists_carry_the_list_role.rb`, which fails if the component ever
stops applying those utilities.

## Related

- `form_field` — the per-field label/hint/error wrapper.
- `alert` — the general-purpose inline message banner (error_summary is a
  purpose-built specialization for form-level errors, not a use of `alert`).

## When to use

- Rendering `ActiveModel::Errors` at the top of a form. The form builder's
  `error_summary` shim builds `items` (with per-field anchors) for you.
