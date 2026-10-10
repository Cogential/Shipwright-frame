#include "SteamFrame.h"

#include <atomic>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>

#include <libultraship/libultraship.h>
#ifdef __APPLE__
#include <SDL.h>
#else
#include <SDL2/SDL.h>
#endif

#include "soh/cvar_prefixes.h"

namespace SteamFrame {

namespace {

#if defined(__linux__) && defined(__aarch64__)
std::string OsReleaseValue(const std::string& key) {
    // Inside Steam Linux Runtime (pressure-vessel) /etc/os-release describes the runtime; the host's
    // copy is mounted at /run/host/os-release.
    std::ifstream osRelease("/run/host/os-release");
    if (!osRelease.is_open()) {
        osRelease.open("/etc/os-release");
    }
    std::string line;
    while (std::getline(osRelease, line)) {
        if (line.rfind(key + "=", 0) != 0) {
            continue;
        }
        std::string value = line.substr(key.size() + 1);
        if (value.size() >= 2 && value.front() == '"' && value.back() == '"') {
            value = value.substr(1, value.size() - 2);
        }
        return value;
    }
    return "";
}
#endif

bool Detect() {
    if (const char* forced = std::getenv("SOH_STEAM_FRAME")) {
        return std::strcmp(forced, "0") != 0;
    }
#if defined(__linux__) && defined(__aarch64__)
    // The Frame reports ID=steamos, VARIANT_ID=vr. It is the only aarch64 device SteamOS ships on;
    // its Arch Linux ARM base (Holo) reports ID=holo.
    const std::string id = OsReleaseValue("ID");
    return id == "steamos" || id == "holo" || OsReleaseValue("VARIANT_ID") == "vr";
#else
    return false;
#endif
}

// frame-input.log: the controllers SDL found and the first input events, so the next session can see
// what the Frame's controllers actually send. Capped so it can't grow during play.
FILE* sInputLog = nullptr;
int sInputLogLines = 0;
constexpr int kInputLogMaxLines = 4000;

// For TakeGamepadButtonPress.
std::atomic<int> sFirstGamepadButton{ -1 };

void InputLog(const char* fmt, ...) {
    if (sInputLog == nullptr || sInputLogLines >= kInputLogMaxLines) {
        return;
    }
    va_list args;
    va_start(args, fmt);
    std::fprintf(sInputLog, "%8u ", SDL_GetTicks());
    std::vfprintf(sInputLog, fmt, args);
    std::fputc('\n', sInputLog);
    va_end(args);
    if (++sInputLogLines == kInputLogMaxLines) {
        std::fputs("(log full)\n", sInputLog);
    }
    std::fflush(sInputLog);
}

void LogJoystick(int deviceIndex, bool open) {
    char guid[64];
    SDL_JoystickGetGUIDString(SDL_JoystickGetDeviceGUID(deviceIndex), guid, sizeof(guid));
    const char* name = SDL_JoystickNameForIndex(deviceIndex);
    InputLog("device %d: \"%s\" %04x:%04x guid %s gamecontroller %d", deviceIndex, name ? name : "?",
             SDL_JoystickGetDeviceVendor(deviceIndex), SDL_JoystickGetDeviceProduct(deviceIndex), guid,
             SDL_IsGameController(deviceIndex));
    if (char* mapping = SDL_GameControllerMappingForDeviceIndex(deviceIndex)) {
        InputLog("  mapping %s", mapping);
        SDL_free(mapping);
    }
    // Not from the event filter: SDL calls it while adding the device.
    SDL_Joystick* joystick = open ? SDL_JoystickOpen(deviceIndex) : nullptr;
    if (joystick != nullptr) {
        InputLog("  %d axes, %d buttons, %d hats", SDL_JoystickNumAxes(joystick), SDL_JoystickNumButtons(joystick),
                 SDL_JoystickNumHats(joystick));
        SDL_JoystickClose(joystick);
    }
}

int SDLCALL FilterInput(void*, SDL_Event* event) {
    switch (event->type) {
        case SDL_JOYDEVICEADDED:
            LogJoystick(event->jdevice.which, false);
            break;
        case SDL_JOYHATMOTION:
            InputLog("joystick %d hat %d = %d", event->jhat.which, event->jhat.hat, event->jhat.value);
            break;
        case SDL_JOYBUTTONDOWN:
            InputLog("joystick %d button %d down", event->jbutton.which, event->jbutton.button);
            break;
        case SDL_CONTROLLERBUTTONDOWN: {
            int none = -1;
            sFirstGamepadButton.compare_exchange_strong(none, event->cbutton.button);
            InputLog("gamepad %d %s down", event->cbutton.which,
                     SDL_GameControllerGetStringForButton(static_cast<SDL_GameControllerButton>(event->cbutton.button)));
            break;
        }
        case SDL_KEYDOWN:
            if (!event->key.repeat) {
                InputLog("key %s down", SDL_GetScancodeName(event->key.keysym.scancode));
            }
            break;
        case SDL_MOUSEWHEEL:
            InputLog("mouse wheel %d,%d", event->wheel.x, event->wheel.y);
            break;
        case SDL_MOUSEBUTTONDOWN:
        case SDL_MOUSEBUTTONUP:
            if (event->type == SDL_MOUSEBUTTONDOWN) {
                InputLog("mouse button %d down", event->button.button);
            }
            // The headset's laser pointer clicks with the left button. The other buttons it sends come
            // from controller presses (the D-pad has shown up as the middle button), and the input editor
            // would bind them instead of the controller button the player meant: drop them.
            if (event->button.button != SDL_BUTTON_LEFT) {
                return 0;
            }
            break;
        default:
            break;
    }
    return 1;
}

} // namespace

void LogInput(const char* fmt, ...) {
    char line[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(line, sizeof(line), fmt, args);
    va_end(args);
    InputLog("%s", line);
}

int TakeGamepadButtonPress() {
    return sFirstGamepadButton.exchange(-1);
}

bool IsSteamFrame() {
    static const bool sIsSteamFrame = Detect();
    return sIsSteamFrame;
}

void ApplyDefaults() {
    if (!IsSteamFrame()) {
        return;
    }

    SPDLOG_INFO("Steam Frame detected, applying Steam Frame defaults");

    // The Frame has no keyboard or mouse in the headset: let the controller's View button open
    // the menu and drive it.
    CVarRegisterInteger(CVAR_IMGUI_CONTROLLER_NAV, 1);
    // The game is presented as a single virtual screen, so keep popout windows inside it.
    CVarRegisterInteger(CVAR_ENABLE_MULTI_VIEWPORTS, 0);
    // Menu text is read from a virtual screen a few metres away; default to the 150% UI scale.
    CVarRegisterInteger(CVAR_SETTING("ImGuiScale"), 2);
    CVarRegisterInteger(CVAR_VSYNC_ENABLED, 1);
    // Save them now: on a fresh config SoH's config migrations call CVarClearBlock(), which reloads
    // every CVar from the file and would drop these before the game starts.
    CVarSave();

    // libultraship only goes fullscreen by itself on VARIANT_ID=steamdeck; otherwise it opens a
    // 640x480 window that gamescope stretches, which makes the menu enormous.
    // Config::Contains() can't be used here: for a missing nested key it finds the nearest parent.
    auto config = Ship::Context::GetRawInstance()->GetConfig();
    const bool fullscreenSet =
        config->GetBool("Window.Fullscreen.Enabled", false) == config->GetBool("Window.Fullscreen.Enabled", true);
    if (!fullscreenSet) {
        config->SetBool("Window.Fullscreen.Enabled", true);
    }
    // Backbuffer size of the flat window; gamescope scales it onto the virtual screen.
    if (config->GetInt("Window.Fullscreen.Width", -1) == -1 && config->GetInt("Window.Fullscreen.Height", -1) == -1) {
        config->SetInt("Window.Fullscreen.Width", 1920);
        config->SetInt("Window.Fullscreen.Height", 1080);
    }
    config->Save();
}

void InstallInputHooks() {
    if (!IsSteamFrame()) {
        return;
    }
    std::string folder;
    if (const char* shipHome = std::getenv("SHIP_HOME"); shipHome != nullptr && shipHome[0] != '\0') {
        folder = shipHome;
    } else if (const char* home = std::getenv("HOME"); home != nullptr) {
        folder = std::string(home) + "/.local/share/soh";
    }
    if (!folder.empty()) {
        sInputLog = std::fopen((folder + "/frame-input.log").c_str(), "w");
    }
    SDL_version linked;
    SDL_GetVersion(&linked);
    const char* steamPadInfo = std::getenv("SteamVirtualGamepadInfo");
    InputLog("SDL %d.%d.%d, video %s, SteamVirtualGamepadInfo %s", linked.major, linked.minor, linked.patch,
             SDL_GetCurrentVideoDriver() ? SDL_GetCurrentVideoDriver() : "?", steamPadInfo ? steamPadInfo : "(unset)");
    for (int i = 0; i < SDL_NumJoysticks(); i++) {
        LogJoystick(i, true);
    }
    SDL_SetEventFilter(FilterInput, nullptr);
}

} // namespace SteamFrame
