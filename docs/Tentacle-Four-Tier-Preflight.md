# Four-tier Tentacle Effects: implementation preflight

Date: 2026-10-30. Status: planning only; not approval to implement or deploy.

The user will supply new JSON stories later. Extreme means the original MME New Milk Maid creation animation, not a new animation asset and not Milk Maid creation gameplay. Repository source was inspected without changing code, JSON, installed mods, profiles, or live game state. Preserve the existing unrelated worktree changes and README.

## Verified baseline

- `MMEAlertsController` owns `NextInjectionGameTime`. `RefreshGameTimeScheduling` calls `ScheduleNextInjection` during initialization, rerolling the current shared deadline. `OnUpdateGameTime` passes one native nearby scan to all due game-time consumers. `ScanNearbyMilkMaids` separately shares one native scan among real-time consumers; these two callbacks are not currently one global cached scan.
- `MMETentacleEffects.RunInjectionCheck` validates loaded Milk Maids and armor classes 2/3 (Living/Parasite), rolls injection chance per actor, applies shared milk/arousal calculations, and chooses one HUD/narration wearer per pass, preferring the player. It does not currently play a tier reaction.
- Preserve the exact calls `MMEMilkBoost.ApplyMilkDrinkBonusForActor(candidate, 1, False, False)` and `MMEArousalBridge.ApplyConfiguredMilkArousalForActor(candidate, "armor injection", False)`. Intensity introduces no effect multipliers.
- The public API invokes `RunInjectionCheck(targets, False, False)`, bypassing scheduled chance. The manual MCM check bypasses waiting but retains chance. Preserve these entry-point distinctions.
- `MMEArousalAnimations` maps female tiers 1/2/3 to `MMEExt_Arousal_F_L1/L2/L3`; male tier 1 to `MMEExt_Arousal_M_L1` and tiers 2/3 to `MMEExt_Arousal_M_L2`. These match `assets/animations/FNIS_MMEExtensionsArousal_List.txt`. Its existing hold is fixed at 3 seconds.
- The installed original `MilkLactacidScr.psc`, resolved by houseCARL to `Milk-Mod-Economy-Scripts-20220522.7z/Scripts/Source`, uses `ZaZAPCHorFd`, a 10-second wait, unconscious/player-control changes and creation gameplay. Reuse only its animation event. `MMEReactionAnimation.StartKneeling` already exposes that event; `StartCustomEvent` additionally supports holding both player and NPC movement.
- Shared reaction safety rejects unavailable actors, combat, mounts, sitting, MME milking, SexLab/OStim scenes, player DHLP suspension, restrained arms and cooperative ownership. Reset avoids interrupting a new external owner; movement cleanup and load recovery already exist.
- `MMELog.MasterDiagnostic` needs only `enablePapyrusTrace`; `Diagnostic` additionally needs verbose. `Status` and `Alarm` are ungated. Current tentacle `Report` uses verbose diagnostics and can show diagnostic HUD notifications. Do not route the new routine footprints through that helper.
- Active result narration reads canonical `Narration/TentacleArmor.json` through `MMENarrationText`. `TentacleEffectNarration.json` currently participates through explicit legacy import mappings. `Injection.lines` is directly consumed through the personal-pool facade.
- Catalog generation currently discovers top-level arrays and asserts 131 entries. Native base resolution expects each catalog entry to have a valid default. Nested optional tier pools therefore require explicit metadata/fallback work, not merely additional JSON keys.

## Decisions for implementation

### Probability and MCM

Add exactly four intensity chance controls and four duration controls. Defaults: Low 50%/3s, Medium 30%/3s, High 15%/3s, Extreme 5%/4s. All existing control names and values remain intact.

Chance sliders: 0–100 in steps of 5. Represent the distribution as twenty units. Preserve the edited value and proportionally allocate the remaining units among the other tiers using largest remainders, with a fixed Low-to-Extreme tie order. If other weights total zero, use their default weights. Every accepted edit totals twenty units. At runtime defensively normalize externally edited/corrupt settings; repair once with a gated trace. Do not persist on every effect.

