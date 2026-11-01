# Complete player-facing JSON editor draft

Draft for review, October 30, 2026. Primary goal: customize Skyrim.Net reactions and lore. Game messages and story popups are extras. This replaces the earlier all-fields presentation proposal. No editor, runtime catalog, flavor text, scripts, DLL, package or installed files changed.

## Navigation

Default section: **Skyrim.Net Reactions & Lore**. Second section: **Game Messages & Stories**. These sections sit inside the existing JSON editor; retain the separate Milk Maids roster and its navigation. Reuse search, a Feature dropdown, Modified Only, save/reload/reset and presets. Show only feature groups with visible entries in the current section. Do not add another usage dropdown.

Shared messages appear once under Game Messages & Stories with **Also used by Skyrim.Net**. The first section provides a navigation hint: “Looking for the exact thought or message? Open Game Messages & Stories.” Do not duplicate editable values in both sections.

Intro: “Customize Skyrim.Net’s reactions, lore and speaking style. Reaction prompts guide generated dialogue; they are not necessarily spoken word for word. These edits change wording, not gameplay.”

Card layout: plain title, purpose badge, description, sharing/inheritance note, editable variants, required-placeholder explanations, and existing Personal / Base / Inherited / Unsaved status. Advanced details may show the internal ID and path; they do not expose internal plumbing as new creative controls.

Shared badge help: “This message can also describe the situation to Skyrim.Net. Editing it may change both the on-screen message and the AI reaction when narration is enabled.”

Inheritance help: “Uses the existing default until customized. Reset returns to that default, including an older personal edit to the parent entry.”

## Complete visible entry list

## Skyrim.Net Reactions & Lore

### Armor

**Putting On Milking Armor** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Putting On Milking Armor. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Armor.narrate_armor_equip_1`

**Putting On Living Armor** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Putting On Living Armor. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Armor.narrate_armor_equip_2`

**Putting On Parasite Armor** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Putting On Parasite Armor. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Armor.narrate_armor_equip_3`

**When Her Armor Pops Off** · Reaction Prompt

Customize the wording Skyrim.Net receives for: When Her Armor Pops Off. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{armorName}`.

Source ID: `Armor.narrate_armor_strip_1`

### Breastfeeding

**How Characters React During Breastfeeding** · Reaction Prompt

Customize the wording Skyrim.Net receives for: How Characters React During Breastfeeding. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{role}`.

Source ID: `Breastfeeding.guidance`

### Speaking Style

**Your Character’s Speaking Style** · Speaking Style

Guide how your character speaks about her own experiences. Shared across several private player reactions, not a general NPC voice setting.

Shared writing instructions for private player self-comments; changes can affect several features.

Required placeholders: `{actor}`.

Source ID: `Common.player_instructions`

### Dwemer Armor

**Dwemer Armor Effects — More Arousal** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Armor Effects — More Arousal. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `DwemerArmor.effects_arousal`

**Dwemer Armor Effects — More Milk** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Armor Effects — More Milk. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `DwemerArmor.effects_milk`

**Dwemer Armor Effects — More Milk and Arousal** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Armor Effects — More Milk and Arousal. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `DwemerArmor.effects_milkAndArousal`

**Dwemer Suit — How It Works** · Background Lore

Customize the background description Skyrim.Net uses for Dwemer Suit — How It Works. This influences how it describes the subject; it does not change gameplay.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.suit_core`

**Dwemer Suit — First Time Wearing It** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Suit — First Time Wearing It. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.suit_firstEquip`

**Dwemer Suit — Wearing It Again** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Suit — Wearing It Again. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.suit_reequip`

**Dwemer Suit — Milking Begins** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Suit — Milking Begins. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.suit_milkingStart`

**Dwemer Suit — Milking Finishes** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Dwemer Suit — Milking Finishes. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.suit_milkingEnd`

**Hidden Dwemer Attachment — How It Works** · Background Lore

Customize the background description Skyrim.Net uses for Hidden Dwemer Attachment — How It Works. This influences how it describes the subject; it does not change gameplay.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.attachment_core`

**Hidden Dwemer Attachment — First Time Wearing It** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Hidden Dwemer Attachment — First Time Wearing It. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.attachment_firstEquip`

