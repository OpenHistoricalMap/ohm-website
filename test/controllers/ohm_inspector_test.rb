# frozen_string_literal: true

require "test_helper"

# Integration tests for the OHM Inspector panel (_ohm_details partial).
# The partial is rendered inside elements/show, so we exercise it via the
# nodes/ways/relations controller show actions.
class OhmInspectorTest < ActionDispatch::IntegrationTest
  # The production IMAGE_DOMAIN_ALLOWLIST is intentionally empty (see
  # OhmInspectorHelper). For tests that exercise image rendering, stub a
  # known allowlist so they cover the partial's behavior independently of
  # what hosts the OHM team eventually trusts.
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

  def test_image_from_disallowed_host_is_dropped
    # Regression for https://github.com/OpenHistoricalMap/issues/issues/585
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://example.com/foo.jpg")
    get node_path(node)
    assert_dom ".ohm-inspector-slideshow", :count => 0
  end

  def test_image_with_non_image_extension_is_dropped
    # Regression for https://github.com/OpenHistoricalMap/issues/issues/583
    node = create(:node)
    create(:node_tag, :node => node, :k => "image:1", :v => "https://upload.wikimedia.org/wikipedia/commons/a/Example.html")
    get node_path(node)
    assert_dom ".ohm-inspector-slideshow", :count => 0
  end

  def test_wikimedia_commons_file_renders_as_image
    # https://github.com/OpenHistoricalMap/issues/issues/581
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikimedia_commons", :v => "File:Example.jpg")
    get node_path(node)
    assert_dom ".ohm-inspector-slide-img[src*='Special:FilePath/Example.jpg']", :count => 1
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
    assert_dom "p.ohm-inspector-dates", :count => 1
    assert_dom "p.ohm-inspector-dates", :text => /1900/
    assert_dom "p.ohm-inspector-dates", :text => /1950/
  end

  def test_date_range_absent_when_no_dates
    node = create(:node)
    create(:node_tag, :node => node, :k => "name", :v => "Foo")
    get node_path(node)
    assert_response :success
    assert_dom "p.ohm-inspector-dates", :count => 0
  end

  def test_date_range_carries_data_attributes_for_timeslider
    # data-start-date / data-end-date are needed by issue #1323
    node = create(:node)
    create(:node_tag, :node => node, :k => "start_date", :v => "1900")
    create(:node_tag, :node => node, :k => "end_date",   :v => "1950")
    get node_path(node)
    assert_dom "p.ohm-inspector-dates[data-start-date='1900'][data-end-date='1950']", :count => 1
  end

  def test_date_range_does_not_have_brackets
    node = create(:node)
    create(:node_tag, :node => node, :k => "start_date", :v => "1900")
    get node_path(node)
    line = css_select("p.ohm-inspector-dates").text
    assert_includes line, "1900"
    assert_not_includes line, "["
    assert_not_includes line, "]"
  end

  def test_local_name_rendered_bold
    node = create(:node)
    create(:node_tag, :node => node, :k => "name", :v => "Old City Hall")
    get node_path(node)
    assert_dom ".ohm-inspector-local-name strong bdi", :text => "Old City Hall"
  end

  # ---------------------------------------------------------------------------
  # Wikidata-driven Wikipedia excerpt + bottom links
  # ---------------------------------------------------------------------------

  def test_wikidata_placeholder_rendered
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikidata", :v => "Q1234")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-wikipedia-excerpt[data-wikidata-id='Q1234']", :count => 1
  end

  def test_wikidata_badge_rendered_with_label_for_a11y
    # The visible glyph is a short "WD" badge; the full localized name is
    # preserved as title / aria-label for accessibility.
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikidata", :v => "Q1234")
    get node_path(node)
    assert_response :success
    assert_dom ".ohm-inspector-wikidata-link[href='https://www.wikidata.org/wiki/Q1234']" \
               "[title='Wikidata'][aria-label='Wikidata']", :count => 1
  end

  def test_wikipedia_badge_rendered_hidden_for_js_to_fill
    # The Wikipedia badge starts hidden; ohm_inspector.js resolves the QID
    # to a localized sitelink, sets href, and removes the hidden attribute.
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikidata", :v => "Q1234")
    get node_path(node)
    assert_dom ".ohm-inspector-wikipedia-link[hidden][title='Wikipedia']", :count => 1
  end

  def test_no_wikipedia_or_wikidata_block_without_wikidata_tag
    # Regression: a `wikipedia` tag without `wikidata` no longer triggers the
    # excerpt or badges — everything is driven by the QID.
    node = create(:node)
    create(:node_tag, :node => node, :k => "wikipedia", :v => "en:Seattle")
    get node_path(node)
    assert_dom ".ohm-inspector-wikipedia-excerpt",  :count => 0
    assert_dom ".ohm-inspector-wikipedia-block",    :count => 0
    assert_dom ".ohm-inspector-wikipedia-link",     :count => 0
    assert_dom ".ohm-inspector-wikidata-link",      :count => 0
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
  # Sidebar title and "Type (id)" subheader placement
  # ---------------------------------------------------------------------------

  def test_sidebar_title_is_just_the_name
    node = create(:node)
    create(:node_tag, :node => node, :k => "name", :v => "Old City Hall")
    get node_path(node)
    assert_response :success
    title = css_select("h2").text
    assert_includes title, "Old City Hall"
    assert_not_includes title, "Node:"
    assert_not_includes title, "(#{node.id})"
  end

  def test_sidebar_title_excludes_date_range
    # Date range belongs in its own paragraph below the bold local name.
    node = create(:node)
    create(:node_tag, :node => node, :k => "name",       :v => "Old City Hall")
    create(:node_tag, :node => node, :k => "start_date", :v => "1900")
    create(:node_tag, :node => node, :k => "end_date",   :v => "1950")
    get node_path(node)
    title = css_select("h2").text
    assert_includes title, "Old City Hall"
    assert_not_includes title, "1900"
    assert_not_includes title, "1950"
  end

  def test_element_id_subheader_uses_combined_format
    # Format: "[Type]/[id] v[version]" all on one line
    node = create(:node)
    get node_path(node)
    assert_response :success
    assert_dom "h3.ohm-inspector-element-id", :text => /Node\/#{node.id}\s+v#{node.version}/
  end

  def test_element_id_subheader_uses_localized_type_label
    way = create(:way)
    get way_path(way)
    assert_response :success
    assert_dom "h3.ohm-inspector-element-id", :text => /Way\/#{way.id}/
  end

  def test_upstream_version_h4_hidden_on_current_version_page
    # The H4 is suppressed on elements/show because the inspector's H3
    # already shows "[Type]/[id] v[v]". (It still renders on old-version pages.)
    node = create(:node)
    get node_path(node)
    assert_dom "h4", :text => /Version\s+#/, :count => 0
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
    create(:node_tag, :node => node, :k => "wikidata",        :v => "Q1234")
    create(:node_tag, :node => node, :k => "more_info:1",     :v => "https://example.com/")
    create(:node_tag, :node => node, :k => "more_info:1:name",:v => "More")
    get node_path(node)
    assert_response :success
    assert_dom "span.translation_missing", :count => 0
  end
end
