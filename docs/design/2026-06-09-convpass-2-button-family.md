# Convention Pass — Plan 2: Button Family (B2 two-axis + A8 SIZES)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `button`, `badge`, and `alert` from a flat one-axis `variant:` enum to the converged-conventions **B2** two-axis `variant:` (shape) × `tone:` (signal) API — with a non-breaking deprecation shim so every existing call site keeps working — and restore the **A8** `:icon` size on button (44×44 AAA).

**Architecture:** Each component keeps its exact current visual output; we re-express the existing flat values as `(variant, tone)` cells of a 2-D matrix, accept the new axes directly, and translate old flat values through a `coerce` shim. We ship **only the (variant,tone) cells that already exist** (each is an AAA-proven treatment with a 0b row); unproven cells **raise in dev / fall back in prod** (the AAA combo-guard — a new fill is an untested `text-on-*` pairing). Alert is a 1-axis `variant→tone` rename (it has no shape axis). Same cross-repo model as Plan 1: gem templates + app generated copies; **button** alone resolves to the app's `.btn-*` CSS layer (so its lookup table differs gem-vs-app), while **badge/alert** are self-contained raw-utility in both.

**Tech Stack:** Ruby ViewComponents (`.rb.tt` gem templates → generated `app/components/ui/*.rb`), TailwindCSS v4, ViewComponent::TestCase render tests (0a), Playwright/axe preview-host system specs (0b, AAA is CI-only). Gem toolchain: `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render …`. App toolchain: `mise exec -- bundle exec …`.

---

## Design reference (the matrices — single source of truth for the tasks below)

### Button

New API: `variant: :solid | :outline | :text` (default `:solid`) × `tone: :primary | :neutral | :danger` (default `:primary`). `size: :default | :icon`.

**Proven cells (the 5 existing treatments) — gem (raw utilities):**

| variant | tone    | gem classes |
| ------- | ------- | ----------- |
| solid   | primary | `#{FILLED} bg-interactive hover:bg-interactive-hover text-text-on-interactive` |
| solid   | danger  | `#{FILLED} bg-danger hover:bg-danger/90 text-text-on-interactive` |
| outline | neutral | `#{FILLED} border border-border text-text-body hover:bg-surface-sunken` |
| text    | primary | `#{TEXT} text-interactive` |
| text    | danger  | `#{TEXT} text-danger` |

**Same 5 cells — app (`.btn-*` layer):**

| variant | tone    | app classes |
| ------- | ------- | ----------- |
| solid   | primary | `btn-primary` |
| solid   | danger  | `btn-danger` |
| outline | neutral | `btn-secondary` |
| text    | primary | `btn-touch-target btn-text btn-text-interactive` |
| text    | danger  | `btn-touch-target btn-text btn-text-danger` |

**Unproven cells** (`[:solid,:neutral]`, `[:outline,:primary]`, `[:outline,:danger]`, `[:text,:neutral]`): **raise** (dev) / fall back to `[:solid,:primary]` (prod). Each becomes shippable only by adding its matrix entry **and** a 0b axe row.

**Deprecation shim (old flat `variant:` → `[variant, tone]`):**

| old value          | → variant | → tone   |
| ------------------ | --------- | -------- |
| `primary`          | solid     | primary  |
| `secondary`        | outline   | neutral  |
| `danger`           | solid     | danger   |
| `destructive`      | solid     | danger   |
| `text`             | text      | primary  |
| `text_interactive` | text      | primary  |
| `text_danger`      | text      | danger   |

**SIZES (A8):** `{ default: "", icon: "px-0 min-w-[var(--form-input-height)]" }` — `:icon` makes a square 44×44 button (the `min-h` is already in `FILLED`/`TEXT`; add `min-w` + drop horizontal padding). Gem and app identical. `:icon` MUST keep `min-w/min-h-[var(--form-input-height)]` (WCAG 2.5.5).

### Badge

New API: `variant: :solid | :soft | :outline | :ghost | :link` (default `:solid`) × `tone: :primary | :neutral | :info | :success | :warning | :danger` (default `:primary`).

**Proven cells (the 9 existing variants) — identical gem + app (raw utilities):**

