# watchfaces

Personal Garmin Connect IQ watch faces. Each face is its own `watchface`
app (own `manifest.xml` and application id). Analog math that every dial
needs lives in `shared/` and is pulled in by Jungle `sourcePath`.

This is not a Connect IQ barrel yet. Jungle shared source is enough while
every face lives in this repo. Extract a barrel later if a face needs to
live in a separate package.

```
watchfaces/
  shared/source/AnalogGeometry.mc   # angles, hand polygons, AOD burn-in
  faces/slim-dial/                  # first face
```

Heap on D2 Mach 2 watch faces is **128 KB**. Do not compile reference
photos into a PRG.

## Toolchain

Same SDK as Strength Coach:

- Connect IQ SDK 9.2.0
- Developer key: `~/GarminDeveloperKeys/developer_key`
- Target: `d2mach2` (API 5.2, 454×454 AMOLED)

```
cd faces/slim-dial

monkeyc -o bin/SlimDial.prg -f monkey.jungle \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -w

monkeyc -o bin/SlimDialTest.prg -f "monkey.jungle;monkey.test.jungle" \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -t -w

monkeydo bin/SlimDialTest.prg d2mach2 -t
monkeydo bin/SlimDial.prg d2mach2
```

Linux `monkeydo` may exit 1 even when tests PASSED; trust the textual summary.

## Sideload to a D2 Mach 2

1. Build `bin/SlimDial.prg` as above.
2. Connect the watch over USB (mass storage / Garmin drive).
3. Copy `SlimDial.prg` to `GARMIN/APPS/` on the watch.
4. Eject, then pick **Slim Dial** in the watch-face picker.

Or, with the watch in debug mode and the SDK device manager seeing it:

```
monkeydo bin/SlimDial.prg d2mach2
```

## Add another face

1. Copy `faces/slim-dial` to `faces/<name>` (or start empty).
2. Generate a new application id in `manifest.xml`. Garmin will reject two
   faces that share an id.
3. Keep `base.sourcePath = source;../../shared/source` in that face's
   `monkey.jungle`.
4. Put layout ratios and drawing in the new face. Use `AnalogGeometry`
   for angles, `handPolygon`, and AOD `burnInShift`.
5. Do not put face-specific numerals or colors in `shared/`.

## Faces

| Dir | App name | Notes |
|---|---|---|
| `faces/slim-dial` | Slim Dial | Stroke-drawn analog, AOD outline 12/3/9 |
