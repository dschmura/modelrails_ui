# Phase 0a — Render Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the gem the ability to actually RENDER a component and assert real HTML/ARIA (via `render_inline` + Capybara matchers), so every future hardening wave is verifiable — proven end-to-end on `button`.

**Architecture:** The gem already loads `.rb.tt` templates by `eval`-ing them as plain Ruby (`test/test_components.rb`) — but against a STUBBED `ViewComponent::Base` (`.call` returns `""`). Phase 0a adds a SECOND, isolated test lane that loads the **real** `view_component` + a minimal Rails app context, evals a component template into a real class, and renders it. The structural lane (stub-based) and the render lane (real ViewComponent) **cannot share a Ruby process** (the stub `ViewComponent::Base` collides with the real one), so they run as **separate rake tasks**.

**Tech Stack:** Ruby, Rails (`railties`/`rails` already deps), `view_component (>= 4.0)` (already a dep), Capybara (to ADD), Minitest. The gem's `mise.toml` is UNTRUSTED — every ruby/rake/rails command MUST be prefixed `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH"` (NOT `mise exec`).

**Design doc:** `docs/design/2026-06-03-component-hardening-program-design.md`

**Scope:** the harness + `button` as proof ONLY. Do NOT harden any other component.

---

## File structure

- Modify: `Gemfile` — add `capybara` (dev).
- Modify: `Rakefile` — split tests into two tasks: `test:structural` (existing, stub-based) and `test:render` (new, real ViewComponent), each its own process; `rake test` runs both; default `rake` = `test` + rubocop.
- Create: `test/render/render_test_helper.rb` — boots minimal Rails app + real `view_component`, evals component templates into real classes, provides `ViewComponent::TestCase`.
- Create: `test/render/button_render_test.rb` — the proof render test.
- Modify: `.github/workflows/main.yml` — only if the matrix doesn't already run the new task (it runs `rake`/`rake test`, which will include `test:render` once the Rakefile wires it).
- Unchanged: `test/test_components.rb` (structural, keeps its stub), `test/test_aaa_contrast.rb` (the AAA-token guarantee).

---

### Task 1: Split the test suite so a real-ViewComponent lane can exist

The structural lane stubs `ViewComponent::Base`; the render lane needs the real one. They must run in separate processes. Establish the split FIRST (with the render lane empty), so later tasks have somewhere isolated to live.

**Files:** `Rakefile`, `Gemfile`

- [ ] **Step 1: Note the current Rakefile** — it is exactly:

```ruby
require "bundler/gem_tasks"
require "minitest/test_task"
Minitest::TestTask.create        # one :test task, globs all test files into ONE process
require "rubocop/rake_task"
RuboCop::RakeTask.new
task default: %i[test rubocop]
```

`Minitest::TestTask.create` loads every test file into a single `ruby` process — which is why the structural stub and a real `view_component` can't coexist. The split below gives each lane its own process.

- [ ] **Step 2: Add Capybara (dev dep)**

In `Gemfile`, add (near the other dev gems):

```ruby
gem "capybara", require: false
```

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle install` → expect it resolves + installs capybara.

- [ ] **Step 3: Define two test tasks + keep them separate processes**

Replace the single `Minitest::TestTask.create` with two named tasks — each `Minitest::TestTask` shells out to its own `ruby` process, which is the isolation we need. The structural lane globs the top-level `test/test_*.rb` files (the existing stub-based suite); the render lane globs `test/render/**/*_test.rb`. New `Rakefile`:

```ruby
# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

# Structural lane: stubs ViewComponent (test_components.rb), reads templates as text.
Minitest::TestTask.create(:"test:structural") do |t|
  t.test_globs = ["test/test_*.rb"]
  t.warning = true
end

# Render lane: real view_component + a minimal Rails app (test/render/render_test_helper.rb).
# MUST be a separate process from the structural lane (incompatible ViewComponent::Base).
Minitest::TestTask.create(:"test:render") do |t|
  t.libs << "test/render"
  t.test_globs = ["test/render/**/*_test.rb"]
  t.warning = false # Rails/ViewComponent emit harmless warnings under -w
end

