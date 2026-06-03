# Design: ship shared/_modal + template-backed copyable previews

**Date:** 2026-06-02
**Status:** Proposed (design approved in brainstorming; pending written-spec review)
**Repo:** modelrails_ui (gem)
**Context:** the reference app (modelrails_base) converted its Lookbook previews to template-backed so the Source tab shows copyable view-native ERB. This milestone brings that to the gem — so every downstream app's generated catalog teaches paste-ready artifacts.

## Why

A Lookbook scenario authored as a Ruby method shows that method in the Source tab — not the ERB a developer pastes into a view. Template-backed previews fix this: the scenario lives in a sibling `.html.erb` file, so Source shows the copyable call.

- For five components (button, input, textarea, file_input, avatar) the conversion is **purely cosmetic**: their primitive call (`ui :input`, `ui :avatar`, …) is already clean, paste-ready ERB. We just move the call from a Ruby method into a `.html.erb`.
- The **dialog is the exception**. Its primitive is slot-Ruby (`ui :dialog … do |d| d.with_trigger { tag.button(…) }; "body" end`) — un-pasteable even as ERB. To give it a clean artifact, the gem must **ship `app/views/shared/_modal.html.erb`** (a thin wrapper over the gem's own `UI::DialogComponent`), which it does not currently ship. Then the dialog scenario teaches `render "shared/modal", trigger:`.

## Scope

**In:** ship `shared/_modal` (with the optional `trigger:` mode); convert all six component previews to template-backed.

**Out (deliberately):** a form builder, `avatar_for`, or any model-aware helper. Those are app-specific ergonomic sugar — a downstream app has its own form builder and its own (or no) user model. The gem's primitives are already clean copyable artifacts, so no `User`-model or form-builder assumption may leak into the gem.

## Design

### 1. Ship `shared/_modal` via `add dialog`

`shared/_modal` is the dialog's view adapter — it references `UI::DialogComponent`, which `rails g modelrails_ui:add dialog` already emits. So it ships **with the dialog**, not at install (no dangling reference).

- **New template:** `lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb` — the partial, carrying the reference app's PR #219 contract: optional `trigger:`/`trigger_class:`. With `trigger:` → render `UI::DialogComponent.new(…, wrapper: true)` + the `with_trigger` slot (complete wrapper + trigger + dialog). Without `trigger:` → `wrapper: false`, `body_id: "modal-body"` (the Turbo Stream append default).
- **Generator change (the one logic change):** `add_generator.rb#copy_template_file` currently routes `*.rb.tt` → `app/components/ui/`, `*_controller.js` → `app/javascript/controllers/`, and `*.html.erb` → `app/components/ui/`. Add a rule: a **leading-underscore partial** (`_*.html.erb`) routes to `app/views/shared/<file>`. (Leading underscore distinguishes a Rails view partial from a component sidecar template.)
- **Idempotency:** the app may already have a customized `shared/_modal` (the reference app does, from PR #219). Rely on the `add` generator's existing copy behavior (skip-if-exists / conflict prompt) so regeneration never clobbers a downstream customization. Confirm exact behavior in the plan.

### 2. Convert all six previews to template-backed

- Each `previews/ui/<component>_component_preview.rb`: scenario methods go **empty** (`def default; end`); class doc-comment, per-method comments, and `@label` annotations are preserved.
- New sibling directory `previews/ui/<component>_component_preview/<scenario>.html.erb` per scenario, containing the copyable ERB.
- **Five primitives:** the template is the existing `ui :x, …` call wrapped in `<%= %>` — moved verbatim.
- **Dialog (re-authored, not ported):** scenarios use `render "shared/modal", trigger:` with **gem-portable content only** — plain HTML and/or `ui :input` inside the modal. **Not** `f.text_field` (app builder) or `shared/confirm_dialog` (app partial). A lean, portable set: e.g. `default` (trigger + body + footer buttons), `large` (`size: :lg`), `dont_no_title`.
- **Lookbook generator: no change.** It copies the `previews/` tree with Thor `directory()`, which is recursive — the new sibling `.html.erb` dirs are picked up automatically.
- **Interactive `playground` scenarios** (if any gem preview has one with `@param` controls) stay **inline** — they're live explorers, not copyable snippets. The plan verifies which gem previews have them.

### 3. Testing

The gem uses Minitest (`test/`). Mirror existing generator-test style.

- Assert `add dialog` emits `app/views/shared/_modal.html.erb`, and that it declares the `trigger:` local (and the surface/complete branches).
- Assert each preview is template-backed: the `.rb` scenario methods are empty and a sibling `<scenario>.html.erb` exists for each.
- Assert the dialog scenario templates reference `shared/modal` and contain **no** `f.text_field` / `shared/confirm_dialog` (portability guard).
- Where feasible, run the generators into a tmp app and assert the emitted file tree; otherwise assert on template-file structure.

## Open details for the plan

- Exact `copy_template_file` routing rule and how it composes with the existing extension dispatch.
- The `add` generator's overwrite/skip behavior for an existing `shared/_modal` (idempotency guarantee).
- Which gem previews currently have a `playground` scenario (keep inline).
- The final gem dialog scenario set (keep portable + minimal).

## Out of scope / relationship to the app

This milestone changes only the gem. The reference app (modelrails_base) already has the richer, app-specific previews (`in_a_form` via the form builder, `for_a_user` via `avatar_for`) from PR #220 — those stay app-authored. After a gem release, an app could regenerate the gem-provided previews, but its app-specific scenarios remain its own. A gem release/tag is the owner's call.

## Toolchain

Gem-repo `mise.toml` is untrusted, so gem commands run as `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec …`.