**Hidden Dwemer Attachment — Wearing It Again** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Hidden Dwemer Attachment — Wearing It Again. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.attachment_reequip`

**Hidden Dwemer Attachment — Milking Begins** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Hidden Dwemer Attachment — Milking Begins. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.attachment_milkingStart`

**Hidden Dwemer Attachment — Milking Finishes** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Hidden Dwemer Attachment — Milking Finishes. This guides the generated reaction rather than guaranteeing an exact spoken line.

The matching How It Works description is combined with each event prompt. Editing that background affects first equip, wearing it again, milking start and milking end for this profile.

Required placeholders: None.

Source ID: `DwemerArmor.attachment_milkingEnd`

### Fullness

**When Her Breasts Become Full** · Reaction Prompt

Customize the wording Skyrim.Net receives for: When Her Breasts Become Full. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Fullness.narrate_milk_full_1`

**When Her Breasts Become Half Full** · Reaction Prompt

Customize the wording Skyrim.Net receives for: When Her Breasts Become Half Full. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Fullness.narrate_milk_half_full_1`

**Full Breasts with Restrained Arms** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Full Breasts with Restrained Arms. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Fullness.build_restrained_capacity_content_1`

**Half-Full Breasts with Restrained Arms** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Half-Full Breasts with Restrained Arms. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Fullness.build_restrained_capacity_content_2`

### Lore

**Milk and Milking Armor Lore** · Background Lore

Customize the background description Skyrim.Net uses for Milk and Milking Armor Lore. This influences how it describes the subject; it does not change gameplay.

Required placeholders: None.

Source ID: `Lore.milk_lore`

**What It Means to Be a Milk Maid** · Background Lore

Customize the background description Skyrim.Net uses for What It Means to Be a Milk Maid. This influences how it describes the subject; it does not change gameplay.

Required placeholders: `{actor}`.

Source ID: `Lore.milkmaid_lore`

### Thoughts & Cravings

**Craving Milk** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Craving Milk. This guides the generated reaction rather than guaranteeing an exact spoken line. The selected thought/craving message is edited separately under Game Messages & Stories.

Required placeholders: `{actor}`, `{craving}`.

Source ID: `MilkCravings.narrate_milk_craving_1`

**A Milk Maid Shares Her Thoughts** · Reaction Prompt

Customize the wording Skyrim.Net receives for: A Milk Maid Shares Her Thoughts. This guides the generated reaction rather than guaranteeing an exact spoken line. The selected thought/craving message is edited separately under Game Messages & Stories.

Required placeholders: `{actor}`, `{thought}`.

Source ID: `Thoughts.narrate_milk_maid_thought_1`

**A Restrained Milk Maid Shares Her Thoughts** · Reaction Prompt

Customize the wording Skyrim.Net receives for: A Restrained Milk Maid Shares Her Thoughts. This guides the generated reaction rather than guaranteeing an exact spoken line. The selected thought/craving message is edited separately under Game Messages & Stories.

Required placeholders: `{actor}`, `{thought}`.

Source ID: `Thoughts.narrate_bound_milk_maid_thought_1`

### Milk Drinking

**Drinking Milk from a Trapped Chest** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Drinking Milk from a Trapped Chest. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{situation}`.

Source ID: `MilkDrinking.narrate_chest_milk_drink_2`

**An NPC Drinks Milk** · Reaction Prompt

Customize the wording Skyrim.Net receives for: An NPC Drinks Milk. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{reaction}`.

Source ID: `MilkDrinking.narrate_n_p_c_milk_drink_1`

**Your Character Drinks Milk — Basic Reaction** · Reaction Prompt

Guide the player’s drink reaction when no detailed rendered outcome was supplied. The Detailed Reaction entry covers the alternative path.

Required placeholders: `{milkName}`.

Source ID: `MilkDrinking.narrate_player_milk_drink_1`

**Your Character Drinks Milk — Detailed Reaction** · Reaction Prompt

Guide the player’s drink reaction when the caller supplies a detailed outcome. The Basic Reaction entry covers the alternative path.

Required placeholders: `{reaction}`.

Source ID: `MilkDrinking.narrate_player_milk_drink_2`

