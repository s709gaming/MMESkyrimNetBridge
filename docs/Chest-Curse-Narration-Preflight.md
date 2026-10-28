# Chest curse narration plan and preflight

2026-10-27. Audit only; no gameplay source, installed files, profiles or packages changed.

## Desired result

One short, positive, playful reaction after a successful treasure-chest Milk Maid curse. The line should feel like spontaneous banter: surprise at the body's sudden ripeness/fullness, followed by a playful suspicion that something enchanted in the chest caused it. The model must receive the chest and magical cause as facts, while the spoken line may express that connection through a rhetorical question or cheeky suspicion rather than an exposition dump.

### Canonical editable instruction

> A magical Milk Maid curse has emerged from a {chest_kind} and affected {actor}. {outcome} Speak as {actor} in first person. React in one or two short sentences of cheerful, lightly sensual storybook banter. Express surprise at the sudden change, then playfully suspect a cheeky enchantment or magical treasure inside that chest. Keep the chest connection identifiable, but do not mechanically explain the spell or repeat these instructions. Favor natural rhetorical questions and playful innuendo about ripeness, fullness, unexpected bounty or wobbling back to town. Treat the effect as a delightful surprise, with personality-appropriate humor. Vary the wording and punchline; not every line needs a wobbling joke. Do not claim she drank anything, invent physical loot, or say she became a Milk Maid again if she was already one. Milk added by this event: {milk_added}; use this only as factual context, not a demand to recite numbers.

Example output, not a required template:

> Whoa, when did my melons grow so wonderfully ripe? There must've been a cheeky little enchantment tucked inside that chest!

The prompt must distinguish conversion from surge. Conversion means milk production was newly awakened; do not claim a measured milk increase unless one actually occurred. Surge means an existing Milk Maid's reserves increased; do not describe a second conversion. A spell's cause is established in context, not left for the model to invent.

## Verified current flow

- MMEDungeonChestConversion knows chest identity, boss/regular kind, selected actor and conversion/surge choice. It calls MMEMilkCurse.ApplySurge or MMENewMilkMaid.TryCreateMilkMaidWithContext.
- ApplySurge captures requested and actual milk delta immediately after the write. By the time its ten-second reaction completes, ordinary MME production/leak/clamp may have changed the stored amount. Do not infer the event's exact addition by reading milk again in the outer chest handler.
- MMENewMilkMaid has an explicit chestCurse branch and already suppresses normal creation narration through CheckMilkmaidCreation(..., False, False). Chest conversion then calls MMEMilkCurse.Feedback.
- MMEMilkCurse.Feedback knows converted versus surge, but carries no chest kind/source. It currently sends generic forced-conversion narration or generic existing-maid curse narration. Non-chest public curse calls can reach the same feedback helper, so rewriting that helper's default prompt to assume a chest would be incorrect.
- Narration JSON is already centralized in SKSE/Plugins/StorageUtilData/MMEAlerts/Narration. MilkMaidCreation.json has conversion and generic curse routes. MMENarrationText.Text supports six token pairs, sufficient for actor/outcome/chest_kind/milk_added.
- Player speech already uses SendCustomPromptToLLM with an attached MMEAlertsController instance callback and TriggerPlayerTTS. NPC speech uses DirectNarration with the affected actor explicitly selected and the player as listener. Do not use NPC narration as a player fallback.
- Existing enableForcedMilkMaidNarration is a shared master for forced-conversion/curse feedback. Keep its saved value authoritative. Skyrim.Net plugin absence or its global enabled setting being off must remain safe skips.

## Implementation plan

