Scriptname MMEAlertsController extends Quest

String SettingsFile = "/MMEAlerts/Settings"
String StateKey = "MMEAlerts.CapacityState"
String MilkingStateKey = "MMEAlerts.IsMilking"
String KnownMilkmaidKey = "MMEExtensions.KnownMilkmaid"
String PendingMilkmaidKey = "MMEExtensions.PendingMilkmaid"
Float NearbyRange = 2000.0
Float NextCapacityUpdate = 0.0
Float NextSkyrimNetUpdate = 0.0
Float NextDebugUpdate = 0.0
Float NextArmorCheck = 0.0
Float NextDialogueDiagnosticUpdate = 0.0
Actor LastDialogueDiagnosticActor = None
String LastDialogueDiagnosticState = ""
Bool MMEOpeningRefreshObserved = False
Float MMEOpeningRefreshSnapshotAt = 0.0
Bool Property OStimDialogueAvailable Auto Conditional

Bool Function IsExtensionsEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
EndFunction

; Quest startup registers MME events and initializes the player monitor/poller.
Event OnInit()
    InitializeController()
EndEvent

; Restores event registrations and abilities; called at startup and after load.
Function InitializeController()
    RefreshOStimDialogueAvailability()
    If !IsExtensionsEnabled()
        DisableController()
        Return
    EndIf
    RegisterMilkingEvents()
    MMEAlertsSkyrimNet.RegisterPromptDecorator()
    MMESkyrimNetVoiceControls.RegisterSelfMilkingAction()
    UnregisterForModEvent("MMEExtensions_Lifecycle")
    RegisterForModEvent("MMEExtensions_Lifecycle", "OnNativeLifecycle")
    UnregisterForModEvent("MMEExtensions_MMEEffectApplied")
    RegisterForModEvent("MMEExtensions_MMEEffectApplied", "OnMMEEffectApplied")
    UnregisterForModEvent("MMEExtensions_ArmorEquipped")
    RegisterForModEvent("MMEExtensions_ArmorEquipped", "OnArmorEquipped")
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

; Skyrim.Net resolves quest action scripts from the existing quest instance.
; Keep this entry point on the controller so upgrades work in established saves.
Function StartBreastfeedingMilkShare(Actor milkSource, Actor target)
    MMESkyrimNetVoiceControls.StartBreastfeedingMilkShare(milkSource, target)
EndFunction

; Stops scheduled work and event subscriptions without removing saved state.
Function DisableController()
    OStimDialogueAvailable = False
    UnregisterForUpdate()
    UnregisterForModEvent("MMEExtensions_Lifecycle")
    UnregisterForModEvent("MMEExtensions_MMEEffectApplied")
    UnregisterForModEvent("MMEExtensions_ArmorEquipped")
    UnregisterForModEvent("MME_AddMilkMaid")
    UnregisterForModEvent("MilkQuest.StartMilkingMachine")
    UnregisterForModEvent("MilkQuest.StopMilkingMachine")
    UnregisterForModEvent("MME_MilkingDone")
    If MMEAlertsSkyrimNet.IsAvailable()
        SkyrimNetApi.UnregisterAction("StartSelfMilking")
        SkyrimNetApi.UnregisterAction("StartMilkMaidSelfMilking")
    EndIf
    NextCapacityUpdate = 0.0
    NextSkyrimNetUpdate = 0.0
    NextDebugUpdate = 0.0
    NextArmorCheck = 0.0
    NextDialogueDiagnosticUpdate = 0.0
    LastDialogueDiagnosticActor = None
    LastDialogueDiagnosticState = ""
    MMEOpeningRefreshObserved = False
    MMEOpeningRefreshSnapshotAt = 0.0
EndFunction

; Exposes one dependency-free quest condition for the optional dialogue INFOs.
Function RefreshOStimDialogueAvailability()
    OStimDialogueAvailable = MMEOStimBreastfeeding.IsDialogueEnabled()
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

