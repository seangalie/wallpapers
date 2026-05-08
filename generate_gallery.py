#!/usr/bin/env python3
"""Generate a static HTML gallery for the wallpapers repository.

Run from the repository root (use the project venv so Pillow is available):
    .venv/bin/python generate_gallery.py

Outputs everything under ./docs/ — the GitHub Pages serving root:

    docs/index.html                       — landing page
    docs/gallery.css                      — shared stylesheet
    docs/{lib}/index.html                 — per-library category menu
    docs/{lib}/{cat}/index.html           — per-category image grid
    docs/thumbnails/{lib}/{cat}/*.jpg     — small previews used in grids
    docs/medium/{lib}/{cat}/*.jpg         — medium previews opened on click

The original wallpapers stay in /{lib}/{cat}/ and remain Git-LFS-tracked.
The download-original links bypass Pages and hit GitHub's LFS-resolving CDN.
"""

import argparse
import html
import sys
from pathlib import Path

try:
    from PIL import Image, ImageOps
except ImportError:
    sys.exit(
        "Pillow is required. Install it into the project venv:\n"
        "    python3 -m venv .venv && .venv/bin/pip install Pillow\n"
        "Then run:\n"
        "    .venv/bin/python generate_gallery.py"
    )

BASE = Path(__file__).parent
OUT = BASE / "docs"
THUMB_DIR = OUT / "thumbnails"
MEDIUM_DIR = OUT / "medium"

LIBS = ["desktop", "dual", "mobile", "triple"]

REPO = "seangalie/wallpapers"
BRANCH = "main"
ORIGINAL_URL = f"https://media.githubusercontent.com/media/{REPO}/{BRANCH}"

THUMB_LONG = 600
MEDIUM_LONG = 1920
JPEG_QUALITY_THUMB = 80
JPEG_QUALITY_MEDIUM = 82
FLATTEN_BG = (13, 13, 13)

LIB_LABELS = {
    "desktop": "Desktop",
    "dual": "Dual Monitor",
    "mobile": "Mobile",
    "triple": "Triple Monitor",
}

LIB_DESC = {
    "desktop": "Single-monitor wallpapers",
    "dual": "Panoramic wallpapers spanning two monitors",
    "mobile": "Portrait wallpapers for phones and tablets",
    "triple": "Ultra-wide wallpapers spanning three monitors",
}

LIB_ICON = {
    "desktop": "🖥",
    "dual": "🖥🖥",
    "mobile": "📱",
    "triple": "🖥🖥🖥",
}

CAT_LABELS = {
    "art": "Art",
    "cars": "Cars",
    "fantasy": "Fantasy",
    "gaming": "Gaming",
    "history": "History",
    "local": "Local",
    "minimal": "Minimal",
    "music": "Music",
    "outdoors": "Outdoors",
    "popculture": "Pop Culture",
    "science": "Science",
    "scifi": "Sci-Fi",
    "space": "Space",
    "startrek": "Star Trek",
    "starwars": "Star Wars",
    "tech": "Tech",
    "urban": "Urban",
}

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}

