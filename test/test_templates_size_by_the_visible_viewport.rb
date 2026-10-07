# frozen_string_literal: true

require "test_helper"

# vh counts the browser bars a phone shows and hides, so a panel capped by it can push its
# own edge behind them; dvh is the viewport the reader sees (playbook standards/frontend/css.md).
class TestTemplatesSizeByTheVisibleViewport < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui", __dir__)
  VIEWPORT_HEIGHT = /\b\d*vh\b|\b(?:min-|max-)?h-screen\b/

  def offenders
    Dir[File.join(TEMPLATES, "**", "*.{tt,erb,rb}")].flat_map do |path|
      File.read(path).scan(VIEWPORT_HEIGHT).map { |unit| "#{path.delete_prefix("#{TEMPLATES}/")}: #{unit}" }
    end
  end

  def test_no_template_sizes_anything_by_vh
    assert_empty offenders, "Use dvh (min-h-dvh, 100dvh, 90dvh):\n  #{offenders.join("\n  ")}"
  end

  def test_the_pattern_catches_vh_and_h_screen_but_not_dvh
    assert_equal %w[90vh min-h-screen 100vh], "max-h-[90vh] min-h-screen calc(100vh-3rem)".scan(VIEWPORT_HEIGHT)
    assert_empty "max-h-[90dvh] min-h-dvh calc(100dvh-3rem)".scan(VIEWPORT_HEIGHT)
  end
end