; True when the actor was already recorded as an established Milkmaid.
Bool Function IsKnownMilkmaid(Actor candidate) Global
    Return candidate != None && StorageUtil.GetIntValue(candidate, "MMEExtensions.KnownMilkmaid", 0) == 1
EndFunction

; True while a candidate conversion is still awaiting MME's Milkmaid state.
Bool Function IsMilkmaidCreationPending(Actor candidate) Global
    Return candidate != None && StorageUtil.GetIntValue(candidate, "MMEExtensions.PendingMilkmaid", 0) == 1
EndFunction

; True when MME/DD reports the actor's arms restrained (armbinder/yoke), which
; makes free-arm breast animations look wrong. The DD-disabled MME bridge
; returns False for every check, so this is optional automatically.
Bool Function IsFreeArmAnimationBlocked(Actor candidate) Global
    If candidate == None
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.DDi == None
        Return False
    EndIf
    Return milkController.DDi.IsMilkingBlocked_Armbinder(candidate) || milkController.DDi.IsMilkingBlocked_Yoke(candidate)
EndFunction

; Narrative-facing semantic alias for the same authoritative MME/DD query.
Bool Function AreArmsRestrained(Actor candidate) Global
    Return IsFreeArmAnimationBlocked(candidate)
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
    If !IsExtensionsEnabled()
        Return
    EndIf
    Actor candidate = sender as Actor
    If candidate == None || !IsMilkmaidCreationEffect(localEffectForm as Int)
        Return
    EndIf
    CheckMilkmaidCreation(candidate, "MME effect")
EndEvent

; Resolves the exact equipped ARMO published by the native global equip sink.
Event OnArmorEquipped(String eventName, String pluginName, Float localArmorForm, Form sender)
    If !IsExtensionsEnabled()
        Return
    EndIf
    Actor wearer = sender as Actor
    Bool diagnostic = MMEArmorScript.GetArmorDiagnostic()
    If diagnostic
        Debug.Notification("Armor Debug: equip detected")
    EndIf
    If wearer == None || pluginName == ""
        MMEArmorScript.ReportArmor(diagnostic, "equip rejected: actor or plugin missing")
        Return
    EndIf
    Armor equippedArmor = Game.GetFormFromFile(localArmorForm as Int, pluginName) as Armor
    If equippedArmor == None
        MMEArmorScript.ReportArmor(diagnostic, "armor resolve failed | " + pluginName + ":" + (localArmorForm as Int))
        Return
    EndIf
    MMEArmorScript.HandleArmorEquipped(wearer, equippedArmor)
EndEvent

; Adds coverage for third-party mods using MME's public creation request.
Event OnMMEAddMilkmaidRequested(Form sender)
    If !IsExtensionsEnabled()
        Return
    EndIf
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
    MMEAlertsSkyrimNet.NarrateMilkmaidCreated(candidate)
    Int handle = ModEvent.Create("MMEExtensions_MilkmaidCreated")
    If handle
        ModEvent.PushForm(handle, candidate)
        ModEvent.Send(handle)
    EndIf
EndFunction

; Receives low-cost lifecycle signals from the optional CommonLibSSE-NG DLL.
Event OnNativeLifecycle(String eventName, String reason, Float numArg, Form sender)
    If !IsExtensionsEnabled()
        Return
    EndIf
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
    If !IsExtensionsEnabled()
        Return
    EndIf
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
    If !IsExtensionsEnabled()
        Return
    EndIf
    Actor milkMaid = actorForm as Actor
    FinishMilking(milkMaid)
EndEvent

