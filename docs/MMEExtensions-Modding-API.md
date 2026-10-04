# MME Extensions Modding API

This document describes the stable Papyrus entry points and ModEvents intended
for other Skyrim mods. The current API version is **11**.

Use `MMEExtensionsAPI.psc`. Do not call `MMEDebug`, `MMENewMilkMaid`,
`MMEOStimBreastfeeding`, or the Skyrim.Net bridge scripts directly. Those are
internal implementation details and may change while the public API remains
compatible.

## Framework naming

API names are deliberately explicit:

- A function with **OStim** in its name is OStim-only.
- A function without a framework name is backend-neutral and does not promise
  OStim, SexLab, or any other scene framework.
- The API does not expose a generic backend-neutral breastfeeding starter.
  It exposes the proven OStim service directly and labels it accordingly.

The breastfeeding lifecycle events are backend-neutral. Their `backend`
argument reports which implementation produced the event. Version 1 emits
`"OStim"`.

## Requirements

- Skyrim Script Extender (SKSE)
- PapyrusUtil/JContainers requirements already required by MME Extensions
- Milk Mod Economy for Milk Maid queries and creation
- OStim 7.2 or newer only when using the OStim-only breastfeeding calls

Compile against the shipped `Source/Scripts/MMEExtensionsAPI.psc`. At runtime,
check `GetAPIVersion()` before depending on features introduced by a later API.

## Public functions

### GetAPIVersion

```papyrus
Int version = MMEExtensionsAPI.GetAPIVersion()
```

Returns `10` for this release.

### IsMilkMaid

```papyrus
Bool registered = MMEExtensionsAPI.IsMilkMaid(targetActor)
```

Backend-neutral. Returns whether the actor is currently registered as an MME
Milk Maid. `None` returns false. This is a registration query, not a general
actor-availability or scene-safety check.

### Story popups

API version 8 provides backend-neutral access to the same large, game-pausing
story presentation used by MME's Living/Parasite and Lactacid sequences. These
functions only present text. They do not start animations, narration, sounds,
milking, or Milk Maid conversion.

```papyrus
Bool shown = MMEExtensionsAPI.ShowStoryPopup(
    targetActor,
    "A strange warmth spreads through {ActorName}."
)
```

`targetActor` supplies the name used for `{actor}` and `{ActorName}`. It may be
the player or an NPC, but the story box is always shown to the player. `true`
means valid text was submitted to Skyrim's message box; Skyrim does not expose
whether or when the player dismissed it.

Data-driven integrations can select a random entry from a PapyrusUtil typed
`stringList` pool:

```papyrus
Bool shown = MMEExtensionsAPI.ShowRandomStoryPopup(
    targetActor,
    "/MyMod/Stories",
    "transformation_start",
    "Something strange happens to {ActorName}."
)
```

The corresponding `SKSE/Plugins/StorageUtilData/MyMod/Stories.json` structure
is:

```json
{
  "stringList": {
    "transformation_start": [
      "Magic gathers around {ActorName}.",
      "{actor} feels an unfamiliar power awakening."
    ]
  }
}
```

The optional fallback is displayed when the file is missing or malformed, the
pool is absent or empty, or the selected entry is blank. Without a usable pool
or fallback, the function returns `false`. Configuration failures use MME
Extensions' smoke-alarm trace, while ordinary successful activity is logged
only when the master Papyrus logging toggle is enabled. Callers remain
responsible for their own feature toggle, timing, and eligibility checks.

### First armor introduction

API version 9 adds a backend-neutral, one-time presentation for Living Armor
(`2`), Living Parasite/Tentacle Armor (`3`), and Dwemer Armor (`4`). It uses
the configured story pool, shared high reaction sound, and safe kneeling
animation. It does not create or register a Milk Maid.

```papyrus
Bool completed = MMEExtensionsAPI.TryFirstArmorIntroduction(targetActor, equippedArmor)
Bool alreadySeen = MMEExtensionsAPI.HasSeenArmorIntroduction(targetActor, 4)
Bool reset = MMEExtensionsAPI.ResetArmorIntroduction(targetActor, 4)
```

`TryFirstArmorIntroduction` validates and classifies the supplied armor. It
returns `false` for unsupported armor, an already-seen actor/category pair, or
when combat, restraint, another scene, or another MME Extensions animation
owns the actor. A blocked request is not marked and can be retried later. A
successful request is latent for approximately ten seconds while it owns and
then safely releases the presentation animation.

