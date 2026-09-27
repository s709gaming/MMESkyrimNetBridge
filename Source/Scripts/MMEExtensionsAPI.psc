Scriptname MMEExtensionsAPI Hidden

; =============================================================================
; MME Extensions public Papyrus API (version 1)
; =============================================================================
; This is the stable entry point for other mods. Call these wrappers instead
; of MMEDebug, MMENewMilkMaid, MMEOStimBreastfeeding, or other internal scripts.
;
; IMPORTANT BACKEND LABELING
; - A function containing "OStim" is OStim-only.
; - Functions without a framework name are not promises about any one scene
;   framework. Version 1 intentionally exposes no generic scene-start function.
;
; Async calls return when a request is accepted, not when its scene or gameplay
; transaction finishes. Listen for the documented ModEvents to observe results.

Int Function GetAPIVersion() Global
    Return 1
EndFunction

; Backend-neutral query. Returns true only for a current, authoritative MME
; Milk Maid registration. This does not depend on Skyrim.Net or OStim.
Bool Function IsMilkMaid(Actor target) Global
    Return MMEArmorScript.IsMMEMilkMaid(target)
EndFunction

; OStim-only availability query. True means OStim is detected, supported, and
; the MCM option required by StartOStimBreastfeeding is enabled.
Bool Function IsOStimBreastfeedingAvailable() Global
    Return MMEOStimBreastfeeding.IsBreastfeedingEnabled() && MMEOStimIntegration.IsSupportedVersion()
EndFunction

; OStim-only request. milkSource supplies the breast; drinker receives milk.
; True means the request passed synchronous validation and OStim returned a
; thread ID. It does not mean the scene has started or completed. Observe:
;   MMEExtensions_BreastfeedingRequestAccepted
;   MMEExtensions_BreastfeedingStarted
;   MMEExtensions_BreastfeedingCompleted
;   MMEExtensions_BreastfeedingAborted
Bool Function StartOStimBreastfeeding(Actor milkSource, Actor drinker) Global
    Return MMEOStimBreastfeeding.StartSharedBreastfeeding(milkSource, drinker, "Public API")
EndFunction

; Backend-neutral gameplay request. Uses MME's native Lactacid creation path,
; including MME's original registration, initialization, and reaction animation.
; Completion is asynchronous from the caller's perspective. Listen for the
; existing actor-only MMEExtensions_MilkmaidCreated event to confirm success.
Function RequestMilkMaidCreation(Actor target) Global
    MMENewMilkMaid.MakeTargetNewMilkMaid(target)
EndFunction

; =============================================================================
; Internal event publishers
; =============================================================================
; These helpers keep payload order in one place. They are Global because a
; Hidden Papyrus script has no instance, but they are not public request APIs.
; External mods should register for the events, never call these publishers.

Bool Function PublishBreastfeedingStage(String eventName, Actor milkSource, Actor drinker, String backend, Int requestID) Global
    Int handle = ModEvent.Create(eventName)
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, milkSource)
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushString(handle, backend)
    ModEvent.PushInt(handle, requestID)
    Return ModEvent.Send(handle)
EndFunction

Bool Function PublishBreastfeedingAborted(Actor milkSource, Actor drinker, String backend, Int requestID, String reason) Global
    Int handle = ModEvent.Create("MMEExtensions_BreastfeedingAborted")
    If handle == 0
        Return False
    EndIf
    ModEvent.PushForm(handle, milkSource)
    ModEvent.PushForm(handle, drinker)
    ModEvent.PushString(handle, backend)
    ModEvent.PushInt(handle, requestID)
    ModEvent.PushString(handle, reason)
    Return ModEvent.Send(handle)
EndFunction
