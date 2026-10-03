# Contributing to Sean's Wallpaper Archive

New wallpapers and corrections are welcome. You can help by adding images,
improving names or categories, identifying sources and creators, or updating
the documentation. Please follow the [code of conduct](CODE_OF_CONDUCT.md).

## Get started

Fork the repository and clone your fork. The archive consists of image files
and Markdown documentation, so no application dependencies or build are required.
Install Git and [Git LFS](https://git-lfs.com/) for a local checkout, then run:

```sh
git lfs install
git clone https://github.com/YOUR-USERNAME/wallpapers.git
cd wallpapers
git lfs pull
```

The repository's [`.gitattributes`](../.gitattributes) routes wallpaper image
formats through LFS when you stage them with `git add`. README previews in
`docs/` stay in regular Git. Add an LFS rule when introducing a new image format.

Keep a pull request focused on one addition or a related set of changes.
Discuss a new category, a large import, or a bulk reorganization in an
[issue](https://github.com/seangalie/wallpapers/issues) before preparing it.

## Add wallpapers

- Choose the display format and category using the
  [organization guide](ORGANIZATION.md).
- Keep images directly inside `wallpapers/<format>/<category>/`. Categories
  stay flat; describe styles, variants, and panels in filenames.
- Use a descriptive filename and preserve the image's actual format. Changing
  an extension does not convert the file.
- Open the image and confirm that its subject, dimensions, and filename agree.
- Include the creator, original source URL, and any known license or permission
  information in the pull request. Mark unknown details as unknown.
- Check for an identical image already in the archive. Distinct resolutions,
  crops, color variants, and paired panels can be useful; explain the difference.
- Preserve the supplied image quality. Explain any cropping, resizing, or
  conversion you propose.

## Correct names, categories, or credits

Identify the current file path and explain the correction. For a rename or
move, include the proposed destination. For a subject, character, location, or
creator identification, include a source that supports it when available.
Known creators and sources are recorded in [CREDITS.md](../CREDITS.md), with
the evidence for each credit.

For bulk changes, provide an old-to-new path list for review. Check that every
destination is unique and free before moving files, keep a rollback mapping,
and verify that image contents and file counts are preserved afterward.

## Submit a pull request

1. Create a branch in your fork.
2. Add or update the relevant files and documentation.
3. Record user-visible changes under `## [Unreleased]` in
   [CHANGELOG.md](../CHANGELOG.md).
4. Stage your changes and run `scripts/check-collection.sh`. It checks paths,
   filenames, LFS tracking, and duplicates, and reports when the README's
   collection table needs updating; `scripts/check-collection.sh --write-readme`
   updates it. Also run `git diff --check` and review the images you changed.
5. Use a [Conventional Commit](https://www.conventionalcommits.org/) message,
   such as `feat: add forest wallpapers` or `fix: correct galaxy filenames`.
6. Push your branch and open a pull request using the repository's template.

Pull requests need at least one of these labels: `breaking-change`, `bugfix`,
`documentation`, `enhancement`, `refactor`, `performance`, `new-feature`,
`maintenance`, `ci`, or `dependencies`. A maintainer can add a label if needed.

## Checks

Run `bash scripts/test-check-collection.sh` after changing collection validation.
The regression tests use disposable Git indexes and do not download wallpapers.

Text files follow [`.editorconfig`](../.editorconfig). The Lint workflow checks
text formatting and runs shellcheck on tracked shell scripts. Workflow changes
are checked by actionlint and zizmor. The CI workflow runs
`scripts/check-collection.sh` on every pull request without downloading the
images.

The script cannot judge what an image shows. For image changes, also verify
that files open, dimensions match the intended format, and filenames
distinguish variants.
For documentation changes, check local links and keep counts and examples
consistent with the archive.

Repository-authored non-image contributions use the
[Apache License 2.0](../LICENSE-APACHE), subject to existing third-party notices.
Wallpapers and preview images retain the rights and terms of their original
creators; they are excluded from the Apache license. Sean's own photographs,
listed in [LICENSE-ORIGINALS](../LICENSE-ORIGINALS), use CC BY-NC 4.0; other
creators who supply originals should state their own terms. Do not infer permission
from an image's presence in the archive. Include known source and licensing
information for wallpaper contributions and clearly mark unknown details.
See [LICENSE](../LICENSE) for the complete licensing scope.
