Movement slap sounds and flat milk stripping
===========================================

Body > Movement Slap contains Movement Slap Sounds (on by default) and Movement Slap
Volume (0–200%, default 100%). This is player-only and requires milk fullness
strictly above 50%, on-foot directional movement, the Extensions master, and
the existing sound master. The existing Moaning Sound Volume also scales it.
Walking, running, sprinting, sneaking, controller input and auto-move use engine
direction state rather than hard-coded keyboard keys. Movement intent against
an obstacle may still count; this is not a distance-travelled measurement.

One controller-owned looping sound instance is checked by the existing shared
single-update scheduler at a nominal half-second interval. Papyrus load may
delay this interval. Menus publish a separate stop event because regular game
updates pause in menus. Mounting, swimming, airborne/sitting/sleeping states,
disabled movement controls, MME milking, SexLab/OStim scenes, DHLP suspension,
and owned extension animations block playback. Disabling a setting stops its
instance. Save-load recovery discards session-local audio IDs.

The original breast-bounce sound remains unchanged. The movement-only WAV has
exactly twice the original PCM amplitude with no clipped samples. Its separate
looping SNDR 0008C4 / SOUN 0008C5 in MMEAlert.esp inherits the original category
and output model. Playback gain is slider / 200, multiplied by the existing
master sound volume. Thus 100% restores the original amplitude and 200% is +6 dB
at full master volume, not necessarily twice the perceived loudness.
tools/prepare_movement_slap.py reproducibly prepares the asset and records.

Armor > Armor Stripping adds Flat Milk Stripping (off by default), subordinate
to Override MME Armor Stripping. Heavy, light and clothing sliders range from
0–100 milk units, defaulting to 4, 8 and 12. These defaults and strict greater-than
comparisons match the original installed MME MilkQUEST.MilkCycle source.
Zero triggers with any positive milk; category toggles disable a category.

The shared player-only evaluator strips when its existing fullness percentage
is reached OR enabled flat milk is exceeded. Existing category controls,
timed armor bonds, registered special equipment protections, refit policy,
DD suit blocks and SexLab no-strip checks still apply. The existing Strip All
Armor setting retains its own protection-bypass policy. Equip, capacity-poll
and deferred drink routes share the evaluator, including the existing attempted
milk handling for drinks whose stored value was clamped by MME. No MME milk,
capacity, progression or inventory calculations are replaced.

MCM version 156 adds one guarded settings migration for both new and existing
saves, preserving all existing settings. The MCM master handler also now runs
its controller enable/disable block from the master branch; that existing block
was previously misplaced inside the breast-bounce sound toggle branch.

Validation before release: compile affected scripts and both native runtime
presets; run the asset isolation/gain tests and existing armor/sound/scheduler
contracts; rebuild and inspect the distributable. In-game validation remains
necessary after installation: direction changes and diagonals, rebinding,
controller dead zones, auto-move, movement against walls, 50% boundaries,
volume 0/100/200, menus and scenes, master/feature toggles, save/load, and all
three stripping categories below/equal/above thresholds. Verify flat-only and
percentage-only triggers, disabled categories, protected armor and NPC exclusion.

Version 157 additions and fixes
------------------------------

Body now constructs its title at runtime with an invisible trailing space, as
already done for the Animations/Arousal pages, to avoid Papyrus string interning
reusing an uppercase BODY token. Existing settings and the page index are kept.
Movement sounds and volume move from General to Body.

Movement Slap Notifications defaults on. Notification Cooldown ranges from 0?48
in-game hours, default 8, with one shared player-scoped StorageUtil timestamp
across the five supplied movement messages in BreastBounceNotifications.json.
First eligible playback can notify immediately. Zero removes the cooldown but
notifications are still evaluated only on a new successful playback start, not
per tick or per audio-loop repetition. Disabling notifications or waiting for
their cooldown never changes sound playback. The existing nearby-NPC breast
bounce notification pools and their separate schedule are unchanged.

Routine eligibility transitions, notification entry/shown/skip decisions,
cooldown remaining, settings changes and sound cleanup use MMELog.MasterDiagnostic,
which requires the master Papyrus Logging toggle. Eligibility logs occur only
when state changes; expected cooldowns/disabled settings are not smoke alarms.
Malformed or empty movement message data produces a deduplicated failure alarm.

All three extension-side MME_DDi call sites (arm checks, armor stripping and
Dwemer armor animation checks) now require both the DD Assets master and zadQuest
before using the bridge. MME can install the full bridge quest even without DD;
checking only that DDi is non-None was insufficient. The original bridge calls
and behavior remain authoritative with DD present, and no DD script/master
is added as a compile-time requirement. Initialization logs bridge availability
under master Papyrus Logging. Existing saved frames may finish old code on their
first resumed execution; subsequent invocations use the newly compiled guards.

The SexLab P+ FOMOD choice is now explicitly optional/manual. Its unreliable file
marker detection rules and the final auto-detection sentence are removed.
