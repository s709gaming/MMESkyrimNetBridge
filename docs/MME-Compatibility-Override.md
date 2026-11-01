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
Its Difficulty changes read `TimesMilkedMult` to synchronize the
private Difficulty selection when a page or its selector opens, displaying
unknown multipliers as Custom, and rejecting invalid selection indices.
Original Difficulty setters and economy refresh behavior remain intact. Its fixed-production hourly preview also includes the new Lactacid bonus through the shared helper below.
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
5. The default-on, fixed-mode Lactacid feature below adds a configurable bonus
   and hourly fuel depletion; OFF restores original fixed behavior.

The original MME production-cycle `MME_MilkCycleComplete` event is retained;
it is not a new hook introduced by this override.

The former diagnostic instrumentation and `MME_StartMilking.pex` override are
not included. MME's capacity progression, player slot, notifications, actor
initialization, factions, milk calculations, animations, and stories remain
unchanged apart from the compatibility safeguards and fixed-mode Lactacid feature described here.

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

Active timed armor locks now acquire optional framework no-strip keywords through
the existing native DLL. The public timed-lock API, lock durations, and vendor/API
release routes are retained. Both frameworks may be absent: shared scripts import
neither framework API for protection. No installed framework scripts are overridden
by this feature, and no new MCM setting or required extender mod is introduced.

Keyword writes run on the game thread with bounded Papyrus confirmation. Lock
release, failed lock cleanup, expiration, disable, and save changes release owned
additions; existing-save locks rebuild them on recovery. Parasite expiry still
leaves the armor equipped and makes it removable. Only keywords added by this
service are removed, and another actor's lock on the same form retains protection.
Because keywords belong to the armor form, unlocked copies of that same form also
receive framework protection while a lock exists. Explicit framework Always Strip
overrides can supersede keywords; this feature preserves those user settings.
Third parties adding the identical keyword after us have no shared ownership
protocol, so they should retain/reapply their own protection when our lock ends.

Routine lock-protection traces use the master `enablePapyrusTrace` switch. Actual
application/timeout failures produce deduplicated smoke alarms. Forced removal
recovery remains the fallback. Compilation/package checks are separate from live
acceptance of scene startup, transition, cleanup, and saved-game recovery.

When physical Data no longer contains optional SDK sources after a Vortex purge,
set the process environment variable MME_PAPYRUS_EXTRA_IMPORTS to a semicolon-separated
list of dependency source directories in the enabled MO2 mods before running
build-package.ps1. These directories supplement existing imports, are not packaged,
and do not install or deploy anything. Use MO2 precedence when constructing the list.

## Roster Auto/Manual mode mirror

The optional Maid Roster adds a robot button beside Drink/Give Milk and Self Milk.
Its highlighted state is original MME Auto (2); clicking sets Manual (0), and
clicking Manual sets Auto. Existing Off (1) remains untouched on opening and is
identified in the tooltip; it is not offered as a third choice. Missing original
storage defaults to Manual exactly as MME does. This does not configure Extensions'
separate Auto Self-Milking feature or override original armor/slave behavior.

MMEOriginalSettings owns the per-actor read/write and readback check. Only the
existing MME.MilkMaid.MilkingMode integer is changed. No milk amounts, slots,
maid levels, spells, animations, timers or gameplay JSON defaults are changed.
The roster keeps its session/revision/row bounds and action allowlist checks,
resolves the actor from its own snapshot, then revalidates current MME membership.
Mode changes keep the roster open and refresh authoritative values. Zero milk,
combat, scene animation and unloaded 3D do not by themselves block a stored
preference edit; no scene or milking action is dispatched by the new route.
Deleted, dead, child or deregistered targets are rejected. Drink/Self Milk retain
their existing availability guards and close/dispatch behavior.

Routine request, token, actor, current/requested mode, eligibility, readback and
cleanup footprints use the existing master Papyrus logging switch. Expected stale
requests, unavailable actors and repeated selections are traces, not smoke alarms.
Invalid original values, invalid setter requests and failed readback produce
failure alarms through the existing deduplication helper. There are no diagnostic
notifications or new update loops. No original MME script edit is needed for this
mode mirror: the original MCM reads the same value when its page redraws.

Validation: real-page JavaScript tests cover both states, legacy Off preservation,
zero milk, unknown/older payloads, NPC row tokens, duplicate clicks and refreshed
state. Source contracts protect actor targeting, snapshot guards, master logging
and absence of gameplay dispatch. Both affected Papyrus scripts are compiled;
the narrow roster SDK projection is compile-only and must never be shipped.
Live two-way original-MCM synchronization, player/NPC selection, logging off/on,
existing saves and disabled/optional-host scenarios remain acceptance tests after
separately authorized installation.

## Fixed-mode Lactacid boost (2026-11-01)

- General: **Fixed Mode Lactacid Boost** defaults ON. **Lactacid Production Bonus** defaults +50%, range 0-200% in 5% steps. These are Extensions settings, separate from the 13 original MME shortcuts above.
- Applies only to an actor using original fixed production (all actors, or the original NPC-only flag). Both controls are disabled when neither fixed option is on; the percentage is also disabled when this toggle is OFF.
- Each stored Lactacid unit lasts one simulated MME hour. Additional Lactacid extends duration rather than strength. No inventory bottles are automatically consumed. At zero fuel, fixed production returns to its normal formula immediately for subsequent simulated time.
- Enabled fixed mode replaces original fixed Lactacid depletion, avoiding double consumption. It ignores original Lactacid decay/strength settings. OFF restores original fixed consumption; dynamic production retains original behavior. 0% adds no milk but still depletes fuel hourly.
- Sleep/wait catch-up boosts only the fueled portion, including fractional final hours. Original breast-scale production caps remain; fuel expiry uses the elapsed time before the production cap. MME's legacy real-time MilkPoll >24 still advances one simulated hour per tick, rather than following elapsed game hours.
- The shared `MMEFixedLactacid.psc` helper calculates bonus milk; MilkQUEST owns actor-state writes. Original MME downstream overflow, pain reduction and optional production-based progression receive the boosted milk total.
- Existing saves: missing keys initialize ON/+50% through MCM version 169; explicit OFF/custom percentages are preserved. No actor migration, new quest properties, timer, dynamic lactation write or slot change is introduced.
- Original MME's hourly production preview uses the same helper. Standard/P+, OStim-only and Estrus Unified variants are rebuilt from matching sources. Competing MilkQUEST/MilkMCM overrides require a deliberate merge.
- `[MME Fixed Lactacid]` cycle/settings traces use the master Papyrus logging toggle. True input/settings/save failures raise deduplicated smoke alarms when detected, independently of routine logging.
- Live acceptance after installation: player/NPC; all/NPC-only fixed flags; dynamic and toggle OFF; +0/+50/+200%; zero/fractional/stacked fuel; sleep/wait; capacity/overflow; repeated drinks; old saves; optional backends; logging off/on and error recovery. Compilation and numerical/package checks do not prove live acceptance.