Automatic equip handling invokes this sequence only for the player because a
story popup pauses the player's game even when its subject is an NPC. Other
mods may explicitly call the API for an NPC when that global pause is desired.
Completion is stored per actor and category. `ResetArmorIntroduction` clears
only the requested category, which is useful for controlled replay or testing.

The editable pools are in
`SKSE/Plugins/StorageUtilData/MMEAlerts/ArmorIntroductionStories.json`:

- `living_first_equip`
- `parasite_first_equip`
- `dwemer_first_equip`

Ordinary lifecycle footprints use the master Papyrus logging toggle. Missing
or malformed story data and an unresolved sound record use the established
smoke-alarm trace.

### Timed armor bonds

API version 10 provides a reusable, standalone chest-armor lock. It does not
depend on Devious Devices. The built-in FOMOD catalogs cover the six C5Kev
Living/Parasite cuirasses and the unenchanted Dwarven Devious Cuirass; other
mods can register exact forms at runtime.

```papyrus
Bool added = MMEExtensionsAPI.RegisterTimedArmor("MyArmor.esp", 0x812, 2)
Bool locked = MMEExtensionsAPI.TryLockTimedArmor(targetActor, targetArmor)
Float daysLeft = MMEExtensionsAPI.GetTimedArmorDaysRemaining(targetActor)
Armor lockedArmor = MMEExtensionsAPI.GetTimedLockedArmor(targetActor)
Bool isLocked = MMEExtensionsAPI.IsTimedArmorLocked(targetActor)
Bool released = MMEExtensionsAPI.ReleaseTimedArmor(targetActor)
Bool removed = MMEExtensionsAPI.UnregisterTimedArmor("MyArmor.esp", 0x812)
```

`RegisterTimedArmor` requires a resolvable slot-32 `Armor` form and saves it to
`SKSE/Plugins/StorageUtilData/MMEAlerts/TimedArmorRegistry.json` immediately.
`armorClass` uses the custom-registry values `1` through `4` and is retained
for compatibility metadata. Registration alone does not equip or classify the
armor; it opts that exact form into automatic timed protection when equipped.

`TryLockTimedArmor` accepts an optional duration in game days. A negative value
uses the user's MCM value (default `3`, range `0` through `30`). The actor can
own only one timed chest lock. During the bond, MME Extensions re-equips the
piece after an external removal and suppresses its own armor-strip route. A
resisted player removal displays a random editable line from
`TimedArmorNotifications.json` instead of using Skyrim's generic hard-lock
message. The
player receives a visible **Special Armor Bond** Active Effect; NPC state is
tracked without adding a visible spell. `ReleaseTimedArmor` is also the public
hook for future blacksmith or quest-based removal mechanics.

Normal lifecycle footprints obey the master Papyrus logging toggle. Missing
records, malformed installed catalogs, failed protection, and failed release
use the smoke-alarm channel.

### Custom armor registry

API version 6 adds an unlimited, persistent compatibility registry for armor
that should behave like MME equipment without consuming one of MME's ten
array entries. Categories are:

- `1`: Milking Armor
- `2`: Living Armor
- `3`: Living Parasite
- `4`: Dwemer Armor

```papyrus
Int armorClass = MMEExtensionsAPI.GetArmorClass(targetArmor)
Bool added = MMEExtensionsAPI.RegisterCustomArmor("MyArmor.esp", 0x812, 2)
Bool removed = MMEExtensionsAPI.UnregisterCustomArmor("MyArmor.esp", 0x812, 2)
```

`RegisterCustomArmor` and `UnregisterCustomArmor` use a plugin-local FormID,
the same ID expected by `Game.GetFormFromFile`; do not pass a load-order
prefix. Registration is saved immediately to
`SKSE/Plugins/StorageUtilData/MMEAlerts/CustomArmorRegistry.json` and survives
save changes because it is a mod-level compatibility setting. A form can be in
only one custom category. Both functions return `false` for invalid input,
unresolved/not-found forms, duplicates, or a failed save.

The four custom-only queries distinguish this registry from MME's built-in
forms and arrays:

