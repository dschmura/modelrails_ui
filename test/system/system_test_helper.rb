# frozen_string_literal: true

# BROWSER lane. The render lane asserts markup; this one asserts what happens once the
# JavaScript runs — open/close, roving focus, ARIA that a controller keeps in sync, and
# the DOM mutations no amount of static markup can reveal.
#
# It exists because every bug found in the 2026-08 overlay audit was browser-observable
# and this gem structurally could not see any of it: a submenu that outlived its parent
# menu, an avatar that vanished from the accessibility tree after its image 404'd. Both
# rendered perfectly correct markup.
#
# Approach: no test/dummy on disk. A tiny Rack app serves one page per scenario, with a
# real importmap wiring the gem's own controller templates and shared modules against the
# Stimulus runtime — the same module graph a host app gets, so a broken import or an
# unpinned specifier fails here exactly as it would in a fork.
#
# SCOPE: behaviour and ARIA, not colour. The stylesheet ships as Tailwind source that
# needs a build step, so axe runs with colour-contrast disabled here; AAA contrast stays
# proven in modelrails_base, which has compiled CSS. Anything asserting a *computed
# colour* belongs there, not here.

require "render_test_helper"
require "capybara"
require "capybara/minitest"
require "capybara/cuprite"
require "rack"
# The shared-module registry: the harness resolves `overlays/top_layer` through the same
# SHARED_JS entry the generator uses, so a module the gem forgot to register fails here.
require_relative "../../lib/generators/modelrails_ui/components"

module BrowserHarness
  ADD_TEMPLATES = File.expand_path("../../lib/generators/modelrails_ui/add/templates", __dir__)
  STIMULUS_JS = Dir.glob(
    File.join(Gem::Specification.find_by_name("stimulus-rails").gem_dir, "app/assets/javascripts/stimulus.min.js")
  ).first
  # axe is injected on demand rather than shipped in the page, so it never influences the
  # DOM under test until an assertion asks for it.
  AXE_JS = Dir.glob(
    File.join(Gem::Specification.find_by_name("axe-core-api").gem_dir, "**/axe.min.js")
  ).first

  # Registered by `scenario`; each block returns the HTML body for one page.
  SCENARIOS = {}

  class << self
    # controllers: stimulus identifiers to register, resolved to <component>/<name>_controller.js
    # modules:     shared ES modules (Components::SHARED_JS namespaces) the controllers import
    def scenario(name, controllers: [], modules: [], &body)
      SCENARIOS[name.to_s] = {controllers: controllers, modules: modules, body: body}
    end

    def controller_source(identifier)
      file = "#{identifier.tr("-", "_")}_controller.js"
      path = Dir.glob(File.join(ADD_TEMPLATES, "*", file)).first
      raise "no template ships #{file}" unless path

      File.read(path)
    end

    def module_source(namespace, name)
      entry = Array(ModelrailsUi::Generators::Components::SHARED_JS.values.flatten)
        .find { |m| m[:dir] == namespace && File.basename(m[:source], ".js") == name }
      raise "no shared module #{namespace}/#{name}" unless entry

      File.read(File.join(ADD_TEMPLATES, entry[:source]))
    end
  end

  # Serves the page plus every JS file it imports. Deliberately mirrors a host's importmap
  # rather than inlining the sources: a controller importing an unpinned bare specifier
  # must fail here the way it would in a real app.
  APP = lambda do |env|
    path = env["PATH_INFO"]

    if (m = path.match(%r{\A/js/controllers/(.+)\.js\z}))
      return [200, {"content-type" => "text/javascript"}, [controller_source_for(m[1])]]
    end
    if (m = path.match(%r{\A/js/modules/([^/]+)/(.+)\.js\z}))
      return [200, {"content-type" => "text/javascript"}, [BrowserHarness.module_source(m[1], m[2])]]
    end
    return [200, {"content-type" => "text/javascript"}, [File.read(STIMULUS_JS)]] if path == "/js/stimulus.js"

    scenario = SCENARIOS[path.delete_prefix("/")]
    return [404, {"content-type" => "text/plain"}, ["no scenario at #{path}"]] unless scenario

    [200, {"content-type" => "text/html"}, [BrowserHarness.page(scenario)]]
  end

  def self.controller_source_for(identifier) = controller_source(identifier)

  def self.axe_source = File.read(AXE_JS)

  def self.page(scenario)
    imports = {"@hotwired/stimulus" => "/js/stimulus.js"}
    scenario[:controllers].each { |c| imports["controllers/#{c}"] = "/js/controllers/#{c}.js" }
    scenario[:modules].each { |m| imports[m] = "/js/modules/#{m}.js" }

    registrations = scenario[:controllers].map do |c|
      "import C_#{c.tr("-", "_")} from \"controllers/#{c}\"\n" \
      "application.register(\"#{c}\", C_#{c.tr("-", "_")})"
    end.join("\n")

    <<~HTML
      <!doctype html>
      <html lang="en"><head><meta charset="utf-8"><title>harness</title>
      <script type="importmap">#{{imports: imports}.to_json}</script>
      </head>
      <body>
        <!-- A landmark wrapper so axe's `region` rule reports on the COMPONENT rather than
             on the harness page having no landmarks of its own. -->
        <main>
        #{scenario[:body].call}
        </main>
        <script type="module">
          import { Application } from "@hotwired/stimulus"
          const application = Application.start()
          // Stimulus catches errors thrown in lifecycle callbacks and routes them here
          // rather than letting them reach window.onerror — so `js_errors` never sees a
          // controller that throws in connect(). Recording them is the only way this lane
          // can tell a working component from a silently dead one.
          window.__stimulusErrors = []
          application.handleError = (error, message, detail) => {
            window.__stimulusErrors.push(`${message}: ${error && error.message}`)
          }
          #{registrations}
          window.__stimulusReady = true
        </script>
      </body></html>
    HTML
  end
