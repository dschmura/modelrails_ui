# frozen_string_literal: true

require_relative "lib/modelrails_ui/version"

Gem::Specification.new do |spec|
  spec.name = "modelrails_ui"
  spec.version = ModelrailsUi::VERSION
  spec.authors = ["Alexey Poimtsev"]
  spec.email = ["alexey.poimtsev@gmail.com"]

  spec.summary = "Primitive view components and helpers for Rails applications"
  spec.description = "Provides a set of primitive view components and helpers for building " \
                     "UI in Rails applications with minimal overhead."
  spec.homepage = "https://github.com/dschmura/modelrails_ui"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dschmura/modelrails_ui"
  spec.metadata["changelog_uri"] = "https://github.com/dschmura/modelrails_ui/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"].reject { |f| File.directory?(f) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.1"
  spec.add_dependency "view_component", ">= 4.0"

  spec.add_development_dependency "rails", ">= 7.1"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "capybara" # render-test assertions (ViewComponent::TestCase matchers)
  spec.add_development_dependency "lefthook"
  spec.add_development_dependency "tailwind_merge" # render harness backs cn with real tailwind_merge (host gets it via install generator)
end
