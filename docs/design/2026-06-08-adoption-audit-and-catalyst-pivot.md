# modelrails_ui — Adoption Audit + Catalyst-Pivot Feasibility (planning note)

**Date:** 2026-06-08 · **Status:** planning / decision-support (no decision made)

Two questions in one note: (A) how much of the hardened component library does the host app
(`modelrails_base`) actually use, and (B) how hard would it be to pivot `modelrails_ui` from a
**shadcn/ui-inspired** design language to a **Tailwind UI _Catalyst_-inspired** one.

**Design references:**
- **Current:** [shadcn/ui](https://ui.shadcn.com) (+ Svelte port [shadcn-svelte](https://www.shadcn-svelte.com)) — credited in the gem README; "you own the code" copy-into-app philosophy; `data-[state=*]` patterns.
- **Proposed:** [Catalyst (Tailwind UI)](https://catalyst.tailwindui.com/docs) — Tailwind Labs' official React kit (Headless UI + Tailwind). Licensed (Tailwind UI).

---

## Part A — Adoption audit (what the app actually uses)

**Headline: the app adopts ~6 of 42 vendored `UI::*` components, almost never via `render(UI::…)` directly.** Consumption is indirect, through four mechanisms:

1. **`TailwindFormBuilder`** (app-wide default form builder): `*_field` → `UI::InputComponent`, `text_area` → `UI::TextareaComponent`, `file_field` → `UI::FileInputComponent`, `submit` → `.btn-primary`, `select` → `.form-field` (styled native), checkboxes/radios → hand-rolled.
2. **`avatar_for`** helper → `UI::AvatarComponent`.
3. **Shared partials** — `_modal`/`_confirm_dialog` → `UI::DialogComponent`; `_pagination` → Pagy `series_nav` (styled).
4. **Direct** — `ui(:alert, variant: :destructive)` → `UI::AlertComponent` (2 sites only); `.btn-*` classes.

### Adopted (6 of 42)
| Component | Where | Mechanism |
|---|---|---|
| `UI::InputComponent` | ~every form | form builder |
| `UI::TextareaComponent` | invitations, projects | form builder |
| `UI::FileInputComponent` | (rare, via builder) | form builder |
| `UI::AvatarComponent` | global header + identity pickers | `avatar_for` |
| `UI::DialogComponent` | avatar change, disconnect, notif bulk | `_modal`/`_confirm_dialog` |
| `UI::AlertComponent` | resources new/edit | `ui(:alert)` |
| *(pagination)* | members#index | Pagy `series_nav` (styled, not a component) |

### Hardened but NOT adopted (hand-rolled equivalents in the app)
`button` (→ `.btn-*` + inline classes), `badge`, `data_table`, `select`, `checkbox`, `radio_group`,
`switch`, `toggle`, `tabs`, `navbar`, `breadcrumb`, `dropdown_menu`, `context_menu`, `menubar`,
`popover`, `tooltip`, `hover_card`, `separator`, `kbd`, `progress`, `indicator`, `skeleton`,
`spinner`, … The app rolls its own: custom badge `<span>`s, plain `<table>`s (members list), a
bespoke `dropdown` Stimulus controller for the user menu, its own breadcrumb/nav partials in
markdowndocs, hand-rolled toggle switches in notification preferences, etc.

### Global chrome (every authenticated page)
`application.html.erb` + `settings.html.erb` render: `UI::AvatarComponent` (user menu) + a
hand-rolled `dropdown` controller, notifications indicator, theme toggle, toasts, sidebars — all
hand-rolled with design-system tokens except the avatar.

### By-route adoption (condensed)
- **Auth** (sessions/registrations/passwords/magic-link): the most on-system area — all forms →
  `UI::InputComponent` + `.btn-primary` + `error_summary` + `_oauth_buttons`.
- **Account** (`/account/*`): forms → Input; profile/avatar → `UI::DialogComponent` (`_modal`) +
  identity-picker cropper; connected-accounts + notifications bulk → `UI::DialogComponent`
  (`_confirm_dialog`); notification-preferences → hand-rolled toggles (NOT `UI::Switch`/`Toggle`).
- **Workspaces core**: members#index → Pagy `series_nav` + hand-rolled `<table>` + hand-rolled
  status badges + form Input/selects; settings/new/edit → form Input + `_modal` logo picker.
- **Projects**: forms → Input/Textarea/selects; resources new/edit → `ui(:alert)`; everything else
  hand-rolled (badges, buttons, nav).
- **Marketing pages** (`/`, `/about`, `/contact`, `/privacy`): hand-rolled `_hero`/`_section`/
  `_feature_card` partials — **zero `UI::*`**.
- **Invitations accept/decline + markdowndocs**: hand-rolled; markdowndocs has its OWN
  `_breadcrumb`/`_navigation` (not `UI::Breadcrumb`/`Navbar`).

**Implication for the pivot (the key one):** because adoption is so thin and indirect, the app's
*look* is driven by a SMALL surface: the ~6 adopted components + the `.btn-*`/`.form-*` design-system
classes + the global chrome. **You can change the app's entire visual language by re-skinning that
small surface — without touching the 36 unadopted components.**

---

## Part B — Catalyst-pivot feasibility

### The crucial reframe: you don't "swap in" Catalyst — you re-skin your own engine
Catalyst is **React** (Headless UI + Tailwind). `modelrails_ui` is **Hotwire/Stimulus + ViewComponent**.
You cannot drop Catalyst's components into a Rails app. So "model after Catalyst" means the SAME thing
the current library did with shadcn: **reimplement Catalyst's visual + interaction _design_ in your own
Hotwire components.** This is a **re-skin + API-convention alignment**, not a swap or a port.

### Engine vs. skin — what carries over (≈70% of the value)
The expensive, hard-won parts of `modelrails_ui` are **reference-agnostic** — they're correct whether the
skin is shadcn or Catalyst:
- **Behavior layer** — the Stimulus controllers (`menu`, `modal`, `floating`, `tabs`, `navbar` disclosure,
  the APG keyboard/roving/dismissal logic). Catalyst's behavior comes from Headless UI (React); you already
  have the Hotwire equivalent. **Keep it.**
- **A11y contract** — the WCAG 2.2 AAA hardening (0a render tests + 0b browser-axe + the CI wcag2aaa 7:1
  hook). **Note:** Catalyst targets ~AA, not AAA — so the a11y rigor is a `modelrails_ui` differentiator to
  *preserve*, not inherit.
- **Token system** — the OKLCH semantic tokens (`bg-surface-*`, `text-text-*`, `bg-interactive`, …) with
  AAA-guaranteed contrast. **Keep the token ENGINE; remap the palette toward Catalyst's visual intent**
  (Catalyst leans zinc/neutral with a refined accent). Catalyst's exact colors may not hit 7:1 — you adapt
  its *language* onto AAA-compliant tokens.
- **Architecture** — ViewComponent base (`ApplicationComponent#cn`/`tailwind_merge`), the `add` generator +
  vendoring model, the EXTRA_STIMULUS shared-controller registry, the Lookbook catalog, the hardening groove.
  **All reference-agnostic. Keep.**

What actually changes per component: **the Tailwind class strings** (the visual skin) and possibly **the
API conventions** (prop/slot names, variant vocabulary) to match Catalyst's idioms.

### Effort tiers (pick based on goal)
- **Tier A — re-skin only what the app uses (~days).** Re-skin the 6 adopted components (Input, Textarea,
  FileInput, Avatar, Dialog, Alert) + the `.btn-*`/`.form-*` design-system classes + the global chrome
  (header/user-menu/toasts). Because of the adoption gap (Part A), **this alone makes `modelrails_base` look
  Catalyst** while the 36 unadopted components sit untouched. Lowest risk, fastest visible payoff. The app's
  full suite + AAA CI catch regressions on the small adopted surface.
- **Tier B — re-skin the whole library in place (~weeks, mechanical).** Re-write every component's class
  strings (and align APIs) to Catalyst, component by component, reusing the existing controllers + tests +
  tokens. The hardening groove mostly carries (behavior unchanged; re-prove AAA on the new skin). This is the
  "the whole library now looks Catalyst" path. Effort ≈ the *styling* slice of each component × ~81, minus the
  ~41 already proven (whose 0a/0b can be re-run after the re-skin).
- **Tier C — parallel `modelrails_ui_catalyst` gem (most work, cleanest separation).** A second skin selectable
  at generate-time. Even here you'd SHARE the engine (generator, token system, controllers, ViewComponent base)
  and fork only the templates — so it's "two skins, one engine," not two libraries. Worth it only if you need
  both shadcn and Catalyst variants live simultaneously.

**Recommendation:** start at **Tier A** as a spike — re-skin the adopted surface + `.btn-*` on a branch, see it
in the running app (both themes, AAA CI), and judge the look/effort before committing to Tier B. The adoption
audit is what makes Tier A a genuinely small, low-blast-radius experiment.

### Caveats / risks
1. **License.** Catalyst ships under the **Tailwind UI license** (more restrictive than shadcn/ui's MIT).
   *Modeling after* it — your own Hotwire reimplementation, visual inspiration — is the defensible posture
   (same as the current shadcn reference, but shadcn is MIT so it was lower-risk). **Verbatim-copying Catalyst's
   markup/code into a public/redistributable gem is the risk.** Since `modelrails_ui` is your own gem and the
   approach is reimplementation (not redistribution of Catalyst source), it's likely fine — but confirm against
   the Tailwind UI license terms before publishing, and keep the gem private if in doubt.
2. **AAA tension.** Catalyst is not AAA. Don't inherit its exact contrast; keep the AAA token engine and map
   Catalyst's intent onto 7:1-compliant tokens. Some Catalyst looks (subtle greys, low-contrast secondary text)
   will need AAA-adjusted values — the same `text-muted == text-body` discipline already in place.
3. **API churn.** If you also adopt Catalyst's API conventions (not just its look), the ~6 adopted components'
   call sites in `modelrails_base` change (esp. the form builder's Input/Textarea/FileInput contract). Keep the
   adapter seam (the form builder + `_modal`/`avatar_for` helpers) so the app's call sites stay stable while the
   skin changes underneath — the adoption indirection is actually an asset here.
4. **Behavior parity.** A few Catalyst components lean on Headless UI niceties (e.g. transitions, focus
   management) that your Stimulus controllers already cover — verify no behavior is silently dropped in the
   re-skin (the 0b browser specs are the guard).

### Open decisions (for the user)
- Tier A spike first, or commit to Tier B?
- Re-skin in place (replace shadcn) vs. parallel Catalyst skin (Tier C)?
- Adopt Catalyst's **API conventions** too, or only its **visual language** (keep current APIs)?
- Confirm the Tailwind UI license permits a reimplemented, modeled-after gem (private vs. public).
- Is this the moment to also **raise app adoption** (migrate the hand-rolled user-menu dropdown →
  `dropdown_menu`, member-table → `data_table`, badges → `badge`, markdowndocs breadcrumb → `breadcrumb`)?
  A re-skin + adoption push together would maximize the payoff, since right now most hardened components
  aren't exercised by the app at all.

---

## Part C — Grounded review of the actual Catalyst source (`~/Downloads/catalyst-ui-kit`)

Read the real kit (TS + JS variants, ~26 components: button, input, textarea, select, checkbox, radio,
switch, dialog, dropdown, avatar, badge, table, navbar, pagination, sidebar, alert, combobox, listbox,
link, divider, heading, text, fieldset, description-list + auth/sidebar/stacked layouts). Findings:

1. **Catalyst is Tailwind v4 — the SAME stack as `modelrails_ui`.** (`@import 'tailwindcss'`, `@theme {}`,
   `@tailwindcss/postcss ^4.2.4`.) **No Tailwind migration.** Class syntax (`size-5`, `rounded-lg`,
   `text-base/6`, `bg-(--btn-bg)`, `px-[calc(--spacing(3)-1px)]`, arbitrary props) is directly portable.

2. **Behavior = Headless UI (React) — exactly what your Stimulus controllers already replace.** Catalyst
   imports `@headlessui/react` for Dialog/Dropdown/Switch/Combobox/Listbox behavior + transitions. You
   **drop Headless UI** and keep your `modal`/`menu`/`floating`/etc. controllers. Concretely: Catalyst's
   `Dialog` = `Headless.Dialog` + `DialogBackdrop` + `DialogPanel` with `data-closed`/`data-enter`/
   `data-leave` transition states — your native `<dialog>` + `modal` controller (translateY slide) already
   does this; you just apply Catalyst's panel skin (`rounded-2xl bg-white ring-1 ring-zinc-950/10 shadow-lg`,
   slide-up `data-closed:translate-y-12`).

3. **The signature Catalyst look is PURE CSS and fully reproducible in a ViewComponent.** The "premium"
   button is an **optical-border + inner-highlight** technique: `border-transparent` + a `before:` layer for
   the real background + an `after:` layer for the hover overlay + an inner top-highlight
   `after:shadow-[inset_0_1px_white/15%]`, driven by per-instance CSS vars (`--btn-bg`, `--btn-border`,
   `--btn-hover-overlay`, `--btn-icon`). Inputs use the same `before:` (bg+shadow) / `after:` (focus ring)
   layering. **None of this needs React** — it's a (long) Tailwind class string + CSS vars, which a
   ViewComponent constant holds perfectly. Corners are softer than shadcn (`rounded-lg`/`2xl`/`3xl` vs
   `rounded-md`); neutral is **zinc**; type is responsive (`text-base/6 sm:text-sm/6`); 44px touch via a
   `TouchTarget` pseudo-span (you already have `.btn-touch-target`).

4. **The mechanical translation per component:**
   - `data-hover:` → `hover:`, `data-focus:` → `focus-visible:`, `data-active:` → `active:`,
     `data-disabled:` → `disabled:`/`aria-disabled:`, `group-data-hover:` → `group-hover:` (Headless's
     JS-driven state attrs → native CSS pseudo-classes — simpler + no JS).
   - React props (`color`, `outline`, `plain`, `size`) → ViewComponent kwargs + a styles map (the same
     shape Catalyst uses: a `base` + `variant` + `colors` hash → your `cn(BASE, VARIANT, COLOR)`).
   - `clsx(...)` → your `cn(...)` (`tailwind_merge`).
   - Slots (`data-slot=icon`, InputGroup) → ViewComponent slots / the `cn` icon utilities you already use.

5. **★ The AAA catch is real and concrete — adopt Catalyst's TECHNIQUE, not its COLORS.** Catalyst targets
   ~AA and uses many sub-AAA values: `text-zinc-500` (placeholder/muted ≈ 4.5:1), `text-{color}-700` on
   `bg-{color}-500/15` badge tints, `ring-zinc-950/10` (10%-opacity borders), `bg-zinc-950/25` backdrop.
   Dropping these in verbatim would **break the AAA CI gate.** So the pivot = Catalyst's structure /
   radius / layering / optical-border technique **mapped onto your OKLCH AAA tokens** (`bg-surface-*`,
   `text-text-*`, `bg-interactive`, the signal `-surface` tints). Your existing `text-muted == text-body`
   AAA discipline + the wcag2aaa CI hook are exactly the guardrail for this re-color. **This re-coloring is
   the actual design work** — the structure ports mechanically; the palette is where taste + AAA meet.

6. **Catalyst's badge ≈ your signal-chip already.** `bg-{color}-500/15 text-{color}-700` (tinted chip) is
   the same pattern as `modelrails_ui`'s `bg-*-surface + text-*` signal chips (and the app's hand-rolled
   status badges). Direct map; just AAA-adjust the tint/text.

### Revised effort read (grounded)
- The hard parts (behavior, a11y, tokens, generator) **do not move** — Catalyst confirms it: its behavior is
  Headless UI, which your controllers already supersede.
- **Tier A (adopted surface) is genuinely ~1–3 days:** re-skin Button(`.btn-*`)/Input/Textarea/FileInput/
  Avatar/Dialog/Alert to Catalyst's technique on AAA tokens. The button + input class strings are the
  biggest single chunk (the optical-border treatment) but they're copy-translate-recolor, and they're
  exactly the surfaces driving the app's look.
- **Tier B (full library) is weeks but mechanical**, and the small Catalyst catalog (~26) maps onto your
  hardened set — components Catalyst lacks (kbd, skeleton, spinner, progress, the overlay zoo) just keep
  their current skin or get a light Catalyst-flavor pass.
- **License:** modeling-after a reimplementation (no verbatim Catalyst markup in the gem) is the posture;
  Tailwind UI's license permits using the components in your projects but restricts redistribution — keep
  the gem private or confirm terms before publishing a Catalyst-skinned `modelrails_ui`.

---

## Part D — Sequencing recommendation (shadcn public + catalyst private)

**Constraints:** shadcn `modelrails_ui` stays public/shared and is still being hardened (~41 left);
the catalyst version is **private, licensed, for the owner's own app** (not published in `modelrails_ui`
or `modelrails_base`); the owner wants to adopt some of Catalyst's **labelling/API conventions** and
backport those standards into the shadcn version too.

### Principle: don't duplicate the engine — two skins, one engine
~70% of the gem is the **engine** (the `add` generator, `ApplicationComponent`/`cn`, the Stimulus
controllers, the OKLCH AAA token scaffolding, the 0a/0b/AAA-CI hardening harness, Lookbook). It is
**skin-agnostic** (Catalyst confirms it: its behavior is Headless UI, which the controllers already
supersede). The engine is also **still in motion** (the hardening program keeps adding controllers +
patterns). Therefore:
- **Forking the whole gem now is the costliest option** — every remaining engine improvement would have
  to be re-ported to the fork, and the two engines will drift. The worst time to fork is while the engine
  is actively growing.
- **The catalyst version should be a thin private _skin overlay_, not a duplicate gem:** the SAME engine
  (public `modelrails_ui`) + a private template pack (catalyst class strings) + an AAA-mapped token file.
  Mechanism: give the generator a pluggable **template source** (default = bundled shadcn; opt-in = a
  private catalyst templates dir / private gem that depends on `modelrails_ui`). Zero engine duplication;
  clean license boundary (public engine + public shadcn skin; private catalyst skin + tokens).

### Refinement: converge the API/labelling FIRST (not after)
The owner wants Catalyst's labelling AND to improve shadcn by it. **Decide the shared API now**, before
finishing the 41 — borrow the Catalyst conventions worth keeping (the `Fieldset`/`Field`/`Label`/
`Description`/`ErrorMessage` field composition; `color`/`outline`/`plain` button props; `data-slot`
naming; the `Dropdown*`/`Dialog*` sub-component naming) — and bake them into the groove. Then:
- the remaining ~41 are hardened with the **final** API,
- the ~40 already-proven components get a one-time convention pass,
- and because the API is shared across skins, **the app's call sites don't change when you swap skins**
  (the form builder / `_modal` / `avatar_for` seam stays stable). Do this late instead and you retrofit
  81 components + their tests + the app twice.

### Recommended phasing
- **Phase 0 — converge conventions (small, now):** review Catalyst's API/labelling, decide what to adopt,
  apply to the proven components, lock it into the hardening groove + the agent-rules.
- **Phase 1 — finish shadcn hardening (~41)** on the converged API. Engine + a11y + tests, **once**.
- **Phase 2 — catalyst skin overlay (private):** reuse the engine; ship catalyst templates + AAA-mapped
  tokens; re-skin component-by-component, **re-proving AAA** (the structure/behavior/tests already exist —
  swap class strings + tokens). Skin in place on the stable engine, not a parallel build.

### Lever: do you need all 81 in catalyst?
The adoption audit shows `modelrails_base` uses ~6 components. If the catalyst version is for the owner's
own app, **adoption can drive scope** — harden+skin only what the app will actually use (the ~6 adopted +
the obvious near-future ones), leaving the long tail. That reaches a catalyst app far faster. The
comprehensive 81 only pays off if the library also serves downstream consumers; for a private app, skin
what you'll adopt.

### Net recommendation
Owner's instinct ("finish shadcn first, then catalyst") is directionally right — sharpened to:
**(0) converge conventions now → (1) finish shadcn hardening on that converged API → (2) catalyst as a
thin private skin-overlay on the same (now-stable) engine, scoped by adoption.** Not a gem fork.
