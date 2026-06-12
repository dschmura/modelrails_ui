# frozen_string_literal: true

require "render_test_helper"
# Card is a compound primitive — the outer container plus five region
# sub-components. Each is an independent class, so all must be loaded.
load_component "card", "card_component.rb.tt"
load_component "card", "card_header_component.rb.tt"
load_component "card", "card_title_component.rb.tt"
load_component "card", "card_description_component.rb.tt"
load_component "card", "card_content_component.rb.tt"
load_component "card", "card_footer_component.rb.tt"

class CardRenderTest < ViewComponent::TestCase
  # --- Container ----------------------------------------------------------

  def test_renders_a_plain_div_container_with_slot_content
    render_inline(UI::CardComponent.new) { "Body" }

    assert_selector "div", text: "Body"
  end

  # The card is a neutral box — it adds no role and is never a link/button.
  def test_container_is_non_interactive_with_no_aria_role
    render_inline(UI::CardComponent.new) { "Body" }

    assert_no_selector "div[role]"
  end

  # AAA semantic tokens (raised surface + body text + semantic border), never raw.
  def test_container_uses_aaa_tokens
    render_inline(UI::CardComponent.new) { "x" }

    assert_selector "div.bg-surface-raised.text-text-body"
    assert_selector "div.border-border"
  end

  def test_container_merges_caller_classes
    render_inline(UI::CardComponent.new(class: "mt-4")) { "x" }

    assert_selector "div.mt-4"
  end

  # --- Title (the only structural sub-component) --------------------------

  def test_title_defaults_to_h3_with_the_heading_token
    render_inline(UI::CardTitleComponent.new("Account"))

    assert_selector "h3.text-text-heading", text: "Account"
  end

  # The caller owns the heading level so the card never hijacks the outline.
  def test_title_honours_caller_supplied_level
    render_inline(UI::CardTitleComponent.new("Account", level: 2))

    assert_selector "h2", text: "Account"
    assert_no_selector "h3"
  end

  def test_title_accepts_label_kwarg_and_block
    render_inline(UI::CardTitleComponent.new(label: "From label"))

    assert_selector "h3", text: "From label"

    render_inline(UI::CardTitleComponent.new("ignored")) { "From block" }

    assert_selector "h3", text: "From block"
  end

  # Fail-loud: an out-of-range level raises in dev/test (Rails.env is non-prod here).
  def test_title_raises_on_out_of_range_level
    assert_raises(ArgumentError) { UI::CardTitleComponent.new("x", level: 7) }
  end

  # --- Description --------------------------------------------------------

  # Muted == body in this token system, so text-text-muted still clears AAA 7:1.
  def test_description_uses_muted_token
    render_inline(UI::CardDescriptionComponent.new("Subtitle"))

    assert_selector "p.text-text-muted", text: "Subtitle"
  end

  # --- Slot composition ---------------------------------------------------

  def test_regions_compose_into_a_single_card
    vc = vc_test_controller.view_context
    render_inline(UI::CardComponent.new) do
      header = UI::CardHeaderComponent.new.render_in(vc) do
        UI::CardTitleComponent.new("Title").render_in(vc)
      end
      footer = UI::CardFooterComponent.new.render_in(vc) { "Footer" }
      (header + UI::CardContentComponent.new.render_in(vc) { "Body" } + footer).html_safe
    end

    assert_selector "div h3", text: "Title"
    assert_selector "div", text: /Body/
    assert_selector "div", text: /Footer/
  end

  def test_content_and_footer_merge_caller_classes
    render_inline(UI::CardContentComponent.new(class: "space-y-2")) { "x" }

    assert_selector "div.space-y-2.px-6"

    render_inline(UI::CardFooterComponent.new(class: "justify-end")) { "x" }

    assert_selector "div.justify-end.px-6"
  end
end
