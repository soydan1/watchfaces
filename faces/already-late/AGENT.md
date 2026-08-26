# Agent brief — Already Late watch face

You are working on a Garmin Connect IQ **watch face** in
`faces/already-late` of the `watchfaces` repo. Do not edit
`/home/agent/projects/coach` or `/home/agent/projects/hermes-face`
unless the user says so.

The dial is a black/orange joke face: crown at 12, “Who cares I’m already
late”, numerals scattered off the chapter ring. Same drawing for high
power and always-on. AOD only drops the seconds hand.

## Read first

1. `DESIGN.md` — constraints, AOD, color, memory
2. `docs/ASSETS.md` — PNG measurements
3. `reference/dial.png` and the four hand sprites
4. `source/LateFaceView.mc` — shared draw path already in place

## Non-negotiables

- This is `type="watchface"`. Heap is **128 KB**.
- **Never** add the raw `reference/*.png` as drawables. Palettize first.
  A 454×454 16bpp buffer is ~403 KB.
- High power and AOD share the black/orange drawing. Do not dim, invert,
  or restyle for AOD.
- AOD: no seconds hand; burn-in shift already in `drawFace`.
- Isolated git worktree / `agent/*` branches if you commit. Do not commit
  unless the user asks. Do not push to `main`.
- Do not publish this as “Rolex” on the Connect IQ Store.

## Current jobs (done)

- Palettized `dial.png` blit via `dc.drawBitmap` (graphics pool, not a
  fullscreen `BufferedBitmap`).
- Bitmap hour/minute/second/arbor with `drawBitmap2`. Pivots: 29 px from
  the bottom of hour and minute, 56 px from the bottom of seconds. Arbor
  last, centered, unrotated.

Do not add complications, settings, or extra bitmaps unless asked.

## Toolchain

```
cd faces/already-late

monkeyc -o bin/LateFace.prg -f monkey.jungle \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -w

monkeyc -o bin/LateFaceTest.prg -f "monkey.jungle;monkey.test.jungle" \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -t -w

monkeydo bin/LateFaceTest.prg d2mach2 -t
```

Linux `monkeydo` may exit 1 even when tests PASSED; trust the textual
summary. Simulator: `monkeydo bin/LateFace.prg d2mach2`. AOD: simulator
File → View Screen Heat Map.

SDK: `~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2`

## Verify

- Release build with `-w` is clean.
- `MemoryBudgetTest` still passes; heap stays under 128 KB.
- If you change drawing, run the simulator and compare to `reference/dial.png`.
- AOD drawing must be mostly black. If in doubt, drop the seconds hand
  (already required) and do not add ticks.

## Style

Match Slim Dial: Toybox imports, typed locals, no fullscreen buffers,
short factual comments for non-obvious constraints only.
