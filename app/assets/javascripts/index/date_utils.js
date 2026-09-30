// Shared date helpers for the map UI, kept in one place so query.js and
// search.js do not each carry their own copy.
OSM.Date = {
  // Compare ISO 8601 dates correctly (handles BCE dates where string comparison fails)
  compareDates: function (date1, date2) {
    if (!date1 && !date2) return 0;
    if (!date1) return -1;
    if (!date2) return 1;

    const match1 = date1.match(/^(-?\d+)(?:-(\d{1,2}))?(?:-(\d{1,2}))?/);
    const match2 = date2.match(/^(-?\d+)(?:-(\d{1,2}))?(?:-(\d{1,2}))?/);
    if (!match1 || !match2) return date1.localeCompare(date2);

    const [, year1Str, month1Str, day1Str] = match1;
    const [, year2Str, month2Str, day2Str] = match2;
    const year1Int = parseInt(year1Str, 10);
    const year2Int = parseInt(year2Str, 10);

    if (year1Int !== year2Int) return year1Int - year2Int;

    const month1 = month1Str ? parseInt(month1Str, 10) : 1;
    const month2 = month2Str ? parseInt(month2Str, 10) : 1;
    if (month1 !== month2) return month1 - month2;

    const day1 = day1Str ? parseInt(day1Str, 10) : 1;
    const day2 = day2Str ? parseInt(day2Str, 10) : 1;
    return day1 - day2;
  },

  // Days in a month, accounting for leap years (BCE has no year 0).
  daysInMonth: function (year, month) {
    if (month !== 2) return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
    const y = year > 0 ? year : year + 1;
    const leap = y % 4 === 0 && (y % 100 !== 0 || y % 400 === 0);
    return leap ? 29 : 28;
  },

  // Fill a partial date to a full YYYY-MM-DD, at the start or end of its period.
  padDate: function (value, startend) {
    if (typeof value === "undefined" || value === null || value === "") return null;
    const date = String(value).trim().replace(/^\+/, "");
    if ((/^-?\d+-\d\d-\d\d$/).test(date)) return date;
    const yearMonth = date.match(/^(-?\d+)-(\d\d)$/);
    if (yearMonth) {
      if (startend === "start") return `${date}-01`;
      const lastDay = OSM.Date.daysInMonth(parseInt(yearMonth[1], 10), parseInt(yearMonth[2], 10));
      return `${date}-${String(lastDay).padStart(2, "0")}`;
    }
    if ((/^-?\d+$/).test(date)) return startend === "start" ? `${date}-01-01` : `${date}-12-31`;
    return null;
  },

  // True when a feature with these dates exists at the given time. The end date
  // pads to the last day of its period, so a feature ending in 1700 lasts all year.
  existsAt: function (startDate, endDate, atDate) {
    const afterStart = !startDate || OSM.Date.compareDates(OSM.Date.padDate(startDate, "start"), atDate) <= 0;
    const beforeEnd = !endDate || OSM.Date.compareDates(OSM.Date.padDate(endDate, "end"), atDate) > 0;
    return afterStart && beforeEnd;
  }
};
