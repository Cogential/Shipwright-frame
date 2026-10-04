**Test build: native ARM64 Linux build of Ship of Harkinian 9.2.3 "Ackbar Delta" for the Steam Frame.**

No ROM or ROM-derived files are included. You need your own Ocarina of Time ROM.

### Install
1. Unzip `soh-steam-frame-arm64.zip` and copy the `soh-steam-frame` folder to the Frame, e.g.
   `~/devkit-game/soh/`.
2. Put your ROM (`.z64`) in that folder, or in `~/.local/share/soh/`.
3. Register **`run.sh`** with Steam (`steam-client-create-shortcut`, FrameDrop, or *Add a
   Non-Steam Game*). Start `run.sh`, not `soh.elf`.
4. Launch it. The first launch builds `oot.o2r` from the ROM with no prompts, then starts the
   game. Saves, settings and `oot.o2r` are kept in `~/.local/share/soh/`.

Press **View** to open the menu; pop-ups are answered with **A**. Put `SOH_STEAM_FRAME=0 %command%`
in the launch options to turn the Frame defaults off.

The AppImage is also attached for desktop Arm Linux. Inside Steam Linux Runtime 4 (no FUSE), use
the zip.

### What was tested
Not yet on a real Steam Frame. In the cloud, the packaged zip was run through its own `run.sh` on
x86_64 under `qemu-aarch64` with Mesa's software renderer, with an empty home folder and the NTSC
1.0 (US) ROM next to `run.sh`:
- `run.sh` copied the ROM to `~/.local/share/soh`. The game detected the Frame, applied its
  defaults (controller nav, 150% UI, VSync, single viewport, 1920x1080 fullscreen), found the ROM,
  built `oot.o2r` with no prompts, loaded it, and showed the boot logo.
- Second launch: with `oot.o2r` present, it started straight away.
- With no ROM, it showed a "No ROM Found" message naming the folder, with the OK button focused for
  the controller.

### Not tested yet
- Anything on the Frame itself: performance, Zink/Turnip rendering, controller input (no gamepad
  was available in the cloud), and running inside Steam Linux Runtime 4.
- Whether every library SteamOS is expected to provide is actually present in the runtime. The
  bundled ones are in `lib/`.
- Text-to-speech isn't included (no eSpeak on the Frame).

### Please report
Whether it launches, frame rate, graphics glitches, controller behaviour in game and in menus, and
the logs in `~/.local/share/soh/logs/`.
