//= require ohm/dates.js

describe("OHM", function () {
  describe("isBeforeYear1000", function () {
    it("returns false when no date is provided", function () {
      expect(isBeforeYear1000()).to.be.false;
    });
    it("returns true when a date is before 1000", function () {
      expect(isBeforeYear1000('999-12-31')).to.be.true;
    });
    it("returns false when a date is after 1000", function () {
      expect(isBeforeYear1000('1000.01.01')).to.be.false;
    });
  });

  describe("compareDates", function () {
    describe("with missing data", function () {
      it("returns 0 when no dates are provided", function () {
        expect(compareDates()).to.be.eq(0);
      });
      it("returns -1 when date1 is not provided", function () {
        expect(compareDates(null, '2026-01-01')).to.be.eq(-1);
      });
      it("returns 1 when date2 is not provided", function () {
        expect(compareDates('2026-01-01')).to.be.eq(1);
      });
    });

    describe("with contemporary dates", function () {
      it("returns -5 when YYYY dates are 5 years apart", function () {
        expect(compareDates('2020', '2025')).to.be.eq(-5);
      });
      it("returns -4 when YYYY-MM dates are 4 months apart", function () {
        expect(compareDates('2025-02', '2025-06')).to.be.eq(-4);
      });
      it("returns -3 when YYYY-MM-DD dates are 3 days apart", function () {
        expect(compareDates('2025-02-02', '2025-02-05')).to.be.eq(-3);
      });
    });

  });

  // describe("filterByDate", function () {
  //   describe("with pre-1000 dates", function () {
  //     it("returns 0 when no dates are provided", function () {
  //       expect(filterByDate('2025, 2026')).to.be.eq(0);
  //     });
  //     it("returns 0 when no dates are provided", function () {
  //       expect(filterByDate('2025-02, 2026-11')).to.be.eq(0);
  //     });
  //     it("returns 0 when no dates are provided", function () {
  //       expect(filterByDate('2025-02-02, 2026-11-11')).to.be.eq(0);
  //     });
  //   });
  // });

});
