# MME Extensions Modding API

This document describes the stable Papyrus entry points and ModEvents intended
for other Skyrim mods. The current API version is **5**.

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

Returns `5` for this release.

### IsMilkMaid

```papyrus
Bool registered = MMEExtensionsAPI.IsMilkMaid(targetActor)
```

Backend-neutral. Returns whether the actor is currently registered as an MME
Milk Maid. `None` returns false. This is a registration query, not a general
actor-availability or scene-safety check.

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
