# Ship shared/_modal + template-backed previews — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the gem emit copyable, paste-ready Lookbook previews — by shipping `app/views/shared/_modal.html.erb` (via `add dialog`) and converting all six component previews to template-backed scenarios.

**Architecture:** (1) A one-branch routing rule in the `add` generator sends leading-underscore `.html.erb` partials to `app/views/shared/`. (2) The dialog's `add` template gains `_modal.html.erb` (the reference app's `trigger:`-mode partial). (3) Each Lookbook preview's scenario methods go empty and gain sibling `<scenario>.html.erb` files; Thor's recursive `directory()` copy needs no change. The five primitive previews move their `ui :x` call verbatim; the dialog is re-authored to `render "shared/modal", trigger:` with gem-portable content only.

**Tech Stack:** Ruby, Rails generators (Thor), ViewComponent/Lookbook previews, Minitest.

**Repo/branch:** `/Users/dschmura/Documents/code/modelrails_ui`, branch `feat/shared-modal-and-copyable-previews`.

**Design doc:** `docs/design/2026-06-02-shared-modal-and-copyable-previews-design.md`

**TOOLCHAIN (critical):** the gem's `mise.toml` is untrusted, so every ruby/rake command MUST be prefixed with `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH"` — do NOT use `mise exec`. Run all commands from the gem repo root. Full suite: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake test`. Single file: `… bundle exec ruby -Itest test/<file>.rb`.

---

## File structure

- Modify: `lib/generators/modelrails_ui/add/add_generator.rb` — add `html_erb_destination` routing helper.
- Create: `lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb` — the shipped partial.
- Modify: `lib/generators/modelrails_ui/lookbook/templates/previews/ui/{button,input,textarea,file_input,avatar,dialog}_component_preview.rb` — empty scenario methods (keep doc-comments/@label/playground).
- Create: `lib/generators/modelrails_ui/lookbook/templates/previews/ui/<component>_component_preview/<scenario>.html.erb` — one per non-playground scenario.
- Create test: `test/test_add_generator_partial_routing.rb`, `test/test_shared_modal_template.rb`, `test/test_lookbook_previews_template_backed.rb`.

---

### Task 1: Route leading-underscore partials to `app/views/shared/`

**Files:**
- Modify: `lib/generators/modelrails_ui/add/add_generator.rb:78-89`
- Test: `test/test_add_generator_partial_routing.rb` (create)

- [ ] **Step 1: Write the failing test**

```ruby
# test/test_add_generator_partial_routing.rb
# frozen_string_literal: true

require "test_helper"

class TestAddGeneratorPartialRouting < Minitest::Test
  # allocate skips #initialize (which requires the components argument); the
  # routing helper is pure and touches no instance state.
  def destination_for(file)
    ModelrailsUi::Generators::AddGenerator.allocate.send(:html_erb_destination, file)
  end

  def test_leading_underscore_partial_routes_to_app_views_shared
    assert_equal "app/views/shared/_modal.html.erb", destination_for("_modal.html.erb")
  end

  def test_component_sidecar_template_routes_to_app_components_ui
    assert_equal "app/components/ui/tabs_component.html.erb", destination_for("tabs_component.html.erb")
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_add_generator_partial_routing.rb`
Expected: FAIL — `NoMethodError: undefined method 'html_erb_destination'`.

- [ ] **Step 3: Implement the routing helper**

In `lib/generators/modelrails_ui/add/add_generator.rb`, replace the `copy_template_file` method's `.html.erb` branch and add the helper (both private):

```ruby
      def copy_template_file(component, file)
        source = "#{component}/#{file}"

        case file
        when /\.rb\.tt\z/
          template source, "app/components/ui/#{file.delete_suffix(".tt")}"
        when /\.html\.erb\z/
          copy_file source, html_erb_destination(file)
        when /_controller\.js\z/
          copy_js_controller source, file.delete_suffix("_controller.js")
        end
      end

      # A leading-underscore .html.erb is a Rails view partial (e.g. _modal) →
      # app/views/shared/. Everything else is a component sidecar template →
      # app/components/ui/.
      def html_erb_destination(file)
        file.start_with?("_") ? "app/views/shared/#{file}" : "app/components/ui/#{file}"
      end
```

