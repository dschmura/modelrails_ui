# Media Band Hardening — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the 5 media components (`audio`, `video`, `gallery`, `carousel`, `embed`) to the program's button-tier DoD and prove them AAA, taking the ledger 55 → 60 proven.

**Architecture:** Each component follows the established groove — harden the gem template + write a 0a render test, then app-side vendor + template-backed preview + 0b preview-host axe spec, then flip the `COMPONENT_STATUS.md` row to `proven` after app CI is green. Gem work is worktree-parallel, bundled into one gem PR on `harden/media`; app work is one branch / one PR. Gallery's lightbox reuses the Wave-4 `modal` controller (native `<dialog>`); carousel gets a full APG-basic + WCAG-2.2.2 rework.

**Tech Stack:** Ruby 4.0.5 (gem), ViewComponent 4.11, Stimulus, TailwindCSS 4 (OKLCH semantic tokens), Capybara + Playwright + axe-core (wcag2aaa in CI), Minitest (gem render harness), RSpec (app).

Design doc: `docs/design/2026-06-09-media-band-hardening-plan.md`. Locked decisions D1–D4 there.

---

## Conventions (apply to every task)

- **Gem toolchain:** `PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake` (NOT mise exec; gem `.ruby-version` is 4.0.5). `rake` = `test:structural` + `test:render` + `rubocop`.
- **App toolchain:** `mise exec -- bundle exec rspec ...`; full suite via the pre-push path.
- **i18n:** render-time `t("ui.<name>.<key>", default: "…")` (the banner pattern — resolved in the view context, never in `initialize`). Interpolation: `t("ui.carousel.slide", n: i + 1, count: n, default: "%{n} of %{count}")`.
- **Fail-loud guard:** mirror banner's `resolve_variant` — coerce to a symbol, return if in the allow-list, else `raise ArgumentError, "unknown … — use one of …"`. Render test asserts the raise with `assert_raises(ArgumentError)` + `assert_match`.
- **Focus:** the `focus-ring` utility, never `focus:ring-*`/`focus-visible:ring-*`.
- **0b specs:** `let(:scope) { [...] }` — NEVER `SCOPE = …` in a `describe` block (leaks to `::SCOPE`, collides across specs). Use the banner spec shape: `expect(axe_clean_in_both_themes?(include: scope)).to be(true), axe_violations_in_both_themes(include: scope).join("\n")`.
- **AAA is CI-only.** A local 0b runs axe at AA. Do not claim AAA from a local run — push and read CI. Do not pre-guess token contrast failures.
- **Commits:** Conventional Commits; no `Co-Authored-By` trailer.

---

## Phase A — Gem hardening (worktree-parallel)

### Task A0: Set up parallel worktrees

**Files:** none (git plumbing). Branch `harden/media` already exists off `modelrails/harden` with the two design docs committed.

- [ ] **Step 1: Create one worktree per component**

```bash
cd ~/Documents/code/modelrails_ui
for c in audio video gallery carousel embed; do
  git worktree add "/private/tmp/mrui-wt/$c" -b "harden/media-$c" harden/media
done
git worktree list
```

Expected: 5 worktrees listed under `/private/tmp/mrui-wt/`.

- [ ] **Step 2: Confirm the render harness runs in a worktree**

```bash
cd /private/tmp/mrui-wt/audio && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test:render 2>&1 | tail -5
```

Expected: existing render tests PASS (baseline green before changes).

---

### Task A1: Harden `audio` (light)

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/audio/audio_component.rb.tt`
- Create: `test/render/audio_render_test.rb`

Worktree: `/private/tmp/mrui-wt/audio`.

- [ ] **Step 1: Write the failing render test**

```ruby
# test/render/audio_render_test.rb
# frozen_string_literal: true

require "render_test_helper"
load_component "audio", "audio_component.rb.tt"

class AudioRenderTest < ViewComponent::TestCase
  def test_renders_audio_with_controls_and_metadata_preload
    render_inline(UI::AudioComponent.new)

    assert_selector "audio[controls][preload='metadata']", visible: :all
  end

  def test_renders_source_children
    render_inline(UI::AudioComponent.new) do |a|
      a.with_source(src: "/a.mp3", type: "audio/mpeg")
    end

    assert_selector "audio source[src='/a.mp3'][type='audio/mpeg']", visible: :all
  end

  def test_autoplay_implies_muted_is_caller_responsibility_but_flags_render
    render_inline(UI::AudioComponent.new(autoplay: true, muted: true))

    assert_selector "audio[autoplay][muted]", visible: :all
  end

  def test_unknown_preload_raises
    error = assert_raises(ArgumentError) { render_inline(UI::AudioComponent.new(preload: :nope)) }

    assert_match(/preload/, error.message)
  end

  def test_merges_caller_classes
    render_inline(UI::AudioComponent.new(class: "w-full"))

    assert_selector "audio.w-full", visible: :all
  end
end
```

- [ ] **Step 2: Run it; verify the preload test fails**

```bash
cd /private/tmp/mrui-wt/audio && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test:render TEST=test/render/audio_render_test.rb 2>&1 | tail -15
```

Expected: FAIL on `test_unknown_preload_raises` (`:nope` is silently accepted today).

- [ ] **Step 3: Harden the template**

Add a `PRELOADS` allow-list + `coerce_preload`, route `preload` through it, and use `cn(@extra_class)`:

```ruby
# inside class AudioComponent
PRELOADS = %i[auto metadata none].freeze

def initialize(controls: true, autoplay: false, muted: false,
               loop: false, preload: :metadata, **html_attrs)
  @controls = controls
  @autoplay = autoplay
  @muted    = muted
  @loop     = loop
  @preload  = coerce_preload(preload)
  @extra_class = html_attrs.delete(:class)
  @html_attrs  = html_attrs
end

def call
  attrs = { preload: @preload, class: cn(@extra_class) }
  attrs[:controls] = true if @controls
  attrs[:autoplay] = true if @autoplay
  attrs[:muted]    = true if @muted
  attrs[:loop]     = true if @loop

  content_tag(:audio, **attrs, **@html_attrs) do
    sources.each { |s| concat s }
    concat content if content?
  end
end

private

# Fail loud so a typo'd preload is caught immediately (not silently dropped to the attr).
def coerce_preload(value)
  sym = value.to_sym
  return sym if PRELOADS.include?(sym)

  raise ArgumentError, "unknown preload #{value.inspect} — use one of #{PRELOADS.join(', ')}"
end
```

- [ ] **Step 4: Run the render test; verify green**

```bash
cd /private/tmp/mrui-wt/audio && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake 2>&1 | tail -8
```

Expected: `test:structural` + `test:render` PASS, `rubocop` 0 offenses.

- [ ] **Step 5: Commit**

```bash
cd /private/tmp/mrui-wt/audio
git add lib/generators/modelrails_ui/add/templates/audio/audio_component.rb.tt test/render/audio_render_test.rb
git commit -m "feat(ui): harden audio — fail-loud preload guard + render test (0a)"
```

---

### Task A2: Harden `video` (light–medium)

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/video/video_component.rb.tt` (the `TrackComponent`)
- Create: `test/render/video_render_test.rb`

Worktree: `/private/tmp/mrui-wt/video`.

- [ ] **Step 1: Write the failing render test**

