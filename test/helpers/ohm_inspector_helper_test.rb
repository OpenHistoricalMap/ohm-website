# frozen_string_literal: true

require "test_helper"

class OhmInspectorHelperTest < ActionView::TestCase
  # The production IMAGE_DOMAIN_ALLOWLIST is intentionally empty (see
  # OhmInspectorHelper). Tests below stub a known allowlist so they cover
  # the helper logic regardless of what hosts the OHM team eventually trusts.
  setup do
    @original_image_allowlist = OhmInspectorHelper::IMAGE_DOMAIN_ALLOWLIST
    OhmInspectorHelper.send(:remove_const, :IMAGE_DOMAIN_ALLOWLIST)
    OhmInspectorHelper.const_set(:IMAGE_DOMAIN_ALLOWLIST,
                                 %w[upload.wikimedia.org commons.wikimedia.org].freeze)
  end

  teardown do
    OhmInspectorHelper.send(:remove_const, :IMAGE_DOMAIN_ALLOWLIST)
    OhmInspectorHelper.const_set(:IMAGE_DOMAIN_ALLOWLIST, @original_image_allowlist)
  end

  # ---------------------------------------------------------------------------
  # ohm_inspector_date_range
  # ---------------------------------------------------------------------------

  def test_date_range_returns_nil_when_no_dates
    assert_nil ohm_inspector_date_range({})
    assert_nil ohm_inspector_date_range("name" => "Foo")
  end

  def test_date_range_with_start_and_end
    result = ohm_inspector_date_range("start_date" => "1900", "end_date" => "1950")
    assert_includes result, "1900"
    assert_includes result, "1950"
  end

  def test_date_range_with_start_only
    result = ohm_inspector_date_range("start_date" => "1900")
    assert_not_nil result
    assert_includes result, "1900"
  end

  def test_date_range_with_end_only
    result = ohm_inspector_date_range("end_date" => "1950")
    assert_not_nil result
    assert_includes result, "1950"
  end

  def test_date_range_bce_year
    result = ohm_inspector_date_range("start_date" => "-200", "end_date" => "-100")
    assert_not_nil result
    assert_includes result, "BCE"
  end

  def test_date_range_does_not_suppress_one_million_bce
    # Regression test for https://github.com/OpenHistoricalMap/issues/issues/747
    # The old JS special-cased -1000000* as "no date" — we must not do the same.
    result = ohm_inspector_date_range("start_date" => "-1000000")
    assert_not_nil result
  end

  def test_date_range_does_not_suppress_one_million_ce
    # Regression test for https://github.com/OpenHistoricalMap/issues/issues/747
    result = ohm_inspector_date_range("end_date" => "1000000")
    assert_not_nil result
  end

  def test_date_range_with_full_iso_date_extracts_year
    result = ohm_inspector_date_range("start_date" => "1900-06-15", "end_date" => "1950-12-31")
    assert_includes result, "1900"
    assert_includes result, "1950"
  end

  # ---------------------------------------------------------------------------
  # ohm_inspector_image_url_safe? (issues #583 and #585)
  # ---------------------------------------------------------------------------

  def test_image_url_safe_for_allowlisted_host_with_image_extension
    assert ohm_inspector_image_url_safe?(
      "https://upload.wikimedia.org/wikipedia/commons/a/aa/Example.jpg"
    )
  end

  def test_image_url_safe_for_commons_filepath
    assert ohm_inspector_image_url_safe?(
      "https://commons.wikimedia.org/wiki/Special:FilePath/Example.jpg"
    )
  end

  def test_image_url_unsafe_when_allowlist_is_empty
    OhmInspectorHelper.send(:remove_const, :IMAGE_DOMAIN_ALLOWLIST)
    OhmInspectorHelper.const_set(:IMAGE_DOMAIN_ALLOWLIST, [].freeze)
    assert_not ohm_inspector_image_url_safe?(
      "https://upload.wikimedia.org/wikipedia/commons/a/aa/Example.jpg"
    )
  end

  def test_image_url_unsafe_for_disallowed_host
    assert_not ohm_inspector_image_url_safe?(
      "https://example.com/some/image.jpg"
    )
  end

  def test_image_url_unsafe_for_http
    assert_not ohm_inspector_image_url_safe?(
      "http://upload.wikimedia.org/wikipedia/commons/a/aa/Example.jpg"
    )
  end

  def test_image_url_unsafe_for_non_image_extension
    assert_not ohm_inspector_image_url_safe?(
      "https://upload.wikimedia.org/wikipedia/commons/a/aa/Example.txt"
    )
  end

  def test_image_url_unsafe_for_javascript_scheme
    assert_not ohm_inspector_image_url_safe?("javascript:alert(1)")
  end

  def test_image_url_unsafe_for_blank
    assert_not ohm_inspector_image_url_safe?(nil)
    assert_not ohm_inspector_image_url_safe?("")
  end

  def test_image_url_unsafe_for_invalid_uri
    assert_not ohm_inspector_image_url_safe?("not a url at all")
  end
end
