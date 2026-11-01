# Milking source API

MMEMilkingSource.psc records actor-local current and latest completed MME
sessions. It does not start milking, change milk/levels/slots/inventory, add a
polling loop, or submit narration. No new plugin, quest, MCM setting or migration
is required. Existing saves start with Generic/no completed record.

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

Existing generic milking ending narration still uses the earlier stop event;
Dwemer also has its dedicated ending narration. This implementation does not
change either. A later narration integration must consume confirmed completion,
check extraction/net reduction, use the matching session, and avoid duplicate
Dwemer/generic lines. Breastfeeding is not identified as a separate method; if
it invokes an MME milking transaction without a known source, Generic applies.
Leaking and periodic armor teasing alone are not MME milking sessions.

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
