# frozen_string_literal: true

require "test_helper"

# A ring color with no ring width paints nothing: `aria-invalid:ring-danger`
# alone is inert, and the invalid state silently loses its ring cue (issue
# #112 fixed this for select; #122 found the same gap shipped in seven more
# templates). This gate pins the class: every template string that sets the
# invalid ring COLOR must set an invalid ring WIDTH in the same file.
class TestInvalidRingWidth < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  def test_every_invalid_ring_color_has_an_invalid_ring_width
    offenders = Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.filter_map do |path|
      src = File.read(path)
      next unless src.include?("aria-invalid:ring-danger")
      next if src.match?(/aria-invalid:ring-\d/)

      path.delete_prefix("#{TEMPLATES}/")
    end

    assert_empty offenders,
      "templates with an invalid ring color but no ring width (inert ring):\n  #{offenders.join("\n  ")}"
  end
end
