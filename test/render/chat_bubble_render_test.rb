# frozen_string_literal: true

require "render_test_helper"
load_component "chat_bubble", "chat_bubble_component.rb.tt"

class ChatBubbleRenderTest < ViewComponent::TestCase
  def test_sent_uses_the_aaa_interactive_fill
    render_inline(UI::ChatBubbleComponent.new(sent: true)) { "Hi" }

    assert_selector "div.bg-interactive.text-text-on-interactive", text: "Hi"
  end

  def test_received_uses_the_aaa_sunken_surface_with_body_text
    render_inline(UI::ChatBubbleComponent.new(sent: false)) { "Hello" }

    assert_selector "div.bg-surface-sunken.text-text-body", text: "Hello"
  end

  # Who spoke is perceivable in text, never by alignment/color alone: an sr-only
  # direction label is always present so a screen-reader user knows the speaker.
  def test_sent_announces_the_speaker_direction_to_assistive_tech
    render_inline(UI::ChatBubbleComponent.new(sent: true)) { "Hi" }

    assert_selector "span.sr-only", text: "You said"
  end

  def test_received_announces_the_speaker_direction_to_assistive_tech
    render_inline(UI::ChatBubbleComponent.new(sent: false)) { "Hello" }

    assert_selector "span.sr-only", text: "They said"
  end

  # A named author is shown visibly (perceivable without color/alignment).
  def test_renders_a_named_author_visibly
    render_inline(UI::ChatBubbleComponent.new(author: "Ada", timestamp: "10:32")) { "Hi" }

    assert_selector "p span", text: "Ada"
    assert_selector "p span", text: "10:32"
  end

  # Timestamps de-emphasize via the AAA muted token (same neutral as body).
  def test_timestamp_uses_the_aaa_muted_token
    render_inline(UI::ChatBubbleComponent.new(timestamp: "10:32")) { "Hi" }

    assert_selector "p.text-text-muted", text: "10:32"
  end

  # The avatar is decorative — empty alt + aria-hidden so it is not announced.
  def test_received_avatar_is_decorative
    render_inline(UI::ChatBubbleComponent.new(avatar: "/a.png")) { "Hi" }

    assert_selector "img[alt=''][aria-hidden='true']"
  end

  # The avatar applies to received messages only.
  def test_sent_messages_have_no_avatar
    render_inline(UI::ChatBubbleComponent.new(sent: true, avatar: "/a.png")) { "Hi" }

    assert_no_selector "img"
  end

  def test_merges_caller_classes
    render_inline(UI::ChatBubbleComponent.new(class: "mb-4")) { "Hi" }

    assert_selector "div.mb-4"
  end

  def test_raises_on_an_unknown_sent_value
    assert_raises(ArgumentError) do
      render_inline(UI::ChatBubbleComponent.new(sent: "left")) { "Hi" }
    end
  end
end