**Your Character Drinks Milk with Restrained Arms** · Reaction Prompt

Customize the wording Skyrim.Net receives for: Your Character Drinks Milk with Restrained Arms. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{milkName}`.

Source ID: `MilkDrinking.build_restrained_player_drink_content_1`

### Milking

**When Milking Begins** · Reaction Prompt

Customize the event description supplied to Skyrim.Net when milking begins. It describes the situation; it does not change milk amounts or force an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Milking.startMessage`

**When Milking Finishes** · Reaction Prompt

Customize the event description supplied to Skyrim.Net when milking finishes. It describes the situation; it does not change milk amounts or force an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `Milking.endMessage`

### Becoming a Milk Maid

**After Becoming a Milk Maid** · Reaction Prompt

Customize the wording Skyrim.Net receives for: After Becoming a Milk Maid. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`.

Source ID: `MilkMaidCreation.narrate_milkmaid_created_1`

**After a Magical Milk Maid Transformation** · Reaction Prompt

Customize the wording Skyrim.Net receives for: After a Magical Milk Maid Transformation. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{conversion}`.

Source ID: `MilkMaidCreation.narrate_forced_milk_maid_conversion_1`

**A Milk Curse Strikes an Existing Milk Maid** · Reaction Prompt

Customize the wording Skyrim.Net receives for: A Milk Curse Strikes an Existing Milk Maid. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{conversion}`.

Source ID: `MilkMaidCreation.narrate_milk_maid_curse_1`

**A Milk Maid Curse Escapes a Chest** · Reaction Prompt

Customize the wording Skyrim.Net receives for: A Milk Maid Curse Escapes a Chest. This guides the generated reaction rather than guaranteeing an exact spoken line.

Required placeholders: `{actor}`, `{outcome}`, `{chest_kind}`, `{milk_added}`.

Source ID: `MilkMaidCreation.narrate_chest_milk_maid_curse_1`

### Living / Parasite Teasing

**Living / Parasite Tease — Low: More Milk** · Reaction Prompt

Customize the wearer’s reaction after a low tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.low.milk`

**Living / Parasite Tease — Low: More Arousal** · Reaction Prompt

Customize the wearer’s reaction after a low tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.low.arousal`

**Living / Parasite Tease — Low: More Milk and Arousal** · Reaction Prompt

Customize the wearer’s reaction after a low tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.low.milkAndArousal`

**Living / Parasite Tease — Medium: More Milk** · Reaction Prompt

Customize the wearer’s reaction after a medium tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.medium.milk`

**Living / Parasite Tease — Medium: More Arousal** · Reaction Prompt

Customize the wearer’s reaction after a medium tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.medium.arousal`

**Living / Parasite Tease — Medium: More Milk and Arousal** · Reaction Prompt

Customize the wearer’s reaction after a medium tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.medium.milkAndArousal`

**Living / Parasite Tease — High: More Milk** · Reaction Prompt

Customize the wearer’s reaction after a high tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.high.milk`

**Living / Parasite Tease — High: More Arousal** · Reaction Prompt

Customize the wearer’s reaction after a high tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.high.arousal`

**Living / Parasite Tease — High: More Milk and Arousal** · Reaction Prompt

Customize the wearer’s reaction after a high tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.high.milkAndArousal`

**Living / Parasite Tease — Extreme: More Milk** · Reaction Prompt

Customize the wearer’s reaction after a extreme tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.extreme.milk`

**Living / Parasite Tease — Extreme: More Arousal** · Reaction Prompt

Customize the wearer’s reaction after a extreme tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.extreme.arousal`

**Living / Parasite Tease — Extreme: More Milk and Arousal** · Reaction Prompt

Customize the wearer’s reaction after a extreme tease with this confirmed outcome. Tease selection and milk/arousal changes remain controlled by gameplay.

Uses the matching untiered narration default until customized. Reset returns to inheritance, including any existing personal edit to that parent.

Required placeholders: `{actor}`.

Source ID: `Pools.TentacleEffectNarration.tiers.extreme.milkAndArousal`

## Game Messages & Stories

### Thoughts & Cravings

**Milk Maid Thought — Less Than Half Full, Without Milking Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.belowHalf_noArmor`

**Milk Maid Thought — Less Than Half Full, Milking Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.belowHalf_milkingArmor`

