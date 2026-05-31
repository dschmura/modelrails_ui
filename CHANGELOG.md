# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0.modelrails.1] - modelrails_base hardening fork

Hardened to meet modelrails_base standards (WCAG 2.2 AAA, I18n, the app's OKLCH semantic
tokens, form_builder integration). See `MODELRAILS_STATUS.md` for the solid / pre-release /
broken / kept-app-native breakdown.

### Fixed
- `add` generator: `source_root` called as an instance method (only defined at class level).
- `add` generator: `template`/`copy_file` overrides were public, so Thor auto-invoked them
  with no args — wrapped in `no_commands`.

### Changed
- All component templates re-themed from shadcn tokens to AAA semantic tokens
  (`surface*`, `interactive*`, `danger*`, `text-*`, `border*`); `dark:` variants dropped
  (tokens auto-flip via `.dark`). NOTE: components now expect the host app to define these
  tokens (see MODELRAILS_STATUS.md → Token portability).
- `Input` / `Textarea` / `FileInput`: first-class `required`/`invalid`/`describedby` → ARIA
  params; styling matches the app's form-field constants; dual-mode (form-builder + standalone).
  `FileInput` gained ARIA wiring the app's plain file_field lacked.
- `Dialog`: rewritten onto the native `<dialog>` + `showModal` pattern (focus-trap/restore,
  native Escape, `::backdrop`) adopted from the app's superior modal; ships the app's
  `modal_controller.js`; added `wrapper:` (embed-only) and `body_id:` options.
- `Button`: rewritten to the app's `.btn-*` taxonomy (primary/secondary/danger + text family).
- `Avatar`: app `AVATAR_SIZES`, rounded-full, hue-tinted initials, role=img/aria-hidden semantics.

### Known issues
- Templates that don't generate: `form_field`, `qr_code` (SyntaxError), `input_otp` (undefined helper).
- `embed` calls `CGI.parse` without `require "cgi"` (breaks on Ruby 4.0).
- Gem's own test suite has ~18 tests asserting pre-hardening behavior (see MODELRAILS_STATUS.md).


## [0.1.0] - 2026-05-30

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
