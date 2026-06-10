# Convention Pass — Plan 3: Form Field (B1, gem-only hardening)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the broken standalone `UI::FormFieldComponent` (converged-conventions **B1**) so it produces an AAA-correct field — `<label for>` bound to the control, hint/error with real ids referenced by the control's `aria-describedby`, and `invalid`/`required` injected into the control — and bring it **broken → proven** (0a render test + app preview-host 0b axe). **Gem-only:** the app's real forms (built with the already-correct `TailwindFormBuilder`) are NOT touched; the only app additions are the new generated component, its preview, and the 0b spec (no existing form/view/builder changes).

**Architecture:** `FormFieldComponent` mints one field `id` and becomes a thin correct mirror of the builder's wiring: it renders the caption via the **Label primitive** (`for: id`), wraps the slotted control in a `data-slot=control` group, renders hint/error as `data-slot=description` paragraphs with ids `#{id}-hint`/`#{id}-error`, and **yields its field context to the control block** (`id` + `describedby` + `invalid` + `required`) so the caller spreads it onto the control. Vertical rhythm uses the Catalyst **`data-slot`-adjacency** model as self-contained Tailwind arbitrary-variant classes on the wrapper (no app CSS) — the builder keeps its `space-y-2` (unifying it is the deferred "Full B1").

**Tech Stack:** Ruby ViewComponent (`.rb.tt` gem template), the existing `UI::LabelComponent` + `UI::InputComponent` primitives, TailwindCSS v4 arbitrary-variant selectors, ViewComponent::TestCase (0a), Playwright/axe preview-host (0b, AAA CI-only). Gem toolchain `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …`; app `mise exec -- …`.

---

## Design reference

### The yield-the-context API

```erb
<%= ui :form_field, label: "Email", hint: "We'll never share it.", error: @user.errors[:email].first, required: true do |f| %>
  <%= ui :input, type: "email", name: "user[email]", **f.input_attrs %>
<% end %>
```

`f` is the component instance (ViewComponent yields it to the block). `f.input_attrs` returns the wiring hash the control spreads:

```ruby
def input_attrs
  { id: @id, describedby: @describedby, invalid: @error.present?, required: @required }
end
```

