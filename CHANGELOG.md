# Changelog

Notable changes to Sean's Wallpaper Archive are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and releases use [Semantic Versioning](https://semver.org/) as it applies to
a collection: adding wallpapers is a minor release, corrections are a patch,
and moving or renaming published paths or downloads is a major release.

<!--
Add entries to [Unreleased] as changes are made, grouped under these headings
and in this order. Omit any heading that has no entries.

  Added       -- new features
  Changed     -- changes to existing functionality
  Deprecated  -- features that will be removed in an upcoming release
  Removed     -- features removed in this release
  Fixed       -- bug fixes
  Security    -- vulnerabilities addressed

Write for the person upgrading, not for the person who wrote the patch: say what
changed for them and what they need to do about it.

When cutting a release, rename [Unreleased] to the new version with its release
date, start a fresh [Unreleased] section above it, and update the link
definitions at the bottom of the file. Then push a matching tag, such as v1.2.0
for a `## [1.2.0] - YYYY-MM-DD` section: the Release workflow publishes that
section as the GitHub release notes, and refuses to publish if it is missing.
-->

## [Unreleased]

## [2.0.0] - 2026-10-07

180 Gruvbox wallpapers join the archive, bringing it to 1,464 images. This is
a major release because the desktop downloads changed: the collection outgrew
GitHub's limit for a single release file, so `wallpapers-desktops.zip` is now
two parts. If you link to or script that download, see **Changed** below.

### Added

- **180 Gruvbox wallpapers:** 171 desktop, 6 ultrawide, and 3 dual-monitor
  images recolored in the warm [Gruvbox](https://github.com/morhetz/gruvbox)
  palette, sorted by subject like the rest of the archive. Their names end in
  `-gruvbox`, or `-gruvbox-light` for the light variant, so they are easy to
  find. Highlights:
  - painted sci-fi countryside, machines, and wrecks in `desktops/scifi`
  - dinosaurs, pterosaurs, and giant creatures in `desktops/fantasy`
  - Linux and NixOS logos with retro stripes in `desktops/tech`
  - Black Mesa, City 17, Doom Eternal, Firewatch, and Red Dead Redemption 2
    scenes in `desktops/gaming`
  - forests, lakes, and mountains in `desktops/outdoors`
  - Gruvbox versions of three wallpapers already in the archive:
    `astronaut-station`, `drawn-spaceship-deck`, and `firewatch-wide-lookout`
  - thirteen images that were too small for today's screens, enlarged and
    listed under "Modified images" in [CREDITS.md](CREDITS.md)
- **Credits:** Simon Stålenhag is credited for four paintings that carry his
  signature or web address, and Ahmed Mostafa for an astronaut scene from
  Desktopography.

### Changed

- **Desktop ZIP downloads come in parts.** The desktop collection has grown
  past what GitHub allows in one release download, so `wallpapers-desktops.zip`
  is replaced by `wallpapers-desktops-part-1.zip` and
  `wallpapers-desktops-part-2.zip`. Each part keeps whole categories together:
  part 1 has `abstract` through `outdoors` (about 1.3 GB), and part 2 has
  `pop-culture` through `urban` (about 0.9 GB). Download both for every
  desktop image, or pick a single category from the per-category ZIPs, which
  are unchanged. As the collection grows, a category may move to the other
  part, or a third part may be added.

## [1.1.0] - 2026-10-07

### Added

- **34 new wallpapers:** 33 desktop images and 1 mobile image. Highlights:
  - a `mojave_` theme in `desktops/themes` with the sand dune at morning, day,
    dusk, and night
  - liquid color swirls in `desktops/abstract`
  - mountain, ocean, and meadow landscapes in `desktops/outdoors`
  - Milky Way, Jupiter, and astronaut scenes in `desktops/space`
  - historical paintings and a ukiyo-e print in `desktops/history` and
    `desktops/art`
  - an Orthodox cathedral dome in `mobile/art`
- **Credits:** Thomas Cole is credited for his signed painting
  `desktops/history/course-of-empire-consummation.jpg`.

### Removed

- The newly added samurai collage wallpaper
  `desktops/inspiration/lock-in-samurai-panels.jpg`, before inclusion in a release.

## [1.0.0] - 2026-10-03

The first public release of Sean's Wallpaper Archive: 1,250 wallpapers for
single desktops, ultrawide screens, two- and three-monitor setups, phones, and
square displays, gathered from all over the internet and now easy to share.

### Added

- **The collection:** 1,250 wallpapers in six display formats, with 964
  desktop, 65 ultrawide, 108 dual-monitor, 47 triple-monitor, 58 mobile, and 8
  square images, sorted into 21 categories from `abstract` to `urban`.
- **ZIP downloads** with every release: one ZIP per display format, such as
  `wallpapers-desktops.zip` with all 964 desktop images (about 1.8 GB), and one
  per desktop category, such as `wallpapers-desktops-space.zip`. Every ZIP
  includes `LICENSE.txt` explaining the image rights, and `SHA256SUMS.txt`
  lists a checksum for each ZIP.
- **Browsing guides:** a README table linking every category in every format,
  the common resolutions for each format, and an organization guide that
  explains the categories, filenames, and how to choose a format for your
  screen or monitor layout.
- **Credits:** `CREDITS.md` names known photographers, artists, and sources,
  with the evidence for each credit. If you recognize an uncredited image,
  please open an issue.
- **Sean's own photographs** of the New Jersey Pine Barrens, in
  `desktops/original`, licensed under Creative Commons Attribution-NonCommercial
  4.0: share and adapt them for non-commercial purposes with credit.
- **Ways to contribute:** guides and issue forms for suggesting wallpapers,
  correcting names or credits, and asking questions, plus a code of conduct.

### Changed

For anyone who used Sean's previous private wallpaper archive (release
`v2026.09`):

- The `desktop` folder is now `desktops`, and `source` is now `square`.
- About 190 images moved to a better-fitting category. Most of the old `art`
  category moved into subject categories such as `outdoors`, `abstract`,
  `urban`, and `space`, and new `abstract` and `retro` categories collect those
  styles. Three more images moved to a different display format.
- About 40 images were renamed to clearer names, and paired dual-monitor panels
  now end in `-left-panel` and `-right-panel`.
- `wallpapers-desktop.zip` is now `wallpapers-desktops.zip`, desktop
  wallpapers are also offered one category per ZIP, and `wallpapers-source.zip`
  is now `wallpapers-square.zip`.
- Three small images, `hobbit-art`, `multicolor-groot`, and `blue-gradient`,
  were enlarged for current displays. `CREDITS.md` records how.

### Removed

- Three duplicate images from the previous archive.

[unreleased]: https://github.com/seangalie/wallpapers/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/seangalie/wallpapers/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/seangalie/wallpapers/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/seangalie/wallpapers/releases/tag/v1.0.0
