Scriptname MMEAlertsController extends Quest

String SettingsFile = "/MMEAlerts/Settings"
String StateKey = "MMEAlerts.CapacityState"
String MilkingStateKey = "MMEAlerts.IsMilking"
String KnownMilkmaidKey = "MMEExtensions.KnownMilkmaid"
String PendingMilkmaidKey = "MMEExtensions.PendingMilkmaid"
Float NearbyRange = 2000.0
Float NextCapacityUpdate = 0.0
Float NextSkyrimNetUpdate = 0.0

; Quest startup registers MME events and initializes the player monitor/poller.
Event OnInit()
    InitializeController()
EndEvent

; Restores event registrations and abilities; called at startup and after load.
Function InitializeController()
    RegisterMilkingEvents()
    MMEAlertsSkyrimNet.RegisterPromptDecorator()
    UnregisterForModEvent("MMEExtensions_Lifecycle")
    RegisterForModEvent("MMEExtensions_Lifecycle", "OnNativeLifecycle")
    UnregisterForModEvent("MMEExtensions_MMEEffectApplied")
    RegisterForModEvent("MMEExtensions_MMEEffectApplied", "OnMMEEffectApplied")
    UnregisterForModEvent("MME_AddMilkMaid")
    RegisterForModEvent("MME_AddMilkMaid", "OnMMEAddMilkmaidRequested")
    UnregisterForUpdate()
    Spell monitorAbility = Game.GetFormFromFile(0x000805, "MMEAlert.esp") as Spell
    If monitorAbility != None
        ; Recreate the active effect once when its drink-tracker implementation
        ; changes. Existing saves otherwise keep the pre-tracker effect instance.
        If JsonUtil.GetIntValue(SettingsFile, "playerDrinkMonitorVersion", 0) < 12
            If Game.GetPlayer().HasSpell(monitorAbility)
                Game.GetPlayer().RemoveSpell(monitorAbility)
            EndIf
            Game.GetPlayer().AddSpell(monitorAbility, False)
            JsonUtil.SetIntValue(SettingsFile, "playerDrinkMonitorVersion", 12)
            JsonUtil.Save(SettingsFile, False)
        ElseIf !Game.GetPlayer().HasSpell(monitorAbility)
            Game.GetPlayer().AddSpell(monitorAbility, False)
        EndIf
    EndIf
    UpdatePolling()
    BaselineKnownMilkmaids()
EndFunction

; Records Milkmaids already present when this version starts to avoid false creation reports.
Function BaselineKnownMilkmaids()
    Actor playerActor = Game.GetPlayer()
    RememberMilkmaid(playerActor)
    Cell currentCell = playerActor.GetParentCell()
    If currentCell == None
        Return
    EndIf
    Int count = currentCell.GetNumRefs(43)
    Int i = 0
    While i < count
        Actor candidate = currentCell.GetNthRef(i, 43) as Actor
        If candidate != None && candidate.Is3DLoaded()
            RememberMilkmaid(candidate)
        EndIf
        i += 1
    EndWhile
EndFunction

Function RememberMilkmaid(Actor candidate)
    If IsMMEMilkMaid(candidate)
        StorageUtil.SetIntValue(candidate, KnownMilkmaidKey, 1)
    EndIf
EndFunction

; Resolves MME's configured effects instead of relying on translated display names.
Bool Function IsMilkmaidCreationEffect(Int localEffectID)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return False
    EndIf
    MagicEffect makeMaidEffect = None
    If milkController.MME_MakeMilkmaid_Spell != None
        makeMaidEffect = milkController.MME_MakeMilkmaid_Spell.GetNthEffectMagicEffect(0)
    EndIf
    Potion lactacid = milkController.MME_Util_Potions.GetAt(0) as Potion
    MagicEffect lactacidEffect = None
    If lactacid != None
        lactacidEffect = lactacid.GetNthEffectMagicEffect(0)
    EndIf
    If makeMaidEffect != None && makeMaidEffect.GetFormID() % 16777216 == localEffectID
        Return True
    EndIf
    Return lactacidEffect != None && lactacidEffect.GetFormID() % 16777216 == localEffectID
EndFunction

; Receives filtered MME magic-effect applications from the CommonLib bridge.
Event OnMMEEffectApplied(String eventName, String pluginName, Float localEffectForm, Form sender)
    Actor candidate = sender as Actor
    If candidate == None || !IsMilkmaidCreationEffect(localEffectForm as Int)
        Return
    EndIf
    CheckMilkmaidCreation(candidate, "MME effect")
