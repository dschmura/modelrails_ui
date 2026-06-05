# Agent-rules generator (`modelrails_ui:agent_rules`) — design

- **Date:** 2026-06-05
- **Status:** Approved (brainstorm complete) — ready for implementation plan
- **Scope:** A new optional generator in `modelrails_ui` that teaches a coding agent to
  defer to the design system, plus a post-install nudge from the `install` generator.

## Problem

`modelrails_ui` ships an AAA, OKLCH-themed ViewComponent library (~81 primitives), a
Lookbook catalog, and an upgrade-via-generator model. What it lacks is the piece that makes
all of that get *used*: nothing tells a coding agent to defer to the system. Left to its own
devices an agent invents ad-hoc utility stacks, reaches for raw hex, and trips project
guardrails it cannot infer (e.g. `text-muted == text-body` here, contrast being a CI-only
verdict, the tinted-chip vs solid-fill signal split).

Builder Methods' **AI Design System** closes this exact gap for React apps by scaffolding a
managed "agent rules" block into `CLAUDE.md`/`AGENTS.md`. Its own *"When to skip it"* guidance
says teams that already have a design system should **borrow the idea** — a reference agents
can read plus agent rules — rather than adopt the skill. This generator is that borrow, on
Hotwire/ViewComponent instead of React. It is **adoption, not a port**: the design system
already exists and is more rigorous; this adds the one missing mechanism.

## Goals

- An **optional**, gem-delivered generator that teaches a coding agent to use `modelrails_ui`.
- **Portable** across host apps and **upgradable** via re-run — consistent with the gem's
  vendored-but-upgradable model.
- Encode **project-specific guardrails** an agent cannot infer.
- **Lowest blast radius**: never silently rewrite host-authored directives.

## Non-goals

- Not bundled into `install` (opt-in, exactly like the `lookbook` generator).
- No new component-catalog artifact — reuse `list` + `docs/components/*.md` + `/lookbook`.
- No auto-rewriting of conflicting host directives (detect-and-report only).
- Not coupled to one agent tool — support both `CLAUDE.md` and `AGENTS.md`.

## Decisions (resolved in brainstorming)

1. **Packaging:** a separate `modelrails_ui:agent_rules` generator with a post-install nudge.
   Rationale: it mutates a host-owned, tooling-specific file (`CLAUDE.md`/`AGENTS.md`); that
   side effect should be opt-in. Mirrors the `lookbook` opt-in precedent.
2. **Reference target:** the rules point agents at existing mechanisms —
   `bin/rails g modelrails_ui:list` (installed surface), `docs/components/<name>.md` (usage),
   `/lookbook` (live previews). No fourth artifact to drift out of sync (YAGNI).
3. **Attachment:** a gem-owned rules *file* plus a single `@`-import line (inside markers) in
   the host agent file. Reuses the `@`-import convention the host already uses (modelrails_base's
   `CLAUDE.md` imports `@.claude-on-rails/context.md`).
4. **Conflict handling:** detect-and-report. Grep host agent files for known-tension phrases,
   print a warning with a suggested reconciliation, and **never** edit host prose. Keeps the
   one useful half of AI-DS's scan without the dangerous half (silent rewrites).
5. **House rules:** sensible host-policy defaults (I18n, CSP→Stimulus) live in a *separate*,
   developer-owned file that is seeded once and never overwritten. This preserves the
   "override-able defaults" intent without breaking the "wholesale overwrite" property of the
   gem-owned file.

## Files and lifecycles

| File | Lifecycle | Owner | Contents |
|---|---|---|---|
| `.modelrails_ui/agent-rules.md` | **Overwritten every run** | The gem | Design-system rules (discovery, tokens, signals, AAA, both-themes). Always current with the gem. |
| `.modelrails_ui/house-rules.md` | **Created once if absent, never overwritten** | The developer | Sensible host-policy defaults (I18n, CSP→Stimulus) the developer may edit or delete. |
| Host agent file (`CLAUDE.md` or `AGENTS.md`) | **Import line added once** (idempotent) | The developer | A marker-delimited `@`-import pointing at `agent-rules.md`. Untouched if already present. |

