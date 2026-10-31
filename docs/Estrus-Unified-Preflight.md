# Estrus Unified integration preflight

Prepared 2026-10-29. Planning and baseline verification only; no gameplay implementation, installation, or live mutation.

## Verified baseline

- Both supplied patches differ from our current matching MilkQUEST source only by the Unified readiness helper, invalid-actor guard and pregnancy query. Their source, PEX and archive hashes match Build Info.json. These are provenance checks, not fresh compilation or runtime proof.
- The real supplied EstrusUnifiedAPI source declares IsReady and GetPregnancyType(Actor target) as global native functions. Pregnancy values are 0 none, 1 Chaurus, 2 Spider, 3 Dwemer. No native C++ implementation was supplied for independent inspection.
- Existing legacy checks and legacy trigger flags must remain unchanged. This request adds pregnancy recognition, not Unified scene triggering or an overhaul of MME's pregnancy rules.
- Important existing behavior: ActorCheck calls isPregnant(PlayerRef), then AssignSlot(PlayerRef) for an eligible player not already in slot 0. Unified recognition therefore expands the pregnancies that can trigger MME's existing automatic player conversion. This is an intended consequence to verify, not a claim that detection has no conversion effects. Do not add separate conversion logic or alter NPC conversion policy.
- Author instructions name the release source location. Our authoritative input is Source/MMECompatibilityOverrides/MilkQUEST.psc. The OStim generator reads it and emits the OStim variant; directly editing only the generated variant is insufficient.
- Existing MME compatibility and Papyrus logging contract checks pass before implementation.
- Papyrus compiler/flags, CommonLib VM headers and native build cache exist. Native build tooling uses the Visual Studio paths in build-native.ps1 rather than the shell PATH. No fresh build has been performed in preflight.

## Dependency design and decision gate

Default goal: automatic support, no installer choice, no Estrus ESP master and no Estrus script type in common gameplay scripts. Never ship the compile-only API subset over Unified's full runtime API.

The supplied direct EstrusUnifiedAPI calls introduce a compile-time script dependency. Readiness guards protect calls but do not remove that dependency; do not copy them into the common source unchanged under current repository rules.

Our existing native bridge already resolves optional RaceMenu static calls by class/function strings and consumes callback results. CommonLib headers also expose RegisterLatentFunction and ReturnLatentResult. A dynamically resolved Unified query through our own native bridge is a candidate, not an already validated solution.

Before choosing it, prove all of the following during implementation's first isolated build/prototype step:

1. Missing ESP, missing DLL and unavailable API return safely without dispatching unknown functions.
2. Actual actor reference is preserved independently for every request; no shared last-actor/result cache.
3. Readiness and pregnancy results are type checked. Failed dispatch, lost callback, load/revert and invalid actor terminate safely; no blocked game thread, busy-wait or indefinite suspended stack.
4. A delayed result cannot silently use stale MME actor indices, milk quantities or parallel arrays. Audit every isPregnant call site, including nested conditions and loop callers. Reject the latent approach if preserving original timing/array semantics cannot be established without broad changes.
5. API absence/unready status falls through to all existing pregnancy checks. A nonpregnant Unified result does likewise. Never cache pregnancy across birth/reset or save/load.

CommonLib's latent-function documentation explicitly warns that pending stack IDs/data must survive save/load or script events can remain permanently blocked. A session-token discard alone is insufficient for a latent return bridge. Given the synchronous core caller and framework arrays, prefer avoiding added latency; a dynamic bridge must prove safe return and save/load behavior before adoption. The existing asynchronous RaceMenu pattern is evidence of dynamic dispatch support, not evidence of synchronous pregnancy-query safety.

If that proof fails or requires disproportionate changes, stop the automatic-integration approach and document an isolated optional compatibility component instead. Do not disguise a hard dependency or substitute undocumented StorageUtil keys, raw DLL offsets, or old form IDs. Do not present asynchronous dispatch as a synchronous answer. Final architecture remains conditional on this gate.

## Planned diagnostic footprints

Prefix: [MME Extensions Estrus]. Use MMELog.MasterDiagnostic for sparse routine entries; it reads enablePapyrusTrace alone. MMELog.Diagnostic requires the additional verbose switch and is unsuitable for the requested master-only footprints. No new MCM setting or existing-save migration is needed for logging.

Record these boundaries with actual actor reference/FormID, request token where asynchronous, and reason:

