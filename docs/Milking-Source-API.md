# Milking source API

MMEMilkingSource.psc records actor-local current and latest completed MME
sessions. It does not start milking, change milk/levels/slots/inventory or add a
polling loop. After committing a completion snapshot it calls MMEPostMilking,
which owns optional history and narration. No new plugin or quest is required.
Existing saves start with Generic/no completed record.

## Methods

0 Generic; 1 Hands; 2 Pump; 3 Milking Equipment; 4 Living Tendrils;
5 Dwemer Machinery. MethodName converts an ID to a readable label.

The final original MME mode is captured immediately before its start broadcast,
after equipment selection and early exits. Mode 0 -> Pump, 1 -> Hands,
2 -> Equipment, 3 -> Living Tendrils. Mode 4 is Generic unless the verified
dedicated Dwemer sequence is active. Unknown external callers remain Generic.
Hands does not prove self-milking or identify another actor's hands.
The living/parasite category is intentionally presented as living tendrils;
it is not a claim about a particular outfit or creature. Do not add precise
tentacle anatomy from that category alone.

## Read API

- IsMilking(actor): original MME BeingMilkedPassive spell is authority.
- GetCurrentSession(actor): active tracked token, zero for untracked/no session.
- GetCurrentMethod(actor): current recorded method, otherwise Generic.
- GetLastMethod(actor): latest completed session method, otherwise Generic.
- GetLastSession(actor): positive session ID, zero means no completion record.
- WasMilkRemoved(actor): completion bottles > 0 or stored milk decreased.
- GetLastNetMilkRemoved(actor): starting milk minus ending milk; may be negative.
- GetLastFinishedDays(actor): in-game days at completion, not real seconds.

The committed MME.Source.LastAfter value is the milk count at completion;
MMEPostMilking receives that immutable value and the net delta directly.

Always check the session ID and completion age before reacting. Last completed
does not mean currently happening. WasMilkRemoved can be true without net
reduction if production/feeding continued during extraction: only positive net
reduction supports a factual claim of having less milk afterward. False from
WasMilkRemoved means extraction was not proven by those signals. Completion
with no extraction is recorded, not silently promoted to success. Clothing is
snapshotted at start and cannot rewrite the method afterward.

## Internal integration and safety

Begin(actor, finalMode, finalEquipment) returns an actor-local token. Complete
receives that same local token after original MME cleanup and before
MME_MilkingDone. The original earlier StopMilkingMachine broadcast is not
completion and is not used to finalize these facts. No existing event signatures
or original control flow are changed.

The existing MilkQUEST override needs two metadata calls because MME's public
events omit its final mode. Source generators carry both hooks into OStim-only
and Estrus Unified variants; P+ uses the same common override. These are the
only new changes to original MME execution. Original source signatures, final
mode selection, actor guards, cleanup and completion payload were inspected.

Tokens isolate actors and reject duplicate/late completion. Abandoned metadata
is replaced at a new valid MME start without claiming the interrupted session
completed. The original passive spell prevents stale metadata from answering
IsMilking after interruption. In-progress MME stacks can retain the token across
saves; newly installed tracking during an old session safely reports Generic.
Master OFF suppresses Begin/query results; completion still clears owned active
metadata. All writes use MME.Source.* keys. Only one last record is retained.

Generic/untracked sessions, children/non-maids, disabled features, late events
and interruptions are gated normal skips. Missing actors at internal hooks,
impossible future tokens/counter overflow, invalid completion counts and missing
required MME query prerequisites are deduplicated alarms independent of logging.
Sparse [MME Milking Source] START/COMPLETE/skip/cleanup traces use the existing
master logging toggle. Getters stay quiet for repeated future consumers.

## Narration remains separate

Generic stop events still finish existing sound/gameplay cleanup, but no longer
publish the old ending context. Confirmed, productive completions record a
source-specific persistent event. Ordinary completion speech is dispatched from
MME_MilkingDone; Dwemer speech waits for its dedicated cleanup and replaces its
old ending request. The publisher consumes each session once, checks snapshots,
and applies actor-local speech cooldown/chance separately from history tracking.
Breastfeeding is not identified as a separate method; if
it invokes an MME milking transaction without a known source, Generic applies.
Leaking and periodic armor teasing alone are not MME milking sessions.

## History and narration settings

Skyrim.Net MCM owns Track Full Capacity, Track Milking Start / Completion,
Narrate Milking Completion (ON), Completion Cooldown (120 real seconds per
actor), Completion Chance (100%), and Milk Full Narration Chance (100%). New
fullness cooldown defaults are 120 seconds; saved cooldown choices are retained.
Missing-only initialization and MCM version 172 support existing saves.

Milking.json contains six editable source descriptions, result fragments, a
productive-without-net-reduction description and a shared reaction instruction.
Fullness.full_event is the editable historical full/leaking crossing. Event text
contains past experience; imperative reaction instructions and shared lore/tone
are added only to the spoken request. Persistent events do not themselves demand
speech or expire. This does not create a timed satisfaction mechanic: the earlier
one-game-hour suggestion remains unimplemented. Current actor status supersedes
historical milk amounts. A persistent event is attempted once per session/crossing,
independent of speech controls; DirectNarration can also retain its own request
history in Skyrim.Net.

First capacity observation establishes a baseline without inventing a crossing.
All observed actors record full crossings, while scan-level selection still
limits fullness speech. Dropping below full rearms the next crossing. No polling
status events or new scan/timer are introduced. Master/dependency OFF suppresses
publication; no old events are replayed later. Interrupted/untracked/no-extraction
sessions never claim success. Extraction without net reduction never claims relief
or emptiness. Nonempty completed results say some milk remained.

Player completion speech uses the existing private prompt and a request-specific
load/session marker, stripped before TTS. Missing, expired, stale or uncorrelated
replies are suppressed without NPC fallback. Pending requests expire after 120 real
seconds. A model that omits the required routing marker produces no player line.
Combat, scenes, framework busy state and owned animations suppress speech without
discarding the history. Sparse master traces and deduplicated alarms identify
entry, actor/source/results, skips, request outcomes and callback cleanup.

## Verification

Actual-source branch tests mock engine/storage and cover all modes, Generic,
Dwemer ownership, player/NPC isolation, clothing snapshots, zero extraction,
ongoing production, disabled/old-save behavior, interruption, late/duplicate
tokens and invalid completion data. They are not live Papyrus acceptance.
Compile and inspect standard/OStim/Estrus hooks and shipped source/PEX pairs.
Live acceptance remains for each route, simultaneous actors, save/load mid-milk,
interruption, metadata lookup after outfit changes, master logging OFF/ON and
optional framework absence. Future consumers must not interpret Generic as an
error or infer current clothing from the last method.