```ruby
# test/render/video_render_test.rb
# frozen_string_literal: true

require "render_test_helper"
load_component "video", "video_component.rb.tt"

class VideoRenderTest < ViewComponent::TestCase
  def test_renders_video_with_controls_and_max_width_token
    render_inline(UI::VideoComponent.new)

    assert_selector "video.max-w-full[controls][preload='metadata']", visible: :all
  end

  def test_poster_and_playsinline
    render_inline(UI::VideoComponent.new(poster: "/p.jpg"))

    assert_selector "video[poster='/p.jpg'][playsinline]", visible: :all
  end

  def test_autoplay_forces_muted
    render_inline(UI::VideoComponent.new(autoplay: true))

    assert_selector "video[autoplay][muted]", visible: :all
  end

  def test_renders_source_and_track_children
    render_inline(UI::VideoComponent.new) do |v|
      v.with_source(src: "/v.mp4", type: "video/mp4")
      v.with_track(src: "/en.vtt", kind: :captions, label: "English", srclang: "en", default: true)
    end

    assert_selector "video source[src='/v.mp4'][type='video/mp4']", visible: :all
    assert_selector "video track[src='/en.vtt'][kind='captions'][label='English'][srclang='en'][default]", visible: :all
  end

  def test_unknown_track_kind_raises
    error = assert_raises(ArgumentError) do
      render_inline(UI::VideoComponent.new) { |v| v.with_track(src: "/x.vtt", kind: :subtitels) }
    end

    assert_match(/kind/, error.message)
  end
end
```

- [ ] **Step 2: Run it; verify the track-kind test fails**

```bash
cd /private/tmp/mrui-wt/video && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test:render TEST=test/render/video_render_test.rb 2>&1 | tail -15
```

Expected: FAIL on `test_unknown_track_kind_raises` (today `:subtitels` silently coerces to `:subtitles`).

- [ ] **Step 3: Harden `TrackComponent` — replace the silent fallback with a fail-loud guard**

```ruby
# inside class TrackComponent
KINDS = %i[subtitles captions descriptions chapters metadata].freeze

def initialize(src:, kind: :subtitles, label: nil, srclang: nil, default: false, **html_attrs)
  @src     = src
  @kind    = coerce_kind(kind)
  @label   = label
  @srclang = srclang
  @default = default
  @html_attrs = html_attrs
end

private

# Was: KINDS.include?(kind.to_sym) ? kind.to_sym : :subtitles — a typo'd kind silently
# became :subtitles. Fail loud instead (the program's canonical silent-fallback defect).
def coerce_kind(value)
  sym = value.to_sym
  return sym if KINDS.include?(sym)

  raise ArgumentError, "unknown track kind #{value.inspect} — use one of #{KINDS.join(', ')}"
end
```

(Leave the rest of `TrackComponent#call` and the outer `VideoComponent` unchanged — `muted if @muted || @autoplay` is already correct.)

- [ ] **Step 4: Run the full rake; verify green**

```bash
cd /private/tmp/mrui-wt/video && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake 2>&1 | tail -8
```

Expected: all green.

- [ ] **Step 5: Commit**

```bash
cd /private/tmp/mrui-wt/video
git add lib/generators/modelrails_ui/add/templates/video/video_component.rb.tt test/render/video_render_test.rb
git commit -m "feat(ui): harden video — fail-loud track kind guard + render test (0a)"
```

---

### Task A3: Harden `gallery` (heavy — lightbox → reuse `modal`)

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/gallery/gallery_component.rb.tt`
- Rewrite: `lib/generators/modelrails_ui/add/templates/gallery/gallery_controller.js`
- Modify: `lib/generators/modelrails_ui/components.rb` (add `gallery` → `modal` to `EXTRA_STIMULUS`)
- Create: `test/render/gallery_render_test.rb`

Worktree: `/private/tmp/mrui-wt/gallery`.

- [ ] **Step 1: Write the failing render test**

```ruby
# test/render/gallery_render_test.rb
# frozen_string_literal: true

require "render_test_helper"
load_component "gallery", "gallery_component.rb.tt"

class GalleryRenderTest < ViewComponent::TestCase
  def gallery
    render_inline(UI::GalleryComponent.new(cols: 2)) do |g|
      g.with_image(src: "/a.jpg", alt: "Photo A")
      g.with_image(src: "/b.jpg", alt: "Photo B", caption: "The coast")
    end
  end

  def test_trigger_is_a_focusable_button_not_a_bare_figure
    gallery

    # WCAG 2.1.1: the lightbox opener must be keyboard-operable.
    assert_selector "button[type='button'][data-gallery-src-param='/a.jpg'][data-gallery-alt-param='Photo A']"
    assert_selector "button[aria-label]", count: 2
  end

  def test_trigger_wires_both_gallery_open_and_modal_open
    gallery

    assert_selector "button[data-action~='gallery#open'][data-action~='modal#open']", count: 2
  end

  def test_renders_one_reusable_dialog_with_modal_targets
    gallery

    assert_selector "dialog[data-modal-target='dialog']", count: 1
    assert_selector "dialog [data-modal-target='panel'] img[data-gallery-target='image']", count: 1, visible: :all
  end

  def test_lightbox_has_an_accessible_close_button
    gallery

    assert_selector "dialog button[data-action~='modal#close'][aria-label].focus-ring"
  end

  def test_grid_wires_both_controllers
    gallery

    assert_selector "div[data-controller~='gallery'][data-controller~='modal']"
  end

  def test_caption_is_not_white_text_over_image
    gallery

    # Caption uses a semantic surface token, not text-white over a gradient.
    assert_no_selector "figcaption.text-white"
  end

  def test_lightbox_false_skips_dialog_and_renders_plain_images
    render_inline(UI::GalleryComponent.new(lightbox: false)) do |g|
      g.with_image(src: "/a.jpg", alt: "")
    end

    assert_no_selector "dialog"
    assert_no_selector "button"
    assert_selector "img[src='/a.jpg']"
  end

  def test_alt_required_when_lightbox_enabled
    error = assert_raises(ArgumentError) do
      render_inline(UI::GalleryComponent.new) { |g| g.with_image(src: "/a.jpg", alt: "") }
    end

    assert_match(/alt/, error.message)
  end
end
```

- [ ] **Step 2: Run it; verify it fails**

```bash
cd /private/tmp/mrui-wt/gallery && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test:render TEST=test/render/gallery_render_test.rb 2>&1 | tail -20
```

Expected: multiple FAILs (no `<button>` trigger, no `<dialog>`, `<figure>`-based today).

- [ ] **Step 3: Rewrite the component template**

```ruby
# frozen_string_literal: true

