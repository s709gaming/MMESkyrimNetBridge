MME Extensions

MME Extensions is a modular reaction add-on for Milk Mod Economy. Its main purpose is to make Milkmaid gameplay feel sillier by adding reactions and triggers to drinking milk, filling up, leaking, milking, and other important MME events.

Skyrim.Net integration is one of the mod’s largest features, allowing nearby characters and narration to recognize these events. However, Skyrim.Net is completely optional. Sounds, notifications, drink effects, dialogue, and other core features work independently. EVERYONE WILL TALK ABOUT FEMALE ANATOMY MUCH MORE!

Everything is modular. Enable only the features you want through the MCM. This still late alpha.

Intended World Setting

Milk acts as an aphrodisiac for Milkmaids and makes them produce even more milk.

The growing weight, fullness, movement, and pressure are pleasurable and desirable. Milkmaids should react positively—and erotically—to filling up, leaking milk, drinking milk, and being milked.

These reactions are the intended tone of the mod and its default messages.

Requirements
Skyrim Special Edition or Anniversary Edition with SKSE
Milk Mod Economy and all its requirements
SkyUI
PapyrusUtil
JContainers
Address Library for SKSE Plugins
Skyrim.Net — optional; only required for Skyrim.Net features
SexLab Aroused or OSLAroused — optional; only required for arousal features

The native DLL was built with CommonLibSSE-NG.

Skyrim VR support is built into the CommonLibSSE-NG DLL but still needs broader in-game verification. Use VR Address Library when testing VR.

Features
Modular Milk Event Reactions

MME Extensions watches important Milk Mod Economy events and reacts to them.

Depending on the event and your MCM settings, the mod can:

Play a suggestive sound effect.
Show an in-game notification.
Alert Skyrim.Net so nearby characters can react.
Apply optional bonus milk or arousal effects when drinking milk.

Supported events include:

Someone becoming a new Milkmaid.
The player or an NPC drinking supported milk.
A Milkmaid reaching half-full capacity.
A Milkmaid reaching full capacity and leaking.
Milking starting.
Milking ending.

Each reaction type is modular and can be enabled or disabled separately.

Milk Drinking Effects
Detects supported milk consumed by the player or NPCs without a polling loop.
NPC effects apply only to valid MME Milkmaids.
Supports Lactacid, normal milk, racial milk, and supernatural milk.
Adds a configurable flat milk bonus when drinking milk.
Can optionally add half the drinker’s Milkmaid level to her milk level.
Gives Lactacid its own configurable multiplier.
Uses MME’s existing milk functions and respects normal capacity limits.
Can optionally raise arousal when SexLab Aroused or OSLAroused is installed.
Milkmaid Dialogue
Adds Drink this, it will make you milky! beneath MME’s existing Hey, there dialogue.
Appears only when speaking to a valid MME Milkmaid.
Transfers and processes one supported milk item from the player.
Selection priority: Lactacid, normal milk, racial milk, then supernatural milk.
Can optionally play MME’s Milkmaid reaction animation after the effects finish.
Additional Skyrim.Net Features

Skyrim.Net is completely optional. All Skyrim.Net functions disable themselves when it is unavailable.

When installed, MME Extensions can:

Publish Milkmaid events as short-lived context.
Report the exact type of milk consumed.
Send summaries of nearby Milkmaid fullness using an MCM-adjustable polling interval.
Request narration when a nearby Milkmaid first becomes full, with an MCM-adjustable cooldown.
Add Milkmaid context only to confirmed MME Milkmaids through a short .prompt file.
Control each Skyrim.Net feature separately through the MCM.
Optional MME Settings

The FOMOD can preload the author’s preferred MME MCM values. These remain normal MME settings and can be changed at any time.

The recommended profile provides natural milk production without mandatory Lactacid, roughly daily milking cycles, Novice progression, 3BA-friendly breast scaling, and a 100% gush chance to avoid extra milking delay.

Choosing Keep MME Defaults leaves MME’s settings unchanged.

