# modelrails_ui — Converged Conventions (Phase 0 spec)

**Date:** 2026-06-08 · **Status:** decided (convention summit) · **Unblocks:** Phase 1 (finish
shadcn hardening on this API) + Phase 2 (private Catalyst skin overlay).

Output of the convention summit — advocates **shadcn** + **Catalyst** (grounded in the real
shadcn-flavored gem templates and the licensed `~/Downloads/catalyst-ui-kit`), filtered by
**DHH / Jorge Manrubia / Léonie Watson** (Rails idiom · Hotwire fit · AAA, with AAA as a hard
veto), synthesized through **Sandi Metz** (cost of change) + **Jim Weirich** (does it tell the
truth). See `2026-06-08-adoption-audit-and-catalyst-pivot.md` for the why.

## Meta-finding
The advocates **converged** independently on one architecture: **Catalyst's per-component
CSS-var plumbing + craft (optical-border, TouchTarget, `data-slot`, subgrid) on top of
shadcn-style global semantic tokens + native-state conventions — with the AAA CI gate owning
every concrete color value.** Catalyst brings *structure & craft*; shadcn brings *tokens &
native state*; the repo's existing code already pointed the way on every contested point. These
conventions are **skin-independent** (they govern API/labelling, not the paint) — one API, two
skins.

---

## A. Settled conventions (confirmed — adopt as-is, with the noted guards)

**A1 — Variant plumbing = per-component CSS vars reading from global semantic tokens.** One
static base template per component; each variant sets a small set of custom properties
(`--btn-bg`, `--btn-border`, `--btn-hover-overlay`, `--btn-icon`; `--switch-bg`; `--checkbox-checked-bg`)
that the base consumes. **The vars may ONLY reference existing semantic OKLCH tokens, never a raw
`oklch(...)`/hue.** This is the dual-skin enabler: swapping skins = supplying different var values;
the base never forks. → *Guard:* extend the raw-value lint to cover `--*:` custom-property
declarations, not just utility classes.

**A2 — `data-slot` is the universal ROLE contract.** `data-slot=control|label|description|error|icon|legend`.
Parents lay out / space / size children by *role* via CSS (`*:data-[slot=icon]:size-5`,
`[&>[data-slot=label]+[data-slot=control]]:mt-3`). Pure HTML attribute → ports React→Hotwire with
zero JS; skin-independent; agent-friendly. → *Guard:* `data-slot` is structural only — **state lives
in ARIA** (A3), never in `data-slot`.

**A3 — State model: ARIA is the source of truth; native pseudos for browser state; `data-[state]`
only for JS-owned state.** Style off `aria-expanded`/`aria-selected`/`aria-disabled`/`hidden`
(`aria-disabled:opacity-60`, `aria-selected:…`). Use native `hover:` / `focus-visible:` / `active:` /
`disabled:` for browser-owned interaction (NOT Headless's `data-hover`/`data-focus` — see L1).
Reserve `data-[state=*]` for state ARIA can't express (e.g. a transient `data-state=entering`
animation phase), and **every `data-state` must be paired with the ARIA attribute AT actually reads.**

**A4 — Icons = slotted SVG sized by the parent.** `data-slot=icon` + descendant sizing with an
override guard: `[&_svg:not([class*='size-'])]:size-4`, `[&_svg:not([class*='text-'])]:text-text-muted`.
No `icon=` prop, no icon-library coupling. Icon-only controls **require an accessible name** —
enforced by the **0b preview-host axe spec**, not by Ruby (the component can't know its slot is
icon-only). A sanctioned thin `icon` helper that emits a correctly-`aria-hidden` SVG is allowed for
*producing* the SVG you then slot.