CSS = """\
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg: #0d0d0d;
  --surface: #161616;
  --surface2: #1e1e1e;
  --border: #262626;
  --text: #e2e2e2;
  --muted: #666;
  --muted2: #888;
  --accent: #7aa2f7;
}

body {
  background: var(--bg);
  color: var(--text);
  font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
  min-height: 100vh;
  line-height: 1.5;
}

a { color: inherit; text-decoration: none; }

/* ── Header ── */
.site-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: .875rem 2rem;
  border-bottom: 1px solid var(--border);
  position: sticky;
  top: 0;
  background: rgba(13,13,13,.9);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  z-index: 100;
}

.logo {
  font-weight: 700;
  font-size: .95rem;
  color: var(--accent);
  white-space: nowrap;
  flex-shrink: 0;
}
.logo:hover { opacity: .8; }

.breadcrumb {
  display: flex;
  align-items: center;
  gap: .35rem;
  font-size: .82rem;
  color: var(--muted);
  flex-wrap: wrap;
  overflow: hidden;
}
.breadcrumb a { color: var(--muted); transition: color .15s; }
.breadcrumb a:hover { color: var(--text); }
.breadcrumb .cur { color: var(--muted2); }
.breadcrumb .sep { opacity: .35; user-select: none; }

/* ── Main ── */
main { max-width: 1440px; margin: 0 auto; padding: 2.5rem 2rem 5rem; }

/* ── Hero (index only) ── */
.hero {
  text-align: center;
  padding: 5rem 1rem 4rem;
}

.hero h2 {
  font-size: clamp(2rem, 5vw, 3.25rem);
  font-weight: 800;
  letter-spacing: -.03em;
  margin-bottom: 1rem;
  background: linear-gradient(135deg, #e2e2e2 30%, #7aa2f7);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero p {
  color: var(--muted2);
  font-size: 1.05rem;
  max-width: 560px;
  margin: 0 auto 2.5rem;
  line-height: 1.85;
}

.hero-stats {
  display: flex;
  justify-content: center;
  gap: 2.5rem;
  flex-wrap: wrap;
  font-size: .85rem;
  color: var(--muted);
  padding: 1.5rem 2rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  width: fit-content;
  margin: 0 auto 3rem;
}
.hero-stats strong { display: block; font-size: 1.5rem; font-weight: 700; color: var(--text); margin-bottom: .15rem; }

.hero-note {
  font-size: .8rem;
  color: var(--muted);
  max-width: 560px;
  margin: 0 auto;
  line-height: 1.7;
}
.hero-note a { color: var(--accent); }

/* ── Section header ── */
.section-head { margin-bottom: 1.75rem; }
.section-head h2 { font-size: 1.5rem; font-weight: 700; }
.section-head p { color: var(--muted2); font-size: .875rem; margin-top: .3rem; }

/* ── Library cards ── */
.lib-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.25rem;
  margin-top: 2rem;
}

.lib-card {
  display: block;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
  transition: border-color .2s, transform .2s;
}
.lib-card:hover { border-color: var(--accent); transform: translateY(-3px); }

.lib-card .thumb { height: 175px; overflow: hidden; background: var(--surface2); }
.lib-card .thumb img { width: 100%; height: 100%; object-fit: cover; transition: transform .5s; display: block; }
.lib-card:hover .thumb img { transform: scale(1.07); }

.lib-card .body { padding: 1.25rem 1.4rem; }
.lib-card .body .icon { font-size: 1.4rem; margin-bottom: .5rem; }
.lib-card .body h3 { font-size: 1.1rem; font-weight: 700; margin-bottom: .35rem; }
.lib-card .body p { color: var(--muted2); font-size: .82rem; line-height: 1.6; }
.lib-card .body .meta { margin-top: .9rem; font-size: .78rem; color: var(--accent); }

/* ── Category cards ── */
.cat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
  gap: 1rem;
  margin-top: 2rem;
}

.cat-card {
  display: block;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 11px;
  overflow: hidden;
  transition: border-color .2s, transform .2s;
}
.cat-card:hover { border-color: var(--accent); transform: translateY(-2px); }

.cat-card .thumb { height: 115px; overflow: hidden; background: var(--surface2); }
.cat-card .thumb img { width: 100%; height: 100%; object-fit: cover; transition: transform .4s; display: block; }
.cat-card:hover .thumb img { transform: scale(1.07); }

.cat-card .label { padding: .8rem 1rem; }
.cat-card .label h4 { font-size: .9rem; font-weight: 600; }
.cat-card .label span { font-size: .75rem; color: var(--muted2); }

/* ── Image grid ── */
.img-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: .75rem;
  margin-top: 1.75rem;
}

.img-item {
  background: var(--surface2);
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--border);
  transition: border-color .2s;
}
.img-item:hover { border-color: #444; }
.img-item > a { display: block; }
.img-item img { display: block; width: 100%; height: 175px; object-fit: cover; transition: transform .3s; }
.img-item:hover img { transform: scale(1.04); }

.img-item .meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: .5rem;
  padding: .4rem .65rem;
}
.img-item .name {
  font-size: .68rem;
  color: var(--muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1 1 auto;
  min-width: 0;
}
.img-item .orig {
  font-size: .68rem;
  color: var(--accent);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: .15rem .45rem;
  flex-shrink: 0;
  transition: border-color .15s, color .15s;
}
.img-item .orig:hover { border-color: var(--accent); color: var(--text); }

/* ── Footer ── */
footer {
  border-top: 1px solid var(--border);
  padding: 2rem;
  text-align: center;
  color: var(--muted);
  font-size: .82rem;
  margin-top: 5rem;
}
footer a { color: var(--muted); text-decoration: underline; text-underline-offset: 3px; }
footer a:hover { color: var(--text); }

/* ── Responsive ── */
@media (max-width: 600px) {
  main { padding: 1.5rem 1rem 3rem; }
  .site-header { padding: .75rem 1rem; }
  .hero { padding: 3rem .5rem 2.5rem; }
  .img-grid { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); }
  .img-item img { height: 110px; }
}
"""


