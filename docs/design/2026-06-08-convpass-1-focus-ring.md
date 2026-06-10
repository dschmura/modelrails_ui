# Convention Pass · Plan 1 — Focus-ring utility + outline sweep (B5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the inconsistent per-component focus *ring* (`focus:ring-*` / `focus-visible:ring-*`, some on `focus:` so they flash on mouse-click) with ONE AAA-correct focus *outline* convention — a single `focus-ring` utility (`focus-visible` offset outline) referenced everywhere across the gem's proven components AND the app's `.btn-*`/`.form-field` CSS layer.

**Architecture:** Two repos. **App** (`modelrails_base`): add a `focus-ring` `@utility` in `app/assets/tailwind/application.css` (the one shared foundation artifact) and sweep the `.btn-*`/`.form-field` CSS layer to it. **Gem** (`modelrails_ui`, branch `convpass/focus-ring` off `modelrails/harden`): sweep the ~21 *proven* component templates from inline `ring` focus to the `focus-ring` utility (parallel-safe — disjoint per-component files). Re-vendor + prove AAA in CI. This is ruling **B5** of `docs/design/2026-06-08-converged-conventions.md`; it also establishes the `focus-ring` artifact that Plans 2 (button) + 3 (form) consume.

**Tech Stack:** TailwindCSS 4 (`@utility`, `@theme inline`, OKLCH AAA tokens), ViewComponent 4, RSpec + Capybara + Playwright + axe-core (CI-only wcag2aaa 7:1 + forced-colors).

**Spec contract:** converged-conventions §B5 + the focus landmine (§C7): `ring` is a `box-shadow` — clipped by `overflow:hidden` ancestors (the dropdown PANEL is `overflow-hidden`) and invisible in forced-colors/Windows-High-Contrast (`box-shadow:none`) → a 2.4.7 failure. `outline` is OS-drawn, survives both, offset gives non-color distinction. **Exception (keep, do NOT touch):** menu/overlay items that use a full-surface `focus-visible:bg-surface-sunken` highlight — that's a *stronger* indicator inside `overflow:hidden`, sanctioned by B5.

**Toolchain:** Gem — `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec …` (render `-Itest/render`). App — `mise exec -- bundle exec …`.

---

## File Structure

**App (`modelrails_base`):**
- `app/assets/tailwind/application.css` — ADD `@utility focus-ring`; sweep `.btn-primary`/`.btn-secondary`/`.btn-danger`/`.btn-text*`/`.form-field`/the `.tabs`-host rule from `focus:ring`/`focus-visible:ring` → `@apply focus-ring`.

**Gem (`modelrails_ui`, branch `convpass/focus-ring`):** sweep the focus classes in the **proven, ring-bearing** component templates (the fan-out — disjoint files, parallel-safe):
`button, badge, breadcrumb, checkbox, data_table, dialog, alert_dialog, drawer, sheet, floating_label, input, number_input, radio_group, range, rating_input, search_input, select, switch, tabs, textarea, toggle` (21).
(Experimental components — accordion/calendar/combobox/etc. — are NOT in scope; they get the convention when hardened. Menu/overlay item highlights are the sanctioned exception — untouched.)

---

## The recipe (applied per file in Tasks 3a–3u and Task 2)

**Replace** any of these focus fragments:
- `focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-interactive-focus`
- `focus:outline-none focus:ring-2 focus:ring-interactive-focus`
- `focus:ring-2 focus:ring-offset-2 focus:ring-interactive-focus` / `focus:ring-interactive-focus`
- `focus:ring-danger`
- `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-interactive-focus`
- `focus-visible:ring-1 focus-visible:ring-interactive-focus`
- `focus-visible:ring-2` (+ any trailing `focus-visible:ring-{color}`)

**With** the single utility token: **`focus-ring`** (a CSS class — it carries the `:focus-visible` outline internally; no `focus-visible:` prefix needed at the call site).

**Rules:**
- The focus indicator is **uniform** (`--color-interactive-focus`) regardless of the control's tone — drop per-tone focus colors (`ring-danger` → `focus-ring`). A uniform high-contrast focus is AAA-correct and simpler (the spec endorses one focus token).
- **Do NOT touch** `focus-visible:bg-surface-sunken` highlights (menu/overlay items — the sanctioned exception).
- Keep any non-focus `ring`/`outline` (e.g. the input *invalid* state's `ring-2 ring-danger` that conveys error, not focus — leave it; it's a state indicator, not a focus ring).
- Leave `outline-none`/`outline` base resets alone unless they were paired with a `ring` focus (then the `focus-ring` utility replaces the whole focus expression).