**A5 — Token VALUES are AAA OKLCH; discard Catalyst's zinc palette + every `/opacity` tint.**
`text-zinc-500` (~4.6:1), `ring-zinc-950/10` (translucency, not contrast), `bg-{c}-500/15 text-{c}-700`
chips (AA) all FAIL the 7:1 gate. Map every value to the repo's semantic tokens (`bg-surface*`,
`text-text-*`, `border-border`, signal chips `bg-*-surface`+`text-*`+`*-border`, fills
`text-text-on-interactive`). **Never approve a tint from a local axe pass** (local = AA; only CI's
wcag2aaa hook catches sub-7:1). Keep Catalyst's *technique*, discard its *values*.

**A6 — Slots vs props.** Scalars (strings/booleans) → kwargs; anything that could contain markup →
slot. (`title:` string ok; a description that might hold a link → slot. Accessible-name kwargs like
`label:` stay required where the component needs a name — ViewComponent raises if omitted.)

**A7 — Naming: signal ladder, not React's `destructive`.** `primary / secondary / danger` and the
canonical `info · success · warning · danger` severity ladder. (Becomes the `tone:` axis — B2.)

**A8 — Resurrect a real `SIZES` ladder.** The current `SIZES = { default: "" }` is dead code + a
44px-target liability. Restore `:icon` (square) + a density step. **The `:icon` size MUST keep
44×44** (via `min-h/min-w-[var(--form-input-height)]` or the TouchTarget overlay) — a sub-44px icon
button fails WCAG 2.5.8 (AA) and 2.5.5 (AAA).

**A9 — Import `TouchTarget`.** Catalyst's `aria-hidden size-[max(100%,2.75rem)]` pseudo-overlay gives a
44×44 hit area without visual inflation — the clean way to satisfy target-size on compact controls.
Parent must be `position: relative`; the overlay is pointer-transparent + `aria-hidden`.

---

## B. Adjudicated rulings (the genuine divergences)

**B1 — Form composition: the form builder is canonical; repair the standalone Field to share ONE
spacing + wiring model.** `TailwindFormBuilder` already mints `#{id}-help`/`#{id}-error`, computes
`aria-describedby`, sets `aria-required`/`aria-invalid`, binds `label[for]` — it is the Rails-native
orchestrator and it's AAA-correct. **The standalone `FormFieldComponent` is the actual defect**
(renders `<label>` with no `for`, hint/error with no `id`, never injects `describedby:`/`invalid:`/
`required:` into its slotted control) — a broken parallel path, not a second good one. Fix:
- Adopt Catalyst's **`data-slot`-adjacency spacing as the single shared model** (`[&>[data-slot=label]+[data-slot=control]]:mt-3`, `…control]+[data-slot=description]]:mt-2`) on **one** wrapper class, emitted by **both** the standalone Field **and** the builder's `field_wrapper` (retire the ad-hoc `space-y-2`/`space-y-1.5` split — pick one).
- Rewrite `FormFieldComponent` to mint a field id, render via the **Label primitive** with `for:`,
  give hint/error real ids, and inject `describedby:`/`invalid:`/`required:` into the slotted control
  (which already accepts them) — a thin correct mirror of the builder, not a divergent reimpl.
- → *Guard:* put `data-slot=control` on the input **group** (prefix+input+suffix), not the bare
  input, or the `+` adjacency selector breaks on input-groups. (Catalyst-style `Field/Label/
  Description/ErrorMessage` as four nested components is React tax here — the builder already wins.)

**B2 — Button (and badge/alert) API: TWO axes — `variant:` (shape) × `tone:` (signal).**
`variant: :solid|:outline|:text` (default `:solid`) × `tone: :primary|:neutral|:danger` (default
`:primary`; room for `:success`/`:warning`). The current flat enum **smuggles a 2-D space into 1-D**:
`text_danger` = (shape:text)×(tone:danger). Factoring N×M → N+M removes the leak (not gold-plating —
the cross-product already exists in the data).
- Map onto the existing `.btn-*` layer: `(solid,primary)`→`primary`, `(solid,danger)`→`danger`,
  `(outline,neutral)`→`secondary`, `(text,*)`→ TEXT family by tone. **Deprecation shim:** `coerce_variant`
  translates old values (`text_danger`→`{variant: :text, tone: :danger}`) so **call sites don't break**.