The two-file split is deliberate: each file has a trivial, opposite lifecycle ("always
replace" vs "create only if absent"), so there is **no merge logic and no preserved-region
parsing** anywhere. A developer's edit to `house-rules.md` survives every regeneration; a gem
update to the design-system rules lands on the next `agent_rules` run.

## Generator behavior

`rails g modelrails_ui:agent_rules` performs:

1. **Resolve the host agent file** — prefer an existing `CLAUDE.md`, else an existing
   `AGENTS.md`; if neither exists, default to `CLAUDE.md`. (A `--file=PATH` override is
   allowed for non-default tooling.)
2. **Write** `.modelrails_ui/agent-rules.md` (overwrite unconditionally).
3. **Create** `.modelrails_ui/house-rules.md` **only if absent**.
4. **Ensure the import marker block** exists in the host agent file: if the
   `<!-- BEGIN modelrails_ui -->`…`<!-- END modelrails_ui -->` markers are present, leave them
   untouched; otherwise append the block. Idempotent — a second run adds nothing.
5. **Conflict scan (report-only):** grep the host agent file and, if present,
   `.claude-on-rails/context.md` for known-tension patterns; print a non-fatal warning with
   `file:line` and a suggested reconciliation line.
6. **Print a summary** of files written/created/skipped and the conflicts found.

The `install` generator gains a closing hint:
> To teach your coding agent to use these components, run
> `bin/rails g modelrails_ui:agent_rules`.

## Content: `agent-rules.md` (gem-owned, portable)

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

## Content: `house-rules.md` (seeded default, developer-owned)

```markdown
# Project house rules (UI)

Sensible defaults from modelrails_ui. This is *your* file — edit or delete freely;
the generator seeds it once and never overwrites it.

- **All UI text uses I18n locale keys** — no hardcoded strings.
- **No inline event handlers** (`onclick`, `onchange`, …). A strict Content Security
  Policy (CSP) blocks them, and system specs won't catch it (Playwright bypasses CSP) —
  use Stimulus actions: `data-action="click->controller#method"`.
```

## Import marker block (added to the host agent file)

```markdown
<!-- BEGIN modelrails_ui -->
When building or changing UI, follow the design-system rules in @.modelrails_ui/agent-rules.md
<!-- END modelrails_ui -->
```

## Conflict detection

A small, extensible table of report-only patterns. Seed entry:

| Pattern (case-insensitive) | Why it conflicts | Suggested reconciliation |
|---|---|---|
| `ViewComponents only when reused` | Reads as "don't reach for `UI::*` primitives" | "`modelrails_ui`'s `UI::*` primitives ARE the shared library; this guideline governs *new app-specific* components." |

The scan is advisory and non-fatal; the developer decides whether to edit their prose.

## Testing (TDD — gem generator specs)

Drive a generator run against a fresh tmp app and assert behavior, not implementation:

1. **Fresh install:** both `.modelrails_ui/agent-rules.md` and `.modelrails_ui/house-rules.md`
   are created; the host agent file gains the marker block with the `@`-import.
2. **Idempotent re-run:** second run overwrites `agent-rules.md` (re-seeds gem content), does
   **not** add a second marker block, and does **not** overwrite `house-rules.md`.
3. **House-rules override survives:** a pre-existing `house-rules.md` with custom content is
   left untouched.
4. **Conflict report:** when the scanned file contains `ViewComponents only when reused`, the
   generator output includes the warning + suggested reconciliation.
5. **AGENTS.md routing:** when only `AGENTS.md` exists, the import lands there, not in a new
   `CLAUDE.md`.

## Rollout

- **Gem PR (this branch):** generator + templates + specs; README `agent_rules` section;
  post-install nudge in the `install` generator; `CHANGELOG.md`; `MODELRAILS_STATUS.md` note.
  Targets `modelrails/harden`.
- **App adoption (modelrails_base, separate PR):** run the generator; commit `.modelrails_ui/*`
  and the `CLAUDE.md` marker block; reconcile the flagged `ViewComponents only when reused`
  line in `.claude-on-rails/context.md`.

## Open questions / future

- **Transitive `@`-import:** confirm the host agent tool resolves an `@`-import *inside* an
  imported file (`agent-rules.md` → `house-rules.md`). If it does not, list both files in the
  marker block instead of chaining.
- **Optional skill wrapper (out of scope):** a thin Claude Code skill that invokes the
  generator would mirror AI-DS's `/bm-design-system` UX. Deferred — the generator is the core.
