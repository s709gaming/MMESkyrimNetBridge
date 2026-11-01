# Original MME override audit — 2026-10-29

## Scope and evidence

Read-only comparison of repository sources, build allowlists, FOMOD choices, the current `dist/MME Extensions.zip`, and houseCARL's configured MO2 VFS. Confirmed instance: `VortexToMO2`, profile `Default`; ModOrganizer.ini agrees. The MO2 Agent Control info command reported that its recorded MO2 process was not running. VFS results describe configured file precedence, not a live game's loaded scripts.

Original comparison baseline: the installed `Milk-Mod-Economy-Scripts-20220522.7z/scripts/source` sources. No installed files, profiles, game files, or gameplay were changed. This is a script/file replacement audit; it does not claim a full record-by-record audit of MMEAlert.esp.

## Standard backend: one unconditional original script replacement

`build-package.ps1` explicitly compiles and packages `Source/MMECompatibilityOverrides/MilkQUEST.psc` as `Scripts/MilkQUEST.pex` and `Source/Scripts/MilkQUEST.psc`. The current archive contains exactly one base script whose name overlaps the installed original MME compiled scripts: MilkQUEST. Both its archived source and compiled file are byte-identical to the corresponding repository files. This checks packaging consistency, not a fresh compilation or proof of runtime behavior.

The full source diff against the installed original contains these changes:

| Change | Purpose | Cost if another replacement wins |
| --- | --- | --- |
| AssignSlot and AssignSlotMaid scan slots 1 through Length-1, incrementing after access | Fix original NPC counting loops reading index Length; preserve player slot 0 | Original array bounds bug returns unless the other script fixes it |
| Eight expression applications use MMEExtApplyExpressionSafe | Skip missing actor/framework/expression safely; one gated missing-expression breadcrumb | Missing-expression errors may return |
| Fourteen DD queries use MMEExtDDCheck | Verify actor, DD Assets/Integration, zadQuest and MME bridge before invoking original bridge methods; gated traces and deduplicated failure alarms | Absent/broken optional DD can again enter unsafe bridge calls |
| Two closed-gag MessageBox calls become gated traces | Keep feeding blocked while removing modal popup interruptions | Original gag popups return |

**Correction to existing documentation:** `MME_MilkCycleComplete` is already sent by the original installed MilkQUEST source (line 572); the extension copy retains it (line 587). It is not a new extension hook. The controller's weight/body/refit/Dwemer reconciliation and the reverse-level listener therefore do not, merely by listening to this event, require our MilkQUEST replacement. Removing the replacement would still require integration and runtime validation.

The replacement also calls extension-owned MMELog. Do not distribute this MilkQUEST as a standalone generic MME fix without accounting for that dependency.

## Optional backend replacements

| FOMOD choice | Original MME files replaced | Reason |
| --- | --- | --- |
| Standard SexLab | MilkQUEST.pex | Safeguards above |
| SexLab P+ | MilkQUEST.pex plus MME_Dialogues.pex and MilkPlayerLoadGame.pex | Dialogue uses P+ scene IDs/StartSceneEx; load-game maintenance replaces legacy animation registrar detection with a forced true breastfeeding flag. Includes converted animation/behavior files and registry assets that can also compete with animation packages |
| Experimental OStim-only | MilkModNEW.esp plus 11 original MME scripts | Broad backend port, not a narrow compatibility fix; replaces SexLab integration and deliberately disables the original DD bridge |

OStim-only's original script names: MilkQUEST, MilkPlayerLoadGame, MilkLactacidScr, MilkPUMP, MilkPUMP_milkbarrel_example, MME_StartMilking, MME_CheckForSpriggan, MME_Dialogues, MME_DDi, MME_MilkSuccubus, MME_zbf. Its other replacement scripts are extension-owned variants. This option needs its own compatibility review against any other MME overhaul; the manifest still marks runtimeValidated false.

The P+ forced animation flag is not proof that animation registration/behaviors are healthy. It is an additional reason to keep that replacement backend-specific.

Elsie and JUGS compatibility choices replace those mods' scripts, not original MME scripts. Their overlap is separate and remains optional. Startup choices replace extension-owned defaults/quickstart scripts; they do not remove the unconditional MilkQUEST replacement, including when choosing Vanilla defaults.

