#!/usr/bin/env bash
# Packages the tracked wallpapers into flat ZIP archives for release downloads.
#
# Most display formats become one archive, wallpapers-<format>.zip, with each
# image at the root named <category>_<filename>: so
# wallpapers/dual/gaming/firewatch-tower-left-panel.jpg becomes
# gaming_firewatch-tower-left-panel.jpg in wallpapers-dual.zip.
#
# Formats listed in SPLIT_FORMATS are too large for one archive, so they become
# one archive per category instead, wallpapers-<format>-<category>.zip, with
# each image at the root under its own filename: so
# wallpapers/desktops/space/galaxy-m82.jpg becomes galaxy-m82.jpg
# in wallpapers-desktops-space.zip.
#
# Every archive also carries the repository's LICENSE as LICENSE.txt, so the
# image rights notice travels with the downloads. An archive holding any image
# listed in LICENSE-ORIGINALS also carries that file as LICENSE-ORIGINALS.txt,
# because those images are licensed under its CC BY-NC 4.0 terms. SHA256SUMS.txt lists a
# checksum for each archive. Images are stored, not recompressed: they are
# already compressed, and recompressing them costs time for no gain.
#
# The collection is checked first with scripts/check-collection.sh. Only images
# tracked by Git are packaged, so local files and OS metadata such as .DS_Store
# never reach an archive. Packaging stops if any image is still an LFS pointer
# (run `git lfs pull` first), or if an archive would reach GitHub's 2 GiB limit
# for a release asset.
#
# Usage: scripts/package-wallpapers.sh [output-dir]
#   output-dir  defaults to dist/release at the repository root. Archives and
#               SHA256SUMS.txt from an earlier run there are replaced.
#
# Requires git, git-lfs contents, zip, and sha256sum or shasum. Written for the
# bash 3.2 that macOS ships as well as the runner's.

set -euo pipefail

FORMATS="desktops ultrawide dual triple mobile square"
SPLIT_FORMATS="desktops"
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

is_split() {
    case " ${SPLIT_FORMATS} " in *" $1 "*) return 0 ;; esac
    return 1
}

for format in $FORMATS; do
    count=0

    while IFS= read -r -d '' path; do
        if head -c 40 "${ROOT}/${path}" | grep -q '^version https://git-lfs'; then
            fail "Git LFS image has not been downloaded (run git lfs pull): ${path}"
            continue
        fi

        relative="${path#wallpapers/"${format}"/}"
        category="${relative%%/*}"
        name="${relative#*/}"
        if is_split "$format"; then
            archive="wallpapers-${format}-${category}"
            entry="$name"
        else
            archive="wallpapers-${format}"
            entry="${category}_${name}"
        fi

        stage="${STAGE}/${archive}"
        if [ ! -d "$stage" ]; then
            mkdir "$stage"
            cp "${ROOT}/LICENSE" "${stage}/LICENSE.txt"
            printf '%s\n' "$archive" >> "${STAGE}/archives"
        fi
        if grep -qxF -- "  ${path}" "${ROOT}/LICENSE-ORIGINALS" \
            && [ ! -f "${stage}/LICENSE-ORIGINALS.txt" ]; then
            cp "${ROOT}/LICENSE-ORIGINALS" "${stage}/LICENSE-ORIGINALS.txt"
        fi
        ln "${ROOT}/${path}" "${stage}/${entry}" 2> /dev/null \
            || cp -p "${ROOT}/${path}" "${stage}/${entry}"
        count=$((count + 1))
    done < <(git -C "$ROOT" ls-files -z -- "wallpapers/${format}")

    if [ "$count" -eq 0 ]; then
        fail "No tracked images found in wallpapers/${format}"
    fi
done

if [ "$errors" -gt 0 ]; then
    echo "Packaging stopped: ${errors} problem(s) found." >&2
    exit 1
fi

# Replace everything an earlier run left, so a renamed or removed category
# cannot leave a stale archive behind.
rm -f "${OUTPUT_DIR}"/wallpapers-*.zip "${OUTPUT_DIR}/SHA256SUMS.txt"

while IFS= read -r archive; do
    zip_path="${OUTPUT_DIR}/${archive}.zip"
    # -0 stores without compression, -X leaves out OS-specific file attributes,
    # and sorting the list keeps the entry order the same from run to run.
    (
        cd "${STAGE}/${archive}"
        find . -type f | sed 's|^\./||' | LC_ALL=C sort | zip -0 -X -q "$zip_path" -@
    )
    images="$(find "${STAGE}/${archive}" -type f ! -name 'LICENSE*.txt' | wc -l | tr -d ' ')"
    size="$(wc -c < "$zip_path" | tr -d ' ')"
    echo "${archive}.zip: ${images} images, ${size} bytes"
    if [ "$size" -ge "$ASSET_LIMIT" ]; then
        fail "${archive}.zip is ${size} bytes; GitHub release assets must be under 2 GiB"
    fi
done < <(LC_ALL=C sort "${STAGE}/archives")

if command -v sha256sum > /dev/null 2>&1; then
    checksum() { sha256sum "$@"; }
else
    checksum() { shasum -a 256 "$@"; }
fi
(
    cd "$OUTPUT_DIR"
    find . -maxdepth 1 -name 'wallpapers-*.zip' | sed 's|^\./||' | LC_ALL=C sort \
        | while IFS= read -r zip_name; do checksum "$zip_name"; done > SHA256SUMS.txt
)

if [ "$errors" -gt 0 ]; then
    exit 1
fi