`UI::InputComponent` already accepts every one of these keys (`id:`, `describedby:`, `invalid:`, `required:` — verified against `TailwindFormBuilder#ui_input`). The control therefore gets `id` (matching the label's `for`), `aria-describedby` (the hint/error ids), `aria-invalid`, and `required` — all the wiring the broken version dropped.

### id minting

```ruby
@id = html_attrs.delete(:id) || "form_field_#{object_id}"
```

(Matches the id-fallback pattern used across the hardened controls, e.g. switch/select.)

### describedby

```ruby
@describedby = [("#{@id}-hint" if @hint.present?), ("#{@id}-error" if @error.present?)].compact.join(" ").presence
```

Both hint and error are referenced when both present (mirrors the builder — the old XOR that hid the hint on error is dropped).

### The wrapper + data-slot adjacency (self-contained, no app CSS)

```ruby
WRAPPER = "[&>[data-slot=label]+[data-slot=control]]:mt-3 " \
          "[&>[data-slot=control]+[data-slot=description]]:mt-2 " \
          "[&>[data-slot=description]+[data-slot=description]]:mt-1"
```

- Label → `data-slot=label` (added to the `LabelComponent` call via its `data:`-passthrough or a wrapping element — see Task 1 guard).
- Control → wrapped in `content_tag(:div, content, data: { slot: "control" })` (the **group**, per the B1 guard, so input-groups don't break the `+` adjacency).
- Hint/error → `data-slot=description`.

### Markup (call)

```ruby
content_tag(:div, class: cn(WRAPPER, @extra_class), **@html_attrs) do
  safe_join([
    (render(UI::LabelComponent.new(@label, for: @id, required: @required, data: { slot: "label" })) if @label),
    content_tag(:div, content, data: { slot: "control" }),
    (content_tag(:p, @hint, id: "#{@id}-hint", class: "text-sm text-text-muted", data: { slot: "description" }) if @hint.present?),
    (content_tag(:p, @error, id: "#{@id}-error", role: "alert", class: "text-sm text-danger", data: { slot: "description" }) if @error.present?)
  ].compact)
end
```

(Hint/error use `text-sm` to match the builder's `HELP_TEXT_CLASSES`/`ERROR_MESSAGE_CLASSES`, and `text-text-muted` is AAA here — same neutral as body. The required `*` is the Label primitive's decorative aria-hidden mark; FormFieldComponent no longer hand-rolls it.)

---

## Task 1: Repair `FormFieldComponent` (gem) + 0a render test

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/form_field/form_field_component.rb.tt`
- Create: `test/render/form_field_render_test.rb`

- [ ] **Step 1 — Write the failing render test.** Assert the accessibility contract:

```ruby
require "test_helper"

class FormFieldRenderTest < ViewComponent::TestCase
  def render_field(**opts)
    render_inline(UI::FormFieldComponent.new(id: "user_email", label: "Email", **opts)) do
      tag.input(type: "email", id: "user_email", aria: { describedby: nil })
    end
  end

  def test_label_is_bound_to_the_control_with_for
    render_field
    assert_selector "label[for='user_email']", text: "Email"
  end

  def test_hint_has_an_id
    render_field(hint: "No spam.")
    assert_selector "p#user_email-hint[data-slot='description']", text: "No spam."
  end

  def test_error_has_an_id_and_alert_role
    render_field(error: "is required")
    assert_selector "p#user_email-error[role='alert'][data-slot='description']", text: "is required"
  end

  def test_data_slots_present_for_adjacency_spacing
    render_field(hint: "No spam.")
    assert_selector "[data-slot='label']"
    assert_selector "[data-slot='control']"
    assert_selector "[data-slot='description']"
  end

  def test_input_attrs_expose_the_wiring
    c = UI::FormFieldComponent.new(id: "user_email", label: "Email", hint: "h", error: "e", required: true)
    attrs = c.input_attrs
    assert_equal "user_email", attrs[:id]
    assert_equal "user_email-hint user_email-error", attrs[:describedby]
    assert_equal true, attrs[:invalid]
    assert_equal true, attrs[:required]
  end

  def test_required_marker_is_decorative_on_the_label
    render_field(required: true)
    assert_selector "label [aria-hidden='true']", text: "*"
  end
end
```

- [ ] **Step 2 — Run, verify RED.** `PATH=… bundle exec ruby -Itest/render test/render/form_field_render_test.rb`.

- [ ] **Step 3 — Rewrite the template** per the Design reference: `initialize(label: nil, hint: nil, error: nil, required: false, **html_attrs)` mints `@id` (from `html_attrs.delete(:id)` or fallback), computes `@describedby`, stores `@extra_class`/`@html_attrs`; add the public `input_attrs`; rewrite `call` to the markup above; delete the hand-rolled `field_label`/`label_text`/`hint_tag`/`error_tag`. Update the doc-comment to show the yield-the-context usage + the accessibility contract.

- [ ] **Step 4 — Run, verify GREEN.**

- [ ] **Step 5 — Guard check:** confirm the `LabelComponent` actually emits `data-slot=label`. The Label primitive forwards `**html_attrs` to the `<label>` (it splats `@html_attrs`), so `data: { slot: "label" }` lands on the `<label>` — verify in the rendered output (`assert_selector "label[data-slot='label']"`). If it does NOT pass through, wrap the Label render in `content_tag(:div, ..., data: { slot: "label" })` instead. Add the chosen assertion to the test.

- [ ] **Step 6 — Commit.** `feat(ui): repair FormFieldComponent — bound label/ids/aria wiring + data-slot spacing (B1)`

## Task 2: Gem preview + full suite + rubocop

**Files:**
- Create/replace: the gem's `form_field` template-backed preview (follow the `alert`/`kbd` exemplar — a `.html.erb` preview that renders the component with label + input + hint + error, AND a `required` example).

- [ ] **Step 1 — Add a template-backed preview** with examples: `default` (label + input), `with_hint`, `with_error`, `required`. The preview's input must spread `**form_field.input_attrs` (so the preview exercises the real wiring, not a detached input).
- [ ] **Step 2 — Full gem render suite** `PATH=… bundle exec rake test` → 0 failures.
- [ ] **Step 3 — Rubocop** the changed `.rb` test files → clean (autocorrect, then re-run the suite to confirm escaping survived).
- [ ] **Step 4 — Commit** the preview. `test(ui): template-backed form_field preview`

## Task 3: App adoption for the 0b proof (additive only — no existing form touched)

**Files:**
- Create: `app/components/ui/form_field_component.rb` (generate via `bin/rails g modelrails_ui:add form_field`, OR copy the repaired gem template surgically — verify it's byte-faithful + app-rubocop-clean).
- Create: `spec/components/previews/ui/form_field_component_preview.rb` (template-backed, mirrors the gem preview).
- Create: `spec/system/ui/form_field_component_spec.rb` (0b preview-host axe spec — follow the `alert` exemplar: visit the preview, scope axe to the component subtree, `axe_clean_in_both_themes?`, no color-contrast exclude).

- [ ] **Step 1 — Branch** `convpass/form-field` off `main` (app), created by the orchestrator.
- [ ] **Step 2 — Generate/vendor** the component into the app; confirm `app/components/ui/form_field_component.rb` matches the repaired gem template (surgical, app-rubocop style).
- [ ] **Step 3 — Add the preview** (with-error + with-hint + required examples, input spreads `**f.input_attrs`).
- [ ] **Step 4 — Add the 0b spec.** It must assert: the `<label for>` matches the input `id`, the input's `aria-describedby` references the rendered hint/error ids, `aria-invalid` set on the error example, and `axe_clean_in_both_themes?` passes (the AAA contrast certifies in CI).
- [ ] **Step 5 — Rebuild Tailwind** (so the arbitrary-variant `[&>[data-slot=…]]` classes compile) + verify they emit (`grep` the compiled declaration, positive control first).
- [ ] **Step 6 — Full app suite** `mise exec -- bundle exec rspec` → 0 failures. Confirm NO existing form/view/spec changed (only the 3 new files). Commit.

## Task 4: Ship + ledger

- [ ] **Step 1 — Push gem branch `convpass/form-field`** → gem PR → CI green → REST sha-guard careful-merge to `modelrails/harden`.
- [ ] **Step 2 — Push app branch** (Lefthook pre-push full suite) → app PR → CI incl. AAA gate → careful-merge (expect the magic_link flaky may recur → `gh run rerun --failed`).
- [ ] **Step 3 — COMPONENT_STATUS:** flip `form_field` → **proven** (0a + 0b green), with a note: "B1 repair — bound label/ids/aria wiring; yields input_attrs; data-slot adjacency spacing."
- [ ] **Step 4 — Cleanup** branches; update memory.

---

## Self-review checklist

1. **Every B1 defect fixed:** `<label for>` bound ✅, hint/error have ids ✅, control gets describedby/invalid/required ✅ (Task 1 tests).
2. **data-slot=control on the GROUP**, not the bare input (input-group guard) ✅ (Design reference).
3. **Gem-only / additive:** no existing app form/view/builder/spec touched — only the new component + preview + 0b spec ✅ (Task 3 Step 6).
4. **Label `data-slot=label` passthrough verified**, with the wrap fallback if it doesn't forward ✅ (Task 1 Step 5).
5. **No placeholders:** markup, input_attrs, describedby, wrapper classes all spelled out ✅.
6. **Required handling:** decorative `*` on the Label (aria-hidden) + `required` on the control — never on the caption ✅.
