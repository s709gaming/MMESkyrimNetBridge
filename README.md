# MMEAlert

MMEAlert is an add-on for **Milk Mod Economy (MME)** that listens for MME actor events and is intended to bridge those events to **SkyrimNet**.

## Current status
NOT FULLY FUNCTIONAL, DEVELOPMENT IN PROGRESS

The minimal Papyrus test implementation is working in-game. It currently:

- Starts automatically through `MMEAlert.esp`.
- Listens for MME milking-start events.
- Listens for MME milking-completion events.
- Identifies the actor supplied by MME.
- Displays an in-game notification prefixed with `MMEAlert`.
- Writes the same event information to the Papyrus log.

Milk-leak detection code is included, but `MMEAlertLeakEffect` must be attached to the appropriate MME MilkLeak Magic Effect record before leak notifications will fire.

The SkyrimNet bridge itself is still under development. The present notification listener is a diagnostic foundation used to verify that MME events are received correctly.

## Example notifications

```text
MMEAlert - ready
MMEAlert - START: Actor Name
MMEAlert - END: Actor Name (3 bottles)
MMEAlert - LEAK START: Actor Name by Caster Name
MMEAlert - LEAK END: Actor Name by Caster Name
```

## Installation

1. Install `MMEAlert.zip` with Vortex or another Skyrim Special Edition mod manager.
2. Enable `MMEAlert.esp`.
3. Deploy the mod.
4. Launch Skyrim through SKSE.

Milk Mod Economy and its required dependencies must already be installed for MME events to occur.

## Logging

Enable Papyrus logging in `Documents\My Games\Skyrim Special Edition\Skyrim.ini`:

```ini
[Papyrus]
bEnableLogging=1
bEnableTrace=1
bLoadDebugInformation=1
```

Log output is written to:

```text
Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log
```

Search for `[MMEAlert]` to find this add-on's messages.

## Building

Double-click `build-package.bat`, or run:

```powershell
.\build-package.ps1
```

The builder compiles the Papyrus scripts and creates:

```text
dist\MMEAlert.zip
```

The build script currently expects Skyrim Special Edition at:

```text
E:\Steam\steamapps\common\Skyrim Special Edition
```

Update `$gameRoot` in `build-package.ps1` if Skyrim is installed elsewhere.

## Project files

- `MMEAlert.esp` — ESL-flagged plugin containing the startup quest.
- `Source/Scripts/MMEDebug.psc` — debug quest listener for MME start/end events.
- `Source/Scripts/MMEAlertLeakEffect.psc` — debug Active Magic Effect listener for milk leaks.
- `src/Plugin.cpp` — minimal native CommonLibSSE-NG/SKSE load test.
- `SEQ/MMEAlert.seq` — startup quest registration data.
- `build-package.ps1` — compiler and packaging script.
- `build-package.bat` — double-clickable build launcher.
- `build-native-test.ps1` — builds the native SKSE test DLL and its Vortex archive.

## License

This project is released under the [MIT License](LICENSE). Anyone may use, copy, modify, redistribute, or incorporate it into another project under the terms of that license.

Milk Mod Economy, Skyrim, SKSE, SkyrimNet, and their respective names and assets belong to their respective authors and owners. This project is an independent add-on and is not an official release of those projects.
