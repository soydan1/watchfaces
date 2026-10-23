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

The outer metal rim is removed with an inner-dial circular crop. Pixels outside
the circle are flattened to black, so hidden rim RGB cannot leak through.
The supplied needle is shortened and pivots about its hub, not the sprite
centre. It is drawn last, **above the bezel and digits**, so it can cover part
of the minutes near hour 7. Red numeral patches preserve the existing scale.

Digits are solid red-orange seven-segment sprites generated without a font
dependency. Subtle top-left highlights and lower-right shadow edges give the
segments a raised bevel; shading is baked into the PNGs, not extra runtime
layers. All digits have equal visible height, including 1/4/7. Minutes are
28×44 px; date digits are 24×42 px (twice the original 21 px date height), in a
124 px-wide date band. The date is centred by its visible strokes at x=322,
not its container: days 10–19 shift 8 px left to compensate for the narrow
leading 1. Both active and AOD use this layout. `digits.PNG` remains
in reference/ for provenance, but the dotted font is no longer used.

## Always-on

Sleep mode uses the supplied **dark-speedometer.png**, with the same hour
needle, red 11/12 highlights, minute digits, and date as the active face. Wake
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
```

`bin/light-preview.png`, `bin/dark-preview.png`, `bin/aod-preview.png`,
`bin/needle-over-minutes-preview.png`, and `bin/hours-preview.png`
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

### Performance diagnostics

Enable **Log render performance** in simulator App Settings. The next updates
print `drawMs`, `maxDrawMs`, `heap`, `maxObservedHeap`, and `free`, together with
active/AOD and theme state. Logging is off by default. Times measure the draw
path (including a theme load when applicable), excluding the log formatting
itself. Observed heap is not the allocator peak; also inspect the simulator's
Memory view/profiler. Simulator timing is not a device battery-life estimate.

Check cold start, steady active updates, AOD, and repeated sleep/wake/theme
switches. Keep the app below its 128 KB heap limit, record peaks and update
times, and watch for growth over several minutes. Disable logging afterwards.
The test PRG also reports the time/heap delta for 4,800 angle lookups and checks
retained resources against 128 KB. These measurements have not been run yet.

Rendering changes avoid per-update angle-array allocations, draw minute glyphs
at native size (only date glyphs and needle require transforms), reuse the same
transform object, and no longer load/redraw a window patch over the needle.
No full-screen offscreen buffer or seconds animation is introduced.

### Runtime acceptance checklist (not yet verified)

- Build both app and tests; all tests pass with retained heap below 128 KB.
- Simulator: 00:00, 01:09, 10:59 → 11:00 → 12:00 → 13:00 and 23:59 → 00:00.
- Verify label 1/2 registration, no leftover highlight after hour 12, and needle
  direction at all hours on both themes.
- Check date/month leading zeroes and date rollover, including month/year edges.
- Change **Dark dial** through simulator App Settings; verify the plate switches
  without memory errors, and the needle stays over the minutes in both modes.
- Check peak memory while actually drawing/rotating; the resource test alone
  does not prove the render path fits.
- Enter low-power mode: verify the supplied dark artwork appears, record the
  screen heat map/AMOLED warnings, and verify wake restores the selected theme.
  Full-artwork AOD compliance is not established.

After verification, manually sideload `bin/Speedometer.prg` to `GARMIN/APPS/`
and select **Speedometer**. No device copy or deployment is automated here.

## Verification status

Offline image/layout/XML checks are available in `tools/test_assets.py`.
Ten offline asset/layout checks passed for the bevelled seven-segment,
optically centred date, and foreground-needle revision. Compilation and runtime performance remain unverified for this
revision. SDK 9.2.0, connectiq, monkeydo, and xvfb-run are installed on the coding
host, but a signed updated PRG is required to run this face in the simulator.
The coding agent has not accessed the owner's signing key. The owner can build
locally and provide the app/test PRGs (not the key) for simulator checks.
