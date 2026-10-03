# Organizing Sean's Wallpaper Archive

The archive uses one display-format folder, one category, and a descriptive
filename:

```text
wallpapers/<format>/<category>/<filename>
```

Images live directly inside their category. Keep categories flat: use names
to distinguish illustration styles, color variants, and individual panels.

## Display formats

| Folder | Purpose |
| --- | --- |
| `desktops` | Single desktop displays |
| `ultrawide` | Wide single-display layouts |
| `dual` | Two-monitor panoramas and matching single-screen panel pairs |
| `triple` | Three-monitor panoramas |
| `mobile` | Portrait layouts and phones |
| `square` | Images with equal width and height |

Check dimensions before assigning a format. These are intended layouts, not
fixed resolutions. Keep the halves of a paired dual-monitor set together in
`dual`, even when each half has a single-monitor aspect ratio.

As a guide, a single landscape image up to about 2.2:1 belongs in `desktops`;
most are 16:9 or 16:10, with some at 4:3. A single image wider than that, such
as 21:9 at 3440×1440, belongs in `ultrawide`. Portrait images belong in
`mobile`, and images at exactly 1:1 belong in `square`.

Judge multi-monitor images by monitor arithmetic rather than raw ratio: they
are two or three copies of a single-screen ratio placed side by side. 3840×1080
is two 1920×1080 screens, 3200×1200 is two 1600×1200 screens, and 7680×1440 is
three 2560×1440 screens. A 3200×1200 image is `dual`, not `ultrawide`, even
though its ratio looks like an ultrawide one.

## Categories

| Category | Main subject or purpose |
| --- | --- |
| `abstract` | Nonrepresentational shapes, patterns, textures, light, and color |
| `art` | Decorative artwork, portraits, interiors, framed prints, or artwork without a clearer category |
| `cars` | Cars, trucks, and vehicle artwork |
| `fantasy` | Magical subjects, mythical creatures, and fantastical worlds |
| `gaming` | Recognizable games, game worlds, characters, and gaming imagery |
| `history` | Historical subjects, military aviation, and historical artwork |
| `inspiration` | Motivational quotations and advice |
| `minimal` | Sparse compositions, simple silhouettes, and restrained graphic designs |
| `music` | Musicians, instruments, and music imagery |
| `original` | Original work supplied by its creator |
| `outdoors` | Landscapes, gardens, plants, wildlife, and outdoor scenes |
| `pop-culture` | Film, television, comics, and other recognizable cultural subjects |
| `retro` | Retro graphic styles, including synthwave and vaporwave |
| `science` | Scientific illustrations, visualizations, and world maps |
| `scifi` | Futuristic technology, fictional spacecraft, and science-fiction settings |
| `space` | Astronomy, celestial scenes, astronauts, and space exploration |
| `star-trek` | Star Trek imagery |
| `star-wars` | Star Wars imagery |
| `tech` | Computers, hardware, software logos, and computing imagery |
| `themes` | Named theme families and their coordinated variants |
| `urban` | Streets, buildings, skylines, and city scenes |

## Choose the most useful category

Keep recognized games, franchises, named theme collections, and creator-supplied
originals in their specific categories. For other images, consider what someone
would look for when browsing the archive.

**Retro:** use `retro` when the graphic aesthetic is the main appeal: synthwave
suns and grids, vaporwave framing, vintage line graphics, or retro city posters.
An old computer photograph belongs in `tech`, a classic car belongs in `cars`,
and a named `retro-82` theme stays in `themes`. Bright neon colors alone do not
make an image retro.

**Illustrations:** sort primarily by subject. An illustrated forest can belong
in `outdoors`, a painted city in `urban`, and an astronomy illustration in
`space`. Sparse illustrations can fit `minimal`. Decorative artwork, portraits,
interiors, and framed prints can remain in `art`. Illustration is a style that
can appear across categories.

Keep a single copy in the best-fitting category. When the identity or source is
uncertain, ask for clarification instead of assigning a speculative franchise,
location, or creator name.

## Filename conventions

- Use lowercase descriptive names with hyphens: subject, setting or composition,
  then a useful style or variant suffix.
- Keep meaningful existing words such as `illustrated`, `painted`, `drawn`,
  `poly`, or `lineart`. For new files, `-illustration`, `-pixel-art`, and
  `-line-art` can distinguish otherwise similar subjects.
- Use `-dark`, `-light`, or a color name for variants. Replace generic numbers
  with a description when the difference is known.
- Preserve established theme prefixes and separators, including underscore
  names used by existing theme families.
- Use `-panel` for an individual panel, or `-left-panel` and `-right-panel`
  for paired halves. A combined panorama may use `-dual` or `-triple`.
- Keep the correct file extension and avoid overwriting an existing filename,
  including names that differ only by letter case.

For example, this dawn set stays directly in `dual/gaming`:

```text
firewatch-dawn-tower-dual.png
firewatch-dawn-tower-left-panel.jpg
firewatch-dawn-tower-right-panel.jpg
```

Before a bulk move or rename, review the full old-to-new path list. Preserve
image contents, keep a rollback mapping, and verify the results. See the
[contributing guide](CONTRIBUTING.md) for submitting changes.

`scripts/check-collection.sh` enforces the layout, the format and category
lists, and the filename rules above. Adding a format or category means updating
the lists in that script along with this guide.
