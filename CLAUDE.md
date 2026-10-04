# Ship of Harkinian (Shipwright) for the Steam Frame: notes for Claude

**Goal:** a native **ARM64 Linux** build of [Ship of Harkinian](https://github.com/HarbourMasters/Shipwright)
**9.2.3 "Ackbar Delta"** (tag `9.2.3`, commit `cb71e22a79bc5d1f688fa881795bbd93094895fc`) for the owner's **Steam
Frame**, released as a zip they can install. This repo is **private** and starts with only this file.

**Never commit or upload a ROM, `oot.o2r`/`oot-mq.o2r`, or any package that contains one**, even here. ROMs and
personal bundles are made on the owner's laptop.

## First steps (bring in upstream)

This repo has no game code yet. Start from the release tag, on a branch named `steam-frame`:

```sh
git remote add upstream https://github.com/HarbourMasters/Shipwright.git
git fetch upstream tag 9.2.3 --no-tags
git checkout -b steam-frame 9.2.3
git checkout main -- CLAUDE.md && git commit -m "Add CLAUDE.md: the Steam Frame port's brief"
git submodule update --init --recursive
git push -u origin steam-frame
```

(Upstream's history contains `.github/workflows/`; pushing it needs the `workflow` permission, which cloud sessions
have. The owner's laptop `gh` login doesn't, which is why the laptop didn't push it.)

## The reference: 2 Ship 2 Harkinian, already ported

SoH and 2 Ship 2 Harkinian (Majora's Mask) are sibling Harbour Masters ports on libultraship (LUS), with the same
extractor, archive and menu code. **A cloud session already ported 2S2H to the Frame and it runs**, so copy its
approach: repo `Cogential/2ship2harkinian-frame` (private, same owner), branch `claude/focused-brahmagupta-sylmhh`,
commits `8dd8eca14` ("Add Steam Frame (aarch64 Linux) port groundwork") through `48d51af56`, release `frame-v0.1.0`.
Read these files there (`gh api repos/Cogential/2ship2harkinian-frame/contents/<path>?ref=claude/focused-brahmagupta-sylmhh`):

| File | What it does |
| --- | --- |
| `.github/workflows/steam-frame.yml` | Builds natively on GitHub's **`ubuntu-22.04-arm`** runner (no cross-compiling, no emulation); publishes a GitHub release on `frame-v*` tags or a manual run |
| `CMake/toolchains/linux-aarch64.cmake`, `steamframe/build-arm64.sh` | Cross-compiling from x86-64 (multiarch apt with `ports.ubuntu.com`), or `--native` on Arm |
| `CMakeLists.txt` (`-DSTEAM_FRAME=ON`), `CMake/Packaging.cmake` | Snapdragon 8 Gen 3 code generation; AppImage packaging with the target-architecture `linuxdeploy` |
| `mm/2s2h/SteamFrame/SteamFrame.{h,cpp}`, `mm/2s2h/BenPort.cpp` | Detects the Frame at launch (aarch64 + SteamOS; `S2H_STEAM_FRAME=0/1` overrides) and fills in defaults the player hasn't changed: controller menu navigation on, multi-viewports off, 150% UI scale, VSync on, fullscreen 1920x1080 |
| `steamframe/make-personal-bundle.sh` | Owner-side: release + their ROM (+ optional pre-built o2r) into a ready-to-copy folder |
| `docs/STEAM_FRAME.md`, `steamframe/RELEASE_NOTES.md` | Player-facing docs |

Port each piece to SoH's layout (`soh/soh/...` instead of `mm/2s2h/...`, `SOH_` names, `soh.o2r` from the
`GenerateSohOtr` target, `oot.o2r` from the ROM).

## The Steam Frame (measured on the owner's headset)

- Valve's VR headset: Snapdragon 8 Gen 3 (Cortex-X4/A720/A520, ARMv9.2), 15 GB RAM, Adreno 750. SteamOS 0.4.x arm64,
  glibc 2.39, libstdc++ from gcc 15, `/etc/os-release` `VARIANT_ID="vr"`. Flat games show on a virtual screen through
  gamescope (nested 1280x720; 2S2H uses a 1920x1080 backbuffer).
- Graphics: Mesa **Turnip Vulkan 1.4**, and OpenGL through **Zink** on top of it. LUS's OpenGL renderer works (2S2H,
  Lighthouse); a Vulkan/Dawn renderer also works (Wind Waker recomp).
- **Don't make an Android APK.** APKs run in Lepton, Valve's Android 11 container, which passes only Wayland pointer,
  touch and keyboard to apps: no gamepad reaches them, and SDL crashes on its missing clipboard service. Native Linux
  builds get the Frame controllers and paired Steam Controllers from Steam Input, as a normal gamepad.
- No keyboard or mouse in the headset: the controller's **View/Back** must open the menu (LUS `CVAR_IMGUI_CONTROLLER_NAV`
  on by default on the Frame). No file dialogs in game mode (zenity/kdialog missing), so the extractor must find the
  ROM by itself in the data folder. LUS only goes fullscreen automatically for `VARIANT_ID=steamdeck`; otherwise a
  640x480 window is stretched and the menu looks enormous, so default to fullscreen on the Frame.

## How games get onto the Frame (what the owner's laptop session does)

- Games live in `~/devkit-game/<gameid>/`, registered with Steam by `~/devkit-utils/steam-client-create-shortcut`
  (the owner's laptop does this over SSH, or the owner uses FrameDrop). They run in **Steam Linux Runtime 4.0
  (arm64)** (`SteamLinuxRuntime_4-arm64`), which has no FUSE: **ship an unpacked folder, not just an AppImage.** The
  2S2H AppImage was unpacked and its `usr/bin/2s2h.elf` launched directly; it finds its libraries via `$ORIGIN/../lib`.
- Launch through a `run.sh` at the folder's top level: `cd` to the binary's folder, `chmod +x` the binary (FrameDrop's
  Windows unzip drops executable bits), set `SHIP_HOME=$HOME/.local/share/soh` (saves, settings and the built o2r
  survive reinstalls), copy a `*.z64` shipped next to it into `SHIP_HOME` until the o2r exists, then exec the binary.
  Make `run.sh` the obvious program: FrameDrop once picked a `.so` as a game's executable.
- Steam shortcut ids must not start with a digit.
- Bundle only what SteamOS lacks (SDL2 if you need a specific one, libzip, tinyxml2, spdlog, fmt, SDL2_net,
  opusfile...). **Never bundle glibc, libstdc++, libgcc_s or GL/EGL/Vulkan/X11/Wayland libraries**: SteamOS's are newer
  and Mesa needs its own. The Frame already has libz, libbz2, libcrypto, libpng16, libogg/vorbis, libvulkan,
  libOpenGL/EGL, X11, Wayland and PulseAudio.

## Deliverables

1. Branch `steam-frame` with the port (Frame detection and defaults, ROM auto-processing, build scripts, CI).
2. A GitHub release on a `frame-v*` tag with **`soh-steam-frame-arm64.zip`** (unpacked folder with `run.sh`, the
   binary, `lib/`, `soh.o2r`, `assets/`/`config` files, `gamecontrollerdb.txt`, no ROM) and optionally the AppImage.
3. Release notes saying what was and wasn't tested.

Test what you can in the cloud (the arm64 runner, or `qemu-aarch64` with a sysroot reaching startup). Real testing
happens on the Frame from the owner's laptop session, which adds their ROM and installs it over SSH.