---

## Task 1: The `focus-ring` utility (app — the shared foundation)

**Files:** Modify `/Users/dschmura/Documents/code/modelrails_base/app/assets/tailwind/application.css`

- [ ] **Step 1: Add the utility** — in `application.css`, inside the existing `@layer utilities { … }` block (currently holds `.page-container`, ~line 91), add:

```css
  /* AAA focus indicator (converged-conventions B5): an OFFSET OUTLINE, not a ring.
     outline is OS-drawn → survives overflow:hidden clipping AND forced-colors/High-Contrast
     (box-shadow rings vanish in both → WCAG 2.4.7 fail). Uniform --color-interactive-focus
     regardless of control tone. Apply as `focus-ring` on any focusable control. */
  .focus-ring:focus-visible {
    outline: 2px solid var(--color-interactive-focus);
    outline-offset: 2px;
  }
```
(`--color-interactive-focus` is a real `@theme inline` token resolving to `--primary-800` light / `--primary-300` dark — already CI-contrast-verified. Placed in `@layer utilities` so a per-instance `class:` can still override.)

- [ ] **Step 2: Verify it compiles + the rule is emitted**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails tailwindcss:build 2>&1 | tail -3
grep -o "\.focus-ring:focus-visible" app/assets/builds/tailwind.css | head -1 && echo "focus-ring rule emitted"
grep -A2 "\.focus-ring:focus-visible" app/assets/builds/tailwind.css | grep -o "outline: 2px solid" | head -1 && echo "outline value present"
```
Expected: build exits 0; `focus-ring rule emitted`; `outline value present`. (Positive control per the repo's "grep the value not the escaped selector" rule.)

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git checkout main && git pull --ff-only
git checkout -b convpass/focus-ring
git add app/assets/tailwind/application.css
git commit -m "feat(ui): add focus-ring utility (AAA offset outline, converged-conventions B5)"
```

---

## Task 2: Sweep the app `.btn-*` / `.form-field` CSS layer

**Files:** Modify `app/assets/tailwind/application.css` (the `@layer components` block, ~lines 99–200)

