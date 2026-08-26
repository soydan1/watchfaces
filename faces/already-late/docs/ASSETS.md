# Asset measurements

Source files were `rolexBG.png`, `rolexHour.png`, `rolexMinute.png`,
`rolexSecond.png`, `rolexMiddle.png` in `~/projects/watchfaces`. They
were moved here on 2026-08-26 and renamed.

## dial.png (454×454 RGBA)

- File size 48 132 bytes.
- Opaque bbox is the full screen.
- Non-black pixels: 10 225 (4.96%).
- Dominant ink after 5-bit quantize: `(240, 128, 24)` → `#F08018`.
- Antialiased script produces ~231 quantized colors; a 2-color palette
  will stair-step the handwriting; 4 colors (black, orange, two AA
  steps) should be enough.
- Art: 5-point crown at 12, two lines of script under it, a faint
  hollow ring near the arbor, numerals 1 6 10 4 2 11 8 5 3 9 7 12
  scattered in the lower half — not 30° apart.

## hour.png (18×158)

- Opaque stem x=4–13, y=0–149 (10×150).
- Pivot 29 px from the bottom: (9, 129).

## minute.png (10×187)

- Every pixel is opaque `#F08018`.
- Pivot 29 px from the bottom: (5, 158). Same rule as the hour hand.

## second.png (36×241)

Lightning bolt, not a straight baton. Row widths:

| Region | Y | Shape |
|---|---|---|
| Arrow tip | 0–16 | widens to ~13 px, x around 23–34 |
| Jog 1 | ~32–36 | shaft shifts left |
| Shaft | ~40–80 | ~6 px, x around 21–26 |
| Jog 2 | ~84–90 | another left shift |
| Shaft | ~92–132 | ~6 px, x around 13–18 |
| Jog 3 | ~136–140 | another left shift |
| Shaft | ~144–212 | ~5–6 px, x around 6–11 |
| Diamond | ~216–240 | widest ~16 px, taper to a point |

Pivot is 56 px from the bottom: (9, 185). That row is the lower shaft
(x=7–11), above the diamond counterweight. Not the 36 px canvas center.

## arbor.png (36×36)

- Opaque disc about 30×33, y=0–27. Empty rows at the bottom of the PNG.
- Unrotated. Draw last, on top of the hands, with the image center
  (18, 18) on the dial center.
