# Media Band Hardening — Design

Date: 2026-06-09
Branch: `harden/media` (off `modelrails/harden`)
Program: component-hardening (see `docs/design/2026-06-03-component-hardening-program-design.md`)

## Context

The hardening program has taken 55 components to **proven** (render test 0a + real app
browser-axe AAA proof 0b). The display tier is complete; navigation is complete. This band
hardens the **media** tier: `audio`, `video`, `gallery`, `carousel`, `embed` — 5 components,
none currently tracked in `COMPONENT_STATUS.md`, none with render tests. Target: **55 → 60 proven**.

The per-component **groove** is unchanged and not re-litigated here:

1. Harden the template to the 10-point DoD (fail-loud guard, AAA semantic tokens, correct ARIA,
   focus + 44px targets, disabled/invalid, i18n, doc-comment, slot API).
2. `test/render/<name>_render_test.rb` (0a) — asserts tag + ARIA + AAA token classes + a fail-loud `assert_raises`.
3. Template-backed Lookbook preview.
4. App: vendor the component (+ controller), preview, and a **0b preview-host axe spec**
   (`visit /rails/view_components/ui/<name>_component/<scenario>`, scope axe by `let(:scope)`,
   `axe_clean_in_both_themes?` with **no contrast exclude**).
5. `COMPONENT_STATUS.md` row.

Worktree-parallel within the band → **one bundled gem PR** + **one app PR** → cross-sibling
review before merge. AAA contrast is proven in **CI only** (the wcag2aaa 7:1 hook is `if ENV["CI"]`;
a local 0b runs axe at AA 4.5:1 and cannot adjudicate AAA contrast).

## Locked decisions

| # | Decision | Choice | Rationale |
| --- | --- | --- | --- |
| D1 | Gallery lightbox | **Reuse the Wave-4 native `<dialog>` + shared `modal` controller** via `EXTRA_STIMULUS`; `gallery` becomes a thin coordinator; trigger → real `<button>` | A lightbox *is* a modal dialog. Reusing the proven focus-trap/escape/restore avoids reinventing dialog a11y in a 2nd place — the DRY hazard the program already flagged. Wathan (compose on the primitive), Schoger (delegate mechanics, polish the visual), and Fried (native `<dialog>`, minimal JS) all converge here. |
| D2 | Carousel autoplay | **Make it WCAG 2.2.2 compliant** | Add a pause/play toggle (when `autoplay > 0`) + pause-on-hover/focus + disable autoplay under `prefers-reduced-motion`. Keeps the feature, satisfies 2.2.2. |
| D3 | Carousel ARIA | **Pragmatic APG "basic" pattern** | `role=group`/`aria-roledescription=carousel`; per-slide `aria-roledescription=slide` + `aria-label "n of m"`; `aria-current` active dot; i18n labels; 44px hit areas. Tabbed `tablist` variant is only for genuinely tab-like slides; APG's button-based basic is the right default. |
| D4 | embed `bg-black` | **Keep, with a one-line comment** | The dark wrapper is a media *letterbox backdrop*, not a text-contrast surface. Inventing a semantic token would be fabrication — same reasoning that correctly left `avatar`'s `bg-hue-initials` alone. |

## Per-component plan (the real fixes)

### audio — light (formalize + fail-loud)

Native `<audio controls>`; browser-native controls are already accessible. Fixes:

