# Skyrim.Net narration centralization audit

Date: 2026-10-25. Source/build/configuration audit only. No source refactor,
installed-file change, archive rebuild or README edit was performed.

## Verdict

Yes: a single authoring compartment is feasible and low risk if runtime paths,
public APIs, callback names, settings and behavior remain unchanged.
The actual narration API calls are already centralized. Replacing them with a
new generic dispatcher adds risk with little benefit for quick content editing.

Recommended split: organize authoring files first, externalize remaining inline
prompt prose incrementally later, and leave runtime routing/state alone.

## Verified current boundary

Source/Scripts/MMEAlertsSkyrimNet.psc contains all narration/TTS native call sites:

| Native operation | Static sites | Meaning |
| --- | ---: | --- |
| DirectNarration | 15 | NPC-targeted or automatic-speaker narration |
| SendCustomPromptToLLM | 6 | Asynchronous player-only generation |
| TriggerPlayerTTS | 5 | Player-only playback after callback checks |

There are 43 SkyrimNetApi sites in this script overall; the other 17 cover
decorators, context/schema publication, UUIDs and build diagnostics. Five more
sites occur elsewhere: two RegisterAction calls in MMESkyrimNetVoiceControls,
two UnregisterAction calls in MMEAlertsController and one UnregisterAction call
in MMEAlertsMCM. Those five are action lifecycle operations, not scattered
narration dispatch. The file-header claim that *all* API calls are here is broader
than the implementation; narration centralization itself is already true.

The six asynchronous requests target these existing controller events:
OnTentaclePlayerLine, OnDwemerEffectPlayerLine, OnDwemerSuitPlayerLine,
OnMilkCravingPlayerLine, OnNewMilkMaidPlayerLine and OnForcedMilkMaidPlayerLine.
Their names/class and quest callback receiver are API contracts. Five playback
sites serve six routes because normal/forced conversion share a playback helper
while retaining separate callback entry points and setting checks.

Gameplay scripts supply verified actor/event facts through existing Narrate*/
Send* entry points. Some supplied text originates in local notification pools;
therefore moving native API calls does not automatically centralize all prose.

## What is actually scattered

- Six YAML action definitions in SkyrimNetActions.
- Three prompt files in SkyrimNetPrompts.
- The Skyrim.Net 25+ external-plugin manifest in SkyrimNet25/s709gaming.mme-extensions.
- Four dedicated narration JSON files in SKSE/Plugins/StorageUtilData/MMEAlerts:
  TentacleEffectNarration, DwemerEffectNarration, DwemerSuitNarration and
  DwemerAttachmentNarration; also integration messages/options in SkyrimNet.json.
- Inline prompt prose/fallbacks in MMEAlertsSkyrimNet.psc, plus inline action
  descriptions in MMESkyrimNetVoiceControls.psc.
- Shared local flavor/story pools such as Thoughts.json, MilkCravings.json and
  ForcedMilkMaidConversion.json. Their text also feeds narration, but these are
  not exclusively Skyrim.Net resources. Injection.json and other notification
  pools likewise must not be relabeled as optional AI-only data.

build-package.ps1 already explicitly maps action/prompt sources into the
manifest-backed Skyrim.Net 25+ plugin and JSON into StorageUtilData/MMEAlerts.
This makes changing authoring paths practical without changing installed paths.
The removed Beta 24 loose paths must not be reintroduced during organization.

## Low-risk implementation boundary

Use one canonical source directory, for example:

    Integrations/SkyrimNet/
      Actions/
      Prompts/
      Narration/
      manifest.json
      EDITING.md

Move the dedicated action/prompt/manifest/narration inputs there, updating build
and test references atomically. A small explicit source-to-destination manifest
can make the mapping reviewable. Keep installed filenames, relative prompt/action
paths, JSON keys, prompt identifiers and action identifiers exactly as they are.
Keep one editable source of truth; do not maintain manually synchronized copies.
The editing guide should link shared flavor pools and the two Papyrus integration
scripts in their current locations. Links give quick access without duplicating
or misclassifying shared gameplay content.

