# MME Extensions

MME Extensions is a development add-on for **Milk Mod Economy (MME)**.

## What this build does

- Plays configurable moans when milking starts or ends, when a Milkmaid becomes full, and when milk is drunk.
- Gives the player configurable milk bonuses for drinking MME milk or regular milk.
- Supports an optional Milkmaid-level bonus and a configurable Lactacid multiplier.
- Can raise the drinker's arousal when SexLab Aroused is installed.
- Reports exact player milk drinks for 90 seconds and milking start/end events for 60 seconds to Skyrim.Net when it is installed.
- Uses a lightweight CommonLibSSE-NG bridge to detect waiting, sleeping, location changes, and save loading. These events refresh nearby Milkmaid capacity state without relying on Papyrus polling.
- Detects MME's Make Milkmaid and Lactacid effects without actor polling, verifies successful new Milkmaids, and publishes a reusable creation event.
- Records each confirmed new Milkmaid as a persistent SkyrimNet recent event when SkyrimNet is installed.
- Can send one replaceable five-minute SkyrimNet summary of nearby Milkmaid fullness using the existing capacity scan and interval.
- Lets players independently disable SkyrimNet tracking for milk drinks, milking, new Milkmaids, and nearby milk statuses.
- Adds an actor-specific SkyrimNet bio prompt that explains Milkmaid lore only for actors carrying MME's Milkmaid level state.
- Uses native nearby-actor discovery for polling and lifecycle refreshes, then passes candidates to Papyrus for authoritative MME validation and gameplay behavior.
- Can optionally poll nearby loaded Milkmaids for half-full and full capacity reactions.
- Adds this dialogue choice to MME's existing **Hey, there** dialogue:
  **Drink this, it will make you milky!**
- The dialogue works only on a valid MME Milkmaid. It gives her one supported milk from the player's inventory, makes her consume it, and applies supported milk, Lactacid, arousal, and moan effects.
- Can optionally play MME's Milkmaid reaction animation after dialogue milk effects finish.
- Provides optional MCM diagnostics for testing each feature.

Milk selection priority for NPC dialogue is:

1. Lactacid
2. Normal milk
3. Racial milk
4. Supernatural milk

Only one item is used per dialogue interaction. MME's normal milk-capacity limits are respected.

## Requirements

- Skyrim Special Edition through SKSE
- Milk Mod Economy
- SkyUI
- PapyrusUtil
- JContainers
- Address Library for SKSE Plugins, or VR Address Library when using Skyrim VR

Skyrim.Net and SexLab Aroused are optional. Their related features turn off when the required mod is unavailable.

SPID is not currently required or active. Its packaged distribution rule remains disabled for possible future NPC monitoring.

## Development status

This is a test build. Player drinking, native lifecycle detection, and the Milkmaid dialogue path are working in current Skyrim AE testing. The CommonLibSSE-NG lifecycle DLL is built as one SE/AE/VR-compatible binary, but its VR behavior still requires in-game verification. NPC dialogue consumption does not send an NPC Skyrim.Net event yet.

## Build and install

Run `build-native.bat` after changing the CommonLib source, then run `build-package.bat`. Install the generated file:

```text
dist\MME Extensions.zip
```

Enable `MMEAlert.esp`, deploy the mod, and launch Skyrim through SKSE.

## Debugging

Useful diagnostics can be enabled on the MCM **Debug** page. SkyrimNet drink, milking, new-Milkmaid, and nearby-status notifications have separate toggles. **Location Wait Load** reports native lifecycle events and nearby Milkmaid status. **Milkmaid Creation Diagnostics** reports detected conversion effects, existing Milkmaids, failed conversions, and confirmed new Milkmaids. Papyrus messages appear in the Papyrus log when logging is enabled; native events are written to `MMEExtensions.log` in the SKSE log folder.

## License

This project is released under the [MIT License](LICENSE). MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab Aroused, or Skyrim.Net release.
