# Already Late — Design Notes

Personal Connect IQ watch face for D2 Mach 2. Visual source is five
device-sized PNGs the user dropped in `~/projects/watchfaces` as
`rolex*.png`. They now live in `reference/` under neutral names.

This is a joke dial, not a product replica. Do not ship it as “Rolex”.

## References

Moved from `watchfaces/` (original filename → here):

| File | Original | Size | Notes |
|---|---|---|---|
| `reference/dial.png` | `rolexBG.png` | 454×454 RGBA, 48 KB | Exact D2 Mach 2 pixel size. Black field, orange crown at 12, handwritten “Who cares / I’m already late”, numerals 1–12 scattered (not on a chapter ring). |
| `reference/hour.png` | `rolexHour.png` | 18×158 RGBA | Straight orange baton, opaque stem 10×150. |
| `reference/minute.png` | `rolexMinute.png` | 10×187 RGBA | Solid `#F08018` rectangle, no alpha. |
| `reference/second.png` | `rolexSecond.png` | 36×241 RGBA | Lightning-bolt seconds: arrow tip, three jogs, diamond counterweight. |
| `reference/arbor.png` | `rolexMiddle.png` | 36×36 RGBA | Orange center cap, ~30 px disc. |

Unlike Slim Dial’s product photos, these are already 454×454 (or hand
sprites). `dial.png` is the watch dial: it is imported as a 4-color
palette (`packingFormat="png"`) and drawn with `dc.drawBitmap`. A decoded
454×454 16bpp buffer is ~403 KB and will not fit the 128 KB watch-face
heap, so the resource stays palettized in the graphics pool.

## Platform constraints

- App type: `watchface` (this repo).
- Screen: 454×454 AMOLED, 16 bpp.
- Heap: **128 KB**. Fullscreen buffer ~403 KB.
- d2mach2 `imageFormats`: `yuv`, `jpg`, `png`. `enhancedGraphicSupport` is true, so a palettized bitmap can live in the graphics pool, not the app heap.
- AMOLED always-on (API 5.2 `System.getDisplayMode()`):
  - `DISPLAY_MODE_HIGH_POWER` — wrist up, ~10 s, 1 Hz updates.
  - `DISPLAY_MODE_LOW_POWER` — AOD, once per minute.
  - At most ~10% of pixels (or luminance on newer AMOLED) may be lit.
  - No pixel may stay on longer than three minute-updates. Shift the whole drawing 1 px on a 5-step orbit (`LateGeometry.burnInShift`).
  - `onPartialUpdate` is a MIP seconds trick. Do not rely on it here.

## High power and AOD are the same drawing

The dial is already a sparse orange-on-black. Measured on `dial.png`:

- 10 225 non-black pixels = **4.96%** of 454×454.
- Orange ≈ `#F08018`.
- Adding hour + minute + arbor ≈ **6.9%**.
- Adding the seconds hand ≈ **7.8%**.

Both modes stay under the 10% lit-pixel cap if we do not fill extra
pixels. Do **not** invert, dim, or restyle for AOD.

| | High power | Always-on |
|---|---|---|
| Field | black | black |
| Dial art | same orange | same orange |
| Hour / minute / arbor | yes | yes |
| Seconds | yes (1 Hz) | **no** (AOD is 1/min) |
| Burn-in shift | no | 1 px, 5-step orbit |

AOD updates once a minute, so a seconds hand would freeze. Dropping it
is the AOD variant; it is also a small pixel-budget margin.

## Color

- Field `#000000`
- Ink and hands `#F08018`
- No second palette. No cream-on-black restyle.

## Hands

Hour and minute are straight batons. Seconds is a lightning bolt, not a
Mercedes star: arrow at the tip, shaft jogs left three times, diamond at
the tail.

Sprites rotate with `dc.drawBitmap2` + `AffineTransform`. Pivot is a
fixed pixel on each PNG, measured from the **bottom**:

| Hand | PNG | Pivot from bottom | Pivot (x, y) | Tip above pivot |
|---|---|---|---|---|
| Hour | 18×158 | 29 px | (9, 129) | 129 px |
| Minute | 10×187 | 29 px | (5, 158) | 158 px |
| Seconds | 36×241 | 56 px | (9, 185) | 185 px |
| Arbor | 36×36 | — | (18, 18) | unrotated |

Seconds pivot x is the shaft (x=9), not the 36 px canvas center. The
center cap is drawn **last** (on top of the hands) and centered on the
dial so it covers the intersection.

## Memory policy

- Keep originals in `reference/`. Do not add them as Connect IQ drawables until they are palettized.
- Import with a 2–4 color `<palette>` (black + orange, plus one or two AA greys if the script needs it) and `dithering="none"`. `packingFormat="png"` is valid on this device.
- Never `Graphics.createBufferedBitmap` at 454×454.
- Fail the unit test if helper code grows the heap by 16 KB.

## Out of scope for v1

- Complications
- Settings / colorways
- Publishing to the Connect IQ Store under a Rolex name
- Sharing code or Storage with Strength Coach or Slim Dial