task test: [:"test:structural", :"test:render"]

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: %i[test rubocop]
```

(`test/test_*.rb` matches the existing structural files incl. the harmless `test_helper.rb`; `test/render/` is excluded from structural and owns the render lane.)

- [ ] **Step 4: Run it to confirm the split works (render lane empty = passes trivially)**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake test:structural` → expect the existing structural suite passes (same counts as before).
Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake test:render` → expect "0 tests" (no render tests yet) and SUCCESS.

- [ ] **Step 5: Commit**

```bash
git add Gemfile Gemfile.lock Rakefile
git commit -m "test(harness): split structural vs render test lanes; add capybara dev dep"
```

---

### Task 2: Build the render harness (SPIKE → working `render_inline`)

**This is the research-heavy enabler.** Goal: from a render test, `render_inline(UI::ButtonComponent.new("Save", variant: :primary))` must return REAL `<button>...</button>` HTML. The mechanism is uncertain enough to spike — but the gem already evals templates, so the recommended path is light.

**Recommended approach (B-extended): minimal in-test Rails app + eval into real classes.** A full `test/dummy` directory app (approach A) is heavier and only needed if `render_inline` refuses to work without it. Try B first.

**Files:** `test/render/render_test_helper.rb`

- [ ] **Step 1: Consult ViewComponent's documented test setup**

Use context7 (`mcp__plugin_context7_context7__resolve-library-id` "view_component" → `query-docs` for "test setup render_inline ViewComponent::TestCase minimal Rails application engine"). Confirm the minimal requirements for `render_inline`: ViewComponent 4 needs `Rails.application` initialized and `ViewComponent::Test::TestHelpers`/`ViewComponent::TestCase`. Note whether a bare `Rails::Application` subclass (no dummy dir) suffices, or a `test/dummy` app is required.

- [ ] **Step 2: Write `test/render/render_test_helper.rb`** — minimal Rails app + real view_component + real ApplicationComponent + eval the install/add templates into real classes.

Starting point to spike from (adjust per Step 1's findings):

```ruby
# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "view_component"
require "capybara/minitest"

# Minimal Rails app — just enough to host ViewComponent rendering. No dummy dir.
class RenderHarnessApp < Rails::Application
  config.eager_load = false
  config.consider_all_requests_local = true
  config.secret_key_base = "test"
  config.logger = Logger.new(IO::NULL)
end
Rails.application.initialize! unless Rails.application.initialized?

require "minitest/autorun"

# Real base class (mirrors install/templates/application_component.rb.tt, with the
# real ViewComponent::Base — NOT the structural stub).
class ApplicationComponent < ViewComponent::Base
  private

  def cn(*classes)
    classes.flatten.compact.reject { |c| c.to_s.empty? }.join(" ")
  end
end

ADD_TEMPLATES = File.expand_path("../../lib/generators/modelrails_ui/add/templates", __dir__)

# Eval a component template (plain Ruby; .tt is convention) into a real class.
def load_component(*parts)
  path = File.join(ADD_TEMPLATES, *parts)
  eval File.read(path), TOPLEVEL_BINDING, path # rubocop:disable Security/Eval
end

module RenderHarness
  include Capybara::Minitest::Assertions
end
```

- [ ] **Step 3: Spike a smoke check that rendering works**

Create a throwaway `test/render/smoke_render_test.rb`:

```ruby
require "render_test_helper"
load_component "button", "button_component.rb.tt"

class SmokeRenderTest < ViewComponent::TestCase
  def test_button_renders_real_html
    render_inline(UI::ButtonComponent.new("Save", variant: :primary))
    assert_selector "button", text: "Save"
  end
end
```

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake test:render`