# ── Filesystem helpers ───────────────────────────────────────────────────────

def get_images(lib: str, cat: str) -> list[str]:
    folder = BASE / lib / cat
    if not folder.is_dir():
        return []
    return sorted(
        f.name for f in folder.iterdir()
        if f.is_file() and f.suffix.lower() in IMAGE_EXTS
    )


def get_cats(lib: str) -> list[str]:
    folder = BASE / lib
    if not folder.is_dir():
        return []
    return sorted(d.name for d in folder.iterdir() if d.is_dir())


def first_image(lib: str, cat: str) -> str | None:
    imgs = get_images(lib, cat)
    return imgs[0] if imgs else None


def largest_cat(lib: str) -> str | None:
    cats = get_cats(lib)
    return max(cats, key=lambda c: len(get_images(lib, c)), default=None)


def pretty_name(filename: str) -> str:
    """art_abstract-boxes.jpg → Abstract Boxes"""
    stem = filename.rsplit(".", 1)[0]
    stem = stem.split("_", 1)[-1]
    return stem.replace("-", " ").replace("_", " ").title()


def thumb_name(filename: str) -> str:
    """Map a source filename to its preview filename (always JPEG).

    JPEG sources keep their stem; other formats include the source extension
    in the stem so that two sources differing only by extension (e.g.
    `foo.jpg` and `foo.png` in the same folder) don't collide on the same
    preview file.
    """
    p = Path(filename)
    suffix = p.suffix.lower()
    if suffix in (".jpg", ".jpeg"):
        return p.stem + ".jpg"
    return f"{p.stem}-{suffix.lstrip('.')}.jpg"


def rel(depth: int, *parts: str) -> str:
    """Build a relative URL from a doc page at the given depth."""
    return "../" * depth + "/".join(parts)


def original_url(lib: str, cat: str, name: str) -> str:
    return f"{ORIGINAL_URL}/{lib}/{cat}/{name}"


# ── Preview generation ──────────────────────────────────────────────────────

def _resize(src: Path, dest: Path, long_edge: int, quality: int) -> bool:
    """Write a JPEG preview at most `long_edge` px on the longer side.

    Returns True if a new file was written, False if up-to-date.
    """
    if dest.exists() and dest.stat().st_mtime >= src.stat().st_mtime:
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)
        im.thumbnail((long_edge, long_edge), Image.Resampling.LANCZOS)
        if im.mode in ("RGBA", "LA") or (im.mode == "P" and "transparency" in im.info):
            bg = Image.new("RGB", im.size, FLATTEN_BG)
            bg.paste(im.convert("RGBA"), mask=im.convert("RGBA").split()[-1])
            im = bg
        elif im.mode != "RGB":
            im = im.convert("RGB")
        im.save(dest, "JPEG", quality=quality, optimize=True, progressive=True)
    return True


def expected_previews() -> dict[Path, Path]:
    """Return a mapping of every expected preview path → its source path."""
    expected: dict[Path, Path] = {}
    for lib in LIBS:
        for cat in get_cats(lib):
            for name in get_images(lib, cat):
                src = BASE / lib / cat / name
                tn = thumb_name(name)
                expected[THUMB_DIR / lib / cat / tn] = src
                expected[MEDIUM_DIR / lib / cat / tn] = src
    return expected


