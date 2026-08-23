# Every assertion here holds on the currently pinned Rack and on any later 3.0.x: these test
# this endpoint's behaviour, not the advisory. A suite that failed on the pinned version would
# make the baseline red and credit a remediation with a fix it did not make.
require "minitest/autorun"
require "rbnotify/delivery"

class DeliveryTest < Minitest::Test
  def test_media_type_ignores_parameters
    assert_equal "application/json",
                 RBNotify::Delivery.media_type("application/json; charset=utf-8")
  end

  def test_media_type_is_lowercased
    assert_equal "application/json", RBNotify::Delivery.media_type("Application/JSON")
  end

  def test_media_type_of_a_bare_type
    assert_equal "text/plain", RBNotify::Delivery.media_type("text/plain")
  end

  def test_charset_is_read_from_the_parameters
    assert_equal "iso-8859-1",
                 RBNotify::Delivery.charset("application/json; charset=iso-8859-1")
  end

  def test_charset_defaults_when_absent
    assert_equal RBNotify::DEFAULT_CHARSET,
                 RBNotify::Delivery.charset("application/json")
  end

  def test_accepts_plain_json
    assert RBNotify::Delivery.acceptable?("application/json")
  end

  def test_accepts_the_vendor_type
    assert RBNotify::Delivery.acceptable?("application/notification+json; charset=utf-8")
  end

  def test_rejects_form_encoding
    refute RBNotify::Delivery.acceptable?("application/x-www-form-urlencoded")
  end

  def test_rejects_an_empty_content_type
    refute RBNotify::Delivery.acceptable?("")
  end

  def test_rejects_a_missing_content_type
    refute RBNotify::Delivery.acceptable?(nil)
  end

  def test_charset_defaults_for_a_missing_content_type
    assert_equal RBNotify::DEFAULT_CHARSET, RBNotify::Delivery.charset(nil)
  end

  def test_call_accepts_a_valid_payload
    status, headers, = RBNotify::Delivery.call("application/json", '{"a":1}')
    assert_equal 202, status
    assert_equal "application/json", headers["content-type"]
  end

  def test_call_reports_the_byte_size
    _, _, body = RBNotify::Delivery.call("application/json", "abcd")
    assert_includes body.first, '"bytes":4'
  end

  def test_call_rejects_an_unsupported_type
    assert_raises(RBNotify::UnsupportedType) do
      RBNotify::Delivery.call("text/html", "<p>no</p>")
    end
  end

  def test_call_counts_multibyte_bodies_in_bytes
    _, _, body = RBNotify::Delivery.call("application/json", "\u00e9")
    assert_includes body.first, '"bytes":2'
  end
end
