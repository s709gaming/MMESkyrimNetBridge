# MME compatibility override

MME Extensions ships a narrow `MilkQUEST.pex` compatibility override based on
the original MME script. It contains two intentional changes:

1. `AssignSlot()` and `AssignSlotMaid()` scan NPC slots `1..Length-1` without
   reading index `Length`. Original MME increments the index before reading it,
   which attempts `MilkMaid[20]` on its 20-entry array.
2. A completed production cycle sends `MME_MilkCycleComplete`, allowing the
   extension's Dwemer and maintenance systems to react after MME finishes.

The former diagnostic instrumentation and `MME_StartMilking.pex` override are
not included. MME's capacity progression, player slot, notifications, actor
initialization, factions, milking behavior, animations, and stories remain
unchanged.

Because `MilkQUEST.pex` is an override, another mod that replaces the same
script requires a deliberate merge. Let MME Extensions win this script conflict
in Vortex unless the other replacement already includes these two changes.