module UI
  class GalleryComponent < ApplicationComponent
    # Responsive image grid. With lightbox: true (default) each cell is a focusable
    # <button> that opens a single shared native <dialog> (the `modal` controller —
    # focus-trap/escape/restore for free). The `gallery` controller swaps the dialog
    # image's src/alt before `modal#open` runs.
    #
    # Usage:
    #   ui :gallery, cols: 3 do |g|
    #     g.with_image(src: "/img/a.jpg", alt: "Photo A")
    #     g.with_image(src: "/img/b.jpg", alt: "The coast", caption: "The coast")
    #   end

    GRID_BASE = "grid gap-2"
    GRID_COLS = {
      1 => "grid-cols-1", 2 => "grid-cols-2", 3 => "grid-cols-3",
      4 => "grid-cols-4", 5 => "grid-cols-5", 6 => "grid-cols-6"
    }.freeze

    TRIGGER_CLS = "group relative block w-full cursor-zoom-in overflow-hidden rounded-md focus-ring"
    IMG_CLS     = "h-full w-full object-cover transition-transform duration-300 " \
                  "group-hover:scale-105 motion-reduce:transition-none"
    # Caption sits on a solid tinted surface (AAA), not white text over a gradient image.
    CAP_CLS     = "absolute inset-x-0 bottom-0 bg-surface-overlay/95 px-3 py-2 text-sm text-text-body " \
                  "opacity-0 transition-opacity group-hover:opacity-100 motion-reduce:transition-none"

    DIALOG_CLS  = "m-auto bg-transparent backdrop:bg-black/80 p-4"
    PANEL_CLS   = "relative opacity-0 scale-95"
    LIGHTBOX_IMG_CLS = "max-h-[90vh] max-w-[90vw] rounded-md object-contain"
    CLOSE_CLS   = "absolute -top-2 -right-2 inline-flex size-11 items-center justify-center " \
                  "rounded-full bg-surface-overlay border border-border shadow-sm focus-ring"

    renders_many :images, "UI::GalleryComponent::ImageComponent"

    # cols:      grid columns (1–6, default 3)
    # lightbox:  enable click/keyboard-to-enlarge (default true)
    # aspect:    Tailwind aspect class per cell (default "aspect-square")
    def initialize(cols: 3, lightbox: true, aspect: "aspect-square", **html_attrs)
      @cols        = cols.to_i.clamp(1, 6)
      @lightbox    = lightbox
      @aspect      = aspect
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      validate_alts! if @lightbox

      grid_attrs = { class: cn(GRID_BASE, GRID_COLS[@cols], @extra_class) }
      grid_attrs[:data] = { controller: "gallery modal" } if @lightbox
      grid_attrs.merge!(@html_attrs)

      content_tag(:div, **grid_attrs) do
        body = safe_join(images.map { |img| cell(img) })
        @lightbox ? safe_join([body, lightbox_dialog]) : body
      end
    end

    private

    # An enlargeable image is not decorative — require a non-blank alt (fail loud).
    def validate_alts!
      images.each do |img|
        next if img.alt.present?

        raise ArgumentError, "gallery image #{img.src.inspect} needs a non-blank alt: when lightbox is on " \
                             "(pass lightbox: false for a decorative grid)"
      end
    end

    def cell(img)
      return plain_cell(img) unless @lightbox

      content_tag(:button, type: "button",
        class: cn(TRIGGER_CLS, @aspect),
        "aria-label": t("ui.gallery.enlarge", alt: img.alt, default: "Enlarge %{alt}"),
        data: { action: "gallery#open modal#open",
                gallery_src_param: img.src, gallery_alt_param: img.alt }) do
        caption_wrap(img)
      end
    end

    def plain_cell(img)
      content_tag(:figure, class: cn(TRIGGER_CLS.sub("cursor-zoom-in", "").sub("focus-ring", ""), @aspect)) do
        caption_wrap(img)
      end
    end

    def caption_wrap(img)
      inner = [img]
      inner << content_tag(:figcaption, img.caption, class: CAP_CLS) if img.caption
      safe_join(inner)
    end

    def lightbox_dialog
      content_tag(:dialog, class: DIALOG_CLS, data: { modal_target: "dialog" }) do
        content_tag(:div, class: PANEL_CLS, data: { modal_target: "panel" }) do
          safe_join([
            tag.img(class: LIGHTBOX_IMG_CLS, alt: "", data: { gallery_target: "image" }),
            close_button
          ])
        end
      end
    end

    def close_button
      content_tag(:button, close_icon, type: "button",
        "aria-label": t("ui.gallery.close", default: "Close"),
        class: CLOSE_CLS, data: { action: "click->modal#close" })
    end

    def close_icon
      raw('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" ' \
          'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' \
          '<path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>')
    end

    class ImageComponent < ApplicationComponent
      attr_reader :src, :alt, :caption

      def initialize(src:, alt: "", caption: nil, **html_attrs)
        @src     = src
        @alt     = alt
        @caption = caption
        @html_attrs = html_attrs
      end

      def call
        tag.img(src: @src, alt: @alt, class: GalleryComponent::IMG_CLS, loading: "lazy", **@html_attrs)
      end
    end
  end
end
```

- [ ] **Step 4: Rewrite the colocated controller as a thin coordinator**

```javascript
// lib/generators/modelrails_ui/add/templates/gallery/gallery_controller.js
import { Controller } from "@hotwired/stimulus"

// Thin coordinator: on a trigger click it sets the shared dialog image's src/alt,
// then the SAME action string runs `modal#open` (focus-trap/escape/restore live in
// the reused modal controller — see EXTRA_STIMULUS). No overlay is hand-built here.
export default class extends Controller {
  static targets = ["image"]

  open({ params: { src, alt } }) {
    this.imageTarget.src = src
    this.imageTarget.alt = alt || ""
  }
}
```

- [ ] **Step 5: Register the shared `modal` controller for gallery**

In `lib/generators/modelrails_ui/components.rb`, add to `EXTRA_STIMULUS`:

```ruby
"gallery" => {source: "dialog/modal_controller.js", name: "modal"},
```

(The `add` generator installs the colocated `gallery_controller.js` automatically and the `EXTRA_STIMULUS` `modal` controller alongside it — `add_generator.rb:86` + `:99`.)

- [ ] **Step 6: Run the full rake; verify green**

```bash
cd /private/tmp/mrui-wt/gallery && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake 2>&1 | tail -10
```

Expected: all green (structural picks up the `components.rb` edit; render passes the new gallery test).

- [ ] **Step 7: Commit**

```bash
cd /private/tmp/mrui-wt/gallery
git add lib/generators/modelrails_ui/add/templates/gallery/ lib/generators/modelrails_ui/components.rb test/render/gallery_render_test.rb
git commit -m "feat(ui): harden gallery — button trigger + reuse modal <dialog> lightbox + render test (0a)"
```

---

### Task A4: Harden `carousel` (heavy — 44px + APG + 2.2.2 + focus-ring)

**Files:**
- Rewrite: `lib/generators/modelrails_ui/add/templates/carousel/carousel_component.rb.tt`
- Rewrite: `lib/generators/modelrails_ui/add/templates/carousel/carousel_controller.js`
- Create: `test/render/carousel_render_test.rb`

Worktree: `/private/tmp/mrui-wt/carousel`.

- [ ] **Step 1: Write the failing render test**

```ruby
# test/render/carousel_render_test.rb
# frozen_string_literal: true

require "render_test_helper"
load_component "carousel", "carousel_component.rb.tt"

