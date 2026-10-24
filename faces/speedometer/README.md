# Speedometer — Garmin D2 Mach 2

Personal-use Connect IQ watch face, 454×454, API 5.2+. Independent application
ID: existing installed faces are not replaced.

## Reading the dial — date gauge (default)

The original **needle image is retained**. The date gauge layout is selected by
app setting **Date gauge layout**, enabled by default.

- Bottom-right window: large, optically centred **24-hour `HH:MM`**, regardless
  of the device's clock preference. The colon is steady; no seconds or animation.
  The inner LCD background is black on both the yellow and dark faces.
- Top window: date tens digit, using the same segmented/stencil font as the time.
- Needle: date ones digit, pointing to the printed 0–9. The printed 10 is unused.
- Date 05: top **0**, needle at **5**. Date 15: top **1**, needle at **5**.
- Dates 10/20/30: top **1/2/3**, needle at the bottom **0**, not the printed 10.
- Date 31: top **3**, needle at **1**. Day 01 restores top **0**, needle at **1**.
- No red 1/2 hour highlight in this mode. The month is not displayed.
- **Dark dial** selects the active background; AOD always uses the dark artwork.

### Original hour-gauge variation

Disable **Date gauge layout** to restore the preceding design: the needle
points to hours 1–10, or red 1/2 for 11/12; top window shows minutes, lower
window shows large `DD-MM`. The needle steps once per hour. Both variations
remain in the same application; changing the setting does not require a
second installation.

The outer metal rim is removed with an inner-dial circular crop. Pixels outside
the circle are flattened to black, so hidden rim RGB cannot leak through.
The supplied needle is shortened and pivots about its hub, not the sprite
centre. It is drawn last, **above the bezel and digits**, so it can cover part
of the upper date digit when its ones digit is 7 (or the minutes near hour 7
in the original variation). Red numeral patches are used only by that original
variation.

Digits use an original angular segmented/stencil design inspired by the
Ferrari F430 neutral **N** reference, with split centre strokes and warm
ivory/amber colouring. This is a stylistic recreation, not an identified or
extracted commercial font. Both the date tens and digital time use this face.
Reference: https://tr.pinterest.com/pin/403353710347136692/

Subtle top-left highlights and lower-right shadow edges give the segments a
raised bevel; shading is baked into the PNGs, not extra runtime layers. All
digital digits have equal visible height, including 1/4/7. Time digits are
24×48 px, in a 124 px-wide band centred at x=322 by visible strokes, not its
container. Times beginning with 1 shift 8 px left. The date tens glyph is 58 px
high. In the original variation, minutes are 28×44 px and date digits 24×42 px,
with the same optical centring. Both active and AOD use the selected layout.
The black lower-panel fill is baked into the light background using a mask of
the dark artwork's inner LCD, preserving the rounded bezel. `digits.PNG` remains
in reference/ for provenance, but the dotted font is no longer used.

## Always-on

Sleep mode uses the supplied **dark-speedometer.png**, with the selected
layout's same digital time/date and image needle. Wake
restores the selected active theme. The dark plate is not further dimmed or
pixel-shifted: this is intentionally a baseline for the owner's burn-in test,
not a claim of AMOLED compliance. Static numerals, bezels, and the bright hub
may exceed Garmin's pixel-coverage or burn-in limits. Test in the simulator
before considering daily always-on use.

In the simulator, enable low-power/sleep mode and open **File → View Screen
Heat Map**. Watch it across several minutes, including an hour boundary; also
check that wake restores the yellow dial when Dark dial is disabled. Share the
heat-map result and any device warnings before adding mitigation.

## Assets and offline checks

Prepared PNGs are checked in; Pillow is only needed to regenerate them.
Reference originals are kept in `reference/`, outside the compiled resources.
All runtime PNGs use `packingFormat="png"`; no full-screen buffered bitmap is
allocated. Only the selected background is retained by the view.

```sh
python3 tools/prepare_assets.py --preview
python3 tools/test_assets.py
python3 tools/check_aod.py
```

