#!/usr/bin/env python3
"""Composite reference sprites the same way LateFaceView rotates them."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "reference"
OUT = ROOT / "docs" / "preview"

HOUR_PIVOT = (9, 158 - 29)
MINUTE_PIVOT = (5, 187 - 29)
SECOND_PIVOT = (9, 241 - 56)
ARBOR_PIVOT = (18, 18)
CX = 227
CY = 227


def hour_angle(hour: int, minute: int) -> float:
    hours12 = hour % 12
    turns = ((hours12 * 60) + minute) / (12.0 * 60.0)
    return turns * math.pi * 2.0


def minute_angle(minute: int) -> float:
    return (minute / 60.0) * math.pi * 2.0


def second_angle(second: int) -> float:
    return (second / 60.0) * math.pi * 2.0


def blit_hand(
    dst: Image.Image,
    src: Image.Image,
    cx: int,
    cy: int,
    angle: float,
    pivot: tuple[int, int],
) -> None:
    # Same matrix as Graphics.AffineTransform used in LateFaceView.drawHand:
    # dest = R * (src - pivot) + center, FILTER_MODE_POINT.
    px, py = pivot
    cos = math.cos(angle)
    sin = math.sin(angle)
    a = cos
    b = sin
    c = -cx * cos - cy * sin + px
    d = -sin
    e = cos
    f = cx * sin - cy * cos + py
    layer = src.transform(
        dst.size,
        Image.AFFINE,
        (a, b, c, d, e, f),
        resample=Image.NEAREST,
    )
    dst.alpha_composite(layer)


def render(hour: int, minute: int, second: int | None, debug: bool = False) -> Image.Image:
    dial = Image.open(REF / "dial.png").convert("RGBA")
    hour_s = Image.open(REF / "hour.png").convert("RGBA")
    minute_s = Image.open(REF / "minute.png").convert("RGBA")
    second_s = Image.open(REF / "second.png").convert("RGBA")
    arbor = Image.open(REF / "arbor.png").convert("RGBA")

    face = Image.new("RGBA", (454, 454), (0, 0, 0, 255))
    face.alpha_composite(dial)

    blit_hand(face, hour_s, CX, CY, hour_angle(hour, minute), HOUR_PIVOT)
    blit_hand(face, minute_s, CX, CY, minute_angle(minute), MINUTE_PIVOT)
    if second is not None:
        blit_hand(face, second_s, CX, CY, second_angle(second), SECOND_PIVOT)

    face.alpha_composite(arbor, (CX - ARBOR_PIVOT[0], CY - ARBOR_PIVOT[1]))

    if debug:
        draw = ImageDraw.Draw(face)
        draw.line([(CX - 12, CY), (CX + 12, CY)], fill=(0, 255, 80, 255), width=1)
        draw.line([(CX, CY - 12), (CX, CY + 12)], fill=(0, 255, 80, 255), width=1)
        draw.ellipse((CX - 2, CY - 2, CX + 2, CY + 2), outline=(0, 255, 80, 255))

    return face


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    shots = {
        "high-101030.png": render(10, 10, 30),
        "aod-1010.png": render(10, 10, None),
        "noon.png": render(12, 0, 0),
        "three.png": render(3, 0, 0),
        "center-debug.png": render(10, 10, 30, debug=True),
    }
    for name, im in shots.items():
        path = OUT / name
        im.save(path)
        print("wrote", path)

    crop = shots["center-debug.png"].crop((227 - 60, 227 - 60, 227 + 60, 227 + 60))
    crop = crop.resize((360, 360), Image.NEAREST)
    crop.save(OUT / "center-crop.png")
    print("wrote", OUT / "center-crop.png")


if __name__ == "__main__":
    main()
