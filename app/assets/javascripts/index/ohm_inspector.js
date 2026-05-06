/*
 * OHM Inspector — enriches the feature sidebar with images, date range, and
 * Wikipedia/Wikidata excerpts.  Called from index/element.js after the sidebar
 * content has been loaded.
 */

// eslint-disable-next-line no-unused-vars
function addOpenHistoricalMapInspector(map) {
  // `map` is accepted for future use by date-click → timeslider (#1323)

  initSlideshow();
  initWikipediaExcerpt();
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

  // Attach SimpleLightbox to all slide image links
  var imageLinks = panel.querySelectorAll(".ohm-inspector-slide-link");
  if (imageLinks.length) {
    new SimpleLightbox({ elements: imageLinks }); // eslint-disable-line no-new
  }
}

function fetchWikipediaExcerpt(url, el) {
  // Parse the language and article title out of a full Wikipedia URL,
  // e.g. https://pt.wikipedia.org/wiki/Algoso_Castle
  var match = decodeURIComponent(url).match(/^https?:\/\/([a-z-]+)\.wikipedia\.org\/wiki\/([^#]+)/i);
  if (!match) return;

  var lang  = match[1];
  var title = match[2];

  var params = new URLSearchParams({
    action:      "query",
    prop:        "extracts",
    exsentences: 2,
    exlimit:     1,
    format:      "xml",
    explaintext: "true",
    exintro:     "true",
    origin:      "*",
    titles:      title
  });

  fetch("https://" + lang + ".wikipedia.org/w/api.php?" + params)
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

function fetchWikipediaViaWikidata(wikidataId, el) {
  // Look up the Wikipedia article linked from a Wikidata item (#584)
  if (!OSM.WIKIDATA_API_URL) return;

  var preferredLangs = (OSM.preferred_languages || ["en"])
    .map(function (l) { return l.split("-")[0] + "wiki"; });
  var wikis = preferredLangs
    .concat(["enwiki"])
    .filter(function (v, i, a) { return a.indexOf(v) === i; }); // dedupe

  fetch(OSM.WIKIDATA_API_URL + "?" + new URLSearchParams({
    action:       "wbgetentities",
    ids:          wikidataId,
    props:        "sitelinks/urls",
    format:       "json",
    origin:       "*",
    sitefilter:   wikis.join("|")
  }))
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var entity = data.entities && data.entities[wikidataId];
      if (!entity || !entity.sitelinks) return;

      var sitelink = wikis.reduce(function (found, wiki) {
        return found || entity.sitelinks[wiki] || null;
      }, null);
      if (!sitelink) return;

      fetchWikipediaExcerpt(sitelink.url, el);
    });
}

function initWikipediaExcerpt() {
  var el = document.querySelector(".ohm-inspector-wikipedia-excerpt");
  if (!el) return;

  var wikipediaUrl = el.dataset.wikipediaUrl;
  var wikidataId   = el.dataset.wikidataId;

  if (wikipediaUrl) {
    fetchWikipediaExcerpt(wikipediaUrl, el);
  } else if (wikidataId) {
    fetchWikipediaViaWikidata(wikidataId, el);
  }
}
