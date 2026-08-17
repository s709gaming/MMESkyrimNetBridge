# MME Extensions

LoversLab Download Page:  
https://www.loverslab.com/files/file/50820-mme-milk-mod-economy-extensions/

**A modular reaction and gameplay expansion for Milk Mod Economy.**

**Every feature can be DISABLED or ADJUSTED through the MCM.**

New to Milk Mod Economy, Skyrim VR, BodySlide, SLIF, 3BA, or breast scaling?

➡️ **[Full Requirements & Recommended Setup](REQUIREMENTS.md)**

MME Extensions makes Milk Maid gameplay more reactive, lewd, and alive.

**Drink milk. Get milkier. Get hornier. Moan about it. Fill up. Leak. Get milked. Let nearby characters notice.**

With **Skyrim.Net**, those reactions can go even further. The AI can understand Milk Maid status, react to important MME events, and even turn natural conversation into actual milking gameplay.

> [!IMPORTANT]
> **Skyrim.Net is completely optional.**
> Sounds, notifications, milk effects, dialogue, animations, and other core features work without it.

<img width="1164" height="864" alt="main menu" src="https://github.com/user-attachments/assets/0b3a32d7-574c-4b9f-b147-98260b94ceff" />

## Quick Overview

| | |
|---|---|
| **Release status** | Beta 0.3.0 |
| **Main requirement** | Milk Mod Economy |
| **Skyrim.Net** | Optional |
| **Arousal integration** | Optional |
| **Skyrim VR** | Supported, but still experimental |
| **Configuration** | Modular MCM options |

---

# 🥛 Major Features

## 🗣️ Skyrim.Net Gameplay Actions

Skyrim.Net can do more than simply talk about milking.

Natural conversation can now lead into **actual MME gameplay actions**.

### Milk Maid Self-Milking

An appropriate Milk Maid can decide to **milk herself for relief** when the situation naturally calls for it.

A very full and milky Milk Maid is given context encouraging the AI to strongly consider milking when appropriate.

### Breastfeeding / Milk Sharing

Conversation can naturally lead to **breastfeeding / milk-sharing scenes between characters through MME's SexLab integration**.

Supported combinations include:

- Player + NPC
- NPC + Player
- NPC + NPC

Instead of characters agreeing to something and then doing nothing:

**Conversation → Skyrim.Net action → MME scene**

These gameplay actions are optional and can be disabled through the MCM.

---

## 🥛 Drink ANY Milk

If the player or an NPC Milk Maid drinks supported milk:

- **Her tits get BIGGER** by increasing her current milk level.
- **Optional: She gets HORNIER** through SexLab Aroused or OSLAroused.
- **She can moan with pleasure** when reaction sounds are enabled.
- An in-game notification can tell you what she drank.
- Skyrim.Net can immediately recognize and react to the drink.
- Optional forced narration lets nearby characters react immediately.

Supported drinks include:

- Lactacid
- Normal milk
- Racial milk
- Supernatural milk

Milk gain is configurable through the MCM.

You can optionally add **half of the Milk Maid's level** to the amount gained from drinking.

Lactacid also has its own adjustable multiplier.

MME Extensions increases current MME milk level and uses MME's existing milk functions and capacity limits.

---

## 🥛 Give Milk to Other Milk Maids

MME's existing **"Hey, there"** dialogue receives a new choice:

> **Drink this, it will make you milky!**

When talking to a valid Milk Maid, MME Extensions automatically selects a supported drink from your inventory.

Priority:

**Lactacid → Normal Milk → Racial Milk → Supernatural Milk**

The NPC actually consumes the drink and receives the same enabled:

- Milk gain.
- Arousal gain.
- Reaction sounds.
- Notifications.
- Skyrim.Net reactions.
- Optional lewd reaction animation afterward.

---

# 💦 Milk Fullness Reactions

Milk Maids react as their breasts fill.

MME Extensions recognizes important capacity thresholds and can trigger local reactions, animations, and Skyrim.Net reactions.

## 50% Full

When a Milk Maid reaches half capacity:

- Gentle reaction/moan.
- Optional in-game notification.
- Optional short **breast-fondling animation**.
- Skyrim.Net receives updated context.
- Optional forced Skyrim.Net narration lets nearby characters react immediately.

## 100% FULL

When a Milk Maid becomes completely full:

- Stronger reaction/moan.
- Optional in-game notification.
- Optional short **breast-fondling animation**.
- Skyrim.Net receives a more urgent and suggestive description.
- Optional forced narration lets nearby characters immediately react.
- MME continues to handle its normal full/leaking behavior.

The 50% and 100% reaction animations can be enabled independently.

Animation duration can be adjusted through the **Animations MCM page** from **0 to 10 seconds**.

The system reacts to the **threshold crossing**, rather than repeatedly triggering because someone remains full.

Narration cooldowns are adjustable to prevent repetitive dialogue and unnecessary token usage.

**Waiting in-game is an easy way to quickly test fullness reactions.**

---

# 🍼 New Milk Maid Reactions

Becoming a Milk Maid is treated as an important event.

When someone becomes a new Milk Maid:

- Local reactions can occur.
- Skyrim.Net receives the event.
- Optional forced narration allows nearby characters to immediately acknowledge her new condition.

MME still owns the actual creation and management of Milk Maids.

---

# 🤖 Skyrim.Net Integration

Skyrim.Net support is one of the largest parts of MME Extensions, but remains completely optional.

When installed, Skyrim.Net can understand:

- Who nearby is a Milk Maid.
- Current Milk Maid fullness.
- Who just drank milk.
- What kind of milk she drank.
- Who recently became a Milk Maid.
- Half-full and completely-full events.
- Milking events.
- Milk leaking.
- Other important MME events.

It can also optionally **act on this information** through self-milking, milk-sharing, and milk-giving gameplay actions.

## Nearby Milk Maid Context

Nearby Milk Maids are summarized as:

- **Less than 50% full**
- **More than 50% full**
- **100% full**

For example:

> **Hulda is less than half full and feeling pleasantly tingly.**
>
> **Jenassa is more than half full, her breasts growing heavy and hot.**
>
> **Saadia is completely full, leaking and desperate.**

These are sent as temporary **Short-Lived Events** rather than permanently accumulating in Skyrim.Net's context.

The update interval can be adjusted through the MCM.

<img width="204" height="130" alt="milk drink tracking" src="https://github.com/user-attachments/assets/dd8d34be-e61f-4e3a-81a7-0bbe9668879f" />

<img width="516" height="213" alt="Recent event" src="https://github.com/user-attachments/assets/8d96ce51-eada-4a42-b1f7-1f65e85f6f0c" />

## Forced Skyrim.Net Reactions

Important events can optionally request an immediate Skyrim.Net narration.

Currently supported:

- Milk Maid reaches **50% full**.
- Milk Maid reaches **100% full**.
- Someone becomes a **new Milk Maid**.
- A Milk Maid **drinks supported milk**.

These features have independent MCM controls and cooldowns where appropriate.

They use short prompts to reduce unnecessary token usage.

---

# ⭐ Recommended Skyrim.Net Add-ons

These are **not required** for MME Extensions, but can greatly expand the AI side of the mod.

## SeverActions

https://github.com/Severause/SeverActions

Recommended for broader conversation-driven Skyrim.Net gameplay actions.

SeverActions gives the AI many more ways to physically interact with the game world instead of only talking about doing things.

For MME Extensions, it can be particularly useful for interactions such as naturally convincing a Milk Maid to **drink milk through conversation**, rather than relying only on the normal **"Hey, there"** dialogue.

Check the Skyrim.Net Discord for current setup information and compatible versions.

## SkyrimNet_SexLab

https://github.com/GoodProvider/SkyrimNet_SexLab

Recommended for richer AI interaction around intimate SexLab scenes.

**It is not required for MME Extensions' own breastfeeding / milk-sharing action.**

MME Extensions directly uses MME's existing SexLab integration for that scene.

SkyrimNet_SexLab can still improve the surrounding experience with features such as:

- Scene-aware AI context.
- Narration during intimate scenes.
- Additional SexLab gameplay actions.
- Better AI reactions before, during, and after scenes.

This can make an MME-triggered intimate scene feel like part of the ongoing Skyrim.Net conversation instead of simply starting an animation and leaving the AI behind.

Check the Skyrim.Net Discord for the latest compatible setup information.

**Neither SeverActions nor SkyrimNet_SexLab is required for MME Extensions.**

---

# 🔥 Intended World Setting

Milk acts as an **aphrodisiac for Milk Maids** and encourages their bodies to produce even more milk.

As a Milk Maid fills:

