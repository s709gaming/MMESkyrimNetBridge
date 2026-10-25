# OStim-only follow-up investigation and fix preflight

Date: 2026-10-25. Read-only investigation; no gameplay changes or deployments.

## Implementation follow-up

The bounded repository implementation is now present: dedicated conversion gate
0008D0 and typed source/target conditions; controller refresh at established
boundaries; isolated CurrentSize refresh; succubus bounds/null guards; dynamic
ZaZ-keyword bridge; and an explicitly unavailable original-DD bridge in the
OStim-only selection. FOMOD rejects active SexLab and original DD masters in that
selection. Standard and P+ integrations retain their existing implementations.

The plugin comparison against the pre-change repository copy preserved the
master list and every pre-existing record payload except INFO 00087E. The only
new record is global 0008D0; TES4 metadata changes accordingly. Exact MME faction
properties resolved to 04D53B (Milk Maid) and 056707 (Milk Slave).

All 24 final isolated variants compiled, and the expanded check passed across
65 effective MME scripts. The full package build passed, including standard/P+
and legacy compatibility contracts and typed dialogue checks. Archive inspection
verified 506 entries, 24 matching PSC/PEX pairs, both plugin hashes, current common
scripts/FOMOD/docs, ZIP integrity and exclusion of diagnostics/dummy SexLab.esm.
Final archive: dist/MME Extensions.zip, SHA256
7d8bfc0fe6344a7a04feb33d66d858f157d85e43135c3e8937bd01952730ef5a.
Evidence: build/diagnostics/ostim-followup-package-final.log and
verify_followup_archive.py. Runtime validation of this revision is pending. No installed
mod, profile, Vortex staging, physical Data file or running game was changed.

Full ZaZ adaptation and the separate OSL/SOS adapter issues remain outside this
bounded implementation. Their errors are neither suppressed nor claimed fixed.

## Completed preflight decision (2026-10-25)

GO for the bounded MME implementation below. NO-GO for declaring the complete
test installation clean or promoting the option beyond experimental until the
runtime and third-party gates pass. Preflight completion is not release approval.

### Verified dependency attribution

| Finding | Actual winning provider / binding | Disposition |
| --- | --- | --- |
| NG inflation | SLIF NG; native load, actor-specific MME Inflate requests and matching CBBE 3BA morph readbacks | Keep NG; no legacy helper patch. Reduction/unregister still untested. |
| ZaZ missing sslAnimationFactory parent | ZAZ 7.0SE-Rev1.7z zbfSexLab | Genuine third-party integration failure; do not suppress or claim all ZaZ functionality supported. |
| zadlibs linking failures | OSL Aroused FOMOD 2.9.3, overriding physical Data | Not evidence that DD is active. Audit installer payload separately; MME's existing DD gate requires both DD masters and zadQuest. |
| MusSOSManagerSL binding failure | CBBE 3BA (3BBB); SOSPhysicsManager.esp quest 000802 | SexLab-specific adapter; quest 000803 separately binds MusSOSManagerOstim. Do not remove the whole physics plugin. |
| Conversion response generation failure | Skyrim.Net generated player response after successful conversion | Separate optional narration issue; do not repeat or roll back conversion to repair narration. |

houseCARL verified ZaZ quest bindings: 0137E6 owns zbfBondageShell, 00CD14
owns zbfSexLab and its animation-entry aliases, 00C243 owns zbfConfig, and
0096B2 owns zbfSlaveControl/zbfSlaveLeash/zbfSlaveActions. Source closure includes
zbfSexLab's missing parent and ssl-typed exports, zbfConfig's typed property and
entry state, zbfSlaveActions' typed property and generic scene starter, zbfUtil's
typed getters, and zbfBondageShell's deprecated tag calls/entry argument.
zbfExternal links Config; zbfExternalInterface and zbfSexLabBaseEntry also need
to be retained when compiling/testing that closure. The base-entry script itself
extends ReferenceAlias, not a missing SexLab class. Its name alone is not a fault.
Evidence exports are in build/diagnostics/no-sexlab-vmad-details.jsonl and
zaz-no-sexlab-source-closure.json, outside release packaging.

### Concrete next implementation scope

1. Fix conversion INFO 00087E visibility with a dedicated source gate and
   authoritative player/target conditions as detailed below. Verify the actual
   faction and unused global against the plugin before allocating or editing.