| variant | tone    | classes (the current value) |
| ------- | ------- | --------------------------- |
| solid   | primary | `bg-interactive text-text-on-interactive [a&]:hover:bg-interactive-hover` |
| soft    | primary | `bg-interactive-subtle text-interactive [a&]:hover:bg-interactive-subtle` |
| soft    | info    | `bg-info-surface text-info border-info-border [a&]:hover:bg-info-hover` |
| soft    | success | `bg-success-surface text-success border-success-border [a&]:hover:bg-success-hover` |
| soft    | warning | `bg-warning-surface text-warning border-warning-border [a&]:hover:bg-warning-hover` |
| soft    | danger  | `bg-danger-surface text-danger border-danger-border [a&]:hover:bg-danger-hover` |
| outline | neutral | `border-border text-text-heading [a&]:hover:bg-surface-sunken [a&]:hover:text-text-heading` |
| ghost   | neutral | `[a&]:hover:bg-surface-sunken [a&]:hover:text-text-heading` |
| link    | primary | `text-interactive underline-offset-4 [a&]:hover:underline` |

**Deprecation shim (old flat → `[variant, tone]`):** `default`→`[solid,primary]`, `secondary`→`[soft,primary]`, `info`→`[soft,info]`, `success`→`[soft,success]`, `warning`→`[soft,warning]`, `danger`→`[soft,danger]`, `destructive`→`[soft,danger]`, `outline`→`[outline,neutral]`, `ghost`→`[ghost,neutral]`, `link`→`[link,primary]`. All other cells raise/fall back to `[solid,primary]`.

> ⚠ Note: old badge `danger` is the **soft/tinted** chip (`bg-danger-surface`), so `destructive`/`danger` → `[soft,danger]` (NOT solid). This differs from button, where `danger` is a solid fill. Per-component shim tables — do not share one table.

### Alert (1-axis rename)

New API: `tone: :neutral | :info | :success | :warning | :danger` (default `:neutral`). **No shape axis** — an alert is always a filled banner. Keep `variant:` accepted as a **deprecated alias** for `tone:` (`default`→`neutral`, others 1:1, `destructive`→`danger`). The `VARIANTS` hash keys rename `default`→`neutral`; `ROLES`/`LIVE` keys rename in lockstep.

---

## Shared helper: the `variant×tone` coerce pattern

All three components grow a `coerce_axes(variant, tone)` (button/badge) or `coerce_tone(tone, variant)` (alert) private method that: (1) if the caller passed a **legacy flat value** in `variant:` (detected by membership in the shim table), translate it to `[variant, tone]` and warn-free-return; (2) else use the passed `variant`/`tone`; (3) look up the cell in the COMBOS matrix; (4) unknown cell → raise `ArgumentError` in dev/test (listing the proven cells), fall back to the default cell in prod. Reuse the existing `defined?(Rails) && Rails.respond_to?(:env) && Rails.env.production?` guard verbatim (it's correct for the gem's Rails-less render tests).

**Back-compat contract (the invariant every task protects):** every currently-valid call — `variant: :primary`, `:secondary`, `:danger`, `:destructive`, `:text`, `:text_interactive`, `:text_danger` (button); the 9 badge values + `:destructive`; the 5 alert values + `:destructive` — must render **byte-identical classes** before and after. The render tests lock this.

---

## Task 1: Button — gem template (two-axis API + shim + `:icon`)

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/button/button_component.rb.tt`
- Test: `test/render/button_render_test.rb`

- [ ] **Step 1 — Write failing back-compat + new-axis render tests.** Add to `button_render_test.rb`: (a) for each legacy value in the shim table, assert the rendered class string equals the current output (lock byte-identical); (b) `variant: :solid, tone: :primary` renders the primary classes; `variant: :text, tone: :danger` renders the text-danger classes; (c) `variant: :solid, tone: :neutral` (unproven) raises `ArgumentError`; (d) `size: :icon` adds `min-w-[var(--form-input-height)]` and `px-0`; (e) `variant: :outline, tone: :neutral` renders the secondary classes.

```ruby
# Back-compat: every legacy flat value still renders its exact classes.
{
  primary: "bg-interactive", secondary: "border-border", danger: "bg-danger",
  text: "text-interactive", text_interactive: "text-interactive", text_danger: "text-danger",
  destructive: "bg-danger"
}.each do |legacy, marker|
  test "legacy variant #{legacy} still renders" do
    render_inline(UI::ButtonComponent.new("Go", variant: legacy))
    assert_selector "button.#{marker.tr(' ', '.')}"
  end
end

