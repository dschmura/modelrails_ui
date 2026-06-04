# frozen_string_literal: true

require "render_test_helper"
load_component "figure", "figure_component.rb.tt"

class FigureRenderTest < ViewComponent::TestCase
  def test_renders_figure_with_content
    render_inline(UI::FigureComponent.new) { "<img src='a.jpg' alt='A'>".html_safe }

    assert_selector "figure img[alt='A']", visible: :all
  end

  def test_renders_figcaption_when_caption_given
    render_inline(UI::FigureComponent.new(caption: "Fig. 1 — the chart")) { "content" }

    assert_selector "figure figcaption", text: "Fig. 1 — the chart", visible: :all
  end

  def test_no_figcaption_when_caption_nil
    render_inline(UI::FigureComponent.new) { "content" }

    assert_no_selector "figcaption", visible: :all
  end

  # text-text-muted is the AAA token in this repo (same neutral as body text).
  def test_caption_uses_aaa_muted_token
    render_inline(UI::FigureComponent.new(caption: "Caption")) { "content" }

    assert_selector "figcaption.text-text-muted", visible: :all
  end

  def test_merges_caption_class
    render_inline(UI::FigureComponent.new(caption: "Caption", caption_class: "italic")) { "content" }

    assert_selector "figcaption.italic", visible: :all
  end
end
