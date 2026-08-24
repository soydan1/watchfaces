import Toybox.Lang;

// Layout measured from resources/drawables/hermesbg.png at 454x454.
// Ratios are fractions of half the short axis (227 px). Shared analog
// math lives in AnalogGeometry.
module HermesGeometry {

    const CHAPTER_RING = 0.72;
    const INNER_DISC = 0.72;
    const NUMERAL_RING = 0.85;

    // Seconds hub on the 454x454 plate. Origin is the frame top-left.
    // Bottom of second.png sits at this point (Figma: 225, 338).
    const SECOND_PIVOT_X = 225;
    const SECOND_PIVOT_Y = 338;
    const DESIGN_SIZE = 454;
}
