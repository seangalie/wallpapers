#!/usr/bin/env bash
# Checks the wallpaper collection against docs/ORGANIZATION.md and keeps the
# README's collection table in step with it.
#
# Everything is read from the Git index, so a checkout holding only LFS pointer
# files -- as CI's does -- is checked as fully as one with the images: layout,
# formats, categories, filenames, LFS tracking, case-insensitive collisions,
# and exact duplicates (the SHA-256 recorded in each LFS pointer is the image's
# own hash). When an image's contents are present and file(1) is available, its
# contents are also checked against its extension.
#
# Usage: scripts/check-collection.sh [--write-readme]
#   --write-readme  rewrite the README's generated table instead of failing
#                   when it is out of date
#
# Written for the bash 3.2 that macOS ships as well as the runner's.

set -euo pipefail

# Keep these in step with docs/ORGANIZATION.md.
FORMATS="desktops ultrawide dual triple mobile square"
CATEGORIES="abstract art cars fantasy gaming history inspiration minimal music
original outdoors pop-culture retro science scifi space star-trek star-wars tech
themes urban"

# Lowercase words joined by hyphens; one underscore separates a theme prefix
# from the image name, in themes/ only. .jpg rather than .jpeg.
NAME_PATTERN='^[a-z0-9]+(-[a-z0-9]+)*(_[a-z0-9]+(-[a-z0-9]+)*)?\.(jpg|png|webp|gif|avif)$'

README_START='<!-- collection-counts:start -->'
README_END='<!-- collection-counts:end -->'

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

WRITE_README=false
case "${1:-}" in
  --write-readme) WRITE_README=true ;;
  "") ;;
  *) echo "usage: $0 [--write-readme]" >&2; exit 2 ;;
esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

errors=0

fail() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$1" >&2; else echo "error: $1" >&2; fi
  errors=$((errors + 1))
}

warn() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::warning::$1" >&2; else echo "warning: $1" >&2; fi
}

contains() {
  # contains WORD LIST
  case " $(printf '%s' "$2" | tr '\n' ' ') " in *" $1 "*) return 0 ;; esac
  return 1
}

# --- Layout and filenames ---------------------------------------------------

# ls-files -s prints "<mode> <object> <stage>\t<path>", which exposes symlinks
# and submodules without touching the disk.
while IFS= read -r -d '' entry; do
  mode="${entry%% *}"
  rest="${entry#* }"
  object="${rest%% *}"
  path="${entry#*$'\t'}"

  if [ "$mode" != "100644" ] && [ "$mode" != "100755" ]; then
    fail "Expected a regular file: ${path}"
    continue
  fi

  relative="${path#wallpapers/}"
  format="${relative%%/*}"
  remainder="${relative#*/}"
  category="${remainder%%/*}"
  name="${remainder#*/}"
  if [ "$format" = "$relative" ] || [ "$category" = "$remainder" ] || [ "$name" != "${name##*/}" ]; then
    fail "Expected wallpapers/<format>/<category>/<filename>: ${path}"
    continue
  fi

  if ! contains "$format" "$FORMATS"; then
    fail "Unknown display format '${format}': ${path}"
    continue
  fi
  if ! contains "$category" "$CATEGORIES"; then
    fail "Unknown category '${category}': ${path}"
    continue
  fi

  if ! [[ "$name" =~ $NAME_PATTERN ]]; then
    fail "Filename is not lowercase, hyphenated, and .jpg/.png/.webp/.gif/.avif: ${path}"
  elif [ "$category" != "themes" ] && [ "$name" != "${name#*_}" ]; then
    fail "Underscores separate theme prefixes, in themes/ only: ${path}"
  fi

  printf '%s %s\n' "$object" "$path" >> "${WORK}/objects"
  printf '%s\t%s\n' "$format" "$category" >> "${WORK}/counts"
done < <(git ls-files -s -z -- wallpapers)

if [ ! -s "${WORK}/objects" ]; then
  fail "No wallpapers are tracked under wallpapers/"
  exit 1
fi

# Names that differ only by letter case collide on macOS and Windows.
git ls-files | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort | uniq -d > "${WORK}/collisions"
while IFS= read -r path; do
  fail "Paths differ only by letter case: ${path}"
done < "${WORK}/collisions"

# --- Git LFS ----------------------------------------------------------------

# An LFS pointer is a small text blob. Anything larger was committed directly
# to Git, which .gitattributes is meant to prevent; only small blobs are read.
cut -d' ' -f1 "${WORK}/objects" \
  | git cat-file --batch-check='%(objectname) %(objectsize)' > "${WORK}/sizes"
awk '$2 > 1024 { print $1 }' "${WORK}/sizes" > "${WORK}/large"
awk '$2 <= 1024 { print $1 }' "${WORK}/sizes" \
  | git cat-file --batch \
  | LC_ALL=C awk '
      /^[0-9a-f]+ blob [0-9]+$/ { object = $1; next }
      /^oid sha256:[0-9a-f]+$/ { sub(/^oid sha256:/, ""); print object, $0 }
    ' > "${WORK}/pointers"

