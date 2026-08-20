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

## Component API — variant × tone, data-slot, focus
- **Two-axis variants.** `button` and `badge` take `variant:` (shape) × `tone:` (signal) —
  button: `variant: :solid|:outline|:text` × `tone: :primary|:neutral|:danger`; badge:
  `variant: :solid|:soft|:outline|:ghost|:link` × `tone: :primary|:neutral|:info|:success|:warning|:danger`.
  `alert` is tone-only (`tone: :neutral|:info|:success|:warning|:danger`). Old flat values
  (`variant: :text_danger`, etc.) still work via a deprecation shim, but **write the two axes
  in new code.** Only AAA-proven `(variant, tone)` cells exist — an unproven combo **raises in
  dev**; add one only with a 0b axe row to prove the new on-color pairing.
- **`data-slot` is the role contract.** Compound primitives tag their parts
  (`data-slot=label/control/description/item/…`); spacing adjacency and ARIA key off it. When
  you compose a field, put `data-slot=control` on the input **group** (prefix + input + suffix),
  not the bare input, or the adjacency spacing breaks. Pass the field's wiring to your control
  via the yielded context (e.g. `<%= ui :input, **f.input_attrs %>`), don't hand-wire ids.
- **Focus is an offset `outline`, never a `ring`.** Focusable controls carry the `focus-ring`
  utility (a 2px AAA offset outline). Never `focus:ring-*` / `focus-visible:ring-*` — a
  box-shadow ring is clipped by `overflow:hidden` ancestors and vanishes in forced-colors mode
  (a 2.4.7 failure). The one exception is a menu item's full-surface
  `focus-visible:bg-surface-sunken` highlight (a stronger indicator where an outline is clipped).
- **A fixed-position overlay container with `aria-label` is a live region OR a landmark — never
  bare, never `role="group"`.** Such a container (toast stack, notification tray) must clear two
  axe rules at once: `aria-prohibited-attr` (`aria-label` needs a role) and `region` (its content
  must sit in a live region or landmark, since it lives outside `<main>`). Two valid shapes:
  (a) make the container the live region — `role="status"` + `aria-live="polite"` (or
  `role="alert"`/`assertive` for errors) — when the container announces its own children; or
  (b) make it a landmark — `role="region"`, with the `aria-label` as its name — when the live
  regions live on the individual items (per-item `role="status"`, so the container must *not*
  also be a live region). `role="group"` clears `aria-prohibited-attr` but is neither, so it
  trips `region`. (`ToasterComponent` uses shape (a); an app's own `shared/_toasts` per-toast
  stack uses shape (b).)

## Before you call UI work done
- **Check both themes** — light *and* dark (class-based dark mode).
- **Contrast is proven by the axe gate, not by eyeballing** — the reference host runs the
  WCAG 2.2 AAA audit locally by default (both themes, each set explicitly) and again in CI;
  don't claim AAA until that gate has passed on your change.
- **Fail loud, don't fabricate.** If a needed token or primitive seems missing, surface it —
  don't invent a raw-value or contrast workaround.
- **Check adoption drift** — `rake modelrails_ui:adoption` shows which components this app
  renders but never audits in isolation (the a11y blind spot).

## Project house rules
This app also follows @.modelrails_ui/house-rules.md — sensible defaults you can edit.
