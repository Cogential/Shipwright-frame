#!/usr/bin/env bash
# Builds a ready-to-install Ship of Harkinian folder for your Steam Frame from the release zip and
# your own ROM. Run it on your own computer.
#
#   steamframe/make-personal-bundle.sh --rom <your .z64> [--rom <another .z64>] [--zip <file>] [--out <dir>]
#
#   --rom   Your Ocarina of Time ROM; repeat for a Master Quest ROM too. Required.
#   --zip   soh-steam-frame-arm64.zip from the GitHub release. If omitted, the script tries
#           `gh release download` for the newest frame-v* release.
#   --out   Output folder (default: ./soh-frame-bundle). A .tar.gz of it is written next to it.
#
# On first launch run.sh hands the ROM to ~/.local/share/soh and the game builds oot.o2r from it
# by itself. The bundle holds your personal copy of the game: keep it on your own devices and
# never upload it to GitHub, including as a release asset.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="Cogential/shipwright-frame"
ZIP_NAME="soh-steam-frame-arm64.zip"
ROMS=() ZIP="" OUT="$PWD/soh-frame-bundle"

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
die() { echo "error: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rom) ROMS+=("$2"); shift 2 ;;
        --zip) ZIP="$2"; shift 2 ;;
        --out) OUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "unknown option: $1" >&2; usage 1 ;;
    esac
done

[[ ${#ROMS[@]} -gt 0 ]] || { echo "error: --rom is required" >&2; usage 1; }

sha1() {
    if command -v sha1sum >/dev/null; then sha1sum "$1" | cut -d' ' -f1; else shasum -a 1 "$1" | cut -d' ' -f1; fi
}

# Only ROMs SoH can extract are accepted; the list lives in docs/supportedHashes.json.
for rom in "${ROMS[@]}"; do
    [[ -f "$rom" ]] || die "ROM not found: $rom"
    hash="$(sha1 "$rom")"
    grep -qi "\"$hash\"" "$ROOT/docs/supportedHashes.json" ||
        die "$rom (SHA-1 $hash) isn't a supported version (see docs/supportedHashes.json)"
    echo "ROM ok: $(basename "$rom") ($hash)"
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
if [[ -z "$ZIP" ]]; then
    command -v gh >/dev/null || die "pass --zip, or install the GitHub CLI (gh) so the script can download it"
    TAG="$(gh release list -R "$REPO" --limit 50 --json tagName -q '.[].tagName' | grep '^frame-v' | head -n1)"
    [[ -n "$TAG" ]] || die "no frame-v* release found in $REPO"
    echo "Downloading $ZIP_NAME from $TAG"
    gh release download "$TAG" -R "$REPO" -p "$ZIP_NAME" -D "$TMP"
    ZIP="$TMP/$ZIP_NAME"
fi
[[ -f "$ZIP" ]] || die "zip not found: $ZIP"

rm -rf "$OUT"
unzip -q "$ZIP" -d "$TMP/unpacked"
mv "$TMP/unpacked/soh-steam-frame" "$OUT"
chmod +x "$OUT/run.sh" "$OUT/soh.elf"
cp "${ROMS[@]}" "$OUT/"

TARBALL="$OUT.tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo
echo "Bundle: $OUT"
echo "Archive: $TARBALL"
echo "Install it as ~/devkit-game/<id>/ on the Frame and point the shortcut at run.sh."
