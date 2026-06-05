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