- Dependency state transition: absent, present/unready, ready. Log transitions only; absence is expected.
- Query entry and selected actor: detailed repeats only under existing verbose logging.
- Result transition per actor: pregnancy type and recognized/not recognized, then whether legacy fallback is selected. Do not log unchanged results every production tick. Keep any deduplication bounded/session-local and separate from authoritative query results.
- Failure/cleanup: rejected invalid request, failed dispatch, invalid return, timeout/cancellation and load cleanup. A result must never be reassigned to another actor.
- Readiness becoming available after initialization must be observable without trusting a saved availability flag.

Use MMELog.Alarm only for real failure, such as a ready integration returning an invalid type or a query failing after prerequisites were confirmed. Include attempted operation, actor and concrete reason; deduplicate by failure category/session. Missing optional dependency, unready startup and a normal nonpregnant actor are traces, not smoke alarms. No routine player notifications. Do not add new polling solely for diagnostics.

## Implementation sequence

1. Resolve the dependency-design gate above using an isolated build/prototype, keeping diagnostics out of release staging.
2. Add the smallest extension-owned query boundary; change the authoritative standard MilkQUEST source at isPregnant entry only where feasible. Preserve all existing property names and legacy checks.
3. Add sparse gated footprints and genuine-failure alarms as specified. Preserve original pregnancy-sensitive actor selection, milk generation and milking rules.
4. Regenerate OStim from the canonical input; update its explicit isolated imports only if the selected design needs them. Preserve no-SexLab/no-DD backend rules. Standard and P+ share the standard MilkQUEST path.
5. Add focused verification for absence/fallback, actor isolation, invalid results and generator preservation. Static contracts alone cannot establish runtime native binding or pregnancy correctness.
6. Compile every affected PSC and any changed native bridge. Run existing relevant MME override, logging and OStim/backend checks. Rebuild MME Extensions.zip and inspect standard/OStim source/PEX pairs, FOMOD priorities and absence of SDK/diagnostic files. Update the compatibility changelog, not README.

## Runtime regression matrix

Execute only after explicit authorization to install/test; preflight does not authorize deployment, actor mutation or pregnancy changes.

| Scenario | Expected evidence |
| --- | --- |
| Unified absent | No missing-function/type errors; old checks still work; sparse absent trace only when master enabled |
| ESP present, DLL missing or API unready | Safe legacy fallback; no unknown native invocation or repeated alarms |
| Chaurus, Spider and Dwemer pregnancy, each on player and NPC | Correct actor recognized; original MME pregnancy settings determine milk behavior |
| Nonpregnant actor, birth and reset | No stale positive; other pregnancy frameworks may still return true |
| Old separate Estrus setup without Unified | Existing detection and legacy flags unchanged; do not install legacy and Unified together for this test |
| Concurrent player and NPC queries/repeated production cycles | No exchanged actors, stale slot access, shared result or unbounded request growth |
| Pregnant player not already a Milk Maid | Existing ActorCheck eligibility and AssignSlot behavior occur for recognized Unified pregnancy, just as for other supported pregnancy; correct player slot and no unintended NPC conversion |
| Extensions disabled / original MME pregnancy settings varied | Detection adds no new autonomous action and preserves existing enablement semantics |
| Milking, combat, busy scene and movement lock | No added scene, conversion or animation; existing guards and cleanup unchanged |
| Save/load and new game | No new migration requirement, saved availability trust or pre-load callback acting on new-session actors |
| Master off; master on with verbose off; master and verbose on | Routine silence; sparse useful boundaries; detailed queries respectively; alarms remain deduplicated |
| Standard SexLab, P+ and OStim-only | Matching script branch compiled and packaged; no new SexLab dependency in OStim |

Inspect Papyrus logs for missing classes/natives, stack dumps, stale actors/indices, repeated noise and unfinished requests. Establish baseline actor milk/level/slot before testing and compare afterward; preserve MME's existing pregnancy-triggered conversion behavior while adding no independent conversion or inventory-transfer logic.

## Exit criteria

Preflight established source provenance, insertion points, build ownership, logging behavior and regression cases. The implementation subsequently selected a synchronous native forwarding facade: it validates the loaded public functions and forwards their existing argument frame through the VM marshaller. There is no asynchronous query, saved request or pregnancy-result cache. The supplied binaries are not copied into the release.

The native bridge and common Papyrus helper have compiled; focused native policy tests and existing override/logging checks pass. Package/build verification is recorded with the implementation results. Engine-side marshalling, native binding, and the runtime matrix above still require in-game validation; compilation and mocked policy tests do not establish those outcomes.
