import Toybox.Lang;

// Layout measured from resources/drawables/hermesbg.png at 454x454.
// Ratios are fractions of half the short axis (227 px). Shared analog
// math lives in AnalogGeometry.
module HermesGeometry {

    const CHAPTER_RING = 0.72;
    const INNER_DISC = 0.72;
    const NUMERAL_RING = 0.84;

    // Seconds subdial on the 6 o'clock axis, on the inner disc.
    const SUBDIAL_CENTER_Y = 0.260;
    const SUBDIAL_RADIUS = 0.229;

    const MAIN_ARBOR = 0.024;
    const SUB_ARBOR = 0.012;

    const HOUR_HAND_LEN = 0.42;
    const MINUTE_HAND_LEN = 0.64;
    const SECOND_HAND_LEN = 0.185;
    const HAND_TAIL = 0.055;
    const HOUR_HAND_WIDTH = 0.016;
    const MINUTE_HAND_WIDTH = 0.011;
    const SECOND_HAND_WIDTH = 0.006;
}
