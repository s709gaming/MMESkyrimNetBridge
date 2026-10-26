# The Milk Maid: full OStim-only port audit

Date: 2026-10-25. User confirmed the requested reference is
`Reference mods/The Milk Maid SE(with convo tags) v1.2/TheMilkMaid.esp`, initially
described as A Milky Life. No gameplay, plugin, installer or installed mod changed.

## Verdict

Feasible, medium-to-large compatibility project. Fewer animation entry points
than JUGS does not make it a smaller behavioral port: this mod embeds the scenes
in dialogue quests, actor aliases, player-control changes and progression.
Prefer a separate, new-game, full replacement option with a backend facade.
Do not claim a full port by changing only breastfeeding or removing its master.

## Evidence and scope

- Plugin SHA256: 5cc8cac27d551bda2a6a524ee1e9da73129563f15b85408696b6ac0cd3f0ebfa.
- Masters: Skyrim.esm, Update.esm, SexLab.esm, MilkModNEW.esp.
- 578 modeled major records, including 12 quests, 15 scenes, 221 dialogue topics,
  256 INFOs and 31 branches; also story-manager nodes and actor packages.
- 98 unique scripts, with a compiled PEX and source for every base filename.
  There are 99 PSC files because one Healer fragment has two differing copies.
- Disassembled all 98 PEX files without errors. Both source and bytecode contain
  16 StartSex calls and 64 scripts with SexLab framework/animation types.
- In the primary Scripts/Source tree, 41 of those 64 scripts have only SexLab
  property declarations among the framework references; the other 23 contain
  additional types or calls. Property-only still requires recompilation and
  matching VMAD edits, not merely leaving the property unset.
- Animation selection: nine zjBreastFeedingVar selections, seven tag-based
  general-sex selections; 16 starts distributed across 15 scripts.
- Nine StripActor calls. No SexLab HookActors/HookAnimation or mod-event listener
  registrations were found in this source set. Eight single-update registrations
  include short dialogue-quest timeout handling, not a central scene lifecycle.
- Plugin link enumeration initially returned 95 affected objects, including 34
  DIAL containers aggregating their child INFO references. The owning-record
  count after excluding those containers is 61: 42 INFOs, four quests and all
  15 scenes. SexLab link targets found are 000D62 and 00E50F. Removing the master
  before clearing/replacing these dependencies would be unsafe.

Static plugin inspection used a diagnostic Mutagen reader against the reference
file, outside the installed load order. Counts describe that file, not live
Skyrim. Raw plugin output, the reader and disassemblies are under
build/diagnostics/milkmaid-*; the canonical record/source-hash inventory is
The-Milk-Maid-OStim-Dependency-Audit.json beside this report.

## Eight implementation areas

1. **Plugin and VMAD closure.** Remove obsolete SexLab-typed properties and their
   bindings in lockstep with compiled script changes. Audit every framework and
   animating-faction link, including scene/alias conditions, before replacing it.
   Preserve filename, original FormKeys, quests, branches, fragment names and
   dialogue ordering. Use a real backend busy predicate/faction contract rather
   than substituting an arbitrary faction or adding fake SexLab forms.
2. **Animation startup.** Route all 16 starts through a shared facade with explicit
   scene intent, actor identities and semantic positions. Supply OStim scenes for
   breastfeeding, cowgirl and doggy/general routes. Respect existing tag
   inclusion/exclusion intent; verify actual animation availability. None of the
   current StartSex call sites captures its return value, so success/failure
   ownership needs new handling, not a textual API replacement.
3. **Scene completion and quest progression.** Add asynchronous startup
   confirmation, owned thread tracking and completion/interruption callbacks.
   TMM__SF_TM_MNPC_MiscMilk_0400AA3A alone starts both breastfeeding and a later
   general scene; its fragments also lock/unlock controls and modify milk.
   Fixed 15/17-second quest timeouts must not prematurely stop or advance a
   pending OStim request. Preserve dialogue and story-manager eligibility.
