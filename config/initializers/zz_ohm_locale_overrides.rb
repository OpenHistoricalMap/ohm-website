# frozen_string_literal: true

# Rails reads locale files in alphabetical order. The last file it reads wins.
#
# This puts the OHM locale files at the end of that list, so they win in every
# locale. Rails also picks them up earlier on its own; reading them twice does no
# harm.
#
# The zz_ prefix makes this file run last, after anything else that touches i18n.
Rails.application.config.i18n.load_path += Rails.root.glob("config/locales/overrides/*.yml")

# Upstream translates almost every key, so a locale with no OHM override shows
# the OpenStreetMap wording instead of falling back to our English. After all
# locale files load, this copies the OHM English text into each locale for the
# keys we override in en.yml but not in that locale. Only keys upstream also has
# are copied; for the rest Rails already falls back to en.
module OhmLocaleFallback
  PLURAL_KEYS = %w[zero one two few many other].freeze

  def init_translations
    super

    ohm_en = flatten_keys(read_override("en"))
    upstream_en = flatten_keys(YAML.load_file(Rails.root.join("config/locales/en.yml"))["en"])
    shared = ohm_en.select { |key, _| upstream_en.key?(key) }

    available_locales.each do |locale|
      next if locale == :en

      translated = flatten_keys(read_override(locale))
      fill = shared.reject { |key, _| translated.key?(key) }
      store_translations(locale, unflatten_keys(fill)) if fill.any?
    end
  end

  private

  def read_override(locale)
    file = Rails.root.join("config/locales/overrides/#{locale}.yml")
    return {} unless file.exist?

    YAML.load_file(file).values.first || {}
  end

  # {"site" => {"index" => {"copyright" => "text"}}} -> {"site.index.copyright" => "text"}
  # A plural hash (one/other/...) stays whole so plural rules keep working.
  def flatten_keys(node, prefix = nil, out = {})
    if node.is_a?(Hash) && (node.keys.map(&:to_s) - PLURAL_KEYS).any?
      node.each { |key, value| flatten_keys(value, [prefix, key].compact.join("."), out) }
    else
      out[prefix] = node
    end
    out
  end

  def unflatten_keys(flat)
    flat.each_with_object({}) do |(key, value), tree|
      *parents, leaf = key.split(".")
      parents.reduce(tree) { |node, part| node[part] ||= {} }[leaf] = value
    end
  end
end

I18n::Backend::Simple.prepend(OhmLocaleFallback)
