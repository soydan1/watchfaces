# watchfaces

Personal Garmin Connect IQ watch faces. Each face is its own `watchface`
app (own `manifest.xml` and application id).

Heap on D2 Mach 2 watch faces is **128 KB**. Do not compile unpalettized
454×454 RGBA photos onto the app heap.

## Faces

| Dir | App name | Notes |
|---|---|---|
| `faces/already-late` | Already Late | Black/orange joke dial. Same drawing for AOD; drop seconds. |

Do not publish Already Late as “Rolex”.

## Toolchain

- Connect IQ SDK 9.2.0
- Developer key: `~/GarminDeveloperKeys/developer_key`
- Target: `d2mach2` (API 5.2, 454×454 AMOLED)

```
cd faces/already-late

monkeyc -o bin/LateFace.prg -f monkey.jungle \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -w

monkeyc -o bin/LateFaceTest.prg -f "monkey.jungle;monkey.test.jungle" \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -t -w

monkeydo bin/LateFaceTest.prg d2mach2 -t
monkeydo bin/LateFace.prg d2mach2
```

Linux `monkeydo` may exit 1 even when tests PASSED; trust the textual summary.

## Sideload to a D2 Mach 2

1. Build `bin/LateFace.prg` as above.
2. Connect the watch over USB (mass storage / Garmin drive).
3. Copy `LateFace.prg` to `GARMIN/APPS/` on the watch.
4. Eject, then pick **Already Late** in the watch-face picker.
