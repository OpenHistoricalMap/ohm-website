# frozen_string_literal: true

require "test_helper"

class OhmInspectorHelperTest < ActionView::TestCase
  # ---------------------------------------------------------------------------
  # ohm_inspector_wikipedia_url
  # ---------------------------------------------------------------------------

  def test_wikipedia_url_returns_nil_when_no_tags
    assert_nil ohm_inspector_wikipedia_url({})
  end

  def test_wikipedia_url_returns_full_url_unchanged
    url = "https://en.wikipedia.org/wiki/Seattle"
    assert_equal url, ohm_inspector_wikipedia_url("wikipedia" => url)
  end

  def test_wikipedia_url_returns_http_url_unchanged
    url = "http://en.wikipedia.org/wiki/Seattle"
    assert_equal url, ohm_inspector_wikipedia_url("wikipedia" => url)
  end

  def test_wikipedia_url_constructs_english_url_from_bare_title
    # value has no language prefix — assume English
    assert_equal "https://en.wikipedia.org/wiki/Seattle",
                 ohm_inspector_wikipedia_url("wikipedia" => "Seattle")
  end

  def test_wikipedia_url_constructs_english_url_from_en_prefix
    assert_equal "https://en.wikipedia.org/wiki/Hotel_Seattle",
                 ohm_inspector_wikipedia_url("wikipedia" => "en:Hotel_Seattle")
  end

  def test_wikipedia_url_constructs_non_english_url_from_language_prefix
    # Regression test for https://github.com/OpenHistoricalMap/issues/issues/859
    assert_equal "https://pt.wikipedia.org/wiki/Algoso_Castle",
                 ohm_inspector_wikipedia_url("wikipedia" => "pt:Algoso_Castle")
  end

  def test_wikipedia_url_supports_three_char_language_prefix
    assert_equal "https://nds.wikipedia.org/wiki/Hamburg",
                 ohm_inspector_wikipedia_url("wikipedia" => "nds:Hamburg")
  end

  def test_wikipedia_url_from_wikipedia_colon_key
    # wikipedia:en=Title (legacy tagging style)
    assert_equal "https://en.wikipedia.org/wiki/Seattle",
                 ohm_inspector_wikipedia_url("wikipedia:en" => "Seattle")
  end

  def test_wikipedia_url_from_non_english_wikipedia_colon_key
    assert_equal "https://pt.wikipedia.org/wiki/Algoso_Castle",
                 ohm_inspector_wikipedia_url("wikipedia:pt" => "Algoso_Castle")
  end

  def test_wikipedia_url_prefers_wikipedia_key_over_wikipedia_colon_key
    # If both are present, the plain `wikipedia` key wins
    result = ohm_inspector_wikipedia_url(
      "wikipedia"    => "en:Primary",
      "wikipedia:de" => "Secondary"
    )
    assert_equal "https://en.wikipedia.org/wiki/Primary", result
  end

  def test_wikipedia_url_ignores_non_wikipedia_tags
    assert_nil ohm_inspector_wikipedia_url(
      "wikidata" => "Q12345",
      "name"     => "Some Place"
    )
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
    # start_date / end_date are often full ISO dates in OHM data
    result = ohm_inspector_date_range("start_date" => "1900-06-15", "end_date" => "1950-12-31")
    assert_includes result, "1900"
    assert_includes result, "1950"
  end
end
