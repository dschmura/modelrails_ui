# Copy

A readonly value with a button that copies it to the clipboard — a share link, a
token, an ID — and confirms in two carriers: a check glyph and a status region that
assistive technology announces. A failed copy selects the value and says so; it never
claims a success the browser did not confirm.

## Installation

```bash
rails g modelrails_ui:add copy
```

Creates `app/components/ui/copy_component.rb` and `app/javascript/controllers/copy_controller.js`,
and installs `button` and `input` (the trigger and the value are those components).
A dependency that is already installed is left alone — a customised `button` or
`input` is never touched. For a file you explicitly asked for (say, a controller
named `copy`), an identical file is left alone too; a differing one prompts —
pass `--force` to take the gem's copy or `--skip` to keep yours.

Previews are installed separately: `rails g modelrails_ui:lookbook --skip` adds the
`copy` preview and leaves your existing preview files alone.

## Usage

```erb
<%= ui :copy, value: @invitation_url, label: t("invitations.link_noun") %>
```

`label:` is the **noun** for the value — "Invitation link", "API token" — never a
sentence: it becomes the `<label>`, part of the button's accessible name
("Copy Invitation link"), and part of both announcements.

## What it renders

```text
div[data-controller=copy][data-slot=control][data-state=idle]
  label[for=ID]                          sr-only when label_hidden: true
  input[readonly][data-copy-target=source]   UI::Input chrome, font-mono, no `name`
  button[aria-label="Copy <label>"]      UI::Button [:outline, :neutral]; visible text "Copy"
    svg (clipboard)  svg[hidden] (check)  span "Copy"
  p[role=status][aria-live=polite]       empty until a copy succeeds
  p[role=alert]                          empty until a copy fails
```

On success the check glyph shows for two seconds and the status region reads
"Copied <label> to the clipboard" — and stays until the next press. On failure the
value is selected (focus moves to it so your copy command applies) and the alert
region reads the failure string. The button's visible text never changes: swapping
it would break label-in-name (WCAG 2.5.3) and voice control for the feedback window.

## Strings

Four keys, English defaults shipped in the template; add them to your locale file to
translate (the host's delegate file is `config/locales/modelrails_ui.en.yml`).

| Key | Default |
| --- | --- |
| `modelrails_ui.copy.action` | `Copy` — the visible button text |
| `modelrails_ui.copy.button_label` | `%{action} %{label}` — the accessible name |
| `modelrails_ui.copy.copied` | `Copied %{label} to the clipboard` |
| `modelrails_ui.copy.failed` | `Couldn't copy automatically. %{label} is selected — use your browser or device copy command.` |

Per call, `copy_label:`, `copied_label:` and `failed_label:` override them. The failure
string deliberately names no keystroke — macOS has no Ctrl, touch has no keyboard.

## Data hooks (`data-state`, `copy:copied`, `copy:failed`)

Assert on these, not on internals:

- `data-state` on the wrapper: `idle` → `copied` | `failed` → back to `idle` after two seconds.
- `copy:copied` (`event.detail.value`) and `copy:failed` (`event.detail.value`, `event.detail.error`) bubble from the wrapper.

## Secure context required

`navigator.clipboard` exists only in secure contexts — `https://` and `localhost`. On a
LAN IP (`http://192.168.…`) it is undefined, so every copy takes the failure path: the
value is selected and the failure string is announced. That is the honest outcome;
there is no `document.execCommand("copy")` fallback (deprecated, and its success
cannot be detected reliably enough to announce).

## Multiple controls on one page

Each instance generates its own id (`copy-<hex>`), or takes `id:`; both announcements
include `%{label}`, so two controls stay distinguishable. `autofocus:` is meaningful on
one instance per page.

## With FormField

Not needed — `ui :copy` renders its own `<label for>`. Wrapping it in `ui :form_field`
would give the value two labels.

## Testing in a fork

Stub the clipboard in a system spec and assert the contract, not the OS clipboard:

```ruby
page.execute_script(<<~JS)
  window.__copied = []
  Object.defineProperty(navigator, "clipboard", {
    value: { writeText: (t) => { window.__copied.push(t); return Promise.resolve() } },
    configurable: true
  })
JS
find("button[data-action='copy#copy']").click
expect(page).to have_css("[data-controller='copy'][data-state='copied']")
```

Whether headless Chrome honours `Browser.grantPermissions` for a real clipboard write
is unverified; the stub needs no permission.

## The 0b obligation

The gem's browser lane proves behaviour and structural axe with no compiled CSS. AAA
contrast for the input, the trigger and the two status lines is proven in the
consuming app against real CSS — a system spec on the real page, asserting axe in
both themes. Do not claim AAA from the gem alone.

## API

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | String | required | The readonly input's value; an empty string is a failure at copy time |
| `label` | String | required | The noun for the value; rendered as `<label for>`, interpolated into the name and announcements |
| `label_hidden` | Boolean | `false` | Render the label `sr-only` |
| `id` | String | `"copy-<hex>"` | The input's id (and the label's `for`) |
| `copy_label` | String | `modelrails_ui.copy.action` | Visible button text |
| `copied_label` | String | `modelrails_ui.copy.copied` | Polite announcement |
| `failed_label` | String | `modelrails_ui.copy.failed` | Assertive announcement |
| `describedby` | String | `nil` | The **button's** `aria-describedby` |
| `autofocus` | Boolean | `false` | Autofocus the **button** |
| `**html_attrs` | Hash | — | Forwarded to the wrapper `<div>`; caller `data:` is merged after the controller wiring |