1. Add a new editable route, e.g. narrate_chest_milk_maid_curse_1, to Narration/MilkMaidCreation.json. Register actor, outcome, chest_kind and milk_added in narration-schema.json; regenerate compiled defaults and the token guide. Reuse the established validation, fallback and explicit reload path. Keep generic conversion and non-chest curse templates unchanged.
2. Add Enable Chest Curse Narration on Misc, default 1 through HasIntValue-guarded initialization. Preserve existing saved preferences and advance only the internal MCM schema revision. Explain that both this chest-specific switch and the existing narration master must be on. Retain its setting while the chest feature is disabled; combine UI disabled flags sensibly with the master. Do not make story popups or notifications depend on this new toggle.
3. Introduce an explicit internal chest narration context path. Preserve existing public API signatures and the default behavior of non-chest calls. Carry chest kind/identity and outcome into the actual effect service, and carry the captured immediate surge delta through cleanup into publication. Use internal wrappers/context-aware helpers as needed; avoid a mutable global last-chest variable or actor context that an overlapping call could overwrite. Chest identity belongs in diagnostics, not spoken text.
4. On a successful committed chest effect, publish the existing brief notification normally, then request exactly one new chest narration after movement/animation cleanup. Suppress the old generic narration only for that chest request, even if chest narration is off or Skyrim.Net is absent; do not let it leak through as a fallback. Failed selection/chance/eligibility does not narrate. A failed milk write must not announce a successful increase. Presentation interruption must not retry the committed milk action to obtain narration.
5. Add a dedicated chest player callback on MMEAlertsController and a guarded playback function in MMEAlertsSkyrimNet. At dispatch, check Extensions master, chest narration switch, existing forced-narration master, Skyrim.Net enabled/present, actor lifecycle and appropriate route. Before player TTS, recheck output authorization and player validity. Retain explicit player speaker instructions and never fall back to a nearby NPC. NPC requests use the affected NPC as originator; the switch is checked before dispatch, while Skyrim.Net owns already accepted asynchronous NPC playback.
6. Encode dynamic context safely with existing EscapeJsonString/renderer helpers. Send magic/source/outcome as strings or factual prose; do not build JSON from unquoted Papyrus boolean text. The context clearly says source=treasure_chest. Supply boss/regular kind in readable wording, and the actual measured surge delta. Keep conversion's initial milk state distinct from a surge; do not fabricate an addition from configured percentage.
7. Add low-frequency MMELog.MasterDiagnostic footprints under a chest narration prefix: entry, actor, chest identity/kind, outcome, measured delta, enabled/optional-dependency skip, JSON route, request acceptance/result and player playback/cancellation. Avoid routine notifications, full prompt spam and polling. Use rate-limited alarms for genuine missing required callback/broken prerequisite or invalid context; disabled settings, absent Skyrim.Net and unavailable actors are expected skips.

## Validation before packaging

- Player and NPC conversion, player and NPC surge: one new chest route, correct actor, correct source and outcome, exact immediate delta for surge, and no old generic narration for the same event. Non-chest APIs retain their generic routes and text.
- Chest narration off, shared narration master off, Extensions off, Skyrim.Net absent, Skyrim.Net disabled: no voice request, no gameplay rollback, normal notification/story settings preserved. Existing-save defaulting does not override an explicitly disabled master.
- Player generation failure, toggle changed while awaiting response, actor death/unload, repeated/overlapping events and load boundaries: no NPC fallback, duplicate dispatch or stale mutable chest context. Do not claim arbitrary asynchronous request cancellation capabilities that the backend does not expose.
- Rendering: actor names containing quotes/Unicode/braces, readable chest kinds, valid JSON context, all four tokens supplied, editable template pools and compiled fallback, invalid template handling. Keep short-line style as an instruction; a prompt alone cannot guarantee every generated sentence obeys wording or length constraints.
- Test the new native transport route separately while retaining baseline checks for old routes. Compile all changed PSC, including callback/controller, and regenerate affected OStim-only variants (controller and MMENewMilkMaid are generated variants). Verify no optional-mod master/type leak, narration schema/default consistency, existing curse/pool-reader contracts and XML installer checks.
- Rebuild MME Extensions.zip, inspect matching source/PEX and the editable JSON route, keep diagnostic artifacts out. No release-number changes, README edits, installed file/profile modifications, deployment or live state changes during implementation without authorization.

## Decision

Ready to implement. Main risks are duplicate generic narration, confusing conversion with an existing-maid surge, reading a delayed milk value as the original event delta, and player speech bypassing the new toggle via the old callback. The explicit context path, dedicated callback and scoped publication guards address these. Skyrim.Net remains optional; gameplay success never depends on an LLM/TTS response. Native MME stories and the recurring quit/Alt+F4 crash remain outside scope.