## Current configured MO2 winners

- MilkQUEST.pex: MME Extensions > original MME scripts mod > unmanaged physical Data.
- MME_Dialogues.pex, MilkPlayerLoadGame.pex, MME_StartMilking.pex and MilkModNEW.esp: original MME scripts mod > unmanaged physical Data.
- No additional enabled provider appeared for those checked paths; no overwrite provider appeared. Disabled mods and mods not installed are not ruled out as competitors.
- Repository `Scripts/MME_StartMilking.pex` is a stale output. The build allowlist excludes it from the standard release archive, and it is not the current configured winner. Do not copy the whole repository Scripts folder into a manual installation.

## Recommendation

Make the standard MilkQUEST safeguards a separate, clearly described optional compatibility component. The cycle event is native to the verified baseline, so it does not justify forcing ownership of this central script. Keep the slot fix, expression guards, DD guards and popup policy individually documented, with a clear loss-of-fixes explanation when omitted.

For a competing MilkQUEST overhaul, merge the required changes into that mod's verified source or supply a compatibility-specific variant. MO2 priority chooses an entire PEX; it cannot merge functions. Simply telling users to let Extensions win can discard an overhaul's changes, while letting the overhaul win can discard these safeguards. An MCM toggle cannot avoid that file conflict because the replacement has already won before settings are evaluated.

Retain P+ and OStim replacements inside their exclusive backend options. Consider narrower dialogue/backend entry points where feasible, but do not assume external listeners can repair an out-of-bounds access or replace an internal unsafe call. Validate player/NPC routes, dependency presence/absence and existing saves before shipping any refactor. No implementation or release rebuild was performed for this audit.

## Fixed-mode Lactacid boost ? 2026-11-01

- MilkQUEST now calls MMEFixedLactacid only inside the existing fixed-production branch. Default ON; +50% default, MCM range 0-200% in 5% steps. Each stored unit fuels one simulated MME hour. No inventory auto-drinking, conversion, actor slots or dynamic lactation changes.
- Original fixed Lactacid deduction is replaced while enabled, preventing double consumption. OFF retains its original decay/output rules. Dynamic production remains byte-for-byte unchanged in source.
- Extra fuel extends duration, without stacking the percentage. Fractional fuel gets a proportional final-hour bonus; catch-up splits boosted and normal production. Existing breast-scale production caps remain; fuel expiry uses elapsed hours before that cap.
- Uses MME's existing scheduler, without another timer. Normal MilkPoll 1-24 uses elapsed game hours, including sleep/wait. Legacy MilkPoll >24 processes one simulated hour per real-time tick, as original MME does; it is not a wall-clock game-hour timer.
- MilkMCM's fixed hourly production preview calls the same helper; this is a second narrowly scoped original-menu change alongside the previously reviewed difficulty sync. Extensions General contains the toggle and bonus slider. Controls are disabled when neither fixed mode is selected; the NPC-only fixed flag remains supported.
- Missing settings default ON/+50% before MCM migration. MCM version 169 initializes only missing keys, preserving explicit OFF and custom percentages on existing saves. 0% still consumes fuel hourly; OFF restores original behavior. The existing original decay/strength settings remain applicable to original routes, not the enabled fixed override.
- Standard/P+, generated OStim-only and Estrus-unified MilkQUEST variants require the shared helper. A competing MilkQUEST replacement can bypass the feature; an MCM toggle cannot merge whole-script overrides.
- Master-gated cycle traces identify actor, elapsed hours, before/remaining fuel, actual bonus and expiry. Deduplicated alarms fire at invalid input/settings or failed JSON save, independently of routine logging. Expected zero fuel/disabled state produces no alarm.
- This changes production, so existing MME downstream overflow, pain reduction and optional production-based progression receive the boosted total. No independent capacity/level calculations are added.
- Static/numerical/compile/package checks do not establish live behavior. Player/NPC, fixed flags, ON/OFF, sleep/wait, saves, optional dependencies, logs and original MCM previews require acceptance after separately authorized installation.
