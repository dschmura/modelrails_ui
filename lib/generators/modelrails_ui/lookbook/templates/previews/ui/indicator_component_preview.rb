# frozen_string_literal: true

module UI
  # # Indicator
  #
  # A small status dot or count badge anchored to the corner of an icon, avatar, or
  # button. Presentational — it conveys nothing on its own to assistive tech.
  #
  # ## Use when
  # - You need a corner dot or count overlaid on an icon/avatar/button.
  #
  # ## Don't use when
  # - The dot is the only carrier of meaning — give the anchored element a name/text.
  #
  # ## Accessibility contract
  # - **Guarantees:** AAA variant treatments (`text-text-on-interactive`, never raw
  #   `text-white`); a valid `variant` is required.
  # - **You supply:** an accessible name on the anchor when the dot is a color-only
  #   signal; the count via `count:`.
  # @logical_path Feedback & Status
  class IndicatorComponentPreview < ViewComponent::Preview
    include UIHelper

    # @!group Examples

    # A bare presence dot on an element.
    def default
    end

    # A count badge.
    def with_count
    end

    # An informational dot — solid info fill.
    def info
    end

    # The semantic variants side by side (info · success · warning · danger).
    def variants
    end

    # @!endgroup

    # @!group Reference

    # Edit the variant, count, and corner live. A blank count renders the bare
    # presence dot. (`destructive` is a non-breaking alias for `danger`.)
    # @param variant select [default, info, success, warning, danger]
    # @param count number
    # @param position select [top_right, top_left, bottom_right, bottom_left]
    def playground(variant: :default, count: 3, position: :top_right)
      render_with_template(locals: {variant: variant.to_sym, count: count, position: position.to_sym})
    end

    # ## Don't — color-only signal
    #
    # This destructive dot is the only thing conveying "error" — there's no text or
    # accessible name on the anchored element, so screen-reader users get nothing.
    # Give the anchor an accessible name/text.
    # @label Don't · color only
    def dont_color_only
    end

    # @!endgroup
  end
end