```papyrus
Bool milkArmor = MMEExtensionsAPI.IsCustomMilkArmor(targetArmor)
Bool livingArmor = MMEExtensionsAPI.IsCustomLivingArmor(targetArmor)
Bool parasiteArmor = MMEExtensionsAPI.IsCustomParasiteArmor(targetArmor)
Bool dwemerArmor = MMEExtensionsAPI.IsCustomDwemerArmor(targetArmor)
```

For integrations that cannot know a form identity in advance, broad display
name fallbacks are also available:

```papyrus
Bool added = MMEExtensionsAPI.RegisterCustomArmorName("Example Living Armor", 2)
Bool removed = MMEExtensionsAPI.UnregisterCustomArmorName("Example Living Armor", 2)
```

Exact-form registration is strongly preferred. A display name can be shared
by unrelated records or changed by another mod or translation.

API version 11 adds reversible, form-oriented Dwemer attachment helpers:

```papyrus
Bool installed = MMEExtensionsAPI.InstallDwemerAttachment(targetArmor)
Bool attached = MMEExtensionsAPI.HasDwemerAttachment(targetArmor)
Bool removed = MMEExtensionsAPI.RemoveDwemerAttachment(targetArmor)
```

These helpers use the dedicated `dwemer_artisan_names` list. Removal can only
delete entries installed through this attachment API; it cannot unregister
built-in or third-party exact-form Dwemer support. Identity is based on the
armor's display name, so unrelated records with the same translated name are
treated as one attachment. `InstallDwemerAttachment` rejects armor already
recognized by any MME Extensions armor category.

On equip, a custom entry follows its matching behavior: it can
register the wearer as a Milk Maid, and Living/Parasite armor applies MME's
living-armor passive and minimum Lactacid state. On unequip, the passive is
removed only after no other recognized Living/Parasite armor remains worn.
Original MME classifications always win, preventing duplicate effects.

Dwemer Armor is deliberately independent. It does not receive the Living or
Parasite passive, narration, or Thoughts behavior. Blacksmith conversations
may show its compact armor-reminder wording on the shared service-reminder
cooldown. Its
dedicated system checks MME's authoritative maximum capacity after production
cycles and automatically invokes MME's external milking route at 90 percent.

Users may also edit the JSON directly. Exact entries use this format, with the
third field serving only as a readable label:

```json
"DwarvenDeviousCuirass.esp|2048|Dwarven Devious Cuirass"
```

The shipped defaults classify only the unenchanted Dwarven Devious Cuirass
record (`0x800`) as Dwemer Armor. The enchanted `0x80A` record is unsupported.
Compatibility is inert when that plugin is absent and does not require Devious Devices. Normal registry activity is logged
only when the master Papyrus logging toggle is enabled; malformed configuration
or failed persistence uses the existing always-on smoke-alarm logging path.

### IsOStimBreastfeedingAvailable

```papyrus
Bool available = MMEExtensionsAPI.IsOStimBreastfeedingAvailable()
```

**OStim-only.** Returns true when MME Extensions is enabled, OStim is detected,
the installed OStim version is supported, and the OStim Breastfeeding MCM option
is enabled.

### StartOStimBreastfeeding

```papyrus
Bool accepted = MMEExtensionsAPI.StartOStimBreastfeeding(milkSource, drinker)
```

**OStim-only.** `milkSource` supplies the breast and `drinker` receives the
milk. The actors must be different, valid, available, and compatible with the
selected OStim scene.

`true` means synchronous validation passed and OStim returned a thread ID. It
does not mean the scene has started or completed. Observe the breastfeeding
lifecycle events below for asynchronous results.

`false` means the request was rejected before an OStim thread was accepted. No
lifecycle event is sent for an immediate synchronous rejection.

### RequestMilkMaidCreation

```papyrus
MMEExtensionsAPI.RequestMilkMaidCreation(targetActor)
```

Backend-neutral gameplay request. It uses MME's native Lactacid conversion
effect for validation, slot assignment, initialization, and MME's original
reaction animation. It does not start an OStim or SexLab scene.

The function intentionally has no Boolean return. Treat it as a request and
listen for `MMEExtensions_MilkmaidCreated` to confirm success. MME Extensions
also displays the established rejection reason when the target is ineligible.

There is no animation-free creation API. MME owns the creation
animation and registration in the same native transaction; bypassing it would
risk an incomplete Milk Maid registration.

### TryCreateMilkMaidForcedAnimated

