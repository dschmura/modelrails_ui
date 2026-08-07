# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2026-08-07

### Added

- Gallery: `full_src:` option lets the lightbox display a larger rendition than the grid thumbnail — lightbox previews auto-scale to fit the viewport while the full source remains clickable.
- Gallery: `LightboxComponent` extracted as a standalone, reusable view component (previously lightbox logic was inline within GalleryComponent). The lightbox now ships prev/next buttons, arrow-key navigation (← / →), and a caption + counter bar (e.g., "2 / 8") rendered only when 2+ images are present.
- Gallery: new `gallery:navigated` Stimulus event fired whenever the lightbox opens, moves to the previous image, or moves to the next image. Event detail includes `{index: N}` (0-based position in the gallery). Callers can listen to this event for analytics, logging, or coordinating with other UI.
- Gallery: trigger contract now includes `gallery-index-param` and `gallery-caption-param` to support the new caption + counter rendering in the lightbox.
- **Migration note:** Running `rails g modelrails_ui:add gallery` regenerates local copies and may overwrite your edits if you have drift. Diff before regenerating; manual integration of changes is safe.

### Fixed

- Gallery: the lightbox panel now carries a `min-h-32` floor. The prev/next buttons this release adds are vertically centered on the panel while the close button sits at `-top-2`; the two only clear each other once the panel is at least ~116px tall. A very short/wide framed image — or the instant right after `modal#open`, before the swapped `src` has decoded and `naturalHeight` is briefly 0 — could collapse the panel below that and overlap the close button with a nav button (WCAG 2.5.8). Found during downstream app integration.

## [0.7.1] - 2026-07-13

### Fixed

- form_draft controller: rename instance property `scope` → `scopeDigest` — it collided with Stimulus's reserved `scope` getter, throwing on connect and disabling recovery entirely. form_draft is non-functional in v0.6.0 and v0.7.0.
- form_draft controller: evaluateReveal hides an already-visible notice when a re-check finds no valid draft (expired drafts no longer leave a stale notice after a morph).
- form_draft notice partial: build the chip wrapper with tag.div so the conditional hidden attribute passes herb-lint (erb-no-output-in-attribute-name).

### Accessibility (follow-up review)

- **context_menu trigger honors `role="button"`.** v0.7.0 added
  `role="button"` (to satisfy axe `aria-allowed-attr`) but the trigger only
  opened on Shift+F10 — a name-role-value promise it didn't keep (WCAG
  4.1.2). It now wires `menu#triggerKeydown`, so Enter/Space/ArrowDown open
  the menu (anchored to the trigger); right-click still opens at the pointer.
- **range slider is a 44px hit box with a slim visible track.** v0.7.0's
  batch omitted `range`, leaving its 8px track failing 2.5.5. Rather than
  inflate the visible track to 44px (a fat pill), the input is now a
  transparent 44px interaction box with a slim track painted via
  `::-webkit-slider-runnable-track` / `::-moz-range-track` and a larger
  (20px) thumb.

## [0.7.0] - 2026-07-06

Fixes surfaced by MiClassrooms rooms work.

### Added
- Tooltip: `TooltipComponent.bubble_classes(side:)` public API for the documented "describe an existing interactive control" pattern — the caller puts `aria-describedby` on its own control, builds a `group/tooltip` wrapper, and reuses the bubble exactly instead of reaching into the component's constants.
- Tabs: `tablist_class:` kwarg merges extra classes onto the tablist bar for placement/styling cases (e.g. a tablist floated over a media stage); conflicts resolve in the caller's favor via `cn`.
- Alert: `role:` override (e.g. `:note`) for persistent context. Any override also drops `aria-live` entirely — persistent context is not a live region, and a banner that Turbo re-rendered with unchanged text was re-announced on every keystroke.

### Fixed
- Tooltip: the bubble's reveal variants use the **named** group `group/tooltip` (`group-hover/tooltip:` · `group-focus-within/tooltip:` · `group-data-[dismissed]/tooltip:`) instead of the bare `group-*:` forms. Tailwind's unnamed group variants match ANY `.group` ancestor — a tooltip nested inside a grouped `<details>` had every bubble raised whenever hover/focus sat anywhere inside that ancestor.
- Breadcrumb: a non-last item without `href` renders as plain text instead of an href-less `<a>` — "linked for some viewers, plain for others" crumbs (e.g. a policy-gated building link) are now expressible.

