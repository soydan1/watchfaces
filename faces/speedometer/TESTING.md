# Date-gauge revision: verification results

These results cover the current working-tree wake-fade revision, retaining
the stencil font, black LCD and fixed 24-hour time. AOD image metrics below
measure the unchanged static low-power layout, not the high-power transition.

## Verified on the coding host

- Connect IQ SDK **9.2.0** and the **d2mach2** device package are installed.
- Device metadata specifies a **454×454 round AMOLED**, 16 bits per pixel,
  screen protection support, and **131,072 bytes** of watch-face heap.
- The native **Connect IQ simulator opened an X11 window under Xvfb**. The
  window title was detected through X11, then that test process was closed.
  This was a launcher smoke test only: Speedometer was not loaded.
- **21 offline asset/layout/metric/wiring checks passed.** They cover the date
  mapping, shared font, centring, black LCD, legacy layout, AOD metric formulas,
  wake timing/eligibility, blend endpoints/bounds, unchanged foreground ink,
  and source-level sleep/hide/timer-cancellation guards. They do not execute
  Monkey C or prove actual SDK callback/timer behaviour.

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
| Gamma-encoded RGB-weighted luma | 8.946% | 9.493% |
| Linear-sRGB luminance | 3.833% | 4.259% |
| Non-black pixel coverage | 42.451% | 43.396% |

The highest encoded-luma sample was date **09**, time **08:08**. At date 15,
**68,513 pixels (42.344%)** remained non-black in every sampled frame from
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

## Wake-fade checks and pending runtime validation

The 300 ms effect uses five packed pre-blended backgrounds (1,088,078 bytes
of additional PNG assets), with 50 ms high-power-only update requests. The view
retains only its current intermediate alongside the final target plate. It
never allocates a full-screen blending buffer. The graphics pool may cache
additional images; native peak memory and decoding time are still unknown.

`test/WakeFadeTest.mc` adds pure Monkey C state tests for eligibility, phase
progression, completion, skipped frames, cancellation before/after starting,
and restart. They never start an SDK timer from the test runner and remain
**unexecuted** until a signed test PRG is provided. The resource heap test now
checks each intermediate, retaining one at a time.

The GIF in `bin/wake-preview.gif` is a generated design preview (300 ms fade
plus a final-frame hold), not evidence of native animation performance.

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
3. Enable **Wake-up fade**, enter AOD, and wake the face. Verify it finishes
   around 300 ms and `fadeFrame` settles at 6. Re-enter sleep mid-fade: no more
   high-power frames/timer activity should occur. Test disabling the fade,
   selecting Dark dial, hiding/showing the view, and rapid repeated wakes.
4. Exercise both layouts/themes and repeated sleep/wake transitions. Check
   09→10, 19→20, 29→30, 31→01, midnight, and fixed 24-hour output even if the
   watch's own clock preference is 12-hour. Verify the high-power time panel is
   black and its rounded bezel has not been covered.
5. Enter low-power mode. Where enabled, use **File → View Screen Heat Map** and
   start the SDK's accelerated test. Record device-specific luminance/protection
   results rather than treating the offline image estimates as an SDK result.
6. Leave always-on disabled for regular device use until those checks pass.
