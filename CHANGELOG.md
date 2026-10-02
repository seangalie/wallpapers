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

Work in progress toward **1.0.0**. Downloadable wallpaper ZIP contents, naming,
and publication workflow are still being planned; no ZIP packaging is
implemented yet. Finalize those decisions and record the implemented behavior
here before publishing the release.

### Added

- Initial collection of 1,252 wallpapers across desktop, ultrawide, dual-monitor,
  triple-monitor, mobile, and square formats.
- A flat `retro` category for 25 images with retro graphic styles.
- Archive browsing instructions, category and filename conventions, and guidance
  for contributing new wallpapers, corrections, and source credits.
- Git LFS tracking for wallpaper image formats, with setup and download
  instructions for local checkouts. README preview images remain in regular Git.

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

### Removed

- One exact duplicate wallpaper from the initial import.

### Fixed

- Corrected filename spelling, astronomy and character titles, and misplaced
  portrait and multi-monitor images.
- Replaced README template placeholders and references to missing screenshots
  with archive documentation and landscape, portrait, and square previews.

[unreleased]: https://github.com/seangalie/wallpapers/commits/main