; Provides an authoritative completion fallback if the earlier stop was missed.
Event OnMMEMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    If !IsExtensionsEnabled()
        Return
    EndIf
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
    If !IsExtensionsEnabled()
        NextCapacityUpdate = 0.0
        NextSkyrimNetUpdate = 0.0
        NextDebugUpdate = 0.0
        NextDialogueDiagnosticUpdate = 0.0
        LastDialogueDiagnosticActor = None
        LastDialogueDiagnosticState = ""
        MMEOpeningRefreshObserved = False
        MMEOpeningRefreshSnapshotAt = 0.0
        Return
    EndIf
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
    If JsonUtil.GetIntValue(SettingsFile, "enableDebugMilkReport", 0) == 1
        NextDebugUpdate = now + 5.0
    Else
        NextDebugUpdate = 0.0
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0) == 1
        NextDialogueDiagnosticUpdate = now + 0.25
    Else
        NextDialogueDiagnosticUpdate = 0.0
        LastDialogueDiagnosticActor = None
        LastDialogueDiagnosticState = ""
        MMEOpeningRefreshObserved = False
        MMEOpeningRefreshSnapshotAt = 0.0
    EndIf
    ScheduleNextUpdate()
EndFunction

; Schedules the debounced player armor-overflow check three seconds from now.
; Re-scheduling cancels the previous single update, so rapid successive drinks
; collapse into one check timed after the most recent drink.
Function RequestPlayerArmorCheck()
    NextArmorCheck = Utility.GetCurrentRealTime() + 3.0
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
    If NextDebugUpdate > 0.0 && (delay <= 0.0 || NextDebugUpdate - now < delay)
        delay = NextDebugUpdate - now
    EndIf
    If NextArmorCheck > 0.0 && (delay <= 0.0 || NextArmorCheck - now < delay)
        delay = NextArmorCheck - now
    EndIf
    If NextDialogueDiagnosticUpdate > 0.0 && (delay <= 0.0 || NextDialogueDiagnosticUpdate - now < delay)
        delay = NextDialogueDiagnosticUpdate - now
    EndIf
    If delay > 0.0
        Float minimumDelay = 1.0
        If NextDialogueDiagnosticUpdate > 0.0
            minimumDelay = 0.25
        EndIf
        If delay < minimumDelay
            delay = minimumDelay
        EndIf
        RegisterForSingleUpdate(delay)
    EndIf
EndFunction

; Services independent local-capacity and SkyrimNet status schedules.
Event OnUpdate()
    If !IsExtensionsEnabled()
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Bool capacityDue = NextCapacityUpdate > 0.0 && now >= NextCapacityUpdate
    Bool skyrimNetDue = NextSkyrimNetUpdate > 0.0 && now >= NextSkyrimNetUpdate
    Bool debugDue = NextDebugUpdate > 0.0 && now >= NextDebugUpdate
    Bool dialogueDiagnosticDue = NextDialogueDiagnosticUpdate > 0.0 && now >= NextDialogueDiagnosticUpdate
    If capacityDue || skyrimNetDue
        ScanNearbyMilkMaids(skyrimNetDue, capacityDue)
    EndIf
    If capacityDue
        NextCapacityUpdate = now + JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 15.0)
    EndIf
    If skyrimNetDue
        NextSkyrimNetUpdate = now + JsonUtil.GetFloatValue(SettingsFile, "skyrimNetStatusInterval", 15.0)
    EndIf
    If debugDue
        ShowDebugCapacitySnapshot()
        NextDebugUpdate = now + 5.0
    EndIf
    If dialogueDiagnosticDue
        Actor dialogueTarget = MMEExtensionsNative.GetDialogueTarget()
        If dialogueTarget == None
            LastDialogueDiagnosticActor = None
            LastDialogueDiagnosticState = ""
            MMEOpeningRefreshObserved = False
            MMEOpeningRefreshSnapshotAt = 0.0
        Else
            Form openingInfo = Game.GetFormFromFile(0x06544B, "MilkModNEW.esp")
            Form[] activeInfos = MMEExtensionsNative.GetActiveDialogueInfos()
            If openingInfo != None && activeInfos != None && activeInfos.Find(openingInfo) >= 0 && !MMEOpeningRefreshObserved
                MMEOpeningRefreshObserved = True
                MMEOpeningRefreshSnapshotAt = now + 0.25
                Debug.Trace("[MME Extensions Dialogue] observed MME opening INFO 06544B; scheduling post-Fragment_00 snapshot")
            EndIf
            If MMEOpeningRefreshObserved && MMEOpeningRefreshSnapshotAt > 0.0 && now >= MMEOpeningRefreshSnapshotAt
                MMEOpeningRefreshSnapshotAt = 0.0
                ShowDialogueEligibilitySnapshot(dialogueTarget, True)
            ElseIf MMEOpeningRefreshObserved && MMEOpeningRefreshSnapshotAt <= 0.0
                ShowDialogueEligibilitySnapshot(dialogueTarget, True)
            Else
                ShowDialogueEligibilitySnapshot(dialogueTarget, False)
            EndIf
        EndIf
        NextDialogueDiagnosticUpdate = now + 0.25
    EndIf
    Bool armorDue = NextArmorCheck > 0.0 && now >= NextArmorCheck
    If armorDue
        NextArmorCheck = 0.0
        MMEArmorScript.CheckPlayerArmorNow(Game.GetPlayer())
    EndIf
    ScheduleNextUpdate()
