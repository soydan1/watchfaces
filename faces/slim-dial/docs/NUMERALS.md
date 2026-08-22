# Hour numeral construction

Source of truth: `reference/hermes.png` (filled, high power) and
`reference/hermes-dark.png` (stroke, AOD). All glyphs are upright.

Local box for a single digit: height = `size`, width ≈ `0.55 * size`,
origin at glyph center. Stroke is 1–2 px; high power may fill, AOD must
stay outline.

## 1

A single vertical stem. No serif, no flag. Slightly shorter than 8 so a
“12” pair does not dwarf neighboring hours.

## 2

The signature angular 2. Top is a sharp open hook (almost a 7), then a
diagonal into a baseline that does not close a loop. Not an “S” 2.

## 3

Two stacked open curves, same contrast as 2. The join at mid-height is a
cusp, not a continuous S.

## 4

Open 4. Left diagonal and right stem meet at the top; the crossbar does
**not** close a triangle on the left. Looks like a chevron with a vertical
on the right.

## 5

Angular top bar, then a curve into an open lower bowl. Sibling of 2,
mirrored in spirit, not in geometry.

## 6

Open loop. Thin oval bowl with a rising spine that does not close at the
top. Not a closed 6.

## 7

Two strokes: short horizontal, long diagonal. Same stem weight as 1.

## 8 — lock this first

**Two stacked circles**, same radius, touching at the center. This is not
a traditional 8 (no pinched waist from a single path). Helper already in
`HermesNumerals.drawEight`. High power: outline or very thin fill-ring.
AOD: outline only.

Use the 8 to set:

- stroke width
- circle radius as a fraction of `size`
- optical center vs geometric center

Then match 0, 6, 9 to that oval language.

## 9

6 inverted. Same open loop, spine downward.

## 0

Perfect thin oval / circle. Used in 10. Same radius language as one half
of the 8, maybe slightly taller.

## 10 / 11 / 12

Draw as two glyphs with a tight gap (~0.12 of `size`). Center the pair on
the hour point so “12” sits on the 12 o’clock axis, not the “1”.

Suggested pair width: `1.2 * size`.

## Placement

```
angle = hour/12 * 2π − π/2    // 12 at top
x = cx + cos(angle) * numeralRadius
y = cy + sin(angle) * numeralRadius
```

Numeral radius is `HermesGeometry.NUMERAL_RING` (0.84 of half-axis).
Keep them outside the chapter ring. At 6, the subdial eats the inner
disc; the 6 glyph still sits on the outer flange.

## AOD subset

Draw 12, 3, 9 only, outline, 1 px, cream on black. Skip 6 so the lower
half can take the minute hand without blowing the pixel budget.
