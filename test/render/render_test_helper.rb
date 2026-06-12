# frozen_string_literal: true

# Approach: minimal in-test Rails application (no test/dummy on disk).
# ViewComponent::TestCase requires an initialized Rails.application + ActionView.
# We boot a bare Rails::Application here, which is sufficient for render_inline.

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "view_component"
require "view_component/test_helpers"
require "tailwind_merge"

class RenderHarnessApp < Rails::Application
  config.eager_load = false
  config.consider_all_requests_local = true
  config.secret_key_base = "test_secret_key_base_render_harness"
  config.logger = Logger.new(IO::NULL)
  config.cache_classes = true
  # Silence the "couldn't find file" asset warnings
  config.assets = ActiveSupport::OrderedOptions.new if config.respond_to?(:assets)
end

Rails.application.initialize! unless Rails.application.initialized?

# ViewComponent 4 wires TestCase against the initialized app (hooks into ActionView);
# this require MUST come after Rails.application.initialize! or the wiring is incomplete.
require "view_component/test_case"
require "minitest/autorun"

# Real ApplicationComponent — mirrors install/templates/application_component.rb.tt
# exactly (cn is backed by tailwind_merge so the render tests exercise components
# under real merge behavior: a per-thread Merger, class: overrides win conflicts).
class ApplicationComponent < ViewComponent::Base
  private

  def cn(*classes)
    joined = classes.flatten.compact.reject { |c| c.to_s.empty? }.join(" ")
    (Thread.current[:modelrails_ui_tw_merge] ||= TailwindMerge::Merger.new).merge(joined)
  end
end

ADD_TEMPLATES = File.expand_path("../../lib/generators/modelrails_ui/add/templates", __dir__)

# Eval a component template (.rb.tt is plain Ruby) into a real class under the
# real ViewComponent::Base hierarchy.
def load_component(*parts)
  path = File.join(ADD_TEMPLATES, *parts)
  eval File.read(path), TOPLEVEL_BINDING, path # rubocop:disable Security/Eval
end

# Wire up the UI acronym inflection so UI::ButtonComponent resolves correctly.
ActiveSupport::Inflector.inflections(:en) { |i| i.acronym "UI" }