EndEvent

String Function DiagnosticBool(Bool value)
    If value
        Return "yes"
    EndIf
    Return "no"
EndFunction

String Function GetMilkBlockers(Actor source, MilkQUEST milkController)
    If source == None
        Return "missing actor"
    EndIf
    String blockers = ""
    Spell beingMilked = milkController.BeingMilkedPassive
    Spell exhaustion = Game.GetFormFromFile(0x023B6C, "MilkModNEW.esp") as Spell
    Spell mentalExhaustion = Game.GetFormFromFile(0x0581F4, "MilkModNEW.esp") as Spell
    Spell livingArmor = Game.GetFormFromFile(0x029709, "MilkModNEW.esp") as Spell
    If beingMilked != None && source.HasSpell(beingMilked)
        blockers = "BeingMilked"
    EndIf
    If exhaustion != None && source.HasSpell(exhaustion)
        blockers += " MilkExhaustion"
    EndIf
    If mentalExhaustion != None && source.HasSpell(mentalExhaustion)
        blockers += " MentalExhaustion"
    EndIf
    If livingArmor != None && source.HasSpell(livingArmor)
        blockers += " LivingArmor"
    EndIf
    If blockers == ""
        Return "none"
    EndIf
    Return blockers
EndFunction

String Function ConditionResults(Int[] values)
    If values == None
        Return "missing"
    EndIf
    String result = ""
    Int i = 0
    While i < values.Length
        If result != ""
            result += ","
        EndIf
        result += "C" + i + "=" + values[i]
        i += 1
    EndWhile
    If result == ""
        Return "empty"
    EndIf
    Return result
EndFunction

