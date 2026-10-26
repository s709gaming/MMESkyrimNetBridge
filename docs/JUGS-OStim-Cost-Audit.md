# JUGS OStim-only port: cost audit

Date: 2026-10-25. Static audit only. No gameplay implementation, installation,
profile change, archive rebuild or README edit.

## Decision

Not a trivial or nearly-free conversion. For a small audience, defer a full
parity port unless there is demonstrated demand or personal value to the user.
A deliberately restricted MME-only experimental adapter is the affordable
candidate, but still carries much of the dependency/cleanup work of a full port.
Do not start a new general animation framework solely for JUGS.

Rough planning estimates from this audit, not measured prototype results:

| Scope | Effort including focused testing | Value judgment |
| --- | --- | --- |
| One player/NPC breastfeeding proof, diagnostic build only | 1–3 hours | Useful to settle reuse questions; not releasable. |
| MME-only, serialized breastfeeding option; no legacy SGO parity or general scenes | 6–12 hours | Possible niche experiment if explicitly wanted. |
| Full reachable JUGS scene coverage, equipment lifecycle and legacy integrations | 12–24+ hours, then support | Poor cost/benefit for a tiny audience without demand. |

These ranges include necessary in-game regression work. Animation availability,
unexpected source/bytecode discrepancies and concurrency requirements can expand
them. A small call count does not eliminate plugin, installer or support costs.

## Verified scope

Audited original mod: C:/Users/Donald/AppData/Local/ModOrganizer/VortexToMO2/mods/JUGs.
Plugin SHA256: 0fae2e73d9f74b5a3bc4564109e09593335fdf0b27f13d8a2725349b53796a36.
Masters: Skyrim.esm, Update.esm, SexLab.esm. Original JUGS has no MME master.

- 525 modeled major records: one quest, 244 DIALs, 251 INFOs, 18 branches,
  nine views and two factions. No authored Scene records or native DLL in the
  audited mod root; dialogue fragments are the animation entry points.
- 78 source files and 75 original PEX files. All 75 disassembled successfully.
- Original source has 39 StartSex calls; original bytecode has 38. The source-only
  JUGs_TIF__03015CF7 is not attached in this plugin; its actual INFO uses
  JUGs_FPC_MF_3a5Script. Two other source-only files are also unattached here.
- Existing MME compatibility option has 43 PSC/PEX pairs. Its effective overlay
  yields 77 PEX files, all disassembled without errors; startup is centralized
  into the helper, with 39 callers. This is a real head start for generation.
- Corrected category count: 22 breastfeeding caller sources, 17 other scene
  callers. One breastfeeding caller is unattached: **38 bound starts = 21
  breastfeeding + 17 general**. The earlier preliminary 21/18 split missed a
  GetAnimationByName("3J Straight Breastfeeding") source, which is unattached.
- Original source has 71 scripts with SexLab types/calls; 21 are property-only.
  Original compiled files contain 69 framework/animation-typed scripts.
- Link enumeration returns 129 affected objects, including 63 DIAL containers
  aggregating child INFO references. Actual owning records: **65 INFOs + one
  quest = 66**. Targets are SexLab framework 000D62 and animating faction 00E50F.
- houseCARL exported all 252 INFO/quest VMAD records in one query. They name
  73 unique bound script classes; no required bound class was missing a PEX in
  the original-plus-existing-patch search. The player-alias script is inside
  the quest's VMAD, not another owning major record.

Canonical dependency/route/source-hash inventory: JUGS-OStim-Cost-Audit.json.
Raw plugin output, VMAD exports and original/effective disassemblies are under
build/diagnostics/jugs-*. No script compilation or OStim gameplay test was run.

## Where the cost actually is

### 1. Removing the master is mostly mechanical, but unavoidable

Generate isolated script variants and remove matching VMAD properties together.
Clear or replace all 66 owning-record dependencies before removing SexLab.esm.
Retain original filenames, FormKeys, dialogue links and fragment names. The
existing SDK compile shims cannot stand in for runtime implementations.
Even a breastfeeding-only port must eliminate dependencies from the rest of the
loaded plugin, or explicitly remove/disable those branches and their bindings.

### 2. Scene mapping has repetition, not one universal request