2. Add the isolated original MME_MilkSuccubus bounds/null/optional-arousal fix.
   Preserve its player-cell scan and gameplay calculations.
3. Isolate MME's ZaZ gag bridge in the OStim-only choice. The installed original
   MME_zbf exposes OnInit, IsIntegraged, IsWearingZaZGag and
   IsWearingZaZGag_Open. Preserve those names/signatures and StorageUtil status
   semantics; replace its typed zbfBondageShell lookup with dynamically resolved
   Keyword forms. Verified records: zbfWornGag=008A4D:ZaZAnimationPack.esm and
   zbfWornPermitOral=019FDA:ZaZAnimationPack.esm. Guard missing actor/plugin/form;
   retain the original distinction between gag and oral permission. This avoids
   MME depending on ZaZ's broken script module without removing ZaZ assets,
   restraints or plugin records. It is not a full ZaZ framework repair.
4. Expand dependency validation beyond the 21 selected scripts: include original
   MME bridge dependencies and their effective VFS providers. The existing
   bytecode test proves the selected variants, not their entire transitive
   runtime closure. Check MME_DDi's zadlibs types and prevent unsupported DD
   integrations from being advertised as working in the no-SexLab branch.
5. Keep the full ZaZ framework adaptation and third-party SOS/OSL installer
   corrections isolated from the MME core. A full ZaZ adaptation requires a
   pinned no-SexLab variant across the above callers and VMAD contracts, rather
   than a two-getter guard or a fake ssl parent. If it is not included, document
   the known failure and retain experimental status; do not call the broader
   installation fully supported. Do not silently alter third-party APIs.

No custom SLIF override, wholesale ZaZ removal, dummy SexLab ESP/scripts,
existing-save migration, native OStim patch, or error suppression is in scope.
Elsie/JUGS remain excluded from this first MME-only option. Preserve normal and
P+ branches; keep compatibility overrides exclusive to the selected option.

### Diagnostics and acceptance

Use MMELog.MasterDiagnostic for sparse source/target eligibility, route result,
cleanup and skip reasons. Logging off must suppress routine footprints. Missing
optional mods and ineligible actors are expected skips. Broken required quest/
form bindings or impossible state get deduplicated MMELog.Alarm failures with
operation, actor and reason. Do not add a polling loop or player notifications.

During implementation compile every changed PSC, verify source/PEX hashes and
bytecode, validate plugin references/conditions and FOMOD exclusivity, then rebuild
and inspect the distributable. Do not deploy or alter installed files as part of
repository implementation. Test each changed route with player and NPC targets,
feature/master off, missing optional dependency, busy/combat states, repeated
calls, cleanup and save/reload. In a fresh SexLab-absent game verify actual
inflation decreases after milking and unregister removes only MME's contribution.
Existing-save switching remains unsupported rather than implicitly migrated.

Baseline tools/Test-OStimOnly.ps1 passed during this preflight: exclusive choices,
dependency guards, source/compiled hashes and selected bytecode dependency checks.
Those tests do not certify third-party scripts or substitute for the runtime
acceptance cases above. Nothing further is required from the user to start the
bounded repository implementation; release gates remain explicit work.

## Runtime update and implementation boundary (11:19 session)

SLIF NG is now enabled. Its plugin, SLIF_Main.pex and BodyInflationNG.dll win.
The native log confirms load, Papyrus registration and CBBE 3BA profile loading.
The live load-order response lists NG at FE012 and no SexLab.esm. SkyLink's
connection probe returned false despite its load-order response succeeding;
runtime conclusions here are independently supported by fresh local logs.

Player conversion completed at 11:22. NG received Milk Mod Economy Inflate
requests for player 00000014 and applied slif_breast morphs with matching
readbacks. Extensions' separate level-zero morph application also verified its
readback. This establishes player conversion and inflation, not NPC parity,
decreasing inflation after milking, unregister cleanup or existing-save safety.
No custom legacy SLIF helper override is warranted for this NG configuration.

Release target remains MME's OStim-only option with SexLab framework absent.
Dialogue source gating and succubus bounds guards are ready for implementation,
subject to the exact record/source checks described below. No additional user
input or game shutdown is required for repository-only implementation.