Function ReportDialogueStructure(Actor subject, Actor playerActor)
    Form playerDrinksTopic = Game.GetFormFromFile(0x062E91, "MilkModNEW.esp")
    Form npcDrinksTopic = Game.GetFormFromFile(0x062E8F, "MilkModNEW.esp")
    Form playerDrinksSexLab = Game.GetFormFromFile(0x05FE12, "MilkModNEW.esp")
    Form npcDrinksSexLab = Game.GetFormFromFile(0x05FE0E, "MilkModNEW.esp")
    Form playerDrinksOStim = Game.GetFormFromFile(0x000858, "MMEAlert.esp")
    Form npcDrinksOStim = Game.GetFormFromFile(0x000859, "MMEAlert.esp")
    Form[] playerDrinksInfos = MMEExtensionsNative.GetTopicInfos(playerDrinksTopic)
    Form[] npcDrinksInfos = MMEExtensionsNative.GetTopicInfos(npcDrinksTopic)
    Int playerDrinksCount = 0
    Int npcDrinksCount = 0
    Int playerSexLabIndex = -1
    Int playerOStimIndex = -1
    Int npcSexLabIndex = -1
    Int npcOStimIndex = -1
    If playerDrinksInfos != None
        playerDrinksCount = playerDrinksInfos.Length
        playerSexLabIndex = playerDrinksInfos.Find(playerDrinksSexLab)
        playerOStimIndex = playerDrinksInfos.Find(playerDrinksOStim)
    EndIf
    If npcDrinksInfos != None
        npcDrinksCount = npcDrinksInfos.Length
        npcSexLabIndex = npcDrinksInfos.Find(npcDrinksSexLab)
        npcOStimIndex = npcDrinksInfos.Find(npcDrinksOStim)
    EndIf
    Bool playerPNAM = MMEExtensionsNative.GetPreviousTopicInfo(playerDrinksOStim) == playerDrinksSexLab
    Bool npcPNAM = MMEExtensionsNative.GetPreviousTopicInfo(npcDrinksOStim) == npcDrinksSexLab
    String structure1 = "runtime PlayerDrinks topic count=" + playerDrinksCount + " SexLabIndex=" + playerSexLabIndex + " OStimIndex=" + playerOStimIndex + " PNAM=" + DiagnosticBool(playerPNAM)
    String structure2 = "runtime NPCDrinks topic count=" + npcDrinksCount + " SexLabIndex=" + npcSexLabIndex + " OStimIndex=" + npcOStimIndex + " PNAM=" + DiagnosticBool(npcPNAM)
    Debug.Trace("[MME Extensions Dialogue] " + structure1)
    Debug.Trace("[MME Extensions Dialogue] " + structure2)

    Int[] playerSexLabConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(playerDrinksSexLab, subject, playerActor)
    Int[] npcSexLabConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(npcDrinksSexLab, subject, playerActor)
    Int[] playerOStimConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(playerDrinksOStim, subject, playerActor)
    Int[] npcOStimConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(npcDrinksOStim, subject, playerActor)
    String exact1 = "Player drinks SexLab [gate,milk,exhaustion,mental,being,living]: " + ConditionResults(playerSexLabConditions)
    String exact2 = "NPC drinks SexLab [gate,milk,being,living,exhaustion,mental]: " + ConditionResults(npcSexLabConditions)
    String exact3 = "Player drinks OStim [milk,exhaustion,mental,being,living,gate]: " + ConditionResults(playerOStimConditions)
    String exact4 = "NPC drinks OStim [milk,being,living,exhaustion,mental,gate]: " + ConditionResults(npcOStimConditions)
    Debug.Trace("[MME Extensions Dialogue] " + exact1)
    Debug.Trace("[MME Extensions Dialogue] " + exact2)
    Debug.Trace("[MME Extensions Dialogue] " + exact3)
    Debug.Trace("[MME Extensions Dialogue] " + exact4)
    Debug.Trace("[MME Extensions Dialogue] engine totals | Player drinks SexLab=" + DiagnosticBool(MMEExtensionsNative.EvaluateTopicInfo(playerDrinksSexLab, subject, playerActor)) + " OStim=" + DiagnosticBool(MMEExtensionsNative.EvaluateTopicInfo(playerDrinksOStim, subject, playerActor)) + " | NPC drinks SexLab=" + DiagnosticBool(MMEExtensionsNative.EvaluateTopicInfo(npcDrinksSexLab, subject, playerActor)) + " OStim=" + DiagnosticBool(MMEExtensionsNative.EvaluateTopicInfo(npcDrinksOStim, subject, playerActor)))
    Debug.Notification("Dialogue DEBUG - " + structure1)
    Debug.Notification("Dialogue DEBUG - " + structure2)
    Debug.Notification("Dialogue DEBUG - " + exact1)
    Debug.Notification("Dialogue DEBUG - " + exact2)
    Debug.Notification("Dialogue DEBUG - " + exact3)
    Debug.Notification("Dialogue DEBUG - " + exact4)