EndEvent

; Adds coverage for third-party mods using MME's public creation request.
Event OnMMEAddMilkmaidRequested(Form sender)
    CheckMilkmaidCreation(sender as Actor, "MME_AddMilkMaid")
EndEvent

; Waits for MME, validates a real false-to-true transition, and publishes it once.
Function CheckMilkmaidCreation(Actor candidate, String source)
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableMilkmaidCreationDiagnostic", 1) == 1
    If candidate == None
        If diagnostic
            Debug.Notification("Milkmaid Creation: failed - actor missing")
        EndIf
        Return
    EndIf
    If StorageUtil.GetIntValue(candidate, KnownMilkmaidKey, 0) == 1
        If diagnostic
            Debug.Notification("Milkmaid Creation: " + GetActorName(candidate) + " was already a Milkmaid")
        EndIf
        Return
    EndIf
    If StorageUtil.GetIntValue(candidate, PendingMilkmaidKey, 0) == 1
        Return
    EndIf
    StorageUtil.SetIntValue(candidate, PendingMilkmaidKey, 1)
    If diagnostic
        Debug.Notification("Milkmaid Creation: detected " + source + " on " + GetActorName(candidate))
    EndIf
    Utility.Wait(1.5)
    StorageUtil.UnsetIntValue(candidate, PendingMilkmaidKey)
    If !IsMMEMilkMaid(candidate)
        If diagnostic
            Debug.Notification("Milkmaid Creation: conversion failed for " + GetActorName(candidate))
        EndIf
        Return
    EndIf
    StorageUtil.SetIntValue(candidate, KnownMilkmaidKey, 1)
    If diagnostic
        Debug.Notification("MME Extensions - " + GetActorName(candidate) + " is a new Milkmaid!")
    EndIf
    MMEAlertsSkyrimNet.SendMilkmaidCreated(candidate)
    Int handle = ModEvent.Create("MMEExtensions_MilkmaidCreated")
    If handle
        ModEvent.PushForm(handle, candidate)
        ModEvent.Send(handle)
    EndIf
EndFunction

; Receives low-cost lifecycle signals from the optional CommonLibSSE-NG DLL.
Event OnNativeLifecycle(String eventName, String reason, Float numArg, Form sender)
    RefreshCapacity(reason)
    If JsonUtil.GetIntValue(SettingsFile, "enableLifecycleDiagnostic", 0) == 1
        Debug.Notification("MME Extensions: detected " + reason)
        Debug.Trace("[MME Extensions Lifecycle] detected " + reason)
        ShowDebugCapacitySnapshot()
    EndIf
EndEvent

; Subscribes to MME's global events; requires PapyrusUtil ModEvent support.
Function RegisterMilkingEvents()
    ; MME emits these events for every actor, regardless of which animation
    ; variant or milking device is in use.
    UnregisterForModEvent("MilkQuest.StartMilkingMachine")
    UnregisterForModEvent("MilkQuest.StopMilkingMachine")
    UnregisterForModEvent("MME_MilkingDone")
    RegisterForModEvent("MilkQuest.StartMilkingMachine", "OnMMEMilkingStart")
    RegisterForModEvent("MilkQuest.StopMilkingMachine", "OnMMEMilkingStop")
    RegisterForModEvent("MME_MilkingDone", "OnMMEMilkingDone")
EndFunction

; Accepts only loaded MME Milk Maids within the fixed local reaction radius.
Bool Function IsNearbyMilkMaid(Actor candidate)
    If !IsMMEMilkMaid(candidate) || !candidate.Is3DLoaded()
        Return False
    EndIf
    Return Game.GetPlayer().GetDistance(candidate) <= NearbyRange
EndFunction

