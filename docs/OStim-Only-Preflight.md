# OStim-only MME FOMOD preflight

Date: 2026-10-25. Investigation only; no gameplay implementation, plugin edits,
installation, or live-game mutations are included in this preflight.

## Decision

Proceed as a staged compatibility port. A FOMOD checkbox alone cannot remove
SexLab. Phase one covers MME and MME Extensions; Elsie and JUGS follow later.
The initial supported target is a new game in a separate MO2 profile, not removal
of SexLab from an existing save. Keep the working profile and original mods.

## Verified blockers

- Installed MilkModNEW.esp directly masters SexLab.esm.
- Installed CP_Elsie.esp and Jugs.esp directly master SexLab.esm.
- The active Elsie compatibility plugin and SLAnimLoader.esp also master SexLab.esm.
- MME's original full scripts use SexLab for validation, actor activity, armor
  stripping policy, gender classification, actor exclusion/animation faction,
  voices, expressions, scene startup, registration, and scene event hooks.
- MME Extensions' current breastfeeding facade exposes SexLab types, including
  sslThreadController. Its current signature is not a framework-neutral contract.
- The P+ backend calls SexlabRegistry.SceneExists. Installing it with standard
  SexLab previously produced unbound-native errors; incompatible backends must
  not be independently selectable or leave stale files on reinstall.
- OStim startup, MME milking completion, and cleanup were observed on the dialogue
  route with SexLab still installed. This is not a SexLab-absent validation.

## Initial source inventory

Verified original source paths requiring review include MilkQUEST,
MilkPlayerLoadGame, MilkLactacidScr, MilkPUMP, MME_StartMilking,
MME_CheckForSpriggan, and MME_Dialogues. Review the milk-barrel pump example if
used by shipped records. MilkMCM also exposes framework-related settings.
Audit MME Extensions callers as well, including MMEArmorScript, MMEDebug,
MMEAlertsController, and breastfeeding facades.

Mentions of SexLab Inflation Framework, SexLab Aroused, and optional SexLab
integration mods do not alone establish a dependency on the SexLab animation
framework. Audit their actual plugin masters, script types, and runtime calls
separately; do not remove body morph or arousal support merely by name matching.
This inventory is an implementation starting point, not a completed dependency
closure or record-reference audit.

## API boundary

Use a common facade with focused methods, not a boolean distributed throughout
gameplay scripts. Keep framework-specific implementations isolated. The common
API must not accept or return SexLab/OStim thread classes or other optional types.
Use actors, forms, simple values, and owned request tokens. Specify before coding:

- Backend identity, readiness, and capability reporting.
- Actor eligibility and busy checks, checked again at scene commit.
- Armor removal policy with explicit no-strip protections.
- Reserve/release actor ownership for MME milking independently of OStim scenes.
- Scene request, asynchronous confirmation, completion/cancellation, timeout,
  and cleanup limited to the scene this request owns.
- Canonical source/drinker roles; translate framework-specific participant order
  only inside adapters. Completion is idempotent across duplicate events.
- Optional voice/expression presentation: an unsupported capability may skip;
  no unguarded PickVoice().Moan() chains or mandatory SexLab facial types.
- Gender classification must preserve existing MME handling; vanilla actor sex
  alone is not an equivalent replacement for the current framework query.

Keep MME slot arrays, progression, capacity, conversion, milk calculations,
inventory transfer, and production timing authoritative in MME. Reuse the existing
OStim integration and milk-transfer API where their contracts fit; do not create
a second competing lifecycle or transfer path.

## Plugin and script work required before release

Enumerate every SexLab-owned record link, condition, VMAD property, and attached
script on the MME plugin and its downstream supported plugins. Replace/remove
those references deliberately, then rebuild the appropriate no-SexLab variant
without changing existing MME FormIDs or compacting records. A later-loading ESP
cannot cancel the original master's requirement; a supported replacement or
equivalent installation variant is necessary. Removing a MAST entry alone is not
a port. Preserve and document upstream provenance and redistribution constraints.

Compile the selected common/OStim-only scripts without SexLab sources on their
import paths. Inspect their compiled dependency closure and plugin references,
not just source text. Isolate legacy typed properties and SexLab registration
logic in the legacy branch; do not preserve them in the no-SexLab variant simply
to satisfy an old property name. Any save migration is separate work.

## FOMOD design