- **Fail-loud `coerce_preload`** — currently any symbol passes through to the `preload` attribute.
  Restrict to `:auto | :metadata | :none`, raise in dev on anything else (program's silent-fallback → fail-loud rule).
- Use `cn(@extra_class)` for class composition (consistency; no BASE classes today).
- Doc-comment already good. Mostly formalize-only (like `kbd`/`image`/`figure`).
- 0a: asserts `<audio controls preload=metadata>`, `<source>` slot renders, fail-loud raise on bad preload.
- 0b: preview-host scenarios (with-controls, multi-source). Native controls — axe checks no orphan labels.

### video — light–medium (fail-loud track kind + verify captions)

Native `<video>` with `<source>` and `<track>` slots — `<track>` caption support is good a11y already. Fixes:

- **`TrackComponent` fail-loud `coerce_kind`** — currently `KINDS.include?(kind) ? kind : :subtitles`
  silently swallows a typo. Raise in dev instead (the canonical Wave-1 defect).
- Keep `muted if @muted || @autoplay` (correct — autoplay requires muted).
- Doc-comment notes captions are the caller's a11y responsibility.
- 0a: `<video>` attrs, `<source>`/`<track>` slots, `default` track flag, fail-loud on bad kind.
- 0b: preview-host (with-poster, with-captions-track). Verify the `<track>` carries `label`/`srclang`.

### gallery — heavy (lightbox dialog rewrite — D1)

Today: trigger is a non-focusable `<figure>` with `click->gallery#open` (mouse-only, **WCAG 2.1.1**);
`open()` builds a bare `<div>` overlay with **no** `role=dialog`, focus move-in, trap, restore, or close
button (**WCAG 4.1.2 / 2.4.3**). Rework per D1:

- **Trigger → `<button type=button>`** wrapping the thumbnail: focusable, keyboard-operable,
  `aria-label` "Enlarge {alt}" (i18n). Keeps the `cursor-zoom-in` / hover-scale visual.
- **One native `<dialog>`** rendered in the gallery markup (a single `<img>` inside), wired to the
  **shared `modal` controller** via `EXTRA_STIMULUS` (`{source: "dialog/modal_controller.js", name: "modal"}`).
- **`gallery` becomes a thin coordinator** (Stimulus): on a trigger click, set the dialog `<img>`
  `src`/`alt` from the clicked button's params, then delegate `open` to the modal controller
  (same pattern menubar used to reuse the *frozen* menu controller via outlets — no edits to `modal`).
- Lightbox dialog gets `aria-label` (the active image's alt) + a real 44px **close button**.
- **Caption**: `text-white` on `from-black/60` gradient over an arbitrary image is unreliable contrast.
  Move the caption to a `<figcaption>` on a solid tinted surface (semantic token), not text-over-image.
- **`alt` required when `lightbox: true`** (an enlargeable image is not decorative); decorative-only
  galleries can pass `lightbox: false` with `alt: ""`.
- 0a: `<button>` trigger (not `<figure>`), one `<dialog>`, `EXTRA_STIMULUS` wiring asserted.
- **0b asserts OUTCOME** (the program's hardest lesson): after activating a trigger **via keyboard**,
  the `<dialog>` is `open`, focus moved inside it, and Escape closes + restores focus to the trigger.
  Structure-only would pass a broken lightbox.

### carousel — heavy (44px + APG ARIA + 2.2.2 autoplay — D2/D3)

Today: `size-9` (36px) prev/next + `size-2` (8px) dots both fail **2.5.5**; `setInterval` autoplay with
**no pause** fails **2.2.2** and ignores `prefers-reduced-motion`; English-hardcoded labels; no carousel ARIA;
dot active state by color/width alone. Rework:

- **44px hit areas** — prev/next ≥44px; dots keep a small visual dot but carry a ≥44px padded tap target.
- **i18n** — "Previous slide" / "Next slide" / "Go to slide {n}" → locale keys; chevrons `aria-hidden`.
- **APG basic ARIA (D3)** — container `role=group aria-roledescription=carousel` + i18n `aria-label`;
  each slide `role=group aria-roledescription=slide aria-label "{n} of {m}"`; active dot `aria-current=true`.
- **Autoplay compliance (D2)** — controller:
  - render a **pause/play toggle** only when `autoplay > 0` (i18n label, 44px);
  - **pause on hover and focus-within**, resume on leave/blur;
  - **`prefers-reduced-motion: reduce` disables autoplay** at connect (no timer started);
  - the slide track is `aria-live=off` while rotating; **pausing flips it to `aria-live=polite`** so the
    "{n} of {m}" updates are announced only when motion is stopped — one control, both 2.2.2 + meaningful live updates.
- 0a: structure + ARIA roles/labels + pause button present when autoplay set + fail-loud on bad input as applicable.
- **0b asserts OUTCOME** — next/prev/goTo actually translate the track (computed `transform`), `aria-current`
  follows the active dot, and toggling pause flips `aria-live`. (Mirrors the data_table sort-reorder lesson:
  assert the DOM/style outcome, not just that the handler is wired. Check the preview fixtures aren't pre-arranged
  to hide the behavior.)

### embed — light–medium (i18n + comment)

iframe-based providers already carry `title`, `loading=lazy`, per-provider `sandbox`. Fixes:

- **i18n `unsupported_msg`** ("Unsupported embed type: {type}") → locale key (keep `text-danger` — AAA signal token).
- **i18n the iframe `default_title`** provider names (accessible name for the `<iframe>`); allow caller `title:` override (already supported).
- **`bg-black` (D4)** — keep; add a one-line comment marking it an intentional letterbox backdrop.
- Widget providers (x/telegram) inject third-party scripts via the existing controller — out of a11y scope; sandbox posture unchanged.
- 0a: provider detection, `<iframe title>` present + non-blank, aspect/height wrapper, unsupported message path.
- 0b: preview-host (youtube/vimeo/maps). axe verifies every `<iframe>` has an accessible name.

## Orchestration & sequencing

- **Gem side** — worktree-parallel under `/private/tmp/mrui-wt/` (one worktree per component; same-clone
  parallel branches collide). Bundle the 5 into `harden/media` → **one gem PR**.
- **Light first to set the pattern, heavy second**: `audio`/`video`/`embed` are near-mechanical;
  `gallery` + `carousel` carry the behavioral risk and the outcome-asserting 0b specs — review those last and hardest.
- **App side** — single working tree, sequential vendor of all 5 (+ `gallery`/`carousel`/`embed` controllers,
  auto-registered) → **one app PR**. Create the app branch **before** any app fan-out ([[create-branch-before-fanout]] lesson).
- **Cross-sibling review** before merge: gallery's `<button>`-trigger and carousel's attr-merge order are the
  attr-clobber / keyboard-trigger patterns that recur — read the rendered DOM, don't reason about it.

## App adoption & 0b proof

Consistent with the display/nav bands: the **preview-host 0b spec is the primary AAA gate** — a real
production page is not required for these media primitives (modelrails_base has no natural home for an
audio player or a third-party embed). Each component is proven by: vendored component + template-backed
preview + a 0b spec visiting `/rails/view_components/ui/<name>_component/<scenario>` that asserts axe-clean
in both themes **and** (for gallery/carousel) the behavioral outcome.

## Definition of Done (per component)

Renders correct semantics · AAA semantic tokens only · correct ARIA · fail-loud guard where inputs are
constrained · focus visible + ≥44px interactive targets · disabled/invalid handled where applicable ·
i18n (no hardcoded user-facing strings) · doc-comment · slot API · template-backed Lookbook preview ·
0a render test green · app 0b axe spec green in CI (AAA) · `COMPONENT_STATUS.md` row flipped to **proven**
only after app CI is green.

## Risks & known gotchas (carried from prior bands)

- **`let(:scope)`, never `SCOPE = …` in a `describe` block** — a block-assigned constant leaks to top-level
  `::SCOPE`; ≥2 scoped 0b specs loaded together clobber each other (passes alone, fails together). Use `let`.
- **AAA is CI-only** — don't claim AAA from a local 0b; push and read CI. Don't pre-guess token failures
  (success/warning/muted all pass AAA in CI here; `text-muted == text-body`).
- **ERB comment footgun** — `<%= ui :x # comment %>` 500s; hoist to `<%# %>`. Keep a preview-smoke gate.
- **Shared controller via `EXTRA_STIMULUS`, never a copy** — gallery references `dialog/modal_controller.js`;
  do not colocate a duplicate (the alert_dialog stale-source bug).
- **File-unique top-level constants in specs** (or `let`) — bare constants in `RSpec.describe` collide in the
  single-process suite.
- **Branch in BOTH repos before fan-out.** Check `git status` before finishing (stray scaffolding).
- **Outcome-asserting 0b for gallery/carousel** — the data_table lesson: 0a + careful review both miss
  behavioral bugs; only the real-browser spec asserting computed style / focus / DOM state catches them.
  Verify preview fixtures aren't pre-arranged to mask the behavior under test.

## Ledger impact

`audio`, `video`, `gallery`, `carousel`, `embed` → new `proven` rows after app CI green. **58 → 63 proven.**
