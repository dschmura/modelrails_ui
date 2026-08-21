# Form Builder

Model-backed form fields through `UI::FormFieldComponent`, wired to
`ActiveModel::Errors` — `f.text_field`, `f.select`, `f.checkbox` and friends
already carry label/hint/error wiring, so you rarely reach for the primitives
directly inside a `form_with`.

## Installation

```bash
rails g modelrails_ui:add form_builder
```

Creates `app/form_builders/ui/form_builder.rb`. The builder renders through
several other components at field-render time, so the generator installs its
dependencies automatically: `form_field`, `input`, `textarea`, `file_input`,
`select`, `label`, `error_summary`. You do not need to `add` any of these
yourself.

**Requires Rails >= 8.0.** `checkbox`/`b.checkbox` is Rails 8's canonical
name for the check_box helper — it doesn't exist on ActionView 7.1/7.2, so
the builder's `super` call has nothing to reach on those versions.

## Wiring it up

Site-wide, as the app's default builder:

```ruby
# config/initializers/form_builder.rb
Rails.application.config.to_prepare do
  ActionView::Base.default_form_builder = UI::FormBuilder
end
```

`to_prepare` runs on every code reload in development (once in production) —
assigning at the initializer's top level would autoload `UI::FormBuilder`
during boot, before Zeitwerk's eager-loading pass is ready for it.

…or per form:

```erb
<%= form_with model: @user, builder: UI::FormBuilder do |f| %>
  ...
<% end %>
```

## The helper surface

Every Rails-named field helper is available on `f`, but not every one is
*wrapped* (routed through `FormFieldComponent` for label/hint/error/id
wiring). Four buckets:

**Wrapped** — render through `FormFieldComponent` + a `UI::*` control, with
full label/hint/error/aria wiring: `text_field`, `email_field`,
`password_field` (defaults `autocomplete: "new-password"`), `url_field`,
`tel_field`, `number_field`, `date_field`, `search_field`, `text_area`,
`file_field`, `select`. Plus two more that don't go through
`FormFieldComponent` but are still builder-aware: `submit` (see below) and
`error_summary` (a shim, not a Rails-named override — see below).

