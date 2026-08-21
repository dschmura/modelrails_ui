# frozen_string_literal: true

require "render_test_helper"
require "active_model"
load_component "label", "label_component.rb.tt"
load_component "form_field", "form_field_component.rb.tt"
load_component "input", "input_component.rb.tt"
load_component "textarea", "textarea_component.rb.tt"
load_component "file_input", "file_input_component.rb.tt"
load_component "select", "select_component.rb.tt"
load_component "error_summary", "error_summary_component.rb.tt"
load_component "form_builder", "form_builder.rb.tt"

# NOTE: FormBuilder is an ActionView::Helpers::FormBuilder, not a
# ViewComponent. These tests call its Rails-named field methods directly
# and assert on the returned HTML via Capybara, rather than going through
# ViewComponent's test helpers — each field method still renders real
# UI::* components internally through the current view context. See
# test/test_catalog_completeness.rb's NOT_A_VIEWCOMPONENT carve-out for how
# the catalog's render-test gate accounts for that.
class B1Article
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string
  attribute :quantity, :integer
  attribute :body, :string
  attribute :terms, :boolean

  # ActiveModel::Attributes (unlike ActiveRecord::Base) does not define
  # `_before_type_cast` reader methods — that machinery is ActiveRecord-only.
  # A real ActiveRecord-backed form object gets this for free; this fixture
  # shim reproduces just enough of it so the builder's before_type_cast
  # fallback (see form_builder.rb.tt#field_value) is genuinely exercised.
  def quantity_before_type_cast
    @attributes["quantity"].value_before_type_cast
  end
end

