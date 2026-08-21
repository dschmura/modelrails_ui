# frozen_string_literal: true

require "test_helper"

# Stimulus resolves keyboard filters against a fixed vocabulary and THROWS on anything
# else — "contains unknown key filter: escape" — which kills the whole action. Nothing but
# a browser sees it: the markup looks right, the render lane passes, and the documented
# behaviour simply never runs.
#
# `command` shipped `keydown.escape` while every other floating component used
# `keydown.esc`, so Escape never closed the command palette in any fork.
class TestStimulusKeyFilters < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  # Stimulus's built-in aliases (see @hotwired/stimulus KeyboardEvent filters).
  KNOWN = %w[enter tab esc space up down left right home end page_up page_down].freeze

  def test_every_keydown_filter_is_one_stimulus_recognises
    offenders = Dir.glob("#{TEMPLATES}/**/*").select { |f| File.file?(f) }.flat_map do |path|
      File.read(path).scan(/keydown\.([a-z_]+)/).flatten
        .reject { |f| KNOWN.include?(f) }
        .map { |f| "#{File.basename(path)}: keydown.#{f}" }
    end

    assert_empty offenders.uniq, <<~MSG
      Stimulus throws on an unrecognised key filter, so the action never runs:

        #{offenders.uniq.join("\n  ")}

      Recognised: #{KNOWN.join(", ")}. Note `esc`, not `escape`.
    MSG
  end
end