class CarouselRenderTest < ViewComponent::TestCase
  def carousel(**opts)
    render_inline(UI::CarouselComponent.new(**opts)) do |c|
      c.with_slide { "one" }
      c.with_slide { "two" }
      c.with_slide { "three" }
    end
  end

  def test_root_is_a_carousel_group
    carousel

    assert_selector "div[role='group'][aria-roledescription='carousel'][aria-label]"
  end

  def test_each_slide_is_a_labelled_slide_group
    carousel

    assert_selector "[role='group'][aria-roledescription='slide']", count: 3
    assert_selector "[aria-roledescription='slide'][aria-label='1 of 3']"
    assert_selector "[aria-roledescription='slide'][aria-label='3 of 3']"
  end

  def test_prev_next_are_44px_and_use_focus_ring_not_a_ring
    carousel

    assert_selector "button.size-11.focus-ring[aria-label]", minimum: 2
    assert_no_selector "[class*='focus-visible:ring']"
  end

  def test_dots_carry_a_44px_target_and_aria_current
    carousel

    assert_selector "[data-carousel-target='dots'] button.size-11[aria-current]", count: 3
    assert_selector "[data-carousel-target='dots'] button[aria-current='true']", count: 1
  end

  def test_pause_button_present_only_when_autoplay_set
    carousel(autoplay: 4000)

    assert_selector "button[data-carousel-target='pause'][aria-label]"
  end

  def test_no_pause_button_without_autoplay
    carousel

    assert_no_selector "[data-carousel-target='pause']"
  end

  def test_live_region_starts_off
    carousel

    assert_selector "[data-carousel-target='status'][aria-live='off']", visible: :all
  end

  def test_root_wires_hover_focus_suspend_resume
    carousel(autoplay: 4000)

    assert_selector "div[data-action~='mouseenter->carousel#suspend'][data-action~='focusout->carousel#resume']"
  end
end
```

- [ ] **Step 2: Run it; verify it fails**

```bash
cd /private/tmp/mrui-wt/carousel && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test:render TEST=test/render/carousel_render_test.rb 2>&1 | tail -20
```

Expected: multiple FAILs (no roles, `size-9` not `size-11`, `focus-visible:ring` present, no pause/status).

- [ ] **Step 3: Rewrite the component template**

```ruby
# frozen_string_literal: true

module UI
  class CarouselComponent < ApplicationComponent
    # Slide carousel (APG "basic" pattern): prev/next + slide-picker dots, all real
    # <button>s with ≥44px targets. Autoplay (when > 0) is WCAG 2.2.2 compliant — a
    # pause/play toggle, pause on hover/focus, disabled under prefers-reduced-motion.
    #
    # Usage:
    #   ui :carousel, label: "Featured photos" do |c|
    #     c.with_slide { image_tag "slide1.jpg" }
    #     c.with_slide { image_tag "slide2.jpg" }
    #   end

    TRACK_CLS = "flex transition-transform duration-300 motion-reduce:transition-none"
    SLIDE_CLS = "min-w-full shrink-0"

    BTN_BASE  = "absolute top-1/2 z-10 -translate-y-1/2 inline-flex size-11 items-center justify-center " \
                "rounded-full bg-surface-raised/80 backdrop-blur border border-border shadow-sm " \
                "transition hover:bg-surface-raised disabled:opacity-40 focus-ring"
    BTN_PREV  = "left-2"
    BTN_NEXT  = "right-2"

    PAUSE_CLS = "absolute bottom-2 right-2 z-10 inline-flex size-11 items-center justify-center " \
                "rounded-full bg-surface-raised/80 backdrop-blur border border-border shadow-sm focus-ring"

    DOTS_CLS  = "mt-3 flex justify-center gap-0.5"
    # 44px hit area carries an 8px visual dot via ::before (target-size without a giant dot).
    DOT_CLS   = "grid size-11 place-items-center rounded-full focus-ring " \
                "before:size-2 before:rounded-full before:bg-text-muted/40 before:transition " \
                "aria-[current=true]:before:w-4 aria-[current=true]:before:bg-interactive"

    CHEVRON_L = "m15 18-6-6 6-6"
    CHEVRON_R = "m9 18 6-6-6-6"
    PLAY_PATH  = "m6 3 14 9-14 9z"
    PAUSE_PATH = "M6 4h4v16H6zM14 4h4v16h-4z"

    renders_many :slides

    # loop:        wrap at the ends (default true)
    # indicators:  show dots (default true)
    # autoplay:    interval ms, 0 = off (default 0)
    # label:       accessible name for the carousel region (i18n default "Carousel")
    def initialize(loop: true, indicators: true, autoplay: 0, label: nil, **html_attrs)
      @loop        = loop
      @indicators  = indicators
      @autoplay    = autoplay.to_i
      @label       = label
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div,
        class: cn("relative overflow-hidden", @extra_class),
        role: "group",
        "aria-roledescription": "carousel",
        "aria-label": @label || t("ui.carousel.label", default: "Carousel"),
        data: root_data,
        **@html_attrs) do
        concat track
        concat prev_btn
        concat next_btn
        concat pause_btn if @autoplay.positive?
        concat dots if @indicators && slides.size > 1
        concat live_region
      end
    end

    private

    def root_data
      data = {
        controller: "carousel",
        carousel_loop_value: @loop,
        carousel_autoplay_value: @autoplay
      }
      # Pause on hover/focus; resume on leave/blur (only if it was autoplaying).
      data[:action] = "mouseenter->carousel#suspend mouseleave->carousel#resume " \
                      "focusin->carousel#suspend focusout->carousel#resume" if @autoplay.positive?
      data
    end

    def track
      content_tag(:div, class: TRACK_CLS, data: { carousel_target: "track" }) do
        safe_join(slides.each_with_index.map { |s, i| slide(s, i) })
      end
    end

    def slide(content, index)
      content_tag(:div, content,
        class: SLIDE_CLS,
        role: "group",
        "aria-roledescription": "slide",
        "aria-label": t("ui.carousel.slide", n: index + 1, count: slides.size, default: "%{n} of %{count}"))
    end

    def prev_btn
      control_btn(BTN_PREV, t("ui.carousel.previous", default: "Previous slide"), "carousel#prev", CHEVRON_L)
    end

    def next_btn
      control_btn(BTN_NEXT, t("ui.carousel.next", default: "Next slide"), "carousel#next", CHEVRON_R)
    end

    def control_btn(pos, label, action, path)
      content_tag(:button, chevron(path),
        type: "button", class: cn(BTN_BASE, pos),
        "aria-label": label, data: { action: "click->#{action}" })
    end

    def pause_btn
      content_tag(:button, icon(PAUSE_PATH),
        type: "button", class: PAUSE_CLS,
        "aria-label": t("ui.carousel.pause", default: "Pause"),
        data: { carousel_target: "pause",
                action: "click->carousel#toggle",
                label_pause: t("ui.carousel.pause", default: "Pause"),
                label_play: t("ui.carousel.play", default: "Play"),
                icon_pause: PAUSE_PATH, icon_play: PLAY_PATH })
    end

    def dots
      content_tag(:div, class: DOTS_CLS, role: "group",
        "aria-label": t("ui.carousel.pick", default: "Choose slide"),
        data: { carousel_target: "dots" }) do
        safe_join(slides.each_with_index.map { |_, i|
          content_tag(:button, nil, type: "button", class: DOT_CLS,
            "aria-label": t("ui.carousel.go_to", n: i + 1, default: "Go to slide %{n}"),
            "aria-current": i.zero?.to_s,
            data: { action: "click->carousel#goTo", carousel_index_param: i })
        })
      end
    end

    # aria-live=off while rotating; the controller flips it to polite when paused.
    def live_region
      content_tag(:div, "", class: "sr-only", "aria-live": "off", data: { carousel_target: "status" })
    end

    def chevron(path)
      icon(path)
    end

    def icon(path)
      content_tag(:svg,
        content_tag(:path, nil, d: path, "stroke-linecap": "round", "stroke-linejoin": "round"),
        class: "size-5", viewBox: "0 0 24 24", fill: "none",
        stroke: "currentColor", "stroke-width": "2", "aria-hidden": "true")
    end
  end