- [ ] **Step 4: Run it to verify it passes**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_add_generator_partial_routing.rb`
Expected: `2 runs, 2 assertions, 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/add/add_generator.rb test/test_add_generator_partial_routing.rb
git commit -m "feat(generator): route leading-underscore partials to app/views/shared/"
```

---

### Task 2: Ship the `shared/_modal` partial via the dialog template

**Files:**
- Create: `lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb`
- Test: `test/test_shared_modal_template.rb` (create)

- [ ] **Step 1: Write the failing test**

```ruby
# test/test_shared_modal_template.rb
# frozen_string_literal: true

require "test_helper"

class TestSharedModalTemplate < Minitest::Test
  PATH = File.expand_path(
    "../lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb", __dir__
  )

  def source
    @source ||= File.read(PATH)
  end

  def test_partial_exists
    assert_path_exists PATH, "dialog add-template should ship _modal.html.erb"
  end

  def test_declares_trigger_local_with_default
    assert_includes source, "trigger: nil"
    assert_includes source, 'trigger_class: "btn-secondary"'
  end

  def test_has_complete_and_surface_branches
    assert_includes source, "if trigger.present?"
    assert_includes source, "wrapper: true"          # complete mode
    assert_includes source, "wrapper: false"         # surface mode
    assert_includes source, 'body_id: "modal-body"'  # Turbo Stream contract preserved in surface mode
    assert_includes source, "d.with_trigger"
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_shared_modal_template.rb`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create the partial**

```erb
<%# lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb %>
<%# locals: (title:, id: nil, size: :md, description: nil, trigger: nil, trigger_class: "btn-secondary") -%>
<%#
  Thin adapter over UI::DialogComponent.

  Surface-only (default, no trigger:): renders ONLY the <dialog> (wrapper: false).
  Callers own the surrounding data-controller="modal" wrapper + trigger button.
  body_id stays "modal-body" to preserve the Turbo Stream contract
  (turbo_stream.append "modal-body").

  Complete (pass trigger:): renders the data-controller="modal" wrapper + a trigger
  button + the <dialog> as one copy-paste unit (wrapper: true). body_id uses the
  component's unique default so multiple complete modals on a page don't collide.
-%>
<% if trigger.present? %>
  <%= render UI::DialogComponent.new(
        title: title, id: id, size: size, description: description, wrapper: true) do |d| %>
    <% d.with_trigger do %>
      <%= tag.button(trigger, type: "button", class: trigger_class) %>
    <% end %>
    <%= yield %>
  <% end %>
<% else %>
  <%= render UI::DialogComponent.new(
        title: title, id: id, size: size, description: description,
        wrapper: false, body_id: "modal-body") do %><%= yield %><% end %>
<% end %>
```

- [ ] **Step 4: Run it to verify it passes**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_shared_modal_template.rb`
Expected: `3 runs, … 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb test/test_shared_modal_template.rb
git commit -m "feat(dialog): ship shared/_modal partial (trigger: mode) with the dialog"
```

---

### Task 3: Convert the five primitive previews to template-backed

A purely mechanical move: each scenario's `ui :x` call goes into a sibling `.html.erb`; the method body goes empty; doc-comments, `@label`, and `playground` stay.

**Files (per component, in `lib/generators/modelrails_ui/lookbook/templates/previews/ui/`):**
- Modify: `button_component_preview.rb`, `input_component_preview.rb`, `textarea_component_preview.rb`, `file_input_component_preview.rb`, `avatar_component_preview.rb`
- Create: `<component>_component_preview/<scenario>.html.erb` per non-playground scenario
- Test: `test/test_lookbook_previews_template_backed.rb` (create)

- [ ] **Step 1: Write the failing test**

