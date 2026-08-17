# Requirements & Recommended Setup

This page covers the required and recommended setup for **MME Extensions**, including Milk Mod Economy, Skyrim VR, breast scaling, optional integrations, physics, and visual mods.

---

# 1. Hard Requirements

## Milk Mod Economy SE

https://www.loverslab.com/files/file/6103-milk-mod-economy-se/

**MME Extensions requires Milk Mod Economy SE.**

Make sure Milk Mod Economy itself is installed and working before troubleshooting MME Extensions.

Milk Mod Economy broadly requires:

- SKSE
- SkyUI
- RaceMenu
- XPMSSE
- SexLab Framework
- A compatible body and skeleton setup
- An animation behavior generator

For animation behavior generation, use the appropriate option for your setup:

- FNIS
- Nemesis
- Pandora

You generally only need one behavior generator.

---

## SexLab Framework - SE / AE

https://www.loverslab.com/files/file/20058-sexlab-se-sex-animation-framework-v166b-01182024/

Required by Milk Mod Economy and its SexLab-based scenes.

---

## Address Library for SKSE Plugins

https://www.nexusmods.com/skyrimspecialedition/mods/32444

Required by the MME Extensions CommonLibSSE-NG DLL.

---

## Skyrim SE / AE

Tested on:

**Skyrim SE / AE 1.6.1170**

---

# 2. Skyrim VR Requirements

Tested on:

**Skyrim VR 1.4.15**

Skyrim VR requires a VR-compatible SexLab setup.

## SexLab VR Setup

https://www.loverslab.com/topic/132489-skyrim-sexlab-and-vr/

## Specific SexLab VR Version

Use the VR-compatible SexLab version linked here:

https://www.loverslab.com/topic/132489-skyrim-sexlab-and-vr/page/54/#findComment-7063911

Do not simply install the normal SE / AE SexLab package for Skyrim VR.

MME Extensions supports Skyrim VR, but VR remains less extensively tested than SE / AE.

---

# 3. Recommended for Breast Scaling

These are **not hard requirements for MME Extensions itself**.

They are recommended if you want Milk Mod Economy's breast growth and scaling to work well with a modern 3BA setup.

## CBBE

https://www.nexusmods.com/skyrimspecialedition/mods/198

Base CBBE body used by 3BA.

---

## CBBE 3BA (3BBB)

https://www.nexusmods.com/skyrimspecialedition/mods/30174

Recommended modern body setup for breast scaling and physics.

---

## BodySlide and Outfit Studio

https://www.nexusmods.com/skyrimspecialedition/mods/201

Used to build your body and supported outfits.

For BodyMorph-based breast scaling, build supported bodies and outfits with:

**Build Morphs = CHECKED**

This is important if you want BodyMorph-based breast scaling to work correctly.

---

## SexLab Inflation Framework SE - SLIF

https://www.loverslab.com/files/file/6938-sexlab-inflation-framework-se/

Optional, but useful for managing breast and body scaling.

SLIF can help coordinate and adjust scaling when Milk Mod Economy or multiple other mods are changing body size.

---

## Tullius 3BA / 3BBB SLIF BodyMorph Setup

Guide:
https://www.loverslab.com/topic/133779-cbbe-3bbb-advanced/#findComment-2820451

---

# 4. Optional Integrations

None of these are required for the core MME Extensions features.

Install them only if you want the related functionality.

## SexLab Aroused / OSLAroused

Optional arousal integration.

MME Extensions can increase a Milk Maid's arousal from drinking milk and other supported events.

This is more powerful than simply changing an arousal number. **Arousal is supported by a huge ecosystem of Skyrim mods**, so increasing it can naturally trigger or influence features created by many other mod authors.

Depending on your setup, high arousal can lead to things such as:

- **AI-driven events and reactions**  
  https://discord.com/channels/1287232260617015336/1467570238546513940

- **Arousal-triggered animations**  
  https://www.nexusmods.com/skyrimspecialedition/mods/103427

- **Non-AI arousal-triggered SexLab encounters**, such as Arousal Based Match Maker (ABMM)  
  https://www.loverslab.com/files/file/8595-arousal-based-match-maker-abmm/

These are only a few examples.

The Skyrim arousal mod ecosystem is **far too large to document here**, and many other mods can react to SexLab Aroused / OSLAroused values in their own ways.

MME Extensions simply provides the optional arousal increase. **What that arousal causes afterward depends on the other mods in your load order.**

Without a compatible arousal framework, MME Extensions simply skips its optional arousal effects.

---

## Skyrim.Net

