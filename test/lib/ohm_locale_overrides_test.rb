# frozen_string_literal: true

require "test_helper"

class OhmLocaleOverridesTest < ActiveSupport::TestCase
  def setup
    @ohm_en = flatten(YAML.load_file(Rails.root.join("config/locales/overrides/en.yml"))["en"])
    @ohm_de = flatten(YAML.load_file(Rails.root.join("config/locales/overrides/de.yml"))["de"])
    @upstream_de = flatten(YAML.load_file(Rails.root.join("config/locales/de.yml"))["de"])
  end

  test "a key overridden in en but not in the locale shows the OHM English text" do
    key = ((@ohm_en.keys & @upstream_de.keys) - @ohm_de.keys).first
    assert_not_nil key, "no key to test with: every OHM key has a German override"

    assert_equal @ohm_en[key], I18n.t(key, :locale => :de)
  end

  test "a key overridden in the locale keeps its translation" do
    key = (@ohm_en.keys & @ohm_de.keys).find { |k| @ohm_de[k].is_a?(String) }

    assert_equal @ohm_de[key], I18n.t(key, :locale => :de)
  end

  test "a key with no OHM override keeps the upstream translation" do
    key = (@upstream_de.keys - @ohm_en.keys).find { |k| @upstream_de[k].is_a?(String) }

    assert_equal @upstream_de[key], I18n.t(key, :locale => :de)
  end

  private

  def flatten(node, prefix = nil, out = {})
    if node.is_a?(Hash) && (node.keys.map(&:to_s) - %w[zero one two few many other]).any?
      node.each { |key, value| flatten(value, [prefix, key].compact.join("."), out) }
    else
      out[prefix] = node
    end
    out
  end
end