; Handles MME's authoritative start broadcast and suppresses duplicate starts.
Event OnMMEMilkingStart(Form actorForm, Int animationSpeed, Int milkingType)
    Actor milkMaid = actorForm as Actor
    If !IsNearbyMilkMaid(milkMaid)
        Return
    EndIf
    ; MME can repeat stage events, so only react to the first start for an actor.
    If StorageUtil.GetIntValue(milkMaid, MilkingStateKey, 0) == 1
        Return
    EndIf
    StorageUtil.SetIntValue(milkMaid, MilkingStateKey, 1)
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1) == 1
        Debug.Notification("MME Alerts - MILKING START: " + GetActorName(milkMaid))
        Debug.Trace("[MMEAlert] MILKING START: " + GetActorName(milkMaid))
    EndIf
    PlayMilkingReaction(milkMaid, True)
    MMEAlertsSkyrimNet.SendMilkingStart(milkMaid)
    PublishMilkingEvent("MMEAlerts_MilkingStart", milkMaid)
EndEvent

; Handles MME's animation-adjacent stop broadcast for timely ending audio.
Event OnMMEMilkingStop(Form actorForm, Int animationSpeed, Int milkingType)
    Actor milkMaid = actorForm as Actor
    FinishMilking(milkMaid)
EndEvent

; Provides an authoritative completion fallback if the earlier stop was missed.
Event OnMMEMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    ; Completion is a fallback when MME's earlier stop event was missed. The
    ; per-actor state prevents the normal stop/done pair from playing twice.
    Actor milkMaid = actorForm as Actor
    FinishMilking(milkMaid)
EndEvent

; Clears per-actor session state and emits one nearby end reaction at most.
Function FinishMilking(Actor milkMaid)
    If milkMaid == None || StorageUtil.GetIntValue(milkMaid, MilkingStateKey, 0) != 1
        Return
    EndIf
    StorageUtil.UnsetIntValue(milkMaid, MilkingStateKey)
    If IsNearbyMilkMaid(milkMaid)
        If JsonUtil.GetIntValue(SettingsFile, "enableMilkingEventDebug", 1) == 1
            Debug.Notification("MME Alerts - MILKING END: " + GetActorName(milkMaid))
            Debug.Trace("[MMEAlert] MILKING END: " + GetActorName(milkMaid))
        EndIf
        PlayMilkingReaction(milkMaid, False)
        MMEAlertsSkyrimNet.SendMilkingEnd(milkMaid)
        PublishMilkingEvent("MMEAlerts_MilkingEnd", milkMaid)
    EndIf
EndFunction

; Plays the ESP-defined Hot start or Mild end pool using shared MCM settings.
Function PlayMilkingReaction(Actor sourceActor, Bool starting)
    If JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) != 1 || JsonUtil.GetIntValue(SettingsFile, "enableMilkingMoans", 1) != 1
        Return
    EndIf
    Int localFormID = 0x000854 ; Mild/low SOUN marker for completion
    If starting
        localFormID = 0x000856 ; Hot SOUN marker for start
    EndIf
    Sound reaction = Game.GetFormFromFile(localFormID, "MMEAlert.esp") as Sound
    If reaction == None
        Debug.Trace("[MMEAlert] milking sound marker did not resolve: " + localFormID)
        Return
    EndIf
    Int instance = reaction.Play(sourceActor)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0) / 100.0)
    Else
        Debug.Trace("[MMEAlert] milking Sound.Play returned " + instance)
    EndIf
EndFunction

; Publishes a stable actor-only event for the future native/SkyrimNet bridge.
Function PublishMilkingEvent(String eventName, Actor milkMaid)
    ; Stable handoff point for the future native/SkyrimNet bridge.
    Int handle = ModEvent.Create(eventName)
    If handle
        ModEvent.PushForm(handle, milkMaid)
        ModEvent.Send(handle)
    EndIf
EndFunction

; Synchronizes optional capacity polling with its persisted MCM toggle.
Function UpdatePolling()
    UnregisterForUpdate()
    Float now = Utility.GetCurrentRealTime()
    If JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1) == 1
        NextCapacityUpdate = now + JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 15.0)
    Else
        NextCapacityUpdate = 0.0
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1) == 1
        NextSkyrimNetUpdate = now + JsonUtil.GetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
    Else
        NextSkyrimNetUpdate = 0.0
    EndIf
    ScheduleNextUpdate()
EndFunction

Function ScheduleNextUpdate()
    Float now = Utility.GetCurrentRealTime()
    Float delay = 0.0
    If NextCapacityUpdate > 0.0
        delay = NextCapacityUpdate - now
    EndIf
    If NextSkyrimNetUpdate > 0.0 && (delay <= 0.0 || NextSkyrimNetUpdate - now < delay)
        delay = NextSkyrimNetUpdate - now
    EndIf
    If delay > 0.0
        If delay < 1.0
            delay = 1.0
        EndIf
        RegisterForSingleUpdate(delay)
    EndIf