EndFunction

; Reports the exact live values used by MME's two breastfeeding INFOs. The
; snapshot repeats only when its state changes, so selecting MME's opening
; line exposes the before/after Fragment_00 refresh without notification spam.
Function ShowDialogueEligibilitySnapshot(Actor subject, Bool postRefresh = False)
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkQC == None
        Debug.Trace("[MME Extensions Dialogue] MME controller/condition quest unavailable")
        Return
    EndIf

    Actor playerActor = Game.GetPlayer()
    MilkQUEST_Conditions conditions = milkController.MilkQC
    Float playerMilk = MME_Storage.getMilkCurrent(playerActor)
    Float subjectMilk = MME_Storage.getMilkCurrent(subject)
    String subjectBlockers = GetMilkBlockers(subject, milkController)
    String playerBlockers = GetMilkBlockers(playerActor, milkController)
    Bool subjectShared = conditions.MME_SubjectMilk >= 1.0 && subjectBlockers == "none"
    Bool playerShared = conditions.MME_TargetMilk >= 1.0 && playerBlockers == "none"
    Bool subjectMaid = milkController.MilkMaid != None && milkController.MilkMaid.Find(subject) >= 0
    ActorBase subjectBase = subject.GetLeveledActorBase()
    ActorBase playerBase = playerActor.GetLeveledActorBase()
    Bool subjectRefreshAllowed = subjectBase != None && (subjectBase.GetSex() == 1 || (subjectBase.GetSex() == 0 && milkController.MaleMaids))
    Bool playerRefreshAllowed = playerBase != None && (playerBase.GetSex() == 1 || (playerBase.GetSex() == 0 && milkController.MaleMaids))
    Keyword actorTypeNPC = Game.GetForm(0x00013794) as Keyword
    Keyword actorTypeCreature = Game.GetForm(0x00013795) as Keyword
    Bool rootEligible = conditions.MME_DialogueMilking && !subject.IsChild() && subject.HasKeyword(actorTypeNPC) && !subject.HasKeyword(actorTypeCreature)
    Bool ostimDetected = MMEOStimBreastfeeding.IsOStimDetected()
    Bool ostimSetting = JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0) == 1
    Bool sexLabPlayerDrinks = subjectShared && conditions.MME_BreasfeedingAnimationsCheck
    Bool sexLabNPCDrinks = playerShared && conditions.MME_BreasfeedingAnimationsCheck
    Bool ostimPlayerDrinks = subjectShared && OStimDialogueAvailable
    Bool ostimNPCDrinks = playerShared && OStimDialogueAvailable
    String snapshotState = postRefresh + ":" + subject.GetFormID() + ":" + playerMilk + ":" + subjectMilk + ":" + conditions.MME_TargetMilk + ":" + conditions.MME_SubjectMilk + ":" + subjectBlockers + ":" + playerBlockers + ":" + conditions.MME_DialogueMilking + ":" + conditions.MME_BreasfeedingAnimationsCheck + ":" + OStimDialogueAvailable
    If subject == LastDialogueDiagnosticActor && snapshotState == LastDialogueDiagnosticState
        Return
    EndIf
    LastDialogueDiagnosticActor = subject
    LastDialogueDiagnosticState = snapshotState

    String line0 = "MME opening INFO observed=" + DiagnosticBool(MMEOpeningRefreshObserved) + " / post-refresh snapshot=" + DiagnosticBool(postRefresh)
    String line1 = "Player milk=" + playerMilk + " / TargetMilk=" + conditions.MME_TargetMilk + " | NPC milk=" + subjectMilk + " / SubjectMilk=" + conditions.MME_SubjectMilk
    String line2 = "NPC maid=" + DiagnosticBool(subjectMaid) + " / SubjectMaid=" + DiagnosticBool(conditions.MME_SubjectMaid) + " / SubjectSlave=" + DiagnosticBool(conditions.MME_SubjectSlave) + " | refresh NPC=" + DiagnosticBool(subjectRefreshAllowed) + " Player=" + DiagnosticBool(playerRefreshAllowed)
    String line3 = "blockers NPC=" + subjectBlockers + " | Player=" + playerBlockers + " | SexLabAnim=" + DiagnosticBool(conditions.MME_BreasfeedingAnimationsCheck)
    String line4 = "DialogueMilking=" + DiagnosticBool(conditions.MME_DialogueMilking) + " / root=" + DiagnosticBool(rootEligible) + " | OStim detected=" + DiagnosticBool(ostimDetected) + " setting=" + DiagnosticBool(ostimSetting) + " condition=" + DiagnosticBool(OStimDialogueAvailable)
    String line5 = "Player drinks: SexLab=" + DiagnosticBool(sexLabPlayerDrinks) + " OStim=" + DiagnosticBool(ostimPlayerDrinks) + " | NPC drinks: SexLab=" + DiagnosticBool(sexLabNPCDrinks) + " OStim=" + DiagnosticBool(ostimNPCDrinks)
    Debug.Trace("[MME Extensions Dialogue] " + GetActorName(subject) + " | " + line0)
    Debug.Trace("[MME Extensions Dialogue] " + line1)
    Debug.Trace("[MME Extensions Dialogue] " + line2)
    Debug.Trace("[MME Extensions Dialogue] " + line3)
    Debug.Trace("[MME Extensions Dialogue] " + line4)
    Debug.Trace("[MME Extensions Dialogue] " + line5)
    Debug.Notification("Dialogue DEBUG - " + line0)
    Debug.Notification("Dialogue DEBUG - " + line1)
    Debug.Notification("Dialogue DEBUG - " + line2)
    Debug.Notification("Dialogue DEBUG - " + line3)
    Debug.Notification("Dialogue DEBUG - " + line4)
    Debug.Notification("Dialogue DEBUG - " + line5)
    If postRefresh
        ReportDialogueStructure(subject, playerActor)
    EndIf