end
```

- [ ] **Step 4: Rewrite the controller**

```javascript
// lib/generators/modelrails_ui/add/templates/carousel/carousel_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "dots", "pause", "status"]
  static values = { loop: { type: Boolean, default: true }, autoplay: { type: Number, default: 0 } }

  connect() {
    this._index = 0
    this._count = this.trackTarget.children.length
    this._reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this._playing = false
    this._suspended = false
    if (this.autoplayValue > 0 && !this._reduced) this.play()
    this._announce()
  }

  disconnect() { this._stop() }

  next() { this._go(this._index + 1) }
  prev() { this._go(this._index - 1) }
  goTo({ params: { index } }) { this._go(index) }

  toggle() { this._playing ? this.pause() : this.play() }

  play() {
    if (this.autoplayValue <= 0 || this._reduced) return
    this._stop()
    this._playing = true
    this._timer = setInterval(() => this.next(), this.autoplayValue)
    this._setPauseUi(true)
    if (this.hasStatusTarget) this.statusTarget.setAttribute("aria-live", "off")
  }

  pause() {
    this._stop()
    this._playing = false
    this._setPauseUi(false)
    if (this.hasStatusTarget) this.statusTarget.setAttribute("aria-live", "polite")
    this._announce()
  }

  // Hover/focus pause — only auto-resume what autoplay started, never override an explicit pause.
  suspend() { if (this._playing) { this._stop(); this._suspended = true } }
  resume() { if (this._suspended) { this._suspended = false; this.play() } }

  _stop() {
    if (this._timer) clearInterval(this._timer)
    this._timer = null
  }

  _go(index) {
    if (this.loopValue) index = ((index % this._count) + this._count) % this._count
    else index = Math.max(0, Math.min(index, this._count - 1))
    this._index = index
    this.trackTarget.style.transform = `translateX(-${index * 100}%)`
    this._updateDots()
    this._announce()
  }

  _updateDots() {
    if (!this.hasDotsTarget) return
    Array.from(this.dotsTarget.children).forEach((dot, i) =>
      dot.setAttribute("aria-current", String(i === this._index)))
  }

  _announce() {
    if (this.hasStatusTarget) this.statusTarget.textContent = `${this._index + 1} / ${this._count}`
  }

  _setPauseUi(playing) {
    if (!this.hasPauseTarget) return
    const t = this.pauseTarget
    t.setAttribute("aria-label", playing ? t.dataset.labelPause : t.dataset.labelPlay)
    const path = t.querySelector("path")
    if (path) path.setAttribute("d", playing ? t.dataset.iconPause : t.dataset.iconPlay)
    t.dataset.playing = String(playing)
  }
}
```

- [ ] **Step 5: Run the full rake; verify green**

```bash
cd /private/tmp/mrui-wt/carousel && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake 2>&1 | tail -10
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
cd /private/tmp/mrui-wt/carousel
git add lib/generators/modelrails_ui/add/templates/carousel/ test/render/carousel_render_test.rb
git commit -m "feat(ui): harden carousel — APG basic ARIA + 44px + compliant autoplay + focus-ring + render test (0a)"
```

---

### Task A5: Harden `embed` (light–medium — i18n + comment)

**Files:**
- Modify: `lib/generators/modelrails_ui/add/templates/embed/embed_component.rb.tt`
- Create: `test/render/embed_render_test.rb`

Worktree: `/private/tmp/mrui-wt/embed`.

- [ ] **Step 1: Write the failing render test**

```ruby
# test/render/embed_render_test.rb
# frozen_string_literal: true

require "render_test_helper"
load_component "embed", "embed_component.rb.tt"

class EmbedRenderTest < ViewComponent::TestCase
  def test_youtube_iframe_has_accessible_title_and_lazy_loading
    render_inline(UI::EmbedComponent.new(url: "https://youtu.be/dQw4w9WgXcQ"))

    assert_selector "iframe[title='YouTube video'][loading='lazy']", visible: :all
    assert_selector "iframe[src*='youtube.com/embed/dQw4w9WgXcQ']", visible: :all
  end

  def test_caller_title_overrides_default
    render_inline(UI::EmbedComponent.new(url: "https://youtu.be/abc", title: "Launch keynote"))

    assert_selector "iframe[title='Launch keynote']", visible: :all
  end

  def test_iframe_title_is_never_blank
    render_inline(UI::EmbedComponent.new(url: "https://vimeo.com/148751763"))

    assert_selector "iframe[title]", visible: :all
    refute_empty page.find("iframe", visible: :all)[:title]
  end

  def test_unsupported_url_renders_a_danger_message
    render_inline(UI::EmbedComponent.new(url: "https://example.com/nope"))

    assert_selector "p.text-danger"
  end
end
```

- [ ] **Step 2: Run it; verify the baseline**

```bash
cd /private/tmp/mrui-wt/embed && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake test:render TEST=test/render/embed_render_test.rb 2>&1 | tail -15
```

Expected: PASS or FAIL depending on `unsupported_msg` text; the point is to lock behavior. (If all pass, the i18n change in Step 3 is a no-output-change refactor; still required for the DoD.)

- [ ] **Step 3: i18n the strings + comment the letterbox**

Replace the hardcoded user-facing strings and annotate `bg-black`:

```ruby
# DARK_WRAPPER_CLS: bg-black is an intentional letterbox backdrop for media iframes —
# a media surface, not a text-contrast surface (so no semantic token applies).
DARK_WRAPPER_CLS = "overflow-hidden rounded-md bg-black"

def unsupported_msg
  content_tag(:p,
    t("ui.embed.unsupported", type: @type, default: "Unsupported embed type: %{type}"),
    class: "text-sm text-danger")
end

TITLES = {
  youtube:     "YouTube video",
  vimeo:       "Vimeo video",
  spotify:     "Spotify player",
  google_maps: "Google Maps",
  yandex_maps: "Yandex Maps",
  loom:        "Loom video",
  soundcloud:  "SoundCloud player",
  x:           "Post on X",
  telegram:    "Telegram post",
  facebook:    "Facebook video"
}.freeze

def default_title
  t("ui.embed.titles.#{@type}", default: TITLES.fetch(@type, "Embedded content"))
end
```

Note: `default_title` is called in `initialize` today. Move the `@title` resolution into a render-time
reader so `t` has a view context, mirroring banner's `region_label`:

```ruby
def initialize(url: nil, query: nil, aspect: nil, height: nil, title: nil, **html_attrs)
  @type   = query ? :google_maps : self.class.detect_provider(url)
  @url    = url
  @query  = query
  @aspect = aspect || PROVIDERS.dig(@type, :aspect)
  @height = height || default_height
  @title_override = title           # was: @title = title || default_title
  @extra_class = html_attrs.delete(:class)
  @html_attrs  = html_attrs
end

# Resolve at render time (t needs the view context).
def title
  @title_override || default_title
