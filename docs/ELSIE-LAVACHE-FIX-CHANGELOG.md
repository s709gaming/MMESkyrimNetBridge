# MME Extensions — Elsie LaVache Fix Changelog

This document covers only the optional Elsie LaVache compatibility patch included with MME Extensions.

## Requirements

- Elsie LaVache 3.4 SE (2020-11-22)
- The original `CP_Elsie.esp` and its requirements
- MME Extensions

This patch does not contain or replace the original Elsie mod. It installs only independently authored compatibility scripts and targeted record overrides.

## Gameplay expansion

- Repaired Elsie's autonomous Milk Maid-to-customer breastfeeding fragments so they validate both actors, reject busy participants, verify the selected animation, and detect SexLab thread-start failures.
- Added automatic fallback from MME's optional 3J breastfeeding registrars to Elsie's bundled `ELV_Taste` animation when necessary.
- Added a one-shot **Test Elsie Auto Breastfeeding** action to the Milk Drinking MCM page. It uses the same checked starter and completion route as the repaired autonomous fragments.
- Added master-toggle-controlled Papyrus footprints and always-on smoke alarms for missing aliases, animations, framework objects, and rejected SexLab starts.
- Added an isolated compatibility facade for Elsie's autonomous `ELV_Taste` SexLab breastfeeding scenes.
- Completed Elsie breastfeeding scenes can now provide the drinker with MME Extensions' existing breastfeeding milk, arousal, notification, flavor, and optional Skyrim.Net effects.
- Added a read-only Elsie detection status and a default-on **Elsie Breastfeeding Gives Milk** control under the Milk Drinking MCM page.
- The existing **Breastfeeding Gives Milk** option remains the master control.
- Added duplicate-safe, master-toggle-controlled Papyrus footprints for recognized and deliberately skipped Elsie scenes.
- This integration does not subtract stored milk from the source Milk Maid.

## Initial release

- Removed the empty, unconditional ninth INFO (`xx12437E`) from the winning `ELV_MQ_C2P_1` generic Hello topic (`xx0944BC`). This entry could be selected as a valid greeting while containing no spoken response, result script, conditions, or continuation.
- Corrected `ELV_DiaGreets_PlayerAliasScript` to extend `ReferenceAlias`, matching the alias on `ELV_DialogueGreetings` where the script is attached.
- Restored the missing `QS`, `CellTracker`, `MC_PlayerRef`, `MC_Elsie`, and `ELV_MakeCows` bindings on the `ELV_FemalePlayer` player alias from Elsie's own complete binding set.
- Added runtime recovery for existing saves that already stored empty Elsie alias properties.
- Added safe guards around Elsie's player-load maintenance and dialogue-quest cleanup.
- Removed the obsolete `Alias_Player` VMAD property from `ELV_TrainCanPers_milk`.
- Added low-volume Papyrus footprints controlled by MME Extensions' master Papyrus logging option.
- Added always-visible Papyrus smoke alarms for missing properties that prevent dialogue cleanup or maintenance.

## Known issue under investigation

`ELV_CanPersMelonsPlayerTopic1` (`xx040451`) contains a visible player prompt whose INFO has no response, result fragment, or linked continuation. It has not been changed because its intended scene transition cannot be established safely from the shipped records alone.

## Installation and load order

The FOMOD selects this component when `CP_Elsie.esp` is active. Keep `MME Extensions - Elsie LaVache Fix.esp` after `CP_Elsie.esp` so its targeted overrides win.

The fix is designed for both new and existing saves. Make a normal save before changing any scripted mod configuration.

## Diagnostics

Enable the MME Extensions master Papyrus logging option to record successful lifecycle footprints. Search `Papyrus.0.log` for:

```text
[MME Extensions Elsie Fix]
```

Messages containing `ROUTE CLOG` identify missing bindings that prevent a repair path from operating.
