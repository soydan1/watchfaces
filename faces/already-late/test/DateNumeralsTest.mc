import Toybox.Lang;
import Toybox.Test;

module DateNumeralsTest {

    function same(got as Array<Number>, want as Array<Number>) as Boolean {
        if (got.size() != want.size()) {
            return false;
        }
        for (var i = 0; i < got.size(); i++) {
            if (got[i] != want[i]) {
                return false;
            }
        }
        return true;
    }

    function sumOf(nums as Array<Number>) as Number {
        var total = 0;
        for (var i = 0; i < nums.size(); i++) {
            total += nums[i];
        }
        return total;
    }

    (:test)
    function testSingletonsAndTeens(logger as Test.Logger) as Boolean {
        if (!same(LateGeometry.dateNumerals(5), [5] as Array<Number>)) {
            logger.error("5th should highlight 5");
            return false;
        }
        if (!same(LateGeometry.dateNumerals(12), [12] as Array<Number>)) {
            logger.error("12th should highlight 12");
            return false;
        }
        if (!same(LateGeometry.dateNumerals(13), [12, 1] as Array<Number>)) {
            logger.error("13th should highlight 12+1");
            return false;
        }
        if (!same(LateGeometry.dateNumerals(17), [12, 5] as Array<Number>)) {
            logger.error("17th should highlight 12+5");
            return false;
        }
        if (!same(LateGeometry.dateNumerals(23), [12, 11] as Array<Number>)) {
            logger.error("23rd should highlight 12+11");
            return false;
        }
        return true;
    }

    (:test)
    function testThirtyIsTenElevenNine(logger as Test.Logger) as Boolean {
        if (!same(LateGeometry.dateNumerals(30), [11, 10, 9] as Array<Number>)) {
            logger.error("30th should highlight 11+10+9");
            return false;
        }
        if (!same(LateGeometry.dateNumerals(24), [12, 11, 1] as Array<Number>)) {
            logger.error("24th should highlight 12+11+1");
            return false;
        }
        if (!same(LateGeometry.dateNumerals(31), [12, 11, 8] as Array<Number>)) {
            logger.error("31st should highlight 12+11+8");
            return false;
        }
        return true;
    }

    (:test)
    function testEveryDaySumsToItself(logger as Test.Logger) as Boolean {
        for (var day = 1; day <= 31; day++) {
            var nums = LateGeometry.dateNumerals(day);
            if (nums.size() < 1) {
                logger.error("day " + day.toString() + " produced no numerals");
                return false;
            }
            if (sumOf(nums) != day) {
                logger.error("day " + day.toString() + " numerals do not sum to the date");
                return false;
            }
            for (var i = 0; i < nums.size(); i++) {
                var n = nums[i];
                if ((n < 1) || (n > 12)) {
                    logger.error("day " + day.toString() + " used numeral outside 1-12");
                    return false;
                }
                for (var j = i + 1; j < nums.size(); j++) {
                    if (nums[j] == n) {
                        logger.error("day " + day.toString() + " repeated a numeral");
                        return false;
                    }
                }
            }
        }
        return true;
    }

    (:test)
    function testGlyphOriginsOnPlate(logger as Test.Logger) as Boolean {
        if ((LateGeometry.dateGlyphX(5) != 256) || (LateGeometry.dateGlyphY(5) != 381)) {
            logger.error("date 5 crop origin drifted");
            return false;
        }
        if ((LateGeometry.dateGlyphX(10) != 123) || (LateGeometry.dateGlyphY(10) != 355)) {
            logger.error("date 10 crop origin drifted");
            return false;
        }
        if ((LateGeometry.dateGlyphX(12) != 305) || (LateGeometry.dateGlyphY(12) != 326)) {
            logger.error("date 12 crop origin drifted");
            return false;
        }
        return true;
    }
}
