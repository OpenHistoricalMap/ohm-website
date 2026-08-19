#!/usr/bin/env ruby
# frozen_string_literal: true

# Finds upstream texts that say OpenStreetMap, reach the OHM site, and have no
# OHM version yet.
#
# Rails loads overrides/en.yml after upstream's en.yml, so the override wins.
# OHM also forked many views under new key names, so keys nothing renders are
# left alone.

require "set"
require "yaml"

ROOT = File.expand_path("../..", __dir__)
UPSTREAM = File.join(ROOT, "config", "locales", "en.yml")
OVERRIDES = File.join(ROOT, "config", "locales", "overrides", "en.yml")

# \bOSM\b is upper case and word bounded, so it skips OSMF, osm_id and .osm.
# The URL pattern wants "//", so it skips the wiki and community subdomains.
TERMS = [
  /OpenStreetMap/,
  /\bOSM\b/,
  %r{//(www\.)?openstreetmap\.org},
  /\bosm\.org\b/,
  /State of the Map/,
  /switch2osm/
].freeze

# Rendered keys where the OpenStreetMap mention is correct. Add one only when the
# mention really belongs, not to turn the build green. Unrendered keys are
# already skipped.
KEEP_UPSTREAM_WORDING = [
  "javascripts.map.openstreetmap_contributors", # OSM base layer attribution
  "layouts.welcome_tou_notice_html", # OSMF terms of use, stays as it is
  "site.export.too_large.other.description", # OSM links OHM points people to
  "site.help.community.description",
  "site.help.switch2osm.description",
  "site.help.switch2osm.title",
  "site.help.switch2osm.url"
].freeze

# Flat "site.about.title" => "text" hash.
def read(path)
  flatten(YAML.load_file(path).values.first)
end

def flatten(node, prefix = [], out = {})
  if node.is_a?(Hash)
    node.each { |key, value| flatten(value, prefix + [key.to_s], out) }
  else
    out[prefix.join(".")] = Array(node).join(" ")
  end
  out
end

# Keys the OHM code renders. A runtime name, t(".#{title}_title"), becomes a
# pattern. When we cannot read the shape we keep the whole scope, so a real key
# is never skipped by guessing.
def rendered
  exact = Set.new
  patterns = []

  scan = lambda do |body, here|
    body.scan(/\bt[( ]\s*["'](\.?[a-z][\w.]*)["']/) do |key,|
      exact << (key.start_with?(".") ? "#{here}#{key}" : key) if here || !key.start_with?(".")
    end
    body.scan(/\bt[( ]\s*["']((?:[^"'\\]|\\.)*?#\{.*?)["']/) do |template,|
      next if template.start_with?(".") && here.nil?

      full = template.start_with?(".") ? "#{here}#{template}" : template
      parts = full.split(/#\{[^}]*\}/, -1).map { |part| Regexp.escape(part) }
      patterns << Regexp.new("\\A#{parts.join('[\\w.]+')}\\z")
    end
  end

  Dir.glob("#{ROOT}/app/views/**/*.erb").each do |file|
    here = file.sub("#{ROOT}/app/views/", "").sub(/\.\w+\.erb\z/, "").split("/")
    here[-1] = here[-1].delete_prefix("_")
    scan.call(File.read(file), here.join("."))
  end
  Dir.glob("#{ROOT}/app/{controllers,helpers,models,mailers,jobs}/**/*.rb").each do |file|
    scan.call(File.read(file), nil)
  end
  Dir.glob("#{ROOT}/app/assets/javascripts/**/*.js").reject { |file| file.include?("/i18n/") }.each do |file|
    File.read(file).scan(/i18n\.t\(\s*["']([\w.]+)["']/i) { |key,| exact << key }
  end

  [exact, patterns]
end

def variables(text)
  text.scan(/%\{(\w+)\}/).flatten.uniq.sort
end

def show(title, lines)
  puts "\n#{title}\n#{'-' * title.length}"
  lines.each { |line| puts line }
  puts
end

upstream = read(UPSTREAM)
overrides = read(OVERRIDES)
exact, patterns = rendered
problems = false

shown = lambda do |key|
  exact.include?(key) || patterns.any? { |pattern| key.match?(pattern) }
end

# Says OSM, the site shows it, no override yet.
said_osm = upstream.select { |_key, text| TERMS.any? { |term| text.match?(term) } }
missing = said_osm.select do |key, _text|
  shown.call(key) && !overrides.key?(key) && !KEEP_UPSTREAM_WORDING.include?(key)
end

if missing.any?
  show("#{missing.length} key(s) need OHM wording in config/locales/overrides/en.yml",
       missing.map { |key, text| "  #{key}\n      #{text.gsub("\n", ' ')}" })
  puts "Add them there, or add the key to KEEP_UPSTREAM_WORDING in this script if the"
  puts "OpenStreetMap mention is correct as it is."
  problems = true
end

# Override lost a %{placeholder}; the page crashes when it renders.
broken = (overrides.keys & upstream.keys).select do |key|
  variables(upstream[key]) != variables(overrides[key])
end

if broken.any?
  show("#{broken.length} override(s) do not use the same %{} variables as upstream",
       broken.map { |key| "  #{key}: upstream #{variables(upstream[key])}, override #{variables(overrides[key])}" })
  puts "These raise I18n::MissingInterpolationArgument. Fix the override."
  problems = true
end

unless problems
  dead = said_osm.keys.reject { |key| shown.call(key) }
  puts "All upstream keys that mention OpenStreetMap and reach the site are covered."
  puts "#{dead.length} more say it but nothing renders them, so they are left alone."
end
exit(problems ? 1 : 0)