- Her breasts become heavier.
- Pressure increases.
- Movement and bouncing become more noticeable.
- Sensitivity increases.
- These sensations are pleasurable and desirable.

Milk Maids should generally react positively and erotically to:

- Drinking milk.
- Filling up.
- Becoming heavy with milk.
- Leaking.
- Being milked.

These reactions are the intended tone of the mod and its default messages.

---

# 🎛️ Modular MCM

Almost every major feature has its own controls.

MCM pages include:

- General
- Milk Drinking
- Animations
- Arousal
- Skyrim.Net
- Debug

Controls include:

- Reaction sounds.
- Milk drinking effects.
- Milk gain.
- Lactacid multiplier.
- Arousal gain.
- NPC drinking notifications.
- Milk-drinking reaction animations.
- 50% fullness animations.
- 100% fullness animations.
- Animation duration.
- Capacity reactions.
- Skyrim.Net status updates.
- Forced narrations.
- Narration cooldowns and chances.
- Skyrim.Net gameplay actions.
- Feature-specific diagnostics.

**Enable only the features you want.**

---

# ⚙️ Optional MME Settings

The FOMOD can optionally preload my preferred Milk Mod Economy settings.

These remain normal MME settings and can be changed afterward through MME's own MCM.

The recommended profile provides:

- Natural milk production without mandatory Lactacid.
- Roughly daily milking cycles.
- Novice progression.
- 3BA-friendly breast scaling.
- 100% gush chance to avoid additional milking delay.

The installer offers three startup profiles:

### Easy MCM Defaults + Free milk on start

Applies the recommended MME settings and grants a small one-time supply of milk for quick testing.

### Easy MCM Defaults + No milk on start

Applies the same recommended settings without starter milk.

### Keep original MME Defaults + No milk on start

Leaves MME's original settings and starter behavior unchanged.

---

# 📥 Installation

For the complete dependency list, Skyrim VR setup, BodySlide instructions, breast-scaling setup, and optional integrations:

➡️ **[Full Requirements & Recommended Setup](REQUIREMENTS.md)**

Basic installation:

1. Install Milk Mod Economy and verify that it works.
2. Install its required dependencies.
3. Install `MME Extensions.zip` through Vortex or Mod Organizer 2.
4. Choose your preferred MME settings during the FOMOD installation.
5. Enable `MMEAlert.esp`.
6. Deploy or sort your load order.
7. Start Skyrim through SKSE.

---

# 🧪 Beta Status

**MME Extensions 0.3.0 is currently in Beta.**

The intended major feature set is substantially complete.

Development is primarily focused on:

- Longer gameplay testing.
- Bug fixes.
- Compatibility.
- Skyrim VR testing.
- Skyrim.Net reliability.
- Balance and polish.

Small features may still appear during testing.

> [!WARNING]
> This is still a Beta.
> Keep backups and avoid risking an important save until the mod receives broader testing.

MME Extensions does **not overwrite the original Milk Mod Economy files**.

Most features can be disabled mid-game through the MCM.

---

# 🛠️ Diagnostics

Major systems include focused optional diagnostics.

Depending on the feature, debug output can report:

- Event detected.
- Actor recognized.
- Milk Maid validation.
- Drink detected.
- Exact milk consumed.
- Fullness threshold detected.
- Animation started or stopped.
- Skyrim.Net availability.
- Narration requested.
- LLM gameplay action received.
- Actor references resolved.
- MME/SexLab scene request attempted.
- Failure or skip reason.

Debug toggles are normally OFF and can be enabled only when needed.

Papyrus details can be written to the normal Papyrus log.

Native bridge details are written to:

`MMEExtensions.log`

inside the SKSE log directory.

---

<details>
<summary><strong>Developer / Technical Notes</strong></summary>

## General Architecture

The ESP owns the startup quest, aliases, dialogue records, sound forms, and script properties.

Papyrus handles MME-facing rules and configurable gameplay.

The CommonLibSSE-NG DLL provides low-cost engine events and nearby actor discovery.

Skyrim.Net integration is isolated behind availability checks so the rest of the mod continues working without Skyrim.Net.

## Efficient Native Support

The native bridge supports:

- Wait events.
- Sleep events.
- Location changes.
- Magic-effect events.
- NPC potion consumption.
- Nearby actor discovery.

Nearby actors are discovered natively and then authoritatively validated against MME through Papyrus.

This avoids broad Papyrus actor scanning where native events are available.

Polling remains available only where useful, with an adjustable interval.