EndFunction

; Services independent local-capacity and SkyrimNet status schedules.
Event OnUpdate()
    Float now = Utility.GetCurrentRealTime()
    Bool capacityDue = NextCapacityUpdate > 0.0 && now >= NextCapacityUpdate
    Bool skyrimNetDue = NextSkyrimNetUpdate > 0.0 && now >= NextSkyrimNetUpdate
    If capacityDue || skyrimNetDue
        ScanNearbyMilkMaids(skyrimNetDue, capacityDue)
    EndIf
    If capacityDue
        NextCapacityUpdate = now + JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 15.0)
    EndIf
    If skyrimNetDue
        NextSkyrimNetUpdate = now + JsonUtil.GetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
    EndIf
    ScheduleNextUpdate()
EndEvent

; Lets player lifecycle events request an immediate capacity rescan.
Function RefreshCapacity(String reason = "event")
    ScanNearbyMilkMaids(False, True)
EndFunction

; Validates MME membership through its StorageUtil level key.
Bool Function IsMMEMilkMaid(Actor candidate)
    If candidate == None || candidate.IsDead() || candidate.IsDisabled()
        Return False
    EndIf
    Return StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.Level")
EndFunction

; Resolves a safe actor display name for notifications and diagnostics.
String Function GetActorName(Actor candidate)
    String actorName = candidate.GetDisplayName()
    If actorName == ""
        ActorBase baseActor = candidate.GetLeveledActorBase()
        If baseActor != None
            actorName = baseActor.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "This Milk Maid"
    EndIf
    Return actorName
EndFunction

