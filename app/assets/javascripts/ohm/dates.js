const isBeforeYear1000 = (dateStr) => {
  // Check if date is before 1000 CE (OverpassQL doesn't support these dates)
  console.info(`isBeforeYear1000 dateStr: ${dateStr}`);
  if (!dateStr) return false;
  const match = dateStr.match(/^(-?\d+)/);
  return match ? parseInt(match[1], 10) < 1000 : false;
}

const compareDates = (date1, date2) => {
    // Compare ISO 8601 dates correctly (handles BCE dates where string comparison fails)
    console.info(`compareDates: date1: ${date1} date2: ${date2}`)
    if (!date1 && !date2) return 0;
    if (!date1) return -1;
    if (!date2) return 1;

    const match1 = date1.match(/^(-?\d+)(?:-(\d{1,2}))?(?:-(\d{1,2}))?/);
    const match2 = date2.match(/^(-?\d+)(?:-(\d{1,2}))?(?:-(\d{1,2}))?/);
    console.info(`compareDates: match1: ${match1} match2: ${match2}`)
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
  }

const filterByDate = (elements, currentDate) => {
    console.info(`filterByDate: elements: ${elements} currentDate: ${currentDate}`)
    if (!currentDate) return elements;
    return elements.filter(element => {
      const tags = element.tags || {};
      const startDate = tags.start_date;
      const endDate = tags.end_date;
      console.info(`filterByDate: startDate: ${startDate} endDate: ${endDate}`)
      if (startDate && compareDates(startDate, currentDate) > 0) return false;
      if (endDate && compareDates(endDate, currentDate) <= 0) return false;
      return true;
    });
  }
