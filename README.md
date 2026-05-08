# Sean's Wallpaper Repository

A semi-curated collection of Desktop, Dual Monitor, Triple Monitor, and Mobile Wallpapers gathered over a long period of time from sources across the internet.

----

## Overview

This repository is an archival collection of desktop wallpapers gathered from all over the internet over years and years... My goal is to preserve and share a broad set of high-quality backgrounds for personal use and enjoyment (and easy downloading to some of my own devices).

## Contents

- Organized into folders by layout and theme (e.g., `desktop/`, `dual/`, `mobile/`, `triple/`).
- Each subfolder contains themed collections (art, gaming, sci-fi, space, pop culture, etc.).
- Images are provided as-is for use as desktop backgrounds on personal devices.

## Usage

- Browse [repository](https://github.com/seangalie/wallpapers) and download images for personal use or [visit seangalie.github.io/wallpapers](https://seangalie.github.io/wallpapers).
- Use as desktop backgrounds, lock screens, or in personal projects (no attribution required for private use).
- For public reuse, check the original creator's terms.

## Gallery Generation

This repository includes a Python-based static site generator that emits a
self-contained site under `docs/`, which is what GitHub Pages serves.

### Why a generated site

Original wallpapers are stored in Git LFS to keep clones reasonable. GitHub
Pages does not resolve LFS pointers, so the generator builds two non-LFS
preview tiers under `docs/` that Pages can serve as real bytes:

- `docs/thumbnails/` — small JPEGs (≤600 px on the long side) used in grids.
- `docs/medium/` — larger JPEGs (≤1920 px) opened when a thumbnail is clicked.

Each grid item also carries a small "Original" link that points at GitHub's
LFS-resolving CDN, so users who want the true full-resolution file get it
without the gallery itself paying the LFS bandwidth cost on every page view.

### Setup

The generator depends on [Pillow](https://pypi.org/project/Pillow/). The
project uses a local virtualenv:

```bash
python3 -m venv .venv
.venv/bin/pip install Pillow
```

The `.venv/` directory is gitignored.

### Running the generator

```bash
.venv/bin/python generate_gallery.py
```

That command:

- Generates thumbnail and medium JPEG previews for every wallpaper under
  `desktop/`, `dual/`, `mobile/`, `triple/`. Previews are skipped if their
  destination is newer than the source, so re-runs are fast.
- Removes orphaned previews whose source no longer exists.
- Writes `docs/index.html`, `docs/{library}/index.html`,
  `docs/{library}/{category}/index.html`, and `docs/gallery.css`.

To re-emit only HTML and CSS without rebuilding previews:

```bash
.venv/bin/python generate_gallery.py --no-previews
```

### Filename consistency check

You can run a filename audit:

```bash
.venv/bin/python generate_gallery.py --check-names
```

This check reports files with:

- missing/unsupported extensions,
- category prefix mismatches (example: `space_...` in `scifi/`),
- uppercase characters in filenames,
- known typo patterns (for example, a missing dot before `.png`).

## File Naming Convention

For consistency and easier indexing, image files should generally follow:

```text
{category}_{descriptive-slug}.{ext}
```

Examples:
- `space_nebula-orion.jpg`
- `scifi_neon-city-window.jpg`
- `outdoors_mountain-lake-vista.png`

Using lowercase and hyphenated slugs keeps sorting and generated labels predictable.

## Copyright & Intellectual Property

- Copyright and intellectual property rights in individual images remain with their respective creators and rights holders.
- These wallpapers were sourced from across the internet and are shared here without conditions by the collector. Sharing or redistributing an image does not transfer ownership or grant additional rights.
- If you are the rights holder of an image in this repository and request removal or wish to provide attribution guidance, please [open an issue](https://github.com/seangalie/wallpapers/issues/new) describing the image and your request.

## Contributions & Contact

- Contributions (organized additions, cleanups, or new wallpaper sets) are welcome via pull request.
- For copyright or takedown requests, open an issue or contact the repository owner with details.

## Disclaimer

- The repository owner is not asserting ownership over the images and is not responsible for their provenance.
- Images are provided for convenience and personal use; ensure any public or commercial use complies with the original rights holder's terms.