- **Success:** the assertion passes — `render_inline` produced a real `<button>Save</button>`. The harness works; proceed.
- **If it fails** (Rails app won't init for render_inline / view paths missing / etc.): READ the error. The two likely fixes, in order: (a) include `ViewComponent::Test::TestHelpers` explicitly and ensure `ViewComponent::Base.config.view_component_path`/preview config isn't required; (b) if ViewComponent 4 genuinely needs an app on disk, FALL BACK to approach A — generate a minimal `test/dummy` app (`rails new test/dummy --minimal --skip-*`), add `view_component` to it, and run the gem's `install` + `add button` generators into it in the harness setup, then render. Document which approach won in a comment at the top of `render_test_helper.rb`.

- [ ] **Step 4: Delete the throwaway smoke test once green**

```bash
rm test/render/smoke_render_test.rb
```

- [ ] **Step 5: Commit the harness**

```bash
git add test/render/render_test_helper.rb Gemfile.lock
git commit -m "test(harness): real-ViewComponent render harness (render_inline works on a component)"
```

---

### Task 3: Button proof render test (TDD)

Prove the harness verifies the things the hardening DoD cares about: correct tag, AAA token classes, ARIA, and the fail-loud guard.

**Files:** `test/render/button_render_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
# frozen_string_literal: true

require "render_test_helper"
load_component "button", "button_component.rb.tt"

class ButtonRenderTest < ViewComponent::TestCase
  def test_primary_renders_button_with_aaa_tokens
    render_inline(UI::ButtonComponent.new("Save changes", variant: :primary))
    assert_selector "button[type='button']", text: "Save changes"
    # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
    assert_selector "button.bg-interactive"
    assert_selector "button.text-text-on-interactive"
    assert_selector "button.focus\\:ring-interactive-focus"
  end

  def test_href_renders_anchor
    render_inline(UI::ButtonComponent.new("Home", href: "/", variant: :primary))
    assert_selector "a[href='/']", text: "Home"
  end

  def test_unknown_variant_raises
    assert_raises(ArgumentError) do
      render_inline(UI::ButtonComponent.new("X", variant: :bogus))
    end
  end
end
```

- [ ] **Step 2: Run to verify it passes (harness from Task 2 makes it real)**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake test:render`
Expected: all pass. If a token assertion fails, INSPECT the rendered HTML (`puts page.native.to_html` in the test) and reconcile the selector with what `button_component.rb.tt` actually emits (the FILLED/VARIANTS class strings) — do NOT change the component; only fix the test selector to match reality.

- [ ] **Step 3: Commit**

```bash
git add test/render/button_render_test.rb
git commit -m "test(harness): button render test proves real HTML/ARIA + fail-loud guard"
```

---

### Task 4: Wire CI + document the harness for future waves

**Files:** `.github/workflows/main.yml` (verify only), `README.md`

- [ ] **Step 1: Confirm the full default task is green locally**

Run: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.4/bin:$PATH" bundle exec rake`
Expected: `test:structural` + `test:render` + rubocop all pass, 0 failures, 0 offenses. (If rubocop flags the new files — e.g. the `eval` — add a scoped `# rubocop:disable` with a comment, matching how `test_components.rb` handles its eval.)

- [ ] **Step 2: Confirm CI runs the render lane**

Read `.github/workflows/main.yml`. The jobs run `bundle exec rake` (default) and `appraisal ... rake test`. Since Task 1 made `rake test` depend on `test:render`, the matrix already covers it — confirm no job hardcodes only `test:structural`. If a job needs capybara available, ensure `bundle install` (already in the workflow) picks it up from the Gemfile. Make the minimal edit only if a job bypasses the new task.

- [ ] **Step 3: Document the harness in README**

Add a short "Verifying components (render tests)" section: how to write a render test for a component (`require "render_test_helper"`, `load_component`, `ViewComponent::TestCase`, `render_inline`, `assert_selector`), and that this is the verification basis for the hardening program (link the design doc). This is the on-ramp every future wave uses.

- [ ] **Step 4: Commit**

```bash
git add README.md .github/workflows/main.yml
git commit -m "docs(harness): document render-test on-ramp; confirm CI runs the render lane"
```

---

## Out of scope (later phases)

- Hardening any component other than `button` (Wave 1 onward).
- Browser axe-AAA system tests (Phase 0b — Capybara+Playwright+axe in the dummy app).
- A tier ledger (`COMPONENT_STATUS.md`) — introduced when Wave 1 starts producing `proven` components.

## Risk note

Task 2 is the only genuinely uncertain task. Its success criterion is concrete (button renders real HTML), and it has a documented fallback (approach A: a real `test/dummy` app) if the minimal-app route fails. Every later phase depends on Task 2 landing, so treat its green smoke test as the gate for the whole program.
