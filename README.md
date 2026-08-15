# MME Extensions
Loverslab Download page: https://www.loverslab.com/files/file/50820-mme-milk-mod-economy-extensions/
A modular reaction add-on for **Milk Mod Economy**.

MME Extensions makes Milkmaid gameplay feel sillier and more responsive by reacting to drinking milk, filling up, leaking, milking, and other important MME events.

Depending on your settings, the mod can:

- Play suggestive sound effects.
- Show in-game notifications.
- Apply milk and arousal effects.
- Alert Skyrim.Net so nearby characters can react.

**Everything is modular. Enable only the features you want through the MCM.**

> [!IMPORTANT]
> Skyrim.Net is completely optional. When enabled, characters will talk about Milkmaids and female anatomy much more often.

## Quick Overview

| | |
|---|---|
| **Release status** | Late alpha |
| **Main requirement** | Milk Mod Economy |
| **Skyrim.Net** | Optional |
| **Arousal integration** | Optional |
| **Skyrim VR** | Included but experimental |
| **Configuration** | Modular MCM options |

## Intended World Setting

Milk acts as an aphrodisiac for Milkmaids and makes them produce even more milk.

The growing weight, fullness, movement, and pressure are pleasurable and desirable. Milkmaids should react positively—and erotically—to filling up, leaking milk, drinking milk, and being milked.

These reactions are the intended tone of the mod and its default messages.

## Requirements

### Required

- Skyrim Special Edition or Anniversary Edition with SKSE
- Milk Mod Economy and all its requirements
- SkyUI
- PapyrusUtil
- JContainers
- Address Library for SKSE Plugins

### Optional

- **Skyrim.Net** — required only for Skyrim.Net reactions and context
- **SexLab Aroused or OSLAroused** — required only for arousal effects

The native DLL was built with CommonLibSSE-NG.

### Skyrim VR

Skyrim VR support is included in the CommonLibSSE-NG DLL. Install VR Address Library when using VR. It did not crash when I tried it.

## Features

### Milk Event Reactions

MME Extensions watches for important Milk Mod Economy events:

- Someone becomes a new Milkmaid.
- The player or an NPC drinks supported milk.
- A Milkmaid reaches half-full capacity.
- A Milkmaid reaches full capacity and begins leaking.
- Milking starts.
- Milking ends.

Depending on the event and your MCM settings, the mod can play a sound, show a notification, or alert Skyrim.Net.

Each reaction type can be enabled or disabled separately.

### Milk Drinking Effects

- Detects supported milk consumed by the player or NPCs without a polling loop.
- Applies NPC effects only to valid MME Milkmaids.
- Supports Lactacid, normal milk, racial milk, and supernatural milk.
- Adds a configurable flat milk bonus.
- Can optionally add half the drinker’s Milkmaid level to her milk level.
- Gives Lactacid its own configurable multiplier.
- Uses MME’s existing milk functions and respects normal capacity limits.
- Can optionally raise arousal through SexLab Aroused or OSLAroused.

### Milkmaid Dialogue

Adds the following choice beneath MME’s existing **Hey, there** dialogue:

> **Drink this, it will make you milky!**

This option:

- Appears only when speaking to a valid MME Milkmaid.
- Transfers and processes one supported milk item from the player.
- Prioritizes Lactacid, normal milk, racial milk, then supernatural milk.
- Can optionally play MME’s Milkmaid reaction animation afterward.

### Skyrim.Net Integration

Skyrim.Net is completely optional. Its features automatically disable themselves when Skyrim.Net is unavailable.

When installed, MME Extensions can:

- Publish Milkmaid events as short-lived context.
- Report the exact type of milk consumed.
- Send summaries of nearby Milkmaid fullness.
- Use an MCM-adjustable interval for nearby summaries.
- Request narration when a nearby Milkmaid first becomes full.
- Apply an MCM-adjustable narration cooldown.
- Add Milkmaid context only to confirmed MME Milkmaids through a short `.prompt` file.
- Control each Skyrim.Net feature separately through the MCM.

### Optional MME Settings

The FOMOD can preload the author’s preferred MME settings. These remain normal MME settings and can be changed at any time.

The recommended profile provides:

- Natural milk production without mandatory Lactacid.
- Roughly daily milking cycles.
- Novice progression.
- 3BA-friendly breast scaling.
- A 100% gush chance to avoid extra milking delay.

Choosing **Keep MME Defaults** leaves MME’s settings unchanged.

### Efficient Native Support

