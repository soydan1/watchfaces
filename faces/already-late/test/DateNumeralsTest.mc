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
    function testStepThousandsEncoding(logger as Test.Logger) as Boolean {
        if (LateGeometry.stepThousandsNumerals(0).size() != 0) {
            logger.error("under 1000 steps should mark nothing");
            return false;
        }
        if (!same(LateGeometry.stepThousandsNumerals(5), [5] as Array<Number>)) {
            logger.error("5000 steps should mark 5");
            return false;
        }
        if (!same(LateGeometry.stepThousandsNumerals(15), [12, 3] as Array<Number>)) {
            logger.error("15000 steps should mark 12+3");
            return false;
        }
        if (!same(LateGeometry.stepThousandsNumerals(30), [11, 10, 9] as Array<Number>)) {
            logger.error("30000 steps should mark 11+10+9");
            return false;
        }
        if (sumOf(LateGeometry.stepThousandsNumerals(32)) != 32) {
            logger.error("32000 steps must still sum to 32");
            return false;
        }
        if (sumOf(LateGeometry.stepThousandsNumerals(78)) != 78) {
            logger.error("78000 cap should use all hour-marks");
            return false;
        }
        if (sumOf(LateGeometry.stepThousandsNumerals(100)) != 78) {
            logger.error("over 78000 should cap at 78");
            return false;
        }
        return true;
    }

    (:test)
    function testOverlapIsYellow(logger as Test.Logger) as Boolean {
        var date5 = LateGeometry.dateNumerals(5);
        var step5 = LateGeometry.stepThousandsNumerals(5);
        if (LateGeometry.numeralRole(5, date5, step5) != LateGeometry.MARK_BOTH) {
            logger.error("same numeral for date and steps should be yellow");
            return false;
        }
        var date17 = LateGeometry.dateNumerals(17);
        var step5k = LateGeometry.stepThousandsNumerals(5);
        if (LateGeometry.numeralRole(12, date17, step5k) != LateGeometry.MARK_DATE) {
            logger.error("12 on the 17th should stay red");
            return false;
        }
        if (LateGeometry.numeralRole(5, date17, step5k) != LateGeometry.MARK_BOTH) {
            logger.error("5 on the 17th with 5k steps should be yellow");
            return false;
        }
        if (LateGeometry.numeralRole(3, date17, step5k) != LateGeometry.MARK_NONE) {
            logger.error("unused 3 should stay unmarked");
            return false;
        }
        var date4 = LateGeometry.dateNumerals(4);
        var step15 = LateGeometry.stepThousandsNumerals(15);
        if (LateGeometry.numeralRole(4, date4, step15) != LateGeometry.MARK_DATE) {
            logger.error("4th with 15k should keep 4 red");
            return false;
        }
        if (LateGeometry.numeralRole(12, date4, step15) != LateGeometry.MARK_STEPS) {
            logger.error("15k should mark 12 blue");
            return false;
        }
        if (LateGeometry.numeralRole(3, date4, step15) != LateGeometry.MARK_STEPS) {
            logger.error("15k should mark 3 blue");
            return false;
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
