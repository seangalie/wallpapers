#!/usr/bin/env bash
# Packages the tracked wallpapers into one flat ZIP per display format.
#
# Each archive holds its files directly at the root, named
# <category>_<filename>, so wallpapers/dual/gaming/firewatch-tower-left-panel.jpg
# becomes gaming_firewatch-tower-left-panel.jpg in wallpapers-dual.zip. Every
# archive also carries the repository's LICENSE as LICENSE.txt, so the image
# rights notice travels with the downloads. Images are stored, not
# recompressed: they are already compressed, and recompressing them costs time
# for no gain.
#
# The collection is checked first with scripts/check-collection.sh. Only images
# tracked by Git are packaged, so local files and OS metadata such as .DS_Store
# never reach an archive. Packaging stops if any image is still an LFS pointer
# (run `git lfs pull` first), or if an archive would reach GitHub's 2 GiB limit
# for a release asset.
#
# Usage: scripts/package-wallpapers.sh [output-dir]
#   output-dir  defaults to dist/release at the repository root
#
# Requires git, git-lfs contents, and zip. Written for the bash 3.2 that macOS
# ships as well as the runner's.

set -euo pipefail

FORMATS="desktops ultrawide dual triple mobile square"
ASSET_LIMIT=2147483648 # 2 GiB

ROOT="$(git rev-parse --show-toplevel)"
OUTPUT_DIR="${1:-${ROOT}/dist/release}"

bash "${ROOT}/scripts/check-collection.sh"

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# Staged beside the output so the hard links below usually stay on one
# filesystem; when they cannot, the file is copied instead.
STAGE="$(mktemp -d "${OUTPUT_DIR}/.stage.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

errors=0

fail() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$1" >&2; else echo "error: $1" >&2; fi
  errors=$((errors + 1))
}

for format in $FORMATS; do
  stage="${STAGE}/${format}"
  mkdir "$stage"
  count=0

  while IFS= read -r -d '' path; do
    if head -c 40 "${ROOT}/${path}" | grep -q '^version https://git-lfs'; then
      fail "Git LFS image has not been downloaded (run git lfs pull): ${path}"
      continue
    fi

    relative="${path#wallpapers/"${format}"/}"
    archive_name="${relative%%/*}_${relative#*/}"
    ln "${ROOT}/${path}" "${stage}/${archive_name}" 2> /dev/null \
      || cp -p "${ROOT}/${path}" "${stage}/${archive_name}"
    count=$((count + 1))
  done < <(git -C "$ROOT" ls-files -z -- "wallpapers/${format}")

  if [ "$count" -eq 0 ]; then
    fail "No tracked images found in wallpapers/${format}"
  fi
  cp "${ROOT}/LICENSE" "${stage}/LICENSE.txt"
  printf '%s\n' "$count" > "${stage}.count"
done

if [ "$errors" -gt 0 ]; then
  echo "Packaging stopped: ${errors} problem(s) found." >&2
  exit 1
fi

for format in $FORMATS; do
  archive="${OUTPUT_DIR}/wallpapers-${format}.zip"
  # zip adds to an existing archive rather than replacing it.
  rm -f "$archive"
  # -0 stores without compression, -X leaves out OS-specific file attributes,
  # and sorting the list keeps the entry order the same from run to run.
  (
    cd "${STAGE}/${format}"
    find . -type f | sed 's|^\./||' | LC_ALL=C sort | zip -0 -X -q "$archive" -@
  )
  size="$(wc -c < "$archive" | tr -d ' ')"
  echo "wallpapers-${format}.zip: $(cat "${STAGE}/${format}.count") images, ${size} bytes"
  if [ "$size" -ge "$ASSET_LIMIT" ]; then
    fail "wallpapers-${format}.zip is ${size} bytes; GitHub release assets must be under 2 GiB"
  fi
done

if [ "$errors" -gt 0 ]; then
  exit 1
fi