test "two-axis solid/primary matches legacy primary" do
  render_inline(UI::ButtonComponent.new("Go", variant: :solid, tone: :primary))
  assert_selector "button.bg-interactive.text-text-on-interactive"
end

test "unproven cell raises in dev" do
  assert_raises(ArgumentError) { render_inline(UI::ButtonComponent.new("Go", variant: :solid, tone: :neutral)) }
end

test "size icon is a 44px square" do
  render_inline(UI::ButtonComponent.new(variant: :solid, tone: :primary, size: :icon))
  assert_selector 'button.px-0.min-w-\\[var\\(--form-input-height\\)\\]'
end
```

- [ ] **Step 2 — Run, verify red.** `PATH=… bundle exec ruby -Itest/render test/render/button_render_test.rb` → fails (new axes unimplemented).

- [ ] **Step 3 — Implement the two-axis API in `button_component.rb.tt`.** Replace the flat `VARIANTS`/`VARIANT_ALIASES`/`coerce_variant` with: `FILLED`/`TEXT` bases unchanged; a `COMBOS` matrix keyed `[variant, tone]` (the 5 gem cells above); `SHIM` (legacy flat → `[variant, tone]`); `SIZES = { default: "", icon: "px-0 min-w-[var(--form-input-height)]" }`; `initialize(label = nil, variant: :solid, tone: :primary, size: :default, href: nil, **html_attrs)`; a `coerce_axes` that applies the shim when `variant` is a legacy key, then looks up `COMBOS.fetch([@variant, @tone])` with the dev-raise/prod-fallback guard; `component_classes = cn(COMBOS.fetch([@variant, @tone], COMBOS[[:solid, :primary]]), SIZES.fetch(@size, ""), @extra_class)`. Keep the doc-comment accurate (list the axes + the proven cells + the shim).

- [ ] **Step 4 — Run, verify green.** Same command → all pass.

- [ ] **Step 5 — Commit.** `git commit -m "feat(ui): button two-axis variant×tone API + shim + :icon size (B2/A8)"`

## Task 2: Badge — gem template (two-axis API + shim)

**Files:** Modify `…/badge/badge_component.rb.tt`; Test `test/render/badge_render_test.rb`.

- [ ] **Step 1 — Failing tests:** back-compat for all 9 legacy values + `destructive` (byte-identical classes); `variant: :soft, tone: :info` renders the info chip; `variant: :solid, tone: :danger` (unproven for badge) raises; `variant: :ghost, tone: :neutral` renders ghost.
- [ ] **Step 2 — Verify red.**
- [ ] **Step 3 — Implement:** `BASE` unchanged; `COMBOS` matrix (the 9 badge cells); per-component `SHIM` (the badge table — note `danger`/`destructive`→`[soft,danger]`); `initialize(label = nil, variant: :solid, tone: :primary, href: nil, **html_attrs)`; `coerce_axes` (shim + dev-raise/prod-fallback to `[solid,primary]`); `cn(BASE, COMBOS.fetch([@variant, @tone]), @extra_class)`.
- [ ] **Step 4 — Verify green.**
- [ ] **Step 5 — Commit.** `feat(ui): badge two-axis variant×tone API + shim (B2)`

## Task 3: Alert — gem template (1-axis `variant→tone` rename + alias)

**Files:** Modify `…/alert/alert_component.rb.tt`; Test `test/render/alert_render_test.rb`.

- [ ] **Step 1 — Failing tests:** back-compat for `default`/`info`/`success`/`warning`/`danger`/`destructive` via BOTH `variant:` (deprecated) and `tone:` (new) — same classes + same `role`/`aria-live`; `tone: :neutral` == legacy `variant: :default`.
- [ ] **Step 2 — Verify red.**
- [ ] **Step 3 — Implement:** rename `VARIANTS` keys `default`→`neutral` (and `ROLES`/`LIVE` in lockstep); `initialize(tone: :neutral, variant: nil, title: nil, description: nil, **html_attrs)`; `coerce_tone` maps a legacy `variant:` (incl. `default`→`neutral`, `destructive`→`danger`) onto `tone`, else uses `tone`; dev-raise/prod-fallback to `:neutral`. Update the doc-comment (tone ladder; `variant:` deprecated alias).
- [ ] **Step 4 — Verify green.**
- [ ] **Step 5 — Commit.** `feat(ui): alert tone axis (variant→tone rename + deprecated alias) (B2)`

## Task 4: Gem — previews + full suite + rubocop + 0a coverage

**Files:** `spec/components/previews/ui/{button,badge,alert}_component_preview.rb` (gem-side previews if present) and/or `test/render/*`.

- [ ] **Step 1 — Add new-axis preview examples** (so the AAA combo-guard has 0b rows downstream): button `solid_primary`/`outline_neutral`/`text_danger`/`icon`; badge `soft_info`/`outline_neutral`; alert `tone_warning`. Keep the legacy-named previews (they exercise the shim).
- [ ] **Step 2 — Full gem render suite:** `PATH=… bundle exec rake test` → 0 failures.
- [ ] **Step 3 — Rubocop:** `PATH=… bundle exec rubocop $(git diff --name-only 'test/render/*.rb')` → clean.
- [ ] **Step 4 — Commit** any preview additions. `test(ui): variant×tone preview examples for button/badge/alert`

## Task 5: App re-vendor — surgical, per-component (NOT a blind copy)

**Files:** `app/components/ui/{button,badge,alert}_component.rb` + their specs.

> Re-vendor lesson from Plan 1: app copies have **drift** (rubocop brace-spacing; **button** points at `.btn-*`). Do NOT `cp` the gem `.tt`. Apply the SAME API change but resolve classes per-repo.

- [ ] **Step 1 — Branch** `convpass/button-family` off `main` (app) — created by the orchestrator; agents edit only.
- [ ] **Step 2 — Button (app):** port the two-axis API + shim + `coerce_axes` + `SIZES`, but `COMBOS` uses the **`.btn-*` app table** (the 5 app cells above). The Ruby structure mirrors the gem; only the matrix values differ.
- [ ] **Step 3 — Badge / Alert (app):** these are self-contained raw-utility in both repos — mirror the gem `COMBOS`/`SHIM`/`coerce` verbatim (modulo the app's rubocop brace style; let the app's `rubocop -A` normalize).
- [ ] **Step 4 — Update app component unit specs** to assert the new axes + the shim back-compat (mirror the gem render tests' intent).
- [ ] **Step 5 — Rebuild + diff-verify:** `mise exec -- bin/rails tailwindcss:build`; confirm the app diff is API-only (no unrelated drift); confirm any `.btn-*`/`:icon` classes still compile (probe `min-w-[var(--form-input-height)]`).
- [ ] **Step 6 — Full app suite** `mise exec -- bundle exec rspec` → 0 failures. Commit per logical unit.

## Task 6: 0b AAA proof + ship

- [ ] **Step 1 — Ensure preview-host 0b specs** cover at least one new-axis example per component (the AAA combo-guard's "every shipped cell has a 0b row"). Reuse the alert exemplar 0b shape (visit preview, scope axe by role, `axe_clean_in_both_themes?`, no color-contrast exclude).
- [ ] **Step 2 — Push gem branch `convpass/button-family`** → open gem PR → poll CI green → REST sha-guard careful-merge to `modelrails/harden`.
- [ ] **Step 3 — Push app branch** (Lefthook pre-push full suite) → open app PR → poll CI incl. the **AAA gate** → careful-merge to `main`. (Expect the magic_link flaky may recur → `gh run rerun --failed`.)
- [ ] **Step 4 — COMPONENT_STATUS:** no tier change (button/badge/alert already `proven`); note the API bump in their Notes column if useful.
- [ ] **Step 5 — Cleanup** branches; update memory.

---

## Self-review checklist (run before execution)

1. **Back-compat coverage:** every legacy value (7 button + 10 badge + 6 alert incl. `destructive`) has a byte-identical render test. ✅ (Tasks 1–3 Step 1)
2. **AAA combo-guard:** only the proven cells are in each `COMBOS`; unproven cells raise; each shipped new-axis preview has a 0b row. ✅ (Task 6 Step 1)
3. **Per-component shim tables** (badge `danger`→soft vs button `danger`→solid — do NOT share). ✅ (Design reference notes)
4. **Cross-repo:** button app table = `.btn-*`; badge/alert mirror gem; surgical re-vendor, diff-verified. ✅ (Task 5)
5. **`:icon` keeps 44×44** (`min-w/min-h-[var(--form-input-height)]`). ✅ (Task 1)
6. **No placeholders:** matrices + shim tables are spelled out above; tasks reference them. ✅
