#!/usr/bin/env bash
# Builds the browsing site published to GitHub Pages: the page and assets in
# site/, the collection's metadata, and two WebP previews per image, a grid
# thumbnail and a larger lightbox view.
#
# GitHub Pages cannot serve Git LFS files and limits a site to 1 GB, so the
# site carries only previews. Its download links point at each image on
# media.githubusercontent.com, pinned to the commit being built; every
# full-size download there counts against the account's monthly LFS
# bandwidth, but browsing the previews does not.
#
# Rendering a preview needs the image itself, and downloading the whole
# collection from LFS costs about 2.5 GiB of that bandwidth, so previews are
# reused wherever possible. Each preview is named after its image's LFS object
# ID, so an unchanged image keeps its previews. Before rendering, the build
# fetches previews/manifest.tsv from the previous build -- SITE_URL when set,
# otherwise an earlier build in the output directory -- and copies every
# preview whose image is unchanged. Only images left over are downloaded from
# LFS, if their contents are not already in the checkout, and rendered.
# Changing PREVIEW_SETTINGS below renders every preview again.
#
# Usage: scripts/build-site.sh [output-dir]
#   output-dir  defaults to dist/site at the repository root, and is replaced.
#
# Environment:
#   SITE_URL         base URL of the published site to reuse previews from,
#                    such as https://seangalie.github.io/wallpapers
#   SITE_REPOSITORY  owner/name for download links; defaults to
#                    GITHUB_REPOSITORY, then the origin remote
#   SITE_REF         commit for download links; defaults to HEAD
#   SITE_JOBS        previews rendered at once; defaults to the CPU count
#   SITE_LFS_LIMIT   most MiB to download from Git LFS; the build stops before
#                    downloading anything if it needs more. Unset means no limit.
#
# Requires git, git-lfs, curl, and ImageMagick 6 or 7 with WebP support.
# Written for the bash 3.2 that macOS ships as well as the runner's.

set -euo pipefail

# The lightbox view fits within 1920 pixels; site/assets/js/site.js assumes
# that size. The thumbnail fills tiles of any shape: its short side is 600
# pixels and its long side at most 1200, so a triple-monitor panorama keeps
# only its middle. Both shrink, never enlarge.
VIEW_SIZE='1920x1920>'
VIEW_QUALITY=78
THUMB_SIZE='600x600^>'
THUMB_CROP='1200x1200'
THUMB_QUALITY=70
PREVIEW_SETTINGS="view ${VIEW_SIZE} q${VIEW_QUALITY}; thumb ${THUMB_SIZE} crop ${THUMB_CROP} q${THUMB_QUALITY}"

# Renders the previews of one image. Runs in its own process through xargs, so
# it reads everything from its arguments.
render() {
    local dir="$1" oid="$2" path="$3" info width height orientation

    info="$(im identify -quiet -ping -format '%w %h %[orientation]\n' "${path}[0]" | head -n 1)"
    read -r width height orientation <<< "$info"
    # Images that are stored sideways are turned upright below, so report
    # their dimensions upright too.
    case "$orientation" in
        LeftTop | RightTop | RightBottom | LeftBottom)
            info="$width"
            width="$height"
            height="$info"
            ;;
    esac

    im convert -quiet "${path}[0]" -auto-orient -strip \
        \( +clone -resize "$VIEW_SIZE" -quality "$VIEW_QUALITY" -write "${dir}/${oid}.webp" +delete \) \
        -resize "$THUMB_SIZE" -gravity center -crop "${THUMB_CROP}+0+0" +repage \
        -quality "$THUMB_QUALITY" "${dir}/${oid}-thumb.webp"
    printf '%s\t%s\t%s\n' "$oid" "$width" "$height" > "${dir}/${oid}.dims"
}

# im TOOL ARGS runs an ImageMagick tool: `magick tool` in version 7, or the
# tool's own command in version 6.
im() {
    local tool="$1"
    shift
    if command -v magick > /dev/null 2>&1; then
        if [ "$tool" = convert ]; then magick "$@"; else magick "$tool" "$@"; fi
    else
        "$tool" "$@"
    fi
}

