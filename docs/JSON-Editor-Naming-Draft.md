# JSON editor naming and classification draft

Superseded for player-facing presentation by [the complete player-facing draft](JSON-Editor-Player-Facing-Draft.md). This earlier inventory remains historical context; its recommendation to present all fields and use a usage dropdown is not the current proposal. The companion metadata draft now follows the player-facing proposal.

Documentation-only investigation, October 30, 2026. No runtime catalog, JSON flavor text, editor code, native DLL, installed files, or package changed. All 147 existing IDs are retained. Metadata suggestions are source-derived, not new runtime acceptance.

## Recommendation

Use two independent filters: Used by (All / Game messages only / Skyrim.Net only / Shared) and Feature. Also show a text-purpose badge: HUD notification, story popup, AI reaction instructions, AI context/lore, or AI prompt fragment. Do not collapse all AI text into spoken narration. Keep Shared explicit rather than calling it non-AI.

Card order: proposed title, usage badge, one-sentence description, shared/fallback warning, editable values, required-token explanations. Keep internal ID/path under Advanced details; preserve them for saved overrides. Broad feature groups can later merge ArmorIntroductionStories into Armor and NonMilkmaidDrinkNotifications into Milk Drinking/Breastfeeding without moving JSON or changing IDs.

## Findings and caution points

- Current labels are mechanically derived from route keys; numbered suffixes hide important distinctions such as ordinary vs restrained or first equip vs re-equip.
- Current family metadata puts tier AI narration into Stories, thoughts & notifications. It is not a reliable usage filter.
- Thoughts, craving-start feedback, conversion feedback, and drink reactions can feed both HUD and AI. Changing these can alter both experiences when the relevant settings are enabled.
- Injection/Dwemer effect HUD wording is separate from their AI narration pools; sharing one gameplay trigger does not make their text shared.
- Untiered Living/Parasite entries are parents for inherited tier wording, not duplicate dead controls.
- Dwemer core profile text is reused across events. Prompt wrappers, factual guards, status summaries, lore and fallbacks should explain their roles instead of presenting themselves as standalone dialogue.
- NonMilkmaidDrinkNotifications is an implementation filename, not an accurate user-facing restriction. The shared breastfeeding completion renderer forwards its HUD reaction to player/NPC AI narration, except on conversion routes that reserve their own narration (MMEDebug.psc around lines 1264-1284).
- Armor-service reminder edits may be replaced by compact wording when their combined HUD line exceeds the length guard.

## Metadata fields

The companion JSON records every current/proposed title, feature, usedBy, textPurpose, description, shared/fallback behavior, token contract, source JSON/path, source readers, and evidence status. It is a draft, not a replacement runtime schema. sourceReaders lists relevant consumer files, not proof that every path in that file consumes every entry.

Token help should describe tokens in their route: actor = affected character; armorName = armor name; role = breastfeeding participant role; reaction/thought/craving/conversion/content/situation = text assembled by the caller; statuses = assembled nearby-character summary; milkName/item = drink name; chestKind/chest_kind = chest kind; outcome = factual curse result; tag = event tag. Preserve each exact token and its current validation contract. Do not rewrite uppercase aliases globally.

## Proposed entry names