Before calling the whole release ready, complete ZaZ type-closure and VMAD
auditing, attribute the current zadlibs and MusSOSManagerSL linking errors to
their actual winning providers/callers, and determine the supported dependency
boundary. A dependency's error is not automatically an MME package defect, but
an MME-required route through it cannot be left broken or called supported.
Do not add fake SexLab declarations or suppress engine failures.

Retain NPC conversion, milking reduction, cleanup/repeat-use, logging-toggle and
dependency-absent tests as release gates. Current Skyrim.Net player-response
generation failure is separate from successful MME conversion. Old SLIF loose
helpers remain exposed under NG and require a scoped cleanup inventory.
Installation cleanup and deployment remain separate from repository changes.

## Replan after SLIF NG installation (2026-10-25)

This update supersedes the immediate SLIF helper-patch recommendation below.
The older evidence is retained as history, not a finding against SLIF NG.

Verified current installed state:

- SLIF NG is installed as version 0.4.17.0, with BodyInflationNG.dll version
  0.4.17.0, a 522-byte replacement SexLab Inflation Framework.esp and new scripts.
- Its modlist entry is currently disabled (`-SLIF NG`).
- houseCARL still resolves SLIF_Main.pex and SLIF_SexLab_Script.pex to physical
  Data, not NG. The physical legacy plugin is 4,259 bytes.
- The latest Papyrus log remains the 08:06 session ending at 08:11:49; it predates
  the new installation. It does not demonstrate any SLIF NG runtime failure.
- NG's shipped source scan found no SexLabFramework/ssl-type or
  SLIF_SexLab_Script references. Its SLIF_Main compatibility facade forwards to
  SLIFNG natives instead of the old gender helper. No old gender-adapter patch
  should be added to NG on the basis of the previous log.

NG's supplied event alias registers SLIF_inflate and SLIF_unregisterActor.
Installed original MME_BodyMod sends a five-argument SLIF_inflate event
(actor, mod name, key, value, old mod name), and our MilkQUEST retains the
two-argument unregisterActor event. NG's upstream compatibility contract lists
these same event shapes:
https://raw.githubusercontent.com/crajjjj/SLIFNG/main/CONTRACT.md
The upstream survey's claim that its surveyed MME only unregisters is narrower
than this installation's source evidence: do not assume its MME build is ours.
Verify actual body changes and cleanup, not merely API names or that survey.

Revised first step, before another custom SLIF patch:

1. In the controlled new-game test profile, resolve NG activation and make its
   plugin, scripts and native DLL the actual winners. Do not change installed
   files as part of this read-only investigation.
2. Inventory and quarantine confirmed legacy SLIF-exclusive loose leftovers,
   with hashes and restore manifest, after cleanup authorization. Keep unrelated
   and shared files. Otherwise old helpers can still be exposed beneath NG.
3. Confirm NG supports runtime 1.7.104 through its own successful startup/native
   registration log. Static source inspection is not runtime approval.
4. Recheck the legacy Tullius Bodymorph settings mod against NG's actual body/
   region configuration support; do not assume the old JSON layout transfers.
5. Start a new game for a clean absence test; the replacement is ESL-flagged and
   old saved quests/gender caches must not be treated as a fresh NG result.
6. Inspect fresh Papyrus and NG logs, test MME breast/body changes and cleanup,
   and independently test Extensions' Maid-level morph contribution. Preserve
   other mods' morph ownership. Do not run migration/repair actions automatically.

Then prioritize the confirmed conversion visibility and succubus reference-loop
fixes. The ZaZ closure investigation remains necessary and independent of NG.
OSA registration pairing remains a separate lower-priority investigation.
No script override, installation, quarantine, setting, or live state was changed
during this replan.

## Evidence baseline

The 08:06 session's live SkyLink load order contains OStim and MME but not
SexLab.esm. Papyrus reports the OStim-only backend ready. The first player-source
conversion request was correctly rejected before the player became a Milk Maid.
The later player-to-Hulda request confirmed startup, scene end, owned cleanup,
and Hulda's canonical MME Lactacid creation effect. This validates that observed
route, not all dependency-absent functionality or every adapter.

