# MME Extensions

**Release status:** Beta 0.5.0  
**Main requirement:** Milk Mod Economy (and its requirements)
IMPORTANT: Skyrim SE/AE 1.7.9.9 is not yet supported.

### Tentacle Effects: optional Skyrim.Net reactions

The Tentacle Effects page now has a **Skyrim.Net Narration** section. Narration
defaults to enabled with a **100% chance**, adjustable from 0-100% in 5% steps.
After a successful check and its usual HUD notification, at most one request
uses one successfully affected wearer as its subject. No timer, detection, armor rules,
milk/arousal calculations, or original HUD lines are changed.

Non-graphic narration text lives in
`SKSE/Plugins/StorageUtilData/MMEAlerts/TentacleEffectNarration.json`. This is
ordinary JSON, following Thoughts' path-based loading and `{actor}` rendering.
It contains three complete outcome templates: `milk`, `arousal`, and
`milkAndArousal`. Each must contain one `{actor}` or `{ACTOR}` token. The matching template
is selected only from confirmed positive results; missing keys/files use
built-in defaults, while a selected template missing its actor token skips
narration. Restart Skyrim after editing the JSON so PapyrusUtil's cached
configuration is refreshed.

The milk result uses the existing helper's actual delta. Arousal requires both
a successfully sent SLA event and a readable increase over the pre-event value.
Sending an event alone is not proof: pending, capped, disabled, or unreadable
arousal is omitted. No new delay or polling is introduced to await SLA.
When neither increase is confirmed, narration is skipped.
Skyrim.Net must also be installed and enabled in the existing bridge settings.

For in-game validation, enable Effect Diagnostics, set narration chance to 100%,
and run a successful effect check; close MCM to allow gameplay/voice playback.
Check the selected wearer and accepted/rejected request result. Test milk-only,
arousal-only, both, and neither; capped/unconfirmed effects must not be claimed.
With multiple affected Maids, expect one request, not one per actor. Repeat at
0% and with narration disabled: effects and HUD must still run, without a request.
Finally restore your preferred chance. These checks apply real gameplay effects.
An accepted API request does not guarantee generated dialogue or voice playback.
Automated source/JSON and bytecode checks are included in the build; Skyrim.Net
playback and asynchronous SLA timing still require in-game validation.

**Enable Player Narration** defaults to enabled under Skyrim.Net Narration.
When an affected player is selected, a private custom LLM request generates a
self-comment and its callback uses Skyrim.Net's player-only TTS endpoint. It
does not publish player dialogue or request bystander reactions. The supplied
`mme_wearer_self_comment.prompt` uses non-graphic, first-person output instructions;
the three existing JSON situation templates remain unchanged. Configure a working
player voice in Skyrim.Net. Generation failure has no bystander fallback.
When this toggle is off, a player-focused check sends no narration request, even
if NPCs were also affected. The callback rechecks toggles before delayed playback.
NPC-only checks explicitly pass the affected NPC as the DirectNarration speaker,
per the installed API contract; this route still needs in-game speaker verification.
Child speakers are rejected. The main
narration toggle gates both routes, and both share the 100% default chance and
one-request-per-check limit. The local effects and HUD notification are unchanged.
Independent Skyrim.Net conversations/world reactions are not globally disabled.

### September 6, 2026: Tentacle Effects scan hotfix

Fixed false "nearby scan returned no actors" skips. The native scan was finding
actors, but array comparisons/initialization with `None` generated rejected
Papyrus casts. The scheduled/manual Tentacle Effects path and shared
Thoughts/capacity scan now use array lengths without those casts. Packaging
checks the compiled bytecode to prevent this regression.

The ESP, native DLL, timer settings, and original Injection.json wording are
unchanged by the scan hotfix. Optional Skyrim.Net integration is described above.

To test: exit Skyrim, install this ZIP over the previous version with the same
installer choices, restart and load your save. With an eligible MME Milk Maid
wearing supported Living/Parasite armor, enable Tentacle Effects, set chance to
100%, and run its MCM debug check. Confirm a nonzero nearby-actor count and the
normal eligibility/effect report. Close the MCM so gameplay and notifications
can resume. Also test a scheduled cycle (1 game-hour interval, zero variation),
then restore your preferred settings. These checks apply real configured effects.
Compilation and bytecode checks are automated; in-game confirmation is still
required.

