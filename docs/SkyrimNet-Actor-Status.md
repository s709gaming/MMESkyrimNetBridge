# Current MME actor status in Skyrim.Net

## Direct prompt transport

The two Extensions prompt modules no longer call the six Papyrus-registered
decorators. They use Skyrim.Net's built-in papyrus_util reads. Milk quantity and
capacity remain live reads of MME storage at render time; unknown is never zero.
Eligibility, armor/leak descriptions and editable lore are actor-local snapshots
under MME.Prompt.*, produced by MMEActorPromptState using the existing facades.
No new DLL, script, quest, property or hard optional dependency is introduced.

Registration's old public function name remains as a compatibility entry point,
but now initializes direct state and never calls RegisterDecorator. Legacy public
callback functions remain callable for compatibility, not used by templates.

## Initialization, update and cleanup

- Initialization/save load increments a global generation, invalidating prior
  snapshots; it bootstraps nearby actors once and the player. Existing gameplay/lifecycle
  scans then refresh the observed actor set, including normal/ineligible actors.
- Conversion hooks refresh after MME assignment. MaidRemove invalidates before
  removal. The original framework values, arrays and calculations are unchanged.
- Equipment events, own leak visual changes, external leak-end signals and
  existing shared observations refresh descriptions. Departed/dead/disabled actors
  lose readiness. Unloaded leak state is unknown, never inferred from fullness.
- Scene role events publish/clear guidance. OStim startup and session cleanup
  refresh both participants; the selected backend retains its original role checks.
- MCM close, lore editor completion and text reload republish settings/lore through
  the existing personal-override/default resolver. No duplicate lore setting.
- Recent-drink expiry uses the existing controller scheduler's earliest deadline,
  including when capacity/leak scans are disabled. Repeated drinks extend their
  own deadline; expiry clears recent-only lore without clearing a real maid's lore.
- Snapshot readiness commits last. Templates require global enable, actor readiness
  and matching generation; unavailable/incomplete snapshots render nothing.

Snapshots are event/scan updated, not engine reads on every render. Changes made
by outside mods without the known events reconcile on the next existing scan;
no independent refresh polling was introduced. Initial snapshots outside the
observed region are unavailable. Milk amounts are always independently read live.

## Eligibility, settings and wording

The exact existing MMEArmorScript eligibility facade is retained (its faction /
MME level-storage semantics); a new cached flag never converts or registers an
actor. Master MME, optional Skyrim.Net presence, bridge enable and the milk/armor
section toggles remain authoritative. MCM keys and user choices are unchanged.
Armor descriptions distinguish four supported families and Dwemer suit/attachment;
ordinary armor is not nudity. Only confirmed leak effects count as active.

Retired periodic AI state events and capacity milestone publishers remain inert.
Gameplay scans, reactions, auto-milking, body effects, Thoughts and leak scheduling
remain active. Histories and editable prose are not rewritten.

## Diagnostics and verification

Master Papyrus Logging records changed snapshots, initialization, invalidation,
expiry and cleanup. Milkmaid Bio Prompt adds focused resolver entry/return traces;
these now diagnose local snapshot production, not Skyrim.Net's callback cache.
Expected disabled/unknown states are skips. Invalid milk data and a missing expiry
scheduler are genuine deduplicated alarms, independent of routine logging.

Actual Inja tests register no legacy callbacks and cover player/NPC isolation,
missing/null actors, first render, readiness/generation, disabled sections,
thresholds, empty/unknown/full milk, armor families, independent leaks, scene roles
and edited guidance. Actual source expiry tests cover 90-second boundaries,
repeated drinks, actor isolation, cleanup and clock rollback. These do not replace
live acceptance after installation: save/load, normal dialogue and dashboard
previews, conversion/removal, equipment, leaks and both optional scene backends.

## Shared knowledge in MME dialogue requests (2026-11-01)

- MMEDialogueKnowledge reads editable Lore.milk_lore and Lore.shared_guidance through MMENarrationText, including saved personal overrides and normal default resolution. Shared Narration Guidance appears immediately beside Skyrim Milk Maid Lore in the editor. It supplies tone and brief-response instructions once per request; event templates supply the situation and specific reaction direction.
- Lore.milkmaid_lore remains the actor-specific identity entry, rendered with the actual actor name by the guarded Milk Maid decorator. It is not included in shared dialogue background. Shared lore does not establish speaker/listener identity or current effects.
- Every MME DirectNarration submission appends the background before the API call, retaining its exact content variable, originator, target, guards and API-result handling. This covers automatically selected speakers without temporarily marking nearby actors. Empty requests retain their original behavior; an already composed block is not appended twice.
- Private player requests include milkKnowledge in their escaped context JSON. The custom player template places it in the system message before generation, retaining playerInstructions, situation and callbacks. Player TTS remains playback only; it does not receive a second prompt or trigger bystander fallback.
- This is request-content enrichment, not permanent biography editing or a pre-speech callback. DirectNarration content can remain in Skyrim.Net event history; there is no strict promise that the knowledge can never influence later conversation. No world-knowledge database writes or temporary global actor flags are used.
- Existing narration switches/cooldowns and Skyrim.Net absence guards remain authoritative. Sparse master-gated traces identify route, known/automatic speaker and composed character count without logging full lore. Empty lore after normal fallback raises a deduplicated alarm independently of routine logging.
- Runtime acceptance requires installed matched source/PEX/template files: actual NPC, automatic speaker, player-only custom generation, edited lore, identity preservation, queue overlap, disabled/absent dependency, save/reload and rendered request inspection. Text composition does not guarantee model compliance with the desired tone.
- Existing saves with an older Lore.json resolve a missing shared_guidance entry through compiled defaults. Personal overrides remain authoritative: existing customized event prose is not silently replaced. Reset selected entries in the narration editor to adopt shorter defaults. Full-capacity narration says full and leaking, reflecting the current gameplay rule; half-full does not imply leaking. No leak mechanics were changed.