4. **Stripping and redressing.** Replace all nine StripActor sites while preserving
   EquipedItems/NPCEquipedItems actor ownership and equipment restoration.
   TM_Main.DisablePlayerControl uses DisablePlayerControls, third person and
   SetPlayerAIDriven(true); every rejection, interruption, load recovery and
   successful finish needs matching owned cleanup. Prevent a second system from
   taking or releasing controls it does not own.
5. **MME semantics.** TM_Main directly writes Maid level, lactacid, milk quantities,
   breast base, milk-capacity base and progression keys; it also calls original
   MilkQUEST.CurrentSize and MilkCycle. Verify those exact installed APIs and
   preserve the original route effects. Our current MME breastfeeding service
   requires a valid MME milk source and performs MME transactions: it is NOT a
   safe automatic replacement for every animation-only or conversion scene.
   Separate animation-only requests from requests that own milk processing and
   conversion. Do not double-credit milk or inadvertently create a Milk Maid.
6. **Body systems and optional integrations.** Preserve this mod's NiOverride and
   SLIF behavior, independently of Extensions' own morph contribution. Verify
   legacy SLIF_morph/SLIF_inflate payloads against NG if NG is targeted; the plugin
   filename alone does not prove equivalent results. Pregnancy and other MME
   integrations remain conditional, with safe absence behavior.
7. **Source reconciliation and build.** Pin the exact input revision and choose
   sources using compiled behavior as evidence. Compile every changed PSC and
   audit bytecode for surviving SexLab types, inheritance and calls. Confirm
   script names/property contracts against VMAD. Audit bundled animation events,
   behavior-generation requirements and scene assets rather than assuming OStim
   supplies the mod's custom poses.
8. **Installer, diagnostics and acceptance.** Provide an isolated option after
   backend selection, with dependency guards and explicit new-game status.
   Master-toggle traces must cover request/actors/eligibility/result/cleanup and
   important skips. Deduplicated alarms identify actual failed prerequisites;
   optional absence is a skip. Preserve the original SexLab setup as a separate
   choice; do not overwrite installed profiles while developing the port.

## Additional findings to resolve before shipping

**Conflicting Healer source:** Source/Scripts/ELV__QF_TM_TheHealer_0400286B.psc
contains empty Fragment_1/3/5 bodies; Scripts/Source has SetObjectiveDisplayed
calls for objectives 10/20/30. The shipped PEX has empty bodies, matching the
former at those points. Blindly compiling whichever directory wins would change
quest behavior. Decide deliberately whether to preserve that baseline or make a
separately documented Healer bug fix. This was confirmed from bytecode, not only
from differing source file hashes.

**Morph reset ownership:** TM_Sizes.ClearBodyMorphs calls
NiOverride.ClearMorphs(actor), although normal writes use its NIO_KEY. A port
must not silently erase SLIF, Extensions or other mods' morph contributions.
Audit all reset callers and migrate to owned-key cleanup where appropriate;
retain intended visual/progression reset effects. This predates the OStim port.

**Existing unchecked calls:** scene fragments access aliases and call StartSex
without acceptance checks. TM_CheckStats.CheckPregnant declares a Boolean return
but only assigns TMisPreg in source. These are investigation candidates, not
proof that every affected route is broken. Keep unrelated repairs attributable
and do not silently rewrite progression while replacing the backend.

## Suggested execution order and release gates

First finish exact VMAD/condition and route-role mapping; reconcile the Healer
source. Then implement one representative breastfeeding scene and one general
scene through the facade, including interrupted/failing startup cleanup. Extend
to all 16 starts and stripping routes before removing SexLab from the plugin.
Use a separate new-game test profile with the matching OStim-only MME build.

Test player and NPC source/drinker roles, follower scenes, each multi-stage
dialogue route, The Healer objectives, busy/combat/wrong-target rejection,
animation unavailable, interruption, repeated use, controls/equipment cleanup,
save/load recovery, optional integration absence, morph ownership and logging
off/on. Check quantities and progression before/after; visual scene success
alone is insufficient. Full script compilation, plugin validation and package
inspection precede any deployment. No runtime approval or redistribution
permission is established by this local static audit.