Proposed duration range: 1–10 seconds in steps of 0.5. It controls the owned hold, not clip speed or a guarantee of seamless animation looping. Verify 1s/3s/4s/10s visually before final acceptance. Existing arousal-threshold/public-API callers retain their three-second behavior. The existing Arousal Animations toggle retains its current scope: reuse its mappings, not its threshold-feature enable gate, for enabled Tentacle Effects.

Migration initializes absent keys only, uses a dedicated migration marker, and normalizes malformed new probabilities without overwriting existing injection chance, interval, variation, narration, notification or sound settings. Do not choose a release version number in this work.

### Independent scheduling and discovery

Use per-actor StorageUtil game-day timestamps plus a save-owned bounded tracked-actor registry. Never use MilkQUEST slot indices as scheduler identities. Preserve existing MME validation helpers and avoid new framework array access.

Actor state: schedule schema, next due, last observed eligible game time, observed presence/generation. Controller state: next relevant injection deadline, discovery deadline when needed, and a reentrancy guard. Advance the actor deadline before dispatch to prevent duplicate callbacks; release the guard on every exit.

Seed each newly discovered eligible actor separately with `now + CalculateNextInterval(existing interval, existing variation)/24`. Use the same randomized calculation after a consumed opportunity. Do not seed every actor with the old shared deadline. On load, restore future actor deadlines instead of reseeding them. Retain the existing serialized quest member for compatibility, but redefine it as an aggregate wake deadline rather than the source of actor timing.

Feed discovery from the existing scan results in both controller paths. Tentacle discovery must remain live when capacity, thoughts, Skyrim.Net and arousal scanning are all disabled: add an internal deadline to the existing controller and combine it with other scan consumers. Proposed discovery cadence is 15 real seconds when no earlier shared scan is due; no actor timer, second quest, new MCM control or high-frequency scan loop. Coalesce due discovery/scan consumers within each callback; do not claim the current game-time and real-time scans are already globally shared.

At a due wake, process only currently nearby, loaded, supported-armor Milk Maids. Future deadlines survive load. Overdue-on-load or re-entry after a missing/stale eligible observation is rearmed from now, with no immediate replay. A continuously observed actor receives at most one event after a delayed callback or wait/sleep, then schedules from now; never loop across missed periods. Actors observed without supported armor lose eligibility and are reseeded on return. Disabled features suspend processing; re-enable preserves valid future deadlines and rearms overdue ones.

Maintain a bounded registry, remove invalid/deleted/unregistered actors, and retire absent actors rather than repeatedly arming overdue wakeups. Absence retirement must not erase a nearby actor due to ordinary callback ordering. Test discovery, retirement and load ordering together. Interval edits reseed relevant schedules; chance/duration edits do not. No new MCM scheduling controls.

### One event, one actor, one tier

For each due actor: validate identity/eligibility; consume the opportunity and advance its deadline; roll injection chance; roll tier only after chance passes; check animation safety and acquire ownership; dispatch the animation; apply the unchanged effect functions once; retain that actor's results and tier for presentation; schedule controller-owned completion.

If animation prerequisites or ownership reject the event, skip the whole package and reschedule normally. No delayed multi-actor backlog or force-play through scenes. This deliberately changes the old effects-only behavior for busy actors to satisfy the requirement that successful tier events have animations; retain a concrete gated skip reason.

Use unique per-event ownership tokens and capture the selected event, duration and actor at start. Do not recompute them from mutable settings during cleanup. Do not hold the shared scanner stack with `Utility.Wait(duration)` or call the existing latent `TryPlay`/`FinishStarted` from its actor loop. Complete pending holds from the existing controller's real-time update and call shared Reset. Cap pending work to the tracked/scanner capacity; reject before gameplay if capacity is unavailable.

Acquire ownership before asynchronous arousal changes can launch threshold reactions. Inspect the threshold retry path: a five-second retry must not replay a second reaction after this event merely because it waited for our lock. Use a narrowly scoped same-event suppression/coordination mechanism, preserving unrelated future arousal reactions. Cleanup on load, disable, actor loss and ownership takeover must release only this event's state. Do not set unconscious, invoke Lactacid, assign Milk Maid slots, or publish creation/orgasm gameplay for Extreme.

