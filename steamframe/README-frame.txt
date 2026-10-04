Ship of Harkinian (Ocarina of Time) for the Steam Frame
=======================================================

This is a native ARM64 Linux build. No ROM or game assets are included: you need your own
Ocarina of Time ROM (.z64), in one of the versions listed in docs/supportedHashes.json.

Install
-------
1. Copy this folder to the Frame, e.g. ~/devkit-game/soh/.
2. Put your ROM (.z64) in this folder, or straight into ~/.local/share/soh/.
3. Add run.sh to Steam as a non-Steam game, or pick run.sh as the executable in FrameDrop.
   run.sh is the program to start, not soh.elf.
4. Start it. The first launch builds oot.o2r from the ROM by itself (no prompts) and then starts
   the game. That takes a few minutes and only happens once.

Controls
--------
Press View (Back) on the controller to open the menu and drive it with the controller. Pop-up
messages can be answered with A.

Where things are kept
---------------------
Saves, settings, logs and oot.o2r are in ~/.local/share/soh/, so they survive reinstalls. Set
SHIP_HOME to use another folder.

Settings
--------
On the Frame the game fills in controller menu navigation, 150% menu text, VSync and
1920x1080 fullscreen for settings you haven't changed. Put SOH_STEAM_FRAME=0 %command% in the
launch options to turn that off.

Text-to-speech (eSpeak) isn't included in this build.
