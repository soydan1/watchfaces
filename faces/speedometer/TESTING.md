# Seconds/rev + instrument-lighting revision: verification

## Verified offline

- **29 Python checks passed**: 17 existing asset/layout/metric tests, four
  lighting tests, and eight seconds-layout/geometry/source-wiring tests.
- Seconds mapping is calibrated to the artwork, monotonic over the gauge arc,
  and aligned with every printed division at multiples of six seconds.
- All 31 full-day values fit and are optically centred in the upper window.
- All 60 second positions render in both instrument variants; the image needle
  remains in front of the displays. Existing layouts remain available.
- Motion mockups use bounded smoothstep easing, including reverse motion for
  the 59→00 return. Source checks cover the timer gate and sleep/hide wiring.
- These tests **do not execute Monkey C or verify SDK callbacks/timers**.

The shared generator bakes two packed PNG plates, retaining the supplied
artwork structure. No per-frame blending, extra full-screen buffer, background
fade is introduced. **Smooth needle**, on by default, keeps a 50 ms frame timer
running while visible in confirmed high-power mode. It stops in sleep, off
mode, hiding, or when seconds mode is disabled. With smooth mode off, native
once-per-second updates drive steady seconds; only short movements use the
timer. Native decoding, frame cadence, battery cost and allocation peaks
remain unmeasured.

ClockTime has no fractional-second field. `SecondPhase` estimates the fraction
from observed clock edges and the monotonic timer, clamping below the next
second until its clock edge is observed. Initial phase is unknown until the
first edge. An 80 ms following filter softens corrections; a small visual lag
is intentional. Native tests for fractional geometry, phase edges, steady
sweep, parked/wake behaviour, rollover and switching modes have been added
but not executed. AOD artwork is unchanged by this smooth-motion revision.

Generated design previews (not simulator captures):

- `bin/seconds-active-preview.png`, `bin/seconds-aod-preview.png`
- `bin/needle-rev-preview.gif`, `bin/needle-return-preview.gif`

## Earlier host-tooling checks (not re-run app validation)

SDK **9.2.0** and the **d2mach2** package are installed. Device metadata specifies
454×454 round AMOLED, API 5.2, and **131,072 bytes** of watch-face heap. An earlier
Xvfb/X11 launcher smoke test opened the native Connect IQ simulator; it did not
load Speedometer and does not validate this revision.

## Offline AOD screening — not a simulator pass

Run from `faces/speedometer`, with Pillow installed:

```sh
python3 tools/test_assets.py
python3 tools/test_depth_preview.py
python3 tools/test_seconds.py
python3 tools/check_aod.py
# Optional comparison with the original dark date-gauge layout:
python3 tools/check_aod.py --legacy
```

The default screening uses the new instrument AOD plate and full day. It
samples all dates at four time/parked-position pairs, plus all 60 parked
positions at 23:59/day 28: **184 sampled frames**. The needle is fixed at second
47 across four consecutive minute frames for the persistence estimate. This is
not exhaustive across every date/time/parked-angle combination and does not
model SDK framebuffer conversion or motion while awake.

The round screen mask contains 161,800 pixels:

| Estimate | Sampled minimum | Sampled maximum |
|---|---:|---:|
| Gamma-encoded RGB-weighted luma | 9.294% | 9.755% |
| Linear-sRGB luminance | 4.003% | 4.364% |
| Non-black pixel coverage | 84.431% | 84.460% |

The highest encoded-luma sample was day **08**, **08:08**, parked second **20**.
Across 13:54–13:57/day 15, **136,625 pixels (84.441%)** remained non-black.
Dim charcoal shading substantially increases non-black/persistent coverage
compared with the previous black background. Parking a bright needle does not
provide burn-in protection.

The SDK FAQ distinguishes older coverage/persistence rules from newer AMOLED
luminance-budget rules. Neither luminance estimate here is asserted to match
Garmin's firmware. The encoded estimate leaves little headroom if the firmware
resembles that formula. These results establish **neither compliance nor a
safe daily-use AOD configuration**. Native heat-map/protection testing is required.

Results are saved to ignored `bin/aod-screening.json` and
`bin/aod-persistent-pixels.png`; `--legacy` uses separate `aod-legacy-*` files.
SDK reference: `doc/docs/Connect_IQ_FAQ/How_Do_I_Make_a_Watch_Face_for_AMOLED_Products.html`.

## Owner-reported heat/burn-test measurement

The owner reported **7.3% luminance** while testing the preceding pushed build
(`b219756`). This is below the documented 10% luminance budget, but the coding
host has not reproduced it. The exact display mode, sampled needle positions,
and complete accelerated protection result were not supplied. It is not
recorded as an overall AOD/burn-in pass. Smooth mode changes only active motion;
new fractional parked positions can still change the measured AOD result.

## Native build/runtime blocker

No signed updated app/test PRG is available on this coding host. An earlier
unsigned compiler preflight exited 101 because no private key was specified.
The coding agent has not accessed the owner's signing key; signing must be
performed by the owner using the README commands. Compilation of this revision,
Monkey C unit execution, native animation performance, peak heap/graphics-pool
usage and official AOD compliance remain **unverified**.

`test/NeedleMotionTest.mc` adds pure native tests for the seconds arc, cold
start, parking, wake, return, interruptions, live-target updates, rollover
during wake, deferred wake until high power, cancellation, and a no-op wake.
They never start an SDK Timer. The resource test now loads the new active/AOD
plates. All native tests remain pending a signed test build.

## Device/simulator acceptance checklist

1. Build app and test PRGs locally; run the Monkey C test suite and inspect its
   textual summary. Linux `monkeydo` may return nonzero even for passing tests.
2. With both new settings enabled, check the full day 01–31 and fixed 24-hour
   clock. At second 6/42/54 the needle should point to printed 1/7/9.
3. Watch 59→00: controlled return over approximately 350 ms, never a full spin.
   Enter AOD at several positions, including mid-movement: no needle changes
   across minute updates. Wake should catch up over approximately 500 ms.
4. Exercise a minute rollover during wake; live seconds ticking during wake;
   rapid sleep/wake, hide/show, display off, and disabling seconds mid-movement.
   No timer should start in low power or continue after hiding/completion.
   Cold start goes directly to current seconds, not an artificial rev from 0.
5. Enable diagnostics. Record `smooth`, `moving`, `needleAngle`, `plate`, draw
   time and observed heap. In smooth mode, the timer must continue while awake
   even when the short wake/return motor movement has ended. Disable smooth:
   it must stop after that movement and revert to one-second steps. Toggle it
   during wake/return and check that neither mode moves while asleep/hidden.
   Use the profiler for actual allocation/graphics peaks; stay below 128 KB.
6. Turn seconds off to test date-gauge mode; also turn Date gauge off for the
   hour/minutes/DD-MM layout. Turn instrument lighting off for original themes.
   Confirm background switches are instant and the needle remains foreground.
7. Run the device-specific SDK heat-map/accelerated protection tests. Record
   native luminance/coverage warnings, including several parked blade positions.
   Leave AOD disabled for normal use until those checks pass.