```ruby
# test/test_lookbook_previews_template_backed.rb
# frozen_string_literal: true

require "test_helper"

class TestLookbookPreviewsTemplateBacked < Minitest::Test
  PREVIEW_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  # component => scenario methods that must be template-backed (playground excluded)
  PRIMITIVES = {
    "button"     => %w[primary secondary danger text_interactive link dont_icon_only_without_label],
    "input"      => %w[default required invalid dont_raw_input],
    "textarea"   => %w[default invalid dont_raw_textarea],
    "file_input" => %w[default images_only multiple dont_raw_file_input],
    "avatar"     => %w[image initials custom_hue dont_interactive_no_label]
  }.freeze

  def preview_rb(component)
    File.read(File.join(PREVIEW_ROOT, "#{component}_component_preview.rb"))
  end

  def test_each_primitive_scenario_has_a_sibling_template
    PRIMITIVES.each do |component, scenarios|
      scenarios.each do |scenario|
        path = File.join(PREVIEW_ROOT, "#{component}_component_preview", "#{scenario}.html.erb")
        assert_path_exists path, "missing sibling template #{path}"
      end
    end
  end

  def test_primitive_scenario_methods_are_empty
    PRIMITIVES.each do |component, scenarios|
      src = preview_rb(component)
      scenarios.each do |scenario|
        # an empty method: `def scenario; end` (no inline ui :x body)
        assert_match(/def #{scenario}; end/, src, "#{component}##{scenario} should be empty")
      end
    end
  end

  def test_playground_stays_inline_where_present
    %w[button avatar].each do |component|
      assert_match(/def playground\(.*\)\n\s+ui /, preview_rb(component),
        "#{component} playground should remain an inline explorer")
    end
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_lookbook_previews_template_backed.rb`
Expected: FAIL — sibling templates missing; methods still have bodies. (If the actual scenario lists differ from `PRIMITIVES`, READ the five `*_component_preview.rb` files and correct the constant before implementing — the test must reflect the real scenarios.)

- [ ] **Step 3: Convert each primitive preview (repeat for all five)**

For EACH of the five components, and EACH scenario method that is NOT `playground`:

1. Create `<component>_component_preview/<scenario>.html.erb` whose entire content is the method's `ui :x …` call wrapped in `<%= … %>`. Worked example — `button` `primary` (was `def primary; ui :button, "Save changes", variant: :primary; end`):

```erb
<%# button_component_preview/primary.html.erb %>
<%= ui :button, "Save changes", variant: :primary %>
```

2. Empty the method in the `.rb`, keeping its doc-comment and any `@label`:

```ruby
    # The default, high-emphasis action. Aim for one primary per view.
    def primary; end
```

Apply verbatim-move for every scenario (e.g. `link` → `<%= ui :button, "Go home", href: "/", variant: :primary %>`; `dont_raw_input` → `<%= ui :input, type: "text", name: "demo_raw" %>`). Leave each preview's `include UIHelper`, class doc-comment, and `playground` method untouched.

- [ ] **Step 4: Run it to verify it passes**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_lookbook_previews_template_backed.rb`
Expected: all assertions pass.

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/lookbook/templates/previews/ui/{button,input,textarea,file_input,avatar}_component_preview.rb \
        lib/generators/modelrails_ui/lookbook/templates/previews/ui/{button,input,textarea,file_input,avatar}_component_preview \
        test/test_lookbook_previews_template_backed.rb
git commit -m "feat(previews): template-back the five primitive component previews"
```

---

### Task 4: Re-author the dialog preview (template-backed, portable)

The dialog scenarios become template-backed AND switch from `ui :dialog … with_trigger` slot-Ruby to `render "shared/modal", trigger:` — using only gem-portable content (plain HTML; no `f.text_field`, no `shared/confirm_dialog`).

**Files:**
- Modify: `lib/generators/modelrails_ui/lookbook/templates/previews/ui/dialog_component_preview.rb`
- Create: `dialog_component_preview/{default,large,dont_no_title}.html.erb`
- Test: extend `test/test_lookbook_previews_template_backed.rb`

- [ ] **Step 1: Add the failing dialog assertions**

Append to `test/test_lookbook_previews_template_backed.rb` (inside the class):

