"""Generates the procedural textures the examples use.

Run with `pixi run assets`. Existing files are left alone unless --force is given.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

TEXTURES = Path(__file__).parent / "textures"
SIZE = 512
SKYBOX_SIZE = 512


def value_noise(shape: tuple[int, int], cells: int, rng: np.random.Generator) -> np.ndarray:
    """Smooth noise in [0, 1], built by upsampling a small lattice bilinearly."""
    lattice = rng.random((cells + 1, cells + 1))
    ys = np.linspace(0, cells, shape[0], endpoint=False)
    xs = np.linspace(0, cells, shape[1], endpoint=False)
    y0, x0 = ys.astype(int), xs.astype(int)
    fy, fx = (ys - y0)[:, None], (xs - x0)[None, :]
    # Smoothstep keeps the lattice from showing through as diamonds.
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)

    top = lattice[y0][:, x0] * (1 - fx) + lattice[y0][:, x0 + 1] * fx
    bottom = lattice[y0 + 1][:, x0] * (1 - fx) + lattice[y0 + 1][:, x0 + 1] * fx
    return top * (1 - fy) + bottom * fy


def fractal_noise(shape: tuple[int, int], octaves: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    total = np.zeros(shape)
    amplitude, weight = 1.0, 0.0
    for octave in range(octaves):
        total += value_noise(shape, 2 * 2**octave, rng) * amplitude
        weight += amplitude
        amplitude *= 0.5
    return total / weight


def ramp(values: np.ndarray, stops: list[tuple[float, tuple[int, int, int]]]) -> np.ndarray:
    """Maps [0, 1] through a colour ramp given as (position, rgb) stops."""
    positions = np.array([stop[0] for stop in stops])
    colours = np.array([stop[1] for stop in stops], dtype=float)
    out = np.empty(values.shape + (3,))
    for channel in range(3):
        out[..., channel] = np.interp(values, positions, colours[:, channel])
    return out


def save(name: str, rgb: np.ndarray) -> None:
    image = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), mode="RGB")
    image.save(TEXTURES / name)
    print("wrote", TEXTURES / name)


def rocky_planet(name: str, seed: int, stops: list[tuple[float, tuple[int, int, int]]]) -> None:
    height = fractal_noise((SIZE, SIZE * 2), octaves=6, seed=seed)
    save(name, ramp(height, stops))


def gas_giant(name: str, seed: int) -> None:
    shape = (SIZE, SIZE * 2)
    turbulence = fractal_noise(shape, octaves=5, seed=seed)
    bands = np.sin(np.linspace(0, 22 * np.pi, shape[0]))[:, None] + turbulence * 1.6
    normalised = (bands - bands.min()) / np.ptp(bands)
    save(
        name,
        ramp(
            normalised,
            [
                (0.0, (108, 70, 44)),
                (0.35, (196, 150, 96)),
                (0.55, (232, 208, 168)),
                (0.75, (176, 122, 74)),
                (1.0, (238, 226, 200)),
            ],
        ),
    )


def sun(name: str, seed: int) -> None:
    granulation = fractal_noise((SIZE, SIZE * 2), octaves=6, seed=seed)
    save(
        name,
        ramp(
            granulation,
            [(0.0, (188, 62, 12)), (0.5, (250, 158, 30)), (0.8, (255, 214, 110)), (1.0, (255, 252, 226))],
        ),
    )


def grid(name: str) -> None:
    """A dark grid, so the wave surface reads as a surface."""
    coords = np.arange(SIZE)
    lines = np.minimum(coords % 64, 63 - (coords % 64))
    mask = np.minimum(lines[:, None], lines[None, :]) < 2
    rgb = np.full((SIZE, SIZE, 3), (14, 20, 34), dtype=float)
    rgb[mask] = (60, 190, 210)
    save(name, rgb)


def white(name: str) -> None:
    save(name, np.full((4, 4, 3), 255.0))


def starfield(name: str, seed: int, density: float = 0.00035) -> None:
    # Deep space stays black: any nebula would show a seam at each cube-map edge.
    rng = np.random.default_rng(seed)
    rgb = np.zeros((SKYBOX_SIZE, SKYBOX_SIZE, 3))

    count = int(SKYBOX_SIZE * SKYBOX_SIZE * density)
    ys = rng.integers(1, SKYBOX_SIZE - 1, count)
    xs = rng.integers(1, SKYBOX_SIZE - 1, count)
    brightness = rng.random(count) ** 2.2
    tint = np.stack([1 - brightness * 0.15, np.ones(count), 0.75 + brightness * 0.25], axis=1)
    for y, x, level, colour in zip(ys, xs, brightness, tint):
        rgb[y, x] += 255 * level * colour
        # A faint cross keeps the brighter stars from vanishing at a distance.
        if level > 0.75:
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                rgb[y + dy, x + dx] += 90 * level * colour
    save(name, rgb)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true", help="regenerate files that already exist")
    force = parser.parse_args().force

    TEXTURES.mkdir(parents=True, exist_ok=True)
    jobs: list[tuple[str, object]] = [
        ("sun.png", lambda name: sun(name, seed=1)),
        (
            "planet_terra.png",
            lambda name: rocky_planet(
                name,
                seed=2,
                stops=[
                    (0.0, (12, 34, 96)),
                    (0.45, (24, 78, 150)),
                    (0.5, (208, 194, 142)),
                    (0.62, (46, 116, 54)),
                    (0.82, (96, 84, 62)),
                    (1.0, (244, 248, 252)),
                ],
            ),
        ),
        (
            "planet_ember.png",
            lambda name: rocky_planet(
                name,
                seed=7,
                stops=[
                    (0.0, (48, 16, 12)),
                    (0.4, (128, 46, 28)),
                    (0.7, (196, 92, 44)),
                    (1.0, (240, 176, 120)),
                ],
            ),
        ),
        ("planet_wisp.png", lambda name: gas_giant(name, seed=11)),
        (
            "moon.png",
            lambda name: rocky_planet(
                name,
                seed=23,
                stops=[(0.0, (58, 58, 64)), (0.55, (128, 128, 136)), (1.0, (206, 206, 212))],
            ),
        ),
        ("grid.png", grid),
        ("white.png", white),
    ]
    for face in range(6):
        jobs.append((f"stars_{face}.png", lambda name, face=face: starfield(name, seed=100 + face)))

    for name, build in jobs:
        if force or not (TEXTURES / name).exists():
            build(name)
        else:
            print("skipping", name, "(already exists)")


if __name__ == "__main__":
    main()
