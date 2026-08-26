# Handoff

Date: 2026-08-26

The user added five `rolex*.png` files to `~/projects/watchfaces` and
asked to check them and move them into a new dial project.

Decision: **new `watchface` package** at `faces/already-late` in this
repo. App name “Already Late”. Do not call it Rolex.

What was true after looking at the files:

- Already 454×454 (or hand sprites), black + orange, ~5% lit. AOD can
  reuse the high-power drawing if the seconds hand is omitted.
- Slim Dial’s “never blit the photo” rule still applies to the **raw**
  RGBA files (heap). Palettized resources into the graphics pool are in
  bounds and are the actual look — the handwriting and scattered
  numerals cannot come from `FONT_TINY`.

Dial blit and bitmap hands are in. Pivots: hour/minute 29 px from the
bottom of the sprite, seconds 56 px. Arbor last, centered.
