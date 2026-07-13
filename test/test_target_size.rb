# frozen_string_literal: true

require "test_helper"

# Structural guard for the WCAG 2.5.5 (Level AAA target-size, 44px) batch.
#
# These assertions read the component TEMPLATES as text (the structural lane,
# like test_shared_modal_template.rb) and pin the target-size fixes so a future
# edit that reintroduces a sub-44px control — or the Tailwind-4 `scale-95`
# rest-state regression on the modal panels — fails here without needing a full
# browser render.
class TestTargetSize < Minitest::Test
  TEMPLATES = File.expand_path(
    "../lib/generators/modelrails_ui/add/templates", __dir__
  )

  def template(rel)
    File.read(File.join(TEMPLATES, rel))
  end

  def test_tabs_trigger_meets_target_size
    assert_includes template("tabs/tabs_component.rb.tt"), "min-h-11",
      "tabs TRIGGER must carry min-h-11"
  end

  def test_modal_panels_drop_scale_95_rest_class
    # TW4 compiles scale-95 to the standalone `scale:` property, which composes
    # with (not overrides) the controller's inline transform → open panels rest
    # at 95%. The rest class must be gone from all three panel constants.
    refute_includes template("dialog/dialog_component.rb.tt"), "scale-95",
      "dialog PANEL must not carry scale-95"
    refute_includes template("alert_dialog/alert_dialog_component.rb.tt"), "scale-95",
      "alert_dialog PANEL must not carry scale-95"
    refute_includes template("gallery/gallery_component.rb.tt"), "scale-95",
      "gallery PANEL_CLS must not carry scale-95"
  end

  def test_context_menu_trigger_has_button_role
    # aria-haspopup/aria-expanded on a role-less div is an axe critical.
    assert_includes template("context_menu/context_menu_component.rb.tt"), 'role: "button"'
  end

  def test_sidebar_toggle_is_44px
    assert_includes template("sidebar/sidebar_component.rb.tt"), "size-11",
      "sidebar TOGGLE_CLS must be size-11"
  end

  def test_combobox_sizes_all_meet_target
    src = template("combobox/combobox_component.rb.tt")

    refute_match(/h-8\b/, src, "combobox SIZES must not keep h-8")
    refute_match(/h-9\b/, src, "combobox SIZES must not keep h-9")
    refute_match(/h-10\b/, src, "combobox SIZES must not keep h-10")
    assert_includes src, "h-11", "combobox SIZES must be h-11"
  end

  def test_checkbox_and_radio_labels_are_tappable
    checkbox = template("checkbox/checkbox_component.rb.tt")

    refute_includes checkbox, "leading-none", "checkbox label must drop leading-none"
    assert_includes checkbox, "min-h-11", "checkbox label must carry min-h-11"
    assert_includes template("radio_group/radio_group_component.rb.tt"), "min-h-11",
      "radio_group label must carry min-h-11"
  end

  def test_breadcrumb_and_tooltip_targets
    assert_includes template("breadcrumb/breadcrumb_component.rb.tt"), "min-h-11"
    assert_includes template("tooltip/tooltip_component.rb.tt"), "min-h-11"
  end

  def test_navigation_and_mega_menu_row_height
    nav = template("navigation_menu/navigation_menu_component.rb.tt")

    refute_includes nav, "h-9", "navigation_menu TRIGGER/LINK must be bumped off h-9"
    assert_includes nav, "h-11"
    assert_includes template("mega_menu/mega_menu_component.rb.tt"), "h-11"
  end

  def test_input_otp_cells_are_44px_wide
    src = template("input_otp/input_otp_component.rb.tt")

    assert_includes src, "w-11", "input_otp CELL_CLS must be w-11"
    refute_includes src, "w-10", "input_otp CELL_CLS must not keep w-10"
  end

  def test_resizable_handle_owns_a_real_strip
    src = template("resizable/resizable_component.rb.tt")

    assert_includes src, "w-11", "resizable HANDLE_CLS must own a 44px strip"
    assert_includes src, "before:bg-border", "resizable hairline must be drawn via before:"
  end

  def test_carousel_arrow_plate_contrast_bumped
    assert_includes template("carousel/carousel_component.rb.tt"), "bg-surface-raised/95"
  end

  def test_badge_link_and_banner_dismiss_targets
    assert_includes template("badge/badge_component.rb.tt"), "min-h-11",
      "badge link variant must add min-h-11"
    assert_includes template("banner/banner_component.rb.tt"), "min-w-11",
      "banner dismiss button must be 44px"
  end

  def test_modal_controller_neutralizes_scale
    js = File.read(File.join(TEMPLATES, "dialog/modal_controller.js"))

    assert_includes js, 'style.scale = "1"',
      "modal_controller must neutralize the TW4 scale: property"
  end
end
