# Sean's Wallpaper Repository
A semi-curated collection of Desktop, Dual Monitor, Triple Monitor, and Mobile Wallpapers gathered over a long period of time from sources across the internet.

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
This repository includes a Python-based static site generator:

```bash
python3 generate_gallery.py
```

That command regenerates:
- `index.html` (root landing page)
- `{library}/index.html` (library category pages)
- `{library}/{category}/index.html` (image gallery pages)
- `gallery.css` (shared stylesheet)

### Filename consistency check
You can run a filename audit before regenerating pages:

```bash
python3 generate_gallery.py --check-names
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
