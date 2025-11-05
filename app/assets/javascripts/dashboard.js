$(function () {
  const defaultHomeZoom = 12;
  let map;

  if ($("#map").length) {
    const position = $("html").attr("dir") === "rtl" ? "top-left" : "top-right";

    map = new maplibregl.Map({
      container: "map",
      style: {
        "version": 8,
        "name": "OSM Raster",
        "sources": {
          "osm": {
            "type": "raster",
            "tiles": [
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            ],
            "tileSize": 256,
            "maxzoom": 19,
            "attribution": "© OpenStreetMap contributors"
          }
        },
        "layers": [
          {
            "id": "osm",
            "type": "raster",
            "source": "osm",
          }
        ],
        "projection": { "type": "globe" },
      },
      attributionControl: false,
      center: OSM.home ? [OSM.home.lon, OSM.home.lat] : [0, 0],
      zoom: OSM.home ? defaultHomeZoom : 0
    });

    map.addControl(new maplibregl.NavigationControl(), position);

    $("[data-user]").each(function () {
      const userData = $(this).data("user");
      if (userData && userData.lon && userData.lat) {
        const popup = new maplibregl.Popup()
          .setHTML(userData.description);

        new maplibregl.Marker({ color: userData.color })
          .setLngLat([userData.lon, userData.lat])
          .setPopup(popup)
          .addTo(map);
      }
    });
  }
});
