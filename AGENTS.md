# Working on Sean's Wallpaper Archive

Instructions for AI agents. Human contributors should start with
[CONTRIBUTING.md](docs/CONTRIBUTING.md). `CLAUDE.md` imports this file, so shared
instructions belong here, not there.

## Project overview

Sean's Wallpaper Archive is a static collection of desktop, multi-desktop, and
mobile wallpapers gathered from across the internet. It serves people browsing
for wallpapers by display format, subject, or style. The repository contains
image assets, Markdown documentation, and GitHub Actions configuration; there
is no application framework. See the [README](README.md).

## Commands and validation

Git LFS is required for wallpaper images in a local checkout. No application
dependency installation, build, or application test suite is required.
`.github/workflows/ci.yml` currently contains only a placeholder step; there are
no all-tests or single-test commands.

```sh
# Set up LFS for this checkout after installing Git LFS:
git lfs install --local
git lfs pull

# Inspect LFS changes and tracked images after staging assets:
git lfs status
git lfs ls-files

# Check whitespace in tracked changes:
git diff --check

# Check text formatting, when editorconfig-checker is available:
editorconfig-checker
```

The Lint workflow runs editorconfig-checker and checks tracked `*.sh` and
`*.bash` files with shellcheck. Its exact script command on Ubuntu is:

```sh
git ls-files -z -- '*.sh' '*.bash' | xargs -0 -r shellcheck
```

Workflow changes are checked by actionlint and zizmor in
`.github/workflows/lint-workflows.yml`. Use the pinned tool configuration there.
For asset changes, verify that every changed image opens and that format,
category, dimensions, and filename agree. Check for duplicate contents and
case-insensitive path collisions. For documentation changes, check local links,
examples, and any collection counts.

## Repository layout

- `wallpapers/<format>/<category>/` -- image assets; each category stays flat.
- `.gitattributes` -- LFS image rules scoped to `wallpapers/`, plus text formatting.
- `LICENSE` -- licensing scope; `LICENSE-APACHE` -- unmodified Apache 2.0 terms.
- `docs/ORGANIZATION.md` -- category definitions and naming conventions.
- `docs/` -- contribution, support, security, and conduct policies, plus README images.
- `.github/` -- issue and PR templates, labels, Dependabot, and workflows.
- `CHANGELOG.md` -- collection additions, reorganizations, and corrections in
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

There are no generated application outputs or repository packaging scripts.
The current Release workflow publishes changelog notes, without building
wallpaper archives.
Downloadable ZIP contents, naming, and publication are still being planned for
1.0.0. Future packaging must fetch LFS image contents and reject unresolved LFS
pointers before building archives. GitHub source archives include pointers by
default unless the repository setting to include LFS objects is enabled; see
the [archive documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/managing-git-lfs-objects-in-archives-of-your-repository).

## Conventions

- Follow [ORGANIZATION.md](docs/ORGANIZATION.md) for the six display formats,
  flat categories, retro styles, illustration placement, and panel suffixes.
- Use descriptive lowercase hyphenated filenames. Preserve established theme
  prefixes and underscore separators. Retain original image quality unless a
  transformation is explicitly requested.
- Do not infer a creator, franchise, location, or license from a vague filename.
  Record uncertainty and use evidence for specific identifications.
- Preserve LFS tracking for wallpaper images. When adding an image format,
  check the scoped rules in `.gitattributes`; keep documentation previews out
  of LFS. Do not rewrite Git history unless explicitly requested.
- For bulk moves or renames, prepare a concrete old-to-new proposal and obtain
  approval unless those exact changes are already authorized. Keep a rollback
  mapping and verify hashes, counts, sizes, modification times, and file identity.
- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/).
- **Changelog:** record user-visible changes under `## [Unreleased]` using the
  headings listed in its comment. Internal-only changes need no entry.
  Until the first release, keep this as the live record for planned 1.0.0.
- **Pull requests** fill in `.github/PULL_REQUEST_TEMPLATE.md` and carry at least
  one of `breaking-change`, `bugfix`, `documentation`, `enhancement`, `refactor`,
  `performance`, `new-feature`, `maintenance`, `ci`, or `dependencies`.
- **Formatting** follows `.editorconfig`: UTF-8, LF, and a final newline. Use
  2 spaces for YAML, JSON, TOML, web files, shell, and Ruby; 4 elsewhere; tabs
  for Go and Makefiles. Markdown has no fixed indentation size. PowerShell,
  batch, and CSV files use CRLF.
- **Releases:** prepare a dated version section in `CHANGELOG.md` before pushing
  a matching `v*` tag. The Release workflow publishes that section as notes.
- **GitHub Actions:** pin third-party actions to a full commit SHA with a version
  comment, and grant each workflow only the permissions it needs.

## Boundaries

- Never commit secrets. Keep `.env` files ignored and document new variables in
  `.env.example` if variables are introduced.
- Preserve the standard Apache text in `LICENSE-APACHE` and third-party notices.
  Follow the scope in `LICENSE`: image rights remain with original creators and
  rights holders; repository-authored non-image files use Apache 2.0. Do not
  claim permissions for imported artwork without source evidence.
- Do not weaken checks by skipping or deleting tests, adding blanket lint
  suppressions, or removing CI steps. Fix the cause or report what is failing.
- Never describe an unfixed security vulnerability in a public issue, pull
  request, or commit message. See [SECURITY.md](docs/SECURITY.md).
- Obtain approval for new category structures, bulk asset changes, license
  changes, and release or publication actions unless already authorized.