- Uses a CommonLibSSE-NG bridge for wait, sleep, location-change, magic-effect, and NPC potion events.
- Uses native nearby-actor discovery followed by authoritative MME validation in Papyrus.
- Avoids broad Papyrus actor scanning and unnecessary polling where native events are available.
- Provides adjustable polling only where it is still needed.

## Installation

1. Install all required dependencies.
2. Install `MME Extensions.zip` with Vortex or Mod Organizer 2.
3. Select your preferred MME defaults during the FOMOD installation.
4. Enable `MMEAlert.esp`.
5. Deploy or sort your load order.
6. Start Skyrim through SKSE.

## Compatibility and Status

> [!WARNING]
> This is a late alpha release. Expect bugs and do not risk an important save.

- Core features work in isolated testing.
- Broader load-order testing is still needed.
- Skyrim VR support is included but still requires broader verification.
- SPID is not required or active. It was only explored during development.

## Diagnostics

- Independent debug toggles keep notifications focused on the feature being tested.
- Papyrus details can be written to the normal Papyrus log.
- Native bridge details are written to `MMEExtensions.log` in the SKSE log directory.
- The former Quick Test helper is inert in release builds and grants no consumables.

<details>
<summary><strong>Developer Notes</strong></summary>

### General Architecture

The ESP owns the startup quest, aliases, dialogue records, sound forms, and script properties.

Papyrus handles MME-facing rules and configurable gameplay. The CommonLibSSE-NG DLL supplies low-cost engine events and nearby-actor discovery.

Skyrim.Net integration is isolated behind availability checks, so the rest of the mod continues working without Skyrim.Net.

### Typical Flow

1. A native event, MME ModEvent, alias event, or dialogue fragment detects an action.
2. Papyrus validates the actor and form against MME.
3. A focused helper applies the enabled sound, milk, arousal, or dialogue behavior.
4. The Skyrim.Net bridge publishes enabled context separately.
5. Feature-specific diagnostics report the decision path when requested.

### Papyrus Script Legend

- `MMEAlertsController.psc` — startup, MME event registration, capacity scheduling, nearby Milkmaid validation, creation detection, and milking events
- `MMEAlertsMCM.psc` — MCM pages, settings, defaults, migrations, tooltips, and diagnostics
- `MMEAlertsPlayerEffect.psc` — restores the controller after startup and save loading
- `MMEAlertsSkyrimNet.psc` — Skyrim.Net checks, prompts, events, nearby summaries, and narration
- `MMEDrinkTracker.psc` — player and NPC milk-drinking detection
- `MMEMilkDrinkEffects.psc` — shared drink reaction sounds
- `MMEMilkBoost.psc` — shared milk-bonus calculation and capacity-safe application
- `MMEArousalBridge.psc` — optional arousal-mod detection and updates
- `MMENPCDialog.psc` — Milkmaid dialogue, inventory selection, consumption, effects, and animation
- `MMEAlertsFlatRateDefaults.psc` — optional FOMOD-selected MME preset
- `MMEAlertsQuickTest.psc` — inert compatibility placeholder retained for the ESP and older saves
- `MMEDebug.psc` — passive troubleshooting helper
- `MMEExtensionsNative.psc` — Papyrus declaration for the native nearby-actor function
- `MMESkyrimNetVoiceControls.psc` — archived experimental actions excluded from release compilation

### Native Code

- `src/Plugin.cpp` — publishes engine events to Papyrus and exposes nearby-actor discovery
- `build-native.bat` / `build-native.ps1` — builds the native DLL
- `build-package.bat` / `build-package.ps1` — compiles Papyrus and creates the distributable FOMOD

### Data and Configuration

- `MMEAlert.esp` — legacy plugin filename containing ME Extensions records
- `SKSE/Plugins/StorageUtilData/MMEAlerts/SkyrimNet.json` — editable Skyrim.Net event messages
- `SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt` — actor-specific Milkmaid context
- `fomod/` — installer metadata and optional defaults
- `assets/sounds/` — source reaction-sound pools

### Build Notes

1. Run `build-native.bat` only after changing the native C++ code or toolchain.
2. Run `build-package.bat` for every distributable build.
3. Install `dist/MME Extensions.zip` with a mod manager.
4. Do not install the staging directory directly.
5. Confirm that General, Milk Drinking, Arousal, Skyrim.Net, and Debug pages appear in the MCM.
6. Keep test-only helpers clearly identified or remove them before release.

</details>

## Credits

- **Ed86** — Milk Mod Economy
- **MinLL and contributors** — Skyrim.Net
- **CharmedBaryon and contributors** — CommonLibSSE-NG

## License

Released under the [MIT License](LICENSE).

MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab Aroused, OSLAroused, or Skyrim.Net release.
