module OhmInspectorHelper
  require "date_range"
  require "uri"

  def ohm_inspector_wikipedia_url(tags)
    if (link = tags["wikipedia"].presence)
      return link if link.match?(/\Ahttps?:\/\//i)

      # Value may carry a language prefix: "pt:Article_Title"
      # Fixes https://github.com/OpenHistoricalMap/issues/issues/859
      if (m = link.match(/\A([a-z]{2,3}):(.+)\z/))
        lang  = m[1]
        title = m[2]
      else
        lang  = "en"
        title = link
      end
      return "https://#{lang}.wikipedia.org/wiki/#{CGI.escape(title)}"
    end

    # Fall back to `wikipedia:xx` keys (e.g. `wikipedia:en`, `wikipedia:pt`)
    tags.each do |key, value|
      if (m = key.match(/\Awikipedia:([a-zA-Z]{2})\z/))
        lang = m[1].downcase
        return "https://#{lang}.wikipedia.org/wiki/#{CGI.escape(value)}"
      end
    end

    nil
  end

  def ohm_inspector_date_range(tags)
    start_date = tags["start_date"].presence
    end_date   = tags["end_date"].presence
    return nil unless start_date || end_date

    DateRange.new(start_date, end_date).to_s.presence
  end
end
