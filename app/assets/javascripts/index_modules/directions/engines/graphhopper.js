//= require polyline_decoder

(function () {
  function GraphHopperEngine(modeId, vehicleType, profile) {
    const GH_INSTR_MAP = {
      "-3": "sharp-left",
      "-2": "left",
      "-1": "slight-left",
      "0": "straight",
      "1": "slight-right",
      "2": "right",
      "3": "sharp-right",
      "4": "destination", // finish reached
      "5": "destination", // via reached
      "6": "roundabout",
      "-7": "fork-left",
      "7": "fork-right",
      "-98": "u-turn-left", // unknown direction u-turn
      "-8": "u-turn-left", // left u-turn
      "8": "u-turn-right" // right u-turn
    };

    function _processDirections(path) {
      const line = OSM.decodePolyline(path.points, { precision: 5 });

      const steps = path.instructions.map(instr => [
        GH_INSTR_MAP[instr.sign],
        instr.text,
        instr.distance,
        line.slice(instr.interval[0], instr.interval[1] + 1)
      ]);

      steps.at(-1)[0] = "destination";

      return {
        line,
        steps,
        distance: path.distance,
        time: path.time / 1000,
        ascend: path.ascend,
        descend: path.descend
      };
    }

    return {
      mode: modeId,
      provider: "graphhopper",
      draggable: false,

      getRoute: function (points, signal, year, date) {
        // GraphHopper Directions API documentation https://docs.graphhopper.com
        const query = {
          profile: vehicleType,
          locale: OSM.i18n.locale,
          elevation: false,
          instructions: true,
          points: points.map(({ lat, lng }) => [lng, lat])
        };
        const demoQuery = new URLSearchParams({ profile });

        for (const { lat, lng } of points) {
          demoQuery.append("point", [lat, lng]);
        }

        if (date) demoQuery.set("date", date);

        // Skip ways that did not exist on the timeslider date
        if (typeof year === "number") {
          query.custom_model = { priority: [{ "if": `ohm_start > ${year} || ohm_end < ${year}`, "multiply_by": "0" }] };
        }

        const meta = {
          credit: "GraphHopper",
          creditlink: "https://www.graphhopper.com/",
          // OHM routing test page, on the same host as the routing endpoint
          demolink: new URL("/?" + demoQuery, OSM.GRAPHHOPPER_URL).href
        };

        return fetch(OSM.GRAPHHOPPER_URL, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(query), signal })
          .then(response => response.json())
          .then(({ paths }) => {
            if (!paths || paths.length === 0) throw new Error();

            return { ..._processDirections(paths[0]), ...meta };
          });
      }
    };
  }

  OSM.directionsEngines.add(new GraphHopperEngine("car", "car", "car"), true);
  OSM.directionsEngines.add(new GraphHopperEngine("foot", "foot", "foot"), true);
  OSM.directionsEngines.add(new GraphHopperEngine("horse", "horse", "horse"), true);
  OSM.directionsEngines.add(new GraphHopperEngine("carriage", "carriage", "carriage"), true);
}());
