# Agent-rules generator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional `modelrails_ui:agent_rules` generator that teaches a coding agent to defer to the design system, plus a post-install nudge.

**Architecture:** A `Rails::Generators::Base` subclass that writes a gem-owned rules file (overwritten every run), seeds a developer-owned house-rules file (once, never overwritten), adds a marker-delimited `@`-import to the host agent file (idempotent), and reports — never rewrites — conflicting host directives. The tricky decisions (host-file priority, idempotent import, conflict scan) live in pure methods unit-tested in isolation; thin Thor file I/O is covered by tmpdir integration tests that instantiate the generator directly.

**Tech Stack:** Ruby, Rails generators (Thor), Minitest. All work happens in the `modelrails_ui` gem on branch `feat/agent-rules-generator` (already created off `modelrails/harden`).

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb` | The generator: pure decision methods + Thor public steps |
| `lib/generators/modelrails_ui/agent_rules/templates/agent-rules.md` | Gem-owned design-system rules (copied verbatim, always overwritten) |
| `lib/generators/modelrails_ui/agent_rules/templates/house-rules.md` | Seed defaults (I18n, CSP→Stimulus); created once |
| `lib/generators/modelrails_ui/install/install_generator.rb` | Modified: add `print_agent_rules_nudge` step |
| `test/test_agent_rules_generator.rb` | Pure-method unit tests + tmpdir integration tests |
| `README.md`, `CHANGELOG.md`, `MODELRAILS_STATUS.md` | Docs + maturity ledger |

**Run tests from the gem root** (`/Users/dschmura/Documents/code/modelrails_ui`):
- Single file: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
- Single test: append `-n test_name`
- Full suite: `bundle exec rake test`

---

### Task 1: Generator skeleton + host-file resolution (pure)

**Files:**
- Create: `lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb`
- Test: `test/test_agent_rules_generator.rb`

- [ ] **Step 1: Write the failing test**

Create `test/test_agent_rules_generator.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/agent_rules/agent_rules_generator"

class TestAgentRulesGenerator < Minitest::Test
  # `pick_agent_file` is pure (no destination_root / FS), so allocate skips #initialize.
  def pick(existing:, override: nil)
    ModelrailsUi::Generators::AgentRulesGenerator
      .allocate.send(:pick_agent_file, existing: existing, override: override)
  end

  def test_prefers_claude_md_when_it_exists
    assert_equal "CLAUDE.md", pick(existing: ["CLAUDE.md", "AGENTS.md"])
  end

  def test_falls_back_to_agents_md_when_only_it_exists
    assert_equal "AGENTS.md", pick(existing: ["AGENTS.md"])
  end

  def test_defaults_to_claude_md_when_neither_exists
    assert_equal "CLAUDE.md", pick(existing: [])
  end

  def test_explicit_override_wins
    assert_equal "docs/AGENT.md", pick(existing: ["CLAUDE.md"], override: "docs/AGENT.md")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
Expected: FAIL — `cannot load such file -- .../agent_rules_generator` (file not created yet).

- [ ] **Step 3: Write minimal implementation**

Create `lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb`:

```ruby
# frozen_string_literal: true

module ModelrailsUi
  module Generators
    # Optional: teaches a coding agent to defer to the modelrails_ui design system.
    # Writes a gem-owned rules file (overwritten on re-run), seeds a developer-owned
    # house-rules file (once), adds a marker-delimited @-import to the host agent file
    # (idempotent), and reports — never rewrites — conflicting host directives.
    #
    #   rails g modelrails_ui:agent_rules
    class AgentRulesGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      AGENT_FILE_CANDIDATES = %w[CLAUDE.md AGENTS.md].freeze

      class_option :file, type: :string, default: nil,
        desc: "Host agent file to import into (default: CLAUDE.md, else AGENTS.md)"

      private

      # Pure: explicit override wins, else first existing candidate in priority
      # order (CLAUDE.md before AGENTS.md), else the default (CLAUDE.md).
      def pick_agent_file(existing:, override: nil)
        return override if override && !override.empty?

        (AGENT_FILE_CANDIDATES & existing).first || AGENT_FILE_CANDIDATES.first
      end
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
Expected: PASS (4 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb test/test_agent_rules_generator.rb
git commit -m "feat(agent-rules): host agent-file resolution"
```

---

### Task 2: Idempotent import-block insertion (pure)

**Files:**
- Modify: `lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb`
- Test: `test/test_agent_rules_generator.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/test_agent_rules_generator.rb` (inside the class):

