# Speedometer — Garmin D2 Mach 2

Personal-use Connect IQ watch face, 454×454, API 5.2+. Independent application
ID: existing installed faces are not replaced.

## Reading the dial — seconds/rev mode (default)

The supplied **needle image is retained**, above all windows and digits.
**Seconds needle + full day** and **Dark instrument lighting** default to on.

- Upper window: complete two-digit day, e.g. **15**, optically centred.
- Lower window: fixed **24-hour `HH:MM`** with a steady colon.
- Awake: the needle tracks seconds along the measured 0–10 arc. Each printed
  division represents **six seconds** (42 seconds points to 7).
- AOD: park at the last rendered angle, even across minute/day changes. This
  is deliberately not an accurate seconds reading. A first launch directly
  into AOD seeds a position from the current second, then parks it.
- Wake: about **500 ms** of smooth acceleration/deceleration from the parked
  angle to the live second. Cold start goes straight to the current second.
- 59→00: about **350 ms** returning down the gauge arc, never a full-circle
  spin through the unused gap. Rollover takes priority during wake movement.
- Steady seconds use the SDK's native high-power once-per-second updates.
  Only the short movements request extra frames, using a 50 ms timer guarded
  by display/visibility/mode state. Sleep/hide stops it and parks the motor.
  Actual cadence and performance remain unverified.

### Earlier date-gauge variation

Disable **Seconds needle + full day** to restore the date gauge (its own setting
remains on by default). Disable **Dark instrument lighting** independently to
restore the old background selection using **Dark dial**.

- Bottom-right window: optically centred **24-hour `HH:MM`**, regardless
  of the device's clock preference. Its inner LCD background is black with
  the original backgrounds, amber-lit with instrument lighting.
- Top window: date tens digit, using the same segmented/stencil font as the time.
- Needle: date ones digit, pointing to the printed 0–9. The printed 10 is unused.
- Date 05: top **0**, needle at **5**. Date 15: top **1**, needle at **5**.
- Dates 10/20/30: top **1/2/3**, needle at the bottom **0**, not the printed 10.
- Date 31: top **3**, needle at **1**. Day 01 restores top **0**, needle at **1**.
- No red 1/2 hour highlight in this mode. The month is not displayed.
- **Dark dial** selects the active background; AOD always uses the dark artwork.

### Original hour-gauge variation

With seconds mode off, also disable **Date gauge** to restore the preceding design: the needle
points to hours 1–10, or red 1/2 for 11/12; top window shows minutes, lower
window shows large `DD-MM`. The needle steps once per hour. Both variations
remain in the same application; changing the setting does not require a
second installation.

The outer metal rim is removed with an inner-dial circular crop. Pixels outside
the circle are flattened to black, so hidden rim RGB cannot leak through.
The supplied needle is shortened and pivots about its hub, not the sprite
centre. It is drawn last, **above the bezel and digits**, so it can cover part
of the upper day at 42 seconds, the old date-tens digit at 7, or minutes near hour 7
in the original variation. Red numeral patches are used only by that original
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
container. Times beginning with 1 shift 8 px left. The fallback date-tens glyph is 58 px
high; the full day uses two 22×44 px glyphs at y=112. In the original variation, minutes are 28×44 px and date digits 24×42 px,
with the same optical centring. Both active and AOD use the selected layout.
The black lower-panel fill is baked into the light background using a mask of
the dark artwork's inner LCD, preserving the rounded bezel. `digits.PNG` remains
in reference/ for provenance, but the dotted font is no longer used.

## Always-on

Instrument lighting uses two baked variants of the supplied
**dark-speedometer.png**: richer charcoal/bevel/amber LCD lighting while awake,
and a restrained version in AOD. Background switching is **instant**, with no
fade. Only the selected plate is retained. Lighting takes precedence over
**Dark dial**; turn lighting off for the previous yellow/dark theme behaviour.

Parking the needle is not burn-in protection. Static numerals, the hub, the
parked blade, and the added dim background pixels require device-specific
power/protection testing. AOD compliance is **not established**. See
[TESTING.md](TESTING.md) for the new sampled image estimates; use the SDK heat
map/accelerated test and record actual warnings before regular AOD use.

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

### Instrument artwork and seconds previews

`tools/instrument_art.py` provides the shared offline lighting generator used
by asset preparation and the original comparison tool `tools/preview_depth.py`.
Reference artwork is never modified. `prepare_assets.py --preview` also writes:

- `bin/seconds-active-preview.png` / `bin/seconds-aod-preview.png`: full day 15,
  13:54, needle at second 47 (parked in the AOD mockup).
- `bin/needle-rev-preview.gif`: 500 ms wake-motion design mockup.
- `bin/needle-return-preview.gif`: 350 ms return-motion design mockup.

These are fixed-value Pillow compositions, not runtime recordings. The GIFs
illustrate the easing, not real SDK timer behaviour or native frame rate.
Run `tools/test_depth_preview.py` and `tools/test_seconds.py` for additional
offline checks. Temperature/calorie/step readouts and controls are not yet added.

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
active/AOD, plate, layout, `moving`, and `needleAngle` state. Logging is off by default. Times measure the draw
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
the heap test includes them and the new instrument plates. No full-screen
offscreen buffer is introduced. Only short high-power needle movements use a timer.

### Runtime acceptance checklist (not yet verified)

- Build both app and tests; all tests pass with retained heap below 128 KB.
- Default layout: full day 01–31 fits the upper window and remains centred.
- Check seconds 0–59: 6→1, 42→7, 54→9; 59→00 returns over the dial arc.
- Enter AOD mid-movement and at several needle positions: it must stay parked
  over several minute updates, then catch up on wake. Cold start must not rev.
- Test minute rollover during wake, repeated wakes, hide/show, display off,
  and disabling seconds during a movement. No low-power timer may be started.
- Turn seconds off to test the earlier date-gauge/legacy layouts; turn lighting
  off to test the original yellow/dark backgrounds.
- Time: 00:00, 01:09, 10:59 → 11:00 → 12:00 → 13:00 and 23:59 → 00:00;
  verify the face stays 24-hour even with a 12-hour device setting, and centring.
- With seconds off, toggle **Date gauge**: original top minutes / bottom DD-MM and red
  hour-11/12 behaviour must return without stale overlays.
- With lighting off, change **Dark dial** through simulator App Settings; verify the plate switches
  without memory errors, and the needle stays above the upper display.
- Check peak memory while actually drawing/rotating; the resource test alone
  does not prove the render path fits.
- Enter low-power mode: verify the selected dark artwork appears, record the
  screen heat map/AMOLED warnings, and verify wake restores the selected theme.
  Full-artwork AOD compliance is not established.

After verification, manually sideload `bin/Speedometer.prg` to `GARMIN/APPS/`
and select **Speedometer**. No device copy or deployment is automated here.

## Verification status

Offline image/layout/XML checks are available in `tools/test_assets.py`.
The original 17 checks, four lighting checks, and six seconds-layout/geometry/
wiring checks passed (**27 offline checks**). They do not execute Monkey C.
Additional native unit tests cover the seconds arc, parked state, wake/return,
interruption, live-target updates, and deferred/cancelled wake; they remain
unexecuted along with the existing Monkey C tests.
Compilation and runtime performance remain unverified for this revision. SDK 9.2.0, connectiq, monkeydo, and xvfb-run are installed on the coding
host. The native simulator launch was verified under Xvfb, but a signed updated
PRG is still required to run this face and its unit tests. See TESTING.md.
The coding agent has not accessed the owner's signing key. The owner can build
locally and provide the app/test PRGs (not the key) for simulator checks.
