# MME Extensions

MME Extensions is a development add-on for **Milk Mod Economy (MME)**.

## What this build does

- Plays configurable moans when milking starts or ends, when a Milkmaid becomes full, and when milk is drunk.
- Gives the player configurable milk bonuses for drinking MME milk or regular milk.
- Supports an optional Milkmaid-level bonus and a configurable Lactacid multiplier.
- Can raise the drinker's arousal when SexLab Aroused is installed.
- Reports player milk drinking and milking events to Skyrim.Net when it is installed.
- Adds this dialogue choice to MME's existing **Hey, there** dialogue:
  **Drink this, it will make you milky!**
- The dialogue works only on a valid MME Milkmaid. It gives her one supported milk from the player's inventory, makes her consume it, and applies supported milk, Lactacid, arousal, and moan effects.
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

Skyrim.Net and SexLab Aroused are optional. Their related features turn off when the required mod is unavailable.

## Development status

This is a test build. Player drinking and the Milkmaid dialogue path are working in current testing. NPC dialogue consumption does not send an NPC Skyrim.Net event yet.

## Build and install

Run `build-package.bat`. Install the generated file:

```text
dist\MME Extensions.zip
```

Enable `MMEAlert.esp`, deploy the mod, and launch Skyrim through SKSE.

## Debugging

Useful diagnostics can be enabled on the MCM **Debug** page. Messages also appear in the Papyrus log when logging is enabled.

## License

This project is released under the [MIT License](LICENSE). MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab Aroused, or Skyrim.Net release.
