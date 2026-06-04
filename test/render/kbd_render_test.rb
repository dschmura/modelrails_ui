# frozen_string_literal: true

require "render_test_helper"
load_component "kbd", "kbd_component.rb.tt"

class KbdRenderTest < ViewComponent::TestCase
  def test_renders_a_kbd_element_with_the_key
    render_inline(UI::KbdComponent.new("Esc"))

    assert_selector "kbd", text: "Esc"
  end

  def test_accepts_the_key_via_label_kwarg
    render_inline(UI::KbdComponent.new(label: "Enter"))

    assert_selector "kbd", text: "Enter"
  end

  def test_slot_content_takes_precedence_over_the_key
    render_inline(UI::KbdComponent.new("ignored")) { "Ctrl" }

    assert_selector "kbd", text: "Ctrl"
    assert_no_text "ignored"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind. In this
  # token system text-text-muted resolves to the same neutral as text-text-body
  # (hierarchy comes from size/weight, not lightness), so it clears AAA 7:1.
  def test_renders_with_aaa_tokens
    render_inline(UI::KbdComponent.new("K"))

    assert_selector "kbd.bg-surface-sunken"
    assert_selector "kbd.text-text-muted"
  end

  # Non-interactive by contract — never a focus or pointer target.
  def test_is_non_interactive
    render_inline(UI::KbdComponent.new("K"))

    assert_selector "kbd.pointer-events-none.select-none"
  end

  def test_merges_caller_classes
    render_inline(UI::KbdComponent.new("K", class: "ml-2"))

    assert_selector "kbd.ml-2"
  end
end
