#!/usr/bin/env bash
# Regression tests use disposable Git indexes and tiny LFS pointers. They never
# fetch images or stage changes in the real collection.
set -euo pipefail

# Inherited Git overrides must not redirect fixture writes into another repo.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="${ROOT}/scripts/check-collection.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
OID=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PATH_IN_INDEX=wallpapers/desktops/abstract/sample.jpg
case_count=0

index_file() {
  local object
  object="$(git hash-object -w --stdin < "$2")"
  git update-index --add --cacheinfo "${3:-100644}" "$object" "$1"
}

setup_case() {
  case_count=$((case_count + 1))
  mkdir "${WORK}/case-${case_count}"
  cd "${WORK}/case-${case_count}"
  git init --quiet
  git config core.attributesFile /dev/null
  mkdir -p wallpapers/desktops/abstract
  printf 'wallpapers/**/*.jpg filter=lfs diff=lfs merge=lfs -text\n' > .gitattributes
  printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%s\nsize 1\n' "$OID" > "$PATH_IN_INDEX"
  index_file .gitattributes .gitattributes
  index_file "$PATH_IN_INDEX" "$PATH_IN_INDEX"
  if [ -f "${WORK}/README.md" ]; then
    cp "${WORK}/README.md" README.md
  else
    printf '<!-- collection-counts:start -->\n<!-- collection-counts:end -->\n' > README.md
    bash "$CHECK" --write-readme > "${WORK}/setup.log" 2>&1
    cp README.md "${WORK}/README.md"
  fi
}

expect_success() {
  if ! bash "$CHECK" > "${WORK}/result.log" 2>&1; then
    cat "${WORK}/result.log" >&2
    echo "FAIL: $1" >&2
    exit 1
  fi
  echo "PASS: $1"
}

expect_failure() {
  local status=0
  bash "$CHECK" "${3:-}" > "${WORK}/result.log" 2>&1 || status=$?
  if [ "$status" -ne 1 ] || ! grep -qF -- "$2" "${WORK}/result.log" \
    || grep -qF 'fatal:' "${WORK}/result.log"; then
    cat "${WORK}/result.log" >&2
    echo "FAIL: $1 (exit ${status})" >&2
    exit 1
  fi
  echo "PASS: $1"
}

setup_case
expect_success 'canonical pointers pass without downloaded images'
if [ -d .git/lfs/objects ] && [ -n "$(find .git/lfs/objects -type f -print)" ]; then
  echo 'FAIL: validation created LFS image objects' >&2
  exit 1
fi

for kind in short-oid long-oid nonhex-oid missing-version wrong-version missing-size invalid-size negative-size oversized-size extra-line missing-newline; do
  setup_case
  case "$kind" in
    short-oid) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:a\n' ;;
    long-oid) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%sa\nsize 1\n' "$OID" ;;
    nonhex-oid) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:g%s\nsize 1\n' "${OID:1}" ;;
    missing-version) printf 'oid sha256:%s\nsize 1\n' "$OID" ;;
    wrong-version) printf 'version https://example.com/spec/v1\noid sha256:%s\nsize 1\n' "$OID" ;;
    missing-size) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%s\n' "$OID" ;;
    invalid-size) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%s\nsize nope\n' "$OID" ;;
    negative-size) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%s\nsize -1\n' "$OID" ;;
    oversized-size) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%s\nsize 999999999999999999999\n' "$OID" ;;
    extra-line) cat "$PATH_IN_INDEX"; printf 'unexpected data\n' ;;
    missing-newline) printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%s\nsize 1' "$OID" ;;
  esac > bad-pointer
  index_file "$PATH_IN_INDEX" bad-pointer
  expect_failure "reject ${kind}" 'Not a valid canonical Git LFS pointer in the index'
done

setup_case
git update-index --force-remove .gitattributes
expect_failure 'working-tree attributes cannot hide missing indexed rules' 'Indexed attributes do not set filter=lfs'

setup_case
printf '' > .gitattributes
expect_success 'indexed attributes apply despite unstaged attribute changes'

setup_case
printf 'wallpapers/**/*.jpg filter=lfs\n%s !filter\n' "$PATH_IN_INDEX" > narrowed-attributes
index_file .gitattributes narrowed-attributes
expect_failure 'reject narrowed indexed LFS rules' 'Indexed attributes do not set filter=lfs'

for name in $'bad\nname.jpg' $'bad\tname.jpg' bad_name.jpg; do
  setup_case
  index_file "wallpapers/desktops/abstract/${name}" "$PATH_IN_INDEX"
  message='Filename is not lowercase'
  if [ "$name" = bad_name.jpg ]; then message='Underscores separate theme prefixes'; fi
  expect_failure 'reject malformed filenames without corrupting scratch records' "$message"
done

setup_case
git update-index --force-remove "$PATH_IN_INDEX"
index_file $'wallpapers/desktops/abstract/bad\nname.jpg' wallpapers/desktops/abstract/sample.jpg
expect_failure 'report an invalid-only collection cleanly' 'Filename is not lowercase'

setup_case
printf 'version https://git-lfs.github.com/spec/v1\noid sha256:a\n' > "$PATH_IN_INDEX"
expect_failure 'reject malformed working-tree pointers even with a valid index' 'Invalid Git LFS pointer in the working tree'

setup_case
index_file wallpapers/desktops/abstract/duplicate.jpg "$PATH_IN_INDEX"
expect_failure 'exact duplicates remain rejected' 'Identical images:'

setup_case
index_file Example.md "$PATH_IN_INDEX"
index_file example.md "$PATH_IN_INDEX"
expect_failure 'case-insensitive collisions remain rejected' 'Paths differ only by letter case'

setup_case
object="$(git hash-object -w --stdin < "$PATH_IN_INDEX")"
printf '100644 %s 2\twallpapers/desktops/abstract/conflict.jpg\n' "$object" | git update-index --index-info
expect_failure 'reject unresolved index stages explicitly' 'Unmerged Git index entry:'

setup_case
printf 'version https://git-lfs.github.com/spec/v1\noid sha256:a\n' > bad-pointer
index_file "$PATH_IN_INDEX" bad-pointer
printf '<!-- collection-counts:start -->\nstale table\n<!-- collection-counts:end -->\n' > README.md
cp README.md before-readme
expect_failure 'failed validation must not rewrite the README' 'Not a valid canonical Git LFS pointer in the index' --write-readme
cmp -s README.md before-readme

setup_case
printf 'Header\n\n  %s\n' "$PATH_IN_INDEX" > originals
index_file LICENSE-ORIGINALS originals
expect_success 'LICENSE-ORIGINALS may list indexed wallpapers'

setup_case
printf 'Header\n\n  wallpapers/desktops/abstract/renamed.jpg\n' > originals
index_file LICENSE-ORIGINALS originals
expect_failure 'reject LICENSE-ORIGINALS paths missing from the index' 'LICENSE-ORIGINALS lists a path that is not a valid wallpaper'

echo "Collection regression tests passed: ${case_count} cases."