See [TESTING.md](TESTING.md) for verified simulator-launch results, offline AOD
estimates, and the precise signed-build blocker. The AOD script is image
screening, not the SDK heat-map test or a compliance certificate.

These are **static Pillow composition checks**, not simulator captures:

- `bin/light-preview.png`: 13:54, date 15, default date-gauge layout.
- `bin/dark-preview.png` / `bin/aod-preview.png`: 23:54, date 31.
- `bin/date-zero-preview.png`: 00:00, date 20 (needle at 0).
- `bin/dates-preview.png`: representative dates including tens/ones boundaries.
- `bin/font-preview.png`: the reference-inspired N and new digits 0–9.
- `bin/needle-over-minutes-preview.png`: date 17, needle above the top digit.
- `bin/legacy-light-preview.png` / `bin/hours-preview.png`: original variation.

Runtime digital glyphs use Garmin's scaler; small rendering differences are
possible.

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

### Performance diagnostics

Enable **Log render performance** in simulator App Settings. The next updates
print `drawMs`, `maxDrawMs`, `heap`, `maxObservedHeap`, and `free`, together with
active/AOD, theme, and date/hour-layout state. Logging is off by default. Times measure the draw
path (including a theme load when applicable), excluding the log formatting
itself. Observed heap is not the allocator peak; also inspect the simulator's
Memory view/profiler. Simulator timing is not a device battery-life estimate.

Check cold start, steady active updates, AOD, and repeated sleep/wake/theme
switches. Keep the app below its 128 KB heap limit, record peaks and update
times, and watch for growth over several minutes. Disable logging afterwards.
The test PRG also reports the time/heap delta for 4,800 angle lookups and checks
retained resources against 128 KB. These measurements have not been run yet.

Rendering avoids per-update angle-array allocations, reuses one transform
object, and does not load/redraw a window patch over the needle. Date-gauge
mode draws its top digit at native size and scales four time sprites plus the
needle. The original variation draws its minutes at native size. Four small
packed date-tens sprites are retained in addition to the existing resources;
the heap test includes them. No full-screen offscreen buffer or seconds
animation is introduced.

### Runtime acceptance checklist (not yet verified)

- Build both app and tests; all tests pass with retained heap below 128 KB.
- Default layout: check every date 01–31 on both themes, especially 09 → 10,
  19 → 20, 29 → 30, and 31 → 01. Tens and needle must update together.
- Check 10/20/30 point to 0, and printed 10 is unused. No red hour highlights.
- Time: 00:00, 01:09, 10:59 → 11:00 → 12:00 → 13:00 and 23:59 → 00:00;
  verify the face stays 24-hour even with a 12-hour device setting, and centring.
- Toggle **Date gauge layout**: original top minutes / bottom DD-MM and red
  hour-11/12 behaviour must return without stale overlays.
- Change **Dark dial** through simulator App Settings; verify the plate switches
  without memory errors, and the needle stays above the upper display.
- Check peak memory while actually drawing/rotating; the resource test alone
  does not prove the render path fits.
- Enter low-power mode: verify the supplied dark artwork appears, record the
  screen heat map/AMOLED warnings, and verify wake restores the selected theme.
  Full-artwork AOD compliance is not established.

After verification, manually sideload `bin/Speedometer.prg` to `GARMIN/APPS/`
and select **Speedometer**. No device copy or deployment is automated here.

## Verification status

Offline image/layout/XML checks are available in `tools/test_assets.py`.
Seventeen offline asset/layout/metric checks passed for the stencil-font and
black-window revision, including all 31 dates, zero-angle calibration, shared
font assets, fixed-24-hour time centring, rounded black LCD masking, stencil
cutouts, and known-colour AOD calculations. Monkey C unit tests also
cover all dates and 24-hour mappings, but have not been executed yet.
Compilation and runtime performance remain unverified for this revision. SDK 9.2.0, connectiq, monkeydo, and xvfb-run are installed on the coding
host. The native simulator launch was verified under Xvfb, but a signed updated
PRG is still required to run this face and its unit tests. See TESTING.md.
The coding agent has not accessed the owner's signing key. The owner can build
locally and provide the app/test PRGs (not the key) for simulator checks.