if [ "${1:-}" = "--render" ]; then
    shift
    render "$@"
    exit
fi

ROOT="$(git rev-parse --show-toplevel)"
OUTPUT_DIR="${1:-${ROOT}/dist/site}"
cd "$ROOT"

fail() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$1" >&2; else echo "error: $1" >&2; fi
    exit 1
}

warn() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::warning::$1" >&2; else echo "warning: $1" >&2; fi
}

# mebibytes BYTES prints BYTES in MiB with one decimal place.
mebibytes() {
    awk -v bytes="$1" 'BEGIN { printf "%.1f MiB", bytes / 1048576 }'
}

if ! im convert -list format 2> /dev/null | grep -Eq '^ *WEBP\*? +WEBP +rw'; then
    fail "ImageMagick with WebP support is required"
fi

REPOSITORY="${SITE_REPOSITORY:-${GITHUB_REPOSITORY:-}}"
if [ -z "$REPOSITORY" ]; then
    REPOSITORY="$(git remote get-url origin | sed -E 's#^(https://github\.com/|git@github\.com:)##; s#\.git$##')"
fi
if ! printf '%s' "$REPOSITORY" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'; then
    fail "Cannot tell the GitHub repository from \"${REPOSITORY}\"; set SITE_REPOSITORY to owner/name"
fi
REF="$(git rev-parse --verify "${SITE_REF:-HEAD}^{commit}")"
JOBS="${SITE_JOBS:-$(getconf _NPROCESSORS_ONLN 2> /dev/null || echo 2)}"

bash "${ROOT}/scripts/check-collection.sh"

# The site is built in a staging directory beside the output and replaces it
# only once complete, so a failed build leaves an earlier one in place to reuse
# next time. Refuse an output directory that does not look like a build, so a
# mistyped argument cannot delete unrelated files.
PREVIOUS=""
if [ -e "$OUTPUT_DIR" ]; then
    if [ -f "${OUTPUT_DIR}/previews/manifest.tsv" ]; then
        PREVIOUS="$(cd "$OUTPUT_DIR" && pwd)"
    elif [ ! -d "$OUTPUT_DIR" ] || [ -n "$(ls -A "$OUTPUT_DIR")" ]; then
        fail "${OUTPUT_DIR} exists and is not a site build; choose another output directory"
    fi
fi
mkdir -p "$(dirname "$OUTPUT_DIR")"
WORK="$(mktemp -d)"
STAGE="$(mktemp -d "$(dirname "$OUTPUT_DIR")/.site-build.XXXXXX")"
trap 'rm -rf "$WORK" "$STAGE"' EXIT
PREVIEWS="${STAGE}/previews"
mkdir "$PREVIEWS"

# --- The collection ---------------------------------------------------------

# The collection check has already confirmed that every entry is a valid LFS
# pointer with a plain lowercase path, so paths need no quoting below. Each
# pointer lists its oid before its size.
git ls-files -s -- wallpapers | awk -F '\t' '{ split($1, field, " "); print field[2] "\t" $2 }' \
    > "${WORK}/entries"
cut -f 1 "${WORK}/entries" | git cat-file --batch \
    | awk '/^oid sha256:/ { oid = substr($2, 8) } /^size / { print oid "\t" $2 }' \
    > "${WORK}/pointers"
if [ "$(wc -l < "${WORK}/pointers")" -ne "$(wc -l < "${WORK}/entries")" ]; then
    fail "Could not read the LFS pointer of every image"
fi
# images: oid, size in bytes, path
cut -f 2 "${WORK}/entries" | paste "${WORK}/pointers" - > "${WORK}/images"
total="$(wc -l < "${WORK}/images" | tr -d ' ')"

# --- Reuse previews ---------------------------------------------------------

if [ -n "${SITE_URL:-}" ]; then
    source_url="${SITE_URL%/}"