| Existing ID | Proposed display title | Used by | Purpose |
| --- | --- | --- | --- |
| `Armor.narrate_armor_equip_1` | Milking Armor — Equip Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Armor.narrate_armor_equip_2` | Living Armor — Equip Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Armor.narrate_armor_equip_3` | Parasite Armor — Equip Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Armor.narrate_armor_equip_4` | Trapped Armor — Surprise Equip Prompt Fragment | Skyrim.Net only | AI prompt fragment / wrapper |
| `Armor.narrate_armor_strip_1` | Armor Stripping — Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Armor.build_nearby_armor_status_1` | Milking Armor — Nearby Wearer Context | Skyrim.Net only | AI event or character context |
| `Armor.build_nearby_armor_status_2` | Living Armor — Nearby Wearer Context | Skyrim.Net only | AI event or character context |
| `Armor.build_nearby_armor_status_3` | Parasite Armor — Nearby Wearer Context | Skyrim.Net only | AI event or character context |
| `Breastfeeding.guidance` | Breastfeeding — AI Scene and Participant Guidance | Skyrim.Net only | AI reaction instructions |
| `Common.player_instructions` | Player Speech — Private Self-Comment Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.narrate_dwemer_effect_1` | Dwemer Effects — Wearer-Perspective Prompt Fragment | Skyrim.Net only | AI prompt fragment / wrapper |
| `DwemerArmor.build_dwemer_suit_prompt_1` | Dwemer Wearer — AI Prompt Assembly Wrapper | Skyrim.Net only | AI prompt fragment / wrapper |
| `DwemerArmor.get_dwemer_profile_fallback_1` | Dwemer Devious Suit — Fallback Profile Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.get_dwemer_profile_fallback_2` | Dwemer Hidden Attachment — Fallback Profile Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.get_dwemer_event_fallback_1` | Dwemer First Equip — Fallback Event Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.get_dwemer_event_fallback_2` | Dwemer Re-equip — Fallback Event Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.get_dwemer_event_fallback_3` | Dwemer Milking Started — Fallback Event Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.get_dwemer_event_fallback_4` | Dwemer Milking Finished — Fallback Event Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.get_dwemer_event_fallback_5` | Dwemer Unrecognized Event — Fallback Event Context | Skyrim.Net only | AI fallback text |
| `DwemerArmor.build_dwemer_effect_narration_1` | Dwemer Effects — AI Situation Wrapper | Skyrim.Net only | AI prompt fragment / wrapper |
| `DwemerArmor.effects_arousal` | Dwemer Effects — Arousal Increase AI Narration Pool | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.effects_milk` | Dwemer Effects — Milk Increase AI Narration Pool | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.effects_milkAndArousal` | Dwemer Effects — Milk + Arousal Increase AI Narration Pool | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.suit_core` | Dwemer Devious Suit — Shared AI Profile Context | Skyrim.Net only | AI event or character context |
| `DwemerArmor.suit_firstEquip` | Dwemer Devious Suit — First Equip Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.suit_reequip` | Dwemer Devious Suit — Re-equip Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.suit_milkingStart` | Dwemer Devious Suit — Milking Started Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.suit_milkingEnd` | Dwemer Devious Suit — Milking Finished Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.attachment_core` | Dwemer Hidden Attachment — Shared AI Profile Context | Skyrim.Net only | AI event or character context |
| `DwemerArmor.attachment_firstEquip` | Dwemer Hidden Attachment — First Equip Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.attachment_reequip` | Dwemer Hidden Attachment — Re-equip Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.attachment_milkingStart` | Dwemer Hidden Attachment — Milking Started Instructions | Skyrim.Net only | AI reaction instructions |
| `DwemerArmor.attachment_milkingEnd` | Dwemer Hidden Attachment — Milking Finished Instructions | Skyrim.Net only | AI reaction instructions |
| `Fullness.send_capacity_milestone_1` | Half Full — AI Milestone Event Context | Skyrim.Net only | AI event or character context |
| `Fullness.send_capacity_milestone_2` | Completely Full — AI Milestone Event Context | Skyrim.Net only | AI event or character context |
| `Fullness.narrate_milk_full_1` | Completely Full — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Fullness.narrate_milk_half_full_1` | Half Full — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Fullness.build_restrained_capacity_content_1` | Restrained and Completely Full — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Fullness.build_restrained_capacity_content_2` | Restrained and Half Full — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Fullness.build_milk_status_1` | Restrained and Completely Full — Character Status Context | Skyrim.Net only | AI event or character context |
| `Fullness.build_milk_status_2` | Restrained and Above Half Full — Character Status Context | Skyrim.Net only | AI event or character context |
| `Fullness.build_milk_status_3` | Restrained and Below Half Full — Character Status Context | Skyrim.Net only | AI event or character context |
| `Fullness.build_milk_status_4` | Completely Full — Character Status Context | Skyrim.Net only | AI event or character context |
| `Fullness.build_milk_status_5` | Above Half Full — Character Status Context | Skyrim.Net only | AI event or character context |
| `Fullness.build_milk_status_6` | Below Half Full — Character Status Context | Skyrim.Net only | AI event or character context |
| `Fullness.nearby_status_summary` | Nearby Milk Maids — AI Milk-Level Summary Wrapper | Skyrim.Net only | AI prompt fragment / wrapper |
| `Lore.milk_lore` | World Lore — Milk and Milking Armor | Skyrim.Net only | AI background lore |
| `Lore.milkmaid_lore` | Character Lore — Being a Milk Maid | Skyrim.Net only | AI background lore |
| `MilkCravings.narrate_milk_craving_1` | Milk Craving — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_chest_milk_drink_1` | Chest Trap Milk Drink — Event Description | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_chest_milk_drink_2` | Chest Trap Milk Drink — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_n_p_c_milk_drink_1` | NPC Milk Drink — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_n_p_c_milk_drink_2` | NPC Milk Drink — Restrained-Arms Prompt Fragment | Skyrim.Net only | AI prompt fragment / wrapper |
| `MilkDrinking.narrate_n_p_c_milk_drink_3` | NPC Milk Drink — Non-Milk-Maid Factual Guard | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_n_p_c_milk_drink_4` | NPC Milk Drink — Established Milk Maid Factual Guard | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_player_milk_drink_1` | Player Milk Drink — Basic AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_player_milk_drink_2` | Player Milk Drink — Outcome-Based AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.narrate_player_milk_drink_3` | Player Milk Drink — Restrained-Arms Prompt Fragment | Skyrim.Net only | AI prompt fragment / wrapper |
| `MilkDrinking.build_restrained_player_drink_content_1` | Restrained Player Milk Drink — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkDrinking.drinkMessage` | Milk Drink — AI Event Context | Skyrim.Net only | AI event or character context |
| `Milking.startMessage` | Milking Started — AI Event Context | Skyrim.Net only | AI event or character context |
| `Milking.endMessage` | Milking Finished — AI Event Context | Skyrim.Net only | AI event or character context |
| `MilkMaidCreation.narrate_milkmaid_created_1` | New Milk Maid — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkMaidCreation.narrate_forced_milk_maid_conversion_1` | Forced Milk Maid Conversion — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkMaidCreation.milkmaidCreatedMessage` | New Milk Maid — AI Event Context | Skyrim.Net only | AI event or character context |
| `MilkMaidCreation.narrate_milk_maid_curse_1` | Existing Milk Maid Curse — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `MilkMaidCreation.narrate_chest_milk_maid_curse_1` | Chest Milk Maid Curse — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `TentacleArmor.narrate_tentacle_effect_1` | Living / Parasite Effects — Wearer-Perspective Prompt Fragment | Skyrim.Net only | AI prompt fragment / wrapper |
| `TentacleArmor.build_tentacle_effect_narration_1` | Living / Parasite Effects — AI Situation Wrapper | Skyrim.Net only | AI prompt fragment / wrapper |
| `TentacleArmor.effects_arousal` | Living / Parasite Effects — Arousal Increase AI Narration Pool / Tier Fallback | Skyrim.Net only | AI fallback text |
| `TentacleArmor.effects_milk` | Living / Parasite Effects — Milk Increase AI Narration Pool / Tier Fallback | Skyrim.Net only | AI fallback text |
| `TentacleArmor.effects_milkAndArousal` | Living / Parasite Effects — Milk + Arousal Increase AI Narration Pool / Tier Fallback | Skyrim.Net only | AI fallback text |
| `Thoughts.narrate_milk_maid_thought_1` | Milk Maid Thoughts — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Thoughts.narrate_bound_milk_maid_thought_1` | Restrained Milk Maid Thoughts — AI Reaction Instructions | Skyrim.Net only | AI reaction instructions |
| `Pools.Thoughts.belowHalf_noArmor` | Milk Maid Thought — Below Half Full, No Supported Milking Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.belowHalf_milkingArmor` | Milk Maid Thought — Below Half Full, Milking Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.belowHalf_parasiteArmor` | Milk Maid Thought — Below Half Full, Parasite Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.belowHalf_livingArmor` | Milk Maid Thought — Below Half Full, Living Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.halfPlus_noArmor` | Milk Maid Thought — Half Full or Above, No Supported Milking Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.armsBound` | Milk Maid Thought — Restrained Arms | Shared | HUD thought + AI input |
| `Pools.Thoughts.halfPlus_milkingArmor` | Milk Maid Thought — Half Full or Above, Milking Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.halfPlus_parasiteArmor` | Milk Maid Thought — Half Full or Above, Parasite Armor | Shared | HUD thought + AI input |
| `Pools.Thoughts.halfPlus_livingArmor` | Milk Maid Thought — Half Full or Above, Living Armor | Shared | HUD thought + AI input |
| `Pools.MilkCravings.craving` | Milk Craving — Craving Begins: Message + AI Input | Shared | HUD notification variants |
| `Pools.MilkCravings.give_in` | Milk Craving — Giving In: Game Message | Game messages only | HUD notification variants |
| `Pools.ArmorIntroductionStories.milking_first_equip` | Milking Armor — First Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.living_first_equip` | Living Armor — First Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.parasite_first_equip` | Parasite Armor — First Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.dwemer_first_equip` | Dwemer Armor — First Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.living_trap_equip` | Living Armor — Chest Trap Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.parasite_trap_equip` | Parasite Armor — Chest Trap Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.dwemer_trap_equip` | Dwemer Armor — Chest Trap Equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.milking_repeat_equip` | Milking Armor — Re-equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.living_repeat_equip` | Living Armor — Re-equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.parasite_repeat_equip` | Parasite Armor — Re-equip Story | Game messages only | Story popup variants |
| `Pools.ArmorIntroductionStories.dwemer_repeat_equip` | Dwemer Armor — Re-equip Story | Game messages only | Story popup variants |
| `Pools.DwemerArmorStories.dwemerarmorstart` | Dwemer Armor — Milking Started Story Popup | Game messages only | Story popup variants |
| `Pools.DwemerArmorStories.dwemerarmorend` | Dwemer Armor — Milking Finished Story Popup | Game messages only | Story popup variants |
| `Pools.ForcedMilkMaidConversion.conversionMessages` | Milk Maid Conversion — Shared Feedback | Shared | HUD feedback + AI input |
| `Pools.ForcedMilkMaidConversion.chestCurseStories` | Milk Maid Curse — Story Popup | Game messages only | Story popup variants |
| `Pools.ArmorCheckReminders.notice_none` | Armor Service Reminder — No Armor | Game messages only | HUD notification variants |
| `Pools.ArmorCheckReminders.notice_regular` | Armor Service Reminder — Ordinary Armor | Game messages only | HUD notification variants |
| `Pools.ArmorCheckReminders.notice_milking` | Armor Service Reminder — Milking Armor | Game messages only | HUD notification variants |
| `Pools.ArmorCheckReminders.notice_living` | Armor Service Reminder — Living Armor | Game messages only | HUD notification variants |
| `Pools.ArmorCheckReminders.notice_parasite` | Armor Service Reminder — Parasite Armor | Game messages only | HUD notification variants |
| `Pools.ArmorCheckReminders.notice_dwemer` | Armor Service Reminder — Dwemer Armor | Game messages only | HUD notification variants |
| `Pools.ArmorCheckReminders.notice_reaction` | Armor Service Reminder — Vendor Reaction Ending | Game messages only | HUD notification variants |
| `Pools.ArousalEffects.low_female` | Arousal Reaction — Low, Female: Notification | Game messages only | HUD notification variants |
| `Pools.ArousalEffects.low_male` | Arousal Reaction — Low, Male: Notification | Game messages only | HUD notification variants |
| `Pools.ArousalEffects.medium_female` | Arousal Reaction — Medium, Female: Notification | Game messages only | HUD notification variants |
| `Pools.ArousalEffects.medium_male` | Arousal Reaction — Medium, Male: Notification | Game messages only | HUD notification variants |
| `Pools.ArousalEffects.high_female` | Arousal Reaction — High, Female: Notification | Game messages only | HUD notification variants |
| `Pools.ArousalEffects.high_male` | Arousal Reaction — High, Male: Notification | Game messages only | HUD notification variants |
| `Pools.BreastBounceNotifications.low` | Breast Movement — Low Bounce Notification | Game messages only | HUD notification variants |
| `Pools.BreastBounceNotifications.high` | Breast Movement — High Bounce Notification | Game messages only | HUD notification variants |
| `Pools.BreastBounceNotifications.movement` | Breast Movement — Movement Slap Notification | Game messages only | HUD notification variants |
| `Pools.DwemerEffectNotifications.lines` | Dwemer Armor — Periodic Effect Notification | Game messages only | HUD notification variants |
| `Pools.Injection.lines` | Living / Parasite — Default Tease Notification | Game messages only | HUD notification variants |
| `Pools.NonMilkmaidDrinkNotifications.male_generic` | Milk Drink — Male, No Confirmed Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.female_generic` | Milk Drink — Female, No Confirmed Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.male_aroused` | Milk Drink — Male, Arousal Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.female_aroused` | Milk Drink — Female, Arousal Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.female_milk` | Milk Drink — Female, Milk Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.female_milk_arousal` | Milk Drink — Female, Milk + Arousal Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.breastfeeding_male_generic` | Breastfeeding — Male, No Confirmed Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.breastfeeding_male_aroused` | Breastfeeding — Male, Arousal Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_generic` | Breastfeeding — Female, No Confirmed Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_aroused` | Breastfeeding — Female, Arousal Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_milk` | Breastfeeding — Female, Milk Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_milk_arousal` | Breastfeeding — Female, Milk + Arousal Increase Reaction | Shared | Reaction wording / HUD and AI input |
| `Pools.TimedArmorNotifications.unequip_resisted` | Timed Armor Lock — Removal Attempt Resisted | Game messages only | HUD notification variants |
| `Pools.Injection.tiers.low.lines` | Living / Parasite — Low Tease Notification | Game messages only | HUD notification variants |
| `Pools.TentacleEffectNarration.tiers.low.milk` | Living / Parasite — Low Tease: Milk Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.low.arousal` | Living / Parasite — Low Tease: Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.low.milkAndArousal` | Living / Parasite — Low Tease: Milk + Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.Injection.tiers.medium.lines` | Living / Parasite — Medium Tease Notification | Game messages only | HUD notification variants |
| `Pools.TentacleEffectNarration.tiers.medium.milk` | Living / Parasite — Medium Tease: Milk Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.medium.arousal` | Living / Parasite — Medium Tease: Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.medium.milkAndArousal` | Living / Parasite — Medium Tease: Milk + Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.Injection.tiers.high.lines` | Living / Parasite — High Tease Notification | Game messages only | HUD notification variants |
| `Pools.TentacleEffectNarration.tiers.high.milk` | Living / Parasite — High Tease: Milk Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.high.arousal` | Living / Parasite — High Tease: Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.high.milkAndArousal` | Living / Parasite — High Tease: Milk + Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.Injection.tiers.extreme.lines` | Living / Parasite — Extreme Tease Notification | Game messages only | HUD notification variants |
| `Pools.TentacleEffectNarration.tiers.extreme.milk` | Living / Parasite — Extreme Tease: Milk Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.extreme.arousal` | Living / Parasite — Extreme Tease: Arousal Increase Narration | Skyrim.Net only | AI narration variants |
| `Pools.TentacleEffectNarration.tiers.extreme.milkAndArousal` | Living / Parasite — Extreme Tease: Milk + Arousal Increase Narration | Skyrim.Net only | AI narration variants |

## Next implementation boundary

Before implementing, review the proposed titles and route-level descriptions for status/fallback availability. Then place approved metadata in the authored catalog generation input, regenerate the catalog and compiled defaults as required, and expose descriptions/badges plus the usage filter through the existing catalog RPC and dashboard. Do not infer classifications from filenames, duplicate shared entries, move saved keys, change text, or touch gameplay. Preserve drafts through filtering and existing save/reset/inheritance behavior. Validate all 147 IDs, shared-channel cases, token contracts, searches, filters, long descriptions, and the package source/compiled pairs. No build or deployment is needed for reviewing this draft.


## Draft coverage check

All 147 catalog IDs have exactly one proposed title, description, usage class, purpose, token contract and source path. Proposed usage counts: 86 Skyrim.Net only, 38 game messages only, 23 shared. These are entry counts, not individual variant counts. Breastfeeding classification was resolved through the common completion renderer. No gameplay, editor or packaging execution was performed for this documentation task.