All bound starts use two actors, and the source assignments have four patterns:
player/speaker, speaker/player, speaker/follower and follower/speaker. Semantic
source/drinker roles must be preserved rather than inferred from a fixed OStim
position. The general scenes use ten distinct tag-selection argument patterns
plus a named AP Blowjob selection. Mapping must honor intended acts and exclusions
and reject unavailable scenes; a random fallback is not parity.

The original mod lacks the authored multi-scene quest structure seen in The Milk
Maid. This makes JUGS appreciably simpler, but repeated fragments still require
compiled matching replacements and validation of actual attached script names.

### 3. The existing MME service is useful but narrower than JUGS

MMEDebug has one ActiveSession and rejects a second breastfeeding request. Its
start validation requires a registered MME milk source. Original JUGS does not
require MME and can animate other sources; its optional SGO queue holds up to
four pairs. Do not call this a drop-in replacement that preserves all original
NPC/concurrent/non-MME use cases. Either declare the MME-only serialized scope
in the installer or implement a separately owned JUGS session registry.

MMEExtensionsAPI.CompleteBreastfeedingMilkShare is already reusable for completed
valid MME-source scenes. Choose who owns milking and post-scene drink effects:
using the MME scene service and then also calling the existing JUGS completion
handoff can duplicate effects. Record actual thread IDs/actors, confirm startup,
and deduplicate completion before clearing ownership.

### 4. Equipment is a small subsystem of its own

There are five StripActor calls and five UnStripActor calls. They share
Jugs.EquipedItems across player and NPC routes, so an unscoped replacement can
restore the wrong actor's equipment or overwrite another request's inventory.
Use per-request/per-actor ownership, no-strip policy and reliable rejection/end/
interruption cleanup. Existing custom undress animation events also need their
assets/behavior compatibility checked. Do not remove outfit features silently.

### 5. Legacy SGO increases support cost

JugsMain supports Soulgem Oven II and III. Our current patch has three direct
fragment calls into its transfer queue plus the alias scene-start listener;
deduplication already matters. Queue continuation depends on SexLabAnimatingFaction.
OStim requests start asynchronously, so "builder accepted" is too early to begin
transfers. Startup/end/failure handling must own queue membership. The standalone
JUGs_SGO_Milker helper is not bound by this plugin; do not budget it as a required
route solely because its source exists. Explicitly excluding legacy SGO parity
is the clearest way to reduce the initial port's dependency matrix.

### 6. Existing compatibility fixes are not all attached here

JUGs_MakeAMaid1C024, the rewritten conversion helper in our patch, is not attached
in this audited plugin. Bound Jugs_FPCMM10 and Jugs_MPCMM11 still equip the
hard-coded MME armor form 0343F2 to convert an actor. A new port must identify and
adapt those actual routes; the existence of the patched helper is not proof they
already use the supported conversion API. This is also a limitation of our current
legacy patch and should be a separately attributable repair if implemented.

## Minimum useful release versus false economy

The smallest honest release is an opt-in, new-game **MME-only JUGS breastfeeding
adapter** with explicit player/NPC roles, a serialized session limit, safe
equipment restoration and no SGO claim. Non-MME sources and the 17 general-sex
choices must be hidden/clearly unavailable, including their parent dialogue paths
where necessary. Returning false from fragments while retaining clickable dead
choices is not an acceptable shortcut. Original SexLab files remain separate.

That release gives fewer features than full JUGS and needs explanation/support.
Removing the 17 general routes does not halve the cost: dependency closure,
stripping, actor roles, conversion, cleanup, FOMOD and most tests still remain.
If a robust generic OStim starter already exists for another project later,
adding the general mappings may be better value than maintaining a restricted UI.

## Recommended stop/go checkpoint

Before funding a full port, timebox a one-route proof using a diagnostic copy:
clean the plugin dependency closure, start one correctly ordered player/NPC pair,
confirm startup/end, verify milk quantities exactly once and restore equipment
after both normal completion and rejection. Test the reverse role direction.
If it requires redesigning the shared MME service or adding a multi-session
framework, stop the low-cost effort and re-evaluate demand.

For any eventual release, test player and follower directions, repeat calls,
busy/combat/invalid targets, animation unavailable, interrupted scene, save/load,
master/feature/logging toggles, conversion paths and optional dependencies. Full
parity adds non-MME sources, concurrent NPC sessions, general acts and both legacy
SGO variants. Keep traces under the master toggle, real failures deduplicated,
and expected optional absences as skips. Preserve original MME quantities and
progression rather than reproducing them independently.