class FormBuilderRenderTest < ViewComponent::TestCase
  def builder(object = B1Article.new, object_name: :b1_article)
    UI::FormBuilder.new(object_name, object, vc_test_controller.view_context, {})
  end

  def page_for(html)
    Capybara::Node::Simple.new(html.to_s)
  end

  # -- wrapped field wiring ---------------------------------------------------

  def test_text_field_binds_label_control_and_id_together
    page = page_for(builder.text_field(:title))

    assert page.has_css?("label[for='b1_article_title']", text: "Title")
    assert page.has_css?("[data-slot='control'] input#b1_article_title[type='text'][name='b1_article[title]']")
  end

  def test_help_renders_a_hint_below_the_control_wired_via_describedby
    page = page_for(builder.text_field(:title, help: "Shown on invoices"))

    assert page.has_css?("p#b1_article_title-hint", text: "Shown on invoices")
    assert page.has_css?("input[aria-describedby='b1_article_title-hint']")
  end

  def test_field_with_errors_renders_plain_error_paragraph_error_first_describedby
    article = B1Article.new
    article.errors.add(:title, "can't be blank")
    page = page_for(builder(article).text_field(:title, help: "h"))

    assert page.has_css?("p#b1_article_title-error", text: "can't be blank")
    refute page.has_css?("p#b1_article_title-error[role='alert']")
    assert page.has_css?("input[aria-invalid='true'][aria-describedby='b1_article_title-error b1_article_title-hint']")
  end

  # -- aria-required only, never native -------------------------------------

  def test_required_marks_the_label_and_sets_aria_required_but_never_native_required
    page = page_for(builder.text_field(:title, required: true))

    assert page.has_css?("label span[aria-hidden='true']", text: "*")
    assert page.has_css?("input[aria-required='true']")
    refute page.has_css?("input[required]")
  end

  # -- value resolution -------------------------------------------------------

  def test_value_uses_before_type_cast_so_failed_numeric_input_survives_rerender
    article = B1Article.new
    article.quantity = "abc"
    page = page_for(builder(article).number_field(:quantity))

    assert page.has_css?("input[value='abc']")
  end

  def test_caller_value_wins_even_when_nil
    article = B1Article.new(title: "Stored")
    page = page_for(builder(article).text_field(:title, value: nil))

    refute page.has_css?("input[value]")
  end

  # -- options contract -------------------------------------------------------

  def test_builder_never_mutates_the_caller_options_hash
    frozen = {required: true, help: "h"}.freeze

    builder.text_field(:title, frozen) # raises FrozenError if the builder mutates

    assert_predicate frozen, :frozen?
  end

  def test_caller_id_nil_is_honoured_not_replaced
    page = page_for(builder.text_field(:title, id: nil))

    refute page.has_css?("input[id]")
  end

  def test_label_false_suppresses_the_label
    page = page_for(builder.text_field(:title, label: false))

    refute page.has_css?("label")
  end

  # -- labels -----------------------------------------------------------------

  def test_label_defaults_to_human_attribute_name
    assert_equal "Title", B1Article.human_attribute_name(:title)
    page = page_for(builder.text_field(:title))

    assert page.has_css?("label", text: "Title")
  end

  # -- objectless forms -------------------------------------------------------

  def test_objectless_builder_still_binds_label_and_control
    page = page_for(builder(nil, object_name: :search).text_field(:query))

    assert page.has_css?("label[for='search_query']")
    assert page.has_css?("input#search_query[name='search[query]']")
  end

  def test_objectless_builder_renders_without_errors_values_or_aria_invalid
    page = page_for(builder(nil, object_name: :search).text_field(:query))

    refute page.has_css?("input[aria-invalid]")
    refute page.has_css?("p")
  end

  # -- password / textarea ----------------------------------------------------

  def test_password_field_defaults_autocomplete_new_password
    page = page_for(builder.password_field(:title))

    assert page.has_css?("input[type='password'][autocomplete='new-password']")
  end

  def test_text_area_renders_the_textarea_component_with_wiring
    article = B1Article.new(body: "Hello")
    page = page_for(builder(article).text_area(:body, help: "Markdown ok"))

    assert page.has_css?("textarea#b1_article_body[name='b1_article[body]'][aria-describedby='b1_article_body-hint']", text: "Hello")
  end

  def test_each_typed_input_renders_its_type
    %w[email url tel date search].each do |type|
      page = page_for(builder.public_send("#{type}_field", :title))

      assert page.has_css?("input[type='#{type}']"), "expected an input[type=#{type}]"
    end
  end

  # -- file_field ---------------------------------------------------------

  def test_file_field_is_brought_in_line_with_the_no_native_required_rule
    # Named behavior change: base's old builder passed native required for files.
    page = page_for(builder.file_field(:title, required: true))

    assert page.has_css?("input[type='file'][aria-required='true']")
    refute page.has_css?("input[type='file'][required]")
  end

  def test_file_field_multiple_gets_an_array_name
    page = page_for(builder.file_field(:title, multiple: true))

    assert page.has_css?("input[type='file'][multiple][name='b1_article[title][]']")
  end

  # -- select ---------------------------------------------------------------

  def test_select_renders_native_select_with_translated_aria
    article = B1Article.new
    article.errors.add(:title, "can't be blank")
    # `select` renders through native Rails `select` (via `super`), whose choice
    # pairs are [text, value] (see options_for_select) — the OPPOSITE of
    # SelectComponent's own [value, label] convention. Confirmed by rendering:
    # [["a", "A"]] produces <option value="A">a</option>, not the reverse.
    page = page_for(builder(article).select(:title, [["A", "a"], ["B", "b"]], help: "Pick one"))

    assert page.has_css?("select#b1_article_title[aria-invalid='true']" \
                         "[aria-describedby='b1_article_title-error b1_article_title-hint']")
    assert page.has_css?("option[value='a']", text: "A")
  end

  def test_select_gets_gem_chrome_not_the_host_app_phantom_class
    page = page_for(builder.select(:title, [["a", "A"], ["b", "B"]]))

    assert page.has_css?("select.ui-select")
    # SelectComponent::BASE chrome, not the base-app-only `form-field` phantom class:
    refute page.has_css?("select.form-field")
  end

  def test_select_required_is_aria_only
    page = page_for(builder.select(:title, %w[a b], required: true))

    assert page.has_css?("select[aria-required='true']")
    refute page.has_css?("select[required]")
  end

  def test_select_honours_caller_html_options
    page = page_for(builder.select(:title, %w[a b], {}, {"data-controller" => "auto-submit"}))

    assert page.has_css?("select[data-controller='auto-submit']")
  end

  def test_select_without_required_has_no_aria_required
    page = page_for(builder.select(:title, %w[a b]))

    refute page.has_css?("select[aria-required]")
  end
end
