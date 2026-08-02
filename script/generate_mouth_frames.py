#!/usr/bin/env python3
"""Build lip-sync frames for ALTEA from her portrait.

No new artwork is invented: each frame warps the mouth of
app/assets/images/altea/avatar.png the way a real one moves.

Three things make it read as a mouth rather than a stretched photo:

  * the jaw swings. Displacement grows with the distance below the pivot
    (roughly ear level), so the chin travels further than the lower lip.
  * the corners stay put. The lip field is narrow, anchored just inside the
    commissures — a mouth opens in the middle, it does not slide sideways.
  * the opening is shaded, and the upper lip lifts by about a third of the
    lower one, which is the real ratio.

Frames are full-canvas and transparent outside the mouth, so stacking them on
the portrait with identical CSS keeps them registered to the pixel. Colour is
zeroed under the transparency: PNG stores RGB regardless of alpha, and leaving
the portrait in there costs ~300 Ko a frame instead of 16.

Run: python3 script/generate_mouth_frames.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "app/assets/images/altea/avatar.png"
OUT_DIR = ROOT / "app/assets/images/altea/mouth"

# measured on the portrait
LIP_X, LIP_Y = 211.0, 306.0
MOUTH_HALF = 30.0        # lips run from x = 181 to x = 241
JAW_PIVOT_Y = LIP_Y - 78 # roughly ear level: the jaw rotates about here

REACH_X = 62.0           # how wide the jaw field spreads
REACH_DOWN = 66.0        # lower lip, chin, and a little of the throat
REACH_UP = 22.0          # philtrum only

# (opening in px, pinch in px) — negative pinch widens, as in "i" or a smile
FRAMES = [
    (1.5, -0.4),   # lips barely parted        m, b, p
    (3.0, -1.0),   # thin and wide             i, é
    (4.5, -0.2),   # neutral                   e
    (6.5,  1.0),   # starting to round         è, a short
    (8.5,  2.2),   # rounded                   o
    (10.5, 3.2),   # tight and rounded         ou
    (12.5, 1.4),   # open, still shaped        an, on
    (15.0, 0.2),   # wide open                 a
]


def smoothstep(edge):
    """1 at the centre, 0 past the edge, with no visible seam."""
    t = np.clip(edge, 0, 1)
    return 1 - (t * t * (3 - 2 * t))


def fields(xx, yy):
    """Two displacement weights: the swinging jaw, and the lips themselves."""
    below = yy >= LIP_Y

    # --- jaw: wide, and stronger the further below the pivot ---------------
    jaw_x = smoothstep(np.abs(xx - LIP_X) / REACH_X)
    jaw_y = smoothstep(np.clip(yy - LIP_Y, 0, None) / REACH_DOWN)
    lever = np.clip((yy - JAW_PIVOT_Y) / (LIP_Y + REACH_DOWN - JAW_PIVOT_Y), 0, 1.35)
    jaw = np.where(below, jaw_x * jaw_y * lever, 0.0)

    # --- lips: narrow, anchored just inside the corners --------------------
    lip_x = smoothstep(np.abs(xx - LIP_X) / (MOUTH_HALF * 0.92))
    span = np.where(below, 26.0, REACH_UP)
    lip_y = smoothstep(np.abs(yy - LIP_Y) / span)
    lip = lip_x * lip_y

    return jaw, lip


def sample(pixels, sx, sy):
    """Bilinear sample of an (h, w, 4) array at float coordinates."""
    h, w = pixels.shape[:2]
    sx = np.clip(sx, 0, w - 1.001)
    sy = np.clip(sy, 0, h - 1.001)

    x0 = np.floor(sx).astype(np.int32)
    y0 = np.floor(sy).astype(np.int32)
    fx = (sx - x0)[..., None]
    fy = (sy - y0)[..., None]

    top = pixels[y0, x0] * (1 - fx) + pixels[y0, x0 + 1] * fx
    bottom = pixels[y0 + 1, x0] * (1 - fx) + pixels[y0 + 1, x0 + 1] * fx
    return top * (1 - fy) + bottom * fy


def build(pixels, opening, pinch):
    h, w = pixels.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    jaw, lip = fields(xx, yy)
    below = yy >= LIP_Y

    # the lower lip rides the jaw; the upper lip lifts about a third as far
    shift_y = jaw * opening * 0.72 + np.where(below, lip * opening * 0.42, -lip * opening * 0.34)

    # rounding pulls the corners in; a negative pinch spreads them
    corner = np.clip(np.abs(xx - LIP_X) / MOUTH_HALF, 0, 1.4)
    shift_x = -np.sign(xx - LIP_X) * pinch * lip * corner

    warped = sample(pixels, xx - shift_x, yy - shift_y)

    # the opening itself, sitting between the parted lips
    gap_ry = max(opening * 0.55, 0.9)
    gap_rx = max(MOUTH_HALF * 0.82 - pinch * 3.4, 7.0)
    gd = np.sqrt(((xx - LIP_X) / gap_rx) ** 2 + ((yy - (LIP_Y + opening * 0.22)) / gap_ry) ** 2)
    gap = np.clip(1 - gd, 0, 1) ** 0.65
    shade = (gap * min(0.85, 0.26 + opening * 0.045))[..., None]
    warped[..., :3] *= 1 - shade * 0.9

    # keep only what moved, fading out so the seam is invisible
    touched = np.clip((jaw * 0.85 + lip) * 1.6, 0, 1)
    warped[..., 3] *= touched

    invisible = warped[..., 3] < 1
    warped[invisible, :3] = 0

    return np.clip(warped, 0, 255).astype(np.uint8)


def main():
    source = Image.open(SOURCE).convert("RGBA")
    pixels = np.asarray(source).astype(np.float32)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for old in OUT_DIR.glob("*.png"):
        old.unlink()

    for index, (opening, pinch) in enumerate(FRAMES, start=1):
        frame = Image.fromarray(build(pixels.copy(), opening, pinch), "RGBA")
        path = OUT_DIR / f"{index}.png"
        frame.save(path, optimize=True)
        print(f"{path.relative_to(ROOT)}  ouverture {opening:>5} px  pincement {pinch:>5} px  "
              f"{path.stat().st_size // 1024} Ko")

    print(f"\n{len(FRAMES)} images — pensez à AlteaMouth::FRAME_COUNT si ce nombre change.")


if __name__ == "__main__":
    main()