def detect_collisions() -> list[str]:
    """Detect source filenames that would map to the same preview filename."""
    issues: list[str] = []
    for lib in LIBS:
        for cat in get_cats(lib):
            seen: dict[str, str] = {}
            for name in get_images(lib, cat):
                tn = thumb_name(name)
                if tn in seen:
                    issues.append(
                        f"{lib}/{cat}/{name} and {lib}/{cat}/{seen[tn]} "
                        f"both map to preview '{tn}' — rename one"
                    )
                else:
                    seen[tn] = name
    return issues


def cleanup_orphans(expected: dict[Path, Path]) -> int:
    """Remove preview files that no longer correspond to any source."""
    removed = 0
    for root in (THUMB_DIR, MEDIUM_DIR):
        if not root.exists():
            continue
        for path in root.rglob("*.jpg"):
            if path not in expected:
                path.unlink()
                removed += 1
        for d in sorted(
            (p for p in root.rglob("*") if p.is_dir()),
            key=lambda p: len(p.parts),
            reverse=True,
        ):
            try:
                d.rmdir()
            except OSError:
                pass
    return removed


def build_previews() -> tuple[int, int, int, int]:
    """Generate thumbnail and medium previews for every original.

    Returns (built, skipped, failed, cleaned).
    """
    collisions = detect_collisions()
    if collisions:
        print("  ERROR  preview-name collisions:", file=sys.stderr)
        for c in collisions:
            print(f"         {c}", file=sys.stderr)
        sys.exit(1)

    expected = expected_previews()
    cleaned = cleanup_orphans(expected)
    if cleaned:
        print(f"  clean  removed {cleaned} orphaned preview file(s)")

    built = skipped = failed = 0
    total = len(expected) // 2
    print(f"  scan   {total} originals")

    i = 0
    for lib in LIBS:
        for cat in get_cats(lib):
            for name in get_images(lib, cat):
                i += 1
                src = BASE / lib / cat / name
                t_dest = THUMB_DIR / lib / cat / thumb_name(name)
                m_dest = MEDIUM_DIR / lib / cat / thumb_name(name)
                try:
                    a = _resize(src, t_dest, THUMB_LONG, JPEG_QUALITY_THUMB)
                    b = _resize(src, m_dest, MEDIUM_LONG, JPEG_QUALITY_MEDIUM)
                except Exception as e:
                    failed += 1
                    print(f"  FAIL   {lib}/{cat}/{name}: {e}", file=sys.stderr)
                    continue
                if a or b:
                    built += 1
                else:
                    skipped += 1
                if i % 100 == 0:
                    print(f"  ...    {i}/{total} processed (built={built}, skipped={skipped})")

    return built, skipped, failed, cleaned


# ── Filename validation ─────────────────────────────────────────────────────

def validate_filenames() -> list[tuple[str, str]]:
    """Return a list of filename issues with suggested fixes."""
    issues: list[tuple[str, str]] = []
    for lib in LIBS:
        for cat in get_cats(lib):
            folder = BASE / lib / cat
            for file in sorted(folder.iterdir()):
                if not file.is_file():
                    continue

                name = file.name
                relpath = file.relative_to(BASE).as_posix()
                lower_name = name.lower()

                if file.suffix.lower() == ".html":
                    continue

                if file.suffix.lower() not in IMAGE_EXTS:
                    if file.suffix == "":
                        issues.append((relpath, "missing extension (for example: .jpg or .png)"))
                    else:
                        issues.append((relpath, f"unsupported extension: {file.suffix}"))
                    continue

                if not name.startswith(f"{cat}_"):
                    issues.append((relpath, f"expected '{cat}_' prefix"))

                if name != lower_name:
                    issues.append((relpath, "contains uppercase letters; use lowercase for consistency"))

                if "widescreenpng" in lower_name:
                    issues.append((relpath, "looks like a typo; likely missing a dot before png"))

    return issues


# ── HTML fragments ──────────────────────────────────────────────────────────

