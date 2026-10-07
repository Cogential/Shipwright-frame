# Ship of Harkinian on the Steam Frame

This fork adds a native **aarch64 Linux** build of Ship of Harkinian 9.3.0 for Valve's Steam Frame
(Snapdragon 8 Gen 3, SteamOS on Arm). Running natively avoids FEX x86 emulation. It follows the
2 Ship 2 Harkinian Frame port (`Cogential/2ship2harkinian-frame`).

The game runs as a flat window on the headset's virtual screen. You supply your own Ocarina of
Time ROM: no ROM or ROM-derived files are in this repository or its releases.

## What's different from upstream SoH

| Area | Change |
| --- | --- |
| Build | `CMake/toolchains/linux-aarch64.cmake` cross toolchain, `-DSTEAM_FRAME=ON` Snapdragon 8 Gen 3 code generation, `steamframe/build-arm64.sh` |
| Packaging | `steamframe/package-steam-frame.sh` makes `soh-steam-frame-arm64.zip`, an unpacked folder with `run.sh` and the libraries SteamOS lacks in `lib/`. The AppImage is built for the target architecture too |
| CI | `.github/workflows/steam-frame.yml` builds on GitHub's `ubuntu-22.04-arm` runner and publishes releases. Upstream's desktop `generate-builds` only runs on request |
| Runtime | `soh/soh/SteamFrame/` detects the Frame at launch and fills in headset-friendly defaults |
| First launch | On the Frame, ROMs in the data folder are processed with no prompts, and if none is there a message says where to put it. Pop-ups can be answered with the controller |
| Fixes | Linux ROM search looked in the working directory instead of the data folder, and outdated archives were only deleted from the working directory. Both matter when `SHIP_HOME` is set. The menu now sees controllers that connect after launch, and the Frame defaults are saved before SoH's config migrations reload settings from disk; both stopped View from opening the menu |

### Steam Frame behaviour

The Frame is detected from the host's `os-release` (`/run/host/os-release` inside Steam Linux
Runtime, otherwise `/etc/os-release`): aarch64 with `ID=steamos`/`holo` or `VARIANT_ID=vr`.
`run.sh` also sets `SOH_STEAM_FRAME=1`. Set `SOH_STEAM_FRAME=0` to turn the Frame behaviour off, or
`SOH_STEAM_FRAME=1` to try it on a desktop.

These defaults are filled in only for settings you haven't already changed:

| Setting | Frame default | Why |
| --- | --- | --- |
| Controller menu navigation | On | No keyboard or mouse in the headset; **View** (Back) opens the menu |
| Allow multi-windows | Off | One virtual screen, so pop-out windows stay inside it |
| UI scale | 150% | Readable on a virtual screen a few metres away |
| VSync | On | Avoids tearing |
| Fullscreen | On, 1920x1080 backbuffer | libultraship only goes fullscreen by itself on `VARIANT_ID=steamdeck`; otherwise gamescope stretches a 640x480 window |

On the Frame, pop-ups also switch on controller navigation while they're showing and focus their
first button, so **A** answers them. Upstream only allows controller navigation while the menu is
open.

Text-to-speech (eSpeak) isn't included in the Frame build: the Frame has no eSpeak library or voice
data.

## Installing on the Frame

The release zip unpacks to `soh-steam-frame/`:

```
soh-steam-frame/
  run.sh                  start this, not soh.elf
  soh.elf
  lib/                    SDL2, SDL2_net, libzip, tinyxml2, spdlog, fmt, opusfile, opus
  soh.o2r
  assets/                 extractor configuration (no game data)
  gamecontrollerdb.txt
  README-steam-frame.txt
```

1. Copy the folder to the Frame, e.g. `~/devkit-game/soh/`. Steam shortcut ids must not start with
   a digit.
2. Put your ROM (`.z64`) in that folder, or straight into `~/.local/share/soh/`.
3. Register `run.sh` with Steam (`~/devkit-utils/steam-client-create-shortcut`, FrameDrop, or **Add
   a Non-Steam Game**).
4. Launch it. The first launch builds `oot.o2r` from the ROM with no prompts and then starts the
   game. This only happens once.

`run.sh` changes to its own folder, restores the executable bit (FrameDrop's Windows unzip drops it),
sets `SHIP_HOME=$HOME/.local/share/soh` so saves, settings and `oot.o2r` survive reinstalls, and
copies any `.z64` next to it into `SHIP_HOME` until `oot.o2r` exists.

The game runs inside Steam Linux Runtime 4.0 (arm64), which has no FUSE, so use the zip rather than
the AppImage there.

### Personal bundle

`steamframe/make-personal-bundle.sh --rom <your.z64> [--zip soh-steam-frame-arm64.zip]` unpacks the
release and adds your ROM, giving a folder that's ready to copy to the Frame. Keep it on your own
devices and never upload it.

## Building

### Natively on Arm64

```sh
git submodule update --init --recursive
INSTALL_DEPS=1 steamframe/build-arm64.sh --native
steamframe/package-steam-frame.sh build-steamframe
```

### Cross-compiling from x86_64 Ubuntu 24.04

Restrict the default apt sources to amd64 and add `ports.ubuntu.com` for arm64:

```sh
sudo sed -i 's|^Types: deb$|Types: deb\nArchitectures: amd64|' /etc/apt/sources.list.d/ubuntu.sources
sudo tee /etc/apt/sources.list.d/ubuntu-ports-arm64.sources <<'EOF'
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates noble-security
Components: main universe restricted multiverse
Architectures: arm64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
INSTALL_DEPS=1 steamframe/build-arm64.sh
```

The build makes `soh.o2r` with its own `soh-o2r-packer` tool. A cross build runs that aarch64 tool
through `qemu-user`, which the toolchain file sets as the cross-compiling emulator, so install
`qemu-user` (the script does with `INSTALL_DEPS=1`).

With `qemu-user` installed you can smoke-test the arm64 binary on the host:
`qemu-aarch64 -L /usr/aarch64-linux-gnu build-steamframe/soh/soh.elf`.

## Releases

Run the **steam-frame** workflow by hand with `release_tag` set (e.g. `frame-v0.1.1`), or push a
`frame-v*` tag. It publishes a pre-release with `soh-steam-frame-arm64.zip`, the AppImage and these
notes.
