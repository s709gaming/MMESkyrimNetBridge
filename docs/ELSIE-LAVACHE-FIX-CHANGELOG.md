# MME Extensions — Elsie LaVache Fix Changelog

This document covers only the optional Elsie LaVache compatibility patch included with MME Extensions.

## Requirements

- Elsie LaVache 3.4 SE (2020-11-22)
- The original `CP_Elsie.esp` and its requirements
- MME Extensions

This patch does not contain or replace the original Elsie mod. It installs only independently authored compatibility scripts and targeted record overrides.

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