```papyrus
Bool created = MMEExtensionsAPI.TryCreateMilkMaidForcedAnimated(targetActor)
```

Backend-neutral, forced gameplay transaction introduced in API version 2. It
supports the player or an eligible adult female NPC. It bypasses MME's NPC
Yes/No confirmation while retaining MME's localized assignment message,
authoritative slot and progression-capacity checks, initial Lactacid state,
and original ten-second `ZaZAPCHorFd` reaction sequence. Player calls can also
show MME's original game-pausing Lactacid story boxes. After a successful call,
MME Extensions selects one editable line from
`ForcedMilkMaidConversion.json`, uses it for the local notification, and sends
the same context to the dedicated Skyrim.Net forced narration route. Each
feedback channel has an MCM toggle; the API's conversion result never depends
on Skyrim.Net being installed or accepting the narration request.

This is a latent call. It returns only after conversion and animation cleanup.
`true` means registration and initialization succeeded and the animation
completed. `false` means the actor was ineligible, animation was unsafe, MME
had no available slot, or initialization failed. A failed capacity or safety
check does not partially convert the actor. Successful calls also publish
`MMEExtensions_MilkmaidCreated`.

### ForceMilkDrink

```papyrus
Bool consumed = MMEExtensionsAPI.ForceMilkDrink(targetActor, milkItem)
```

Backend-neutral forced inventory transaction introduced in API version 3.
`milkItem` must be an MME milk (including exotic milk), MME Lactacid, or the
HearthFires Jug of Milk. The function stages exactly one temporary item and
equips it, allowing MME and MME Extensions' ordinary drink observers to remain
authoritative for gameplay effects. It never removes an item the actor already
owned.

This is a short latent call. `true` means the staged item was consumed;
`false` means validation, staging, or consumption failed and any staged item
was removed. It does not promise a particular animation or Milk Maid outcome.
The actor must be a loaded, living, conscious adult humanoid. Successful calls
publish `MMEExtensions_ForcedMilkDrinkCompleted`.

### DrinkNormalMilk

```papyrus
Bool consumed = MMEExtensionsAPI.DrinkNormalMilk(targetActor)
```

Convenience wrapper introduced in API version 3. It supplies the HearthFires
Jug of Milk to the same transaction used by `ForceMilkDrink`, so callers do not
need to resolve or ship a milk form. It has the same actor validation, latent
return behavior, normal drink processing, cleanup guarantees, and
`MMEExtensions_ForcedMilkDrinkCompleted` event. The event's `drinkKind` is `3`.

### GiveAvailableMilk

```papyrus
Bool consumed = MMEExtensionsAPI.GiveAvailableMilk(giverActor, drinkerActor)
```

Backend-neutral, inventory-backed actor-to-actor transaction introduced in API
version 4. The giver and drinker may be the player or eligible adult NPCs, but
must be two different loaded actors outside combat. The function selects one
item the giver actually owns using the established Give Milk priority:

1. normal milk (HearthFires Jug or MME basic milk);
2. racial milk;
3. supernatural milk.

This is category priority, not a dynamic comparison of gold value or magic
effect strength. Within an MME FormList, the first owned entry wins. Lactacid
is deliberately excluded.

If the giver owns no eligible milk, the existing **Free Jug for Give Milk** MCM
setting controls fallback behavior. When enabled, the transaction supplies and
consumes one temporary HearthFires Jug; when disabled, it returns `false`
without changing inventory. Transfer and failed-consumption paths roll back the
selected item. A successful latent call includes the established give/drink
animations where safe, ordinary drink effects and feedback, and publishes
`MMEExtensions_AvailableMilkGiven`.

### TryMilkArmorThought

```papyrus
Bool shown = MMEExtensionsAPI.TryMilkArmorThought(targetActor)
```

Backend-neutral presentation request introduced in API version 5. It runs the
existing periodic Milk Armor Thought pipeline for exactly `targetActor` rather
than scanning for and randomly choosing a nearby Milk Maid. The actor's live
milk fullness and worn body armor choose the existing editable JSON pool. A
successful call uses the same HUD notification, configured reaction sound, and
optional Skyrim.Net narration as the scheduled feature.

The automatic Thought interval and actor selection are bypassed. The Milk
Armor Thoughts feature must be enabled, and the target must be a loaded valid
MME Milk Maid. `true` means a complete Thought was rendered and shown; it does
not mean Skyrim.Net necessarily accepted narration.