- [ ] **Step 1: Replace the focus fragments in the component layer.** In `application.css`, change each rule's focus expression to `@apply focus-ring`:
  - `.btn-text` (~line 110): `@apply focus-visible:outline-none focus-visible:ring-2;` → `@apply focus-ring;`
  - `.btn-text-danger` (~line 116): drop `focus-visible:ring-danger` (keep `text-danger`) → the base `.btn-text`'s `focus-ring` now covers focus. Line becomes `@apply text-danger;`
  - `.btn-text-interactive` (~line 120): drop `focus-visible:ring-interactive-focus` (keep `text-interactive`) → `@apply text-interactive;`
  - `.btn-primary` (~line 133): `@apply focus:outline-none focus:ring-2 focus:ring-offset-2;` + `@apply focus:ring-interactive-focus;` → replace BOTH with `@apply focus-ring;`
  - `.btn-secondary` (~line 141): same as primary → `@apply focus-ring;`
  - `.btn-danger` (~line 149): `@apply focus:outline-none focus:ring-2 focus:ring-offset-2;` + `@apply focus:ring-danger;` → `@apply focus-ring;`
  - The `.tabs`-ish trigger rule (~line 159): `@apply focus:outline-none focus:ring-2 focus:ring-interactive-focus;` → `@apply focus-ring;`
  - `.form-field` (~line 166): `… focus:outline-none focus:ring-2 …` (line 166) + `focus:ring-interactive-focus` (line 167) → replace the focus bits with `@apply focus-ring;` (keep the `focus:outline-none`? NO — `focus-ring` uses `:focus-visible` + outline; remove the `focus:ring-2`/`focus:ring-interactive-focus`, add `@apply focus-ring`. Leave the invalid-state `ring-2 ring-danger` on line 171 ALONE — that's an error indicator, not focus.)
  - The `.tabs`-trigger app rule (~line 197): `@apply focus-visible:ring-1 focus-visible:ring-interactive-focus;` → `@apply focus-ring;`
  - **Do NOT change** line 171 (`ring-2 ring-danger bg-danger-surface` — the form-field INVALID state; that ring conveys error, not focus) or the biscuit-btn block (lines 315–322 — third-party, already an offset outline).

- [ ] **Step 2: Verify build + no stray ring-focus in the compiled component layer**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails tailwindcss:build 2>&1 | tail -3
# the .btn-* rules now carry the outline (via focus-ring), not a box-shadow ring:
grep -c "outline: 2px solid var(--color-interactive-focus)" app/assets/builds/tailwind.css
# sanity: the invalid-state danger ring (NOT focus) is still present:
grep -c "ring-danger\|--tw-ring" app/assets/builds/tailwind.css | head -1
```
Expected: build exits 0; the outline rule count rises (more elements now share it); the invalid-state ring still exists (we intentionally kept it). (Authoritative AAA + no-mouse-flash check is the app 0b/CI in Task 4 — a focus *outline* on `:focus-visible` won't show on mouse-click.)

- [ ] **Step 3: Commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
git add app/assets/tailwind/application.css
git commit -m "refactor(ui): sweep .btn-*/.form-field focus ring → focus-ring outline (B5)"
```

---

## Task 3: Sweep the gem proven components (the parallel fan-out)

**Files (gem, branch `convpass/focus-ring` off `modelrails/harden`):** the 21 proven templates listed in File Structure. **These are disjoint files — Tasks 3a–3u can run in parallel** (one component each). Each follows the same shape.

> **Per-component procedure (the recipe + verify), shown for `input` — apply identically to each of the 21:**

- [ ] **Step 1: Apply the recipe** to `lib/generators/modelrails_ui/add/templates/<component>/<component>_component.rb.tt`:
  - Find every focus fragment matching the recipe list above; replace the whole focus expression with the class `focus-ring`.
  - Example (`input_component.rb.tt`): `focus:outline-none focus:ring-2 focus:ring-interactive-focus` → `focus-ring`. (If a danger/invalid focus color appears, e.g. `focus-visible:ring-danger`, replace with `focus-ring` too — uniform focus.)
  - Leave `focus-visible:bg-surface-sunken` highlights and non-focus state rings (invalid `ring-danger`) untouched.

- [ ] **Step 2: Confirm the component no longer ring-focuses + still has a focus indicator**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
# no focus ring left (should be 0); focus-ring utility present (should be ≥1):
grep -c "focus:ring\|focus-visible:ring" lib/generators/modelrails_ui/add/templates/<component>/<component>_component.rb.tt
grep -c "focus-ring" lib/generators/modelrails_ui/add/templates/<component>/<component>_component.rb.tt
```
Expected: first grep `0` (no remaining focus ring — UNLESS the only ring was the invalid-state `ring-danger`, which is NOT a focus ring and stays; in that case 0 *focus*-rings), second grep ≥1.

- [ ] **Step 3: Re-run the component's 0a render test** (most don't assert focus classes, so it stays green; if one DOES assert `ring-interactive-focus`, update that assertion to `focus-ring`):

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec ruby -Itest/render test/render/<component>_render_test.rb 2>&1 | tail -3
```
Expected: green (or update the one focus assertion, then green). (Not every component has a render test yet — if none exists, skip; the app 0b is the gate.)

- [ ] **Step 4 (after ALL 21 swept): full gem suite + rubocop + commit**

```bash
cd /Users/dschmura/Documents/code/modelrails_ui
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test 2>&1 | tail -3
PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rubocop -A lib/generators/modelrails_ui/add/templates/ 2>&1 | tail -2
git add lib/generators/modelrails_ui/add/templates/
git commit -m "refactor(ui): sweep proven components focus ring → focus-ring outline (B5, 21 components)"
```
Expected: full `rake test` 0 failures; rubocop clean. (Parallel note: if the fan-out runs as one-agent-per-component, each does Steps 1–3 on its file; a final coordinator does Step 4's suite + the single commit.)

---

## Task 4: Re-vendor + verify (the AAA gate)

**Files (app, `convpass/focus-ring` branch):** re-vendor the swept components; the app's existing 0b system specs are the AAA gate.

- [ ] **Step 1: Temp-pin + re-vendor the swept components**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
# temp-pin Gemfile modelrails_ui → branch "convpass/focus-ring" + local override (per the vendoring pattern)
mise exec -- bundle config set --local local.modelrails_ui /Users/dschmura/Documents/code/modelrails_ui
mise exec -- bundle install 2>&1 | tail -2
# re-generate the swept proven components that ARE vendored in the app (button, input, textarea,
# file_input, select, dialog, alert, badge, tabs, breadcrumb, switch, … — whichever app/components/ui/* exist):
for c in $(ls app/components/ui/ | sed 's/_component.rb//;s/.html.erb//' | sort -u); do
  mise exec -- bin/rails g modelrails_ui:add "$c" --force 2>/dev/null
done
mise exec -- bundle exec rubocop -A app/components/ui/ 2>&1 | tail -2
```
Expected: vendored `.rb` re-generated; rubocop clean. (Only components the app actually vendors are regenerated; the focus-ring class flows through.)

- [ ] **Step 2: Build CSS + full app suite (the 0b/AAA proof)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bin/rails tailwindcss:build 2>&1 | tail -2
mise exec -- bundle exec rspec 2>&1 | grep -E "^[0-9]+ examples|failures" | tail -2
```
Expected: build 0; **full suite 0 failures**. The existing per-component 0b axe specs re-prove AAA on the outline focus in both themes. (Local axe = AA; the authoritative AAA 7:1 + the outline's forced-colors survival are confirmed by the CI `test` job after push.)

- [ ] **Step 3: Lint + clean tree + commit (NO push — handoff gate)**

```bash
cd /Users/dschmura/Documents/code/modelrails_base
mise exec -- bundle exec rubocop app/components/ui/ 2>&1 | tail -2
mise exec -- bundle exec rake erb:check > /dev/null 2>&1 && echo "erb:check 0" || echo "erb:check NONZERO"
git add app/components/ui/ Gemfile Gemfile.lock app/assets/builds/tailwind.css 2>/dev/null
git commit -m "chore(ui): re-vendor focus-ring sweep + rebuild CSS"
git log --oneline main..HEAD
cd /Users/dschmura/Documents/code/modelrails_ui && git log --oneline modelrails/harden..HEAD
```

- [ ] **Step 4: STOP — human handoff.** Report: focus convention swept (gem 21 proven components + app `.btn-*`/`.form-field` + the `focus-ring` utility), full app suite green, ring→outline everywhere except the sanctioned menu-highlight exception. Browser-review focus on a few surfaces (Tab through a form, a button, the members table) in BOTH themes + (if possible) forced-colors/High-Contrast — the outline must show on keyboard focus, NOT on mouse-click, and survive inside `overflow:hidden` panels. On OK: push gem `convpass/focus-ring` → PR into `modelrails/harden` → careful-merge (REST `-f sha=`) → re-pin app → push → app PR → after the AAA `test` job is green + merge, the `focus-ring` utility is the shared artifact Plans 2 (button) + 3 (form) build on.

---

## Self-Review

**1. Spec coverage (B5 → tasks):** uniform offset-outline focus token (`focus-ring` utility, Task 1) ✅; sweep gem proven components (Task 3, 21 files) ✅; sweep app `.btn-*`/`.form-field` layer (Task 2) ✅; menu-highlight exception preserved (recipe rule + not-in-scope list) ✅; `ring`/box-shadow retired as focus (Tasks 2–3; the invalid-state ring kept as a non-focus state indicator) ✅; forced-colors/overflow survival = the *reason* (outline), verified by browser/CI (Task 4 Step 4) ✅; grep-the-compiled-value guards (Tasks 1–2) ✅.

**2. Placeholder scan:** No TBD/TODO. The per-component recipe (Task 3) is a concrete transformation + verify applied to a named 21-file inventory — DRY, not a placeholder (writing 21 identical blocks would violate DRY). The "if a render test asserts the focus class, update it" branch is a known conditional with the concrete fix, not a placeholder.

**3. Type/name consistency:** `focus-ring` is the single utility name across Task 1 (definition), Task 2 (`.btn-*`/`.form-field`), Task 3 (gem components); `--color-interactive-focus` is the real token; the invalid-state `ring-danger` is consistently preserved (not a focus ring) in Tasks 2 + 3.

**Flagged for CI/browser:** forced-colors/Windows-High-Contrast survival of the outline (axe doesn't fully automate this — manual HCM check in Task 4 Step 4) and the offset-outline contrast on every surface (AAA `test` job). The `focus-ring` utility lives in the APP's CSS — the gem components reference the class but the app owns the definition (correct: tokens/CSS are app-side, components are gem-side; downstream consumers ship their own `focus-ring`, documented in Plan 4's agent-rules update).
```