**See:**  
[Full Requirements & Recommended Setup](REQUIREMENTS.md)

**LoversLab Download Page:**  
https://www.loverslab.com/files/file/50820-mme-milk-mod-economy-extensions/

---

Milk Mod Economy Extensions modernizes and expands ed86's popular **Milk Mod Economy** with reactions, animations, OStim support, and optional AI-powered **Skyrim.Net integration**.

**Everything is OPTIONAL and adjustable through an in-game MCM.**

Make Milk Maid gameplay feel more alive, reactive, and a little more shameless.

## KEY FEATURES

- **Optional (but major) Skyrim.Net integration** gives nearby NPCs AI-generated voice reactions to major MME events and can turn certain conversations into actual gameplay actions.

- Drinking milk can increase a Milk Maid's milk amount, temporarily inflate her breasts, raise arousal, and trigger moans, animations, or reactions.

- Arousal is meant to trigger your other arousal mods, like animations or events. 

- Milk can come from bottles... or straight from the tap~

- Nearby Milk Maids react as they become heavy, full, leaking, milked, or fitted with questionable milking equipment.

- Create new Milk Maids through a simple, erotic breastfeeding ritual.

- Supports the modern **OStim animation framework** while retaining existing SexLab support.

**In short: MME still handles the milk. MME Extensions makes Skyrim notice.**

## WHAT CAN TRIGGER REACTIONS?

Depending on your MCM settings, AI narration, lewd sounds, animations, or notifications can react to:

- Drinking milk and becoming aroused and bustier.
- Reaching 50% or 100% milk fullness.
- A new Milk Maid discovering her newfound gifts.
- Equipping milking devices such as milk cuirasses, parasite armor, and similar equipment.
- Talking to blacksmiths, alchemists, or court wizards while wearing armor recognized by MME—or no body armor at all.
- Periodically wearing those questionable devices around Skyrim.
- Being milked or breastfeeding lovers.
- Clothes flying off your body from overly large assets or other important MME events.

## OPTIONAL MME SETTINGS

The FOMOD can optionally preload my preferred **Milk Mod Economy settings**.

These remain normal MME settings and can be changed afterward through MME's own MCM.

The recommended profile provides:

- Natural milk production without mandatory Lactacid
- Roughly daily milking cycles
- Novice progression
- 3BA-friendly breast scaling
- 100% gush chance to avoid additional milking delay

The installer offers three startup profiles:

### Easy MCM Defaults + Starter Items

Applies easier MME settings and grants a small one-time supply of milk and a milking cuirass so you can jump quickly into the mod.

### Easy MCM Defaults + No Starter Items

Applies the same recommended settings without starter items.

### Keep Original MME Defaults

Leaves MME's original settings and starter behavior unchanged.

## INSTALLATION

For the complete dependency list, Skyrim VR setup, BodySlide instructions, breast-scaling setup, optional integrations, and visual recommendations, see:

[Full Requirements & Recommended Setup](REQUIREMENTS.md)

Basic installation:

1. Install Milk Mod Economy and verify that it works.
2. Install its required dependencies.
3. Install `MME Extensions.zip` through Vortex or Mod Organizer 2.
4. Choose your preferred MME settings during the FOMOD installation.
5. Enable `MMEAlert.esp`.
6. Deploy or sort your load order.
7. Start Skyrim through SKSE.

## SOURCE CODE

https://github.com/s709gaming/MMESkyrimNetBridge

## CREDITS

- **Ed86** - Milk Mod Economy
- **MinLL and contributors** - Skyrim.Net
- **CharmedBaryon and contributors** - CommonLibSSE-NG
- **Tetherball88** - Reference for OStim implementation
- **GoodProvider** - Reference for SexLab implementation

## LICENSE / PERMISSIONS

Released under the **MIT License**.

Feel free to use, modify, redistribute, or build on MME Extensions under the MIT License.

Credit is appreciated.

Third-party dependencies and assets remain subject to their own permissions.

MME Extensions is an independent add-on and is not an official Milk Mod Economy, Skyrim, SKSE, SexLab, SexLab Aroused, OSLAroused, or Skyrim.Net release.

## CHANGELOG

See [GitHub Releases](https://github.com/s709gaming/MMESkyrimNetBridge/releases) for version history and detailed changes.
