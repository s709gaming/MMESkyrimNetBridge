# Milk Maid roster actions preflight

Prepared 2026-10-26. Audit and implementation contract only; gameplay code and installed files unchanged.

## Evidence and scope

Repository sources inspected: MMEExtensionsAPI, MMEAvailableMilkTransaction, MMENPCDialog, MMESelfMilking, MMEAnimationSafety, MMEDrinkTracker, MMEForcedMilkDrink, MMELog, and the roster controller/page. Original installed MME MilkQUEST and MilkLactacidScr sources verified. houseCARL confirms VortexToMO2 / Default and MME Extensions as the winning provider of MMENPCDialog, MMESelfMilking, and MilkQUEST PEX files. This is static evidence, not a live action test or a proof that installed PEX matches current repository source.

Existing public API version is 17. GiveAvailableMilk(giver, drinker) consumes one inventory item, leases both actors, verifies transfer/consumption, rolls back failures, and preserves player-alias versus NPC effect ownership. It rejects identical giver/drinker. ForceMilkDrink stages an extra item: do not use it for inventory-backed player drinking. MMESelfMilking dispatches MME MilkSelf; true means dispatched, not scene started. StartCompatible can return true for protected Living/Parasite armor while suppressing ordinary self-milking: that must not be shown as started.

## Planned API behavior

- Preserve existing public signatures and events. Document the intentional GiveAvailableMilk behavior change: confirmed recipient Milk Maids prefer owned Lactacid, then normal, racial, supernatural milk. Non-Milk Maids never automatically select Lactacid.
- Centralize recipient-aware inventory selection, keeping the existing two-argument FindFirstSupportedMilk as the ordinary-milk selector for compatibility. Add a separate recipient-aware helper used by both dialogue selection and the inventory-backed API. Resolve MME_Util_Potions only after None/size checks; original MME identifies index 0 as Lactacid.
- Recheck actual MME membership immediately before equipping Lactacid. If membership changed, cancel and restore the transferred item; do not silently convert or substitute during the transaction. Do not manually adjust Lactacid storage: MME's native potion effect owns it.
- Preserve the existing Free Jug fallback only after no eligible owned item exists. Never manufacture Lactacid. No milk-storage deduction for these inventory-backed drinks; do not use MMEActorDrinkTransaction.GiveDrink, which can fund a synthetic jug from MilkCurrent.
- Add public DrinkAvailableMilk(drinker) for consuming from that actor's own inventory. Use the same selector and cooperative actor lease, honor the existing Free Jug cheat fallback after owned items, and preserve native player/NPC observer ownership. No same-actor transfer or free Lactacid. The user explicitly requested the existing cheat toggle for this new entry point.
- Add a public manual self-milking wrapper through MMESelfMilking. Keep existing automatic/voice entry points compatible. Validate master, adult actor, current Milk Maid membership, nonzero milk, loaded/nearby state, combat/mount/sit/scene/restraint/animation ownership guards. Reject protected Living/Parasite/Dwemer armor initially with an expected skip rather than dispatching an unrelated armor route or replacing armor. MME retains all capacity, milking, output, and inventory semantics.
- Advance only the internal API capability revision when adding the new public wrappers. Do not change release version metadata or archive names.

## Roster wiring

NPC row: Give Milk (player inventory to selected NPC), Self Milk. Player row: Drink (own inventory), Self Milk. All rows remain visible when unloaded but their actions are disabled with a short reason. API availability and master state are checked at execution, not just when rendering.

The page currently sends no actor identity. Add an opaque per-refresh row token mapped to a captured Actor reference in Papyrus. Validate view, session, snapshot revision, token bounds, and live membership. Never use actor names, runtime FormIDs from JavaScript, or a retained MilkMaid array index as action authority. Reject stale page events and duplicate clicks. Rebuild mappings atomically with roster data; invalidate them on close/load/destroy. Capture the actor before closing the roster and releasing focus, then revalidate before dispatch. Use existing scheduling rather than Utility.Wait inside a menu handler. Do not reopen automatically during animations.

Keep manual self-milking dispatch separate from confirmed start. Observe MME's established actor-specific start/end events using the existing controller conventions; bound any pending request lease and recover it on load. A missing confirmation is not success. Avoid resetting animations or controls owned by MME or another mod.

## Diagnostics

Use MMELog.MasterDiagnostic for sparse action boundaries, independent of verbose logging: request, selected actor and action/token, eligibility or skip reason, selected item/category and Milk Maid membership, pre/post inventory counts, dispatch versus confirmed start, rollback and cleanup. Prefixes: [MME Maid Roster UI], [MME Extensions Available Milk API], [MME Extensions Self-Milking API]. Include actor identity/reference as well as display name. No polling traces or routine diagnostic notifications.

MMELog.Diagnostic currently requires both enablePapyrusTrace and enableVerbosePapyrusLogging; it alone does not meet the requested master-only footprints. Failures use deduplicated/rate-limited alarms identifying operation, actor, and reason. Cooldowns, optional dependencies absent, stale clicks, empty inventory, protected armor, and ordinary busy actors are expected skips. Verify logging with master on / verbose off, and master off.

## Implementation checks

1. Inventory selection: Milk Maid with Lactacid and all milk categories; no Lactacid; non-Milk Maid with Lactacid only; empty inventory with fallback on/off; player-owned consumption; ownership/membership changing before commit.
2. Transactions: exactly one consumed item, native Lactacid state changes once, existing stacks preserved, consumption/transfer rejection rollback, duplicate clicks and actor leases, player alias versus NPC observer duplicate suppression, narration/events published once.
3. Self-milking: player/NPC, zero milk, protected armor, restraint, busy animation, OStim/SexLab/MME scene, combat/mount/sit, unload, repeated use, confirmed start/end, interrupted/load recovery. No conversion or wrong actor.
4. UI: duplicate display names, stale/reordered roster, refreshed session tokens, Close/Escape focus restoration, disabled reasons, host missing, master/roster disabled, existing save initialization.
5. Compile all affected PSC and ship matching PEX. Rebuild and check standard and OStim-only variants: MMEAnimationSafety has a separate OStim-only implementation, so avoid adding a SexLab type to common UI code. Retain optional integrations and test dependency absence.
6. Update obsolete Lactacid-exclusion assertions deliberately. test_service_fragments.py also contains an old literal MCM Return 125 assertion: report/adapt only the relevant contract, not gameplay to fit a stale test. Run UI JS harness, relevant contracts and complete package checks; inspect MO2/Vortex XML and ZIP structure. No diagnostics or build-only SDKs in package.

## Concerns / go decision

Proceed with implementation after these guardrails; no fundamental blocker found. Primary risks are accidental Lactacid conversion after membership changes, duplicate native/explicit drink effects, stale row targeting, and reporting spell dispatch or armor suppression as actual milking. Original native effects run asynchronously, so static checks cannot prove live sequencing or eliminate every cross-mod race. Reserve live player/NPC, controls, and log smoke tests for the user-installed build. This preflight does not authorize deployment or modify installed files.
