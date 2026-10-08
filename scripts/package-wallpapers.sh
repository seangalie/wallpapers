#!/usr/bin/env bash
# Packages the tracked wallpapers into flat ZIP archives for release downloads.
#
# Every display format becomes one archive, wallpapers-<format>.zip, or
# numbered parts of one as described below, with each image at the root named
# <category>_<filename>: so
# wallpapers/dual/gaming/firewatch-tower-left-panel.jpg becomes
# gaming_firewatch-tower-left-panel.jpg in wallpapers-dual.zip.
#
# Formats listed in SPLIT_FORMATS are large, so they also get one archive per
# category, wallpapers-<format>-<category>.zip, with each image at the root
# under its own filename: so wallpapers/desktops/space/galaxy-m82.jpg becomes
# galaxy-m82.jpg in wallpapers-desktops-space.zip.
#
# GitHub's 2 GiB limit below cannot be raised, so formats listed in
# PART_FORMATS have their full archive split into numbered parts,
# wallpapers-<format>-part-<n>.zip, instead of one wallpapers-<format>.zip.
# Entries keep the <category>_<filename> naming, and each category stays whole
# in one part: categories are taken in alphabetical order and shared between
# as few parts as keeps each near PART_TARGET or below, so space_galaxy-m82.jpg
# lands in a later part than abstract_ images. Adding images can move a
# category to a neighboring part, or add a part.
#
# Every archive also carries the repository's LICENSE as LICENSE.txt, so the
# image rights notice travels with the downloads. An archive holding any image
# listed in LICENSE-ORIGINALS also carries that file as LICENSE-ORIGINALS.txt,
# because those images are licensed under its CC BY-NC 4.0 terms.
# SHA256SUMS.txt lists a checksum for each archive. Images are stored, not
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
#   output-dir  defaults to dist/release at the repository root. Archives and
#               SHA256SUMS.txt from an earlier run there are replaced.
#
# Requires git, git-lfs contents, zip, and sha256sum or shasum. Written for the
# bash 3.2 that macOS ships as well as the runner's.

set -euo pipefail

FORMATS="desktops ultrawide dual triple mobile square"
SPLIT_FORMATS="desktops"
PART_FORMATS="desktops"
PART_TARGET=1610612736 # 1.5 GiB, leaving room to grow before the limit
ASSET_LIMIT=2147483648 # 2 GiB

ROOT="$(git rev-parse --show-toplevel)"
OUTPUT_DIR="${1:-${ROOT}/dist/release}"

bash "${ROOT}/scripts/check-collection.sh"

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# Staged beside the output so the links below usually stay on one filesystem;
# when they cannot, the file is copied instead.
STAGE="$(mktemp -d "${OUTPUT_DIR}/.stage.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

# On macOS, stage images as APFS clones, falling back to a plain copy where
# cloning is unavailable, such as on a non-APFS volume. Never hard-link there:
# a hard link updates the image's ctime, so Git would re-hash the whole
# collection through the LFS filter, and an editor's background `git status`
# doing that can leave .git/index.lock behind. Elsewhere, hard links are cheap
# and nothing is watching the checkout. GNU cp gives -c a different meaning, so
# check the platform rather than trying it.
CLONE=false
if [ "$(uname -s)" = "Darwin" ]; then
    CLONE=true
fi

errors=0

fail() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$1" >&2; else echo "error: $1" >&2; fi
    errors=$((errors + 1))
}

is_split() {
    case " ${SPLIT_FORMATS} " in *" $1 "*) return 0 ;; esac
    return 1
}

is_parted() {
    case " ${PART_FORMATS} " in *" $1 "*) return 0 ;; esac
    return 1
}

# add_to_archive ARCHIVE ENTRY PATH stages the image at PATH as ENTRY in
# ARCHIVE, creating the archive's stage with its license files on first use.
add_to_archive() {
    local stage="${STAGE}/$1"
    if [ ! -d "$stage" ]; then
        mkdir "$stage"
        cp "${ROOT}/LICENSE" "${stage}/LICENSE.txt"
        printf '%s\n' "$1" >> "${STAGE}/archives"
    fi
    if grep -qxF -- "  $3" "${ROOT}/LICENSE-ORIGINALS" \
        && [ ! -f "${stage}/LICENSE-ORIGINALS.txt" ]; then
        cp "${ROOT}/LICENSE-ORIGINALS" "${stage}/LICENSE-ORIGINALS.txt"
    fi
    if [ "$CLONE" = true ]; then
        cp -c -p "${ROOT}/$3" "${stage}/$2" 2> /dev/null \
            || cp -p "${ROOT}/$3" "${stage}/$2"
    else
        ln "${ROOT}/$3" "${stage}/$2" 2> /dev/null \
            || cp -p "${ROOT}/$3" "${stage}/$2"
    fi
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
        if is_parted "$format"; then
            # Parts are assigned below, once every category's size is known.
            size="$(wc -c < "${ROOT}/${path}" | tr -d ' ')"
            printf '%s\t%s\t%s\n' "$category" "$size" "$path" >> "${STAGE}/${format}.parts"
        else
            add_to_archive "wallpapers-${format}" "${category}_${name}" "$path"
        fi
        if is_split "$format"; then
            add_to_archive "wallpapers-${format}-${category}" "$name" "$path"
        fi
        count=$((count + 1))
    done < <(git -C "$ROOT" ls-files -z -- "wallpapers/${format}")

    if [ "$count" -eq 0 ]; then
        fail "No tracked images found in wallpapers/${format}"
    fi
done

for format in $PART_FORMATS; do
    [ -f "${STAGE}/${format}.parts" ] || continue
    # Use the fewest parts that keep an even share at or under PART_TARGET.
    # Each category goes to the part where its midpoint falls, so the parts
    # come out close to that share while keeping categories whole. The list is
    # in Git's path order, so categories arrive alphabetically.
    while IFS="$(printf '\t')" read -r part category path; do
        add_to_archive "wallpapers-${format}-part-${part}" \
            "${category}_${path#wallpapers/"${format}"/"${category}"/}" "$path"
    done < <(awk -F '\t' -v target="$PART_TARGET" '
        {
            if (!($1 in size)) order[++categories] = $1
            size[$1] += $2
            total += $2
            line[NR] = $0
        }
        END {
            parts = int((total + target - 1) / target)
            if (parts < 1) parts = 1
            share = total / parts
            before = 0
            for (i = 1; i <= categories; i++) {
                part = int((before + size[order[i]] / 2) / share) + 1
                if (part > parts) part = parts
                part_of[order[i]] = part
                before += size[order[i]]
            }
            for (i = 1; i <= NR; i++) {
                split(line[i], field, "\t")
                print part_of[field[1]] "\t" field[1] "\t" field[3]
            }
        }' "${STAGE}/${format}.parts")
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
