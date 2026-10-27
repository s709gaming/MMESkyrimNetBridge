# Milk Maid menu and canonical stories preflight

Audit only, 2026-10-27. No gameplay, installed files, profiles, or packages changed.

## Confirmed changes

- Rename the armor master display label to **Enable Trap Armor Chest**, preserving enableChestArmorTrap and existing values.
- Add **Enable Milk Maid Curse Trap** under the Milk Maid chest section, backed by a new enableMilkMaidCurseTrap setting. Default on with HasIntValue-guarded initialization and a new internal MCM schema revision. Preserve independent boss/regular toggles, probabilities, surge percentage and ally scope.
- Remove **Forced Conversion Feedback** divider. Rename its labels to Enable Milk Maid Notifications, Enable Milk Maid Stories, Enable Skyrim.Net Narration, and Enable Milk Maid Diagnostics. Preserve existing enableForcedMilkMaid* keys and option property names. Help must say these settings govern the Extensions forced-conversion/curse routes, not every native MME event.
- Grey chest-specific children while the new master is off. Keep feedback options editable because non-chest callers still use them. Disabling the master must not clear child settings, chest resolution markers or user story choices, and must not disable exotic milk or armor traps.
- Gate both conversion and existing-maid surge in MMEDungeonChestConversion.HandleActivation. A disabled curse branch returns its normal no-outcome result, allowing the independent exotic milk branch to retain the existing priority chain. Recheck the new master immediately before a chest operation commits, since MCM state may change after initial selection. Once gameplay committed, always complete owned cleanup even if settings change.

## Story caller audit

MMENewMilkMaid.TryCreateMilkMaidWithContext currently shows the old openingStory/closingStory pair for non-chest forced conversions and MMEMilkCurse.ShowStory for chest conversion. MMEMilkCurse.ApplySurge also calls ShowStory. That shared helper already selects one entry from the five chestCurseStories, substitutes {actor}, respects the existing story toggle and limits popups to the player.

Use that existing five-entry pool for every Extensions-owned forced-conversion/curse story route. Call the shared selector once for successful forced conversion regardless of chest context; remove the old opening/closing display calls from that route. Leave the JSON key chestCurseStories in place for backward compatibility with edited pools; document that its use is broader than its historical name. Retain openingStory and closingStory as legacy configuration fields rather than destructively migrating player text or replacing unrelated native data.

Keep animation-only APIs story-free. Preserve registration, Lactacid initialization, milk addition/overflow, notifications, narration, locks, duration, actor targeting and chest chance rules. There is no need to change the public API signature or capability version for display-label changes and this default story selection.

The five stories describe magical abundance without requiring a particular previous Milk Maid state, so they fit conversion and surge. They become the default presentation pool for the scoped routes. NPC conversion/surge continues without player-interrupting story popups.

## Native MME boundary

Native MilkLactacidScr independently reads /MME/Strings lactacidstory and lactacidorgasm under MilkQuest.MilkStory. Its generated OStim-only counterpart retains those native story calls too. Normal Lactacid drinking can therefore still use native MME stories, outside the Extensions-owned forced-conversion API.

Do not silently override the native script or global MME strings to satisfy a menu cleanup. Extending the five-story system to native Lactacid would be a separate compatibility change: audit both standard and OStim-only versions, native MME story settings, and duplicate suppression before implementing it. This preflight covers the previously agreed Extensions-owned story scope.

## Implementation / validation

1. MCM: new option ID/reset, enabled default preserving existing values, master toggle handler with Save/ForcePageReset, tooltips, child flags that combine master with each boss/regular toggle, and internal schema upgrade. No existing setting renames.
2. Runtime: master off blocks conversion and surge; armor and exotic drink remain independent; toggling back on restores child configuration. No side effects or story when disabled. Existing non-chest API callers still work.
3. Story: successful player chest conversion, non-chest forced conversion and surge each show one randomly selected pool entry; story off shows none; NPCs show no popup; missing/empty pool uses one safe fallback. Preserve user-customized pool and legacy fields. No generic opening/closing duplicate and no new automatic story in animation-only calls.
4. Diagnostics: retain master-gated entry, route/actor, selected story index and cleanup footprints. Add a gated reason for a disabled chest master. Normal toggles and missing eligible targets are expected skips, not alarms. The renamed diagnostic option remains detailed feature logging, not a replacement for the master Papyrus toggle.
5. Compile each changed PSC, regenerate affected OStim-only sources/PEX, update relevant menu/story contracts without deleting behavior assertions, and run narration and curse regressions. Inspect final source/PEX pairs and MO2/Vortex FOMOD XML in MME Extensions.zip. No versioned release names or installation/deployment.

## Decision

Ready to implement the menu cleanup and Extensions-owned canonical story changes. No new gameplay blocker. Native MME Lactacid story replacement is explicitly outside this narrow change and should not be implied by the menu labels or release description.
