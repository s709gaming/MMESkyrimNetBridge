# MMEAlert

MMEAlert is an add-on for **Milk Mod Economy (MME)** intended to bridge MME actor information and events to **SkyrimNet**.

Current test dependencies are Milk Mod Economy, SkyUI, PapyrusUtil, and JContainers. SkyUI supplies the MCM, while JContainers stores this mod's settings in its own JSON file.

> **Development status:** incomplete and not ready as a functional SkyrimNet bridge.

## Current progress

Only the diagnostic/debug functionality has been demonstrated in-game so far.

Working debug behavior:

- The startup quest loads and identifies itself with an `MMEAlert - ready` notification.
- Milk/full-status debug reporting works in the current test setup.
- MME milking-start events are detected.
- MME milking-completion events are detected.
- The actor supplied by MME is identified by name.
- Debug information is displayed as an in-game notification.
- The same information is written to the Papyrus log.
- A separate SkyUI MCM named `MME Alerts` stores its settings in `SKSE/Plugins/StorageUtilData/MMEAlerts/Settings.json`.
- Capacity refreshes run after load, location change, waiting, and sleeping through a permanent invisible player monitor.
- Optional polling is disabled by default; when enabled its interval is configurable from 5–30 seconds (default 15).
- First observation establishes a baseline; crossing into 50–99% or 100%+ produces one notification and spatial sound.
- Nearby NPCs must be loaded, alive, enabled, and within 2,000 game units. The player is always eligible when registered as a Milk Maid.
- `MMEDebug.psc` is diagnostics-only. Its MCM toggle plays the Mild test sound every five seconds until disabled.

The minimal native CommonLibSSE-NG test DLL also builds and loads successfully through SKSE on Skyrim runtime `1.6.1170`. It currently writes only a native test log and is not connected to MME, Papyrus, or SkyrimNet.

## Not implemented

The following features are planned or experimental and should not be considered functional:

- Communication with SkyrimNet.
- Transfer of MME actor state from Papyrus to the native SKSE DLL.
- Nearby milkmaid discovery and fullness refresh.
- Refreshing actor state after cell, location, load, or fast-travel events.
- A stable public data format or API.
- Production configuration, error recovery, and compatibility handling.
- Grouped simultaneous capacity reactions and sound overlap management.

The earlier magic-effect leak hook was removed because it was not reliable in testing. Full capacity is now detected from MME's stored milk values instead.

## Confirmed debug output

```text
MMEAlert - ready
MMEAlert - START: Actor Name
MMEAlert - END: Actor Name (3 bottles)
```

Milk/full-status output is diagnostic and may change as the MME data adapter is developed.

## Installation for testing

1. Build or install `MMEAlert.zip` with Vortex or another Skyrim Special Edition mod manager.
2. Enable `MMEAlert.esp`.
3. Deploy the mod.
4. Launch Skyrim through SKSE.

Milk Mod Economy and its required dependencies must already be installed for MME events to occur.

This package is intended for development testing. Do not treat the current release as a working SkyrimNet integration.

## Papyrus logging

Enable Papyrus logging in `Documents\My Games\Skyrim Special Edition\Skyrim.ini`:

```ini
[Papyrus]
bEnableLogging=1
bEnableTrace=1
bLoadDebugInformation=1
```

Papyrus output is written to:

```text
Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log
```

Search for `[MMEAlert]`.

## Native SKSE load test

The separate native test plugin writes:

```text
Documents\My Games\Skyrim Special Edition\SKSE\MMEAlertTest.log
```

Expected output:

```text
MMEAlertTest loaded successfully through CommonLibSSE-NG
Runtime version: 1-6-1170-0
```

This proves that the C++/CommonLibSSE-NG DLL can be built and loaded. It does not prove that the planned bridge works.

## Building the Papyrus test package

Double-click `build-package.bat`, or run:

```powershell
.\build-package.ps1
```

The output is:

```text
dist\MMEAlert.zip
```

The script currently expects Skyrim Special Edition at:

```text
E:\Steam\steamapps\common\Skyrim Special Edition
```

Update `$gameRoot` in `build-package.ps1` if Skyrim is installed elsewhere.

## Building the native test

Double-click `build-native-test.bat`, or run:

```powershell
.\build-native-test.ps1
```

The native test archive is written to:

```text
dist\MMEAlertNativeTest.zip
```

The current native builder depends on the local `extern/CommonLibSSE-NG` and `extern/vcpkg` directories. Those dependency directories are intentionally excluded from Git.

## Important project files

- `MMEAlert.esp` - ESL-flagged plugin containing the startup debug quest.
- `Source/Scripts/MMEDebug.psc` - working debug listener for MME milking start/end events.
- `Source/Scripts/MMEAlertLeakEffect.psc` - experimental leak-effect listener that is not yet wired into the ESP.
- `src/Plugin.cpp` - minimal native CommonLibSSE-NG/SKSE load test.
- `CMakeLists.txt` and `CMakePresets.json` - native build configuration.
- `build-package.ps1` - Papyrus compilation and package builder.
- `build-native-test.ps1` - native DLL and test-package builder.

## License

This project is released under the [MIT License](LICENSE). Anyone may use, copy, modify, redistribute, sublicense, sell, or incorporate it into another project under the terms of that license.

Milk Mod Economy, Skyrim, SKSE, SkyrimNet, and their respective names and assets belong to their respective authors and owners. MMEAlert is an independent add-on and is not an official release of those projects.
