#!/usr/bin/env python3
"""Generate static HTML gallery pages for the wallpapers repository.

Run from the repository root:
    python3 generate_gallery.py

Produces:
    index.html                      — welcome/landing page
    {lib}/index.html                — category menu for each library
    {lib}/{cat}/index.html          — image grid for each category
    gallery.css                     — shared stylesheet
"""

from pathlib import Path

BASE = Path(__file__).parent
LIBS = ["desktop", "dual", "mobile", "triple"]

LIB_LABELS = {
    "desktop": "Desktop",
    "dual": "Dual Monitor",
    "mobile": "Mobile",
    "triple": "Triple Monitor",
}

LIB_DESC = {
    "desktop": "Single-monitor widescreen wallpapers (16:9)",
    "dual": "Panoramic wallpapers spanning two monitors (32:9)",
    "mobile": "Portrait wallpapers for phones and tablets (9:16)",
    "triple": "Ultra-wide wallpapers spanning three monitors (48:9)",
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
.img-item a { display: block; }
.img-item img { display: block; width: 100%; height: 175px; object-fit: cover; transition: transform .3s; }
.img-item:hover img { transform: scale(1.04); }
.img-item .name {
  padding: .4rem .65rem;
  font-size: .68rem;
  color: var(--muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

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


# ── Helpers ──────────────────────────────────────────────────────────────────

def get_images(lib: str, cat: str) -> list[str]:
    folder = BASE / lib / cat
    return sorted(
        f.name for f in folder.iterdir()
        if f.is_file() and f.suffix.lower() in IMAGE_EXTS
    )


def get_cats(lib: str) -> list[str]:
    folder = BASE / lib
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


# ── HTML fragments ────────────────────────────────────────────────────────────

def page_head(title: str, css_depth: int = 0) -> str:
    css_path = "../" * css_depth + "gallery.css"
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} — Wallpapers</title>
  <link rel="stylesheet" href="{css_path}">
</head>
<body>
"""


def site_header(crumbs: list[tuple[str, str | None]], root: str = "") -> str:
    """crumbs: list of (label, href) — None href means current page."""
    parts = ""
    for i, (label, href) in enumerate(crumbs):
        if i:
            parts += '<span class="sep">›</span>'
        if href is not None:
            parts += f'<a href="{root}{href}">{label}</a>'
        else:
            parts += f'<span class="cur">{label}</span>'
    return f"""<header class="site-header">
  <a class="logo" href="{root}index.html">Wallpapers</a>
  <nav class="breadcrumb">{parts}</nav>
</header>
"""


def page_foot() -> str:
    return """<footer>
  <p>A semi-curated archive of desktop wallpapers for personal use.<br>
  <a href="https://github.com/seangalie/wallpapers">View on GitHub</a> &nbsp;·&nbsp; MIT License</p>
</footer>
</body>
</html>
"""


# ── Page generators ───────────────────────────────────────────────────────────

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
        preview_src = f"{lib}/{preview_cat}/{preview_img}" if preview_img else ""
        thumb_html = f'<img src="{preview_src}" loading="lazy" alt="">' if preview_src else ""

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
        page_head("Gallery", css_depth=0)
        + site_header([])
        + f"""<main>
  <div class="hero">
    <h2>Desktop Wallpapers</h2>
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
        thumb_html = f'<img src="{cat}/{first}" loading="lazy" alt="">' if first else ""
        cards += f"""
  <a class="cat-card" href="{cat}/index.html">
    <div class="thumb">{thumb_html}</div>
    <div class="label">
      <h4>{label}</h4>
      <span>{count} wallpapers</span>
    </div>
  </a>"""

    return (
        page_head(LIB_LABELS[lib], css_depth=1)
        + site_header(
            [("Home", "index.html"), (LIB_LABELS[lib], None)],
            root="../"
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
        items += f"""
  <div class="img-item">
    <a href="{img}" target="_blank" rel="noopener" title="{name}">
      <img src="{img}" loading="lazy" alt="{name}">
    </a>
    <div class="name">{img}</div>
  </div>"""

    return (
        page_head(f"{label} — {LIB_LABELS[lib]}", css_depth=2)
        + site_header(
            [
                ("Home", "index.html"),
                (LIB_LABELS[lib], f"{lib}/index.html"),
                (label, None),
            ],
            root="../../"
        )
        + f"""<main>
  <div class="section-head">
    <h2>{label}</h2>
    <p>{LIB_LABELS[lib]} &nbsp;·&nbsp; {len(img_list)} wallpapers — click any image to open full size</p>
  </div>
  <div class="img-grid">{items}
  </div>
</main>
"""
        + page_foot()
    )


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    # Shared stylesheet
    (BASE / "gallery.css").write_text(CSS, encoding="utf-8")
    print("  wrote  gallery.css")

    # Root landing page
    (BASE / "index.html").write_text(gen_index(), encoding="utf-8")
    print("  wrote  index.html")

    for lib in LIBS:
        lib_dir = BASE / lib

        # Library index (e.g. desktop/index.html)
        (lib_dir / "index.html").write_text(gen_lib(lib), encoding="utf-8")
        print(f"  wrote  {lib}/index.html")

        for cat in get_cats(lib):
            (lib_dir / cat / "index.html").write_text(gen_cat(lib, cat), encoding="utf-8")
            print(f"  wrote  {lib}/{cat}/index.html")

    print("\nDone.")


if __name__ == "__main__":
    main()
