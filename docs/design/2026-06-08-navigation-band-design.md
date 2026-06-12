# Navigation band — Design (Wave 7)

**Status:** Approved design (brainstorm-validated). Per-arc implementation plans are produced
separately by `superpowers:writing-plans`.

**Goal:** Harden the four core navigation components — **tabs · navbar · breadcrumb ·
pagination** — to WCAG 2.2 AAA + the relevant WAI-ARIA APG patterns, using the proven
hardening groove (0a render test + app 0b browser-axe AAA + ledger + doc).

**Band context:** Wave 7, after the menu band (Wave 6: dropdown_menu/context_menu/menubar,
all proven). Toolchain: gem `PATH="…/ruby/4.0.5/bin:$PATH" bundle exec …` (render load path
`-Itest/render`); app `mise exec -- bundle exec …`.

## §0 — Why this band is not "formalize-only"

Unlike the menu band (3 components sharing ONE `menu` controller), the navigation band is
**four independent a11y contracts** — four different APG patterns, little controller sharing.
That removes shared-controller regression risk and parallelizes well, but each component
carries its own gaps:

- **tabs** — currently click-only: `role=tablist/tab/tabpanel` + `aria-selected`, but **no
  keyboard, no roving tabindex, no `aria-controls`/`aria-labelledby`/ids, non-focusable
  panels**, and an odd dual `@items_data`-array + slots API. The heaviest member → the
  **band exemplar**.
- **navbar** — disclosure controller flips `this.element.nextElementSibling.hidden`; **no
  `aria-expanded`/`aria-controls`/Escape/focus management** (and a declared `toggle` target
  goes unused). Medium.
- **breadcrumb / pagination** — structurally sound already (nav landmark, `aria-current`,
  `aria-disabled`, decorative-separator `aria-hidden`); **gaps are hardcoded English strings
  (i18n)** + formalization. Light.

## §1 — Sequencing (3 arcs, exemplar-first)

1. **tabs** — band exemplar; own gem PR + app PR (sets the keyboard/roving pattern).
2. **navbar** — own arc (disclosure controller).
3. **breadcrumb + pagination** — **bundled** into one arc (both tiny markup + i18n of the
   identical "static nav with `aria-current`" shape; user-approved bundle).

Each arc: subagent-driven groove (implementer + two-stage review per task), gem PR into
`modelrails/harden` + app PR into `main`, careful-merge (poll head==SHA + checks; the REST
`gh api PUT /pulls/N/merge -f sha=<HEAD>` primitive guards stale-head merges server-side).

## §2 — tabs (exemplar): the full APG tabs contract

**Roles & wiring** (auto-generated ids per tab `i`):

- Wrapper `data-controller="tabs"`.
- **`role="tablist"`** with an i18n accessible name (`label:` → `aria-label`), default
  `aria-orientation="horizontal"`.
- Each **`role="tab"`**: `id`, `aria-selected` (true on active), `aria-controls="{panel_id}"`,
  **roving tabindex** (active `0`, rest `-1`), `data-tabs-target="tab"`.
- Each **`role="tabpanel"`**: `id`, `aria-labelledby="{tab_id}"`, **`tabindex="0"`** (so
  keyboard users can reach/scroll panel content), `hidden` when inactive,
  `data-tabs-target="panel"`.

**Automatic activation** (the controller rewrite):

- `ArrowRight`/`ArrowLeft` (horizontal): move focus to the adjacent tab **and activate it**
  (show its panel), wrapping, **skipping `aria-disabled`**.
- `Home`/`End`: first/last enabled tab (+ activate).
- Click: activate. (`Enter`/`Space` are no-ops under automatic — focus already activated.)
- Roving on every activate: active tab `tabindex="0"` + `.focus()`, others `-1`.

**Disabled tabs:** `aria-disabled="true"` (NOT native `disabled` — keeps the tab in the a11y
tree + roving-skippable), `pointer-events-none`.

**API consolidation** (notable, safe — tabs is experimental/unadopted, no app surface): drop
the dual `@items_data` array **and** slots → **slots-only**, matching the proven
`renders_many` idiom (dropdown_menu items / menubar menus):

```erb
<%= render(UI::TabsComponent.new(label: "Account settings")) do |t| %>
  <% t.with_tab(title: "Profile") do %> …panel content… <% end %>
  <% t.with_tab(title: "Password", disabled: true) do %> … <% end %>
<% end %>
```

