#!/usr/bin/env bash
# Regression tests for scripts/build-site.sh. Each case builds a disposable
# repository holding the build and check scripts, a minimal page, and tiny
# images made with ImageMagick, so nothing is fetched from Git LFS and the real
# collection is never touched.
#
# Requires git, git-lfs, curl, and ImageMagick 6 or 7 with WebP support.
set -euo pipefail

# Inherited Git overrides must not redirect fixture writes into another repo.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
unset SITE_URL SITE_REPOSITORY SITE_REF SITE_JOBS SITE_LFS_LIMIT

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export SITE_REPOSITORY=example/wallpapers

if command -v magick > /dev/null 2>&1; then
    image() { magick "$@"; }
else
    image() { convert "$@"; }
fi

fail() {
    cat "${WORK}/result.log" >&2 2> /dev/null || true
    echo "FAIL: $1" >&2
    exit 1
}

pass() {
    echo "PASS: $1"
}

build() {
    bash scripts/build-site.sh "$@" > "${WORK}/result.log" 2>&1
}

expect_summary() {
    grep -qF -- "$2" "${WORK}/result.log" || fail "$1 (expected \"$2\")"
}

oid_of() {
    git cat-file -p ":$1" | sed -n 's/^oid sha256://p'
}

commit() {
    git add -A
    bash scripts/check-collection.sh --write-readme > /dev/null
    git add README.md
    git -c user.name=Test -c user.email=test@example.com commit --quiet -m "$1"
}

setup_repository() {
    rm -rf "${WORK}/repo"
    mkdir -p "${WORK}/repo/scripts" "${WORK}/repo/site" \
        "${WORK}/repo/wallpapers/desktops/space" "${WORK}/repo/wallpapers/mobile/space"
    cd "${WORK}/repo"
    git init --quiet
    git config core.attributesFile /dev/null
    git lfs install --local > /dev/null
    cp "${ROOT}/scripts/build-site.sh" "${ROOT}/scripts/check-collection.sh" scripts/
    printf 'wallpapers/**/*.png filter=lfs diff=lfs merge=lfs -text\n' > .gitattributes
    printf '<!-- collection-counts:start -->\n<!-- collection-counts:end -->\n' > README.md
    printf '<html>\n  <body>\n    <!-- collection -->\n  </body>\n</html>\n' > site/index.html
    image -size 320x180 gradient:navy-black wallpapers/desktops/space/wide-sky.png
    image -size 90x160 gradient:orange-purple wallpapers/mobile/space/tall-sky.png
    commit 'Add fixtures'
}

setup_repository
build "${WORK}/site" || fail 'a fresh build succeeds'
expect_summary 'a fresh build renders every preview' '2 images: 0 reused, 2 rendered'
wide="$(oid_of wallpapers/desktops/space/wide-sky.png)"
tall="$(oid_of wallpapers/mobile/space/tall-sky.png)"
for oid in "$wide" "$tall"; do
    if [ ! -s "${WORK}/site/previews/${oid}.webp" ] || [ ! -s "${WORK}/site/previews/${oid}-thumb.webp" ]; then
        fail "previews are named after the LFS object ID ${oid}"
    fi
done
if ! grep -qx "${wide}	320	180" "${WORK}/site/previews/manifest.tsv" \
    || ! grep -qx "${tall}	90	160" "${WORK}/site/previews/manifest.tsv"; then
    fail 'the manifest records each image'\''s dimensions'
fi
if ! grep -qF "\"repository\":\"example/wallpapers\",\"ref\":\"$(git rev-parse HEAD)\"" "${WORK}/site/index.html" \
    || ! grep -qF '"path":"wallpapers/mobile/space/tall-sky.png"' "${WORK}/site/index.html" \
    || grep -qF '<!-- collection -->' "${WORK}/site/index.html"; then
    fail 'the page embeds the collection, repository, and commit'
fi
pass 'a fresh build renders previews and embeds the collection'

build "${WORK}/site" || fail 'a rebuild succeeds'
expect_summary 'a rebuild reuses the earlier build' '2 images: 2 reused, 0 rendered'
pass 'a rebuild reuses previews from the output directory'

cp -R "${WORK}/site" "${WORK}/published"
image -size 320x180 gradient:teal-black wallpapers/desktops/space/wide-sky.png
commit 'Change an image'
SITE_URL="file://${WORK}/published" build "${WORK}/site" || fail 'a build from a published site succeeds'
expect_summary 'only the changed image is rendered' '2 images: 1 reused, 1 rendered'
[ ! -e "${WORK}/site/previews/${wide}.webp" ] || fail 'previews of replaced images are dropped'
pass 'a build reuses a published site'"'"'s previews and renders changed images'

image -size 64x64 xc:gray wallpapers/desktops/space/new-sky.png
commit 'Add an image'
new="wallpapers/desktops/space/new-sky.png"
git cat-file -p ":${new}" > "$new"
status=0
SITE_LFS_LIMIT=0 build "${WORK}/site" || status=$?
[ "$status" -ne 0 ] || fail 'a build over the LFS limit fails'
expect_summary 'the LFS limit is reported' 'over the 0 MiB limit'
[ -s "${WORK}/site/previews/${tall}.webp" ] || fail 'a failed build keeps the earlier build'
[ -z "$(find "$WORK" -maxdepth 1 -name '.site-build.*')" ] || fail 'a failed build removes its staging directory'
pass 'a build stops before downloading more than the LFS limit, keeping the earlier build'

mkdir -p "${WORK}/unrelated"
touch "${WORK}/unrelated/keep.txt"
status=0
build "${WORK}/unrelated" || status=$?
if [ "$status" -eq 0 ] || [ ! -f "${WORK}/unrelated/keep.txt" ]; then
    fail 'a directory that is not a build is left alone'
fi
expect_summary 'the refusal is explained' 'is not a site build'
pass 'a build refuses to replace a directory that is not a build'
