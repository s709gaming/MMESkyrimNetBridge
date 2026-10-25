
# Requirements & Recommended Setup

This guide covers what **MME Extensions** needs to run, plus optional integrations, breast scaling, Skyrim VR, and a few recommended mods. **You do not need everything listed here.** Start with the requirements for your chosen installation, then add the extras you actually want.

## 1. Core Requirements

### Milk Mod Economy SE (Required)

[Milk Mod Economy SE](https://www.loverslab.com/files/file/6103-milk-mod-economy-se/)

**MME Extensions requires Milk Mod Economy SE.** Get MME itself working before troubleshooting the extension.

Follow MME's own requirements, which generally include:

- SKSE, SkyUI, RaceMenu, and XPMSSE
- A compatible body and skeleton
- An animation behavior generator: **FNIS, Nemesis, or Pandora** (generally just one)
- SexLab Framework for the standard SexLab-based setup

### Choose Your Animation Setup

**Standard SexLab setup:** Install [SexLab Framework SE / AE](https://www.loverslab.com/files/file/20058-sexlab-se-sex-animation-framework-v166b-01182024/). This is the familiar option for SexLab-based MME add-ons and integrations, including Devious Devices.

**OStim alongside SexLab:** MME Extensions can use OStim animations while SexLab remains installed for other mods and compatibility. The two frameworks can coexist.

**Experimental OStim-only FOMOD option:** An alternative installation that replaces the mod's SexLab dependency with OStim. **SexLab-based expansions such as Elsie Lavache, Devious Devices, and JUGS are not supported in this mode.** Check the requirements of any other MME add-ons before choosing it.

**Optional:** [SexLab P+](https://www.loverslab.com/files/file/25318-sexlab-p/) is a performance-oriented SexLab patch. **Read its requirements carefully.**

### Address Library for SKSE Plugins (Required)

[Address Library](https://www.nexusmods.com/skyrimspecialedition/mods/32444) is required by the MME Extensions CommonLibSSE-NG DLL.

### Supported Game Versions

- **Skyrim SE / AE:** Tested on 1.7.104; built with CommonLibSSE-NG 8.3.0 for that runtime.
- **Skyrim VR:** Tested on 1.4.15, with less extensive testing than SE / AE. See the VR setup below.

## 2. Optional Content for Specific Features

### Trapped Treasure Chest Armor

- [Tentacle armor](https://www.nexusmods.com/skyrimspecialedition/mods/62644?tab=files)
- [Devious Dwarven Cuirass 3BA SE/AE](https://www.loverslab.com/files/file/23018-dwarven-devious-cuirass-3ba-seae/)

These armor options **do not require the Devious Devices mod** merely for the trapped-chest armor feature.

### 3BA Milk Cuirass

[MME milk harness / cuirass BodySlide files](https://www.loverslab.com/topic/156760-milk-mod-economy-mme-cbbebhunp3ba-leseae-new-milk-harness-body-slide/)

Recommended for 3BA users to avoid an odd body shape while wearing the milk cuirass.

## 3. Breast Scaling & Physics (Recommended)

**Not core requirements.** These are useful for a modern 3BA setup and visible breast growth.

| Mod | Why use it |
| --- | --- |
| [CBBE](https://www.nexusmods.com/skyrimspecialedition/mods/198) | Base body for 3BA |
| [CBBE 3BA (3BBB)](https://www.nexusmods.com/skyrimspecialedition/mods/30174) | Body setup for scaling and physics |
| [BodySlide and Outfit Studio](https://www.nexusmods.com/skyrimspecialedition/mods/201) | Build bodies and supported outfits |
| [SLIF NG (Inflation Framework NG)](https://www.nexusmods.com/skyrimspecialedition/mods/192276?tab=description) | Modern body scaling framework, including MME integration |
| [CBPC](https://www.nexusmods.com/skyrimspecialedition/mods/21224) | Physics and collisions |
| [FSMP (Faster HDT-SMP)](https://www.nexusmods.com/skyrimspecialedition/mods/57339) | SMP physics for supported meshes |

### SLIF NG (Recommended)

**SLIF NG replaces the original SexLab Inflation Framework (SLIF)** with a modern SKSE-based system.

It modernizes MME breast scaling, supports BodyMorphs, and coordinates body changes from multiple mods without needing the old Tullius configuration guide.

**If upgrading from old SLIF, remove the original framework and its patches before installing SLIF NG.** Follow SLIF NG's installation instructions and select your body type.

### BodySlide Setup

For BodyMorph-based scaling, build supported bodies and outfits in BodySlide with:

**Build Morphs = CHECKED**

This allows supported body parts to grow and change properly.

For physics, 3BA may use CBPC, FSMP, or both depending on your setup.

## 4. Optional Integrations

### SexLab Aroused / OSLAroused

MME Extensions can raise a Milk Maid's arousal through drinking milk and other supported events. Other mods can then respond to that value, for example with:

- [AI-driven events and reactions](https://discord.com/channels/1287232260617015336/1467570238546513940)
- [Arousal-triggered animations](https://www.nexusmods.com/skyrimspecialedition/mods/103427)
- [Arousal Based Match Maker (ABMM)](https://www.loverslab.com/files/file/8595-arousal-based-match-maker-abmm/), for non-AI SexLab encounters

The arousal ecosystem is much bigger than this short list. **MME Extensions changes arousal; what happens next depends on the other mods installed.** Without a compatible arousal framework, it skips the optional arousal effects.

### Skyrim.Net (AI Integration)

[Skyrim.Net](https://github.com/MinLL/SkyrimNet-GamePlugin) can give NPCs awareness of Milk Maids, fullness, milk drinking, and newly created Milk Maids. It also supports narration, conversation-driven actions, self-milking, and breastfeeding / milk-sharing interactions.

It can enhance roleplay with AI dialogue, actions, and reactions, and can voice otherwise silent NPC dialogue.

**Voice setup:** In the Skyrim.Net web UI, go to **Settings > Audio & Voice > Dialogue Replacement**, and enable **TTS for Silent NPC**.

To turn off AI gameplay while retaining voice generation, use the top-right **Quick Toggles** and switch off **Skyrim.Net Enabled**.

Skyrim.Net can cost less than a dollar per hour at minimal usage settings, depending on configuration and provider. **MME Extensions' normal dialogue, sounds, notifications, milk effects, and animations do not require Skyrim.Net.**

### Other Skyrim.Net Add-ons

- [SeverActions](https://github.com/Severause/SeverActions): Adds broader conversation-driven gameplay actions.
- [SkyrimNet_SexLab](https://github.com/GoodProvider/SkyrimNet_SexLab): Adds AI-voiced dialogue to SexLab scenes.

Both are optional.

## 5. More Mods for the MME Ecosystem

These are **content suggestions, not requirements**. Read their individual dependency and compatibility notes, especially if you use the experimental OStim-only option.

### Elsie Lavache

[Elsie Lavache for MME](https://www.loverslab.com/topic/81744-elsie-lavache-for-mme-v34/)

Adds lewd quests and transformations into milky bimbos. MME Extensions enhances the effects of milk shared through Elsie's interactions. Cups not provided! 🥛

Skyrim.Net can provide AI roleplay and voice Elsie's otherwise silent dialogue using its TTS feature.

### JUGS

[JUGS SSE conversion](https://www.loverslab.com/topic/42635-jugs/page/14/#findComment-4211824)

A dialogue-based adult expansion by Chajapa, creator of Elsie Lavache. Adds more flavorful ways to share milk, with extra opportunities for Skyrim.Net roleplay.

### Other Gameplay Additions

- [Breast Controls / Scaling for MME](https://www.loverslab.com/topic/101166-milk-mod-economy-se/page/78/#comment-3791114): More control over MME body scaling.
- [The LactTAT](https://www.loverslab.com/files/file/18183-the-lacttat/): A milk-themed curse that can unexpectedly boost production.
- [Being a Cow, Alternate Version](https://www.loverslab.com/topic/187761-being-a-cow-alternate-version/): **Extreme, taste-dependent content.** Can gradually turn characters into cow-like humanoids. Expect to adjust visuals and MCM options.
- [Milk Addict](https://www.loverslab.com/topic/97335-milk-addict/page/22/#elControls_4259982_menu): Adds milk and Lactacid addiction mechanics. **Personal recommendation:** Disable its armor-break system and tune the addiction settings; check the discussion for SE-specific files and patches.

## 6. Skyrim VR Setup

**Tested on Skyrim VR 1.4.15.** VR has received less testing than SE / AE.

For a SexLab-based VR installation, use a **VR-compatible SexLab build**, not the regular SE / AE package:

- [SexLab VR setup discussion](https://www.loverslab.com/topic/132489-skyrim-sexlab-and-vr/)
- [Specific VR-compatible SexLab version](https://www.loverslab.com/topic/132489-skyrim-sexlab-and-vr/page/54/#findComment-7063911)

**Optional VR extras:**

- [VRTouchEvents (AI NPC touch reactions)](https://github.com/Telord72612/VRTouchEvents)
- [Aroused by Touch](https://www.nexusmods.com/skyrimspecialedition/mods/126800)

## 7. My Optional Visual Setup

**None of these are required.** These are simply recommendations for a more polished or exaggerated look.

- [Ghaans Revealing CBBE 3BBB Outfits](https://www.nexusmods.com/skyrimspecialedition/mods/39187): Revealing 3BBB outfit replacer; build supported outfits in BodySlide for morph scaling.
- [BD's Armor and Clothes Replacer, CBBE 3BA](https://www.nexusmods.com/skyrimspecialedition/mods/32518): Another outfit replacer. Its barkeeper dress appears in the mod thumbnail. **Choose Ghaans or BD's; you do not need both.**
- [Botox for Skyrim SE](https://www.nexusmods.com/skyrimspecialedition/mods/95308): Broad NPC appearance overhaul.
- [ColdSun's Visions, NPCs AIO Recasted](https://www.nexusmods.com/skyrimspecialedition/mods/109529): Higher-detail replacer for many named NPCs. **Load after Botox** to use ColdSun for covered NPCs and Botox for the rest.
- [My Tasteful Body, CBBE 3BA BodySlide Preset](https://www.nexusmods.com/skyrimspecialedition/mods/67370): Very curvy preset that makes MME body scaling especially noticeable.

---

**Quick rule:** First get MME and MME Extensions running with the appropriate animation framework and dependencies. Then add body scaling, optional integrations, and extra content one piece at a time. The milk will still be there. 🥛