Winners were checked with houseCARL: zbfUtil from ZAZ 7.0SE-Rev1.7z;
SLIF_SexLab_Script from SexLab Inflation Framework SE 1.2.2 beta Installer.7z;
OSANative from OStim Standalone; MME_MilkSuccubus from original MME Scripts.
Sources and logs were inspected directly. OSANative's winning PEX was also
disassembled into build/diagnostics, outside release contents.

## 1. Conversion dialogue visibility — confirmed, fix design ready

INFO 00087E:MMEAlert.esp, MMEExt_NewMilkMaid, prompts:
"Wanna become a Milk Maid? Have a taste! Straight from the tap."
Its two conditions are global 00085A == 1 and female dialogue subject.
There is no player Milk Maid condition or player milk-quantity condition.
RefreshOStimDialogueAvailability sets 00085A from general OStim feature readiness,
not source eligibility. The independent SexLab conversion gate already considers
player-source eligibility, but it does not control this OStim INFO.

Do not tighten general global 00085A: it also controls other OStim choices,
including the player drinking from an NPC. The conversion INFO needs a dedicated
source-availability gate, using the existing ValidateMilkSource predicate and
MME's current milk >= 1. Preserve the action-time validation, which worked.
Add an authoritative player-reference faction condition to prevent a stale true
cached source gate exposing this option before conversion. Resolve the actual
MME faction property from the plugin during implementation; do not guess IDs.
Target-side conditions should reject an existing Milk Maid/Slave and child NPC;
retain the current female-subject restriction and full action-time eligibility.

Refresh the dedicated gate at established dialogue/lifecycle, settings, conversion,
and milk-change boundaries. Check ordering before dialogue choices are evaluated;
no new polling loop. Preserve existing FormIDs, branch links and result fragments.
Choose a verified unused FormID for any new global. The fix should apply to the
common dialogue data, with equivalent controller handling in the generated variant.

Test: non-maid source hidden; maid with insufficient milk hidden; eligible source
and eligible NPC visible; already-converted Hulda hidden; slave/child rejected;
disabled feature/master hidden; player-drinks-from-NPC route unaffected; source
state changes and save/load cannot leave a stale visible choice.

Footprints: sparse [MME Extensions Dialogue Gate] via MMELog.MasterDiagnostic,
including source actor, backend, source eligibility/milk result, old/new gate and
refresh reason. Trace state changes and useful dialogue entry, not every scheduler
tick. An expected ineligible source is not an alarm. Missing required global or a
failed write/readback is a deduplicated alarm with operation and source actor.

## 2. SLIF gender adapter — confirmed, narrow optional override feasible