Leave Papyrus scripts under Source/Scripts for the first pass. Moving those
sources requires compiler/import/test/generator changes and yields little value
for routine writing edits. Preserve the existing public global function names,
controller events and quest bindings. No ESP or MCM migration is necessary for
an authoring-only relocation.

At packaging, compare every output payload against the baseline. Moving source
files should leave shipped action, prompt and JSON bytes and destinations
identical. Update the source manifest/test paths, not runtime JSON references.
Do not move live/user-edited settings or reset saved cooldown fields.

## Why a generic dispatcher is higher risk

1. Speaker/originator/listener arguments differ deliberately. None, an NPC wearer
   and the player are not interchangeable. Player speech uses private generation
   followed by player TTS; it must never fall back to a bystander's narration.
2. Success conventions differ: DirectNarration and player TTS treat 0 as accepted;
   SendCustomPromptToLLM uses 1 for queued. One shared success rule would break
   cooldowns or classify successful requests as failures.
3. The callbacks recheck route-specific feature/master/dependency settings after
   generation. Normal conversion, forced conversion, cravings and armor effects
   have different authorization; preserve the six callback entry points.
4. Cooldown scopes and writes differ. Some routes write a timestamp only after
   acceptance; forced conversion intentionally has no narration cooldown. Shared
   last-request state would couple unrelated features. Real-time rollback across
   game sessions and existing settings keys must retain their handling.
5. Random/chance checks, confirmed effect deltas and child/actor guards belong to
   the original route. Do not move random draws earlier or invent milk/arousal
   effects from a successful event send alone.
6. Context publication is distinct from token-using narration. RegisterEvent and
   RegisterShortLivedEvent must not start LLM requests because they share a helper.
7. Duplicate suppression includes caller-side ownership. For example, chest drink
   context can take over ordinary NPC-drink narration, and dedicated armor routes
   suppress generic narration. A second dispatcher must not submit both.
8. Preserve optional-dependency boundaries. Do not spread SkyrimNetApi imports
   into gameplay scripts or call new wrappers before established plugin guards.
9. The OStim-only generator derives MMEAlertsSkyrimNet from the common source and
   replaces BreastfeedingPromptRole. Moving/renaming that API without updating
   generation would leave the two backend variants inconsistent.

## A second phase for genuinely easier wording edits

Externalize remaining inline prompt prose into data one route at a time while
keeping every Narrate* function signature and routing decision unchanged. Reuse
the current token renderers/JSON escaping and retain supported legacy JSON shapes.
Malformed/missing/empty templates need a defined fallback or gated skip, with
deduplicated diagnostics where appropriate. Do not weaken factual restrictions
such as an ordinary drink not implying Milk Maid conversion or milk growth.

Do not simply merge all JSON files into one: keys have different schemas and
callers, and shared flavor text is also used without Skyrim.Net. No whole-file
settings migration is justified for an editing convenience refactor.

## Risk and acceptance

| Change | Risk | Recommendation |
| --- | --- | --- |
| Editing index with links | Very low | Useful immediately |
| Canonical authoring folder plus unchanged packaging destinations | Low | Recommended first implementation |
| Externalizing inline prose with preserved route functions | Low-to-moderate | Separate incremental change |
| New generic dispatcher, shared queue/cooldowns or merged callbacks | Moderate-to-high | Avoid for this objective |

Existing TentacleNarration, DwemerEffects, DwemerArmor and MilkCraving contract
tests passed during this audit. They cover important actor/player-TTS/content
invariants but do not validate all 15 narration routes or establish runtime
equivalence after a future refactor.

For authoring-only moves: validate JSON/YAML/prompt/manifest integrity, resolved
source paths, all manifest action/prompt entries, exact packaged paths/content,
and absence of stale duplicate sources. Use the unversioned MME Extensions.zip.
For any Papyrus change: compile every affected script, regenerate/test OStim-only
variants, check PSC/PEX hashes, and rebuild/inspect the package. Gameplay tests
must cover NPC and player speech, toggles changed during pending generation,
optional Skyrim.Net absent, rejected generation, missing JSON, overlapping
requests, preserved cooldowns, escaping and one-request-per-event behavior.
Routine footprints remain under the master Papyrus logging toggle; no new
timers, scans, polling, player notifications or gameplay transactions are needed.
