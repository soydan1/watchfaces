# Already Late

Connect IQ analog watch face for Garmin D2 Mach 2. Black field, orange
hands, scrambled hour numerals, crown, and the line “Who cares I’m
already late”. Same drawing in high power and always-on; AOD only drops
the seconds hand.

This package is `type="watchface"` with a **128 KB** heap. Do not publish
it as “Rolex”.

Lives at `faces/already-late` in the `watchfaces` repo.

## Heap

| Type | Heap |
|---|---|
| watch-app (Strength Coach) | 768 KB |
| **watch-face (this)** | **128 KB** |

A 454×454 16bpp bitmap is ~403 KB. `dial.png` is imported as a 4-color
palette into the graphics pool. See `DESIGN.md`.

## Toolchain

- Connect IQ SDK 9.2.0 at `~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2`
- Developer key: `~/GarminDeveloperKeys/developer_key`
- Target: `d2mach2` (API 5.2, round 454×454 AMOLED)

From this directory:

```
monkeyc -o bin/LateFace.prg -f monkey.jungle \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -w

monkeyc -o bin/LateFaceTest.prg -f "monkey.jungle;monkey.test.jungle" \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -t -w

monkeydo bin/LateFaceTest.prg d2mach2 -t
monkeydo bin/LateFace.prg d2mach2
```

In the simulator: File → View Screen Heat Map to test AOD burn-in.

## Current state

Palettized `dial.png` is the watch dial. Hour/minute pivot 29 px from the
bottom of the sprite, seconds 56 px, arbor drawn last at center. Preview
composites: `docs/preview/`.
