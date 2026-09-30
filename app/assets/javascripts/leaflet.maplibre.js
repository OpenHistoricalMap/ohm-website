//= require @maplibre/maplibre-gl-leaflet

maplibregl.setRTLTextPlugin(OSM.MODULE_PATHS.mapbox_rtl_text, true);

L.OSM.MaplibreGL = L.MaplibreGL.extend({
  getAttribution: function () {
    return this.options.attribution;
  }
});

// OHM map styles, packaged as the npm module @openhistoricalmap/map-styles.
// app/assets/javascripts/index.js requires @openhistoricalmap/map-styles/dist/ohm.styles,
// which fills this object; config/layers.yml defines the matching L.MaplibreGL layers.
// See timeslider.js which adds the TimeSlider to the map, keying it for those layers.
window.ohmVectorStyles = {};