SLIF_SexLab_Script.GetGender declares a SexLabFramework local. ForceSexLabGender
also declares that type despite its plugin-availability guard. With SexLab absent,
the log reports failure linking both functions. SLIF_Main.GetGender then calls the
unavailable helper from its inflation path (observed during Hulda's conversion).

Original SLIF_Main.GetGender preserves cached slif_gender first, asks the SexLab
helper next, caches results 0..6, and otherwise falls back to actor-base sex.
A no-SexLab implementation of the helper can return its supplied gender unchanged;
the existing SLIF fallback then remains authoritative. SexLab synchronization
functions become guarded expected skips. Preserve all public signatures and SLIF
gender codes; do not substitute the new MME backend's 0/1/2 classification for
SLIF's 0..6 classification. Keep this override exclusive to the no-SexLab option
and conditional on the supported SLIF installation.

The failed call returns None; inspect whether the VM coerced/cached a valid-looking
zero before deciding any migration. Do not bulk-clear or rewrite slif_gender:
legitimate cached/manual choices must be preserved. Use fresh-game tests first,
then a separately reviewed targeted repair if polluted values are demonstrated.

Test stored codes 0..6, unset -1 fallback, male/female NPC and player inflation,
SLIF absent, repeated events, no unwanted gender writes, and unchanged normal/P+
branches. Audit all helper exports/callers, compile the entire override without
SexLab declarations, and inspect its bytecode. Document the invasive override.

Footprints: master-toggle initialization and deduplicated fallback/synchronization
skip traces, identifying actor when applicable. No per-morph/per-node spam, no
alarm for deliberately absent SexLab, and no notification for routine diagnostics.

## 3. ZaZ type closure — confirmed new concern; broader audit required

zbfUtil.GetSexLab and GetSL return zbfSexLab. That class inherits from the absent
sslAnimationFactory. The VM reports those two type-link failures, then cannot call
zbfUtil.GetVersion from zbfConfig.GetVersion/CheckVersion on reload. Merely adding
Game.GetModByName guards does not remove a missing return type or parent class.

This is not confined to two getters: zbfConfig declares a zbfSexLab property and
zbfSexLabBaseEntry state; zbfBondageShell has deprecated calls through GetSexLab
and a method accepting zbfSexLabBaseEntry. A minimal change to the getters alone
cannot be declared a complete ZaZ fix. Changing their return type to Quest would
also change an existing API contract and must not be presented as drop-in safe.

Before implementation, enumerate the affected ZaZ script inheritance/signature/
property closure, its quest VMAD bindings, MCM initialization and all callers.
Then choose an isolated no-SexLab ZaZ compatibility variant or another supported
ZaZ configuration. Keep bondage keywords, constraints, idles and MME pump assets
intact. Removing ZaZ wholesale is not an approved substitute for that audit.
Do not install fake SexLab scripts or suppress engine errors to conceal the issue.

This is the largest scope/risk item and should be a separate compatibility change.
No claim of a quick, fully specified ZaZ patch is made here. Retest core ZaZ/MCM
and MME restraint/idle behavior with the dependency absent after any chosen fix.

## 4. MME succubus milk LOS — confirmed original boundary bug

Original MME_MilkSuccubus.OnEffectStart scans PlayerREF.GetParentCell using
iRef <= cell.GetNumRefs(43), then immediately calls aNPC.HasLOS(akTarget).
The final index is outside the count; other lookups can also legitimately return
None. The 08:07:28 log points to that unguarded call at line 23.

Narrow fix: validate target, required MME quest and cell; cache the count; use
iRef < count; check the cast actor before HasLOS. Preserve the existing player-cell
scope (do not silently switch to target-cell scanning), transformation logic,
fixed arousal change and other gameplay. Guard the optional arousal integration
without aborting unrelated transformation effects. Caster None need not invalidate
a valid target, since this implementation does not use the caster.

Test player/NPC drinkers, empty/sparse cells, unloaded refs, repeated use, transition
without a cell, and arousal dependency present/absent. No per-actor polling traces:
master-toggle entry and summary counts/skip reason are sufficient. Missing optional
arousal or transitional cell state is a trace; a broken required quest is a
deduplicated alarm. Isolate and document the original-script override.

## 5. OSA native registration — diagnosis narrowed, defer speculative patch

The current native log says NewObject/DeleteObject cannot be bound on OSANative.
The winning OStim OSANative source comments out both experimental declarations:
Form NewObject(String Classname) and DeleteObject(Form FormRef). The winning PEX
disassembly likewise contains no such functions. Thus the observed direction is
native registration against absent script declarations, not a gameplay call by
our backend to an undefined function. OStim's tested scene nevertheless completed.

Before changing anything, verify the installed OStim DLL/PEX release pairing and
the matching native registration source for runtime 1.7.104. Do not uncomment the
declarations merely to silence the messages without verifying the native return/
parameter types and whether those experimental functions are supported. No DLL
patch, blanket OSANative override, or log suppression is justified by this evidence.
Classify its practical impact separately from the confirmed SLIF/ZaZ failures.

## Implementation order and release gates

1. Dialogue visibility and succubus bounds guards: scoped fixes ready to implement.
2. SLIF NG: player inflation now verified; test reduction and cleanup. Do not
   implement the superseded legacy helper patch for this configuration.
3. ZaZ: complete the broader closure audit and agree the compatibility boundary.
4. OSA: confirm exact native/script pairing before selecting a corrective action.

For every implemented change: preserve unrelated work; do not modify README;
compile all changed PSCs; validate selected PSC/PEX pairs and FOMOD combinations;
retain legacy/P+ regressions; rebuild and inspect the archive; keep test artifacts
out of it. Installed MO2/game files remain unchanged until separately authorized.
Run dependency-absent tests in the controlled new-game profile. Source/compiled
checks do not replace player/NPC runtime, cleanup and master-toggle tests.

No implementation was performed during this investigation. The new ZaZ scope
concern and unresolved OSA pairing are explicit gates, not hidden completed work.
