# frozen_string_literal: true

require "test_helper"

# `rubocop:enable Layout/LineLength` is a trap in shipped templates: the cop is
# OFF under rubocop-rails-omakase, and an `enable` directive turns it back ON
# for the rest of the HOST's file — surfacing unrelated long lines in every app
# that generates the component (#111). Long Tailwind class strings need no
# disable here; templates must ship none of these directives.
class TestTemplateRubocopDirectives < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui", __dir__)

  def test_no_shipped_template_carries_a_line_length_directive
    offenders = Dir.glob("#{TEMPLATES}/**/*.tt").select do |path|
      File.read(path).include?("rubocop:disable Layout/LineLength")
    end.map { |p| p.delete_prefix("#{TEMPLATES}/") }

    assert_empty offenders, "templates shipping Layout/LineLength directives: #{offenders.inspect}"
  end
end
