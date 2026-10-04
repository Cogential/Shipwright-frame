#!/usr/bin/env bash
# Builds Ship of Harkinian for the Steam Frame (aarch64 Linux).
#
#   steamframe/build-arm64.sh            # cross-compile from an x86_64 Debian/Ubuntu host
#   steamframe/build-arm64.sh --native   # build on an aarch64 machine (Arm Linux box, Frame dev container)
#
# Set INSTALL_DEPS=1 to have the script install the Ubuntu packages it needs (uses sudo, and for a
# cross build adds the arm64 architecture to apt). Output ends up in build-steamframe/; package it
# with steamframe/package-steam-frame.sh build-steamframe.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build-steamframe}"
NATIVE=0
[[ "${1:-}" == "--native" ]] && NATIVE=1

DEV_PKGS="libusb-1.0-0-dev libsdl2-dev libsdl2-net-dev libpng-dev libglew-dev libtinyxml2-dev libspdlog-dev
          libogg-dev libopus-dev libopusfile-dev libvorbis-dev libzip-dev libopengl-dev libbz2-dev zlib1g-dev"

if [[ "${INSTALL_DEPS:-0}" == "1" ]]; then
    if [[ $NATIVE == 1 ]]; then
        sudo apt-get update
        sudo apt-get install -y gcc g++ git cmake ninja-build python3 lsb-release nlohmann-json3-dev zipcmp zipmerge ziptool \
            patchelf zip $DEV_PKGS
    else
        # Ubuntu serves arm64 from ports.ubuntu.com; see docs/STEAM_FRAME.md for the apt sources.
        sudo dpkg --add-architecture arm64
        sudo apt-get update
        sudo apt-get install -y crossbuild-essential-arm64 git cmake ninja-build python3 lsb-release nlohmann-json3-dev \
            patchelf zip $(for p in $DEV_PKGS; do printf '%s:arm64 ' "$p"; done)
    fi
fi

# Text-to-speech is left out: the Frame has no eSpeak or voice data.
CMAKE_ARGS=(-S "$ROOT" -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release -DSTEAM_FRAME=ON -DESPEAK=ESPEAK-NOTFOUND
            -DBUILD_REMOTE_CONTROL=1)
if [[ $NATIVE == 0 ]]; then
    CMAKE_ARGS+=(-DCMAKE_TOOLCHAIN_FILE="$ROOT/CMake/toolchains/linux-aarch64.cmake")
fi

cmake "${CMAKE_ARGS[@]}"

if [[ $NATIVE == 1 ]]; then
    cmake --build "$BUILD_DIR" --target GenerateSohOtr
elif [[ ! -f "$BUILD_DIR/soh/soh.o2r" ]]; then
    # soh.o2r is architecture independent but is produced by running ZAPD, which a cross build
    # makes for aarch64. Build it with any host (x86_64) build and copy it over.
    echo "note: copy a soh.o2r from a host build into $BUILD_DIR/soh/ (cmake --build build --target GenerateSohOtr)"
fi

cmake --build "$BUILD_DIR"
echo "Built $BUILD_DIR/soh/soh.elf"