**Milk Maid Thought — Less Than Half Full, Parasite Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.belowHalf_parasiteArmor`

**Milk Maid Thought — Less Than Half Full, Living Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.belowHalf_livingArmor`

**Milk Maid Thought — At Least Half Full, Without Milking Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.halfPlus_noArmor`

**Milk Maid Thought — Restrained Arms** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.armsBound`

**Milk Maid Thought — At Least Half Full, Milking Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.halfPlus_milkingArmor`

**Milk Maid Thought — At Least Half Full, Parasite Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.halfPlus_parasiteArmor`

**Milk Maid Thought — At Least Half Full, Living Armor** · Also used by Skyrim.Net

Selected thought is displayed as a game message and can be included in Skyrim.Net reaction instructions.

Required placeholders: `{actor}`.

Source ID: `Pools.Thoughts.halfPlus_livingArmor`

**When She Craves Milk — Message** · Also used by Skyrim.Net

Wording when a periodic craving begins; also passed to AI narration.

Required placeholders: `{ActorName}`.

Source ID: `Pools.MilkCravings.craving`

**Giving In to a Milk Craving — Message** · On-Screen Message

Game notification when a character gives in to the craving; distinct from the later drink reaction.

Required placeholders: `{ActorName}`.

Source ID: `Pools.MilkCravings.give_in`

### Armor

**Milking Armor — First Time Wearing It Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.milking_first_equip`

**Living Armor — First Time Wearing It Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: None.

Source ID: `Pools.ArmorIntroductionStories.living_first_equip`

**Parasite Armor — First Time Wearing It Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: None.

Source ID: `Pools.ArmorIntroductionStories.parasite_first_equip`

**Dwemer Armor — First Time Wearing It Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: None.

Source ID: `Pools.ArmorIntroductionStories.dwemer_first_equip`

**Living Armor — Caught by a Chest Trap Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.living_trap_equip`

**Parasite Armor — Caught by a Chest Trap Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.parasite_trap_equip`

**Dwemer Armor — Caught by a Chest Trap Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.dwemer_trap_equip`

**Milking Armor — Wearing It Again Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.milking_repeat_equip`

**Living Armor — Wearing It Again Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.living_repeat_equip`

**Parasite Armor — Wearing It Again Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.parasite_repeat_equip`

**Dwemer Armor — Wearing It Again Story** · Story Popup

Random story popup for this armor family and equip route; AI equip narration has separate entries.

Required placeholders: `{ActorName}`.

Source ID: `Pools.ArmorIntroductionStories.dwemer_repeat_equip`

### Dwemer Armor

**Dwemer Armor — Milking Started Story Popup** · Story Popup

Game story popup at the corresponding Dwemer milking boundary; separate from AI suit/attachment prompts.

Required placeholders: None.

Source ID: `Pools.DwemerArmorStories.dwemerarmorstart`

**Dwemer Armor — Milking Finished Story Popup** · Story Popup

Game story popup at the corresponding Dwemer milking boundary; separate from AI suit/attachment prompts.

Required placeholders: None.

Source ID: `Pools.DwemerArmorStories.dwemerarmorend`

**Dwemer Armor — Periodic Effect Message** · On-Screen Message

HUD flavor after a successful armor effect. AI narration uses separate text pools.

Required placeholders: `{actor}`.

Source ID: `Pools.DwemerEffectNotifications.lines`

### Becoming a Milk Maid

**A Magical Transformation — Message** · Also used by Skyrim.Net

Conversion feedback used in HUD and some AI conversion/curse routes.

Required placeholders: `{actor}`.

Source ID: `Pools.ForcedMilkMaidConversion.conversionMessages`

**A Milk Maid Curse — Story Popup** · Story Popup

Story popup used by the curse route; the internal chestCurseStories name does not mean every caller is exclusively a chest event.

Required placeholders: `{actor}`.

Source ID: `Pools.ForcedMilkMaidConversion.chestCurseStories`

### Armor Service Reminders

**Armor Service Reminder — No Armor** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_none`

**Armor Service Reminder — Ordinary Armor** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_regular`

**Armor Service Reminder — Milking Armor** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_milking`

