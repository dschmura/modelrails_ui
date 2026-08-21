# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

# Structural lane: stubs ViewComponent (test_components.rb), reads templates as text.
Minitest::TestTask.create(:"test:structural") do |t|
  t.test_globs = ["test/test_*.rb"]
  t.warning = true
end

# Render lane: real view_component + a minimal Rails app (test/render/render_test_helper.rb).
# MUST be a separate process from the structural lane (incompatible ViewComponent::Base).
Minitest::TestTask.create(:"test:render") do |t|
  t.libs << "test/render"
  t.test_globs = ["test/render/**/*_test.rb"]
  t.warning = false
end

# Browser lane: real Chrome over CDP, the gem's own controller templates loaded through a
# real importmap. Proves BEHAVIOUR — the render lane asserts markup and is blind to what
# only happens once JS runs. Separate process for the same reason as the render lane.
Minitest::TestTask.create(:"test:system") do |t|
  t.libs << "test/render" << "test/system"
  t.test_globs = ["test/system/**/*_test.rb"]
  t.warning = false
end

task test: [:"test:structural", :"test:render", :"test:system"]

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: %i[test rubocop]