https://github.com/MinLL/SkyrimNet-GamePlugin

Optional AI integration.

Skyrim.Net enables features such as:

- Milk Maid context.
- Fullness awareness.
- Milk-drinking reactions.
- Forced narration.
- New Milk Maid reactions.
- Conversation-driven gameplay actions.
- Self-milking.
- Breastfeeding / milk-sharing.

MME Extensions' local sounds, notifications, milk effects, animations, and normal dialogue work without Skyrim.Net.

---

## SeverActions

https://github.com/Severause/SeverActions

Optional Skyrim.Net add-on.

Adds broader conversation-driven gameplay actions and gives Skyrim.Net more ways to physically interact with the game world.

Useful alongside MME Extensions, but not required.

---

## SkyrimNet_SexLab

https://github.com/GoodProvider/SkyrimNet_SexLab

Optional Skyrim.Net / SexLab integration.

MME Extensions already includes its own:

- Milk Maid self-milking action.
- Breastfeeding / milk-sharing action.

SkyrimNet_SexLab is **not required** for those features.

It can still improve the surrounding SexLab experience with additional scene-aware context, narration, reactions, and actions.

---

# 5. Optional Physics

These are not required by MME Extensions itself, but are commonly useful with 3BA.

## CBPC - Physics with Collisions

https://www.nexusmods.com/skyrimspecialedition/mods/21224

Provides body physics and collisions.

---

## FSMP - Faster HDT-SMP

https://www.nexusmods.com/skyrimspecialedition/mods/57339

Provides SMP physics for supported bodies, clothing, hair, and other meshes.

Depending on your setup, 3BA can use CBPC, FSMP, or a combination of both.

---

# 6. Optional Personal Visual Setup

The mods below are **NOT required** for MME Extensions.

They are simply part of the more lewd / polished visual setup I personally use.

I am including them because they may help users who want a similar look.

## Ghaans Revealing CBBE 3BBB Outfits

https://www.nexusmods.com/skyrimspecialedition/mods/39967

Optional 3BBB-compatible outfit replacer.

Build supported outfits in BodySlide if you want them to follow your body preset and BodyMorph scaling.

---

## BD's Armor and Clothes Replacer - CBBE 3BA

https://www.nexusmods.com/skyrimspecialedition/mods/32518

Optional 3BA-compatible armor and clothing replacer.

You do not need both Ghaans and BD's.

Choose whichever outfit setup you prefer.

---

## Botox For Skyrim SE

https://www.nexusmods.com/skyrimspecialedition/mods/95308

Optional broad NPC appearance overhaul.

Purely visual and not required for Milk Mod Economy or breast scaling.

---

## ColdSun's Visions - NPCs AIO - Recasted

https://www.nexusmods.com/skyrimspecialedition/mods/109529

Optional higher-detail replacer for many named NPCs.

**Load this after Botox** so ColdSun's covered NPCs use its appearances while Botox continues covering the remaining NPCs.

---

## My Tasteful Body - CBBE 3BA BodySlide Preset

https://www.nexusmods.com/skyrimspecialedition/mods/67370

**Highly optional.**

A very curvy and suggestive 3BA BodySlide preset.

Useful if you want an exaggerated body shape where Milk Mod Economy's breast scaling is especially noticeable.

---

# Quick Summary

## Required

- Milk Mod Economy SE
- Milk Mod Economy's own requirements
- SexLab Framework
- Address Library
- SKSE
- SkyUI
- RaceMenu
- XPMSSE
- Compatible body / skeleton
- FNIS, Nemesis, or Pandora

## Skyrim VR

- Skyrim VR 1.4.15 tested
- VR-compatible SexLab setup required

## Skyrim VR Optionals (use your imagination) 
- AI NPC TOUCH Reactions. https://github.com/Telord72612/VRTouchEvents
- Aroused by Touch. https://www.nexusmods.com/skyrimspecialedition/mods/126800

## Recommended for Breast Scaling

- CBBE
- CBBE 3BA
- BodySlide
- SLIF
- Tullius 3BA / 3BBB BodyMorph configuration

## Optional Integrations

- SexLab Aroused / OSLAroused
- Skyrim.Net
- SeverActions
- SkyrimNet_SexLab

## Optional Physics

- CBPC
- FSMP

## Optional Personal Visual Setup

- Ghaans outfits
- BD's armor replacer
- Botox
- ColdSun's Visions
- My Tasteful Body preset

If you only care about getting **MME Extensions working**, start with the hard requirements.

The rest adds breast scaling support, AI integration, physics, or optional visual improvements.