- `cn(SHAPE.fetch(variant), TONE.fetch(tone))`; unknown value raises (house rule).
- **Reject Catalyst's free-form full-palette `color:`** (17 hues) — that IS the over-engineering; keep
  `tone` to the AAA-verified signal set. → *Guard (AAA):* each new shape×tone *fill* is an untested
  `text-on-interactive` pairing — **ship only combos with a 0b CI axe row; raise on the rest until proven.**

**B3 — Compound widgets: keep the un-clobberable render-lambda slots; grow the part vocabulary as
lambda branches (for the ARIA); import subgrid; shortcuts via hardened `kbd`.** Keep `renders_one :trigger`
+ `renders_many :items` with the **el-last-splat** lambda (`**attrs, **el` — wiring splats LAST so
`role`/`tabindex`/`menu_target`/`action` always win; callers can add attrs but can't break the
menu). This is *more* robust than Catalyst's per-part components (where a caller can pass `role:` and
break it) and the most Hotwire-native shape.
- Add the Catalyst part *vocabulary* as **lambda branches**, NOT nested namespaces:
  `separator: true` (exists), `heading:` → `role="presentation"`, `section:` → `role="group"` +
  `aria-labelledby`. Adopt the vocab **for the ARIA it unlocks** (flat-list menus are an AT failure).
- **Subgrid** (icon/label/shortcut column alignment) → `grid-cols-subgrid` behind
  `supports-[grid-template-columns:subgrid]:`, exactly like the existing `supports-[position-area]:`
  guard. Fallback must stay **legible**, not just non-crashing.
- **Shortcut** → render via the already-hardened `ui :kbd` (decorative mirror of the accelerator the
  Stimulus controller binds).

**B4 — Responsive type as density: primitives DO carry it — scoped to focusable text-entry controls.**
`text-base md:text-sm` (16px mobile → no iOS focus-zoom; 14px at `md+`) on Input/Textarea/Select/
NumberInput/FloatingLabel **base**. This is an a11y invariant that belongs *with the control* (like the
44px target), not a layout concern. The repo already does this (`number_input`, `floating_label`).
- → *Guard:* **scope to focusable text-entry controls ONLY** — do NOT spray `text-base md:text-sm` onto
  buttons, labels, or display primitives (the 16px-zoom rationale doesn't apply; it'd just bloat them).
  Pick `md:` vs `sm:` once and apply uniformly (repo uses `md:`).

**B5 — Focus indicator: offset `outline` is the uniform AAA default; full-surface highlight the
sanctioned exception; `ring` (box-shadow) is RETIRED.** `focus-visible:outline-2
focus-visible:outline-offset-2 focus-visible:outline-interactive-focus`. `ring` is a `box-shadow`:
**clipped by `overflow:hidden` ancestors** (the dropdown PANEL is `overflow-hidden` → a ring on an
item gets cut) and **invisible in forced-colors / Windows High Contrast** (`box-shadow:none`) — a
2.4.7 failure for the users who most need focus. `outline` is OS-drawn, survives both, and the offset
gives geometric (non-color) distinction.
- **Exception:** the dropdown menu items' filled `focus-visible:bg-surface-sunken` highlight stays — a
  full-row highlight is a *stronger* indicator inside `overflow:hidden` than an outline. Outline =
  default; full-surface highlight = sanctioned alternative where outline is clipped/wrong.
- → *Guard:* after the sweep, **grep the COMPILED CSS for lingering `box-shadow` focus declarations**
  (value, not escaped selector — repo rule), not just source classes.

---

## C. Translation landmines (look portable, bite)
1. **`data-state` ≠ ARIA** — port the styling hook, never the state source-of-truth (AAA fail).
2. **`/opacity` borders & tints** (`ring-zinc-950/10`, `bg-{c}-500/15`) — translucency reads AA-passing
   in a *local* axe run; only CI's 7:1 gate catches it. Discard every `/N` on anything carrying meaning.
