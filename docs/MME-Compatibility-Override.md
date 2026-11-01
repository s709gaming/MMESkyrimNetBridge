# MME compatibility override

## Original MME quick settings and Difficulty display

Extensions mirrors 13 original MME controls at the top of General and Body.
`MMEOriginalSettings.psc` reads/writes the original quest properties, global
StorageUtil mastery value and player spell ownership. There are no mirrored
JSON values, automatic resets, polling or new quest properties to initialize.
Opening a page reads current MME values, including changes made in its menu.
The shortcuts remain usable independently of the Extensions gameplay switch;
they configure original MME, not Extensions gameplay.

The additional `MilkMCM.pex` override is based on original MME 20220522.
Its only behavioral changes are reading `TimesMilkedMult` to synchronize the
private Difficulty selection when a page or its selector opens, displaying
unknown multipliers as Custom, and rejecting invalid selection indices.
Original Difficulty setters and economy refresh behavior remain intact.
Both Standard/P+ and the generated OStim-only backend include this fix.
Another mod replacing MilkMCM requires a deliberate merge; this is an
intentional, small override, not a replacement MME menu.

The facade preserves original slider ranges/defaults (including volume-mode
growth ranges), the Difficulty economy initialization, PostMilk refreshes for
the original buffs/debuffs toggle, and CurrentSize refreshes for the size cap.
Growth sliders do not overwrite individual-maid settings. Spell changes target
only the original MME PlayerREF. No maid conversion, slot assignment or milk
inventory change is performed by the facade.

Milking Speed is the original Gush percentage, extracting a fraction of
remaining milk each cycle (minimum one unit); higher is faster. Cycle Duration
is not total session duration. Leveling Speed also changes MME economy.
The original (De)Buffs toggle includes beneficial effects, and original
penalties can stack with Extensions penalties. Zero maximum size is unlimited.

Sparse `[MME Original Settings]` entry/result and per-actor refresh traces use
the master Papyrus logging toggle. Broken prerequisites and failed spell
ownership changes produce deduplicated smoke alarms; recovery re-arms them.
There are no per-tick traces or diagnostic notifications.

Build validation includes compilation, a pinned normalized-source check that
rejects unrelated original-MCM edits, 13-control wiring checks, and package
source/PEX presence. Runtime acceptance remains required after installation:

- Change every control in each menu, reopen the other, and confirm both values.
- Check all six leveling presets, a preexisting Custom value, cancel, and save/load.
- Check spells absent/present and repeated add/remove; confirm NPC spells unchanged.
- Test debuffs and size-cap refresh on player and NPC maids, including empty slots.
- Check normal/volume growth mode, per-maid overrides, zero cap, and Extensions disabled.
- Confirm opening pages leaves existing values untouched; inspect logging off/on
  for wrong actors, errors, stack dumps and repeated alarms.

MME Extensions ships a narrow `MilkQUEST.pex` compatibility override based on
the original MME script. It includes these intentional compatibility changes:

1. `AssignSlot()` and `AssignSlotMaid()` scan NPC slots `1..Length-1` without
   reading index `Length`. Original MME increments the index before reading it,
   which attempts `MilkMaid[20]` on its 20-entry array.
2. Missing SexLab facial expressions are skipped safely, and closed-gag feeding
   blocks use gated traces instead of interrupting message boxes.
3. Optional DD calls are guarded as described below.
4. The optional Estrus Unified FOMOD override adds public-API pregnancy recognition
   alongside the existing separate Estrus checks; the default override omits it.

The original MME production-cycle `MME_MilkCycleComplete` event is retained;
it is not a new hook introduced by this override.

The former diagnostic instrumentation and `MME_StartMilking.pex` override are
not included. MME's capacity progression, player slot, notifications, actor
initialization, factions, milk calculations, animations, and stories remain
unchanged apart from the compatibility safeguards described here.

## Estrus Unified pregnancy recognition

Estrus Unified support is an optional FOMOD compatibility choice, based on the
mod author's supplied MilkQUEST patch. The default Standard/P+ and OStim scripts
have no Unified API references. Selecting the option installs a freshly compiled
matching backend override at installer priority 60. See
[Estrus Unified compatibility](Estrus-Unified-Compatibility.md) for dependencies,
credits, upgrade instructions, diagnostics and validation limits.

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