end
```

Then use `title` (the method) wherever `@title` was referenced in `iframe_markup` (e.g. `title: title`).

- [ ] **Step 4: Run the full rake; verify green**

```bash
cd /private/tmp/mrui-wt/embed && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake 2>&1 | tail -8
```

Expected: all green. (Defaults preserve the English strings, so the render test still passes.)

- [ ] **Step 5: Commit**

```bash
cd /private/tmp/mrui-wt/embed
git add lib/generators/modelrails_ui/add/templates/embed/embed_component.rb.tt test/render/embed_render_test.rb
git commit -m "feat(ui): harden embed — i18n unsupported/title + render-time title + render test (0a)"
```

---

### Task A6: Cross-sibling review, bundle, ledger rows, gem PR

**Files:**
- Modify: `COMPONENT_STATUS.md` (5 new rows, tier `hardened`)

- [ ] **Step 1: Cross-sibling consistency review (read the rendered DOM, don't reason)**

Check across the 5: every fail-loud guard raises `ArgumentError` with a "use one of …" message; every new
control uses `focus-ring` (grep for any stray `focus:ring`/`focus-visible:ring`); `t("ui.<name>.…", default:)`
spelling is consistent; attr-merge order is component-wins (set role/aria AFTER spreading `@html_attrs`).

```bash
cd ~/Documents/code/modelrails_ui
git diff modelrails/harden..harden/media-carousel -- '*.tt' '*.js' | grep -nE 'focus-visible:ring|focus:ring' && echo "STRAY RING — fix" || echo "no stray rings"
```

- [ ] **Step 2: Merge the 5 worktree branches into `harden/media`**

```bash
cd ~/Documents/code/modelrails_ui
git checkout harden/media
for c in audio video gallery carousel embed; do git merge --no-ff "harden/media-$c" -m "merge harden/media-$c"; done
```

Expected: 5 clean merges (the only shared file is `components.rb`, edited solely by gallery).

- [ ] **Step 3: Add the ledger rows (tier `hardened` — flips to `proven` after app CI)**

Append to the component table in `COMPONENT_STATUS.md`:

```markdown
| audio | hardened | ✅ | ⏳ | Media band (fail-loud preload guard; native controls; render test) |
| video | hardened | ✅ | ⏳ | Media band (fail-loud track-kind guard; <track> captions; render test) |
| gallery | hardened | ✅ | ⏳ | Media band (figure→button trigger 2.1.1; lightbox reuses modal <dialog> via EXTRA_STIMULUS; caption off text-over-image; alt required when lightbox) |
| carousel | hardened | ✅ | ⏳ | Media band (APG basic ARIA; 44px prev/next+dots; aria-current; compliant autoplay pause/play+hover/focus+reduced-motion w/ aria-live flip; ring→focus-ring; i18n) |
| embed | hardened | ✅ | ⏳ | Media band (i18n unsupported msg + iframe titles; render-time title; bg-black letterbox commented) |
```

- [ ] **Step 4: Full gem rake green, then commit + push + PR**

```bash
cd ~/Documents/code/modelrails_ui && PATH="/Users/dschmura/.local/share/mise/installs/ruby/4.0.5/bin:$PATH" bundle exec rake 2>&1 | tail -10
git add COMPONENT_STATUS.md
git commit -m "docs(status): add media band rows (audio/video/gallery/carousel/embed) — hardened, app-proof pending"
git push -u origin harden/media
gh pr create --repo dschmura/modelrails_ui --base modelrails/harden --head harden/media \
  --title "feat(ui): harden media band — audio/video/gallery/carousel/embed (0a)" \
  --body "Media band hardening (5 components) to button-tier DoD + render tests. See docs/design/2026-06-09-media-band-*. App 0b proof in modelrails_base PR (pending). Ledger rows added as hardened; flip to proven after app CI is green."
```

Expected: gem CI green (Ruby 3.2/3.3/3.4/4.0 + Appraisal 7.2/8.1).

- [ ] **Step 5: Clean up worktrees**

```bash
cd ~/Documents/code/modelrails_ui
for c in audio video gallery carousel embed; do git worktree remove "/private/tmp/mrui-wt/$c"; done
```

---

## Phase B — App adoption + 0b proof

### Task B0: App branch, temp re-pin, vendor the 5

**Files:**
- Modify: `Gemfile` (temporary branch pin — reverted in Task B6)

- [ ] **Step 1: Create the app branch FIRST (branch-before-fan-out)**

```bash
cd ~/Documents/code/modelrails_base
git checkout -b feat/ui-media-band main
git branch --show-current
```

- [ ] **Step 2: Temporarily pin the Gemfile to `harden/media` + bundle**

In `Gemfile`, change the `modelrails_ui` line to `branch: "harden/media"`, then:

```bash
cd ~/Documents/code/modelrails_base && mise exec -- bundle update modelrails_ui 2>&1 | tail -5
```

- [ ] **Step 3: Vendor the 5 hardened components (+ controllers)**

```bash
cd ~/Documents/code/modelrails_base
mise exec -- bin/rails g modelrails_ui:add audio video gallery carousel embed
git status --short app/components/ui app/javascript/controllers
```

Expected: `app/components/ui/{audio,video,gallery,carousel,embed}_component.rb` + colocated
`gallery_controller.js`, `carousel_controller.js`, `embed_controller.js`, and the shared
`modal_controller.js` (for gallery, via EXTRA_STIMULUS — should already exist from Wave 4; confirm no clobber).

- [ ] **Step 4: Commit the vendored components**

```bash
git add app/components/ui app/javascript/controllers
git commit -m "feat(ui): vendor hardened media band (audio/video/gallery/carousel/embed)"
```

---

### Tasks B1–B5: Preview + 0b spec per component

For each component: create the preview class + template-backed scenarios, write the 0b spec, run it
locally (AA gate — proves no orphan-label/structure violations; AAA is CI-only), commit. **Use
`let(:scope)`.** Preview files live in `spec/components/previews/ui/<name>_component_preview.rb` (+ a
`<name>_component_preview/` dir of `.html.erb` scenarios). Specs live in `spec/system/ui/<name>_component_spec.rb`.

### Task B1: `audio` preview + 0b

- [ ] **Step 1: Preview**

```ruby
# spec/components/previews/ui/audio_component_preview.rb
# frozen_string_literal: true
module Ui
  class AudioComponentPreview < ViewComponent::Preview
    def default; end
    def multi_source; end
  end
end
```

```erb
<%# spec/components/previews/ui/audio_component_preview/default.html.erb %>
<div data-test="audio">
  <%= render(UI::AudioComponent.new) do |a| %>
    <% a.with_source(src: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.mp3", type: "audio/mpeg") %>
  <% end %>
</div>
```

```erb
<%# spec/components/previews/ui/audio_component_preview/multi_source.html.erb %>
<div data-test="audio">
  <%= render(UI::AudioComponent.new(loop: true)) do |a| %>
    <% a.with_source(src: "/audio/clip.ogg", type: "audio/ogg") %>
    <% a.with_source(src: "/audio/clip.mp3", type: "audio/mpeg") %>
  <% end %>
</div>
```

- [ ] **Step 2: 0b spec**

```ruby
# spec/system/ui/audio_component_spec.rb
# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Audio component accessibility", type: :system do
  let(:scope) { [ "[data-test='audio']" ] }

  def expect_aaa_in_both_themes
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true), axe_violations_in_both_themes(include: scope).join("\n")
    )
  end

  it "default: native audio controls pass AAA in both themes" do
    visit "/rails/view_components/ui/audio_component/default"

    expect(page).to have_css("audio", visible: :all)
    expect_aaa_in_both_themes
  end

  it "multi_source: multiple sources pass AAA in both themes" do
    visit "/rails/view_components/ui/audio_component/multi_source"

    expect(page).to have_css("audio", visible: :all)
    expect_aaa_in_both_themes
  end