**Armor Service Reminder — Living Armor** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_living`

**Armor Service Reminder — Parasite Armor** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_parasite`

**Armor Service Reminder — Dwemer Armor** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_dwemer`

**Armor Service Reminder — Vendor Reaction Ending** · On-Screen Message

Vendor observation or reaction ending combined into a HUD reminder during an eligible armor-service interaction.

Long combined reminders are replaced by compact code-owned wording; a longer edit may not appear verbatim.

Required placeholders: None.

Source ID: `Pools.ArmorCheckReminders.notice_reaction`

### Arousal

**Arousal Reaction — Low, Female: Message** · On-Screen Message

HUD flavor for an arousal-reaction tier and character sex. This is not a Living/Parasite tease probability or AI prompt.

Required placeholders: `{actor}`.

Source ID: `Pools.ArousalEffects.low_female`

**Arousal Reaction — Low, Male: Message** · On-Screen Message

HUD flavor for an arousal-reaction tier and character sex. This is not a Living/Parasite tease probability or AI prompt.

Required placeholders: `{actor}`.

Source ID: `Pools.ArousalEffects.low_male`

**Arousal Reaction — Medium, Female: Message** · On-Screen Message

HUD flavor for an arousal-reaction tier and character sex. This is not a Living/Parasite tease probability or AI prompt.

Required placeholders: `{actor}`.

Source ID: `Pools.ArousalEffects.medium_female`

**Arousal Reaction — Medium, Male: Message** · On-Screen Message

HUD flavor for an arousal-reaction tier and character sex. This is not a Living/Parasite tease probability or AI prompt.

Required placeholders: `{actor}`.

Source ID: `Pools.ArousalEffects.medium_male`

**Arousal Reaction — High, Female: Message** · On-Screen Message

HUD flavor for an arousal-reaction tier and character sex. This is not a Living/Parasite tease probability or AI prompt.

Required placeholders: `{actor}`.

Source ID: `Pools.ArousalEffects.high_female`

**Arousal Reaction — High, Male: Message** · On-Screen Message

HUD flavor for an arousal-reaction tier and character sex. This is not a Living/Parasite tease probability or AI prompt.

Required placeholders: `{actor}`.

Source ID: `Pools.ArousalEffects.high_male`

### Breast Movement

**Breast Movement — Low Bounce Message** · On-Screen Message

HUD flavor for this bounce/movement reaction; does not select the sound or animation.

Required placeholders: `{actor}`.

Source ID: `Pools.BreastBounceNotifications.low`

**Breast Movement — High Bounce Message** · On-Screen Message

HUD flavor for this bounce/movement reaction; does not select the sound or animation.

Required placeholders: `{actor}`.

Source ID: `Pools.BreastBounceNotifications.high`

**Breast Movement — Movement Slap Message** · On-Screen Message

HUD flavor for this bounce/movement reaction; does not select the sound or animation.

Required placeholders: None.

Source ID: `Pools.BreastBounceNotifications.movement`

### Milk Drinking

**Milk Drink — Male, No Confirmed Milk or Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

The filename is misleading: shared readers also support established Milk Maids. Rendered drink reactions can be passed to player/NPC AI narration.

Required placeholders: `{actor}`, `{milk}`.

Source ID: `Pools.NonMilkmaidDrinkNotifications.male_generic`

**Milk Drink — Female, No Confirmed Milk or Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

The filename is misleading: shared readers also support established Milk Maids. Rendered drink reactions can be passed to player/NPC AI narration.

Required placeholders: `{actor}`, `{milk}`.

Source ID: `Pools.NonMilkmaidDrinkNotifications.female_generic`

**Milk Drink — Male, Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

The filename is misleading: shared readers also support established Milk Maids. Rendered drink reactions can be passed to player/NPC AI narration.

Required placeholders: `{actor}`, `{milk}`.

Source ID: `Pools.NonMilkmaidDrinkNotifications.male_aroused`

**Milk Drink — Female, Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

The filename is misleading: shared readers also support established Milk Maids. Rendered drink reactions can be passed to player/NPC AI narration.

Required placeholders: `{actor}`, `{milk}`.

Source ID: `Pools.NonMilkmaidDrinkNotifications.female_aroused`

**Milk Drink — Female, Milk Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

The filename is misleading: shared readers also support established Milk Maids. Rendered drink reactions can be passed to player/NPC AI narration.

Required placeholders: `{actor}`, `{milk}`.

Source ID: `Pools.NonMilkmaidDrinkNotifications.female_milk`

**Milk Drink — Female, Milk + Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

The filename is misleading: shared readers also support established Milk Maids. Rendered drink reactions can be passed to player/NPC AI narration.

Required placeholders: `{actor}`, `{milk}`.

Source ID: `Pools.NonMilkmaidDrinkNotifications.female_milk_arousal`

### Breastfeeding

**Breastfeeding — Male, No Confirmed Milk or Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

Shared completion renderer supports both framework backends. HUD reaction is forwarded to player/NPC drink narration except on conversion routes, which reserve their own narration. The filename does not restrict the reader to non-Milk-Maids.

Required placeholders: None.

Source ID: `Pools.NonMilkmaidDrinkNotifications.breastfeeding_male_generic`

**Breastfeeding — Male, Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

Shared completion renderer supports both framework backends. HUD reaction is forwarded to player/NPC drink narration except on conversion routes, which reserve their own narration. The filename does not restrict the reader to non-Milk-Maids.

Required placeholders: None.

Source ID: `Pools.NonMilkmaidDrinkNotifications.breastfeeding_male_aroused`

**Breastfeeding — Female, No Confirmed Milk or Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

Shared completion renderer supports both framework backends. HUD reaction is forwarded to player/NPC drink narration except on conversion routes, which reserve their own narration. The filename does not restrict the reader to non-Milk-Maids.

Required placeholders: None.

Source ID: `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_generic`

**Breastfeeding — Female, Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

Shared completion renderer supports both framework backends. HUD reaction is forwarded to player/NPC drink narration except on conversion routes, which reserve their own narration. The filename does not restrict the reader to non-Milk-Maids.

Required placeholders: None.

Source ID: `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_aroused`

**Breastfeeding — Female, Milk Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

Shared completion renderer supports both framework backends. HUD reaction is forwarded to player/NPC drink narration except on conversion routes, which reserve their own narration. The filename does not restrict the reader to non-Milk-Maids.

Required placeholders: None.

Source ID: `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_milk`

**Breastfeeding — Female, Milk + Arousal Increase Reaction** · Also used by Skyrim.Net

Outcome-based reaction selected for this route and sex; can be displayed as a game notification.

Shared completion renderer supports both framework backends. HUD reaction is forwarded to player/NPC drink narration except on conversion routes, which reserve their own narration. The filename does not restrict the reader to non-Milk-Maids.

Required placeholders: None.

Source ID: `Pools.NonMilkmaidDrinkNotifications.breastfeeding_female_milk_arousal`

### Armor Locks

**Timed Armor Lock — Removal Attempt Resisted** · On-Screen Message

HUD notification when removal is resisted while a timed armor lock is active.

Required placeholders: None.

Source ID: `Pools.TimedArmorNotifications.unequip_resisted`

### Living / Parasite Teasing

**Living / Parasite — Low Tease Message** · On-Screen Message

On-screen flavor message for a successful Low Living/Parasite effect.

Inherits the default tease message until customized. Reset returns to inheritance. AI narration has separate tier entries in the first tab.

Required placeholders: `{actor}`.

Source ID: `Pools.Injection.tiers.low.lines`

**Living / Parasite — Medium Tease Message** · On-Screen Message

On-screen flavor message for a successful Medium Living/Parasite effect.

Inherits the default tease message until customized. Reset returns to inheritance. AI narration has separate tier entries in the first tab.

Required placeholders: `{actor}`.

Source ID: `Pools.Injection.tiers.medium.lines`

**Living / Parasite — High Tease Message** · On-Screen Message

On-screen flavor message for a successful High Living/Parasite effect.

Inherits the default tease message until customized. Reset returns to inheritance. AI narration has separate tier entries in the first tab.

Required placeholders: `{actor}`.

Source ID: `Pools.Injection.tiers.high.lines`

**Living / Parasite — Extreme Tease Message** · On-Screen Message

On-screen flavor message for a successful Extreme Living/Parasite effect.

Inherits the default tease message until customized. Reset returns to inheritance. AI narration has separate tier entries in the first tab.

Required placeholders: `{actor}`.

Source ID: `Pools.Injection.tiers.extreme.lines`

## Retained internal entries

These are not normal player controls. Preserve their stored IDs and any existing personal overrides; hidden does not mean deleted, reset or ignored. Existing default parents still influence inherited tier entries.

| Existing ID | Reason |
| --- | --- |
| `Armor.narrate_armor_equip_4` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Armor.build_nearby_armor_status_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Armor.build_nearby_armor_status_2` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Armor.build_nearby_armor_status_3` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.narrate_dwemer_effect_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.build_dwemer_suit_prompt_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_profile_fallback_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_profile_fallback_2` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_event_fallback_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_event_fallback_2` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_event_fallback_3` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_event_fallback_4` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.get_dwemer_event_fallback_5` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `DwemerArmor.build_dwemer_effect_narration_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.send_capacity_milestone_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.send_capacity_milestone_2` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.build_milk_status_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.build_milk_status_2` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.build_milk_status_3` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.build_milk_status_4` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.build_milk_status_5` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.build_milk_status_6` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `Fullness.nearby_status_summary` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkDrinking.narrate_chest_milk_drink_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkDrinking.narrate_n_p_c_milk_drink_2` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkDrinking.narrate_n_p_c_milk_drink_3` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkDrinking.narrate_n_p_c_milk_drink_4` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkDrinking.narrate_player_milk_drink_3` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkDrinking.drinkMessage` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `MilkMaidCreation.milkmaidCreatedMessage` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `TentacleArmor.narrate_tentacle_effect_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `TentacleArmor.build_tentacle_effect_narration_1` | Internal prompt assembly, status formatting, factual boundary, or fallback. Not an independently useful creative control. |
| `TentacleArmor.effects_arousal` | Untiered narration parent retained for existing overrides and inheritance. Expose the twelve tier/outcome entries rather than competing parent controls. |
| `TentacleArmor.effects_milk` | Untiered narration parent retained for existing overrides and inheritance. Expose the twelve tier/outcome entries rather than competing parent controls. |
| `TentacleArmor.effects_milkAndArousal` | Untiered narration parent retained for existing overrides and inheritance. Expose the twelve tier/outcome entries rather than competing parent controls. |
| `Pools.Injection.lines` | Untiered notification parent retained for old edits and inheritance. Expose four tier messages instead of a competing default control. |

## Preservation and editing behavior

- Preserve all 147 IDs, paths, current prose, token validation and resolver precedence. No gameplay behavior changes.
- Preserve drafts when changing sections, feature filters, or search. Save staged edits together as today.
- Normal Reset All must explicitly say “Reset all visible editor entries” and preserve hidden internal overrides. It must cover both editor sections rather than silently depending on search filters.
- Existing imports/exports/backups can preserve the complete stored profile, including hidden entries; state the scope in their preview. Do not silently drop hidden or unknown overrides.
- Show a neutral notice when needed: “Some saved customizations belong to internal fields and remain active.”
- Avoid implying an edit guarantees a spoken line or forces an event; settings, eligibility, chance, route selection, outcome, inheritance and HUD length limits continue to apply.
- Keep exact placeholder names and explain them per entry; the companion metadata contains allowed/required tokens and token help.

## Implementation boundary and validation

This is a draft, not implementation authorization. After review, add authored presentation metadata to the existing catalog-generation input and current catalog RPC; reuse the current editor and personal override store. Do not create another editor or split files. Compile/build only when implementing.

Verify every current ID is assigned once, every visible field has a clear trigger/purpose, shared messages appear once, all four tease tiers have three narration outcomes and one message, both Dwemer profiles remain distinct, old hidden edits survive save/reset/import/export, drafts survive navigation, long descriptions wrap, required-token validation remains unchanged, and package source/compiled pairs match. Visual runtime testing and deployment require separate authorization.

## Coverage

147 existing entries: 111 visible (51 Skyrim.Net; 60 messages/stories), 36 retained internal. These are controls, not counts of individual random variants. All names/descriptions are source-derived review proposals; they do not establish every runtime route has been tested.