def page_head(title: str, depth: int = 0) -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} — Sean's Wallpaper Repository</title>
  <link rel="stylesheet" href="{rel(depth, 'gallery.css')}">
</head>
<body>
"""


def site_header(crumbs: list[tuple[str, str | None]], depth: int = 0) -> str:
    """crumbs: list of (label, href) pairs; href=None marks the current page."""
    parts = ""
    for i, (label, href) in enumerate(crumbs):
        if i:
            parts += '<span class="sep">›</span>'
        if href is not None:
            parts += f'<a href="{rel(depth, href)}">{label}</a>'
        else:
            parts += f'<span class="cur">{label}</span>'
    return f"""<header class="site-header">
  <a class="logo" href="{rel(depth, 'index.html')}">Sean's Wallpaper Repository</a>
  <nav class="breadcrumb">{parts}</nav>
</header>
"""


def page_foot() -> str:
    return """<footer>
  <p>A semi-curated archive of desktop wallpapers for personal use.<br>
  <a href="https://github.com/seangalie/wallpapers">View on GitHub</a> &nbsp;·&nbsp; <a href="https://choosealicense.com/licenses/mit/">MIT License</a></p>
</footer>
</body>
</html>
"""


# ── Page generators ─────────────────────────────────────────────────────────

def gen_index() -> str:
    total = sum(
        len(get_images(lib, cat))
        for lib in LIBS
        for cat in get_cats(lib)
    )
    cat_total = sum(len(get_cats(lib)) for lib in LIBS)

    cards = ""
    for lib in LIBS:
        lib_cats = get_cats(lib)
        img_count = sum(len(get_images(lib, cat)) for cat in lib_cats)
        preview_cat = largest_cat(lib)
        preview_img = first_image(lib, preview_cat) if preview_cat else None
        thumb_html = ""
        if preview_img:
            src = rel(0, "thumbnails", lib, preview_cat, thumb_name(preview_img))
            thumb_html = f'<img src="{src}" loading="lazy" alt="">'

        cards += f"""
  <a class="lib-card" href="{lib}/index.html">
    <div class="thumb">{thumb_html}</div>
    <div class="body">
      <div class="icon">{LIB_ICON[lib]}</div>
      <h3>{LIB_LABELS[lib]}</h3>
      <p>{LIB_DESC[lib]}</p>
      <div class="meta">{len(lib_cats)} categories &nbsp;·&nbsp; {img_count} wallpapers</div>
    </div>
  </a>"""

    return (
        page_head("Gallery", depth=0)
        + site_header([], depth=0)
        + f"""<main>
  <div class="hero">
    <h2>Sean's Wallpaper Repository</h2>
    <p>A semi-curated archive of high-quality wallpapers gathered over the years,
       organized by display layout and theme.</p>
    <div class="hero-stats">
      <div><strong>{total}</strong> wallpapers</div>
      <div><strong>{cat_total}</strong> categories</div>
      <div><strong>4</strong> libraries</div>
    </div>
    <p class="hero-note">
      All images are for personal use. Copyright remains with original creators.
      For takedown requests, <a href="https://github.com/seangalie/wallpapers/issues/new">open an issue</a>.
    </p>
  </div>

  <div class="section-head">
    <h2>Choose a Library</h2>
    <p>Select the layout that matches your display setup</p>
  </div>
  <div class="lib-grid">{cards}
  </div>
</main>
"""
        + page_foot()
    )


def gen_lib(lib: str) -> str:
    lib_cats = get_cats(lib)
    total = sum(len(get_images(lib, cat)) for cat in lib_cats)

    cards = ""
    for cat in lib_cats:
        img_list = get_images(lib, cat)
        count = len(img_list)
        label = CAT_LABELS.get(cat, cat.replace("-", " ").title())
        first = img_list[0] if img_list else None
        thumb_html = ""
        if first:
            src = rel(1, "thumbnails", lib, cat, thumb_name(first))
            thumb_html = f'<img src="{src}" loading="lazy" alt="">'
        cards += f"""
  <a class="cat-card" href="{cat}/index.html">
    <div class="thumb">{thumb_html}</div>
    <div class="label">
      <h4>{label}</h4>
      <span>{count} wallpapers</span>
    </div>
  </a>"""

    return (
        page_head(LIB_LABELS[lib], depth=1)
        + site_header(
            [("Home", "index.html"), (LIB_LABELS[lib], None)],
            depth=1,
        )
        + f"""<main>
  <div class="section-head">
    <h2>{LIB_ICON[lib]} {LIB_LABELS[lib]}</h2>
    <p>{LIB_DESC[lib]} &nbsp;·&nbsp; {total} wallpapers across {len(lib_cats)} categories</p>
  </div>
  <div class="cat-grid">{cards}
  </div>