end
```

- [ ] **Step 3: Run + commit**

```bash
cd ~/Documents/code/modelrails_base && mise exec -- bundle exec rspec spec/system/ui/audio_component_spec.rb 2>&1 | tail -8
git add spec/components/previews/ui/audio_component_preview* spec/system/ui/audio_component_spec.rb
git commit -m "test(ui): audio preview + 0b axe spec"
```

Expected: 2 examples, 0 failures (local AA).

### Task B2: `video` preview + 0b

- [ ] **Step 1: Preview** (`default` with poster, `captions` with a `<track>`)

```ruby
# spec/components/previews/ui/video_component_preview.rb
# frozen_string_literal: true
module Ui
  class VideoComponentPreview < ViewComponent::Preview
    def default; end
    def captions; end
  end
end
```

```erb
<%# .../video_component_preview/default.html.erb %>
<div data-test="video">
  <%= render(UI::VideoComponent.new(poster: "https://picsum.photos/640/360")) do |v| %>
    <% v.with_source(src: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4", type: "video/mp4") %>
  <% end %>
</div>
```

```erb
<%# .../video_component_preview/captions.html.erb %>
<div data-test="video">
  <%= render(UI::VideoComponent.new) do |v| %>
    <% v.with_source(src: "/video/demo.mp4", type: "video/mp4") %>
    <% v.with_track(src: "/video/en.vtt", kind: :captions, label: "English", srclang: "en", default: true) %>
  <% end %>
</div>
```

- [ ] **Step 2: 0b spec** (same shape; `let(:scope) { ["[data-test='video']"] }`; scenarios `default`, `captions`; assert `have_css("video", visible: :all)` and for captions `have_css("video track[kind='captions']", visible: :all)`).

- [ ] **Step 3: Run + commit**

```bash
mise exec -- bundle exec rspec spec/system/ui/video_component_spec.rb 2>&1 | tail -8
git add spec/components/previews/ui/video_component_preview* spec/system/ui/video_component_spec.rb
git commit -m "test(ui): video preview + 0b axe spec"
```

### Task B3: `gallery` preview + 0b (OUTCOME-asserting)

- [ ] **Step 1: Preview** (`default` lightbox grid)

```ruby
# spec/components/previews/ui/gallery_component_preview.rb
# frozen_string_literal: true
module Ui
  class GalleryComponentPreview < ViewComponent::Preview
    def default; end
  end
end
```

```erb
<%# .../gallery_component_preview/default.html.erb %>
<div data-test="gallery">
  <%= render(UI::GalleryComponent.new(cols: 3)) do |g| %>
    <% g.with_image(src: "https://picsum.photos/id/10/400/400", alt: "Forest canopy") %>
    <% g.with_image(src: "https://picsum.photos/id/20/400/400", alt: "City street", caption: "Downtown") %>
    <% g.with_image(src: "https://picsum.photos/id/30/400/400", alt: "Mountain lake") %>
  <% end %>
</div>
```

- [ ] **Step 2: 0b spec — assert the lightbox OUTCOME, not just structure**

```ruby
# spec/system/ui/gallery_component_spec.rb
# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Gallery component accessibility", type: :system do
  let(:scope) { [ "[data-test='gallery']" ] }

  def expect_aaa_in_both_themes
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true), axe_violations_in_both_themes(include: scope).join("\n")
    )
  end

  it "default: focusable button triggers; AAA in both themes" do
    visit "/rails/view_components/ui/gallery_component/default"

    expect(page).to have_css("[data-test='gallery'] button[aria-label]", count: 3)
    expect(page).to have_css("dialog[data-modal-target='dialog']", visible: :all)
    expect_aaa_in_both_themes
  end

  it "opens the lightbox via keyboard and moves focus into the dialog" do
    visit "/rails/view_components/ui/gallery_component/default"

    first_trigger = find("[data-test='gallery'] button", match: :first)
    first_trigger.native.press("Enter")

    # The shared modal opened the native <dialog> and moved focus inside it.
    expect(page).to have_css("dialog[open]")
    in_dialog = page.evaluate_script("document.activeElement.closest('dialog') !== null")
    expect(in_dialog).to be(true)
    # The coordinator set the dialog image to the clicked thumbnail.
    expect(page).to have_css("dialog[open] img[alt='Forest canopy']")
  end

  it "closes on Escape and restores focus to the trigger" do
    visit "/rails/view_components/ui/gallery_component/default"

    find("[data-test='gallery'] button", match: :first).native.press("Enter")
    expect(page).to have_css("dialog[open]")

    page.driver.browser.keyboard.press("Escape") if page.driver.respond_to?(:browser)
    find("body").native.press("Escape")

    expect(page).not_to have_css("dialog[open]")
    restored = page.evaluate_script("document.activeElement?.getAttribute('aria-label')")
    expect(restored).to match(/Forest canopy/)
  end
end
```

> Note: the exact key-press API depends on the Capybara/Playwright driver. If `native.press`
> is unavailable, use `find(...).send_keys(:enter)` / `send_keys(:escape)`. Adjust to whatever
> the existing dialog 0b spec (`spec/system/ui/dialog_component_spec.rb`) uses — copy that idiom.

- [ ] **Step 3: Run + commit**

```bash
mise exec -- bundle exec rspec spec/system/ui/gallery_component_spec.rb 2>&1 | tail -12
git add spec/components/previews/ui/gallery_component_preview* spec/system/ui/gallery_component_spec.rb
git commit -m "test(ui): gallery preview + 0b axe spec (lightbox open/focus/escape outcome)"
```

### Task B4: `carousel` preview + 0b (OUTCOME-asserting)

- [ ] **Step 1: Preview** (`default` manual, `autoplay` with pause button)

```ruby
# spec/components/previews/ui/carousel_component_preview.rb
# frozen_string_literal: true
module Ui
  class CarouselComponentPreview < ViewComponent::Preview
    def default; end
    def autoplay; end
  end
end
```

```erb
<%# .../carousel_component_preview/default.html.erb %>
<div data-test="carousel" class="max-w-md">
  <%= render(UI::CarouselComponent.new(label: "Featured photos")) do |c| %>
    <% c.with_slide { tag.img(src: "https://picsum.photos/id/11/600/300", alt: "Slide one", class: "w-full") } %>
    <% c.with_slide { tag.img(src: "https://picsum.photos/id/12/600/300", alt: "Slide two", class: "w-full") } %>
    <% c.with_slide { tag.img(src: "https://picsum.photos/id/13/600/300", alt: "Slide three", class: "w-full") } %>
  <% end %>
</div>
```

```erb
<%# .../carousel_component_preview/autoplay.html.erb %>
<div data-test="carousel" class="max-w-md">
  <%= render(UI::CarouselComponent.new(label: "Auto gallery", autoplay: 3000)) do |c| %>
    <% c.with_slide { tag.img(src: "https://picsum.photos/id/14/600/300", alt: "Auto one", class: "w-full") } %>
    <% c.with_slide { tag.img(src: "https://picsum.photos/id/15/600/300", alt: "Auto two", class: "w-full") } %>
  <% end %>
