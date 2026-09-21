# Skyrim.Net targeted Milk Maid conversion

## Implemented route

`MakeTargetNewMilkMaid` accepts one explicitly selected nearby female NPC. Its AI-facing description treats the transformation as an open-ended narrative tool: Lactacid, unusual milk, magic, curses, blessings, experiments, accidents, and voluntary changes can all invoke the same mechanical result. Its Papyrus entry point lives on the persistent `MMEAlertDebugQuest`, then delegates to `MMENewMilkMaid`, which already owns the mod's Milk Maid conversion adapters.

The action stages and equips one internal MME Lactacid dose. MME's own `MilkLactacidScr` remains authoritative for `AssignSlotMaid`, StorageUtil initialization, faction membership, Lactacid initialization, and the ten-second `ZaZAPCHorFd` reaction. No player inventory item is consumed.

## Compared implementations

- Original MME dialogue: equips Lactacid immediately. The native effect validates capacity, assigns the slot, initializes Lactacid, then starts its reaction animation.
- MME Extensions OStim variant: completes the paired OStim breastfeeding scene, then enters the same native Lactacid route.
- MME Extensions SexLab/direct breastfeeding variant: lets MME start its original breastfeeding animation, observes the owned scene through completion, then enters the same native Lactacid route.
- Skyrim.Net action: uses the original dialogue's direct route. It does not add an unrelated breastfeeding scene.

## Validation and failure behavior

Before staging an item, the action validates a distinct loaded adult female NPC; non-Milk-Maid and non-Milk-Slave state; the running MME quest; condition quest, registry, faction, potion, Lactacid effect, SexLab, and ZaZ dependencies; standing/non-combat/non-scene animation state; unrestricted arms; MME level capacity; and a physically free registry slot. Every rejection produces an in-game reason. Missing or internally inconsistent MME data also writes an error-only alarm.

MME's current active registration path uses `MilkQUEST.MilkMaid[]`; old alias references in the upstream source are commented out. Accordingly, the array is the validated registry dependency rather than a quest alias.

## Remaining compatibility assumptions

- The implementation targets the MME behavior represented by the bundled SDK and the inspected 2022 source. An MME fork that hides `MilkMaid[]` from external Papyrus will fail closed with a notification rather than attempting conversion.
- The native effect owns the actual animation and registration. Other mods can still interrupt that effect after commit. A missing assignment leaves no registered target; an assigned slot without Lactacid initialization is rolled back through MME's own `SingleMaidReset` cleanup and emits an alarm.
- Papyrus can verify that ZaZ is loaded but cannot query whether one specific animation-event string is present in the target's behavior graph. `ZaZAPCHorFd` is therefore trusted exactly as MME's own `MilkLactacidScr` trusts it.
- The YAML's static eligibility can only cheaply gate the conversational actor. All authoritative target and MME checks are repeated in Papyrus immediately before conversion.
- The action includes its own compact definition of a Milk Maid, so selection does not depend on probabilistic semantic-lore retrieval. The fuller shared lore remains token-efficient Skyrim.Net world knowledge.
