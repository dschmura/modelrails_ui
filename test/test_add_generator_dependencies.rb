# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/add/add_generator"

# DEPENDENCIES are copied transitively (see test_form_builder_registry.rb), but a
# dependency the host app already customised should not hit the Thor overwrite
# prompt just because some other component needs it. These tests pin the
# already-installed-dependency skip on the generator's own dependency step —
# `copy_or_skip` is the only path into `copy_component` (and, through it,
# `template`/`copy_file`), so spying on it proves those never fire for a
# dependency that is already on disk.
class TestAddGeneratorDependencies < Minitest::Test
  Components = ModelrailsUi::Generators::Components

  # allocate skips #initialize (which requires the components argument);
  # components and destination_root are stubbed directly, same idiom as
  # test_add_generator_partial_routing.rb and test_form_builder_registry.rb.
  def generator_for(requested, root)
    generator = ModelrailsUi::Generators::AddGenerator.allocate
    generator.instance_variable_set(:@components, requested)
    generator.define_singleton_method(:destination_root) { root }
    generator
  end

  def with_copy_component_spy(generator)
    calls = []
    generator.define_singleton_method(:copy_component) { |name| calls << name }
    yield calls
  end

  def test_already_installed_dependencies_are_left_alone
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "app/components/ui"))
      File.write(File.join(root, "app/components/ui/button_component.rb"), "# customised")
      File.write(File.join(root, "app/components/ui/input_component.rb"), "# customised")

      generator = generator_for(%w[copy], root)

      with_copy_component_spy(generator) do |calls|
        _out, = capture_io { generator.copy_components }

        assert_equal %w[copy], calls,
          "button and input are already installed dependencies — copy_component (and " \
          "therefore template/copy_file) must not run for them"
      end
    end
  end

  def test_missing_dependencies_are_still_installed
    Dir.mktmpdir do |root|
      generator = generator_for(%w[copy], root)

      with_copy_component_spy(generator) do |calls|
        capture_io { generator.copy_components }

        assert_equal %w[copy button input], calls,
          "with no pre-existing files, every expanded component (the explicit " \
          "request and its dependencies) must still be copied"
      end
    end
  end

  def test_already_installed_dependency_message_names_the_requesting_component
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "app/components/ui"))
      File.write(File.join(root, "app/components/ui/button_component.rb"), "# customised")
      File.write(File.join(root, "app/components/ui/input_component.rb"), "# customised")

      generator = generator_for(%w[copy], root)

      with_copy_component_spy(generator) do
        out, = capture_io { generator.copy_components }

        assert_includes out, "button already installed — left alone (dependency of copy)"
        assert_includes out, "input already installed — left alone (dependency of copy)"
      end
    end
  end

  def test_explicitly_requested_component_is_never_skipped_even_if_already_installed
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "app/components/ui"))
      File.write(File.join(root, "app/components/ui/button_component.rb"), "# customised")

      generator = generator_for(%w[button], root)

      with_copy_component_spy(generator) do |calls|
        capture_io { generator.copy_components }

        assert_equal %w[button], calls,
          "an explicitly requested component keeps today's behaviour and always copies"
      end
    end
  end
end