### TryHeavyRestraintReaction

```papyrus
Bool shown = MMEExtensionsAPI.TryHeavyRestraintReaction(targetActor)
```

Backend-neutral presentation request introduced in API version 5. It runs the
existing Devious heavy-restraint Thought pipeline for exactly `targetActor`,
including its editable JSON line, HUD notification, configured hot reaction
sound, and optional Skyrim.Net narration.

The automatic enable switch, interval, random actor selection, and scheduled
Bound Thought chance are bypassed. MME Extensions must be enabled, Devious
Devices' `zad_DeviousHeavyBondage` keyword must be available, and the target
must be a loaded MME Milk Maid currently wearing an item with that keyword.
`true` means the local Thought was rendered and shown; narration may still be
disabled, rejected, or fail its own configured narration chance.

### TryLivingArmorEffect

```papyrus
Bool applied = MMEExtensionsAPI.TryLivingArmorEffect(targetActor)
```

Backend-neutral gameplay request introduced in API version 5. It runs the
existing Tentacle Effects pipeline for one target instead of scanning a nearby
group. The call validates current Living or Parasite Armor, applies the
configured milk and arousal effects, and reuses the existing HUD notification,
reaction sound, and optional Skyrim.Net narration.

The periodic interval and Injection Chance are bypassed. Tentacle Effects must
be enabled, and the target must be a loaded valid MME Milk Maid wearing a
supported Living or Parasite Armor. `true` means the eligible effect pipeline
ran; individual milk, arousal, sound, and narration channels retain their own
settings and availability checks.

### TryArmorStrippingCheck

```papyrus
Bool stripped = MMEExtensionsAPI.TryArmorStrippingCheck(targetActor)
```

Backend-neutral gameplay request introduced in API version 5. It immediately
runs the same fullness-based evaluator used by periodic polling and delayed
post-drink checks. It reads the target's current milk, threshold, and slot 32
armor. A verified removal reuses the existing notification, hot reaction
sound, and optional Skyrim.Net narration.

Armor Stripping must be enabled. MME armor protections, Devious Devices checks,
SexLab no-strip rules, configured thresholds, and engine verification remain
authoritative. `true` means slot 32 armor was actually removed; `false` includes
safe rejection, insufficient fullness, protected equipment, and unavailable
actors.

## Timed armor lifecycle events

The timed armor service publishes these events:

- `MMEExtensions_TimedArmorLocked`
- `MMEExtensions_TimedArmorReequipped`
- `MMEExtensions_TimedArmorReleased`
- `MMEExtensions_TimedArmorFailed`

Every event uses this exact payload order:

1. `Form actor`
2. `Form armor`
3. `Float days` — configured duration when locked, remaining duration when
   re-equipped, and `0.0` on release/failure where no duration applies
4. `String source` — for example `Automatic Equip`, `Public API`,
   `Timer Expired`, or a concise failure reason

Register again from `OnPlayerLoadGame`, as with all SKSE ModEvents. A
`TimedArmorReequipped` event means an early removal was resisted, not that a
new lock began. A `TimedArmorFailed` event is exceptional and should not be
used as the normal expiration signal.

## Available milk transaction event

```text
MMEExtensions_AvailableMilkGiven
```

Published once after `GiveAvailableMilk` verifies consumption and finishes its
owned animations. Payload order is stable:

1. `Form giver`
2. `Form drinker`
3. `Form milkItem`
4. `Int fallbackSupplied` (`1` for the temporary HearthFires Jug, otherwise `0`)

## Forced milk drink event

```text
MMEExtensions_ForcedMilkDrinkCompleted
```

Published once after `ForceMilkDrink` verifies that the temporary item was
consumed. Payload order is stable:

1. `Form drinker`
2. `Form milkItem`
3. `Int drinkKind` (`1` MME milk, `2` Lactacid, `3` HearthFires milk)

This event reports the public API transaction. Separately,
`MMEAlerts_DrinkDetected` continues to report ordinary completed drink
processing where applicable; integrations should not treat both events as one
combined stream without deduplication.

## Existing Milk Maid creation event

The existing event remains unchanged for compatibility:

```text
MMEExtensions_MilkmaidCreated
```

Payload, in order:

1. `Form createdActor`

Example listener:

```papyrus
; Attach this example to a player ReferenceAlias so OnPlayerLoadGame is valid.
Scriptname MyMMEIntegration extends ReferenceAlias

Event OnInit()
    RegisterForModEvent("MMEExtensions_MilkmaidCreated", "OnMMEMilkmaidCreated")
EndEvent

Event OnPlayerLoadGame()
    RegisterForModEvent("MMEExtensions_MilkmaidCreated", "OnMMEMilkmaidCreated")
EndEvent

Event OnMMEMilkmaidCreated(Form createdActor)
    Actor newMilkMaid = createdActor as Actor
    If newMilkMaid != None
        Debug.Trace("My Mod: confirmed new Milk Maid " + newMilkMaid.GetDisplayName())
    EndIf
EndEvent
```

## Breastfeeding lifecycle events

All lifecycle events originate from the persistent scene service. They are not
Skyrim.Net-specific and are emitted at most once per stage and request.

### MMEExtensions_BreastfeedingRequestAccepted

An OStim thread ID was returned and the asynchronous startup check was armed.

### MMEExtensions_BreastfeedingStarted

The scene is running and MME Extensions confirmed ownership of the exact actor
pair and manual OStim thread.

### MMEExtensions_BreastfeedingCompleted

The owned scene ended normally. Any route-specific completion work is performed
before the terminal event is published.

### MMEExtensions_BreastfeedingAborted

An accepted request did not complete normally—for example, startup timed out,
the scene changed ownership, another integration enabled auto mode, or a stale
saved session could not be recovered.

The first three events have this exact payload order:

1. `Form milkSource`
2. `Form drinker`
3. `String backend`
4. `Int requestID`

The aborted event adds:

5. `String reason`

`requestID` correlates stages within the current save. Do not treat it as a
globally unique identifier or persist it across a new game.

Example listener:

```papyrus
; Attach this example to a player ReferenceAlias so OnPlayerLoadGame is valid.
Scriptname MyMMEBreastfeedingListener extends ReferenceAlias

Event OnInit()
    RegisterMMEExtensionsEvents()
EndEvent

Event OnPlayerLoadGame()
    ; SKSE ModEvent registrations must be refreshed after loading a save.
    RegisterMMEExtensionsEvents()
EndEvent

Function RegisterMMEExtensionsEvents()
    RegisterForModEvent("MMEExtensions_BreastfeedingStarted", "OnMMEBreastfeedingStarted")
    RegisterForModEvent("MMEExtensions_BreastfeedingCompleted", "OnMMEBreastfeedingCompleted")
    RegisterForModEvent("MMEExtensions_BreastfeedingAborted", "OnMMEBreastfeedingAborted")
EndFunction

Event OnMMEBreastfeedingStarted(Form sourceForm, Form drinkerForm, String backend, Int requestID)
    Actor milkSource = sourceForm as Actor
    Actor drinker = drinkerForm as Actor
    Debug.Trace("My Mod: breastfeeding started via " + backend + " request " + requestID)
EndEvent

Event OnMMEBreastfeedingCompleted(Form sourceForm, Form drinkerForm, String backend, Int requestID)
    Debug.Trace("My Mod: breastfeeding completed via " + backend + " request " + requestID)
EndEvent

Event OnMMEBreastfeedingAborted(Form sourceForm, Form drinkerForm, String backend, Int requestID, String reason)
    Debug.Trace("My Mod: breastfeeding aborted via " + backend + " request " + requestID + " | " + reason)
EndEvent
```

## Lifecycle sequence

Successful request:

```text
StartOStimBreastfeeding returns true
  -> BreastfeedingRequestAccepted
  -> BreastfeedingStarted
  -> BreastfeedingCompleted
```

Accepted request that later fails:

```text
StartOStimBreastfeeding returns true
  -> BreastfeedingRequestAccepted
  -> optional BreastfeedingStarted
  -> BreastfeedingAborted
```

Immediate rejection:

```text
StartOStimBreastfeeding returns false
  -> no lifecycle event
```

## Compatibility policy

- Existing API version 1 function names and parameter meanings will not be
  silently repurposed.
- Existing event names, payload types, and payload order will remain stable.
- New functions and events may be added without increasing the major API
  version when existing contracts remain compatible.
- Breaking changes require a new API version and new event names.
- Public calls still obey the user's MCM settings and normal safety checks.
