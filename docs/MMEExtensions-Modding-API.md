# MME Extensions Modding API

This document describes the stable Papyrus entry points and ModEvents intended
for other Skyrim mods. The current API version is **1**.

Use `MMEExtensionsAPI.psc`. Do not call `MMEDebug`, `MMENewMilkMaid`,
`MMEOStimBreastfeeding`, or the Skyrim.Net bridge scripts directly. Those are
internal implementation details and may change while the public API remains
compatible.

## Framework naming

API names are deliberately explicit:

- A function with **OStim** in its name is OStim-only.
- A function without a framework name is backend-neutral and does not promise
  OStim, SexLab, or any other scene framework.
- API version 1 does not expose a generic backend-neutral breastfeeding starter.
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

Returns `1` for this release.

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

There is no animation-free creation API in version 1. MME owns the creation
animation and registration in the same native transaction; bypassing it would
risk an incomplete Milk Maid registration.

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
