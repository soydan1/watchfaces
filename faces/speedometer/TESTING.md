# Date-gauge revision: verification results

These results cover the current working-tree digital-time/date-gauge revision,
not just the previously pushed hour-gauge build.

## Verified on the coding host

- Connect IQ SDK **9.2.0** and the **d2mach2** device package are installed.
- Device metadata specifies a **454×454 round AMOLED**, 16 bits per pixel,
  screen protection support, and **131,072 bytes** of watch-face heap.
- The native **Connect IQ simulator opened an X11 window under Xvfb**. The
  window title was detected through X11, then that test process was closed.
  This was a launcher smoke test only: Speedometer was not loaded.
- **15 offline asset/layout/metric checks passed.** They cover the date mapping,
  dial numeral assets, pointer calibration, both time formats, centring, legacy
  layout rendering, and AOD metric calculations on known colours.

## Offline AOD screening (not a simulator pass)

Run from `faces/speedometer` with Pillow installed:

```sh
python3 tools/check_aod.py
```

This renders the dark date-gauge layout with Pillow for all dates 01–31 at
00:00, 08:08, 18:58, and 23:59: **124 sampled frames**, in 24-hour mode. It is
not an exhaustive test of all possible times, firmware colour conversion, or
actual on-device framebuffer output.

The screen mask contains 161,800 pixels. Results:

| Estimate | Sampled minimum | Sampled maximum |
|---|---:|---:|
| Gamma-encoded RGB-weighted luma | 8.840% | 9.594% |
| Linear-sRGB luminance | 3.581% | 4.030% |
| Non-black pixel coverage | 42.916% | 44.260% |

The highest encoded-luma sample was date **09**, time **08:08**. At date 15,
**69,291 pixels (42.825%)** remained non-black in every sampled frame from
13:54 through 13:57.

These are intentionally different metrics. The SDK FAQ says the original Venu
uses pixel coverage/persistence limits, while newer AMOLED devices use a
**10% screen-luminance budget**. Neither luma formula above is asserted to be
Garmin's firmware formula. Non-black coverage is not a luminance percentage.
Persistent pixels alone do not establish failure on a luminance-budget device.
The encoded estimate has little headroom if it resembles the device's actual
calculation, so this artwork must not yet be labelled AOD compliant.

Generated details, ignored by Git:

- `bin/aod-screening.json`: all samples and explicitly labelled estimates.
- `bin/aod-persistent-pixels.png`: pixels non-black in all four minute samples.

SDK reference: `doc/docs/Connect_IQ_FAQ/How_Do_I_Make_a_Watch_Face_for_AMOLED_Products.html`.

## Runtime test blocker

No signed updated `Speedometer.prg` or `SpeedometerTest.prg` is available here.
An unsigned compiler preflight exited **101** with:

```text
ERROR: The private key was not specified. Use command line option: -y.
```

The coding agent has not read or used the owner's signing key. The owner must
run the README build commands manually, either in this worktree or on their
own PC, and provide the resulting PRGs, **not the key**. No runtime timing,
heap/GC peak, cold-start rendering, sleep/wake, or official AOD pass/fail result
has been obtained for this revision.

## Next runtime checks once signed PRGs are available

1. Launch `connectiq`, then run `monkeydo bin/SpeedometerTest.prg d2mach2 -t`.
   Inspect the textual test summary; Linux may return nonzero even for passes.
2. Run `monkeydo bin/Speedometer.prg d2mach2` and enable **Log render performance**
   through App Settings. Record cold-start/steady-state draw times and observed
   heap; use the simulator memory/profiler tools for actual allocation peaks.
3. Exercise both layouts/themes and repeated sleep/wake transitions. Check
   09→10, 19→20, 29→30, 31→01, midnight, and both time formats.
4. Enter low-power mode. Where enabled, use **File → View Screen Heat Map** and
   start the SDK's accelerated test. Record device-specific luminance/protection
   results rather than treating the offline image estimates as an SDK result.
5. Leave always-on disabled for regular device use until those checks pass.
