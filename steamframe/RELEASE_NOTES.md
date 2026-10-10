**Test build: native ARM64 Linux build of Ship of Harkinian 9.3.0 "Dewey Alfa" for the Steam Frame.**

No ROM or ROM-derived files are included. You need your own Ocarina of Time ROM.

### New in frame-v0.2.2
- **The headset's laser pointer can't steal controller mappings any more.** While the controller
  points at the game window, Steam can send controller presses as mouse buttons (the D-pad showed up
  as the middle mouse button in the input editor). The Frame build now ignores every mouse button
  except the pointer's click, so the input editor waits for the real controller button.
- **Remapping tip:** point the controller away from the game window while the "Press any button"
  popup is open, then press the D-pad direction.
- **Input log for diagnosing the controller:** the first input after launch is recorded in
  `~/.local/share/soh/frame-input.log` (the controllers SDL found, their mapping, and the buttons,
  D-pad, keys and mouse buttons that arrive). It's rewritten each launch and stops at 4,000 lines.

### New in frame-v0.2.1
- **Fixes the D-pad and controller mapping on the Frame.** Steam describes its virtual controller in a
  way SDL can't map, so only some buttons arrived (D-pad up worked, but down, left and right didn't,
  even when remapping). `run.sh` now hides that description and the controller works as an Xbox pad.
  Nothing else changed from frame-v0.2.0.

### New in frame-v0.2.0
- **Updated to Ship of Harkinian 9.3.0.** See upstream's
  [9.3.0 release notes](https://github.com/HarbourMasters/Shipwright/releases/tag/9.3.0) for the
  game changes.
- **Updating keeps your `oot.o2r`, saves and settings.** 9.3.0 extracts the ROM with a new tool
  (Torch), but it still accepts the `oot.o2r` that v0.1.x made, so there's no new extraction step.
  The two contain the same files and differ only in padding bytes. To rebuild it anyway, delete
  `~/.local/share/soh/oot.o2r` and keep your ROM next to `run.sh`.
- The Frame changes are carried over from v0.1.1: Frame detection, the defaults (View opens the
  menu, 150% UI, VSync, single viewport, 1920x1080 fullscreen), and first-launch ROM processing
  with no prompts. 9.3.0's libultraship now handles controllers that connect after launch itself,
  so the Frame's own workaround for that was removed.

### Install
1. Unzip `soh-steam-frame-arm64.zip` and copy the `soh-steam-frame` folder to the Frame, e.g.
   `~/devkit-game/soh/`. When updating, replace the old folder's contents: `soh.o2r` and `assets/`
   must come from this release.
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
Not yet on a real Steam Frame. In the cloud, the packaged ARM64 zip was run through its own
`run.sh` on x86_64 under `qemu-aarch64` with Mesa's software renderer:
- **Fresh install** (empty home folder, NTSC 1.0 US ROM next to `run.sh`): `run.sh` copied the ROM
  to `~/.local/share/soh`. The game detected the Frame, saved its defaults, found the ROM, built
  `oot.o2r` with Torch and no prompts (about 5.5 minutes under emulation; it will be quicker on
  the Frame), then started 9.3.0 fullscreen at 1920x1080 and showed the boot logos.
- **Update from v0.1.1** (the v0.1.1 settings and its 9.2.3 `oot.o2r`, no ROM): the settings were
  migrated, the old `oot.o2r` loaded, and the game booted. With an SDL virtual controller, pressing
  View opened the settings menu with *Menu Controller Navigation* on, and pressing it again closed
  it.
- The GitHub Arm runner build that produced these files passed.

### Not tested yet
- Anything on the Frame itself: performance, Zink/Turnip rendering, real controllers (the cloud
  tests used SDL virtual controllers), and running inside Steam Linux Runtime 4.
- Updating over an existing v0.1.x install on the Frame (old `oot.o2r` and settings).
- Text-to-speech isn't included (no eSpeak on the Frame).

### Please report
Whether it launches, frame rate, graphics glitches, controller behaviour in game and in menus, and
the logs in `~/.local/share/soh/logs/`.