**Checkbox family** — `checkbox` (canonical name; `check_box` is
re-aliased to it — see below), `collection_checkboxes` (+
`collection_check_boxes`), `collection_radio_buttons`. These render their
own `<label>`/`<fieldset>` markup directly — **not** through
`FormFieldComponent`, and not through the standalone `UI::CheckboxComponent`
either — but share its id + hint/error *conventions*: the same
`#{id}-hint`/`#{id}-error` paragraph classes, the same error-first
`aria-describedby` order. See [Checkbox family](#checkbox-family) below.

**Passthrough** — Rails' own implementation, untouched: `hidden_field`,
`fields_for`, `label`, `button`. Nothing to wire (no visible label to bind,
or the helper already returns a plain control), so the builder doesn't
intercept them.

**Known-unwrapped** — also Rails' own implementation, but *not yet* wrapped,
so you get no aria wiring from the builder: `rich_text_area`, `radio_button`
(the bare-input primitive; use `collection_radio_buttons` for the wrapped
group), `collection_select`, `datetime_local_field`. The `date_select`
multiparameter family (`date_select`, `time_select`, `datetime_select`) is
**never** wrapped — reach for `date_picker` instead of Rails' multiparameter
selects.

### Why `check_box` needs a re-alias, not just an override

Rails 8.1's canonical name is `checkbox`; `check_box` is an alias bound to
the *original* `ActionView::Helpers::FormBuilder#check_box` method object at
alias-definition time. Overriding only `check_box` would leave `f.checkbox`
walking straight past this builder. The template defines `checkbox` and then
re-aliases `check_box` to it, so both names produce identical, wrapped
output (see `test_check_box_legacy_name_produces_identical_output`).

## Checkbox family

```erb
<%= f.checkbox :terms, label: "I accept the terms", help: "Required before you can submit" %>
<%= f.collection_checkboxes :role_ids, Role.all, :id, :name, help: "Who can edit" %>
<%= f.collection_radio_buttons :role_id, Role.all, :id, :name %>
```

`checkbox`, `collection_checkboxes` (+ `collection_check_boxes`), and
`collection_radio_buttons` render their own row markup — a `<label>` wrapping
input + caption, one ≥44px target per WCAG 2.5.5 — rather than going through
`FormFieldComponent`. `help:` still works: it renders a hint paragraph
(`#{id}-hint`, right below the row) wired via `aria-describedby`, same as
the wrapped fields — the id and class conventions are shared even though the
markup isn't. `aria-describedby` lists **error-first, then hint** when both
are present, matching the wrapped-field order.

**Caller `class:`** on any of the three is additive — merged with the
family's shared `CHECKBOX_CLASSES`, never a replacement (so a caller styling
hook doesn't silently drop the accent color or focus ring).

**An explicit `id: nil`** on `checkbox` opts out of id-derived wiring
entirely: no `aria-describedby`, and the hint/error paragraphs render with
no `id` rather than a degenerate `"-error"`/`"-hint"` nothing points at.

## `submit`

```erb
<%= f.submit "Save" %>
<%= f.submit "Save draft", class: "btn-secondary" %>
```

Defaults `class:` to `btn-primary`. A caller-supplied `class:` **replaces**
the default — it does not merge. `"btn-primary btn-secondary"` would leave
stylesheet load order to silently decide which one wins; replacement is a
loud, predictable failure mode instead.

## The aria-required-only contract

Controls the builder wraps get `aria-required="true"` and the label gets a
decorative `*`, but the HTML `required` attribute is **never** emitted.

Native `required` lets the browser block an empty submit with its own
transient validation bubble — the request never reaches the server. That
means the error summary and every inline error this builder exists to render
never get a chance to appear: the round trip the whole design depends on
(422 re-render → focused summary → per-field errors) is short-circuited
before it starts. If your browser is *not* blocking an empty submit on a
required field, that's this contract working as designed, not a bug.

## `error_summary`

A one-line shim over `UI::ErrorSummaryComponent` — the component is the real
surface (see `docs/components/error_summary.md` for its full accessibility
contract). The shim adds the one thing only the builder knows: each error's
field anchor.

```erb
<%= form_with model: @article, builder: UI::FormBuilder do |f| %>
  <%= f.error_summary %>
  <%= f.text_field :title %>
  <%# ... %>
<% end %>
```

**Placement:** call it once, at the top of the form, before the fields —
it's meant to be the first thing a failed submit lands focus on.

**Focus / announcement contract:** the rendered container is focusable
(`tabindex="-1"`) and carries `autofocus`. Browsers honour `autofocus` on
initial load, and Turbo Drive re-honours it on every render, including the
422 re-render after a failed submit — so a failed submit becomes an actual
focus + announcement event, not a silent DOM swap. See
`docs/components/error_summary.md#why-it-exists-the-focusannouncement-problem`
for why `role="alert"` alone isn't enough here.

**Build rule:** every error in `object.errors` becomes an item; `:base`
errors (no single field) render as plain text, every other attribute's
errors link to `"##{field_id(attribute)}"` so the summary doubles as a
working task list.

**`heading_level:`** forwards straight to the component — pass it when the
form sits under a deeper heading in the page outline (WCAG 1.3.1 / 2.4.10):

```erb
<%= f.error_summary(heading_level: 3) %>
```

Returns nothing when the object has no errors (or there's no model at all)
— safe to call unconditionally at the top of every form.

## I18n

The error summary's heading text is looked up at
`modelrails_ui.error_summary.heading`, count-pluralized:

```yaml
en:
  modelrails_ui:
    error_summary:
      heading:
        one: "1 error prevented this from being saved"
        other: "%{count} errors prevented this from being saved"
```

This key ships pre-filled in the single consolidated
`config/locales/modelrails_ui.en.yml` — installed once by
`rails g modelrails_ui:install`, alongside every other modelrails_ui I18n
key (one delegate file: gem-shipped, host-owned, host-edited). The component
also carries this text as an inline `default:`, so deleting the key — or the
whole file — degrades to the English default, never to "translation
missing".

## Required CSS custom properties

If your app defines its own design tokens, `rails g modelrails_ui:install`
detects that and skips copying the gem's `modelrails_ui.css` — in that case
your own stylesheet needs to define whatever custom properties the builder's
rendered output references. Verified against
`install/templates/modelrails_ui.css`:

| Property | Used for |
|---|---|
| `--color-danger` | required-mark asterisk (label + checkbox), inline field errors, invalid-state text/border/ring on input & textarea, error-summary heading/link text |
| `--color-danger-surface` | invalid-state background on input & textarea, the error summary's panel background |
| `--color-danger-border` | invalid-state border on select & file_input, the error summary's panel border |
| `--color-danger-icon` | the error summary's decorative icon |
| `--color-text-muted` | hint paragraphs, input/textarea placeholder text |
| `--color-text-heading` | input/textarea value text color |
| `--color-text-body` | checkbox/collection row labels, fieldset legends, field caption text (label), file_input's filename caption |
| `--color-border-strong` | checkbox border, default border on input/textarea/select |
| `--color-border-focus` | select's focus/hover border |
| `--color-interactive` | checkbox accent (checked-state) color, file_input's choose-file button background and selected-file chip text |
| `--color-interactive-hover` | file_input's choose-file button hover background |
| `--color-interactive-subtle` | file_input's selected-file chip background |
| `--color-text-on-interactive` | file_input's choose-file button text color |
| `--color-surface-raised` | background of the text/textarea/select controls the builder wraps |
| `--form-input-height` | the 44px (2.75rem) minimum control height (WCAG 2.5.5), on the wrapped text/textarea/select/file controls |

Plus the `focus-ring` utility (every focusable control, including the
checkbox) and the `.btn-primary` utility class (`submit`'s default).

`--color-danger`, `--color-text-body`, `--color-border-strong` and
`--color-interactive` are literal in the **builder itself** — its own
`CHECKBOX_CLASSES`/`CHECKBOX_ROW_CLASSES`/`LEGEND_CLASSES` constants and
`required_mark` helper render the checkbox family's markup directly; there
is no separate checkbox component in that path (see
[Checkbox family](#checkbox-family)). Every other token here is transitive:
consumed by the `FormFieldComponent`, `LabelComponent`, `InputComponent`,
`TextareaComponent`, `SelectComponent` and `FileInputComponent` the builder
renders internally for the wrapped fields. They're listed here because using
the builder means rendering all of them; each control's own docs page
documents its complete token list if you need more detail than this summary.

## `select`: Rails choice-pair order, not the primitive's

`f.select` renders through Rails' native `select` (via `super`) inside the
wrapper — so its choices follow **Rails' own convention**:
`options_for_select`-style `[text, value]` pairs, e.g.
`[["Admin", "admin"], ["Editor", "editor"]]`. This is the **opposite** of
standalone `UI::SelectComponent`'s own `options:` convention, which takes
`[value, label]` pairs. If you're used to composing `options:` for the bare
`select` primitive, swap the pair order when you move to `f.select` — the
gem chrome comes along for free either way (`select.ui-select`, not the
host-app-only `form-field` class).

## Collections don't support a custom row block (yet)

`collection_checkboxes` and `collection_radio_buttons` render each row as a
fixed `label` + input + caption layout (one ≥44px target per WCAG 2.5.5). A
block passed to either method is currently **ignored** — there's no hook for
a caller-supplied row template. If you need a custom row layout, compose the
fieldset by hand with the `checkbox`/`radio_button` primitives instead.

## Collisions with an existing form builder

**Already have an `ApplicationFormBuilder`?** Point it at `UI::FormBuilder`
via inheritance (`class ApplicationFormBuilder < UI::FormBuilder`) rather
than duplicating the wiring — you keep your app-specific additions and this
builder's aria contract in one chain.

**Already using `simple_form`?** `UI::FormBuilder` is a **replacement**, not
a companion. The two builders solve the same problem (label/hint/error
wiring) in incompatible ways; running both on the same form invites
conflicting markup. Migrate a form at a time rather than mixing builders
within one form.

## Update rule: subclass, don't edit

Re-running `rails g modelrails_ui:add form_builder` **overwrites**
`app/form_builders/ui/form_builder.rb`. Put customizations in a subclass and
point `default_form_builder` (or a form's `builder:`) at the subclass — never
edit the generated file directly. The supported override surface is the
public Rails-named field helpers; private helpers may change between gem
versions without notice (see the class's own header comment).

## `FormFieldComponent` `class:` passthrough

Where you compose a field with `FormFieldComponent` directly (not through
the builder — see `docs/components/form_field.md`), any `class:` you pass is
**additive** to its internal label→control→hint/error adjacency-spacing
utilities, never a replacement. Use it for layout only (e.g. `max-w-md`) —
don't pass vertical spacing utilities (`space-y-*`, margin utilities), which
would fight the wrapper's own built-in rhythm instead of composing with it.

## Related

- `form_field` — the primitive the builder wraps every field in.
- `error_summary` — the form-level error panel `f.error_summary` shims.
- `input` · `select` — the controls behind the wrapped helpers.
- `checkbox` — the standalone component with the same visual language as the
  builder's checkbox-family markup; the builder does **not** render it (its
  own `CHECKBOX_CLASSES` constant duplicates the styling, not the component).