- `label:` **required** (tablist accessible name; i18n) — applies the menubar require-label
  lesson (a generic default passes axe's name-present check while under-naming the widget).
- `selected:` index (default `0`) for the initially-active tab.
- One rendering path instead of two.

**Controller** (`tabs_controller.js`, rewritten): `static targets = ["tab", "panel"]`,
`static values = { index: Number }`. Methods: `connect` (initial render + roving), `select`
(click→activate by index), `navigate` (keydown → arrows/Home/End with skip-disabled + wrap →
activate+focus), private `#render(active)` syncing `aria-selected`/`tabindex`/`hidden` (+
focus on the active tab). **Own controller** — tabs is a distinct pattern (no `EXTRA_STIMULUS`
reuse).

**Scope cuts (YAGNI):** horizontal orientation only (vertical = a future `orientation:`
prop); no "Down-arrow moves focus into the panel" enhancement; no lazy/Turbo-Frame panels
(that is the manual-activation path we ruled out — panels render inline/eager).

**Tokens:** unchanged; all verified real (`bg-surface-sunken`, `bg-surface-raised`,
`text-text-heading`, `ring-interactive-focus`). The active-tab treatment
(`data-[state=active]:bg-surface-raised … shadow`) stays; AAA is proven in CI.

## §3 — navbar: disclosure hardening

A `<nav>` landmark (i18n `aria-label` — a page often has multiple navs) with a responsive
mobile-menu disclosure. The controller is rewritten off its fragile `nextElementSibling`
coupling:

- **Toggle `<button>`:** `aria-expanded` (synced), `aria-controls="{menu_id}"`, i18n
  accessible name; drives a **`menu` target** (not `nextElementSibling`).
- **Menu panel:** `id`, `hidden` when collapsed.
- **Escape** closes + returns focus to the toggle; **outside-click** closes.
- Controller (`navbar_controller.js`, rewritten): `static targets = ["menu", "toggle"]`;
  `toggle()`/`close()` sync `aria-expanded` on the toggle target. Own controller (nav-specific
  responsive disclosure; does not entangle the separate `collapsible` component).

## §4 — breadcrumb + pagination: markup + i18n (bundled arc)

Both are structurally sound; this is formalization + **i18n** + a 0a/0b each.

- **breadcrumb:** i18n the "Breadcrumb" `aria-label` (overridable + a `t()` default key); keep
  the `items:` array API (`[{ label:, href: }, …, { label: }]`; last = current page, gets
  `aria-current="page"`); separators stay decorative (`aria-hidden`); `text-text-muted` is
  AAA here (resolves to the same neutral as body). No long-breadcrumb overflow collapse (YAGNI).
- **pagination:** i18n the three strings ("Pagination" `aria-label`, "Previous page", "Next
  page"); verify `border-border-strong` / `bg-interactive` / `text-text-on-interactive` are
  real tokens at build; add `aria-hidden="true"` to the decorative ellipsis; keep the
  paginator-agnostic `url:` callable + `current_page`/`total_pages`/`window` API (works
  directly with Pagy metadata — the preview demonstrates a Pagy-shaped usage).

## §5 — DoD + verification (per component)

Per component (tabs, navbar, breadcrumb, pagination):

- Renders · AAA semantic tokens only · correct ARIA (the role/relationship contract above) ·
  i18n (no hardcoded user-facing strings) · disabled treatment · focus management +
  focus-visible · fail-loud where applicable · doc-comment · slot/prop API · template-backed
  preview.
- **0a render test** (gem, structure-only): roles + aria wiring + roving tabindex (tabs) +
  `aria-expanded`/`aria-controls` (navbar) + `aria-current` (breadcrumb/pagination) + i18n
  labels + disabled.
- **0b browser-axe system spec** (app — the real gate):
  - **tabs:** full keyboard (←/→ activate + wrap, Home/End, skip-disabled, click), roving
    tabindex, `aria-selected`/`hidden` sync, focusable panel, AAA both themes.
  - **navbar:** toggle discloses (`aria-expanded` sync), Escape closes + focus return,
    outside-click closes, AAA both themes.
  - **breadcrumb / pagination:** render + `aria-current` + AAA both themes (mostly static —
    lighter 0b).
- **doc** (`docs/components/<name>.md`) + **ledger** rows `hardened` → `proven`.
- AAA is **CI-only** (the `wcag2aaa` 7:1 hook); a local 0b runs axe default (AA) — don't claim
  AAA from a local pass; push and read CI.

## §6 — Risks & notes

- **tabs is the meat** — the keyboard/roving/aria-controls contract + the API consolidation
  (dropping `@items_data`) are the real work; the app 0b is the gate (the render harness can't
  exercise JS). Test the ←/→-activate-and-wrap + skip-disabled + panel-focusable paths
  explicitly.
- **navbar disclosure** — the rewrite must replace `nextElementSibling` with a proper `menu`
  target and add the `aria-expanded`/Escape/outside-click contract; prove disclosure + focus
  return in the 0b.
- **i18n** — every hardcoded English string (tabs has none in markup beyond author content;
  navbar toggle name; breadcrumb/pagination labels) must move to locale keys with sensible
  `t()` defaults.
- **No controller reuse** — each interactive component (tabs, navbar) owns its controller; no
  `EXTRA_STIMULUS` entries this band (the patterns don't overlap).
- **Token verification** — confirm `border-border-strong`, `bg-interactive`,
  `text-text-on-interactive`, `ring-interactive-focus` resolve (no phantoms) during the build,
  Adam-style.
