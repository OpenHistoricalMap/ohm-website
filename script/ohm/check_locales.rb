#!/usr/bin/env ruby
# frozen_string_literal: true

# Keeps config/locales/overrides/en.yml honest against upstream's en.yml.
#
# Rails loads overrides/en.yml after upstream's en.yml, so our text wins wherever
# we define a key. That file is the only place we restate upstream strings, so it
# is also where stale text piles up: upstream renames a key, drops a model or
# rewrites a sentence, and our copy stays behind saying nothing to nobody.
#
# Four checks, three of them fatal:
#
#   1. upstream says OpenStreetMap, the site shows it, and we have no override.
#      Someone reads OpenStreetMap on an OHM page.                      (fails)
#
#   2. an override drops or renames a %{} variable that upstream uses.
#      Rails raises I18n::MissingInterpolationArgument and the page dies. (fails)
#
#   3. an override repeats the upstream text word for word, so it overrides
#      nothing and is one more string to keep in sync.                   (fails)
#
#   4. upstream has no such key and nothing in the code renders it, so it is
#      probably left over from a page or model that went away.         (reports)
#
# Check 4 only reports, because some keys are built at runtime, as in
# t("...border_types.#{value}"), and no scan can prove those are dead. Treat its
# list as candidates to read, not as a verdict.
#
# Scope: English only. The other 109 override files come from Translatewiki, and
# OHM forked many views under new key names, so keys nothing renders are left
# alone rather than guessed at.

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
  # help.html.erb lists its cards from %w[wiki github forum discord slack
  # mailing_list], so these upstream sections never reach a page. The scan reads
  # the cards as t(".#{site}.url") and cannot tell which sections the list holds,
  # so it counts them as rendered and they need an entry here.
  "site.help.community.description",
  "site.help.switch2osm.description",
  "site.help.switch2osm.title",
  "site.help.switch2osm.url"
].freeze

# Scopes the scan cannot follow, so the unused report skips them.
DYNAMIC_SCOPES = [
  "site.about_section.",
  "geocoder.search_osm_nominatim."
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
    # Only the outer double quote closes the string, so #{} may hold quotes.
    body.scan(/\bt[( ]\s*"([^"]*\#\{[^}]*\}[^"]*)"/) do |template,|
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
  # lib looks up keys too, like date_range.rb.
  Dir.glob("#{ROOT}/lib/**/*.rb").each do |file|
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

# Same text as upstream, so the override does nothing.
same_as_upstream = (overrides.keys & upstream.keys).select do |key|
  overrides[key] == upstream[key]
end

if same_as_upstream.any?
  show("#{same_as_upstream.length} override(s) repeat the upstream text word for word",
       same_as_upstream.map { |key| "  #{key}: #{upstream[key].gsub("\n", ' ')}" })
  puts "Delete them from config/locales/overrides/en.yml. Upstream already says this,"
  puts "so the override only adds a string to keep in sync."
  problems = true
end

# Not in upstream and nothing renders it. Reported only: some keys are built at
# runtime and no scan can see them.
unused = overrides.keys.reject { |key| upstream.key?(key) || shown.call(key) }
unused = unused.reject { |key| DYNAMIC_SCOPES.any? { |scope| key.start_with?(scope) } }

if unused.any?
  show("#{unused.length} override(s) may be unused: upstream has no such key and nothing renders it",
       unused.map { |key| "  #{key}" })
  puts "Check each one before deleting. If a key is built at runtime, add its scope"
  puts "to DYNAMIC_SCOPES in this script instead."
end

unless problems
  dead = said_osm.keys.reject { |key| shown.call(key) }
  puts "All upstream keys that mention OpenStreetMap and reach the site are covered."
  puts "#{dead.length} more say it but nothing renders them, so they are left alone."
end
exit(problems ? 1 : 0)