## Typical Flow

1. A native event, MME ModEvent, alias event, dialogue fragment, or Skyrim.Net action detects something.
2. Papyrus validates the actor/form where necessary.
3. A focused helper applies enabled gameplay behavior.
4. Skyrim.Net integration separately publishes enabled context or narration.
5. Feature-specific diagnostics report the decision path when requested.

## Papyrus Script Legend

- `MMEAlertsController.psc` - startup, MME events, capacity scheduling, nearby Milk Maid validation, creation detection, and milking events.
- `MMEAlertsMCM.psc` - MCM pages, settings, defaults, migrations, tooltips, and diagnostics.
- `MMEAlertsPlayerEffect.psc` - restores the controller after startup and save loading.
- `MMEAlertsSkyrimNet.psc` - Skyrim.Net checks, prompts, events, nearby summaries, and forced narration.
- `MMEDrinkTracker.psc` - player and NPC milk-drinking detection.
- `MMEMilkDrinkEffects.psc` - shared drinking reaction sounds.
- `MMEMilkBoost.psc` - milk-bonus calculation and capacity-safe application.
- `MMEArousalBridge.psc` - optional arousal integration.
- `MMENPCDialog.psc` - Milk Maid dialogue, inventory selection, consumption, effects, and animation.
- `MMEAlertsFlatRateDefaults.psc` - optional FOMOD-selected MME preset.
- `MMEAlertsQuickTest.psc` - compatibility/testing helper.
- `MMEDebug.psc` - troubleshooting helper.
- `MMEExtensionsNative.psc` - Papyrus declarations for native functions.
- `MMESkyrimNetVoiceControls.psc` - Skyrim.Net self-milking, milk-sharing, and milk-giving action bridge.

## Native Code

- `src/Plugin.cpp` - publishes engine events to Papyrus and exposes nearby actor discovery.
- `build-native.bat` / `build-native.ps1` - builds the native DLL.
- `build-package.bat` / `build-package.ps1` - compiles Papyrus and creates the distributable FOMOD.

## Data and Configuration

- `MMEAlert.esp` - plugin containing MME Extensions records.
- `SKSE/Plugins/StorageUtilData/MMEAlerts/SkyrimNet.json` - editable Skyrim.Net event messages.
- `SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt` - actor-specific Milk Maid context.
- `fomod/` - installer metadata and optional defaults.
- `assets/sounds/` - reaction sound pools.
- `tools/README.md` - archival xEdit/Pascal tooling guidance.
- `tools/mme-sdk/` - minimal compile-time declarations for MME, SexLab, and SkyUI APIs. Runtime calls resolve against installed mods.

## Build Notes

1. Run `build-native.bat` only after changing native C++ code or the toolchain.
2. Run `build-package.bat` for every distributable build.
3. Install `dist/MME Extensions.zip` using a mod manager.
4. Do not install the staging directory directly.
5. Confirm that General, Milk Drinking, Animations, Arousal, Skyrim.Net, and Debug pages appear in the MCM.
6. Remove or clearly identify test-only helpers before release.

## Skyrim.Net Developer Actions

MME Extensions exposes gameplay actions that other Skyrim.Net mods and integrations can build around.

### `StartMilkMaidSelfMilking`

Starts MME self-milking for a valid Milk Maid.

### `StartBreastfeedingMilkShare`

Starts an MME breastfeeding / milk-sharing scene between two actors.

### `GiveMilkToMilkmaid`

Gives and consumes a supported milk item through the MME Extensions drinking pipeline.

These can be useful when creating additional Skyrim.Net actions, prompts, or integrations.

See:

`Source/Scripts/MMESkyrimNetVoiceControls.psc`

for the current implementation and validation.

</details>

---

# Source Code

https://github.com/s709gaming/MMESkyrimNetBridge

# Credits

- **Ed86** - Milk Mod Economy
- **MinLL and contributors** - Skyrim.Net
- **CharmedBaryon and contributors** - CommonLibSSE-NG

# License / Permissions

Released under the MIT License.

Feel free to use, modify, redistribute, or build on MME Extensions under the MIT License.

Credit is appreciated.

Third-party dependencies and assets remain subject to their own permissions.

MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab, SexLab Aroused, OSLAroused, or Skyrim.Net release.

# Changelog

See **[GitHub Releases](https://github.com/s709gaming/MMESkyrimNetBridge/releases)** for version history and detailed changes.