# MME Extensions

> Editable release README template. Replace this note and any bracketed text before publishing.

MME Extensions is a modular add-on for Milk Mod Economy. It connects important Milkmaid gameplay to Skyrim.Net and adds optional sounds, notifications, drink effects, dialogue, and diagnostics. Features can be enabled separately through the MCM.

## Requirements

- Skyrim Special Edition or Anniversary Edition through SKSE
- Milk Mod Economy (MME)
- SkyUI
- PapyrusUtil
- JContainers
- Address Library for SKSE Plugins
- Skyrim.Net — optional; only required for Skyrim.Net features
- SexLab Aroused or OSLAroused — optional; only required for arousal features

Skyrim VR support is built into the CommonLibSSE-NG DLL but still needs broader in-game verification. Use VR Address Library when testing VR.

## Features

### Modular reactions

- Optional reaction sounds for drinking milk, Milkmaid fullness, and milking start/end.
- Adjustable sound volume.
- Optional half-full and full Milkmaid notifications.
- Configurable polling interval when capacity polling is enabled.

### Milk drinking

- Detects supported milk consumed by the player without a polling loop.
- Adds a configurable flat milk bonus.
- Optionally adds half the drinker's Milkmaid level.
- Gives Lactacid its own configurable multiplier.
- Uses MME's existing milk functions and respects normal capacity limits.
- Can optionally raise arousal when a supported arousal mod is installed.
- Detects supported milk consumed by NPCs; extension effects apply only to valid MME Milkmaids.

### Milkmaid dialogue

- Adds **Drink this, it will make you milky!** beneath MME's existing **Hey, there** dialogue.
- Appears only for a valid MME Milkmaid.
- Transfers and processes one milk item from the player.
- Selection priority: Lactacid, normal milk, racial milk, then supernatural milk.
- Can optionally play MME's Milkmaid reaction animation after the effects finish.

### Skyrim.Net integration

- Automatically disables Skyrim.Net functions when Skyrim.Net is unavailable.
- Reports exact player milk drinks as short-lived events.
- Reports milking start and end as short-lived events.
- Reports half-full and full capacity milestones.
- Records confirmed new Milkmaids as recent events.
- Sends a configurable summary of nearby Milkmaid fullness.
- Can request narration when a nearby Milkmaid first reaches full capacity, with a configurable cooldown.
- Adds optional Milkmaid lore only to actors confirmed as MME Milkmaids.
- Provides separate toggles for drinks, milking, creation, nearby status, and narration.

### Native event support

- Uses a CommonLibSSE-NG bridge for wait, sleep, location-change, magic-effect, and NPC potion events.
- Uses native nearby-actor discovery, followed by authoritative MME validation in Papyrus.
- Avoids broad Papyrus actor scanning and unnecessary polling where native events are available.

### Optional MME MCM defaults

The FOMOD can preload the author's preferred MME MCM values. They remain ordinary MME settings and may be changed by the player at any time.

The recommended profile provides natural production without mandatory Lactacid, roughly daily milking cycles, Novice progression, 3BA-friendly breast scaling, and 100% gush chance to avoid extra milking delay. Choosing **Keep MME Defaults** leaves MME's values unchanged.

### Diagnostics

- Independent debug toggles keep notifications focused on the feature being tested.
- Papyrus details can be written to the normal Papyrus log.
- Native bridge details are written to `MMEExtensions.log` in the SKSE log directory.
- Development-only Quick Test provisioning remains available in test builds.

## Installation

1. Install all required dependencies.
2. Install `MME Extensions.zip` with Vortex or Mod Organizer 2.
3. Choose whether the FOMOD should preload the recommended MME MCM values.
4. Enable `MMEAlert.esp` and deploy or sort the mod.
5. Start Skyrim through SKSE.

## Compatibility and status

- [Add tested Skyrim runtime versions.]
- [Add tested MME version.]
- [Add tested Skyrim.Net version.]
- [Add known conflicts or limitations.]
- Experimental Skyrim.Net conversational actions are intentionally excluded because competing actions and scene context made them unreliable.
- SPID is not currently required or active.

