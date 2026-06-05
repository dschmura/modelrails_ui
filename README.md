# modelrails_ui

A WCAG 2.2 **AAA**, OKLCH-themed Rails component library — the design system for
**modelrails_base**, built on [ViewComponent](https://viewcomponent.org).

> **Lineage & acknowledgements** — `modelrails_ui` is a hardened fork of
> [alec-c4/view_primitives](https://github.com/alec-c4/view_primitives), which is itself
> inspired by [shadcn/ui](https://ui.shadcn.com) (and its Svelte port
> [shadcn-svelte](https://www.shadcn-svelte.com)). Deep thanks to those projects.
> This fork re-themes every component onto modelrails_base's AAA OKLCH token system,
> adopts the app's superior implementations where they exist (e.g. the native-`<dialog>`
> modal), adds form-builder/accessibility integration, fixes upstream generator bugs, and
> **proves AAA contrast in its own test suite**. MIT licensed (see `LICENSE.txt`).

Components are **copied into your app** via a generator — you own the files. This fork is
a **dev-only scaffolding gem**: it generates components + the token CSS into your app,
which you commit. **Production carries no runtime dependency on `modelrails_ui`** (only
`view_component`).

## What makes this fork different

- **WCAG 2.2 AAA, proven.** `test/test_aaa_contrast.rb` computes OKLCH→luminance contrast for
  the core token pairs and asserts ≥ 7:1 in light **and** dark. A token change that breaks AAA
  fails the build.
- **Ships an AAA OKLCH design system.** The install generator emits the full token system
  (primitives → semantic tokens, `@theme inline`, class-based dark mode, `.btn-*`/`bg-hue-*`).
- **Self-contained app.** The generated `ApplicationComponent` inlines the `cn` helper and an
  inflection initializer is written into your app, so nothing references the gem at runtime.
- **Integrates with Rails.** Form components accept first-class a11y params
  (`required`/`invalid`/`describedby` → ARIA) and are drivable by a custom `FormBuilder` *or*
  standalone. The `Dialog` is a native `<dialog>` with focus-trap/restore.

See **`MODELRAILS_STATUS.md`** for the per-component maturity record (solid / pre-release /
broken / kept-app-native) and **`CHANGELOG.md`** for the fork changes.

## Requirements

- Ruby >= 3.2 · Rails >= 7.1 · [ViewComponent](https://viewcomponent.org) >= 4.0 · Tailwind CSS 4

## Installation (dev-only)

```ruby
# Gemfile — scaffolding tool, not shipped to production
group :development do
  gem "modelrails_ui", git: "https://github.com/dschmura/modelrails_ui.git", tag: "v0.2.0"
end
```

```bash
rails g modelrails_ui:install              # tokens + self-contained ApplicationComponent + UI inflection
rails g modelrails_ui:add button input dialog   # copy components into app/components/ui
```

Commit the generated files. To update later: bump the tag, re-run the generators, review the diff.

## Usage

```erb
<%= render UI::ButtonComponent.new("Save", variant: :primary) %>
<%= render UI::DialogComponent.new(title: "Confirm") do |d| %>
  <% d.with_trigger { render UI::ButtonComponent.new("Open") } %>
  <p>Body</p>
<% end %>
```

### Recommended adoption pattern: adapters

Rather than changing call sites, point your existing integration seams at the components — so
adoption is zero-churn (this is how modelrails_base adopts it):

- **Forms:** your `FormBuilder` renders `UI::Input`/`Textarea`/`FileInput` internally; views keep
  using `f.text_field`/`f.text_area`/`f.file_field` unchanged.
- **Modal:** a thin `shared/_modal` partial renders `UI::DialogComponent(wrapper: false)`.
- **Avatar:** an `avatar_for` helper renders `UI::AvatarComponent`.
- **Buttons:** use the component for new code; existing `.btn-*` CSS keeps working.

`rails g modelrails_ui:list` shows available + installed components.

## Living documentation (Lookbook)

For a navigable, shareable component explorer — live, styled, interactive previews developers can
poke at:

```bash
rails g modelrails_ui:lookbook   # preview layout + initializer + ViewComponent::Preview classes
```

Then add `gem "lookbook"` to your `:development` group, mount it in `config/routes.rb`
(`mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?`), and visit `/lookbook`.
The generated preview layout loads your app's compiled Tailwind and importmap, so previews render
with real tokens and working Stimulus (the dialog actually opens). Previews land in
`spec/components/previews/ui/` — edit or extend them freely. Dev-only; nothing ships to production.

### Teach your coding agent (optional)

```bash
rails g modelrails_ui:agent_rules
```

Writes `.modelrails_ui/agent-rules.md` (gem-owned design-system rules, overwritten on
re-run) and seeds `.modelrails_ui/house-rules.md` (your editable host-policy defaults), then
adds a marker-delimited `@`-import to your `CLAUDE.md`/`AGENTS.md`. It reports — never
rewrites — directives that conflict with the design system. Re-run after a gem bump to refresh
the rules; your house-rules edits are preserved.

## Testing & accessibility

The gem's suite (`rake test`) runs two lanes:

- **`test:structural`** — fast, no Rails: reads the `.rb.tt` templates as text and asserts
  structure (`test/test_components.rb` and friends).
- **`test:render`** — real rendering: boots a minimal Rails app + ViewComponent and renders
  a component, asserting actual HTML/ARIA. AAA contrast is guaranteed by
  `test/test_aaa_contrast.rb` (token ratios), so a render test that asserts a component
  uses the semantic token classes inherits AAA.

### Verifying components (render tests)

To add a render test for a new component, create
`test/render/<name>_render_test.rb`:

```ruby
# test/render/<name>_render_test.rb
require "render_test_helper"
load_component "<name>", "<name>_component.rb.tt"

class <Name>RenderTest < ViewComponent::TestCase
  def test_renders_with_aaa_tokens
    render_inline(UI::<Name>Component.new(...))
    assert_selector "..."             # tag + structure
    assert_selector ".bg-interactive" # AAA semantic token actually rendered
  end
end
```

Replace `<name>` with the snake_case component name and `<Name>` with PascalCase
(e.g. `button` / `Button`). This render lane is the verification basis for the
component-hardening program
(see `docs/design/2026-06-03-component-hardening-program-design.md`).

Rendering/ARIA is also verified by **integration specs in the consuming app** (a real
view context), where each adopted component is asserted for correct markup and ARIA.

## Known gaps

`form_field`, `qr_code`, `input_otp` don't generate (template bugs); `embed` needs
`require "cgi"` on Ruby 4.0. See `MODELRAILS_STATUS.md`.
