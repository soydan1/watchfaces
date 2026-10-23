# Speedometer — Garmin D2 Mach 2

Personal-use Connect IQ watch face, 454×454, API 5.2+. Independent application
ID: existing installed faces are not replaced.

## Reading the dial

- Hours 1–10: needle points to the original printed number.
- Hour 11: needle points to **1**, and **1 turns red**.
- Hour 12 (including midnight): needle points to **2**, and **2 turns red**.
- At 13:00/01:00 the needle returns to the normal 1; the highlight clears.
- Needle steps once per hour. It does not interpolate with minutes.
- Top window: minutes, always two digits (`00`–`59`).
- Bottom-right window: local day–month (`DD-MM`, e.g. `10-08`).
- App setting **Dark dial** selects the alternate supplied background.

The metal rim is cropped to a narrow border. The supplied needle is shortened
and pivots about its hub, not the sprite centre. The top screen/bezel sits in
front of the needle so minutes remain legible near hour 7. Red numeral patches
preserve the existing scale. LED sprites use a clean dot sampled from digits.PNG
and rebuild its digit patterns to eliminate scattered red artefacts.

## Always-on

A deliberately simpler black display with dim digital 12-hour time and date,
not the full dark photograph. The group cycles through five separated vertical
positions every minute. Heat-map/pixel coverage, font spacing, and burn-in
behaviour still need simulator/device verification; do not assume compliance
from the image or positioning code alone.

## Assets and offline checks

Prepared PNGs are checked in; Pillow is only needed to regenerate them.
Reference originals are kept in `reference/`, outside the compiled resources.
All runtime PNGs use `packingFormat="png"`; no full-screen buffered bitmap is
allocated. Only the selected background is retained by the view.

```sh
python3 tools/prepare_assets.py --preview
python3 tools/test_assets.py
```

`bin/light-preview.png`, `bin/dark-preview.png`, and `bin/hours-preview.png`
are **static Pillow composition checks**, not simulator captures. The contact
sheet shows 1–12 at minute 54 and date 10-08. Runtime date digits are scaled by
the Garmin renderer; small rendering differences are possible.

## Build and test — run locally with your signing key

From this directory, using the existing SDK 9.2.0 toolchain:

```sh
monkeyc -o bin/Speedometer.prg -f monkey.jungle \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -w
monkeyc -o bin/SpeedometerTest.prg -f 'monkey.jungle;monkey.test.jungle' \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -t -w
monkeydo bin/SpeedometerTest.prg d2mach2 -t
monkeydo bin/Speedometer.prg d2mach2
```

Signing must be performed by the owner; do not share the private key. Linux
`monkeydo` can return 1 even if tests pass: inspect its textual summary.

### Runtime acceptance checklist (not yet verified)

- Build both app and tests; all tests pass with retained heap below 128 KB.
- Simulator: 00:00, 01:09, 10:59 → 11:00 → 12:00 → 13:00 and 23:59 → 00:00.
- Verify label 1/2 registration, no leftover highlight after hour 12, and needle
  direction at all hours on both themes.
- Check date/month leading zeroes and date rollover, including month/year edges.
- Change **Dark dial** through simulator App Settings; verify plate and window
  switch together without memory errors.
- Check peak memory while actually drawing/rotating; the resource test alone
  does not prove the render path fits.
- Enter low-power mode: check time/date do not overlap, screen heat map remains
  within AMOLED limits, and wake restores the coloured dial.

After verification, manually sideload `bin/Speedometer.prg` to `GARMIN/APPS/`
and select **Speedometer**. No device copy or deployment is automated here.

## Verification status

Offline image/layout/XML checks are available in `tools/test_assets.py`.
Compilation and simulator checks are pending: `monkeyc` refuses an unsigned
build, and the coding agent has not accessed the owner's signing key.
