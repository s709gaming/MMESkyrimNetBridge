# MME compatibility override

MME Extensions ships a narrow `MilkQUEST.pex` compatibility override based on
the original MME script. It includes these intentional compatibility changes:

1. `AssignSlot()` and `AssignSlotMaid()` scan NPC slots `1..Length-1` without
   reading index `Length`. Original MME increments the index before reading it,
   which attempts `MilkMaid[20]` on its 20-entry array.
2. Missing SexLab facial expressions are skipped safely, and closed-gag feeding
   blocks use gated traces instead of interrupting message boxes.
3. Optional DD calls are guarded as described below.
4. Estrus Unified pregnancies are recognized through its public API as described
   below, alongside the existing separate Estrus mods.

The original MME production-cycle `MME_MilkCycleComplete` event is retained;
it is not a new hook introduced by this override.

The former diagnostic instrumentation and `MME_StartMilking.pex` override are
not included. MME's capacity progression, player slot, notifications, actor
initialization, factions, milk calculations, animations, and stories remain
unchanged apart from the compatibility safeguards described here.

## Estrus Unified pregnancy recognition

Based on risarei's supplied pregnancy-detection patch, both standard SexLab/P+
and generated OStim-only MilkQUEST variants recognize Unified Chaurus, Spider
and Dwemer pregnancies on the actual player or NPC reference. The legacy separate
Estrus plugin checks and other pregnancy integrations remain unchanged. Do not
load the old Estrus plugins alongside Unified merely because detection supports
either setup.

Unified remains optional. The extension's DLL resolves the public IsReady and
GetPregnancyType functions dynamically and validates their native, static,
non-latent signatures before forwarding through the VM marshaller. It returns
the result synchronously, without queues, stale pregnancy caches or suspended
save stacks. Common scripts reference only the extension's own facade; no
Estrus API shim, Unified script type or plugin master is added to the package.
Missing/unready Unified and failed queries fall through to MME's old checks.

This recognizes pregnancy; it does not start Unified scenes, replace MilkMCM,
or change MME's calculations. Original MME can automatically assign an eligible
pregnant player a Milk Maid slot: recognizing a Unified pregnancy allows that
existing behavior too. No separate conversion or inventory-transfer logic is
added. No new setting or existing-save migration is required.

[MME Extensions Estrus] result/state footprints use the existing master Papyrus
logging toggle. Repeated query entry/completion details additionally require
verbose logging. Unchanged results are suppressed using bounded native diagnostic
history, reset on load/new game; this history is never used to answer pregnancy
queries. Actual API failures produce deduplicated alarms with actor and reason.
Normal absence, startup unready state and nonpregnancy are not alarms.

Native policy tests cover absent dependencies, player/NPC result isolation,
birth/reset, readiness transitions, invalid results and logging suppression.
They do not prove engine-side binding or gameplay. Runtime validation remains
required for all three pregnancy types on player/NPC, birth/reset, original MME
conversion rules, dependency absence, save/load, logging and both backends.

Because `MilkQUEST.pex` is an override, another mod that replaces the same
script requires a deliberate merge. Let MME Extensions win this script conflict
in MO2 unless the other replacement already includes these changes.

## Optional Devious Devices guard

All DD queries in the MilkQUEST override now use a guarded helper. The original
full MME_DDi bridge dereferences zadLibs without checking whether zadQuest exists;
selecting that bridge and later disabling DD otherwise causes None-object and
None-keyword errors during milking, armor selection, leaking, and piercing checks.

The helper requires the Assets and Integration plugins, zadQuest, a valid actor,
and the MME DDi bridge before calling the original DD methods. Missing optional
DD returns false for DD-only checks. Existing slot-56 name-based piercing/plug
checks, MME arrays, capacity, inventory, and milking cleanup remain unchanged.
No DD script type or plugin master is added, and MME_DDi itself is not replaced.

Sparse [MME Extensions DD] traces use MMELog.MasterDiagnostic (enablePapyrusTrace),
covering bridge state changes and milking check entry/results. There is no per-tick
trace for unchanged availability. Invalid actor or loaded DD with a missing MME
bridge produces a deduplicated alarm; absent DD is only a gated trace. New diagnostic
fields use safe defaults; no existing properties are renamed. A previously saved
availability state is never trusted for gating: prerequisites are checked per query.

Runtime validation pending: player and NPC milking with DD absent/present, actual
DD restraints/milkers, repeated milking and cleanup, leaking, slot-56 plugs,
save/load after changing dependency availability, and master logging off/on.
This addresses Papyrus DD errors; it does not establish or fix the native CTD cause.

## Building with MO2 dependency sources

When physical Data no longer contains optional SDK sources after a Vortex purge,
set the process environment variable MME_PAPYRUS_EXTRA_IMPORTS to a semicolon-separated
list of dependency source directories in the enabled MO2 mods before running
build-package.ps1. These directories supplement existing imports, are not packaged,
and do not install or deploy anything. Use MO2 precedence when constructing the list.
