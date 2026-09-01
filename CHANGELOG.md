# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `copy`: copy-to-clipboard field — a readonly `input` value with a real label, a 44px `[:outline, :neutral]` trigger whose visible text never changes, polite (copied) and assertive (failed) regions present from first render, honest failure without `execCommand`, `data-state` + `copy:copied`/`copy:failed` hooks, and four `modelrails_ui.copy.*` strings. Closes #139.

### Fixed

- `add` generator: the "already exists — overwriting" message was false — Thor prompts on a differing file; the message now names the prompt and `--force`/`--skip`.
- `button` docs: variants, sizes and the API table now describe the shipped two-axis cells and `SIZES` (`default`, `icon`), and the Links example no longer uses the unshipped `:ghost` variant.

## [0.14.2] - 2026-08-30

### Fixed

- `form_builder`: a field for an attribute loaded from the database renders the reader's value, not `*_before_type_cast` — for an Active Record encrypted attribute that was the ciphertext. The raw pre-cast value is used only when the attribute came from the user this request (the guard ActionView's own field helpers apply), so a failed cast still re-renders what was typed.

## [0.14.1] - 2026-08-29

### Fixed

- `calendar`: arrow keys cross the month boundary — a target past the grid's edge pages to the adjacent month and lands on that date instead of dead-ending (APG date-grid). Paging renders synchronously so PageUp/PageDown focus the NEW grid, and a re-render keeps the roving stop on the focused day. (#177)
- `agent_rules` template: replace the phantom `bg-page` with `bg-surface`/`bg-surface-raised`; same phantom in the `bottom_nav` lookbook preview template.
- `agent_rules` template: the overlay-container rule keeps the live region on the container — the per-item-only shape it prescribed silences appended toasts.
- `agent_rules` template: point component docs at the gem's `docs/components/` path.
- `house-rules` template: system specs bypass CSP via Cuprite, not Playwright.

## [0.14.0] - 2026-08-25

### Added

