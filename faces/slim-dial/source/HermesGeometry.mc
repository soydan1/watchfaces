import Toybox.Lang;

// Slim Dial layout ratios. Values are fractions of half the short screen
// axis so they stay round on 454x454. Shared analog math lives in
// AnalogGeometry (repo shared/source).
module HermesGeometry {

    const CHAPTER_RING = 0.62;
    const INNER_DISC = 0.60;
    const NUMERAL_RING = 0.84;
    // Ticks sit on the inner disc, just inside the chapter ring.
    const MINUTE_TICK_INNER = 0.575;
    const MINUTE_TICK_OUTER = 0.608;
    const HOUR_TICK_INNER = 0.548;
    const HOUR_TICK_OUTER = 0.608;

    // Seconds subdial on the 6 o'clock axis; bottom overlaps the chapter ring.
    const SUBDIAL_CENTER_Y = 0.42;
    const SUBDIAL_RADIUS = 0.23;
    const SUBDIAL_TICK_INNER = 0.185;
    const SUBDIAL_TICK_OUTER = 0.220;
    const SUBDIAL_CARDINAL_INNER = 0.165;

    const MAIN_ARBOR = 0.016;
    const SUB_ARBOR = 0.009;

    const HOUR_HAND_LEN = 0.36;
    const MINUTE_HAND_LEN = 0.56;
    const SECOND_HAND_LEN = 0.19;
    const HAND_TAIL = 0.05;
    const HOUR_HAND_WIDTH = 0.014;
    const MINUTE_HAND_WIDTH = 0.010;
    const SECOND_HAND_WIDTH = 0.006;
}
