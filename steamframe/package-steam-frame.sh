#!/usr/bin/env bash
# Packages an aarch64 build as the Steam Frame zip: an unpacked folder (Steam Linux Runtime 4 has
# no FUSE, so an AppImage alone won't do) with run.sh, soh.elf, the libraries SteamOS lacks in
# lib/, soh.o2r, the extractor assets and gamecontrollerdb.txt. No ROM or ROM-derived files.
#
#   steamframe/package-steam-frame.sh <build-dir> [output.zip]
#
# Libraries are bundled from an explicit list; anything else the binary needs must be on the list
# of libraries SteamOS provides, or packaging fails so the choice is made deliberately.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$(cd "${1:?usage: $0 <build-dir> [output.zip]}" && pwd)"
OUT="$(realpath -m "${2:-$PWD/soh-steam-frame-arm64.zip}")"
NAME=soh-steam-frame

# Libraries SteamOS lacks: bundle these.
BUNDLE='^lib(SDL2-2\.0|SDL2_net-2\.0|zip|tinyxml2|spdlog|fmt|opusfile|opus|samplerate|usb-1\.0|GLEW)\.so'
# Libraries the Frame provides. Never bundle glibc, libstdc++/libgcc_s or graphics/windowing
# libraries: SteamOS's are newer and Mesa needs its own.
SYSTEM='^(ld-linux.*|lib(c|m|dl|pthread|rt|mvec|stdc\+\+|gcc_s|GL|GLX|GLdispatch|OpenGL|EGL|GLESv2|vulkan|X11|X11-xcb|Xext|Xi|Xrandr|Xcursor|Xfixes|Xss|Xxf86vm|xcb|wayland-.*|xkbcommon|decor-0|drm|gbm|z|bz2|png16|ogg|vorbis|vorbisfile|vorbisenc|pulse|pulse-simple|asound|crypto|ssl|lzma|zstd|lz4|udev|dbus-1|systemd|cap|gcrypt|gpg-error))\.so'

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/$NAME"

cmake --install "$BUILD" --prefix "$APP" --component ship >/dev/null
# On Linux the extractor configuration (assets/) is its own component; the in-game ROM extraction needs it.
cmake --install "$BUILD" --prefix "$APP" --component extractor >/dev/null
[[ -f "$APP/soh.elf" ]] || { echo "error: soh.elf missing from the install" >&2; exit 1; }
[[ -d "$APP/assets/xml" ]] || { echo "error: extractor assets missing from the install" >&2; exit 1; }
[[ -f "$APP/soh.o2r" ]] || { echo "error: soh.o2r missing; build the GenerateSohOtr target first" >&2; exit 1; }
# Never package a ROM or anything built from one.
find "$APP" \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' -o -name 'oot.o2r' -o -name 'oot-mq.o2r' \) -delete

machine() { LC_ALL=C readelf -h "$1" | sed -n 's/^ *Machine: *//p'; }
needed() { LC_ALL=C readelf -d "$1" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'; }

ARCH="$(machine "$APP/soh.elf")"
[[ "$ARCH" == AArch64 ]] || { echo "error: soh.elf is $ARCH, not AArch64" >&2; exit 1; }
SEARCH=(/usr/local/lib /usr/local/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu /lib/aarch64-linux-gnu /usr/lib)

find_lib() {
    local dir
    for dir in "${SEARCH[@]}"; do
        if [[ -e "$dir/$1" && "$(machine "$(readlink -f "$dir/$1")")" == AArch64 ]]; then
            echo "$dir/$1"
            return
        fi
    done
    return 1
}

mkdir -p "$APP/lib"
queue=("$APP/soh.elf")
while [[ ${#queue[@]} -gt 0 ]]; do
    elf="${queue[0]}"
    queue=("${queue[@]:1}")
    for lib in $(needed "$elf"); do
        if [[ "$lib" =~ $SYSTEM ]]; then
            continue
        elif [[ "$lib" =~ $BUNDLE ]]; then
            [[ -e "$APP/lib/$lib" ]] && continue
            src="$(find_lib "$lib")" || { echo "error: $lib not found for bundling" >&2; exit 1; }
            cp -L "$src" "$APP/lib/$lib"
            echo "bundled $lib  <- $(readlink -f "$src")"
            queue+=("$APP/lib/$lib")
        else
            echo "error: $(basename "$elf") needs $lib, which is on neither the bundle nor the system list" >&2
            exit 1
        fi
    done
done

patchelf --set-rpath '$ORIGIN/lib' "$APP/soh.elf"
for lib in "$APP"/lib/*.so*; do
    patchelf --set-rpath '$ORIGIN' "$lib"
done

install -m 755 "$ROOT/steamframe/run.sh" "$APP/run.sh"
install -m 644 "$ROOT/steamframe/README-frame.txt" "$APP/README-steam-frame.txt"

rm -f "$OUT"
(cd "$STAGE" && zip -qr -y "$OUT" "$NAME")
echo "Packaged $OUT ($(du -h "$OUT" | cut -f1))"
