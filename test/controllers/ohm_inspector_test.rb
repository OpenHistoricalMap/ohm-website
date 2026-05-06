# frozen_string_literal: true

require "test_helper"

# Integration tests for the OHM Inspector panel (_ohm_details partial).
# The partial is rendered inside elements/show, so we exercise it via the
# nodes/ways/relations controller show actions.
class OhmInspectorTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Panel is absent when the feature has no inspector-relevant tags
  # ---------------------------------------------------------------------------

  def test_panel_absent_for_plain_node
    node = create(:node)
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-panel", :count => 0
  end

  def test_panel_absent_for_invisible_node
    node = create(:node, :deleted)
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-panel", :count => 0
  end

  # ---------------------------------------------------------------------------
  # Image slideshow
  # ---------------------------------------------------------------------------

  def test_single_image_renders_no_nav_buttons
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://upload.wikimedia.org/wikipedia/commons/a/a.jpg")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-slideshow", :count => 1
    assert_dom ".ohm-inspector-slide",     :count => 1
    assert_dom ".ohm-inspector-slideshow-prev", :count => 0
    assert_dom ".ohm-inspector-slideshow-next", :count => 0
  end

  def test_multiple_images_render_nav_buttons
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://upload.wikimedia.org/wikipedia/commons/a/a.jpg")
    create(:node_tag, :node => node, :k => "image:2", :v => "https://upload.wikimedia.org/wikipedia/commons/b/b.jpg")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-slide",          :count => 2
    assert_dom ".ohm-inspector-slideshow-prev", :count => 1
    assert_dom ".ohm-inspector-slideshow-next", :count => 1
  end

  def test_second_and_later_slides_are_initially_hidden
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://upload.wikimedia.org/wikipedia/commons/a/a.jpg")
    create(:node_tag, :node => node, :k => "image:2", :v => "https://upload.wikimedia.org/wikipedia/commons/b/b.jpg")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-slide:not(.ohm-inspector-slide--hidden)", :count => 1
    assert_dom ".ohm-inspector-slide.ohm-inspector-slide--hidden",       :count => 1
  end

  def test_image_caption_rendered_when_present
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://upload.wikimedia.org/wikipedia/commons/a/a.jpg")
    create(:node_tag, :node => node, :k => "image:1:caption", :v => "Old City Hall")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-slide-caption", :text => /Old City Hall/
  end

  def test_image_tag_stops_at_gap
    # image:3 is absent — image:4 should not appear
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://upload.wikimedia.org/wikipedia/commons/a/a.jpg")
    create(:node_tag, :node => node, :k => "image:2", :v => "https://upload.wikimedia.org/wikipedia/commons/b/b.jpg")
    create(:node_tag, :node => node, :k => "image:4", :v => "https://upload.wikimedia.org/wikipedia/commons/c/c.jpg")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-slide", :count => 2
  end

  # ---------------------------------------------------------------------------
  # Date range
  # ---------------------------------------------------------------------------

  def test_date_range_rendered_when_present
    node = create(:node)
    create(:node_tag, :node => node, :k => "start_date", :v => "1900")
    create(:node_tag, :node => node, :k => "end_date",   :v => "1950")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-dates", :count => 1
    assert_dom ".ohm-inspector-dates", :text => /1900/
    assert_dom ".ohm-inspector-dates", :text => /1950/
  end

  def test_date_range_absent_when_no_dates
    node = create(:node)
    create(:node_tag, :node => node, :k => "name", :v => "Foo")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-dates", :count => 0
  end

  def test_date_range_carries_data_attributes_for_timeslider
    # data-start-date / data-end-date are needed by issue #1323
    node = create(:node)
    create(:node_tag, :node => node, :k => "start_date", :v => "1900")
    create(:node_tag, :node => node, :k => "end_date",   :v => "1950")
    get node_path(node)
    assert_dom ".ohm-inspector-dates[data-start-date='1900'][data-end-date='1950']", :count => 1
  end

  # ---------------------------------------------------------------------------
  # Wikipedia excerpt placeholder
  # ---------------------------------------------------------------------------

  def test_wikipedia_placeholder_rendered_for_wikipedia_tag
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikipedia", :v => "en:Seattle")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikipedia-url]", :count => 1
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikidata-id]",   :count => 0
  end

  def test_wikipedia_placeholder_for_non_english_wikipedia_tag
    # Regression for https://github.com/OpenHistoricalMap/issues/issues/859
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikipedia", :v => "pt:Algoso_Castle")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikipedia-url*='pt.wikipedia.org']", :count => 1
  end

  def test_wikidata_placeholder_rendered_when_no_wikipedia_tag
    # Regression for https://github.com/OpenHistoricalMap/issues/issues/584
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikidata", :v => "Q1234")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikidata-id='Q1234']", :count => 1
  end

  def test_wikipedia_placeholder_takes_priority_over_wikidata
    # When both are present the wikipedia URL is used; no wikidata fallback needed
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikipedia", :v => "en:Seattle")
    create(:node_tag, :node => node, :k => "wikidata",  :v => "Q1234")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikipedia-url]", :count => 1
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikidata-id]",   :count => 0
  end

  # ---------------------------------------------------------------------------
  # More-info links
  # ---------------------------------------------------------------------------

  def test_more_info_links_rendered
    node = create(:node)
    create(:node_tag, :node => node, :k => "more_info:1",      :v => "https://example.com/foo")
    create(:node_tag, :node => node, :k => "more_info:1:name", :v => "Example Site")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-more-info", :count => 1
    assert_dom ".ohm-inspector-more-info a[href='https://example.com/foo']", :text => "Example Site"
  end

  def test_more_info_link_uses_fallback_text_when_name_absent
    node = create(:node)
    create(:node_tag, :node => node, :k => "more_info:1", :v => "https://example.com/foo")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-more-info a[href='https://example.com/foo']", :text => "(link)"
  end

  def test_more_info_stops_at_gap
    node = create(:node)
    create(:node_tag, :node => node, :k => "more_info:1", :v => "https://example.com/one")
    create(:node_tag, :node => node, :k => "more_info:3", :v => "https://example.com/three")
    get node_path(node)
    assert_dom ".ohm-inspector-more-info li", :count => 1
  end

  # ---------------------------------------------------------------------------
  # No missing translations
  # ---------------------------------------------------------------------------

  def test_no_missing_translations_in_panel
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1",         :v => "https://upload.wikimedia.org/wikipedia/commons/a/a.jpg")
    create(:node_tag, :node => node, :k => "image:2",         :v => "https://upload.wikimedia.org/wikipedia/commons/b/b.jpg")
    create(:node_tag, :node => node, :k => "start_date",      :v => "1900")
    create(:node_tag, :node => node, :k => "end_date",        :v => "1950")
    create(:node_tag, :node => node, :k => "wikipedia",       :v => "en:Seattle")
    create(:node_tag, :node => node, :k => "more_info:1",     :v => "https://example.com/")
    create(:node_tag, :node => node, :k => "more_info:1:name",:v => "More")
    get node_path(node)
    assert_response :success
    assert_dom "span.translation_missing", :count => 0
  end
end