</main>
"""
        + page_foot()
    )


def gen_cat(lib: str, cat: str) -> str:
    img_list = get_images(lib, cat)
    label = CAT_LABELS.get(cat, cat.replace("-", " ").title())

    items = ""
    for img in img_list:
        name = pretty_name(img)
        safe_name = html.escape(name)
        safe_img = html.escape(img)
        thumb_src = rel(2, "thumbnails", lib, cat, thumb_name(img))
        medium_src = rel(2, "medium", lib, cat, thumb_name(img))
        orig_href = html.escape(original_url(lib, cat, img))
        items += f"""
  <div class="img-item">
    <a href="{medium_src}" target="_blank" rel="noopener" title="{safe_name}">
      <img src="{thumb_src}" loading="lazy" alt="{safe_name}">
    </a>
    <div class="meta">
      <span class="name">{safe_img}</span>
      <a class="orig" href="{orig_href}" target="_blank" rel="noopener" title="Download original">Original</a>
    </div>
  </div>"""

    return (
        page_head(f"{label} — {LIB_LABELS[lib]}", depth=2)
        + site_header(
            [
                ("Home", "index.html"),
                (LIB_LABELS[lib], f"{lib}/index.html"),
                (label, None),
            ],
            depth=2,
        )
        + f"""<main>
  <div class="section-head">
    <h2>{label}</h2>
    <p>{LIB_LABELS[lib]} &nbsp;·&nbsp; {len(img_list)} wallpapers — click any image for a larger preview, or "Original" for the full-resolution file</p>
  </div>
  <div class="img-grid">{items}
  </div>
</main>
"""
        + page_foot()
    )


# ── Entry point ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate wallpaper gallery pages.")
    parser.add_argument(
        "--check-names",
        action="store_true",
        help="Check wallpaper filenames for consistency and print issues.",
    )
    parser.add_argument(
        "--no-previews",
        action="store_true",
        help="Skip thumbnail/medium generation; only re-emit HTML and CSS.",
    )
    args = parser.parse_args()

    if args.check_names:
        issues = validate_filenames()
        if not issues:
            print("No filename issues found.")
            return
        print("Filename issues:")
        for relpath, issue in issues:
            print(f"  - {relpath}: {issue}")
        return

    OUT.mkdir(exist_ok=True)

    if not args.no_previews:
        built, skipped, failed, cleaned = build_previews()
        print(
            f"  done   previews: built={built}, skipped={skipped}, "
            f"failed={failed}, cleaned={cleaned}"
        )

    (OUT / "gallery.css").write_text(CSS, encoding="utf-8")
    print("  wrote  docs/gallery.css")

    (OUT / "index.html").write_text(gen_index(), encoding="utf-8")
    print("  wrote  docs/index.html")

    for lib in LIBS:
        lib_dir = OUT / lib
        lib_dir.mkdir(parents=True, exist_ok=True)
        (lib_dir / "index.html").write_text(gen_lib(lib), encoding="utf-8")
        print(f"  wrote  docs/{lib}/index.html")

        for cat in get_cats(lib):
            cat_dir = lib_dir / cat
            cat_dir.mkdir(parents=True, exist_ok=True)
            (cat_dir / "index.html").write_text(gen_cat(lib, cat), encoding="utf-8")
            print(f"  wrote  docs/{lib}/{cat}/index.html")

    print("\nDone.")


if __name__ == "__main__":
    main()
