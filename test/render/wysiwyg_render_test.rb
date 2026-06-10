# frozen_string_literal: true

require "render_test_helper"
load_component "wysiwyg", "wysiwyg_component.rb.tt"

# STRUCTURE-only render specs. Wysiwyg is a rich-text editor adapter (Trix/Quill).
# It is SUPERSEDED by Lexxy in the host app, so it gets gem-side hardening + a 0a
# render test only — no app adoption and no app 0b. Here we assert the
# accessibility contract: a labelled editor region, named + focus-ringed toolbar
# toggle buttons, semantic AAA tokens, fail-loud on a bad adapter, and html_attrs
# passthrough. A real browser would prove AAA contrast; this is the scaffolding.
class WysiwygRenderTest < ViewComponent::TestCase
  # --- Trix (default adapter) ---

  def test_default_adapter_renders_a_labelled_trix_editor_region
    render_inline(UI::WysiwygComponent.new(name: "body"))

    # The editor region carries an accessible name (i18n default) + textbox role.
    assert_selector "trix-editor[role='textbox'][aria-multiline='true'][aria-label='Rich text editor']", visible: :all
    # And the hidden input wires the form field name.
    assert_selector "input[type='hidden'][name='body']", visible: :all
  end

  def test_custom_label_names_the_editor_region
    render_inline(UI::WysiwygComponent.new(name: "body", label: "Article body"))

    assert_selector "trix-editor[aria-label='Article body']", visible: :all
  end

  def test_editor_carries_the_focus_ring_not_an_outline_none
    render_inline(UI::WysiwygComponent.new(name: "body"))

    assert_selector "trix-editor.focus-ring", visible: :all
  end

  # --- Toolbar buttons: accessible names + pressed state + focus-ring ---

  def test_toolbar_is_a_named_landmark
    render_inline(UI::WysiwygComponent.new(name: "body"))

    assert_selector "div[role='toolbar'][aria-label='Formatting']", visible: :all
  end

  # Every Trix toolbar control is wired to its attribute AND carries an i18n
  # accessible name (data-driven so it stays a single logical assertion).
  EXPECTED_BUTTONS = {
    "bold" => "Bold",
    "italic" => "Italic",
    "strike" => "Strikethrough",
    "href" => "Link",
    "bullet" => "Bulleted list",
    "number" => "Numbered list"
  }.freeze

  def test_toolbar_buttons_have_i18n_accessible_names
    render_inline(UI::WysiwygComponent.new(name: "body"))

    EXPECTED_BUTTONS.each do |attribute, label|
      assert_selector "button[aria-label='#{label}'][data-trix-attribute='#{attribute}']", visible: :all
    end
  end

  def test_toolbar_buttons_advertise_toggle_state_and_carry_the_focus_ring
    render_inline(UI::WysiwygComponent.new(name: "body"))

    # Every toolbar control is a real toggle button with an offset focus-ring.
    assert_selector "button.focus-ring[type='button'][aria-pressed='false']", minimum: 6, visible: :all
  end

  def test_toolbar_can_be_suppressed
    render_inline(UI::WysiwygComponent.new(name: "body", toolbar: false))

    assert_no_selector "div[role='toolbar']", visible: :all
    assert_no_selector "button[data-trix-attribute]", visible: :all
    # The editor still renders and stays labelled.
    assert_selector "trix-editor[aria-label='Rich text editor']", visible: :all
  end

  # --- Quill adapter ---

  def test_quill_adapter_renders_a_labelled_editor_wired_to_the_controller
    render_inline(UI::WysiwygComponent.new(name: "body", adapter: :quill))

    assert_selector "div[data-controller='wysiwyg'][data-wysiwyg-adapter-value='quill']", visible: :all
    assert_selector "div[data-wysiwyg-target='editor'][role='textbox'][aria-multiline='true'][aria-label='Rich text editor'].focus-ring", visible: :all
    assert_selector "input[type='hidden'][name='body'][data-wysiwyg-target='input']", visible: :all
  end

  # --- AAA semantic tokens (the design-token guarantee), not raw Tailwind ---

  def test_renders_with_aaa_semantic_tokens
    render_inline(UI::WysiwygComponent.new(name: "body"))

    # Wrapper + editor use semantic surface/border/text tokens, never raw palette.
    assert_selector "div.bg-surface-raised.border-border-strong"
    assert_selector "trix-editor.text-text-body", visible: :all
    # Toolbar buttons use the semantic body/heading text tokens.
    assert_selector "button.text-text-body", visible: :all
  end

  # The aria-pressed active surface is a `&`/`[`-style arbitrary variant; assert it
  # via a substring class match (the literal class carries brackets).
  def test_toolbar_button_active_surface_keys_off_aria_pressed
    render_inline(UI::WysiwygComponent.new(name: "body"))

    assert_selector "button[class*='aria-pressed:bg-surface-sunken']", visible: :all
  end

  # Regression guard: the ring/outline-none anti-patterns must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_inline(UI::WysiwygComponent.new(name: "body"))
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "focus:ring-"
    refute_includes html, "outline-none"
  end

  # --- Fail loud on a bad enum ---

  def test_unknown_adapter_raises
    assert_raises(ArgumentError) do
      render_inline(UI::WysiwygComponent.new(name: "body", adapter: :bogus))
    end
  end

  # --- html_attrs passthrough onto the root, matching the sibling components ---

  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::WysiwygComponent.new(name: "body", id: "post-body", data: {testid: "wysiwyg"}))

    assert_selector "div#post-body[data-testid='wysiwyg']"
  end

  # A caller-supplied class merges onto the root without clobbering the wrapper tokens.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::WysiwygComponent.new(name: "body", class: "mt-4"))

    assert_selector "div.mt-4.bg-surface-raised"
  end
end