## Developer notes

### General architecture

The ESP owns the startup quest, aliases, dialogue records, sound forms, and script properties. Papyrus handles MME-facing rules and configurable gameplay. The CommonLibSSE-NG DLL supplies low-cost engine events and nearby-actor discovery. Skyrim.Net integration is isolated behind availability checks, so the rest of the mod continues working without Skyrim.Net.

Typical flow:

1. A native event, MME ModEvent, alias event, or dialogue fragment detects an action.
2. Papyrus validates the actor and form against MME.
3. A focused helper applies the enabled sound, milk, arousal, or dialogue behavior.
4. The Skyrim.Net bridge publishes enabled context separately.
5. Feature-specific diagnostics report the decision path when requested.

### Papyrus script map

- `MMEAlertsController.psc` — central startup, MME event registration, capacity scheduling, nearby Milkmaid validation, creation detection, and milking start/end handling.
- `MMEAlertsMCM.psc` — MCM pages, settings, defaults, migrations, tooltips, and diagnostic controls.
- `MMEAlertsPlayerEffect.psc` — player ability lifecycle hook; restores the controller after startup and save loading.
- `MMEAlertsSkyrimNet.psc` — active Skyrim.Net availability checks, prompt decoration, events, nearby summaries, and narration requests.
- `MMEDrinkTracker.psc` — player equip-based drink detection and native NPC potion-consumption handling.
- `MMEMilkDrinkEffects.psc` — shared drink reaction-sound playback.
- `MMEMilkBoost.psc` — shared milk-bonus calculation and MME capacity-safe application.
- `MMEArousalBridge.psc` — optional SexLab Aroused/OSLAroused detection and arousal updates without a hard script dependency.
- `MMENPCDialog.psc` — Milkmaid-only dialogue validation, inventory priority, transfer, consumption, extension effects, and optional animation.
- `MMEAlertsFlatRateDefaults.psc` — optional FOMOD-selected MME MCM preset; captures values so its changes can be reversed.
- `MMEAlertsQuickTest.psc` — temporary test-item provisioning for development builds.
- `MMEDebug.psc` — passive debug helper retained for focused troubleshooting.
- `MMEExtensionsNative.psc` — Papyrus declaration for the DLL's native nearby-actor function.
- `MMESkyrimNetVoiceControls.psc` — archived experimental actions; deliberately excluded from release compilation.

### Native code

- `src/Plugin.cpp` — CommonLibSSE-NG plugin. Publishes wait, sleep, location, MME magic-effect, and NPC potion events to Papyrus and exposes nearby-actor discovery.
- `build-native.bat` / `build-native.ps1` — builds the native DLL after C++ changes.
- `build-package.bat` / `build-package.ps1` — compiles active Papyrus scripts and creates the distributable FOMOD archive.

### Data and configuration

- `MMEAlert.esp` — current legacy plugin filename; contains the MME Extensions records.
- `SKSE/Plugins/StorageUtilData/MMEAlerts/SkyrimNet.json` — editable Skyrim.Net event messages.
- `SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt` — actor-specific Milkmaid lore prompt.
- `fomod/` — installer metadata and optional defaults selection.
- `assets/sounds/` — source reaction-sound pools packaged under `Sound/`.

### Build notes

1. Run `build-native.bat` only after changing the native C++ code or toolchain.
2. Run `build-package.bat` for every distributable build.
3. Install `dist/MME Extensions.zip` with a mod manager; do not install the staging directory directly.
4. Confirm that the MCM title is **MME Extensions** and that General, Milk Drinking, Arousal, Skyrim.Net, and Debug pages appear.
5. Keep test-only helpers clearly identified or remove them before the public release.

## Credits

- [Milk Mod Economy author and contributors]
- [Skyrim.Net]
- [CommonLibSSE-NG]
- [Additional tools, testers, and sound credits]

## License

This project is released under the [MIT License](LICENSE). MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab Aroused, or Skyrim.Net release.