### Accessibility

- Target size (WCAG 2.5.5, Level AAA): interactive controls across ~18 components now guarantee the 44×44px minimum. `min-h-11`/`min-w-11` (or a bumped fixed height) was applied to tooltip, checkbox and radio_group labels, tabs triggers, breadcrumb links, context_menu trigger, navbar (brand, hamburger, mobile links), sidebar (nav items + collapse toggle now `size-11`), navigation_menu (triggers + links `h-11`), mega_menu trigger, combobox (all `sm`/`md`/`lg` sizes → `h-11`), timepicker trigger, collapsible summary, input_otp cells (`w-11`), banner dismiss button, and the badge link variant. The resizable separator now owns a real 44px-wide (or -tall) grab strip while the visible hairline is drawn with a centered `before:` pseudo-element — the operable target meets AAA without thickening the divider.
- Removed the `scale-95` rest class from the dialog, alert_dialog, and gallery panels and neutralized `scale` in `modal_controller.js` (on `connect` and at the top of `animateIn`). Under Tailwind 4, `scale-95` compiles to the standalone `scale:` property, which *composes* with — rather than overrides — the controller's inline `transform`, so any panel rendered already-open (a path that skips `animateIn`) rested permanently at 95%.
- Context menu: the trigger region gained `role="button"`. Carrying `aria-haspopup`/`aria-expanded` on a role-less `<div>` is an axe critical (`aria-allowed-attr`); the role makes the ARIA state legal.
- Carousel: the previous/next arrow plates go from 80% to 95% surface opacity for stronger contrast over slide images.
- Popover Lookbook preview: the account links are sized to the 44px target.

## [0.6.0] - 2026-07-06