```ruby
  def with_block(content)
    ModelrailsUi::Generators::AgentRulesGenerator
      .allocate.send(:with_import_block, content)
  end

  def test_adds_block_to_empty_file
    result = with_block("")
    assert_includes result, "<!-- BEGIN modelrails_ui -->"
    assert_includes result, "@.modelrails_ui/agent-rules.md"
  end

  def test_appends_block_after_existing_content_with_separation
    result = with_block("# My rules\n")
    assert_includes result, "# My rules"
    assert_includes result, "<!-- BEGIN modelrails_ui -->"
    assert result.index("# My rules") < result.index("<!-- BEGIN modelrails_ui -->")
  end

  def test_is_idempotent_when_block_already_present
    once = with_block("# My rules\n")
    twice = with_block(once)
    assert_equal once, twice
    assert_equal 1, twice.scan("<!-- BEGIN modelrails_ui -->").size
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb -n /import_block|block_already|adds_block/`
Expected: FAIL — `NoMethodError: ... with_import_block`.

- [ ] **Step 3: Write minimal implementation**

In `agent_rules_generator.rb`, add the constant under `AGENT_FILE_CANDIDATES`:

```ruby
      MARKER = "<!-- BEGIN modelrails_ui -->"

      IMPORT_BLOCK = <<~MARKDOWN
        <!-- BEGIN modelrails_ui -->
        When building or changing UI, follow the design-system rules in @.modelrails_ui/agent-rules.md
        <!-- END modelrails_ui -->
      MARKDOWN
```

And add this private method:

```ruby
      # Pure: returns content unchanged if the block is already present; otherwise
      # appends it (with a blank-line separator when content is non-empty).
      def with_import_block(content)
        return content if content.include?(MARKER)

        content.empty? ? IMPORT_BLOCK : "#{content.chomp}\n\n#{IMPORT_BLOCK}"
      end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
Expected: PASS (7 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb test/test_agent_rules_generator.rb
git commit -m "feat(agent-rules): idempotent import-block insertion"
```

---

### Task 3: Conflict scan (pure)

**Files:**
- Modify: `lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb`
- Test: `test/test_agent_rules_generator.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/test_agent_rules_generator.rb` (inside the class):

```ruby
  def warnings_for(content)
    ModelrailsUi::Generators::AgentRulesGenerator
      .allocate.send(:conflict_warnings, content, file: "context.md")
  end

  def test_flags_viewcomponents_only_when_reused
    warnings = warnings_for("- ViewComponents only when reused across unrelated views")
    assert_equal 1, warnings.size
    assert_equal "context.md", warnings.first[:file]
    assert_includes warnings.first[:message], "shared library"
  end

  def test_no_warnings_for_clean_content
    assert_empty warnings_for("- Use Pundit for authorization")
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb -n /flags_viewcomponents|clean_content/`
Expected: FAIL — `NoMethodError: ... conflict_warnings`.

- [ ] **Step 3: Write minimal implementation**

In `agent_rules_generator.rb`, add the constant under `IMPORT_BLOCK`:

```ruby
      CONFLICT_PATTERNS = [
        {
          pattern: /ViewComponents only when reused/i,
          summary: '"ViewComponents only when reused"',
          message: "modelrails_ui's UI::* primitives ARE the shared library; this guideline " \
                   "governs new app-specific components, not the design-system primitives."
        }
      ].freeze
```

And add this private method:

```ruby
      # Pure: returns one warning hash per known-tension pattern found in `content`.
      def conflict_warnings(content, file:)
        CONFLICT_PATTERNS.filter_map do |c|
          next unless content.match?(c[:pattern])

          {file: file, summary: c[:summary], message: c[:message]}
        end
      end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
Expected: PASS (9 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb test/test_agent_rules_generator.rb
git commit -m "feat(agent-rules): report-only conflict scan"
```

---

### Task 4: Templates (agent-rules.md + house-rules.md)

**Files:**
- Create: `lib/generators/modelrails_ui/agent_rules/templates/agent-rules.md`
- Create: `lib/generators/modelrails_ui/agent_rules/templates/house-rules.md`
- Test: `test/test_agent_rules_generator.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/test_agent_rules_generator.rb` (inside the class):

