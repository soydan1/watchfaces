import Toybox.Lang;

// Layout measured from resources/drawables/hermesbg.png at 454x454.
// Ratios are fractions of half the short axis (227 px). Shared analog
// math lives in AnalogGeometry.
module HermesGeometry {

    const CHAPTER_RING = 0.72;
    const INNER_DISC = 0.72;
    const NUMERAL_RING = 0.85;

    // Seconds subdial arbor on hermesbg.png, y = 227 + 0.260*227.
    const SUBDIAL_CENTER_Y = 0.260;
}