# Prints "<path>\t<lfs-oid>" for pointers and "<path>\t-" for anything else.
awk '
  FILENAME == ARGV[1] { oid[$1] = $2; next }
  { object = $1; sub(/^[^ ]+ /, ""); print $0 "\t" ((object in oid) ? oid[object] : "-") }
' "${WORK}/pointers" "${WORK}/objects" > "${WORK}/lfs"

while IFS=$'\t' read -r path oid; do
  if [ "$oid" = "-" ]; then
    fail "Not stored in Git LFS (check .gitattributes, then re-add the file): ${path}"
  fi
done < "${WORK}/lfs"

# The same LFS object under two paths is the same image twice.
awk -F'\t' '$2 != "-" { print $2 "\t" $1 }' "${WORK}/lfs" | LC_ALL=C sort > "${WORK}/by-oid"
awk -F'\t' '
  $1 == previous { group = group ", " $2; repeated = 1; next }
  { if (repeated) print group; previous = $1; group = $2; repeated = 0 }
  END { if (repeated) print group }
' "${WORK}/by-oid" > "${WORK}/duplicates"
while IFS= read -r group; do
  fail "Identical images: ${group}"
done < "${WORK}/duplicates"

# --- Contents, when they are present ----------------------------------------

pointers_only=0
if command -v file > /dev/null 2>&1; then
  while IFS=$'\t' read -r path _; do
    [ -f "$path" ] || continue
    if head -c 40 "$path" | grep -q '^version https://git-lfs'; then
      pointers_only=$((pointers_only + 1))
      continue
    fi
    detected="$(file --brief --mime-type -- "$path")"
    case "${path##*.}:${detected}" in
      jpg:image/jpeg | png:image/png | webp:image/webp | gif:image/gif | avif:image/avif) ;;
      *) fail "${path} contains ${detected}, not what its extension says" ;;
    esac
  done < "${WORK}/lfs"
  if [ "$pointers_only" -gt 0 ]; then
    echo "${pointers_only} images are LFS pointers in this checkout; their contents were not checked."
  fi
else
  warn "file(1) is not installed; image contents were not checked against their extensions."
fi

# --- README table -----------------------------------------------------------

title() {
  printf '%s' "$1" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }'
}

thousands() {
  printf '%s' "$1" | awk '{ n = $0; s = ""; while (length(n) > 3) { s = "," substr(n, length(n) - 2) s; n = substr(n, 1, length(n) - 3) }; print n s }'
}

count_of() {
  # count_of FORMAT CATEGORY (either may be "*")
  awk -F'\t' -v f="$1" -v c="$2" '(f == "*" || $1 == f) && (c == "*" || $2 == c) { n++ } END { print n + 0 }' "${WORK}/counts"
}

{
  total="$(count_of '*' '*')"
  echo "$README_START"
  echo "<!-- Generated by scripts/check-collection.sh --write-readme; do not edit by hand. -->"
  echo
  echo "The collection contains **$(thousands "$total") images**. Select a count to open that folder."
  echo
  header="| Category |"
  rule="| --- |"
  for format in $FORMATS; do
    header="${header} [$(title "$format")](wallpapers/${format}/) |"
    rule="${rule} ---: |"
  done
  echo "${header} Total |"
  echo "${rule} ---: |"
  for category in $CATEGORIES; do
    row_total="$(count_of '*' "$category")"
    [ "$row_total" -eq 0 ] && continue
    row="| \`${category}\` |"
    for format in $FORMATS; do
      n="$(count_of "$format" "$category")"
      if [ "$n" -eq 0 ]; then
        row="${row} — |"
      else
        row="${row} [${n}](wallpapers/${format}/${category}/) |"
      fi
    done
    echo "${row} ${row_total} |"
  done
  row="| **Total** |"
  for format in $FORMATS; do
    row="${row} **$(thousands "$(count_of "$format" '*')")** |"
  done
  echo "${row} **$(thousands "$total")** |"
  echo "$README_END"
} > "${WORK}/table"

if ! grep -qxF -- "$README_START" README.md || ! grep -qxF -- "$README_END" README.md; then
  fail "README.md is missing the ${README_START} and ${README_END} markers"
else
  awk -v start="$README_START" -v end="$README_END" -v table="${WORK}/table" '
    $0 == start { while ((getline line < table) > 0) print line; skipping = 1; next }
    $0 == end { skipping = 0; next }
    !skipping { print }
  ' README.md > "${WORK}/README.md"
  if ! cmp -s README.md "${WORK}/README.md"; then
    if [ "$WRITE_README" = true ]; then
      cp "${WORK}/README.md" README.md
      echo "Updated the collection table in README.md."
    else
      fail "README.md's collection table is out of date; run scripts/check-collection.sh --write-readme"
    fi
  fi
fi

if [ "$errors" -gt 0 ]; then
  echo "Collection check failed: ${errors} problem(s) found." >&2
  exit 1
fi
echo "Collection check passed: $(thousands "$(count_of '*' '*')") images."