```ruby
  TEMPLATE_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/agent_rules/templates", __dir__
  )

  def test_agent_rules_template_anchors_present
    content = File.read(File.join(TEMPLATE_ROOT, "agent-rules.md"))
    assert_includes content, "Design system rules (modelrails_ui)"
    assert_includes content, "bin/rails g modelrails_ui:list"
    assert_includes content, "text-text-muted"
    assert_includes content, "@.modelrails_ui/house-rules.md"
  end

  def test_house_rules_template_anchors_present
    content = File.read(File.join(TEMPLATE_ROOT, "house-rules.md"))
    assert_includes content, "I18n locale keys"
    assert_includes content, "Stimulus"
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb -n /template_anchors/`
Expected: FAIL — `Errno::ENOENT` (template files don't exist yet).

- [ ] **Step 3: Create the templates**

Create `lib/generators/modelrails_ui/agent_rules/templates/agent-rules.md`:

```markdown
# Design system rules (modelrails_ui)

This app uses **modelrails_ui** — an AAA, OKLCH-themed ViewComponent library.
Defer to it instead of inventing UI from scratch.

## Before you build any UI
- **Check what exists first.** `bin/rails g modelrails_ui:list` shows installed primitives;
  `docs/components/<name>.md` documents usage; `/lookbook` shows live previews.
- **Prefer a documented `UI::*` primitive** over a hand-rolled utility stack. Build bespoke
  markup only when no primitive fits — and say so explicitly.
- `UI::*` **is** the shared component library — use it freely.

## Color, type, tokens — never raw
- **No raw hex, arbitrary color utilities, or off-system fonts.** Use semantic tokens:
  `bg-page`/`bg-surface`, `text-text-body`/`text-text-heading`, `bg-hue-*`, `.btn-*`.
- **Signals** are canonical `info · success · warning · danger`. Chips (alert/badge/toast)
  are *tinted* (`bg-*-surface` + `text-*` + `*-border`); fills (button, indicator dot) are
  *solid* with adaptive on-color. Base signal tokens are TEXT colors — never a solid fill,
  and never pair a signal fill with `text-text-heading`.
- **AAA is built into the tokens.** `text-text-muted` resolves to the *same* value as
  `text-text-body` (both ≥7:1) — de-emphasize with size/weight, never by "fixing" muted.

## Before you call UI work done
- **Check both themes** — light *and* dark (class-based dark mode).
- **Contrast is proven in CI, not locally** — a local axe pass is AA-only; don't claim AAA
  from a local run.
- **Fail loud, don't fabricate.** If a needed token or primitive seems missing, surface it —
  don't invent a raw-value or contrast workaround.

## Project house rules
This app also follows @.modelrails_ui/house-rules.md — sensible defaults you can edit.
```

Create `lib/generators/modelrails_ui/agent_rules/templates/house-rules.md`:

```markdown
# Project house rules (UI)

Sensible defaults from modelrails_ui. This is *your* file — edit or delete freely;
the generator seeds it once and never overwrites it.

- **All UI text uses I18n locale keys** — no hardcoded strings.
- **No inline event handlers** (`onclick`, `onchange`, …). A strict Content Security
  Policy (CSP) blocks them, and system specs won't catch it (Playwright bypasses CSP) —
  use Stimulus actions: `data-action="click->controller#method"`.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
Expected: PASS (11 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/agent_rules/templates/
git add test/test_agent_rules_generator.rb
git commit -m "feat(agent-rules): rules + house-rules templates"
```

---

### Task 5: Generator public steps + tmpdir integration tests

**Files:**
- Modify: `lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb`
- Test: `test/test_agent_rules_generator.rb`

- [ ] **Step 1: Write the failing test**

Add `require "tmpdir"` and `require "stringio"` near the top of `test/test_agent_rules_generator.rb` (after the existing requires), then add inside the class:

```ruby
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def run_agent_rules(dest, file: nil)
    opts = file ? {"file" => file} : {}
    generator = ModelrailsUi::Generators::AgentRulesGenerator.new([], opts, destination_root: dest)
    capture_stdout do
      generator.write_agent_rules
      generator.seed_house_rules
      generator.ensure_import
      generator.report_conflicts
      generator.print_summary
    end
  end

  def test_fresh_run_creates_both_files_and_import
    Dir.mktmpdir do |dest|
      run_agent_rules(dest)
      assert_path_exists File.join(dest, ".modelrails_ui/agent-rules.md")
      assert_path_exists File.join(dest, ".modelrails_ui/house-rules.md")
      claude = File.read(File.join(dest, "CLAUDE.md"))
      assert_includes claude, "<!-- BEGIN modelrails_ui -->"
      assert_includes claude, "@.modelrails_ui/agent-rules.md"
    end
  end

  def test_rerun_overwrites_rules_but_preserves_house_rules_and_single_import
    Dir.mktmpdir do |dest|
      run_agent_rules(dest)
      house = File.join(dest, ".modelrails_ui/house-rules.md")
      File.write(house, "# MY EDITS\n")
      File.write(File.join(dest, ".modelrails_ui/agent-rules.md"), "stale\n")

      run_agent_rules(dest)

      assert_equal "# MY EDITS\n", File.read(house), "house-rules must survive re-run"
      assert_includes File.read(File.join(dest, ".modelrails_ui/agent-rules.md")),
        "Design system rules", "agent-rules must be re-seeded from the gem"
      claude = File.read(File.join(dest, "CLAUDE.md"))
      assert_equal 1, claude.scan("<!-- BEGIN modelrails_ui -->").size, "import added once"
    end
  end

  def test_routes_import_into_existing_agents_md
    Dir.mktmpdir do |dest|
      File.write(File.join(dest, "AGENTS.md"), "# Agents\n")
      run_agent_rules(dest)
      assert_includes File.read(File.join(dest, "AGENTS.md")), "<!-- BEGIN modelrails_ui -->"
      refute_path_exists File.join(dest, "CLAUDE.md")
    end
  end

  def test_reports_conflict_from_context_md
    Dir.mktmpdir do |dest|
      FileUtils.mkdir_p(File.join(dest, ".claude-on-rails"))
      File.write(File.join(dest, ".claude-on-rails/context.md"),
        "- ViewComponents only when reused across unrelated views\n")
      output = run_agent_rules(dest)
      assert_includes output, "may conflict"
      assert_includes output, "shared library"
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb -n /fresh_run|rerun_overwrites|routes_import|reports_conflict/`
Expected: FAIL — `NoMethodError: undefined method 'write_agent_rules'`.

- [ ] **Step 3: Write the public steps**

In `agent_rules_generator.rb`, add these public methods (above `private`), after the `class_option` line:

```ruby
      def write_agent_rules
        # Gem-owned: always overwrite so re-running pulls the latest rules.
        copy_file "agent-rules.md", ".modelrails_ui/agent-rules.md", force: true
      end

      def seed_house_rules
        target = ".modelrails_ui/house-rules.md"
        if File.exist?(File.join(destination_root, target))
          say "  #{target} already exists — leaving your edits untouched.", :yellow
        else
          copy_file "house-rules.md", target
        end
      end

      def ensure_import
        target = agent_file
        path = File.join(destination_root, target)
        existing = File.exist?(path) ? File.read(path) : ""
        updated = with_import_block(existing)

        if updated == existing
          say "  #{target} already imports the design-system rules — skipping.", :yellow
        else
          create_file target, updated, force: true
          say "  Added the modelrails_ui import block to #{target}.", :green
        end
      end

      def report_conflicts
        warnings = scan_files.flat_map do |relpath|
          conflict_warnings(File.read(File.join(destination_root, relpath)), file: relpath)
        end
        return if warnings.empty?

        say "\n  Heads up — found directives that may conflict with the design system:", :yellow
        warnings.each do |w|
          say "    • #{w[:file]}: #{w[:summary]}", :yellow
          say "      Suggest: #{w[:message]}", :cyan
        end
        say "  (Not changed — edit them yourself if you agree.)\n", :yellow
      end

      def print_summary
        say "\n  Design-system agent rules installed.", :green
        say "    • .modelrails_ui/agent-rules.md  (gem-owned; re-run to update)", :cyan
        say "    • .modelrails_ui/house-rules.md   (yours to edit)", :cyan
        say "    • import added to #{agent_file}\n", :cyan
      end
```

Then add these private helpers (below the existing private methods):

```ruby
      def agent_file
        @agent_file ||= pick_agent_file(
          existing: AGENT_FILE_CANDIDATES.select { |c| File.exist?(File.join(destination_root, c)) },
          override: options[:file]
        )
      end

      # Files worth scanning for conflicts: the agent files + ClaudeOnRails context.
      def scan_files
        ["CLAUDE.md", "AGENTS.md", ".claude-on-rails/context.md"]
          .select { |f| File.exist?(File.join(destination_root, f)) }
      end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb`
Expected: PASS (15 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/agent_rules/agent_rules_generator.rb test/test_agent_rules_generator.rb
git commit -m "feat(agent-rules): generator steps with idempotent file I/O"
```

---

### Task 6: Post-install nudge

**Files:**
- Modify: `lib/generators/modelrails_ui/install/install_generator.rb`
- Test: `test/test_agent_rules_generator.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/test_agent_rules_generator.rb` — first add the require at the top:

```ruby
require_relative "../lib/generators/modelrails_ui/install/install_generator"
```

Then add inside the class:

```ruby
  def test_install_generator_nudges_toward_agent_rules
    Dir.mktmpdir do |dest|
      generator = ModelrailsUi::Generators::InstallGenerator.new([], {}, destination_root: dest)
      output = capture_stdout { generator.print_agent_rules_nudge }
      assert_includes output, "modelrails_ui:agent_rules"
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb -n test_install_generator_nudges_toward_agent_rules`
Expected: FAIL — `NoMethodError: undefined method 'print_agent_rules_nudge'`.

- [ ] **Step 3: Add the nudge step**

In `lib/generators/modelrails_ui/install/install_generator.rb`, add this method immediately after `inject_css_import` (the last public method, before `private`):

```ruby
      def print_agent_rules_nudge
        say "\n  Optional: teach your coding agent to use these components —", :green
        say "    bin/rails g modelrails_ui:agent_rules", :cyan
      end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec ruby -Itest test/test_agent_rules_generator.rb -n test_install_generator_nudges_toward_agent_rules`
Expected: PASS (1 run, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add lib/generators/modelrails_ui/install/install_generator.rb test/test_agent_rules_generator.rb
git commit -m "feat(agent-rules): nudge from install generator"
```

---

### Task 7: Docs, changelog, and status ledger

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `MODELRAILS_STATUS.md`

- [ ] **Step 1: README — document the generator**

In `README.md`, in the Installation/Usage area near the `modelrails_ui:lookbook` mention, add a subsection:

```markdown
### Teach your coding agent (optional)

```bash
rails g modelrails_ui:agent_rules
```

Writes `.modelrails_ui/agent-rules.md` (gem-owned design-system rules, overwritten on
re-run) and seeds `.modelrails_ui/house-rules.md` (your editable host-policy defaults), then
adds a marker-delimited `@`-import to your `CLAUDE.md`/`AGENTS.md`. It reports — never
rewrites — directives that conflict with the design system. Re-run after a gem bump to refresh
the rules; your house-rules edits are preserved.
```

- [ ] **Step 2: CHANGELOG — one-line action entry**

In `CHANGELOG.md`, under the top/unreleased section, add (match the file's existing one-line style):

```markdown
- Add optional `modelrails_ui:agent_rules` generator: writes design-system agent rules + seeded house rules, adds an idempotent `@`-import, reports directive conflicts.
```

- [ ] **Step 3: MODELRAILS_STATUS — record the generator**

In `MODELRAILS_STATUS.md`, add a row/line noting `agent_rules` generator as solid (follow the file's existing format for generators).

- [ ] **Step 4: Run the full suite**

Run: `bundle exec rake test`
Expected: PASS — all tests green (existing suite + the new `test_agent_rules_generator.rb`).

- [ ] **Step 5: Commit**

```bash
git add README.md CHANGELOG.md MODELRAILS_STATUS.md
git commit -m "docs(agent-rules): document generator + status ledger"
```

---

## Self-Review

**Spec coverage** — every design-doc element maps to a task:
- Optional generator → Tasks 1–5. Post-install nudge → Task 6.
- Reference target (existing mechanisms) → baked into `agent-rules.md` template (Task 4).
- Owned file overwritten / house-rules seeded-once → Task 5 (`write_agent_rules` force, `seed_house_rules` guard) + `test_rerun_overwrites_rules_but_preserves_house_rules`.
- Marker `@`-import, idempotent → Tasks 2 + 5 (`with_import_block`, `ensure_import`, single-import assertion).
- Detect-and-report conflicts → Tasks 3 + 5 (`conflict_warnings`, `report_conflicts`, `test_reports_conflict_from_context_md`).
- Host-file resolution (CLAUDE.md → AGENTS.md → default, `--file`) → Task 1 + `test_routes_import_into_existing_agents_md`.
- House-rules defaults (I18n, CSP) → Task 4.
- Two-PR rollout → gem PR is Tasks 1–7; app adoption is a separate follow-up (out of scope for this plan).

**Placeholder scan** — no TBD/TODO; every code step shows complete code. Task 7 Step 3 references "the file's existing format" — acceptable since it mirrors an established ledger whose row shape must match neighbors; the action (add a solid `agent_rules` row) is explicit.

**Type/name consistency** — method names are consistent across tasks: `pick_agent_file`, `with_import_block`, `conflict_warnings`, `agent_file`, `scan_files`, `write_agent_rules`, `seed_house_rules`, `ensure_import`, `report_conflicts`, `print_summary`, `print_agent_rules_nudge`. Constants `MARKER`, `IMPORT_BLOCK`, `CONFLICT_PATTERNS`, `AGENT_FILE_CANDIDATES` are defined once (Tasks 1–3) and reused.

**Open verification (from the design doc):** confirm the host agent tool resolves an `@`-import *inside* an imported file (`agent-rules.md` → `house-rules.md`). If it does not in practice, a later change can list both files in `IMPORT_BLOCK`. Not a blocker for this plan.
