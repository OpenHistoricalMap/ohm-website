/*
 * OHM Inspector — enriches the feature sidebar with images, date range, and
 * Wikipedia/Wikidata excerpts.  Called from index/element.js after the sidebar
 * content has been loaded.
 */

// eslint-disable-next-line no-unused-vars
function addOpenHistoricalMapInspector(map) {
  initSlideshow();
  initWikipediaExcerpt();
  initDateClickToTimeslider(map);
}

// https://github.com/OpenHistoricalMap/issues/issues/1323
// Click the rendered date range to advance the map timeslider to that date.
// Clicking on the start_date / end_date / range jumps the slider:
//   - clicking the date paragraph as a whole jumps to start_date
//   - clicking parts could be wired up later if dates are split into spans
function initDateClickToTimeslider(map) {
  var datesEl = document.querySelector(".ohm-inspector-dates[data-start-date], .ohm-inspector-dates[data-end-date]");
  if (!datesEl || !map || !map.timeslider) return;

  var startDate = datesEl.dataset.startDate;
  var endDate   = datesEl.dataset.endDate;
  var target    = startDate || endDate;
  if (!target) return;

  // Normalize bare year ("1976") to "1976-01-01"; let full ISO dates pass through.
  if (/^-?\d+$/.test(target)) target = target + "-01-01";

  datesEl.classList.add("ohm-inspector-dates--clickable");
  datesEl.title = OSM.i18n.t("javascripts.ohm_inspector.jump_to_date", { defaultValue: "Jump to this date on the map" });
  datesEl.addEventListener("click", function () {
    map.timeslider.setDate(target);
  });
}

function initSlideshow() {
  var panel = document.querySelector(".ohm-inspector-slideshow");
  if (!panel) return;

  var slides = Array.prototype.slice.call(panel.querySelectorAll(".ohm-inspector-slide"));
  if (!slides.length) return;

  var prevBtn = panel.querySelector(".ohm-inspector-slideshow-prev");
  var nextBtn = panel.querySelector(".ohm-inspector-slideshow-next");
  var current = 0;

  function showSlide(index) {
    slides.forEach(function (slide, i) {
      slide.classList.toggle("ohm-inspector-slide--hidden", i !== index);
    });
    current = index;
    if (prevBtn) prevBtn.classList.toggle("ohm-inspector-slideshow-btn--hidden", index === 0);
    if (nextBtn) nextBtn.classList.toggle("ohm-inspector-slideshow-btn--hidden", index >= slides.length - 1);
  }

  if (prevBtn) prevBtn.addEventListener("click", function () { showSlide(current - 1); });
  if (nextBtn) nextBtn.addEventListener("click", function () { showSlide(current + 1); });

  showSlide(0);

  // Attach SimpleLightbox to all slide image links.
  // Modern SimpleLightbox (npm 2.x) takes the elements/selector as the first
  // positional argument; the old `{ elements: … }` options form throws.
  var imageLinks = panel.querySelectorAll(".ohm-inspector-slide-link");
  if (imageLinks.length) {
    new SimpleLightbox(imageLinks); // eslint-disable-line no-new
  }
}

function fetchWikipediaExcerpt(url, el) {
  // Parse the language and article title out of a full Wikipedia URL,
  // e.g. https://pt.wikipedia.org/wiki/Algoso_Castle
  var match = decodeURIComponent(url).match(/^https?:\/\/([a-z-]+)\.wikipedia\.org\/wiki\/([^#]+)/i);
  if (!match) return;

  var lang  = match[1];
  var title = match[2];

  fetch("https://" + lang + ".wikipedia.org/w/api.php?" + new URLSearchParams({
    action:      "query",
    prop:        "extracts",
    exsentences: 2,
    exlimit:     1,
    format:      "xml",
    explaintext: "true",
    exintro:     "true",
    origin:      "*",
    titles:      title
  }))
    .then(function (r) { return r.text(); })
    .then(function (text) {
      var xmldoc = new DOMParser().parseFromString(text, "text/xml");
      var extractEl = xmldoc.querySelector("extract");
      if (!extractEl) return;
      var excerpt = extractEl.textContent.replace(/\(\s*\(\s*listen\s*\)\s*\)/, "").trim();
      if (excerpt) el.textContent = excerpt;
    })
    .catch(function () {
      el.textContent = OSM.i18n.t("javascripts.ohm_inspector.network_error");
    });
}

function fetchWikipediaViaWikidata(wikidataId, excerptEl) {
  // Resolve the Wikidata QID to the user's preferred-language Wikipedia
  // sitelink, then fill the excerpt placeholder and reveal the Wikipedia
  // link in the bottom-links row.
  if (!OSM.WIKIDATA_API_URL) return;

  var preferredLangs = (OSM.preferred_languages && OSM.preferred_languages.length
    ? OSM.preferred_languages
    : ["en"]
  ).map(function (l) { return l.split("-")[0] + "wiki"; });
  var wikis = preferredLangs
    .concat(["enwiki"])
    .filter(function (v, i, a) { return a.indexOf(v) === i; }); // dedupe

  fetch(OSM.WIKIDATA_API_URL + "?" + new URLSearchParams({
    action:     "wbgetentities",
    ids:        wikidataId,
    props:      "sitelinks/urls",
    format:     "json",
    origin:     "*",
    sitefilter: wikis.join("|")
  }))
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var entity = data.entities && data.entities[wikidataId];
      if (!entity || !entity.sitelinks) return;

      var sitelink = wikis.reduce(function (found, wiki) {
        return found || entity.sitelinks[wiki] || null;
      }, null);
      if (!sitelink) return;

      // Reveal the Wikipedia badge alongside the excerpt
      var wikipediaLink = document.querySelector(".ohm-inspector-wikipedia-link");
      if (wikipediaLink) {
        wikipediaLink.href = sitelink.url;
        wikipediaLink.removeAttribute("hidden");
      }

      fetchWikipediaExcerpt(sitelink.url, excerptEl);
    });
}

function initWikipediaExcerpt() {
  var el = document.querySelector(".ohm-inspector-wikipedia-excerpt[data-wikidata-id]");
  if (!el) return;

  fetchWikipediaViaWikidata(el.dataset.wikidataId, el);
}