elif [ -n "$PREVIOUS" ]; then
    source_url="file://${PREVIOUS}"
else
    source_url=""
fi

: > "${WORK}/previous.tsv"
if [ -n "$source_url" ]; then
    status="$(curl -sS --retry 3 -o "${WORK}/previous.tsv" -w '%{http_code}' \
        "${source_url}/previews/manifest.tsv")" || status="failed"
    case "$status" in
        # curl reports 000 for a file:// URL that exists.
        200 | 000) ;;
        404)
            warn "No previews are published at ${source_url} yet, so every preview will be rendered"
            : > "${WORK}/previous.tsv"
            ;;
        *)
            # Rendering everything instead would quietly spend the collection's
            # size in LFS bandwidth, so stop and let someone look.
            fail "Could not fetch ${source_url}/previews/manifest.tsv (${status})"
            ;;
    esac
    if [ -s "${WORK}/previous.tsv" ] \
        && [ "$(head -n 1 "${WORK}/previous.tsv")" != "# ${PREVIEW_SETTINGS}" ]; then
        warn "The preview settings have changed, so every preview will be rendered"
        : > "${WORK}/previous.tsv"
    fi
fi

# Download every reusable preview in one parallel curl run. A preview that
# fails to arrive is simply rendered again below.
awk -F '\t' 'FILENAME == ARGV[1] { if (!/^#/) dims[$1] = 1; next } ($1 in dims) { print $1 }' \
    "${WORK}/previous.tsv" "${WORK}/images" > "${WORK}/reusable"
if [ -s "${WORK}/reusable" ]; then
    while IFS= read -r oid; do
        for preview in "${oid}.webp" "${oid}-thumb.webp"; do
            printf 'url = "%s/previews/%s"\noutput = "%s/%s"\n' \
                "$source_url" "$preview" "$PREVIEWS" "$preview"
        done
    done < "${WORK}/reusable" > "${WORK}/curl.conf"
    curl --parallel --parallel-max 16 --fail --silent --show-error --retry 3 \
        --remove-on-error --config "${WORK}/curl.conf" 2> "${WORK}/curl.log" \
        || warn "Some previews could not be reused and will be rendered: $(head -n 1 "${WORK}/curl.log")"
fi

# --- Render the rest --------------------------------------------------------

: > "${WORK}/render"
: > "${WORK}/fetch"
fetch_bytes=0
while IFS="$(printf '\t')" read -r oid size path; do
    if [ -s "${PREVIEWS}/${oid}.webp" ] && [ -s "${PREVIEWS}/${oid}-thumb.webp" ]; then
        continue
    fi
    rm -f "${PREVIEWS}/${oid}.webp" "${PREVIEWS}/${oid}-thumb.webp"
    printf '%s\t%s\n' "$oid" "$path" >> "${WORK}/render"
    if head -c 40 "$path" | grep -q '^version https://git-lfs'; then
        printf '%s\n' "$path" >> "${WORK}/fetch"
        fetch_bytes=$((fetch_bytes + size))
    fi
done < "${WORK}/images"
rendered="$(wc -l < "${WORK}/render" | tr -d ' ')"
fetched="$(wc -l < "${WORK}/fetch" | tr -d ' ')"

if [ -n "${SITE_LFS_LIMIT:-}" ] && [ "$fetch_bytes" -gt $((SITE_LFS_LIMIT * 1048576)) ]; then
    fail "Rendering ${rendered} previews needs $(mebibytes "$fetch_bytes") from Git LFS, over the ${SITE_LFS_LIMIT} MiB limit"
fi

if [ "$fetched" -gt 0 ]; then
    echo "Downloading ${fetched} images ($(mebibytes "$fetch_bytes")) from Git LFS"
    # Batches keep each --include list well under the system's argument limits.
    split -l 200 "${WORK}/fetch" "${WORK}/fetch-batch."
    for batch in "${WORK}"/fetch-batch.*; do
        git lfs pull --include="$(paste -sd , "$batch")" --exclude=""
    done
    while IFS= read -r path; do
        if head -c 40 "$path" | grep -q '^version https://git-lfs'; then
            fail "Git LFS did not download ${path}"
        fi
    done < "${WORK}/fetch"
