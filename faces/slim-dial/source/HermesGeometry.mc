import Toybox.Lang;

// Layout measured from resources/drawables/hermesbg.png at 454x454.
// Ratios are fractions of half the short axis (227 px). Shared analog
// math lives in AnalogGeometry.
module HermesGeometry {

    const CHAPTER_RING = 0.72;
    const INNER_DISC = 0.72;
    const NUMERAL_RING = 0.85;

    // Seconds subdial measured from hermesbg.png (arbor ~286, rim ~r=33).
    const SUBDIAL_CENTER_Y = 0.260;
    const SUBDIAL_RADIUS = 0.145;

    const MAIN_ARBOR = 0.026;
    const MAIN_ARBOR_PIP = 0.011;
    const MAIN_ARBOR_PIN = 0.005;
    const SUB_ARBOR = 0.010;
    const SUB_ARBOR_PIN = 0.004;

    const HOUR_HAND_LEN = 0.46;
    const MINUTE_HAND_LEN = 0.62;
    const SECOND_HAND_LEN = 0.118;
    const HAND_TAIL = 0.072;
    const SECOND_TAIL = 0.042;
    const HOUR_HAND_WIDTH = 0.030;
    const MINUTE_HAND_WIDTH = 0.018;
    const SECOND_HAND_WIDTH = 0.007;
    const SECOND_COUNTERWEIGHT = 0.011;
}
