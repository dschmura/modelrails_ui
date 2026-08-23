# frozen_string_literal: true

require "system_test_helper"
require "base64"

# Two AES-256 keys a host would deliver via <meta name="form-draft-key">; the
# second plays the rotated key after a deploy changes the scope digest.
module FormDraftTestKeys
  KEY_ONE = Base64.strict_encode64("\x00" * 32)
  KEY_TWO = Base64.strict_encode64("\x01" * 32)
end

BrowserHarness.scenario("form_draft/lifecycle", controllers: %w[form-draft]) do
  <<~HTML
    <meta name="form-draft-scope" content="digest-one">
    <meta name="form-draft-key" content="#{FormDraftTestKeys::KEY_ONE}">
    <form id="draft-form" action="/articles" method="post"
          data-controller="form-draft"
          data-form-draft-key-value="rotation-test"
          data-action="input->form-draft#save">
      <div data-form-draft-target="notice" hidden>
        <button type="button" data-action="form-draft#recover">Recover draft</button>
        <button type="button" data-action="form-draft#discard">Discard draft</button>
      </div>
      <div data-form-draft-target="status" role="status" aria-live="polite" aria-atomic="true"
           data-found-text="Recoverable draft found."
           data-restored-text="Draft restored. %{count} fields updated."
           data-discarded-text="Draft discarded."></div>
      <label>Title <input type="text" name="title" value="hello"></label>
    </form>
  HTML
end

# The render lane proves the markup contract; only this lane can see the two
# lifecycle bugs from the 2026-07 review: an announcement timer outliving its
# controller (#74) and the module-level key cache surviving a scope-digest
# rotation (#73).
class FormDraftSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("form_draft/lifecycle")
  end

  # Control: proves announce() actually fires while connected, so the
  # disconnect test below cannot pass vacuously.
  def test_discard_announces_into_the_status_region
    page.execute_script(%{document.querySelector('[data-action="form-draft#discard"]').click()})

    assert page.has_css?('[data-form-draft-target="status"]', text: "Draft discarded.")
    assert_no_stimulus_errors
  end

  # #74: announce() schedules rAF -> setTimeout(100ms); disconnect() must
  # cancel the chain or the write lands on a detached node — and on a Turbo
  # cache restore of the same element, a stale announcement.
  def test_disconnect_cancels_a_pending_announcement
    page.execute_script(<<~JS)
      const form = document.getElementById("draft-form")
      window.__status = form.querySelector('[data-form-draft-target="status"]')
      form.querySelector('[data-action="form-draft#discard"]').click()
      form.remove()
    JS
    sleep 0.4 # well past the rAF + 100ms announcement delay

    assert_equal "", page.evaluate_script("window.__status.textContent"),
      "a pending announcement fired after disconnect()"
  end

  # #73: rotate scope digest + key meta (a deploy), reconnect the form, save.
  # The new draft must decrypt with the ROTATED key; the stale cached key
  # would strand every draft written after the rotation.
  def test_scope_rotation_reimports_the_key_before_the_next_save
    page.execute_script(<<~JS)
      document.querySelector('meta[name="form-draft-scope"]').content = "digest-two"
      const rotated = document.createElement("meta")
      rotated.name = "form-draft-key"
      rotated.content = "#{FormDraftTestKeys::KEY_TWO}"
      document.head.append(rotated)
      const form = document.getElementById("draft-form")
      const parent = form.parentElement
      form.remove()
      parent.append(form)
    JS
    page.execute_script(<<~JS)
      const field = document.querySelector('input[name="title"]')
      field.value = "rotated draft"
      field.dispatchEvent(new Event("input", { bubbles: true }))
    JS

    result = page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      setTimeout(async () => {
        try {
          const key = Object.keys(localStorage).find((k) => k.startsWith("draft:v1:digest-two:"))
          if (!key) return done({ ok: false, reason: "no draft stored under the rotated digest" })
          const bytes = Uint8Array.from(atob(localStorage.getItem(key)), (c) => c.charCodeAt(0))
          const rotated = await crypto.subtle.importKey(
            "raw",
            Uint8Array.from(atob("#{FormDraftTestKeys::KEY_TWO}"), (c) => c.charCodeAt(0)),
            "AES-GCM", false, ["decrypt"]
          )
          try {
            await crypto.subtle.decrypt(
              { name: "AES-GCM", iv: bytes.subarray(0, 12),
                additionalData: new TextEncoder().encode(key), tagLength: 128 },
              rotated, bytes.subarray(12)
            )
            done({ ok: true })
          } catch {
            done({ ok: false, reason: "draft was not encrypted with the rotated key" })
          }
        } catch (e) {
          done({ ok: false, reason: e.message })
        }
      }, 600) // past the 300ms save debounce + encryption
    JS

    assert result["ok"], "after rotation: #{result["reason"]}"
    assert_no_stimulus_errors
  end
end