Preserve the current one HUD/narration focus per shared processing pass to bound simultaneous presentation. Every successful actor independently receives its own tier animation/effects. The selected HUD/narration actor uses its own tier and confirmed results; a generic others count must not attribute the selected tier/outcome to every actor. Preserve wearer-as-speaker and player-private-TTS routes and existing presentation toggles/chances. Do not add a new speech timer or retry backlog.

### Content, fallback and editor contract

Proposed paths: `Injection.tiers.<low|medium|high|extreme>.lines` and `TentacleEffectNarration.tiers.<tier>.<milk|arousal|milkAndArousal>`. Keep existing top-level keys and canonical untiered IDs. Proposed new stable IDs contain tier/outcome explicitly; finalize them before authoring tests, then use the same IDs everywhere.

Resolution: tier personal override → authored tier content → existing untiered personal content → existing untiered base/canonical content → established built-in fallback. No confirmed milk or arousal increase still means no result narration. Keep actor token aliases compatible with legacy narration.

No flavor text or empty placeholder arrays are needed for the initial infrastructure. Add explicit fallback metadata for optional tier entries to the generator/native store. The editor can display inherited content and allow a valid personal override even while the authored tier path is absent. Reset removes only the selected personal tier override and returns to inheritance. Do not materialize inherited content as personal customizations or populate the user's files during migration. Account for fallback-source changes in revision/conflict detection and preview the same effective content the runtime selects.

Expose four tier categories inside the existing editor, with notification and three narration outcomes per tier. Reuse lazy fields, variants, validation, drafts, preview, save/reload/reset, atomic batches and presets. This adds sixteen tier entries in the proposed layout, taking the catalog from 131 to 147 if no unrelated entries are added. Replace fixed count assumptions with validated expected inventory. Legacy entries remain available.

The observed reopen issue requires a regression: session uncertainty must reconcile when an already-selected editor becomes visible, preserving drafts and enabling Save only after revision verification. Include the fix only in the approved editor integration scope; it is not fixed by this preflight.

## Papyrus footprints

Use `MMELog.MasterDiagnostic` and prefix `[MME Extensions Tentacle Effects]` for new routine boundaries. Keep existing editor source traces under `[MME Narration Editor]`. Routine text must not become player notifications. Existing manual Run Effect Check Now may retain a concise final user-requested result, not per-step debug popups. Detailed scan enumeration belongs behind the existing verbose/deep gate, never a new MCM toggle.

| Boundary | Required fields |
|---|---|
| Migration/load | operation, schema, restored/seeded/pruned counts, repaired settings, result |
| Probability edit | edited tier, requested value, final four weights, total=100 |
| Actor schedule change | actor name/reference, reason, nowGameDays, dueGameDays, randomized intervalHours |
| Due opportunity | actor, armor class, eligibility, skip reason if rejected |
| Rolls | actor, injection roll/chance/result; tier roll and selected tier only after chance success |
| Animation start | actor, event ID, tier, captured durationSeconds, owner/event token, start/rejection result |
| Effects | actor, tier, returned milk delta, arousal baseline, dispatch result; observed after-value when available, never inferred success |
| Presentation | actor, tier, outcome, stable entry ID, personal/tier/legacy/built-in source, request result or expected skip |
| Completion/cancel | actor, token, reason, ownership/reset result, movement release result, pending state removed |
| Feature disable/load recovery | canceled holds, restored movement, retained/rearmed schedule counts |

Trace state transitions, not every scan, idle actor, remaining second, text keystroke or transport chunk. Deduplicate unchanged skips by actor/reason/state and content sources by entry/revision. Never log full prose, prompt payloads, presets or credentials in the new footprints. Existing legacy paths that print prose are outside a blanket logging rewrite; new calls must not expand that behavior.

Smoke alarms use `MMELog.Alarm`, with subsystem, operation, actor when applicable, and concrete failure. Deduplicate by actor/reason/schema or revision, not a freshly generated request ID. Examples: missing required controller/framework prerequisite, invalid tier after normalization, inconsistent pending ownership, or cleanup unable to release our movement marker. Do not alarm for disabled settings, chance misses, no eligible actors, busy scenes, absent optional integrations, or a missing optional tier pool with a valid fallback.