```ruby
  DIALOG_SCENARIOS = %w[default large dont_no_title].freeze

  def dialog_template(scenario)
    File.read(File.join(PREVIEW_ROOT, "dialog_component_preview", "#{scenario}.html.erb"))
  end

  def test_dialog_scenarios_are_template_backed
    src = File.read(File.join(PREVIEW_ROOT, "dialog_component_preview.rb"))
    DIALOG_SCENARIOS.each do |scenario|
      assert_path_exists File.join(PREVIEW_ROOT, "dialog_component_preview", "#{scenario}.html.erb")
      assert_match(/def #{scenario}; end/, src, "dialog##{scenario} should be empty")
    end
  end

  def test_dialog_scenarios_teach_shared_modal_and_stay_portable
    DIALOG_SCENARIOS.each do |scenario|
      src = dialog_template(scenario)
      assert_includes src, 'render "shared/modal"', "#{scenario} should teach the shared/modal partial"
      # Portability guard: no app-only infrastructure may leak into the gem.
      refute_includes src, "f.text_field", "#{scenario} must not use the app form builder"
      refute_includes src, "shared/confirm_dialog", "#{scenario} must not use the app confirm partial"
      refute_includes src, "avatar_for", "#{scenario} must not use the app avatar helper"
    end
  end
```

- [ ] **Step 2: Run to verify it fails**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_lookbook_previews_template_backed.rb`
Expected: FAIL — dialog templates missing; methods still slot-Ruby.

- [ ] **Step 3: Create the three dialog scenario templates**

```erb
<%# dialog_component_preview/default.html.erb %>
<%= render "shared/modal",
      title: "Confirm action",
      description: "This action cannot be undone.",
      trigger: "Open dialog",
      trigger_class: "btn-primary" do %>
  <p>Are you sure you want to proceed? All related data will be permanently removed.</p>
<% end %>
```

```erb
<%# dialog_component_preview/large.html.erb %>
<%= render "shared/modal",
      title: "Edit profile",
      description: "Update your display name and preferences.",
      size: :lg,
      trigger: "Open large dialog",
      trigger_class: "btn-secondary" do %>
  <%= ui :input, type: "text", name: "display_name", placeholder: "Display name" %>
<% end %>
```

```erb
<%# dialog_component_preview/dont_no_title.html.erb %>
<%# ✗ A vague title gives screen-reader users no context via aria-labelledby. %>
<%= render "shared/modal", title: "Untitled", trigger: "Open", trigger_class: "btn-secondary" do %>
  Body content.
<% end %>
```

- [ ] **Step 4: Empty the dialog preview methods (keep doc-comments + @label)**

In `dialog_component_preview.rb`, replace the three method bodies with empties, preserving the class doc-comment, each method's comment, and the `@label Don't · no title (breaks aria-labelledby)` annotation:

```ruby
    def default; end

    def large; end

    # @label Don't · no title (breaks aria-labelledby)
    def dont_no_title; end
```

- [ ] **Step 5: Run to verify it passes**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec ruby -Itest test/test_lookbook_previews_template_backed.rb`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/generators/modelrails_ui/lookbook/templates/previews/ui/dialog_component_preview.rb \
        lib/generators/modelrails_ui/lookbook/templates/previews/ui/dialog_component_preview \
        test/test_lookbook_previews_template_backed.rb
git commit -m "feat(previews): re-author dialog previews to teach render shared/modal (portable)"
```

---

### Task 5: Full suite + integration check

- [ ] **Step 1: Run the full gem test suite**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake test`
Expected: 0 failures, 0 errors. (Confirms the existing template-syntax / component tests still pass alongside the new ones.)

- [ ] **Step 2: Integration check — regenerate into the reference app (manual, optional but recommended)**

In a throwaway branch of modelrails_base, point its Gemfile at this local gem (`gem "modelrails_ui", path: "../modelrails_ui"`), run `bin/rails g modelrails_ui:add dialog` and `bin/rails g modelrails_ui:lookbook`, and confirm: `app/views/shared/_modal.html.erb` lands in the right place, `/lookbook` renders each component, and the Source tab shows the copyable ERB. Discard the throwaway branch afterward. (This is the only true render check; the gem's own suite is structural.)

- [ ] **Step 3: Final commit (if any fixups)**

```bash
git add -A
git commit -m "chore: tidy after shared/_modal + template-backed preview port"
```

---

## Out of scope

- Form-builder / `avatar_for` / model-aware helpers (app-specific; the gem's primitives are already clean).
- A gem release/tag (owner's call).
- Changing the `lookbook` generator (Thor `directory()` copies the new sibling dirs recursively).
