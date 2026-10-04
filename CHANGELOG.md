# Changelog

Notable changes to Sean's Wallpaper Archive are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This is a live record of user-visible changes toward the first **1.0.0** release.
Keep updating **Unreleased** as the collection and repository are prepared;
add a dated 1.0.0 section only when the release is ready.

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

Work in progress toward **1.0.0**.

### Added

- Initial collection of 1,250 wallpapers across desktop, ultrawide, dual-monitor,
  triple-monitor, mobile, and square formats.
- A flat `retro` category for 25 images with retro graphic styles.
- A Creative Commons Attribution-NonCommercial 4.0 license for Sean's own
  photographs in `desktops/original`, listed in `LICENSE-ORIGINALS`. They may
  be shared and adapted for non-commercial purposes with credit.
- `CREDITS.md`, listing creators and sources found in image metadata, with the
  evidence for each credit and any uncertainty.
- Archive browsing instructions, category and filename conventions, and guidance
  for contributing new wallpapers, corrections, and source credits.
- Git LFS tracking for wallpaper image formats, with setup and download
  instructions for local checkouts. README preview images remain in regular Git.
- A category-by-format table in the README, with each count linking to its
  folder, and common resolutions for each display format.
- Instructions for downloading a single format or category with
  `git lfs pull --include`, instead of the whole 2 GB collection.
- Aspect-ratio and multi-monitor arithmetic guidance for choosing a display
  format in the organization guide.
- A collection check, run in CI without downloading images, that verifies
  layout, categories, filenames, Git LFS pointers and tracking rules,
  case-insensitive path collisions, exact duplicates, and the README's
  collection counts.
- ZIP downloads attached to each GitHub release: one ZIP per display format,
  and one per category for desktop wallpapers, each with `LICENSE.txt`, plus
  `SHA256SUMS.txt` checksums. Release downloads do not count against the
  repository's monthly Git LFS bandwidth.

### Changed

- Introduced the project name **Sean's Wallpaper Archive** and the description
  "A collection of desktop, multi-desktop, and mobile wallpapers gathered from
  all over the internet".
- Organized images by display format and flat subject or style categories,
  including illustration placement in outdoors, urban, and minimal categories.
- Clarified generic filenames, image variants, and paired panel names with
  `-left-panel` and `-right-panel` suffixes.
- Separated image rights from the Apache 2.0 license for repository-authored
  documentation, configuration, and code. Image terms remain with original
  creators and rights holders, unknown terms are identified as unknown, and
  existing third-party notices are retained.
- Replaced the Contributor Covenant with a shorter code of conduct written for
  this archive, including how to report a concern privately.
- Added a `NOTICE` file with the copyright notice for repository-authored
  files.
- Questions and suggestions now go through issues; the repository does not use
  GitHub Discussions.
- Renamed seven wallpapers for consistent names: `desktops/space/galaxy-m82`
  (was `galaxy-messier82`), `desktops/space/earth` and `planetrise` (dropped
  the redundant `space-` prefix), `dual/urban/san-francisco-1906` (was
  `sanfrancisco-1906`), and `dual/urban/brooklyn-bridge`, `chernobyl-ruins`,
  and `golden-gate-bridge` (dropped the `landmarks-` prefix).
- Renamed `mobile/tech/asop-portrait-dark.png` and `asop-portrait-light.png` to
  `grapheneos-logo-blue.png` and `grapheneos-logo-white.png`, identifying the
  GrapheneOS logo and naming each by its logo color.
- Enlarged three small images for current displays: `hobbit-art` and
  `multicolor-groot` to 3840×2160 with Real-ESRGAN, and `blue-gradient` to
  4096×3072 by reconstructing the gradient. `CREDITS.md` records each method.

### Removed

- Three duplicate wallpapers from the initial import: one exact copy, and JPEG
  re-encodes of `dual/gaming/firewatch-tower-dual.png` and
  `desktops/themes/osaka-jade_shaded-entrance.png`, which remain.

### Fixed

- Corrected filename spelling, astronomy and character titles, and misplaced
  portrait and multi-monitor images.
- Replaced README template placeholders and references to missing screenshots
  with archive documentation and landscape, portrait, and square previews.

[unreleased]: https://github.com/seangalie/wallpapers/commits/main
