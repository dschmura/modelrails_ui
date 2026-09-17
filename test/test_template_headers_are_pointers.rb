# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/component_header"

# Every component template's class-level comment is the three-line pointer to
# docs/components/<name>.md; the prose lives in the doc. PENDING shrinks one
# wave at a time and is empty once the migration lands.
class TestTemplateHeadersArePointers < Minitest::Test
  TEMPLATE_ROOT = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  DOCS_ROOT = File.expand_path("../docs/components", __dir__)
  H = ModelrailsUi::ComponentHeader

  PENDING = %w[
    audio embed figure iframe image
    map_area picture sidebar video
  ].freeze

  def templates
    Dir[File.join(TEMPLATE_ROOT, "*", "*_component.rb.tt")].sort.map { |f| [File.basename(f, "_component.rb.tt"), f] }
  end

  def test_migrated_templates_carry_only_the_pointer
    offenders = templates.reject { |name, _| PENDING.include?(name) }.reject do |name, file| # rubocop:disable Style/HashExcept
      H.pointer?(H.locate(File.readlines(file)), doc: H.doc_name(name))
    end

    assert_empty offenders.map(&:first),
      "Header is prose, not the three-line pointer — run bin/migrate-component-header: #{offenders.map(&:first).join(", ")}"
  end

  def test_pending_names_are_real_components
    assert_empty PENDING - templates.map(&:first), "PENDING names a template that does not exist"
  end

  def test_every_component_has_a_doc_to_point_at
    templates.each do |name, _|
      assert_path_exists File.join(DOCS_ROOT, "#{H.doc_name(name)}.md"), "#{name}: no doc to point at"
    end
  end

  def test_no_markdown_heading_comments_survive_in_migrated_templates
    offenders = templates.reject { |name, _| PENDING.include?(name) }.select do |_, file| # rubocop:disable Style/HashExcept
      File.readlines(file).any? { |l| l.match?(/\A\s*#\s*##?\s+\S/) }
    end

    assert_empty offenders.map(&:first),
      "A markdown heading comment survived migration (locate() missed it): #{offenders.map(&:first).join(", ")}"
  end
end
