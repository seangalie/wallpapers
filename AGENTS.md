# Working on wallpapers

Instructions for AI coding agents. Human contributors should start with
[CONTRIBUTING.md](docs/CONTRIBUTING.md). `CLAUDE.md` imports this file, so shared
instructions belong here, not there.

If a section below still shows a `[?]` prompt, it has not been written yet: work
it out from the code and `.github/workflows/ci.yml` rather than guessing.

## Project overview

> **[?]**
> Two or three sentences: what wallpapers does, who uses it, and the main
> languages and frameworks. Link to the README for the rest.

## Commands

> **[?]**
> The exact commands to install dependencies, build, test, lint, and format,
> including how to run a single test. Keep them in step with CI: if
> `.github/workflows/ci.yml` runs it, list it here.

```sh
# Install:
# Build:
# Test (all):
# Test (one):
# Lint / format:
```

## Repository layout

- `docs/` -- contributing, security, support, and conduct policies, plus the README images.
- `.github/` -- issue and PR templates, labels, Dependabot, and the workflows.
- `CHANGELOG.md` -- release notes, in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

> **[?]**
> Add the source, test, and build-output directories, and name anything that is
> generated and must not be edited by hand.

## Conventions

- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org):
  `feat: add export command`, `fix(parser): handle empty input`.
- **Changelog:** record user-visible changes under `## [Unreleased]` in
  `CHANGELOG.md`, using the headings listed in its comment. Internal-only
  changes need no entry.
- **Pull requests** fill in `.github/PULL_REQUEST_TEMPLATE.md` and need at least
  one of these labels, or the PR Labels check fails: `breaking-change`,
  `bugfix`, `documentation`, `enhancement`, `refactor`, `performance`,
  `new-feature`, `maintenance`, `ci`, `dependencies`.
- **Formatting** follows `.editorconfig`: UTF-8, LF line endings, and a final
  newline. Indent with 2 spaces for YAML, JSON, TOML, web files, shell, and
  Ruby; 4 spaces elsewhere; tabs for Go and Makefiles. PowerShell, batch, and
  CSV files use CRLF. The Lint workflow enforces it with editorconfig-checker,
  and runs shellcheck over every `*.sh` and `*.bash` file.
- **Releases:** move the `## [Unreleased]` entries under a new version heading,
  then push a matching `v*` tag. The Release workflow publishes that
  `CHANGELOG.md` section as the release notes.
- **GitHub Actions:** pin every third-party action to a full commit SHA with its
  version in a trailing comment (`uses: owner/action@<sha> # vX.Y.Z`), and grant
  each workflow only the `permissions:` it needs. actionlint and zizmor check
  every change under `.github/workflows/`.

> **[?]**
> Add the project's code style: language version, naming, error handling,
> patterns to follow or avoid, and the files that show them best.

## Boundaries

- Never commit secrets. `.env` files are git-ignored; document new variables in
  `.env.example` instead.
- Leave the text of `LICENSE` unmodified.
- Do not make a change pass by weakening the checks: no skipped or deleted
  tests, blanket lint suppressions, or removed CI steps. Fix the cause, or stop
  and report what is failing.
- Never describe an unfixed security vulnerability in a public issue, pull
  request, or commit message. See [SECURITY.md](docs/SECURITY.md).

> **[?]**
> Add anything an agent must ask about before doing: schema migrations, public
> API changes, dependency upgrades, release steps.