3. **`text-white` on fills** — passes light, FAILS dark AAA → always `text-text-on-interactive`.
   (Catalyst markup is littered with `text-white`.)
4. **`first-child`/positional icon detection** — fragile under slots → explicit `data-slot=icon` +
   descendant matching, never positional.
5. **Subgrid support window** — newer than the menus' anchor-positioning; `supports-` guard mandatory,
   fallback must be legible.
6. **Native `required` vs server-rendered errors** — the repo deliberately emits **`aria-required`
   only** (`required: false`) so the browser doesn't pre-empt the server error summary
   (`registration_validation_spec.rb`). Any ported Field/Input that re-introduces native `required`
   silently breaks the validation UX — adapter must strip it.
7. **`ring` under `overflow:hidden` / forced-colors** (B5) — survives copy-paste, looks fine until an
   HCM user or a clipped container hits it.
8. **`space-y-*` vs `data-slot` adjacency collision** — adopting B1's adjacency spacing while keeping
   `space-y-*` double-spaces. One spacing model; remove the other.

---

## D. Cost-of-change + honesty (Sandi / Jim)
**Cost (Sandi):** the only convention changes with real blast radius are **B2** (button two-axis —
capped by the `coerce_variant` deprecation shim, so call sites don't break), **B1** (Field repair +
unify spacing — touches the form builder + `FormFieldComponent` + the field wrapper), and **B5** (focus
sweep — mechanical, every primitive). Everything else is additive or a guard. **The shim (B2) + the
shared wrapper (B1) keep `modelrails_base`'s call sites stable** — that is the cost-minimizing path,
and it's why this is cheap NOW and expensive later (retrofit across 81 components + the app twice).
**Honesty (Jim):** these rulings make the library *tell the truth* — the standalone Field that renders
a `<label>` with no `for` is a lie (looks accessible, isn't); `data-state` that desyncs from ARIA is a
lie; the flat enum pretending `text_danger` is one axis is a lie. Each ruling removes a lie.

---

## E. Concrete impact
- **Shipped (~40 proven) components:** one **convention pass** — A1–A9 mostly already hold; the deltas
  are B2 (button/badge/alert → variant×tone + shim), B5 (ring→outline sweep), B1 (FormFieldComponent
  repair + builder spacing unify), A8 (restore SIZES). Re-run 0a/0b after.
- **Remaining ~41:** hardened directly on this API (variant×tone, outline focus, data-slot, per-component
  vars, responsive type on text controls, render-lambda slots + ARIA part-vocab) — **the win of doing
  Phase 0 first.**
- **`.modelrails_ui/agent-rules.md`:** add — the variant×tone axes; `data-slot` role contract;
  ARIA-as-state; outline-not-ring focus; per-component-var plumbing (vars reference tokens only);
  responsive-type scope; the `aria-required`-only rule; "ship only AAA-verified fill combos."
- **Catalyst skin (Phase 2) inherits for free:** the entire API/labelling layer (variant×tone,
  data-slot, slots, part vocab), every controller, the AAA token engine. The skin = a different set of
  per-component **var values** (optical-border with `--btn-bg: <catalyst-mapped AAA token>`) + density/
  radius constants. Because the API is shared, **`modelrails_base`'s call sites don't change when the
  skin swaps.**

## F. Open follow-ups
- Decide the `tone` set's outer bound (just `primary/neutral/danger`, or `+success/warning`?) — each
  added fill is an AAA-verify cost.
- Confirm the `md:` breakpoint for B4 across all text controls (repo currently `md:`).
- Spec the `data-slot=control`-on-group rule for input-groups (B1 guard) before the Field rewrite.
- Sequence: land B1/B2/B5/A8 on the shipped components (the convention pass) **before** resuming the
  remaining-41 hardening, so the rest are built once on the final API.