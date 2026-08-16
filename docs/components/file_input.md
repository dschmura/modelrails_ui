# FileInput

Styled `<input type="file">` with support for MIME-type filtering and multiple file selection.

## Installation

```bash
rails g view_primitives:add file_input
```

Creates `app/components/ui/file_input_component.rb`.

## Usage

```erb
<%= ui :file_input, name: "avatar" %>
```

## Accept filter

```erb
<%# Images only %>
<%= ui :file_input, name: "photo", accept: "image/*" %>

<%# Specific extensions %>
<%= ui :file_input, name: "document", accept: ".pdf,.docx" %>
```

## Multiple files

```erb
<%= ui :file_input, name: "attachments[]", multiple: true %>
```

## Showing which files are selected

A native `<input type="file" multiple>` only shows a count — "3 files" — never
which files. `show_selection: true` fixes that dead end: the input is wrapped with
a pill list (one badge-style chip per file name) and an sr-only live region, kept
in sync by the vendored `file-input` Stimulus controller. Re-selecting replaces
the pills; clearing the selection hides the list and announces the `none` string.

```erb
<%= ui :file_input, name: "attachments[]", multiple: true, show_selection: true %>
```

The default mode (no `show_selection:`) still renders the bare `<input>`,
unchanged.

### Selection strings (`selection_labels:`)

The announcement/label strings are host-supplied (i18n lives in your app; the
defaults are English). Pass any subset — it merges over the defaults:

```erb
<%= ui :file_input, name: "attachments[]", multiple: true, show_selection: true,
      selection_labels: {
        one:  t("uploads.one_selected"),   # e.g. "1 file selected: %{names}"
        many: t("uploads.many_selected"),  # e.g. "%{count} files selected: %{names}"
        none: t("uploads.none_selected")   # e.g. "No files selected"
      } %>
```

`%{count}` and `%{names}` are substituted client-side (names joined with `", "`),
so keep the placeholders literal in your locale files.

### Design note: why the live region is separate from the list

The sr-only status `<span aria-live="polite">` is always present in the DOM, even
while empty. A live region that exists from page load announces reliably;
un-hiding an already-populated live region often does not. The visible pill list
is therefore a separate element that starts `hidden` and carries no live-region
semantics.

## With FormField

```erb
<%= ui :form_field, label: "Profile picture" do %>
  <%= ui :file_input, name: "user[avatar]", accept: "image/*" %>
<% end %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `accept` | String | `nil` | MIME types or file extensions, e.g. `"image/*"` or `".pdf,.docx"` |
| `multiple` | Boolean | `false` | Allow selecting multiple files |
| `show_selection` | Boolean | `false` | Also render the selected file names as pills plus an sr-only announcement (Stimulus `file-input` controller); default is the bare input, unchanged |
| `selection_labels` | Hash | `{}` | Selection strings merged over the English defaults (i18n; defaults to `one: "1 file selected: %{names}"`, `many: "%{count} files selected: %{names}"`, `none: "No files selected"`) |
| `**html_attrs` | Hash | — | Forwarded to the `<input type="file">` element |