- `keyboard/keyboard_nav.js` — a shared ES module holding the two movement algorithms the menu family had inlined four times: `TypeAhead` (buffer + APG idle reset + wrap-scan) and `nextActive` (ArrowDown/Up/Home/End over a visible set). Both are pure movement and never touch focus, aria, or the DOM; each controller keeps its own focus mechanics. Registered in `SHARED_JS` for dropdown_menu, context_menu, menubar, menubar_menu, combobox, and command — consumers need a `keyboard` importmap pin. Net −53/+27 across the four controllers. (#168)
- Theme-aware hue-ramp tokens: `--hue-initials-l`/`--hue-initials-c` for the fill and `--color-text-on-hue-initials` for its text, redefined under `.dark` the way `interactive` already is. (#144)
- Browser-lane coverage for menubar's bar-level keyboard contract — type-ahead match/wrap/multi-character-buffer/no-match, the menu-side `enabledItems` filter reached through the bar, and the ←/→ navigation that stays local. menubar previously had render-lane coverage only, and the render lane cannot run JS or Stimulus outlets. (#171, #168)
- `test_hue_ramp_contrast.rb` — AAA proven across all 360 hues in both themes, reading the shipped values out of the stylesheet and resolving the declared on-color rather than restating either. (#144)

### Fixed

- `command`: a caller-supplied `<hr>` is neutralized to `role="presentation"` + `aria-hidden` in `_tagOptions()`. An `<hr>`'s implicit `role="separator"` is an illegal child of `role="listbox"` (axe `aria-required-children`, critical) — and the component invited the markup, since `SEPARATOR` is an exposed constant and command.md's example places one inside the list. (#167)
- `command`: ArrowUp with no active option enters at the LAST item, matching `combobox`. Parity rather than a live path — `filter()` re-seeds the active option on every open and input — but it keeps the duplicated pair identical, which the #168 extraction depends on. (#167)
- `bg-hue-initials` participates in dark mode. It resolved to a fixed `oklch(0.35 0.2 var(--hue))` in both themes while `AvatarComponent` hardcoded `text-white` on it, so a hue disc stayed dark-with-white-text beside a `bg-interactive` sibling that flips to light-fill-with-dark-text. Dark is now L 0.80 / C 0.10 with `--neutral-900` text: 9.14:1 at the worst hue, and the only candidate that stays inside sRGB gamut at every hue — so that ratio is what renders rather than an estimate of the browser's gamut mapping. Light mode is unchanged (8.82:1 worst hue, verified). (#144)
- FormBuilder tolerates object-less forms (`form_with url:` sets the builder's object to FALSE, which survives safe navigation): `error_for` and `error_summary` guard with `respond_to?(:errors)`, so enhanced helpers render on model-less forms instead of raising. (#163)
- `dialog`: focus is restored on disconnect, and a detached opener is guarded. (#165)

### Changed

- `AvatarComponent#color_classes` pairs the hue fill with `text-text-on-hue-initials` instead of a hardcoded `text-white`. **Consumers with an app-side `text-white` on a `bg-hue-initials` element should remove it** — it defeats the adaptive on-color and leaves white text on a re-lit fill. (#144)

## [0.13.1] - 2026-08-23

### Fixed

- Switch off-state presence: the unchecked track carries `border-border-strong` (transparent again once checked) and the thumb gains `shadow-sm` — `bg-surface-sunken` barely separates from a raised card in either theme and the thumb was the card's own surface color, so an off switch rendered as a barely-visible oval. Caught in host-app browser review. (#161)
- Menu-family keyboard entry, two live bugs: `menu` ArrowUp with no focused item (the panel's `tabindex="-1"` catches padding/separator clicks) now enters at the LAST item instead of silently landing on `items[n-2]` — the one navigation path still missing the entry guard `command`/`combobox` already carry; `combobox` ArrowDown/ArrowUp after Escape on a zero-match filter now reopens the listbox (entering at first/last per APG) instead of locking the keyboard out until a printable keystroke. Browser-lane tests pin both, plus an invariant example pinning that `command` stays closed on ArrowUp after Escape (its parity branch is deliberately unreachable).

## [0.13.0] - 2026-08-23

### Added

- `min-h-input` is registered in `@theme inline` — the named 44px form-control floor (WCAG 2.2 AAA target size), resolving to `var(--form-input-height)`. customization.md documents it and deprecates the two legacy spellings (`min-h-11`, `min-h-[var(--form-input-height)]`); the consumer migration sweep stays tracked on the issue. (#142)
- Lookbook `@param` playgrounds for alert (tone/title/description/icon) and indicator (variant/count/position) — DoD item 10 backfill. (#19)
- Browser-lane coverage for form_draft: announce-after-disconnect, discard announcement, and a key-rotation test that decrypts the stored blob with the rotated key. (#74, #73)
- Guard tests pinning previously untested invariants: COMPONENT_STATUS.md row-set == `Components.supported` (#133); SHARED_RB/NON_COMPONENT_RB source disjointness + a real two-declarer `add dialog` → `add sheet` idempotency run (#132); no `Layout/LineLength` directives in shipped templates (#111); every `primary_path` producible from a shipped template (#75).

### Fixed

- FormBuilder: `required: true` in the `html_options` hash — the documented Rails signature — now converts to aria-only in `select` and in the collection checkbox/radio groups, instead of passing native `required` through to `super` and defeating the no-native-required contract. (#145)
- form_draft: `disconnect()` cancels the pending announce rAF/timer chain, so an announcement can no longer land on a detached node or a Turbo-cache-restored copy of the element. (#74)
- form_draft: the module-level key cache re-imports the key when the scope digest rotates; a digest change with no fresh key meta fails closed (feature off) rather than encrypting drafts no fresh page load could decrypt. (#73)
- `modelrails_ui:list` no longer misreports form_draft (partial-only) as not installed — `PRIMARY_PATHS` gains its notice-partial entry. (#75)
- Shipped templates no longer carry `rubocop:disable/enable Layout/LineLength` pairs (7 components) — the enable half re-activated a cop rubocop-rails-omakase turns off, surfacing unrelated long lines in every generated host file. (#111)

### Changed

- Badge Lookbook Examples demo the two-axis `variant:`/`tone:` API across all 10 shipped cells; `variant: :destructive` remains as the single, labeled legacy-shim demo. (#154)
- COMPONENT_STATUS.md reconciled with the generator catalog: form_builder and error_summary rows added as `gem-0a-proven / app-0b-pending`, counts corrected. (#133)
- Docs: alert.md documents the `**html_attrs` passthrough (#138); indicator.md synced to the shipped 5-tone set (`default/info/success/warning/danger`, `destructive` as alias) (#136).

## [0.12.1] - 2026-08-23

### Added

- Badge Lookbook preview gains a `neutral` scenario (`variant: :soft, tone: :neutral`), reachable at `.../badge_component/neutral`, so a consuming app's per-scenario 0b axe row can exercise the `[:soft, :neutral]` cell. (#146)

### Fixed

- Badge docs (docblock, badge.md, preview comment, test comment) no longer claim AAA proof for the `[:soft, :neutral]` cell — restores the review fix (25aa4b0) that missed the v0.12.0 merge: PR #152 landed at 4b78b30 before its follow-up commit was pushed, so the wording correction never shipped. Reworded to "9 AAA-proven, plus `soft`/`neutral` pending the consuming app's 0b axe row" throughout. (#146)

## [0.12.0] - 2026-08-23

### Added

- Badge emits stable `data-variant`/`data-tone` contract hooks so host specs can assert the two-axis contract instead of private class lists. (#149)
- Badge gains the `[:soft, :neutral]` cell (muted chip: `bg-surface text-text-muted border-border`) for draft-style pills; AAA proof lands with the consuming app's 0b axe row. badge.md rewritten for the two-axis API. (#146, #141)

### Changed

- Docs: _modal docblock reflects the fail-loud id contract; ModalChrome documents its includer interface (panel, dialog_attrs); dialog.md documents id/body_id/wrapper.
- BREAKING for hosts styling the list via `class:` — breadcrumb's `class:` now lands on the `<nav>` root like every other passthrough attribute; use the new `list_class:` to style the `<ol>`. (#148)

### Fixed

- Badge no longer ships `focus-ring` on non-focusable spans or an `aria-invalid` box-shadow ring; link badges (`href:`) keep `focus-ring` explicitly. (#147)

## [0.11.0] - 2026-08-22

### Added

- `UI::ModalChrome` — the eleven chrome methods shared by dialog, sheet and drawer (wrapper_attrs, header, close_button, body, footer_area, etc.) now live in one concern instead of three hand-copied sets; sheet and drawer adopt it, keeping only their variant-specific bits.
- Generator: `SHARED_RB` registry — a component template can now declare a shared Ruby module (alongside the existing `SHARED_JS`), copied once to `app/components/ui/`. First user: `modal_chrome.rb`.
- Dialog/sheet/drawer chrome now carries `data-slot` roles (`header`, `close`, `body`, `footer`) for host styling and test hooks.

### Changed

- **Breaking:** `UI::AlertDialogComponent` is gone — folded into dialog. Use `ui :dialog, role: :alertdialog` instead.
- **Breaking:** `wrapper: true` without an explicit `id:` or `body_id:` now raises `ArgumentError` in dev/test instead of minting a random body id whose Turbo Stream target silently no-ops in production.

### Fixed

- Sheet applied `extra_class` twice — once on the wrapper, once again on the panel — unlike its three siblings, which apply it once on the wrapper only.
- `body_id` derivation unified across dialog, sheet and drawer through `ModalChrome`'s shared `setup_modal_chrome`, instead of each template deriving it independently.

## [0.10.1] - 2026-08-22

### Fixed
- FormFieldComponent: with neither `id:` nor `label:` the field now renders unwired (no ids) instead of using a constant fallback id that collided when a page rendered two instances (caught by base's no-constant-DOM-ids guard).

## [0.10.0] - 2026-08-22

### Added

- Sidebar: the collapsed rail now explains its icons. Items show a hint bubble on hover or focus, `aria-hidden` by construction — the item's label is clipped to width 0 but stays in the accessibility tree, so the link already has its name and announcing the bubble too would name every item twice. It is `fixed` + anchor-positioned because the nav is `overflow-y-auto`, which makes its overflow-x non-visible as well and would clip an `absolute` bubble at the rail edge. (A5)

- Sidebar: `remember:` (default `true`) persists the collapse choice to a `sidebar_collapsed` cookie. A cookie rather than localStorage so the server can render the rail in the remembered shape on the first paint instead of painting it expanded and collapsing after; the component doc comment carries the one-line host helper. (A5)

- Drawer drag-to-dismiss. The component already rendered a grab handle that ignored the pointer. Drag starts from the handle only (dragging from the body would mean telling a drag from a scroll on every pointerdown, and getting that wrong breaks scrolling inside the drawer); the dismiss threshold is a fraction of the panel's own height rather than a fixed distance, because a bottom-anchored drawer has only its own height of travel below the handle. Drag is an addition — Escape and the close button are untouched, and the handle stays `aria-hidden` and unfocusable rather than advertising a control keyboard users cannot operate. (A8)

- Command palette fuzzy ranking. The filter was substring-only and preserved source order; it now scores with cmdk's scorer (vendored, MIT — full notice in the file header) and ranks matches within each group. `data-command-keywords` lets an item be found by a synonym it does not display. Group order is left alone deliberately: it is authored intent, and reordering groups between keystrokes moves the palette's shape under the reader. (A7)

- `test/test_shipped_stylesheet_completeness.rb` — guards both of the above: every custom class a template emits must be defined in the shipped stylesheet, and no shipped class may use a box-shadow focus ring. This bug class is invisible by construction, so it needs a test rather than a fix.

- Browser lane coverage for tabs, popover, combobox and checkbox — 38 tests over the behaviour the render lane cannot reach: arrow-key models, roving tabindex, filtering, `aria-activedescendant` resolving to a real option, runtime-minted ids staying unique across instances, and the `indeterminate` DOM property.
- Browser test lane (`rake test:system`). A real Chrome drives the gem's own controller templates through a real importmap, so behaviour that only exists once JS runs is provable here instead of only in a host app. Includes a structural axe audit (colour-contrast deliberately disabled — the stylesheet ships as Tailwind source, so a contrast pass here would be meaningless).

- Checkbox: `indeterminate:` for tri-state parents. Ships an `indeterminate` controller, since the property has no HTML attribute; deliberately does not also set `checked`.
- Collapsible: `disabled:` — `aria-disabled` + out of the tab order + pointer-inert, no JS. An already-open disclosure stays open.
- Breadcrumb: `max_items:` collapses the middle of a long trail behind an ellipsis, dropping the collapsed crumbs for every audience rather than hiding them from one.
- Avatar: initials now take over when the image FAILS to load, not only when `src` is nil. Wired only when both a `src` and a `fallback` are given, so src-only call sites keep their bare `<img>`.

- Tabs: `orientation: :vertical` (↑/↓ navigation, `aria-orientation`, restacked bar) and `activation: :manual` (arrows move the tab stop; Enter/Space reveals). Both default to the previous behaviour — horizontal and automatic — so existing call sites are unaffected.

- Generator: shared ES modules. A component can now ship a plain module alongside its Stimulus controller (`Components::SHARED_JS`), copied to `app/javascript/<namespace>/` with the importmap pin added automatically. Needed for behaviour that must be a SINGLE instance across components — a per-component controller copy cannot provide it. First user: `top_layer.js`.

- Overlays reach the browser top layer. `sticky`/`backdrop-blur` chrome establishes a stacking context that no z-index escapes from the inside; promoted panels paint above it. Promotion is gated on the panel already being `position: fixed`, because the top layer re-parents an element's containing block to the viewport — an `absolute`-placed panel would be torn off its trigger.
- Popover, combobox, date_picker, timepicker, navigation_menu and mega_menu now place with CSS anchor positioning (`anchor-name`/`position-anchor` + `position-area` + `position-try-fallbacks`), matching dropdown_menu and menubar_menu. Panels flip to stay on-screen where the old static offsets clipped. Width-tied panels (combobox, mega_menu) take their width from `anchor-size(width)`.
- DropdownMenu: checkable items (`checkbox:`/`radio:` → `menuitemcheckbox`/`menuitemradio` with `aria-checked`), which toggle in place and keep the menu open; `tone: :danger` for destructive actions; and nested submenus via `with_item(submenu: "…")`.

- `UI::FormBuilder` — generator-installed form builder rendering fields through FormFieldComponent, wired to ActiveModel::Errors; aria-required only, never native `required`.
- `UI::ErrorSummary` — focusable, autofocused form-level error panel; items link to fields; `heading_level:` option.
- Add generator: `NON_COMPONENT_RB` routing for non-component Ruby templates; transitive `DEPENDENCIES` installation.
- Install generator: consolidated `config/locales/modelrails_ui.en.yml`.
- `FormFieldComponent#html_input_attrs` — input_attrs translated to real ARIA attributes for native controls.

### Changed

- `ButtonComponent::COMBOS` now names the canonical `.btn-*` classes instead of re-listing their utilities. The stylesheet owns button appearance and the Ruby table is the typed accessor for it — previously the same rules existed in both languages and had already drifted. Rendered output is equivalent; `.btn-primary` carries exactly what the old utility string produced. (#101)

- **Breaking:** `FormFieldComponent` describedby order is now error-first; field-level error paragraphs are plain `<p>` (no `role="alert"`) — the focused ErrorSummary is the announcement mechanism.
- SelectComponent invalid state now paints its ring (`aria-invalid:ring-2` added) (#112).
- **Breaking:** railties floor raised to >= 8.0 — the form builder uses Rails 8's canonical checkbox helpers.

### Removed

- **`ModelrailsUi::ClassHelper` is gone.** It existed only as a test double for the structural lane's stubbed `ViewComponent::Base`, yet it lived in `lib/` and was required by the gem entrypoint, so it shipped as public API. Nothing in generated code used it — generated components get the real `cn` from `application_component.rb.tt`. Worse, it did **not** merge, so the structural lane was asserting class strings under different semantics than production. The stub now lives in the test lane, is tailwind_merge-backed, and a test pins that it merges.

- The shipped stylesheet no longer carries app-specific CSS: Markdowndocs prose styles, the Rouge syntax theme, workspace-branding overrides, Biscuit cookie-banner theming, and the development-only a11y-simulation filters. **1155 → 677 lines (−41%).** No component template referenced any of it. A fork using Markdowndocs or Biscuit now owns that styling — `modelrails_base` already does, in its own `_prose.css` and `_syntax.css`.

### Fixed
- Invalid-state ring now paints on all seven templates that set only its color (`aria-invalid:ring-2` added; structural gate pins the class); input/textarea keep the disabled affordance in the error state (#122).
- `error_summary` gains `unlinked:` to opt attributes out of derived-id anchors (custom ids, value-suffixed checkboxes, unrendered fields); the anchor contract is documented (#121).
- Legacy I18n keys (`ui.toaster.*`, `ui.resizable.*`, `modals.close`) migrated to the `modelrails_ui.*` namespace; old keys keep working as fallbacks for hosts that translated them (#116).

- FormFieldComponent: the no-`id:` fallback now derives a stable id from `label` (constant `form_field` when there's none) instead of `object_id`, which changed on every render and broke Turbo morphing. (#113)

- Sidebar: the toggle exposed no state to assistive technology. Collapse lived entirely in `data-collapsed`, which drives the CSS and is invisible to a screen reader — the button announced no state before, none after, and no indication anything had happened (WCAG 4.1.2). It now carries `aria-expanded` and `aria-controls` pointing at the nav it collapses, kept in step by the controller. (A5)

- Sidebar: a caller-supplied `id:` stopped reaching the root `<aside>` once `id:` became a named argument for the nav wiring. It is rendered on the root again, and derives the nav's id.

- `modal` warned "Stacked modals are not supported" and then called `showModal()` anyway. The browser has always supported it: a second `showModal()` puts that dialog above the first in the top layer, moves the focus trap, and gives it Escape. The warning is gone and browser tests hold the behaviour it was wrong about.

- **Escape never closed the command palette.** The component used `keydown.escape`, which is not in Stimulus's key-filter vocabulary — Stimulus throws "contains unknown key filter" and the action never runs. Every other floating component already used `keydown.esc`. Invisible to the structural and render lanes; found by the browser lane. A new test pins every `keydown.*` filter to one Stimulus recognises.

- `.btn-text` used a `focus-visible:ring-*` box-shadow ring, the same defect fixed in `.btn-*` earlier but with a different prefix — so text buttons would have lost their outline focus indicator when COMBOS switched to class names. Now `@apply focus-ring`, matching the reference app. The per-tone `focus-visible:ring-<colour>` declarations on `.btn-text-interactive`/`.btn-text-danger` existed only to colour that ring and are removed.

- `trigger_class:` on Popover and DropdownMenu **replaced** the trigger's classes instead of merging, so a caller restyling the trigger silently removed its focus indicator (WCAG 2.4.11) and 44px target-size floor (2.5.5 AAA) — from the one element the components document as "a real `<button>` trigger". Caller classes are now merged over a non-replaceable `TRIGGER_BASE`. Default rendering is unchanged. (#100)

- **The `focus-ring` utility now ships.** It is emitted by 47 component templates but was never defined in `modelrails_ui.css`, and Tailwind drops unresolvable classes silently — so in every install the design system's own AAA focus treatment (a 2px offset outline on `:focus-visible`) simply did not exist, and components fell back to the browser default. (#98)
- `.btn-primary`, `.btn-secondary`, `.btn-danger` and `.form-input` used a box-shadow focus ring (`focus:ring-*`), which the library's own rules forbid: a ring is clipped by any `overflow: hidden` ancestor and vanishes in forced-colors mode (WCAG 2.4.7). They now `@apply focus-ring`, matching the reference app. `.btn-*` also fired on `:focus` rather than `:focus-visible`, so the indicator appeared on mouse click. (#99)

- Avatar's image-error fallback never fired when the image failed FAST — a quick 404 or a cached failure beats ES-module loading, so the `error` event was dispatched before the controller connected and nothing was listening. The controller now also checks `complete && naturalWidth === 0` on connect. Found by the new browser lane on its first run.

- Avatar was absent from the accessibility tree after its image failed to load. The `<img>` carries the accessible name and is removed on failure, so the standby initials — hardcoded `aria-hidden` — left screen-reader users with nothing where sighted users saw initials. Both nodes are named now; `hidden` keeps only one exposed.
- A caller-supplied `data:` on Avatar clobbered the Stimulus wiring and silently disabled the image-error fallback. The wiring is merged over caller data now.
- A DropdownMenu submenu stayed open when its parent menu closed — `aria-expanded="true"` while the menu was shut, and already expanded on reopen. The parent now closes its submenus.

- Command emitted a constant listbox id, so two palettes on a page produced duplicate ids and the `aria-controls` pointing at one resolved to whichever rendered first. Ids are per-instance now — the same bug fixed in Combobox.
- Combobox and Command minted option ids from a hardcoded prefix with a per-instance counter, so two instances each produced `-option-0` and `aria-activedescendant` named an ambiguous node. Prefixes derive from the host element's id.

- Popover `side: :left`/`:right` rendered the panel ON its trigger instead of beside it. The old maps emitted both `left-0` and `right-full`, and CSS drops `right` when left, width and right are all set. Anchor positioning replaces the pair with one cell per placement, and every `side` × `align` cell is now covered by a test.
- Combobox emitted a hardcoded listbox id, so two comboboxes on a page produced duplicate ids and `aria-controls` resolved to whichever rendered first. Ids are now per-instance. **UI::Command still has this bug.**
- Generator no longer drops unrecognised template files silently — it says which file it skipped. A plain `.js` in a template directory used to vanish with no warning and no pin, leaving a bare-specifier import that throws at runtime.

- The two status files contradicted each other. README's "Known gaps" and `MODELRAILS_STATUS.md` both said `form_field`, `qr_code`, `input_otp` and `embed` were broken and must not be used, while `COMPONENT_STATUS.md` listed all 82 components as proven or hardened. The pessimistic pair was stale: all four generate and render, verified on Ruby 4.0.5 with 6, 8, 8 and 16 passing render tests.

- form_field docs: stale `view_primitives` generator name; corrected hint/error co-rendering claim (#114).

## [0.9.0] - 2026-08-16

### Added

- FileInput: opt-in `show_selection:` renders a pill per selected file name plus an always-present sr-only `aria-live` announcement — native `multiple` inputs only show a count, never which files. `selection_labels:` takes host-supplied strings (`one:`/`many:`/`none:`, literal `%{count}`/`%{names}` placeholders; i18n lives in the host). Default mode renders the bare input unchanged. Ships a component-own `file-input` Stimulus controller (auto-vendored alongside the component); pills reuse the proven badge soft/primary cell — no new AAA pairing.
- **Migration note:** Running `rails g modelrails_ui:add file_input` regenerates local copies and may overwrite your edits if you have drift. Diff before regenerating; manual integration of changes is safe.

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
