# Milking trigger diagnostics

This diagnostic build overrides `MilkQUEST.pex` and `MME_StartMilking.pex`
from original MME's 2022-05-22 scripts. Their sources live separately in
`Source/MMEDiagnosticOverrides`, not in the minimal developer SDK.
The local installed original MilkQUEST source matched that reference exactly
(SHA256: `605AF69DF97A1266AF67E9F6E8D0C1DB8BE9CB3DB038FE3B1622AA1AD9199805`).
Do not combine these overrides with another mod's modified MilkQUEST script
without merging the changes. Let this package win both script conflicts in Vortex.

## Test

Enable the existing master Papyrus logging toggle. Wear one tested armor at a
time, remain a registered Milk Maid, fill milk, then remain equipped through
several original MME production cycles. After using Wait, close the menu and
allow scripts time to finish. Keep original MME stories enabled for popup tests.

Search Papyrus logs for `[MME Milking Diagnostic]` and
`[MME Extensions Dwemer Armor]`. The chain is:

1. Timer entry and clock/elapsed-hours check.
2. Cycle start and actual slot-32 armor/recognition/rows/milk snapshot.
3. Living armor random roll and sex/proximity/SexLab gates.
4. Accepted spell cast, effect entry, effect rejection or accepted mode.
5. Milking entry, mode-3 selection/story eligibility, animation dispatch,
   story pool dispatch, and sequence end.
6. Cycle completion dispatch, Extensions event receipt, Dwemer scan/candidate
   decisions and the existing threshold/start/end/popup-result footprints.

Ordinary footprints require only the master logging switch, not the secondary
specific-diagnostic switch. No new MCM controls or gameplay changes are added.
Original MME's pre-existing logging is left intact.

## Smoke alarms

Required spell/controller/target and deficient original story pools produce
rate-limited alarm logs using the existing unconditional MMELog alarm policy.
No new HUD warning or popup is added.

While master logging is enabled, the existing controller callback also checks
for a production cycle outstanding for 300 real seconds and a player living
armor spell cast that has not reached Milking entry after 60 real seconds.
These are diagnostic suspicions, not proof: a long sequence, menu or delayed VM
can explain them. Each alarm kind is limited to once per 300 real seconds.
Timers reset when milking events register on initialization/load.
NPC dispatches have ordinary traces but no per-NPC timeout watchdog in this build.

No automatic retries, actor unlocking, timer repairs, random changes or animation
substitutions occur. The original effect's separate SexLab-validity, passive,
combat and mount gates remain unchanged.