Efficient Native Support
Uses a CommonLibSSE-NG bridge for wait, sleep, location-change, magic-effect, and NPC potion events.
Uses native nearby-actor discovery followed by authoritative MME validation in Papyrus.
Avoids broad Papyrus actor scanning and unnecessary polling where native events are available.
Provides adjustable polling only where it is still needed.
Diagnostics for Developers
Independent debug toggles keep notifications focused on the feature being tested.
Papyrus details can be written to the normal Papyrus log.
Native bridge details are written to MMEExtensions.log in the SKSE log directory.
The former Quick Test helper is inert in release builds and grants no consumables.
Installation
Install all required dependencies.
Install MME Extensions.zip with Vortex or Mod Organizer 2.
Choose whether the FOMOD should preload the recommended MME MCM values.
Enable MMEAlert.esp and deploy or sort the mod.
Start Skyrim through SKSE.
Compatibility and Status
This is an alpha release.
Core features work in isolated testing, but broader load-order testing is still needed.
Expect bugs. Do not risk an important save.
Skyrim VR support is included but still requires broader in-game verification.
SPID is not currently required or active. I was only poking around with it during development.
Developer Notes
General Architecture

The ESP owns the startup quest, aliases, dialogue records, sound forms, and script properties. Papyrus handles MME-facing rules and configurable gameplay. The CommonLibSSE-NG DLL supplies low-cost engine events and nearby-actor discovery. Skyrim.Net integration is isolated behind availability checks, so the rest of the mod continues working without Skyrim.Net.

Typical flow:

A native event, MME ModEvent, alias event, or dialogue fragment detects an action.
Papyrus validates the actor and form against MME.
A focused helper applies the enabled sound, milk, arousal, or dialogue behavior.
The Skyrim.Net bridge publishes enabled context separately.
Feature-specific diagnostics report the decision path when requested.
Papyrus Script Legend
MMEAlertsController.psc — central startup, MME event registration, capacity scheduling, nearby Milkmaid validation, creation detection, and milking start/end handling.
MMEAlertsMCM.psc — MCM pages, settings, defaults, migrations, tooltips, and diagnostic controls.
MMEAlertsPlayerEffect.psc — player ability lifecycle hook; restores the controller after startup and save loading.
MMEAlertsSkyrimNet.psc — active Skyrim.Net availability checks, prompt decoration, events, nearby summaries, and narration requests.
MMEDrinkTracker.psc — player equip-based drink detection and native NPC potion-consumption handling.
MMEMilkDrinkEffects.psc — shared drink reaction-sound playback.
MMEMilkBoost.psc — shared milk-bonus calculation and MME capacity-safe application.
MMEArousalBridge.psc — optional SexLab Aroused/OSLAroused detection and arousal updates without a hard script dependency.
MMENPCDialog.psc — Milkmaid-only dialogue validation, inventory priority, transfer, consumption, extension effects, and optional animation.
MMEAlertsFlatRateDefaults.psc — optional FOMOD-selected MME MCM preset; captures values so its changes can be reversed.
MMEAlertsQuickTest.psc — inert compatibility placeholder. The Recommended FOMOD startup profile replaces it with an isolated, once-per-save starter-milk helper.
MMEDebug.psc — passive debug helper retained for focused troubleshooting.
MMEExtensionsNative.psc — Papyrus declaration for the DLL’s native nearby-actor function.
MMESkyrimNetVoiceControls.psc — archived experimental actions; deliberately excluded from release compilation.
Native Code
src/Plugin.cpp — CommonLibSSE-NG plugin. Publishes wait, sleep, location, MME magic-effect, and NPC potion events to Papyrus and exposes nearby-actor discovery.
build-native.bat / build-native.ps1 — builds the native DLL after C++ changes.
build-package.bat / build-package.ps1 — compiles active Papyrus scripts and creates the distributable FOMOD archive.
Data and Configuration
MMEAlert.esp — current legacy plugin filename; contains the MME Extensions records.
SKSE/Plugins/StorageUtilData/MMEAlerts/SkyrimNet.json — editable Skyrim.Net event messages.
SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt — actor-specific Milkmaid lore prompt.
fomod/ — installer metadata and optional defaults selection.
assets/sounds/ — source reaction-sound pools packaged under Sound/.
Build Notes
Run build-native.bat only after changing the native C++ code or toolchain.
Run build-package.bat for every distributable build.
Install dist/MME Extensions.zip with a mod manager; do not install the staging directory directly.
Confirm that the MCM title is MME Extensions and that General, Milk Drinking, Arousal, Skyrim.Net, and Debug pages appear.
Keep test-only helpers clearly identified or remove them before the public release.
Credits
[Milk Mod Economy] Ed86
[Skyrim.Net] MinLL
[CommonLibSSE-NG] CharmedBaryon/
License

This project is released under the MIT License. MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab Aroused, or Skyrim.Net release.