### Added
- Component adoption manifest: a new `rake modelrails_ui:adoption` (and `:adoption:strict`) reports, per component, how the host app adopts it (`direct`/`adapter`/`utility-standin`/`transitive`/`none`) and its `N/M` audit-scenario coverage — leading with the "adopted-but-under-audited" blind-spot list. Adoption is read from host code (comments/strings stripped, so doc examples don't inflate); the audit denominator comes from the host's own live previews; a fork-owned `.modelrails_ui/adoption.yml` supplies adapter overrides and row suppression. A gem-internal completeness gate now fails the build if any shipped component lacks a real Lookbook preview or render test.
- form_draft: encrypted localStorage form-draft recovery (notice partial + form-mounted controller).

### Changed
- `COMPONENT_STATUS.md` drops its two machine-derivable columns (`Render test`, `App-adopted`) — those facts are now computed by `rake modelrails_ui:adoption`; the ledger is human judgment (Tier + Notes) only.

## [0.5.0] - 2026-07-05

### Added
- Alert: signal tones (`info` · `success` · `warning` · `danger`) now render a tone-matched severity icon automatically — the same Lucide-style glyphs as the toaster, so an alert and a toast at the same level share one glyph. Distinct shapes keep severity legible without relying on color alone (WCAG 1.4.1); the icon is `aria-hidden`, so screen readers still hear only the urgency-matched live region and the caller's title/description. `neutral` stays icon-free; the new `icon: false` kwarg opts out and restores the previous rendering exactly.

### Fixed
- Customizable Select: the styled base-select button dropped its picker-icon onto a second line (and let it drift as the picker opened), because `.form-field`/`.form-input` set `display: block`, overriding base-select's default flex button. The `@supports` block now restores `display: flex` on `.ui-select` and pins the picker-icon inline at the end.

## [0.4.0] - 2026-06-30

### Added
- Customizable Select: `UI::Select`'s native `<select>` picker now opts into `appearance: base-select` where supported (Chromium, Safari 26+), rendering a fully styled picker that matches the design system — the combobox's overlay/border/shadow, a brand-tinted checkmark on the selected row, roomy options, and a flipping picker-icon. Browsers without support fall back to the untouched native control. Pure CSS + one `ui-select` hook class; no JS, no markup change.

## [0.3.1] - 2026-06-15

### Fixed
- Calendar: a day that is both today and selected rendered low-contrast heading text on the selected fill (dark-mode AAA failure); today's text emphasis now yields to the selected on-color.

## [0.3.0] - 2026-06-11

### Added
- Optional `modelrails_ui:agent_rules` generator: writes design-system agent rules + seeded house rules, adds an idempotent `@`-import to `CLAUDE.md`/`AGENTS.md`, reports directive conflicts.
- Hardened the component library to the proven tier — 80 of 82 components proven (render tests + template-backed Lookbook previews; browser-axe AAA verification in the host app's CI) across display, dialog, floating, menu, navigation, and media bands. See `COMPONENT_STATUS.md`.
- One shared `modal` Stimulus controller drives the native-`<dialog>` family (dialog, alert_dialog, drawer, sheet, gallery lightbox); one shared `menu` controller (roving tabindex, type-ahead, dismissal) drives dropdown_menu, context_menu, and the menubar coordinator.
- CSS anchor positioning (`position-area`/`position-try`) for popover, tooltip, and hover_card.
- Lookbook teaching catalog: choosing/decision pages, form-control playgrounds, Related cross-link graphs, and per-preview backgrounds.

### Changed
- Two-axis component API: `button` and `badge` take `variant:` (shape) × `tone:` (signal); old flat values still work via a deprecation shim.
- Unified signal vocabulary to a canonical `info·success·warning·danger` ladder across alert/badge/button/indicator (`destructive` kept as a non-breaking alias for `danger`). Alert gains all four tinted signal levels; badge signal chips move from solid base-token fills to tinted surfaces (`bg-*-surface` + `text-*` + `*-border`), since the base tokens are TEXT colors and rendered as muddy dark chips when used as fills.
- Focus indicators standardized on the `focus-ring` offset-outline utility (never `focus:ring-*` box-shadows, which vanish in forced-colors mode).

### Fixed
- Indicator `warning` count text used the non-adaptive `text-text-heading` (low-contrast on the fill in both themes); now uses the adaptive `text-text-on-interactive`.

## [0.2.0] - 2026-05-30

### Added
- Lookbook living documentation. `rails g modelrails_ui:lookbook` installs a dev-only preview
  layout (loads the host's compiled Tailwind + importmap so previews render styled and
  interactive), a config initializer, and `ViewComponent::Preview` classes for the six solid
  components (button, input, textarea, file_input, dialog, avatar). Mount `Lookbook::Engine` and
  visit `/lookbook` for a navigable, shareable component explorer.

## [0.1.0] - 2026-05-30

First release of **modelrails_ui** — a hardened fork of view_primitives 0.1.0 (see the upstream
baseline entry below), re-themed and extended to meet modelrails_base standards: WCAG 2.2 AAA,
I18n, OKLCH semantic tokens, and form_builder integration. All upstream components are included.
See `MODELRAILS_STATUS.md` for the per-component maturity record.

### Added
- Self-contained install: generates an `ApplicationComponent` with an inlined `cn` helper and a
  `UI` inflection initializer, so adopting apps carry **no runtime dependency** on the gem.
- Ships the full AAA OKLCH design system via the install generator (tokens, `@theme inline`,
  class-based dark mode, `.btn-*`/`.bg-hue-*`); the installer skips it when the host already owns
  the tokens.
- Gem-side WCAG 2.2 AAA contrast test (`test/test_aaa_contrast.rb`): OKLCH→luminance contrast for
  the core token pairs, asserted ≥ 7:1 in light and dark.

### Changed
- All component templates re-themed from shadcn tokens to AAA semantic tokens
  (`surface*`, `interactive*`, `danger*`, `text-*`, `border*`); `dark:` variants dropped
  (tokens auto-flip via `.dark`).
- `Input` / `Textarea` / `FileInput`: first-class `required`/`invalid`/`describedby` → ARIA;
  styling matches the app's form-field constants; dual-mode (form-builder + standalone).
- `Dialog`: rewritten onto the native `<dialog>` + `showModal` pattern (focus trap/restore,
  native Escape, `::backdrop`); ships `modal_controller.js`; adds `wrapper:` and `body_id:`.
- `Button`: app `.btn-*` taxonomy (primary/secondary/danger + text family).
- `Avatar`: app `AVATAR_SIZES`, rounded-full, hue-tinted initials, role=img/aria-hidden.

### Fixed
- `add` generator: `source_root` instance-method bug; public `template`/`copy_file` wrapped in
  `no_commands`.
- Install generator: skips token CSS when the host already owns the tokens; robust
  `@import "tailwindcss"` anchor (with or without the trailing semicolon).

### Known issues
- Templates that don't generate: `form_field`, `qr_code` (SyntaxError), `input_otp` (undefined helper).
- `embed` calls `CGI.parse` without `require "cgi"` (breaks on Ruby 4.0).

---

_The entry below is from the upstream view_primitives project, retained for provenance._


## view_primitives 0.1.0 (upstream baseline) - 2026-05-30

### Added

**Generators**
- `rails g view_primitives:install` — copies `ApplicationComponent`, CSS variables, prints Tailwind config
- `rails g view_primitives:add <component>` — copies component files into `app/components/ui/`; warns before overwriting
- `rails g view_primitives:list` — shows all available components with installed status
- `ui` helper available in controllers, views, and Action Mailer views
- Install generator checks `UI` inflection and detects existing Tailwind entry point

**Phase 1 — Foundation**
- Button — 6 variants, 4 sizes, defaults to `type="button"` inside forms
- Alert — informational banner with title/description slots and destructive variant
- Accordion — collapsible `<details>` sections; optional `exclusive:` Stimulus mode

**Phase 2 — Display**
- Badge, Avatar, Card, Separator, Label, Skeleton, Progress, Aspect Ratio, Spinner, KBD
- Rating — read-only star display
- Rating Input — interactive star rating with form/AJAX submission
- Indicator — status dot/count badge overlaid on an element
- List Group — bordered list with optional links and active state
- Banner — announcement strip with variants
- Button Group — visually joined row of buttons

**Phase 3 — Forms**
- Input, Textarea, Checkbox, Radio Group, Select, Switch, Toggle, Toggle Group
- Form Field — label + input + hint + error layout wrapper
- File Input, Search Input, Number Input, Range, Floating Label

**Phase 4 — Navigation**
- Tabs — array API + Stimulus slot API
- Breadcrumb, Pagination, Stepper, Bottom Navigation, Footer
- Navbar — responsive top bar with hamburger
- Navigation Menu — top-level nav with dropdown flyouts
- Mega Menu — full-width dropdown with grouped links and images

**Phase 5 — Overlays**
- Dialog, Alert Dialog, Sheet, Drawer, Popover, Tooltip, Hover Card

**Phase 6 — Menus**
- Dropdown Menu, Context Menu, Menubar, Command, Combobox

**Phase 7 — Complex**
- Calendar, Date Picker, Timepicker, Carousel, Data Table, Sidebar, Input OTP
- Collapsible, Scroll Area, Resizable
- Gallery — responsive image grid with optional lightbox
- Chat Bubble, Speed Dial, Device Mockup, QR Code

**Phase 8 — Advanced**
- Chart — Chart.js adapter (bar, line, pie, doughnut, radar, polar area)
- Toaster — stacked toast notifications (Sonner-style)
- Timeline — vertical timeline with event items
- WYSIWYG — rich-text editor with Trix (default) or Quill adapter

**Phase 9 — Media & Semantic HTML**
- Picture — `<picture>` + `<source>` for art direction and modern formats (AVIF/WebP)
- Video — `<video>` + `<source>` with poster, controls, and `<track>` captions
- Figure — `<figure>` + `<figcaption>` wrapper
- Image — responsive `<img>` with `srcset` / `sizes`
- Audio — `<audio>` + `<source>` with optional transcript link
- Iframe — sandboxed embed wrapper with required `title` and lazy loading
- Map / Area — image map with clickable `<area>` regions
- Embed — third-party embeds with automatic provider detection from URL; supports YouTube, Vimeo, Spotify, Google Maps, Yandex Maps, Loom, SoundCloud, X (Twitter), Telegram, Facebook

### Changed

- Removed public `component` helper — use `ui` for primitives, `render` for other namespaces
- `AddGenerator` copies files from template directories automatically (no per-component methods)
- `Components.supported` is derived from template directories, not a duplicated list
- Simplified `Detector` and `ComponentHelper`
- `view_primitives:add` exits with status 1 on unknown components; prints copy summary
- Requires `view_component >= 4.0` and Rails `>= 7.1`

[0.1.0]: https://github.com/alec-c4/view_primitives/releases/tag/v0.1.0
