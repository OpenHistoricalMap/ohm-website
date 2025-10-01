L.OSM.OHM = L.OSM.MaplibreGL.extend({
  onAdd: function (map) {
    const styleName = (this.options.layerId || this.options.name?.replaceAll(' ', ''))
      .trim()
      .replace(/\w\S*/g, w => w[0].toUpperCase() + w.slice(1).toLowerCase());

    L.OSM.MaplibreGL.prototype.onAdd.call(this, map);
    this.getMaplibreMap().setStyle(ohmVectorStyles[styleName]);
  },
  onRemove: function (map) {
    L.OSM.MaplibreGL.prototype.onRemove.call(this, map);
  }
});

L.OSM.Historical = L.OSM.OHM.extend({});
L.OSM.Railway = L.OSM.OHM.extend({});
L.OSM.Woodblock = L.OSM.OHM.extend({});
L.OSM.JapaneseScroll = L.OSM.OHM.extend({});
