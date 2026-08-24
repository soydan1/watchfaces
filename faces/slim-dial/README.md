# Slim Dial

Connect IQ analog watch face for Garmin D2 Mach 2. Stroke-drawn from the
dials in `reference/`. App name is **Slim Dial**.

High-power draws `hermesbg.png` plus `hour.png` / `minute.png` /
`second.png`. Always-on draws `hermesDark.png` plus `hourDark.png` /
`minuteDark.png` (no seconds), shifted 1 px for AMOLED burn-in. Hubs
are the bottom circle of each hand sprite.

## Build

```
cd faces/slim-dial

monkeyc -o bin/SlimDial.prg -f monkey.jungle \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -w

monkeyc -o bin/SlimDialTest.prg -f "monkey.jungle;monkey.test.jungle" \
  -y ~/GarminDeveloperKeys/developer_key -d d2mach2 -t -w

monkeydo bin/SlimDialTest.prg d2mach2 -t
monkeydo bin/SlimDial.prg d2mach2
```

Sideload: copy `bin/SlimDial.prg` to `GARMIN/APPS/` on the watch, then
pick Slim Dial in the watch-face picker.

Always-on: simulator File → View Screen Heat Map. AOD draws outline
12 / 3 / 9 only on black.
