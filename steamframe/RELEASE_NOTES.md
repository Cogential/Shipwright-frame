**Experimental: Ship of Harkinian in 3D on the Steam Frame.** A native ARM64 Linux build of Ship of Harkinian 9.3.0 that shows the game on a floating 3D screen: each eye sees its own picture, so Hyrule has real depth while you play with the controller as usual. It's a separate install from the normal Frame build and shares its saves, settings and `oot.o2r` (`~/.local/share/soh`).

No ROM or ROM-derived files are included. You need your own Ocarina of Time ROM.

### New in frame-3d-v0.1.1
- **Black around the screen** instead of white (that also hides the dark specks at the edges of the lenses).
- **Grab the screen like SteamVR's theater screen:** hold a **grip** and point or move that controller to drag
  the screen around; hold **both grips** and pull your hands apart or together to make it bigger or smaller.
  The screen always turns to face you, and stays where you leave it.

### Adjusting the 3D
Hold a **grip** and press the **D-pad**:
- Left grip + D-pad up/down: more or less depth.
- Left grip + D-pad left/right: move the focus (what sits on the screen) farther or nearer.
- Right grip + D-pad up/down: bigger or smaller screen.
- Right grip + D-pad left/right: screen farther or nearer.

Pressing the D-pad during a grip hold adjusts instead of moving the screen. Settings are saved. Use
SteamVR's recenter if the screen isn't in front of you.

### Notes
- If the headset can't be used the game plays flat as usual, and the reason is in the log (`~/.local/share/soh/logs/`, lines starting `Frame 3D:`).
- The controllers are read through OpenXR and given to the game as a gamepad, in case Steam's own gamepad stops while the game is a VR app.
- MSAA is off in 3D mode.

---

**Test build: native ARM64 Linux build of Ship of Harkinian 9.3.0 "Dewey Alfa" for the Steam Frame.**

No ROM or ROM-derived files are included. You need your own Ocarina of Time ROM.

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
