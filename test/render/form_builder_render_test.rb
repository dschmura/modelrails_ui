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

  # -- single checkbox --------------------------------------------------------

  def test_checkbox_row_is_one_44px_label_target_wrapping_input_and_caption
    page = page_for(builder.checkbox(:terms, label: "I accept the terms"))

    assert page.has_css?("label.min-h-11 input[type='checkbox']#b1_article_terms")
    assert page.has_css?("label.min-h-11", text: "I accept the terms")
  end

  def test_checkbox_gains_the_error_path_base_never_had
    article = B1Article.new
    article.errors.add(:terms, "must be accepted")
    page = page_for(builder(article).checkbox(:terms))

    assert page.has_css?("p#b1_article_terms-error", text: "must be accepted")
    assert page.has_css?("input[type='checkbox'][aria-invalid='true']" \
                         "[aria-describedby='b1_article_terms-error']")
  end

  def test_checkbox_required_is_aria_only_with_a_decorative_mark
    page = page_for(builder.checkbox(:terms, required: true))

    assert page.has_css?("input[type='checkbox'][aria-required='true']")
    refute page.has_css?("input[type='checkbox'][required]")
    assert page.has_css?("label span[aria-hidden='true']", text: "*")
  end

  def test_checkbox_multiple_derives_the_value_suffixed_id_for_its_label
    page = page_for(builder.checkbox(:terms, {multiple: true}, "admin"))

    assert page.has_css?("input[type='checkbox']#b1_article_terms_admin")
  end

  def test_check_box_legacy_name_produces_identical_output
    assert_equal builder.checkbox(:terms).to_s, builder.check_box(:terms).to_s
  end

  def test_checkbox_help_renders_a_hint_paragraph_wired_via_describedby_not_a_help_attribute
    page = page_for(builder.checkbox(:terms, help: "Required before you can submit"))

    assert page.has_css?("p#b1_article_terms-hint", text: "Required before you can submit")
    assert page.has_css?("input[type='checkbox'][aria-describedby='b1_article_terms-hint']")
    refute page.has_css?("input[help]")
  end

  def test_checkbox_help_and_error_together_describedby_lists_error_first
    article = B1Article.new
    article.errors.add(:terms, "must be accepted")
    page = page_for(builder(article).checkbox(:terms, help: "Read the terms first"))

    assert page.has_css?("input[type='checkbox']" \
                         "[aria-describedby='b1_article_terms-error b1_article_terms-hint']")
    assert page.has_css?("p#b1_article_terms-hint", text: "Read the terms first")
    assert page.has_css?("p#b1_article_terms-error", text: "must be accepted")
  end

  def test_checkbox_explicit_id_nil_skips_describedby_wiring_without_degenerate_ids
    article = B1Article.new
    article.errors.add(:terms, "must be accepted")
    page = page_for(builder(article).checkbox(:terms, id: nil, help: "Read the terms first"))

    refute page.has_css?("[id='-error']")
    refute page.has_css?("[id='-hint']")
    refute page.has_css?("input[aria-describedby]")
  end

  def test_checkbox_explicit_id_nil_still_renders_the_hint_and_error_text
    # Only the id-derived wiring is skipped — the text itself still renders.
    article = B1Article.new
    article.errors.add(:terms, "must be accepted")
    page = page_for(builder(article).checkbox(:terms, id: nil, help: "Read the terms first"))

    assert page.has_css?("p", text: "must be accepted")
    assert page.has_css?("p", text: "Read the terms first")
  end

  # -- collections ------------------------------------------------------------

  ROLES = [["1", "Admin"], ["2", "Editor"]].freeze

  def test_collection_checkboxes_fieldset_carries_group_describedby
    article = B1Article.new
    article.errors.add(:title, "pick at least one")
    html = builder(article).collection_checkboxes(:title, ROLES, :first, :last, help: "Who can edit")
    page = page_for(html)

    assert page.has_css?("fieldset[aria-describedby='b1_article_title-error b1_article_title-hint']")
    assert page.has_css?("fieldset legend", text: "Title")
  end

  def test_collection_checkboxes_fieldset_carries_hint_and_error_paragraphs
    article = B1Article.new
    article.errors.add(:title, "pick at least one")
    html = builder(article).collection_checkboxes(:title, ROLES, :first, :last, help: "Who can edit")
    page = page_for(html)

    assert page.has_css?("p#b1_article_title-hint", text: "Who can edit")
    assert page.has_css?("p#b1_article_title-error", text: "pick at least one")
  end

  def test_collection_checkboxes_inputs_carry_aria_invalid_so_forms_mode_arrival_hears_the_state
    article = B1Article.new
    article.errors.add(:title, "pick at least one")
    page = page_for(builder(article).collection_checkboxes(:title, ROLES, :first, :last))

    assert_equal 2, page.all("input[type='checkbox'][aria-invalid='true']").size
  end

  def test_collection_rows_are_44px_label_targets
    page = page_for(builder.collection_checkboxes(:title, ROLES, :first, :last))

    assert_equal 2, page.all("fieldset label.min-h-11 input[type='checkbox']").size
  end

  def test_collection_check_boxes_legacy_name_produces_identical_output
    assert_equal builder.collection_checkboxes(:title, ROLES, :first, :last).to_s,
      builder.collection_check_boxes(:title, ROLES, :first, :last).to_s
  end

  def test_collection_radio_buttons_mirror_the_checkbox_group_contract
    article = B1Article.new
    article.errors.add(:title, "pick one")
    page = page_for(builder(article).collection_radio_buttons(:title, ROLES, :first, :last))

    assert page.has_css?("fieldset[aria-describedby='b1_article_title-error']")
    assert_equal 2, page.all("fieldset label.min-h-11 input[type='radio'][aria-invalid='true']").size
  end

  def test_collection_radio_buttons_keeps_checkbox_classes_when_caller_passes_a_class
    page = page_for(builder.collection_radio_buttons(:title, ROLES, :first, :last, {},
      {class: "auto-submit"}))

    # Caller class is additive, not a replacement — dropping CHECKBOX_CLASSES here
    # would leave radio rows unstyled and out of the accent color system.
    assert_equal 2, page.all("input[type='radio'].auto-submit.text-interactive").size
  end

  # -- submit -------------------------------------------------------------

  def test_submit_defaults_to_btn_primary
    page = page_for(builder.submit("Save"))

    assert page.has_css?("input[type='submit'].btn-primary")
  end

  def test_submit_caller_class_replaces_the_default_not_merges
    # Replace semantics: predictable, loud failure mode. A merge yields
    # "btn-primary btn-secondary" with stylesheet order deciding the winner.
    page = page_for(builder.submit("Save draft", class: "btn-secondary"))

    assert page.has_css?("input[type='submit'].btn-secondary")
    refute page.has_css?("input[type='submit'].btn-primary")
  end

  # -- error_summary shim ---------------------------------------------------

  def test_error_summary_renders_nothing_without_errors
    # ErrorSummaryComponent#render? returns false with no items, and
    # @template.render of a non-rendering component returns "" (not nil) on
    # this ViewComponent version — assert blank output, not identity-nil, so
    # the assertion states what actually happens rather than what would be
    # convenient.
    output = builder.error_summary

    assert_predicate output.to_s, :blank?
  end

  def test_error_summary_links_each_error_to_its_field
    article = B1Article.new
    article.errors.add(:title, "can't be blank")
    article.errors.add(:base, "is a duplicate")
    page = page_for(builder(article).error_summary)

    assert page.has_css?("div[role='alert'][tabindex='-1'][autofocus]")
    assert page.has_css?("li a[href='#b1_article_title']", text: "Title can't be blank")
    assert page.has_css?("li", text: "is a duplicate")
  end

  def test_error_summary_does_not_link_the_base_error_to_a_field
    article = B1Article.new
    article.errors.add(:base, "is a duplicate")
    page = page_for(builder(article).error_summary)

    refute page.has_css?("li a[href='#b1_article_base']")
  end

  def test_error_summary_forwards_heading_level
    article = B1Article.new
    article.errors.add(:title, "can't be blank")
    page = page_for(builder(article).error_summary(heading_level: 3))

    assert page.has_css?("h3")
  end
end