</div>
```

- [ ] **Step 2: 0b spec — assert slide transform + aria-current + pause flips aria-live**

```ruby
# spec/system/ui/carousel_component_spec.rb
# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Carousel component accessibility", type: :system do
  let(:scope) { [ "[data-test='carousel']" ] }

  def expect_aaa_in_both_themes
    expect(axe_clean_in_both_themes?(include: scope)).to(
      be(true), axe_violations_in_both_themes(include: scope).join("\n")
    )
  end

  it "default: carousel group + slide labels; AAA in both themes" do
    visit "/rails/view_components/ui/carousel_component/default"

    expect(page).to have_css("[role='group'][aria-roledescription='carousel'][aria-label='Featured photos']")
    expect(page).to have_css("[aria-roledescription='slide']", count: 3)
    expect_aaa_in_both_themes
  end

  it "Next actually translates the track and moves aria-current (outcome, not wiring)" do
    visit "/rails/view_components/ui/carousel_component/default"

    expect(page).to have_css("[data-carousel-target='dots'] button[aria-current='true']:first-child")
    find("button[aria-label='Next slide']").click

    transform = page.evaluate_script(
      "getComputedStyle(document.querySelector('[data-carousel-target=track]')).transform"
    )
    expect(transform).not_to eq("none")          # the track moved
    expect(page).to have_css("[data-carousel-target='dots'] button:nth-child(2)[aria-current='true']")
  end

  it "pause flips the live region to polite (WCAG 2.2.2 mechanism)" do
    visit "/rails/view_components/ui/carousel_component/autoplay"

    expect(page).to have_css("button[data-carousel-target='pause']")
    find("button[data-carousel-target='pause']").click

    expect(page).to have_css("[data-carousel-target='status'][aria-live='polite']", visible: :all)
  end

  it "autoplay: AAA in both themes" do
    visit "/rails/view_components/ui/carousel_component/autoplay"

    expect(page).to have_css("[aria-roledescription='carousel']")
    expect_aaa_in_both_themes
  end
end
```

- [ ] **Step 3: Run + commit**

```bash
mise exec -- bundle exec rspec spec/system/ui/carousel_component_spec.rb 2>&1 | tail -12
git add spec/components/previews/ui/carousel_component_preview* spec/system/ui/carousel_component_spec.rb
git commit -m "test(ui): carousel preview + 0b axe spec (slide transform/aria-current/pause-live outcome)"
```

### Task B5: `embed` preview + 0b

- [ ] **Step 1: Preview** (`youtube`, `map`)

```ruby
# spec/components/previews/ui/embed_component_preview.rb
# frozen_string_literal: true
module Ui
  class EmbedComponentPreview < ViewComponent::Preview
    def youtube; end
    def map; end
  end
end
```

```erb
<%# .../embed_component_preview/youtube.html.erb %>
<div data-test="embed" class="max-w-xl">
  <%= render(UI::EmbedComponent.new(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")) %>
</div>
```

```erb
<%# .../embed_component_preview/map.html.erb %>
<div data-test="embed" class="max-w-xl">
  <%= render(UI::EmbedComponent.new(query: "Eiffel Tower, Paris")) %>
</div>
```

- [ ] **Step 2: 0b spec** (`let(:scope) { ["[data-test='embed']"] }`; assert `have_css("iframe[title]", visible: :all)` per scenario; `expect_aaa_in_both_themes`).

- [ ] **Step 3: Run + commit**

```bash
mise exec -- bundle exec rspec spec/system/ui/embed_component_spec.rb 2>&1 | tail -8
git add spec/components/previews/ui/embed_component_preview* spec/system/ui/embed_component_spec.rb
git commit -m "test(ui): embed preview + 0b axe spec"
```

---

### Task B6: Full suite, app PR (CI proves AAA)

- [ ] **Step 1: Full media 0b run together (catches the SCOPE-collision class)**

```bash
cd ~/Documents/code/modelrails_base && mise exec -- bundle exec rspec spec/system/ui/{audio,video,gallery,carousel,embed}_component_spec.rb 2>&1 | tail -15
```

Expected: all green together (proves no `let(:scope)` collision; if a spec passes alone but fails here, a bare top-level constant leaked — convert to `let`).

- [ ] **Step 2: Full app suite via the pre-push path**

```bash
cd ~/Documents/code/modelrails_base && mise exec -- bin/rails test 2>/dev/null; mise exec -- bundle exec rspec 2>&1 | tail -15
```

Expected: 0 failures (full-suite gate — also catches collateral 0a/0b misses, e.g. a vendored controller colliding with a same-named app controller; grep-usage-before-relying).

- [ ] **Step 3: Push + open the app PR (do NOT re-pin Gemfile yet)**

```bash
git push -u origin feat/ui-media-band
gh pr create --repo dschmura/modelrails_base --base main --head feat/ui-media-band \
  --title "feat(ui): adopt hardened media band — audio/video/gallery/carousel/embed + 0b AAA proofs" \
  --body "Vendors the 5 hardened media components + template-backed previews + 0b preview-host axe specs (AAA in CI both themes). Gallery lightbox reuses the modal <dialog>; carousel is APG-basic + WCAG 2.2.2 compliant. Gemfile temporarily pinned to harden/media — re-pin to modelrails/harden after gem PR merges. Pairs with modelrails_ui media-band PR."
```

Expected: app CI green — the `test` job runs axe at **wcag2aaa (7:1)**; this is the real AAA gate.

---

## Phase C — Merge + ledger flip + re-pin

### Task C1: Merge gem PR, flip ledger, re-pin app

- [ ] **Step 1:** After app CI is green, merge the gem PR (`harden/media` → `modelrails/harden`) using the careful-merge primitive:

```bash
HEAD=$(git -C ~/Documents/code/modelrails_ui rev-parse harden/media)
gh api -X PUT repos/dschmura/modelrails_ui/pulls/<N>/merge -f merge_method=squash -f sha="$HEAD"
```

- [ ] **Step 2:** On `modelrails/harden`, flip the 5 ledger rows `hardened`→`proven` and `⏳`→`✅`:

```bash
cd ~/Documents/code/modelrails_ui && git checkout modelrails/harden && git pull
# edit COMPONENT_STATUS.md: 5 rows → proven / ✅, append "— app PR #<M> AAA-green" to each Notes
git add COMPONENT_STATUS.md
git commit -m "docs(status): flip media band experimental→proven (5 components, gem #<N> + app #<M> AAA-green)"
git push
```

Verify: `grep -cE '^\| .* \| proven \|' COMPONENT_STATUS.md` → **60**.

- [ ] **Step 3:** Re-pin the app Gemfile from `branch: "harden/media"` back to `branch: "modelrails/harden"`, `bundle update modelrails_ui` (content no-op), commit on `feat/ui-media-band`, push. Then merge the app PR (careful-merge primitive against `main`).

- [ ] **Step 4:** Update memory `project_component_hardening_program.md`: media band SHIPPED & PROVEN, 60/81, note any new lessons.

---

## Self-review notes (author)

- **Spec coverage:** D1 (gallery→modal) → A3 + B3; D2 (autoplay compliant) → A4 controller + B4 pause-live spec; D3 (APG basic) → A4 component + B4 group/slide spec; D4 (bg-black comment) → A5 Step 3. All 5 components get 0a (A1–A5) + 0b (B1–B5) + ledger row (A6/C1).
- **Carry-forward gotchas covered:** `let(:scope)` (every B spec + B6 Step 1), AAA-CI-only (B-phase notes + B6 Step 3), branch-before-fan-out (A0 + B0 Step 1), EXTRA_STIMULUS-not-copy (A3 Step 5), focus-ring-not-ring (A4 + A6 Step 1 grep), outcome-asserting 0b (B3/B4), careful-merge primitive (C1).
- **Driver caveat (B3):** the key-press API is driver-specific — B3 explicitly says to copy the existing `dialog_component_spec.rb` idiom rather than guess.