## Affected files and build obligations

- `MMEAlertsController.psc`: restore/discovery/due processing and pending animation completion.
- `MMETentacleEffects.psc`: tier configuration, event pipeline, focused presentation, new gated reporting.
- `MMEAlertsMCM.psc`: eight controls, balancing and upgrade initialization.
- `MMEArousalAnimations.psc`, `MMEReactionAnimation.psc`, `MMEAnimationSafety.psc`, and narrowly `MMEArousalEffects.psc` if required: mapping reuse, owned starts/cleanup and threshold coordination. Preserve old signatures or add backward-compatible facades.
- `MMEAlertsSkyrimNet.psc`, `MMENarrationText.psc`, `MMENarrationOverrides.psc`: tier/outcome selection and compatible inheritance.
- `tools/generate_narration_catalog.py`, schema/legacy/default metadata, generated catalog/defaults, `src/NarrationStore.cpp` and relevant headers: explicit optional tier entries, inherited preview and revisions.
- Existing Magelight page/script: categories and reopen regression; no second editor.
- JSON files: later additive tier pools only after wording is supplied; preserve old content.
- `tools/generate_ostim_only.py`, build/package scripts and affected tests: regenerate variants from source, do not patch generated variant files as the source of truth.

Compile every changed PSC and all affected OStim-only variants in isolated imports without SexLab sources. Rebuild native universal/VR targets if store/catalog changes require them. Verify source/PEX and page/catalog/DLL manifests, run targeted and existing regressions, rebuild `MME Extensions.zip`, and inspect FOMOD paths and exclusion of diagnostics/personal data. No plugin/master or original MME override is expected. Deployment is separate from implementation approval.

## Acceptance strategy and stop conditions

1. Probability tests exhaust all valid twenty-unit distributions and each slider edit; verify sum, step, endpoints, stable tie-breaking and corrupt input repair. Test roll boundaries directly, not only statistical frequencies.
2. Scheduling behavior tests cover staggered actors, initialization, load, re-enable, interval edits, chance failure, unsupported armor, range/unload/re-entry, wait/sleep/long absence, registry retirement and simultaneous callbacks. Demonstrate liveness when other scan consumers are disabled and bounded scans when several are enabled.
3. Runtime player/NPC tests independently force each tier through a development-only harness. No new shipping MCM testing controls. Confirm fixed mappings, hold extremes, visible movement recovery, concurrent actors, disabled paths and repeated use.
4. Interrupt with combat, mount/sit, external scenes, restraints, actor loss, feature disable and save/load during holds. Verify no stale owner, wrong-actor cleanup, duplicate threshold reaction or delayed injection queue.
5. Confirm unchanged milk/arousal calculations and no conversion/creation state changes. Test arousal capped, pending, absent and unreadable outcomes, plus milk-only/arousal-only/both/neither narration.
6. Content tests cover all sixteen tier entries, legacy arrays/single strings, absent/invalid tier data, inherited previews, tier and untiered personal overrides, Reset, Unicode/tokens/limits, conflicts, presets and live generated prompts. Do not infer runtime text from editor preview.
7. Logging matrix: master OFF/verbose OFF and master OFF/verbose ON produce no new routine footprints; master ON/verbose OFF includes all useful boundaries; master ON/verbose ON adds bounded detail only. Inject one genuine failure and verify alarm dedup; ordinary skips must remain quiet.
8. Standard/OStim-only, optional Skyrim.Net/arousal/DD frameworks present/absent; animation behaviors available/missing. Papyrus cannot acknowledge animation playback: missing behavior assets require visual diagnosis, not a fabricated successful-play claim.

Stop expansion on changed actor identity, stale deadlines, partial saves, wrong tier/outcome, repeated noise, unreleased movement, or accidental creation gameplay. Fix and retest the responsible layer before broadening coverage. A planning artifact or successful compile is not in-game acceptance.

Implementation sequence after approval: configuration/probability and save-safe schedules; shared nonblocking animation lifecycle; tier resolver/catalog/editor infrastructure with inherited old text; supplied prose integration; isolated builds/regressions/package inspection; separately authorized runtime deployment and acceptance.