EndFunction

; Lets player lifecycle events request an immediate capacity rescan.
Function RefreshCapacity(String reason = "event")
    If !IsExtensionsEnabled()
        Return
    EndIf
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
Int Function ProcessActor(Actor candidate, Actor[] reactionActors, Int[] reactionKinds, Bool processLocalReactions = True)
    If candidate == None || !candidate.Is3DLoaded() || !IsMMEMilkMaid(candidate)
        Return 0
    EndIf
    Int crossing = UpdateCapacityState(candidate)
    If crossing == 0
        Return 0
    EndIf
    MMEAlertsSkyrimNet.SendCapacityMilestone(candidate, crossing)
    MMESkyrimNetVoiceControls.PlayFullnessSelfMilkAnimation(candidate, crossing)
    If !processLocalReactions
        Return crossing
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
    Return crossing
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
    Actor halfFullNarrationActor = None
    Actor fullNarrationActor = None
    Int i = 0
    While i < nearbyActors.Length
        Actor candidate = nearbyActors[i]
        If processReactions || publishSkyrimNet
            Int crossing = ProcessActor(candidate, reactionActors, reactionKinds, processReactions)
            If crossing == 2 && fullNarrationActor == None
                fullNarrationActor = candidate
            ElseIf crossing == 1 && halfFullNarrationActor == None
                halfFullNarrationActor = candidate
            EndIf
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
    If fullNarrationActor != None
        MMEAlertsSkyrimNet.NarrateMilkFull(fullNarrationActor)
    EndIf
    If halfFullNarrationActor != None
        MMEAlertsSkyrimNet.NarrateMilkHalfFull(halfFullNarrationActor)
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
    Int milkState = 0
    If current >= maximum
        milkState = 2
    ElseIf current >= maximum * 0.5
        milkState = 1
    EndIf
    Return MMEAlertsSkyrimNet.BuildMilkStatus(candidate, milkState)
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
