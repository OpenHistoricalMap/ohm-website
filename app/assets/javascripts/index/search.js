OSM.initializations.push(function (map) {
  $(".search_form a.btn.switch_link").on("click", function (e) {
    e.preventDefault();
    const query = $(this).closest("form").find("input[name=query]").val();
    let search = "";
    if (query) search = "?" + new URLSearchParams({ to: query });
    OSM.router.route("/directions" + search + OSM.formatHash(map));
  });

  $(".search_form").on("submit", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    const params = new URLSearchParams({
      query: this.elements.query.value,
      zoom: map.getZoom(),
      minlon: map.getBounds().getWest(),
      minlat: map.getBounds().getSouth(),
      maxlon: map.getBounds().getEast(),
      maxlat: map.getBounds().getNorth()
    });
    const search = params.get("query") ? `/search?${params}` : "/";
    OSM.router.route(search + OSM.formatHash(map));
  });

  $(".describe_location").on("click", function (e) {
    e.preventDefault();
    $("header").addClass("closed");
    const zoom = map.getZoom();
    const { lat, lng } = OSM.cropLocation(map.getCenter(), zoom);

    OSM.router.route("/search?" + new URLSearchParams({ lat, lon: lng, zoom }));
  });
});

OSM.Search = function (map) {
  $("#sidebar_content")
    .on("click", ".search_more a", clickSearchMore)
    .on("click", ".search_results_entry a.set_position", clickSearchResult);

  const markers = L.layerGroup().addTo(map);
  let processedResults = 0;

  function clickSearchMore(e) {
    e.preventDefault();
    e.stopPropagation();

    const div = $(this).parents(".search_more");

    $(this).hide();
    div.find(".loader").prop("hidden", false);

    fetchReplace(this, div);
  }

  function fetchReplace({ href }, $target) {
    return fetch(href, {
      method: "POST",
      body: new URLSearchParams(OSM.csrf)
    })
      .then(response => response.text())
      .then(html => {
        const result = $(html);
        $target.replaceWith(result);
        result.filter("ul").children().each(showSearchResult);
      });
  }

  function showSearchResult() {
    const index = processedResults++;
    const listItem = $(this);
    const inverseGoldenAngle = (Math.sqrt(5) - 1) * 180;
    const color = `hwb(${(index * inverseGoldenAngle) % 360}deg 5% 5%)`;
    listItem.css("--marker-color", color);
    const data = listItem.find("a.set_position").data();
    const marker = L.marker([data.lat, data.lon], { icon: OSM.getMarker({ color, className: "activatable" }) });
    marker.on("mouseover", () => listItem.addClass("bg-body-secondary"));
    marker.on("mouseout", () => listItem.removeClass("bg-body-secondary"));
    marker.on("click", function (e) {
      OSM.router.click(e.originalEvent, listItem.find("a.set_position").attr("href"));
    });
    markers.addLayer(marker);
    listItem.on("mouseover", () => $(marker.getElement()).addClass("active"));
    listItem.on("mouseout", () => $(marker.getElement()).removeClass("active"));
  }

  function panToSearchResult(data) {
    if (data.minLon && data.minLat && data.maxLon && data.maxLat) {
      map.fitBounds([[data.minLat, data.minLon], [data.maxLat, data.maxLon]]);
    } else {
      map.setView([data.lat, data.lon], data.zoom);
    }
  }

  // Compare two ISO 8601 dates, tolerating partial (year, year-month) and BCE values.
  // Same logic as compareDates() in query.js; kept local until we share a date util.
  function compareDates(date1, date2) {
    const match1 = date1.match(/^(-?\d+)(?:-(\d{1,2}))?(?:-(\d{1,2}))?/);
    const match2 = date2.match(/^(-?\d+)(?:-(\d{1,2}))?(?:-(\d{1,2}))?/);
    if (!match1 || !match2) return date1.localeCompare(date2);

    const [, year1, month1, day1] = match1;
    const [, year2, month2, day2] = match2;
    if (parseInt(year1, 10) !== parseInt(year2, 10)) return parseInt(year1, 10) - parseInt(year2, 10);

    const m1 = month1 ? parseInt(month1, 10) : 1;
    const m2 = month2 ? parseInt(month2, 10) : 1;
    if (m1 !== m2) return m1 - m2;

    return (day1 ? parseInt(day1, 10) : 1) - (day2 ? parseInt(day2, 10) : 1);
  }

  // The slider only accepts full YYYY-MM-DD, so pad a year or year-month before setDate().
  function padDate(value) {
    if (value === null || value === undefined || value === "") return null;
    const parts = String(value).trim().match(/^(-?\d{1,4})(?:-(\d{2}))?(?:-(\d{2}))?/);
    if (!parts) return null;
    return `${parts[1]}-${parts[2] || "01"}-${parts[3] || "01"}`;
  }

  // Move the slider so the picked feature is visible. If it already exists at the
  // current time we leave the slider alone.
  function adjustTimeSliderToResult(data) {
    if (!map.timeslider) return;

    const startDate = data.startDate != null && data.startDate !== "" ? String(data.startDate) : null;
    const endDate = data.endDate != null && data.endDate !== "" ? String(data.endDate) : null;
    if (!startDate && !endDate) return;

    const current = map.timeslider.getDate();
    const afterStart = !startDate || compareDates(startDate, current) <= 0;
    const beforeEnd = !endDate || compareDates(endDate, current) > 0;
    if (afterStart && beforeEnd) return; // already visible now

    // out of view: jump to start_date, or to end_date when there is no start
    const target = padDate(startDate || endDate);
    if (target) map.timeslider.setDate(target);
  }

  function clickSearchResult(e) {
    const data = $(this).data();

    panToSearchResult(data);
    adjustTimeSliderToResult(data);

    // Let clicks to object browser links propagate.
    if (data.type && data.id) return;

    e.preventDefault();
    e.stopPropagation();
  }

  const page = {};

  page.pushstate = page.popstate = function (path) {
    const params = new URLSearchParams(path.substring(path.indexOf("?")));
    if (params.has("query")) {
      $(".search_form input[name=query]").val(params.get("query"));
    } else if (params.has("lat") && params.has("lon")) {
      $(".search_form input[name=query]").val(params.get("lat") + ", " + params.get("lon"));
    }
    OSM.loadSidebarContent(path, page.load);
  };

  page.load = function () {
    // the original page.load content is the function below, and is used when one visits this page, be it first load OR later routing change
    // below, we wrap "if map.timeslider" so we only try to add the timeslider if we don't already have it
    function originalLoadFunction () {
      $(".search_results_entry[data-href]").each(function (index) {
        const entry = $(this);
        fetchReplace(this.dataset, entry.children().first())
          .then(() => {
            // go to first result of first geocoder
            if (index === 0) {
              const firstResult = entry.find("*[data-lat][data-lon]:first").first();
              if (firstResult.length) {
                panToSearchResult(firstResult.data());
              }
            }
          });
      });

      return map.getState();
    }  // end originalLoadFunction

    // "if map.timeslider" only try to add the timeslider if we don't already have it
    if (map.timeslider) {
      originalLoadFunction();
    }
    else {
      var params = querystring.parse(location.hash.substring(1));
      addOpenHistoricalMapTimeSlider(map, params, originalLoadFunction);
    }
  };

  page.unload = function () {
    markers.clearLayers();
    processedResults = 0;
  };

  return page;
};