; Formats current milk capacity for the optional debug snapshot.
String Function EvaluateMilkMaid(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        Return ""
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return GetActorName(candidate) + ": invalid maximum"
    EndIf
    Float current = MME_Storage.getMilkCurrent(candidate)
    If current >= maximum
        Return GetActorName(candidate) + ": full (100% or above)"
    ElseIf current >= maximum * 0.5
        Return GetActorName(candidate) + ": 50% or above"
    EndIf
    Return GetActorName(candidate) + ": below 50%"
EndFunction

; Reports the player and nearby loaded Milk Maids; intended only for debugging.
Function ShowDebugCapacitySnapshot()
    Actor playerActor = Game.GetPlayer()
    String report = EvaluateMilkMaid(playerActor)
    Cell currentCell = playerActor.GetParentCell()
    If currentCell != None
        Int count = currentCell.GetNumRefs(43)
        Int i = 0
        While i < count
            Actor candidate = currentCell.GetNthRef(i, 43) as Actor
            If candidate != None && candidate != playerActor && candidate.Is3DLoaded() && playerActor.GetDistance(candidate) <= 2000.0
                String result = EvaluateMilkMaid(candidate)
                If result != ""
                    If report != ""
                        report = report + " | "
                    EndIf
                    report = report + result
                EndIf
            EndIf
            i += 1
        EndWhile
    EndIf
    If report == ""
        Debug.Notification("MME Alerts DEBUG - no evaluable Milk Maids nearby.")
    Else
        Debug.Notification("MME Alerts DEBUG - " + report)
    EndIf
EndFunction

; Returns 0 for no crossing, 1 for crossing 50%, and 2 for crossing 100%.
; First observation establishes a baseline and never produces a reaction.
Int Function UpdateCapacityState(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        StorageUtil.UnsetIntValue(candidate, StateKey)
        Return 0
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return 0
    EndIf
    Float current = MME_Storage.getMilkCurrent(candidate)
    Int currentState = 0
    If current >= maximum
        currentState = 2
    ElseIf current >= maximum * 0.5
        currentState = 1
    EndIf
    Int previousState = StorageUtil.GetIntValue(candidate, StateKey, -1)
    StorageUtil.SetIntValue(candidate, StateKey, currentState)
    If previousState < 0
        Return 0
    ElseIf previousState < 2 && currentState == 2
        Return 2
    ElseIf previousState == 0 && currentState == 1
        Return 1
    EndIf
    Return 0
EndFunction

; Evaluates one actor and queues a threshold reaction for the current scan.
Function ProcessActor(Actor candidate, Actor[] reactionActors, Int[] reactionKinds)
    If candidate == None || !candidate.Is3DLoaded() || !IsMMEMilkMaid(candidate)
        Return
    EndIf
    Int crossing = UpdateCapacityState(candidate)
    If crossing == 0
        Return
    EndIf
    Int slot = reactionKinds.Find(0)
    If slot >= 0
        reactionActors[slot] = candidate
        reactionKinds[slot] = crossing
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableCapacityNotifications", 1) == 1
        If crossing == 2
            Debug.Notification(GetActorName(candidate) + " is completely milky and teetering on a boobgasm!")
        Else
            Debug.Notification(GetActorName(candidate) + " is now half-milky and building nicely!")
        EndIf
    EndIf
EndFunction

; Scans the current cell and selects one highest-priority capacity sound.
Function ScanNearbyMilkMaids(Bool publishSkyrimNet = False, Bool processReactions = True)
    Actor[] reactionActors = new Actor[128]
    Int[] reactionKinds = new Int[128]
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(NearbyRange)
    If nearbyActors == None || nearbyActors.Length == 0
        Debug.Trace("[MME Extensions Native Scan] scanner returned no actors; capacity scan skipped")
        If JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0) == 1
            Debug.Notification("Native Scan failed: no actors returned")
        EndIf
        Return
    EndIf

    ; Retired after native/Papyrus parity testing passed:
    ; Cell.GetNumRefs(43) + Cell.GetNthRef() enumeration previously ran here.
    ; MME validation and all capacity behavior remain in ProcessActor below.
    String milkStatuses = ""
    Int milkmaidCount = 0
    Int i = 0
    While i < nearbyActors.Length
        Actor candidate = nearbyActors[i]
        If processReactions
            ProcessActor(candidate, reactionActors, reactionKinds)
        EndIf
        String status = EvaluateMilkMaidFlavor(candidate)
        If status != ""
            If milkStatuses != ""
                milkStatuses = milkStatuses + " "
            EndIf
            milkStatuses = milkStatuses + status
            milkmaidCount += 1
        EndIf
        i += 1
    EndWhile
    If publishSkyrimNet
        MMEAlertsSkyrimNet.SendNearbyMilkStatuses(Game.GetPlayer(), milkStatuses, nearbyActors.Length, milkmaidCount)
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0) == 1
        Debug.Notification("Native Scan active: " + nearbyActors.Length + " nearby actors")
    EndIf

    ; One sound per scan. A full crossing has priority over a half crossing.
    Actor soundActor = None
    Int soundKind = 0
    Int j = 0
    While j < reactionKinds.Length
        If reactionKinds[j] > soundKind
            soundKind = reactionKinds[j]
            soundActor = reactionActors[j]
        EndIf
        j += 1
    EndWhile
    If soundActor != None && JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1) == 1
        PlayCapacityReaction(soundActor, soundKind)
    EndIf
EndFunction

; Converts MME capacity into compact scene-context prose for SkyrimNet.
String Function EvaluateMilkMaidFlavor(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        Return ""
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return ""
    EndIf
    Float current = MME_Storage.getMilkCurrent(candidate)
    If current >= maximum
        Return GetActorName(candidate) + " is completely full, swollen and on the brink of a boobgasm!"
    ElseIf current >= maximum * 0.5
        Return GetActorName(candidate) + " is over half full, feeling heavier and warm."
    EndIf
    Return GetActorName(candidate) + " is less than half full, feeling pleasantly tingly."
EndFunction

; Plays Medium/Hot capacity pools; sound records must exist in MMEAlert.esp.
Function PlayCapacityReaction(Actor sourceActor, Int crossing)
    If JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) != 1 || JsonUtil.GetIntValue(SettingsFile, "enableFullnessMoans", 1) != 1
        Return
    EndIf
    Int localFormID = 0x000855 ; Medium SOUN marker
    If crossing == 2
        localFormID = 0x000856 ; Hot SOUN marker
    EndIf
    Sound reaction = Game.GetFormFromFile(localFormID, "MMEAlert.esp") as Sound
    If reaction == None
        Debug.Trace("[MMEAlert] capacity sound marker did not resolve: " + localFormID)
        Return
    EndIf
    Int instance = reaction.Play(sourceActor)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0) / 100.0)
    Else
        Debug.Trace("[MMEAlert] capacity Sound.Play returned " + instance)
    EndIf
EndFunction
