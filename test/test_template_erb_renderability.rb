# frozen_string_literal: true

require "test_helper"
require "erb"

# Every .rb.tt template is rendered through ERB by Thor's `template` action at
# install time — so a literal ERB tag anywhere in the file, INCLUDING inside a
# Ruby doc comment's usage example, is evaluated as template code and crashes
# `rails g modelrails_ui:add <name>` for the host. The gem's own render lane
# never catches this class: `load_component` evals templates as plain Ruby,
# where comments stay comments. This gate takes the same ERB path Thor does.
# Doc-comment examples must use the doubled form (`<%%=` / `<%%`), which
# renders back to a literal tag in the installed file.
class TestTemplateErbRenderability < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  def test_every_rb_tt_template_renders_through_erb_without_error
    offenders = Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.filter_map do |path|
      ERB.new(File.read(path), trim_mode: "-").result(binding)
      nil
    rescue Exception => e # rubocop:disable Lint/RescueException -- SyntaxError is not a StandardError
      "#{path.delete_prefix("#{TEMPLATES}/")}: #{e.class}: #{e.message.lines.first&.strip}"
    end

    assert_empty offenders,
      "templates that crash Thor's ERB render at install time:\n  #{offenders.join("\n  ")}"
  end
end