Add an explicit SelectExactlyOne backend group: Standard SexLab, SexLab P+,
and OStim-only MME. Keep current default behavior for existing users. Remove the
independently selectable P+ backend option or tie it to the exclusive selection.
All backend files, source counterparts, and plugin variants must follow that
selection consistently. Detect active OStim for the OStim option and explain
required scene assets; availability detection is not proof of API compatibility.

Phase one must prevent selecting existing SexLab-dependent Elsie/JUGS patches
with OStim-only. Explain their unsupported status, including the need to disable
their original plugins in the separate no-SexLab test profile. Do not silently
disable installed mods. Audit all other enabled plugins for SexLab master chains.
Provide clean replacement/reinstall instructions so P+ or legacy scripts cannot
survive as leftovers. Inspect every valid selection's effective installed files.

## Papyrus footprints and failures

Use a consistent prefix such as [MME Extensions Backend]. Routine footprints
must use MMELog.MasterDiagnostic: enablePapyrusTrace alone, not an additional
verbose requirement. Never put routine diagnostics in player notifications.

At initialization report selected backend/version, dependency and capability
results. At request boundaries report caller, token, actor identities, normalized
roles, eligibility or concrete skip reason, selected scene, startup result,
completion/transfer result, cancellation, and cleanup. Record control/ownership
release and whether a callback was ignored as duplicate or stale. Trace armor
policy at a decision boundary, not on every polling pass. Repeated unchanged
availability and unsupported presentation skips must be deduplicated or verbose.

Expected absence of SexLab in OStim-only, unsupported optional presentation,
disabled settings, busy targets, cooldowns, and no eligible actor are gated
traces, not smoke alarms. Genuine failures use deduplicated MMELog.Alarm with
operation, token, actor, backend, and reason: selected required backend cannot
initialize, invalid actor/role state, failed confirmed request, lost ownership,
or failed cleanup. Do not attempt an unavailable native merely to log its error.
Treat native Papyrus errors as bugs to prevent, not useful diagnostic footprints.

## Acceptance gates

1. Resolve design and complete the plugin/script dependency audit above.
2. Compile every changed script; all selected PSC/PEX pairs match. Build-time
   checks cover backend exclusivity, installed file selection, and absence of
   forbidden runtime types/masters. Preserve existing legacy/P+ regression checks.
3. Build the distributable and inspect the FOMOD root, variant contents, source
   pairs, required assets, and exclusion of diagnostics, shims, and failed builds.
4. In a separate new-game MO2 profile, verify zero missing masters and no physical
   Data/overwrite leftovers providing SexLab scripts or DLLs. Check actual VFS
   winners before trusting a dependency-absent result.
5. Test player-source/NPC-drinker and NPC-source/player-drinker separately,
   repeated scenes, duplicate hooks, rejection, interruption, and owned cleanup.
   Verify milk/inventory changes occur exactly once on the intended actors.
6. Test pumps, standalone milking, dialogue, lactacid, armor strip protections,
   leaking, gender handling, and optional DD absent/present behavior.
7. Test disabled MCM/master behavior, combat/busy/movement guards, cooldowns,
   timing, OStim unavailable, missing scenes, save/load, and logging off/on.
8. Master logging off produces no routine backend traces; on gives useful request
   footprints without loop spam. No unbound natives, None calls, leaked controls,
   wrong actors, or recurring alarms. Confirm runtime loaded state read-only.

Do not claim runtime approval from compilation or from manual dps output. Record
Alt+F4 reports separately from spontaneous crashes; use normal quit for tests.

## Current status

Updated audit: architecture and direct MME record preflight are complete;
implementation is the next step. The current installed setup remains
SexLab-dependent. Compiled/transitive dependency closure, generated replacement
round-trip checks, and runtime behavior are acceptance gates for implementation,
not claims already validated by this preflight.

## Completed direct-record audit

houseCARL enumerated all 318 forms defined by the installed SexLab.esm and queried
MME for references to that whole set in one batch. Six records matched; all six
were inspected from the MME plugin itself, not a generated patch or later winner.
The complete source-plugin VMAD projection covered 619 records without truncation.
The direct matches are:

| MME FormKey | EditorID | SexLab dependency | Planned replacement |
|---|---|---|---|
| 000D62:MilkModNEW.esp | MME_6TITS | Keywords[0]: 02F16E:SexLab.esm (SexLabNoStrip) | Local protection keyword |
| 000D67:MilkModNEW.esp | MME_MilkCuirass_FUTA | Same keyword | Local protection keyword |
| 001D8D:MilkModNEW.esp | MME_4TITS | Same keyword | Local protection keyword |
| 001D8E:MilkModNEW.esp | MME_8TITS | Same keyword | Local protection keyword |
| 005B10:MilkModNEW.esp | MME_MilkCuirass | Same keyword | Local protection keyword |
| 00E209:MilkModNEW.esp | MME_MilkQUEST | MilkQUEST script SexLab object property: 000D62:SexLab.esm (SexLabQuestFramework) | Remove from OStim-only VMAD and script |

Machine-readable direct links and original-source call locations are in
OStim-Only-Dependency-Audit.json. The diagnostic JSONL exports under build/diagnostics
are not release assets. No master or record was changed during the audit.

## Implementation scope confirmed by the audit

The OStim-only replacement must preserve all existing MME FormKeys and provide
local no-strip semantics. Removing the five keywords without replacement would
regress equipment protection. The legacy branches keep their original bindings.
After writing the replacement, re-enumerate every outgoing FormLink and verify
no SexLab.esm master or links survive; compare all unrelated records to baseline.

MilkPlayerLoadGame currently checks SexLabUtil.GetVersion, probes SexLab
animation registrars, and subscribes to SexLab stage/start/end/orgasm events.
Its OStim-only variant must retain MME initialization and gameplay events while
replacing framework-specific hooks and reporting selected-backend readiness.
Pumps, lactacid, the milking magic effect, dialogue, and spriggan armor checks
also call the framework directly; patching MilkQUEST alone is insufficient.

The MME Extensions caller audit includes MMEDebug (persistent scene service),
MMEAlertsController, MMEAlertsSkyrimNet, MMEAnimationSafety, MMEArmorScript,
MMEDiagnostics, MMEDwemerArmor, MMENewMilkMaid, MMEElsieBreastfeeding, and the
breastfeeding facade. Typed legacy callback signatures must not remain reachable
in the no-SexLab branch. Disable unsupported Elsie routes explicitly rather than
letting unresolved ssl types act as a feature switch.

MME's akActorSex uses both actor-base sex and SexLab.GetGender plus the existing
SOS/equippable-schlong checks. Specify and test the OStim-only classification;
preserve MME's Male/Female/Futa/Beast distinctions and existing SOS handling.
The bundled OStim SDK does not yet establish an equivalent gender or no-strip
API, so verify installed OStim source/API before choosing its adapter methods.
Do not invent calls or silently claim vanilla actor sex is an exact substitute.

The existing MME_SLA and MME_zbf adapters also resolve other frameworks. Audit
their actual winning source dependencies separately so the new variant does not
replace one missing SexLab call with a missing arousal/ZaZ call. This phase removes
the SexLab animation-framework requirement; it does not implicitly promise to
remove every optional framework from the modlist.

## Go/no-go

GO for implementation in repository only, with the acceptance gates above.
Do not expose an installable OStim-only option backed by unfinished scripts or
an unverified replacement plugin. Do not deploy or change the current profile.
If the installed OStim API cannot preserve a necessary gameplay distinction,
report that concrete behavior issue before choosing a changed policy. First
runtime approval requires a clean new-game profile with SexLab actually absent.

## Implementation result (2026-10-25)

The experimental option is implemented in the repository. The exclusive backend
selection preserves Standard/P+ options and gates unsupported Elsie/JUGS/SLAL
combinations. The replacement plugin is built from a hash-pinned MME input and
round-trip verified: all original FormKeys retained, one local protection keyword,
no SexLab master/links, and only the audited outgoing-link substitutions.

Twenty-one isolated source/compiled script pairs pass compilation with SexLab
framework declarations excluded from imports. Compiled disassembly checks reject
SexLab types, registry/native calls and property reads. Legacy/P+ and logging
contracts passed. The full package build passed; the archive and variant source/
PEX hashes were inspected. Repository tools generate and verify these outputs;
installed MO2/Vortex/game files were not changed.

Runtime acceptance remains pending in a separate new-game profile. This is not
approval to remove SexLab from an existing save. The reservation API is internal
to the MME bridge; unrelated OStim callers must respect it to avoid starting a
scene during standalone MME milking. Standard/P+ frameworks were not replaced or
reimplemented. Future Elsie/JUGS adapters can use the neutral OStim entry point.
