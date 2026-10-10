#ifndef STEAM_FRAME_H
#define STEAM_FRAME_H

// Support for running Ship of Harkinian natively on the Steam Frame (Snapdragon 8 Gen 3,
// aarch64 SteamOS).
//
// The game is shown as a flat window on a virtual screen inside the headset, with no keyboard or
// mouse and no file dialogs, so the work here is about making it usable from a controller alone:
// controller-driven menus and popups, a single fullscreen surface, readable text, and ROM
// processing that needs no prompts.
namespace SteamFrame {

// True when running on a Steam Frame. Set SOH_STEAM_FRAME=1 (or 0) to force the answer, e.g. to
// test the Frame behaviour on a desktop or to opt out of it on the headset.
bool IsSteamFrame();

// Fills in Frame-friendly defaults for any setting the player has not chosen themselves. Must run
// after the configuration and CVars are loaded and before the window is created.
void ApplyDefaults();

// Controller fixes that need SDL running: keeps the headset's laser pointer from turning controller
// presses into mouse-button mappings, and records what the controller sends to frame-input.log in the
// data folder (for diagnosing input from afar). Call once after the window is created.
void InstallInputHooks();

// The first controller button (SDL_GameControllerButton) pressed since the previous call, or -1. The
// input editor binds it when polling the controller found nothing: the Frame's D-pad taps can be over
// before the editor looks.
int TakeGamepadButtonPress();

// Adds a line to frame-input.log (printf-style).
void LogInput(const char* fmt, ...);

} // namespace SteamFrame

#endif // STEAM_FRAME_H