fi

if [ "$rendered" -gt 0 ]; then
    echo "Rendering previews of ${rendered} images, ${JOBS} at a time"
    tr '\t' '\n' < "${WORK}/render" | tr '\n' '\0' \
        | xargs -0 -n 2 -P "$JOBS" "$BASH" "${ROOT}/scripts/build-site.sh" --render "$PREVIEWS"
fi

# --- Metadata and page ------------------------------------------------------

# dims: oid, width, height for every image, reused or rendered.
{
    grep -v '^#' "${WORK}/previous.tsv" || true
    if [ "$rendered" -gt 0 ]; then cat "${PREVIEWS}"/*.dims; fi
} | awk -F '\t' '!seen[$1]++' > "${WORK}/dims"
rm -f "${PREVIEWS}"/*.dims

{
    printf '# %s\n' "$PREVIEW_SETTINGS"
    awk -F '\t' 'FILENAME == ARGV[1] { dims[$1] = $2 "\t" $3; next } { print $1 "\t" dims[$1] }' \
        "${WORK}/dims" "${WORK}/images"
} > "${PREVIEWS}/manifest.tsv"

missing="$(awk -F '\t' '!/^#/ && $2 == "" { print $1 }' "${PREVIEWS}/manifest.tsv")"
while IFS= read -r oid; do
    [ -n "$oid" ] || continue
    fail "No dimensions recorded for LFS object ${oid}"
done <<< "$missing"
while IFS="$(printf '\t')" read -r oid size path; do
    for preview in "${oid}.webp" "${oid}-thumb.webp"; do
        [ -s "${PREVIEWS}/${preview}" ] || fail "Preview ${preview} of ${path} is missing"
    done
done < "${WORK}/images"

# The page reads the collection from JSON embedded in index.html, so it works
# without a server and needs no second request.
awk -F '\t' -v repository="$REPOSITORY" -v ref="$REF" '
    FILENAME == ARGV[1] { dims[$1] = $2 "\t" $3; next }
    FNR == 1 {
        printf "{\"repository\":\"%s\",\"ref\":\"%s\",\"images\":[", repository, ref
    }
    {
        split(dims[$1], size, "\t")
        printf "%s\n{\"path\":\"%s\",\"oid\":\"%s\",\"bytes\":%s,\"width\":%s,\"height\":%s}", \
            (FNR > 1 ? "," : ""), $3, $1, $2, size[1], size[2]
    }
    END { print "]}" }' "${WORK}/dims" "${WORK}/images" > "${WORK}/collection.json"

git ls-files -z -- site | while IFS= read -r -d '' file; do
    target="${STAGE}/${file#site/}"
    mkdir -p "$(dirname "$target")"
    cp "$file" "$target"
done
grep -q '^ *<!-- collection -->$' "${STAGE}/index.html" \
    || fail "site/index.html has no <!-- collection --> line to replace"
awk -v data="${WORK}/collection.json" '
    /^ *<!-- collection -->$/ {
        print "<script type=\"application/json\" id=\"collection\">"
        while ((getline line < data) > 0) print line
        print "</script>"
        next
    }
    { print }' "${STAGE}/index.html" > "${WORK}/index.html"
mv "${WORK}/index.html" "${STAGE}/index.html"

# mktemp creates the stage private to its owner; a published site is not.
chmod 755 "$STAGE"
rm -rf "$OUTPUT_DIR"
mv "$STAGE" "$OUTPUT_DIR"

reused=$((total - rendered))
summary="Built the site for ${total} images: ${reused} reused, ${rendered} rendered, ${fetched} downloaded from Git LFS ($(mebibytes "$fetch_bytes")). Site size: $(du -sh "$OUTPUT_DIR" | cut -f 1)."
echo "$summary"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "$summary" >> "$GITHUB_STEP_SUMMARY"
fi
