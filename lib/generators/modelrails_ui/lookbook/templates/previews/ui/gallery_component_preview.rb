# frozen_string_literal: true

module UI
  # # Gallery
  #
  # A responsive image grid. With `lightbox: true` (default) each cell is a
  # focusable `<button>` that opens a single shared native `<dialog>` (the reused
  # `modal` controller — focus-trap / Escape / restore for free). The `gallery`
  # controller swaps the dialog image's `src`/`alt`/caption before `modal#open`
  # runs, and — with more than one image — the dialog gains prev/next buttons
  # and a counter bar (`LightboxComponent`, also renderable standalone).
  #
  # ## Accessibility contract
  # - **Guarantees:** each enlargeable cell is a real `<button>` with an i18n
  #   accessible name ("Enlarge %{alt}") and the `focus-ring` utility; the lightbox
  #   is a native focus-trapped `<dialog>` with an accessible close button, and
  #   (with 2+ images) accessible prev/next buttons plus Left/Right arrow keys.
  # - **You supply:** a non-blank `alt:` per image when lightbox is on (fail-loud).
  #
  # ## Related
  # `dialog` · `image` · `carousel`
  # @logical_path Media
  class GalleryComponentPreview < ViewComponent::Preview
    include UIHelper

    # A 3-up lightbox grid. Click (or keyboard-activate) any cell to enlarge it.
    def default
    end

    # Multiple images with captions: the lightbox shows prev/next nav, a
    # caption, and a counter ("1 / 3"). Left/Right arrow keys also navigate.
    def multiple_images
    end
  end
end
