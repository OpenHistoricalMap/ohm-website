module OhmInspectorHelper
  require "date_range"
  require "uri"

  # Project-defined allowlist of image hosts the inspector may render inline.
  # See https://github.com/OpenHistoricalMap/issues/issues/585.
  #
  # STUB: this list is intentionally empty pending an OHM-team decision on
  # which third-party hosts are trusted. While it stays empty, the only
  # images the inspector renders are the ones constructed from a tag whose
  # safety the inspector itself controls (e.g. wikimedia_commons=File:…
  # routed through commons.wikimedia.org/wiki/Special:FilePath, which the
  # partial adds to the slideshow without going through this check).
  #
  # Maintainers: add hosts as bare strings, HTTPS-only is enforced separately
  # by ohm_inspector_image_url_safe?. Examples of likely-acceptable hosts:
  #   "upload.wikimedia.org"
  #   "commons.wikimedia.org"
  #   "live.staticflickr.com"
  #   "static.openhistoricalmap.org"
  #   "tile.loc.gov"
  IMAGE_DOMAIN_ALLOWLIST = [].freeze

  # Extensions we'll accept as "almost certainly an image". This is a cheap
  # server-side gate (https://github.com/OpenHistoricalMap/issues/issues/583);
  # a stricter content-type check would require a HEAD request per image.
  IMAGE_EXTENSIONS = %w[jpg jpeg png gif webp svg avif].freeze

  # True when `url` is HTTPS, points to an allowlisted host, and ends in a
  # recognized image extension.
  def ohm_inspector_image_url_safe?(url)
    return false if url.blank?
    uri = URI.parse(url)
    return false unless uri.scheme == "https" && uri.host
    return false unless IMAGE_DOMAIN_ALLOWLIST.include?(uri.host)
    return false unless uri.path.present?

    ext = uri.path.split(".").last.to_s.downcase
    IMAGE_EXTENSIONS.include?(ext)
  rescue URI::InvalidURIError
    false
  end

  # Sidebar title for a feature: just the locale-preferred name, with no
  # "Type:" prefix and no "(id)" suffix. The date range and the local-language
  # `name` tag render below the H2 in elements/show.
  def ohm_inspector_feature_title(feature)
    return tag.bdi(feature.id.to_s) if feature.redacted?

    name = feature_name(feature.tags)
    tag.bdi(name.presence || feature.id.to_s)
  end

  # Raw `name` tag value, displayed bold on a flex row with the date range
  # under the sidebar header.
  def ohm_inspector_local_name(feature)
    return nil if feature.redacted?

    feature.tags["name"].presence
  end

  def ohm_inspector_date_range(tags)
    start_date = tags["start_date"].presence
    end_date   = tags["end_date"].presence
    return nil unless start_date || end_date

    DateRange.new(start_date, end_date).to_s.presence
  end
end
