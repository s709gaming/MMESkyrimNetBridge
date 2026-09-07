# Reverse Milk Maid Leveling — manual ESP handoff

**Completed 2026-09-07:** installer revision 3 succeeded in SSEEdit with zero
errors across 49 records. The saved ESP is now in the repository and Vortex
staging folder. SEQ was regenerated from both start-enabled quests in that ESP.
The steps below are retained for reproducing the installation; they do not need
to be repeated when installing the completed release ZIP. Gameplay testing remains.

**Installer revision 3:** fixes MGEF data lookup by locating the container with
the actual scalar fields, then writes those fields directly. It retains revision
2's individual link/type diagnostics and also checks flags and actor values.
If revision 1 or 2 failed and you did not save, close that SSEEdit session without
saving and retry from disk with revision 3.
No Papyrus scripts need reinstalling for this installer-only revision.

## Run with Vortex

1. Close Skyrim. Back up your current `MMEAlert.esp` and a test save. Start from
   the current MME Extensions installation with the Blacksmith, Alchemist and
   Mage dialogue installers already applied.
2. Copy the handoff's `Scripts` and `Source` folders into your existing **MME
   Extensions Vortex staging folder**, then deploy. They contain only extension
   scripts. Do not copy anything from `tools/mme-sdk` into the game.
3. Copy `AddMMEExtensionsReverseLeveling.pas` into SSEEdit's `Edit Scripts`
   folder. Start SSEEdit against your deployed Skyrim `Data` directory. Load
   `Skyrim.esm`, `MilkModNEW.esp`, `MMEAlert.esp`, their required masters, and
   **all plugins overriding MME's Hey there DIAL/INFO** (`06544A` / `06544B` in
   MilkModNEW.esp). The installer requires MMEAlert.esp to win both records and
   preserve the earlier overrides' dialogue links/responses.
4. Right-click `MMEAlert.esp` → **Apply Script** →
   **AddMMEExtensionsReverseLeveling**. Wait for
   `MME Extensions Reverse Leveling installed successfully.`
   If any error/exception occurs, close without saving the target plugin;
   retain the log for diagnosis. xEdit scripts do not provide transaction rollback.
5. Review these six new records, then run **Check for Errors** on MMEAlert.esp:

   | Type | EditorID | Expected wiring |
   |---|---|---|
   | QUST | `MMEExt_ReverseLevelQuest` | Start Game Enabled; `MMEReverseLevel`; `ReverseAbility` bound to the new SPEL |
   | SPEL | `MMEExt_ReverseLevelAbility` | Ability, Constant Effect, Self; exactly one new MGEF, magnitude/area/duration 0 |
   | MGEF | `MMEExt_ReverseLevelEffect` | Script archetype; Constant Effect/Self; `MMEReverseLevelEffect`; no hostile or actor-value modification |
   | GLOB | `MMEExt_MageReverseLevelAvailable` | Default 0; opening wrapper publishes eligibility |
   | DIAL | `MMEExt_MageReverseLevelTopic` | Same MME quest/branch as the extension's existing choices |
   | INFO | `MMEExt_MageReverseLevel` | Wizard faction AND availability = 1; `Fragment_ApplyReverseLeveling` |

   The existing opening INFO gains one property and one **Link To** entry.
   The player's prompt is “My tits are getting too big.” The mage response is
   “At that level of growth, I can see why. This spell should shave you down a
   few notches whenever you're milked.” The result fragment belongs to the
   extension's `MMEBlacksmithDialogue` wrapper, which retains the original
   MME opening behavior through inheritance. No original MME PEX/PSC is replaced.
6. Save **MMEAlert.esp only**. Generate its SEQ using the plugin context menu
   **Other → Create SEQ File** (this includes the new start-enabled quest).
   Copy the saved `Data/MMEAlert.esp` and `Data/SEQ/MMEAlert.seq` back into
   both your MME Extensions Vortex staging folder and the matching repository
   root/`SEQ` paths. Redeploy so Vortex retains the edited plugin and SEQ.
7. Test in game before building a release. The installer preserves the new
   records' FormIDs and avoids duplicate links on reruns; do not compact their
   FormIDs after starting a save with the feature.

The new dialogue is unvoiced, using the existing forced-subtitle response
template. Allow the subtitle response to finish so its result fragment runs.
The ability's duration is managed in **game hours** by its quest, so the engine's
Active Effects display will not show a native countdown. Reapplication refreshes
the deadline without stacking another ability.

## Current repair: no SSEEdit rerun

The existing opening wrapper now gates the dialogue on the configured minimum
Milk Maid level (default 5, range 1-10), rechecked at selection. The slider never
changes the player's actual level or progress. Existing values become the threshold.
Misc is before Debug and Troubleshoot; duration and minimum level are on the left,
with debug Apply/Remove and optional Reverse Leveling Trace on the right.

Each completed milking with positive progression lowers the current level by
exactly one (10 to 9). Progress resets to zero so accumulated overflow cannot
immediately restore the level. Original MME setMaidLevel recalculates dependent
values. Multiple gushes are collected until BeingMilkedPassive ends; duplicate
completion/cycle callbacks cannot decrement again. Another milking can lower
one further level. Only a player `MME_MilkingDone` event with positive bottles
authorizes a decrease. Passive growth, vendor dialogue and eventless progress
never authorize one; MilkCycleComplete and the watcher only schedule checks.
The watcher only runs while active. Sessions completing after expiry are not reversed.

Each actual decrease shows:
`Your breasts feel lighter. Milk maid level decreased by 1.`
Level zero remains at zero without a false notification. Reapplying refreshes
duration; removing stops future losses. Loading upgrades the old progression
snapshot without restoring previously lost levels. Use original MME's debug
menu to restore a test level if an earlier build already reduced it.

The trace toggle defaults off. Enabled traces use `[MME Reverse Level]` and
report APPLY, LOAD, MILKING DONE, DECREASE, REBASE, DEFER and REMOVE. Debug Apply
bypasses the dialogue minimum but still requires an existing Milk Maid.

## Verification

`python tools/test_reverse_leveling.py` executes the actual check body against
mocked MME storage: 14 tests including 198 combinations of levels, difficulties
and gain sizes. Tests cover huge gains, duplicate events, multi-gush sessions,
stale snapshots, successive sessions, zero floor, eventless/empty/NPC event rejection,
expiry and MCM wiring.
The full package build compiles all extension scripts and runs existing checks.
No original MME script is modified or shipped. The current ESP adds OnEnd
bindings to the seven blacksmith/alchemist/mage service INFOs. These play vanilla
IdleGive (Skyrim.esm 0B5E20) only after a successful service and its final line.
Existing OnBegin actions, opening dialogue, conditions, FormIDs and SEQ are preserved.
The updated ESP is already in the project and release ZIP; no SSEEdit rerun is needed.

After rerunning any older xEdit service installer, run
`python tools/add_service_completion_fragments.py MMEAlert.esp` before packaging.
The strict, idempotent helper backs up the ESP before changing it; `--check`
verifies bindings without writing. Its layout follows xEdit's INFO VMAD schema.

In Skyrim, check dialogue visibility below/at/above the configured threshold;
confirm moving the slider never changes the actual level. At level ten, apply
and finish milking: expect level nine, zero progress, and one notification.
Wait afterward to confirm there is no further decrement without another session
even if passive progress increases. Verify a successful service gestures after
its response; opening dialogue and rejected services must not gesture.
Test save/load, removal and expiry. Runtime
scheduler behavior is not simulated by the tests; a third-party storage writer
can still interleave between the final read-back check and the write.
