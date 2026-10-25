# MME compatibility override

MME Extensions ships a narrow `MilkQUEST.pex` compatibility override based on
the original MME script. It includes these intentional compatibility changes:

1. `AssignSlot()` and `AssignSlotMaid()` scan NPC slots `1..Length-1` without
   reading index `Length`. Original MME increments the index before reading it,
   which attempts `MilkMaid[20]` on its 20-entry array.
2. A completed production cycle sends `MME_MilkCycleComplete`, allowing the
   extension's Dwemer and maintenance systems to react after MME finishes.

The former diagnostic instrumentation and `MME_StartMilking.pex` override are
not included. MME's capacity progression, player slot, notifications, actor
initialization, factions, milk calculations, animations, and stories remain
unchanged apart from the compatibility safeguards described here.

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