end

Capybara.register_driver(:cuprite_gem) do |app|
  Capybara::Cuprite::Driver.new(app, headless: true, js_errors: true, process_timeout: 30, timeout: 15,
    window_size: [1200, 900],
    **(Process.uid.zero? ? {browser_options: {"no-sandbox" => nil, "disable-dev-shm-usage" => nil}} : {}))
end

# webrick, not puma: the harness serves a handful of small static responses, so the
# lighter server keeps the lane's startup cost down and avoids another dependency.
Capybara.server = :webrick
Capybara.app = BrowserHarness::APP
Capybara.default_driver = :cuprite_gem
Capybara.default_max_wait_time = 5

# js_errors: true above turns an exception inside a controller into a test failure rather
# than a silently dead component — the failure mode this lane exists to catch.
class BrowserTestCase < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    Capybara.reset_sessions!
    super
  end

  def visit_scenario(name)
    visit("/#{name}")
    # Stimulus boots asynchronously; without this an action can be dispatched before the
    # controller connects and the assertion fails for the wrong reason.
    Timeout.timeout(5) { sleep 0.02 until page.evaluate_script("window.__stimulusReady === true") }
  end

  def press(key) = page.driver.browser.keyboard.type(key)

  # A controller that throws in a lifecycle callback renders nothing visibly wrong — it
  # just stops working. Assert explicitly that none did.
  def assert_no_stimulus_errors
    errors = page.evaluate_script("window.__stimulusErrors || []")

    assert_empty errors, "Stimulus reported controller errors:\n  #{errors.join("\n  ")}"
  end

  # Structural accessibility only. `color-contrast` is OFF because the stylesheet ships as
  # Tailwind source and this harness serves no compiled CSS — axe would report against
  # unstyled defaults and a green result would mean nothing. AAA contrast is proven in
  # modelrails_base against real compiled CSS; do not re-enable it here without also
  # building the stylesheet.
  def assert_axe_clean(within: "body")
    page.execute_script(BrowserHarness.axe_source) unless page.evaluate_script("typeof axe !== 'undefined'")
    violations = page.evaluate_async_script(<<~JS, within)
      const [selector, done] = [arguments[0], arguments[1]];
      axe.run(document.querySelector(selector), { rules: { "color-contrast": { enabled: false } } })
         .then((r) => done(r.violations.map((v) => v.id + ": " + v.nodes.length + " node(s) — " + v.help)))
         .catch((e) => done(["axe failed to run: " + e.message]));
    JS

    assert_empty violations, "axe violations in #{within}:\n  #{violations.join("\n  ")}"
  end
end
