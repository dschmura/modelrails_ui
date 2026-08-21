# frozen_string_literal: true

require "system_test_helper"
load_component "avatar", "avatar_component.rb.tt"

BrowserHarness.scenario("avatar/broken_image", controllers: %w[avatar]) do
  view = ActionController::Base.new.view_context
  UI::AvatarComponent.new(src: "/definitely-missing.png", fallback: "DC", aria_label: "Dave Chmura")
    .render_in(view)
end

# The image-failure path is invisible to the render lane: the swap only happens when the
# browser actually attempts the request and fires `error`. This is the bug the 2026-08
# audit found — initials appeared, but the avatar left the accessibility tree entirely.
class AvatarSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("avatar/broken_image")
  end

  def test_initials_replace_the_failed_image
    assert_selector "[data-avatar-target=fallback]", text: "DC"
  end

  # A hidden-but-present <img> would keep announcing a picture that never arrived.
  def test_the_failed_image_is_removed_not_hidden
    assert_selector "[data-avatar-target=fallback]", text: "DC"

    assert_no_selector "img", visible: :all
  end

  # The regression: the standby initials were aria-hidden, so once the <img> was removed
  # the avatar had no accessible name at all.
  def test_the_avatar_keeps_an_accessible_name_after_the_swap
    assert_selector "[data-avatar-target=fallback]", text: "DC"

    assert_selector "[role=img][aria-label='Dave Chmura']"
  end

  def test_the_swapped_avatar_passes_a_structural_axe_audit
    assert_selector "[data-avatar-target=fallback]", text: "DC"

    assert_axe_clean
  end
end
