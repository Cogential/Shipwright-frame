#!/bin/sh
# Starts Ship of Harkinian on the Steam Frame. This is the program to point Steam or FrameDrop at.
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

# FrameDrop's Windows unzip drops executable bits.
chmod +x "$DIR/soh.elf" 2>/dev/null

# Saves, settings and the oot.o2r built from the ROM live outside the install folder, so they
# survive reinstalls.
export SHIP_HOME="${SHIP_HOME:-$HOME/.local/share/soh}"
mkdir -p "$SHIP_HOME"

# This launcher only ships in the Steam Frame build, so turn on the Frame behaviour even if
# detection can't see the host OS. SOH_STEAM_FRAME=0 in the launch options turns it off.
export SOH_STEAM_FRAME="${SOH_STEAM_FRAME:-1}"

# Hand any ROM shipped next to the game to the data folder until SoH has built its archive.
if [ ! -f "$SHIP_HOME/oot.o2r" ] && [ ! -f "$SHIP_HOME/oot-mq.o2r" ]; then
    for rom in "$DIR"/*.z64 "$DIR"/*.n64 "$DIR"/*.v64; do
        [ -f "$rom" ] && [ ! -e "$SHIP_HOME/$(basename "$rom")" ] && cp "$rom" "$SHIP_HOME/"
    done
fi

exec "$DIR/soh.elf" "$@"
