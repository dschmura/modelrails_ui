# frozen_string_literal: true

require "test_helper"

# A component doc says when to reach for the component and when not to (#268).
class TestComponentDocsSayWhenToUse < Minitest::Test
  DOCS = File.expand_path("../docs/components", __dir__)
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  SECTIONS = ["When to use", "When not to use"].freeze
  DOCS_WRITTEN_AGAINST = 86

  def test_the_walk_finds_the_docs
    assert_operator docs.size, :>=, DOCS_WRITTEN_AGAINST,
      "#{DOCS} holds fewer docs than this guard was written against, so it would pass on nothing"
  end

  def test_every_doc_has_both_sections
    offenders = docs.flat_map do |path|
      SECTIONS.reject { |name| bulleted?(section(File.read(path), name)) }
        .map { |name| "#{File.basename(path)}: ## #{name}" }
    end

    assert_empty offenders, <<~MSG
      component docs missing a section, or carrying one with no bullet under it:
        #{offenders.join("\n  ")}

      The API section says what a component accepts. These two say which component
      fits the job, which is the part a reader cannot infer from the options.
    MSG
  end

  def test_the_sections_name_only_components_that_ship
    offenders = docs.flat_map do |path|
      named = SECTIONS.flat_map { |name| section(File.read(path), name).to_s.scan(/UI::(\w+)Component/).flatten }
      (named.uniq - shipped).map { |klass| "#{File.basename(path)}: UI::#{klass}Component" }
    end

    assert_empty offenders, "component docs point a reader at a component this gem does not ship:\n  #{offenders.join("\n  ")}"
  end

  def test_a_doc_without_the_heading_has_no_section
    assert_nil section("# Thing\n\n## API\n\n- a row\n", "When to use")
  end

  def test_a_heading_with_nothing_under_it_does_not_count
    refute bulleted?(section("## When to use\n\n## When not to use\n\n- a reason\n", "When to use"))
  end

  def test_when_to_use_is_not_satisfied_by_when_not_to_use
    assert_nil section("## When not to use\n\n- a reason\n", "When to use")
  end

  def test_a_section_runs_to_the_end_of_the_doc
    assert bulleted?(section("## When not to use\n\n- a reason\n", "When not to use"))
  end

  private

  def docs = Dir.glob("#{DOCS}/*.md")

  def shipped
    @shipped ||= Dir.glob("#{TEMPLATES}/*/*_component.rb.tt").map do |file|
      File.basename(file, "_component.rb.tt").split("_").map(&:capitalize).join
    end
  end

  def section(doc, name)
    doc[/^## #{Regexp.escape(name)}[ \t]*\n(.*?)(?=^## |\z)/m, 1]
  end

  def bulleted?(text)
    text.to_s.match?(/^- \S/)
  end
end
