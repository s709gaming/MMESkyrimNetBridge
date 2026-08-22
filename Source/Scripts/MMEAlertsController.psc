Scriptname MMEAlertsController extends Quest

; ---------------------------------------------------------------------------
; Controller-owned persistent state
; ---------------------------------------------------------------------------
; This quest is the long-lived coordinator for native events and periodic work.
; All timed features share one OnUpdate schedule below; adding an independent
; polling quest should be a last resort. Each Next* value is an absolute real-
; time deadline, while dialogue fields form one debounced post-INFO snapshot.
String SettingsFile = "/MMEAlerts/Settings"
String StateKey = "MMEAlerts.CapacityState"
String MilkingStateKey = "MMEAlerts.IsMilking"
String KnownMilkmaidKey = "MMEExtensions.KnownMilkmaid"
String PendingMilkmaidKey = "MMEExtensions.PendingMilkmaid"
String EffectOwnedMilkmaidKey = "MMEExtensions.PendingMilkmaid.EffectOwned"
String DhlpSuspendedKey = "MMEExtensions.DhlpSuspended"
Float NearbyRange = 2000.0
Float NextCapacityUpdate = 0.0
Float NextSkyrimNetUpdate = 0.0
Float NextDebugUpdate = 0.0
Float NextArmorCheck = 0.0
Float NextDialogueDiagnosticUpdate = 0.0
Float NextOStimBreastfeedingWatchdog = 0.0
Actor LastDialogueDiagnosticActor = None
Actor PendingDialogueDiagnosticActor = None
String LastDialogueDiagnosticState = ""
Bool MMEOpeningRefreshObserved = False
Float MMEOpeningRefreshSnapshotAt = 0.0
Bool Property OStimDialogueAvailable Auto Conditional

Bool Function IsExtensionsEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
EndFunction

; True while an external mod has sent dhlp-Suspend and has not yet sent
; dhlp-Resume. DHLP is a player-scoped convention, so NPC reactions do not
; consult this flag.
Bool Function IsDhlpSuspended() Global
    Return StorageUtil.GetIntValue(None, "MMEExtensions.DhlpSuspended", 0) == 1
EndFunction

; Quest startup registers MME events and initializes the player monitor/poller.
Event OnInit()
    InitializeController()
EndEvent

; Restores event registrations and abilities; called at startup and after load.
Function InitializeController()
    ; Phase 1: refresh conditional forms and recover legacy animation state
    ; before honoring the master toggle. The OStim Global must also be correct
    ; while disabled so Skyrim cannot retain a stale dialogue choice.
    RefreshOStimDialogueAvailability()
    MMEVendorServices.RefreshAvailability()
    MMEArmorScript.RestorePlayerMovementIfNeeded(Game.GetPlayer(), MMEArmorScript.GetArmorDiagnostic())
    If !IsExtensionsEnabled()
        DisableController()
        Return
    EndIf
    ; Re-apply the configurable stripping master toggle so MME's own stripping
    ; state stays consistent with this feature after load and init.
    MMEArmorScript.ApplyArmorStrippingMasterToggle()
    ; Phase 2: refresh framework-derived gates and register integrations. Event
    ; registration is deliberately idempotent: unregister first so save reloads
    ; and MCM upgrades cannot accumulate duplicate callbacks.
    RefreshMMESexLabAnimationGate("controller initialization")
    RegisterMilkingEvents()
    RegisterDhlpEvents()
    MMEAlertsSkyrimNet.RegisterPromptDecorator()
    MMESkyrimNetVoiceControls.RegisterSelfMilkingAction()
    UnregisterForModEvent("MMEExtensions_Lifecycle")
    RegisterForModEvent("MMEExtensions_Lifecycle", "OnNativeLifecycle")
    UnregisterForModEvent("MMEExtensions_MMEEffectApplied")
    RegisterForModEvent("MMEExtensions_MMEEffectApplied", "OnMMEEffectApplied")
    UnregisterForModEvent("MMEExtensions_MMEEffectRemoved")
    RegisterForModEvent("MMEExtensions_MMEEffectRemoved", "OnMMEEffectRemoved")
    UnregisterForModEvent("MMEExtensions_DialogueInfo")
    RegisterForModEvent("MMEExtensions_DialogueInfo", "OnDialogueInfoSelected")
    UnregisterForModEvent("MMEExtensions_ArmorEquipped")
    RegisterForModEvent("MMEExtensions_ArmorEquipped", "OnArmorEquipped")
    UnregisterForModEvent("MME_AddMilkMaid")
    RegisterForModEvent("MME_AddMilkMaid", "OnMMEAddMilkmaidRequested")
    ; Phase 3: repair the player monitoring ability on the one known bytecode
    ; migration. Existing active effects retain their original script instance,
    ; so remove/re-add is required when the tracker implementation changes.
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
    ; Phase 4: start shared schedules, then baseline existing Milk Maids. The
    ; baseline prevents established actors from being narrated as new creations.
    UpdatePolling()
    BaselineKnownMilkmaids()
EndFunction

; MME computes this conditional from the same two registrars during its load
; script. Refreshing the cached value fixes load-order staleness without
; weakening the original requirement or coupling SexLab to OStim.
Bool Function RefreshMMESexLabAnimationGate(String reason = "event")
    ; MME caches registrar availability in a quest-condition Boolean. Resolve
    ; the live SexLab animation slots first; missing interfaces are diagnostic,
    ; never a reason to force the original dialogue gate open.
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkQC == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        Debug.Trace("[MME Extensions SexLab BF] gate refresh skipped: MME/SexLab interface unavailable | " + reason)
        Return False
    EndIf
    Bool straightFound = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar") != None
    Bool lesbianFound = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding") != None
    Bool liveGate = straightFound && lesbianFound
    ; Match MME's own AND requirement exactly. This refresh repairs stale cache
    ; state but does not relax registration or gameplay conditions.
    Bool oldGate = milkController.MilkQC.MME_BreasfeedingAnimationsCheck
    milkController.MilkQC.MME_BreasfeedingAnimationsCheck = liveGate
    Debug.Trace("[MME Extensions SexLab BF] refreshed MME gate " + DiagnosticBool(oldGate) + " -> " + DiagnosticBool(liveGate) + " | zjBreastFeedingVar(Straight)=" + DiagnosticBool(straightFound) + " zjBreastFeeding(Lesbian)=" + DiagnosticBool(lesbianFound) + " | " + reason)
    Return liveGate
EndFunction

; Skyrim.Net resolves quest action scripts from the existing quest instance.
; Keep this entry point on the controller so upgrades work in established saves.
Function StartBreastfeedingMilkShare(Actor milkSource, Actor target)
    Debug.Trace("[MMEAlert SkyrimNet BF] dedicated action selected | semantic intent=speaker offers breast to target | speaker/source=" + milkSource + " | target/drinker=" + target)
    MMESkyrimNetVoiceControls.StartBreastfeedingMilkShare(milkSource, target, "speaker/source=" + MMEOStimBreastfeeding.GetActorName(milkSource) + " | target/drinker=" + MMEOStimBreastfeeding.GetActorName(target))
EndFunction

; Reverse Skyrim.Net contract: the conversational speaker is the drinker and
; the selected target is the source. Normalize it before entering the one shared
; OStim/SexLab backend so animation and gameplay logic are never duplicated.
Function StartBreastfeedingDrinkFromTarget(Actor drinker, Actor milkSource)
    Debug.Trace("[MMEAlert SkyrimNet BF] dedicated action selected | semantic intent=speaker drinks from target | speaker/drinker=" + drinker + " | target/source=" + milkSource)
    MMESkyrimNetVoiceControls.StartBreastfeedingMilkShare(milkSource, drinker, "speaker/drinker=" + MMEOStimBreastfeeding.GetActorName(drinker) + " | target/source=" + MMEOStimBreastfeeding.GetActorName(milkSource))
EndFunction

; Stops scheduled work and event subscriptions without removing saved state.
Function DisableController()
    ; Symmetric teardown for every registration and deadline owned by this quest.
    ; Saved gameplay data is preserved; only active observation/scheduling stops.
    OStimDialogueAvailable = False
    MMEVendorServices.DisableAvailability()
    UnregisterForUpdate()
    UnregisterForModEvent("MMEExtensions_Lifecycle")
    UnregisterForModEvent("MMEExtensions_MMEEffectApplied")
    UnregisterForModEvent("MMEExtensions_MMEEffectRemoved")
    UnregisterForModEvent("MMEExtensions_DialogueInfo")
    UnregisterForModEvent("MMEExtensions_ArmorEquipped")
    UnregisterForModEvent("MME_AddMilkMaid")
    UnregisterForModEvent("MilkQuest.StartMilkingMachine")
    UnregisterForModEvent("MilkQuest.StopMilkingMachine")
    UnregisterForModEvent("MME_MilkingDone")
    UnregisterForModEvent("dhlp-Suspend")
    UnregisterForModEvent("dhlp-Resume")
    StorageUtil.UnsetIntValue(None, DhlpSuspendedKey)
    If MMEAlertsSkyrimNet.IsAvailable()
        SkyrimNetApi.UnregisterAction("StartSelfMilking")
        SkyrimNetApi.UnregisterAction("StartMilkMaidSelfMilking")
    EndIf
    NextCapacityUpdate = 0.0
    NextSkyrimNetUpdate = 0.0
    NextDebugUpdate = 0.0
    NextArmorCheck = 0.0
    MMEArmorScript.CancelPlayerArmorCheck(Game.GetPlayer())
    ; Restore MME's own stripping while MME Extensions is disabled.
    MMEArmorScript.ApplyArmorStrippingMasterToggle()
    NextDialogueDiagnosticUpdate = 0.0
    NextOStimBreastfeedingWatchdog = 0.0
    LastDialogueDiagnosticActor = None
    PendingDialogueDiagnosticActor = None
    LastDialogueDiagnosticState = ""
    MMEOpeningRefreshObserved = False
    MMEOpeningRefreshSnapshotAt = 0.0
EndFunction

; Exposes one dependency-free quest condition for the optional dialogue INFOs.
Function RefreshOStimDialogueAvailability()
    ; The ESP dialogue CTDA reads a GlobalVariable, not Papyrus directly. Keep
    ; the Conditional property and Global synchronized from the same predicate.
    OStimDialogueAvailable = MMEOStimBreastfeeding.IsDialogueEnabled()
    GlobalVariable dialogueGate = GetOStimDialogueAvailabilityGlobal()
    If dialogueGate != None
        If OStimDialogueAvailable
            dialogueGate.SetValue(1.0)
        Else
            dialogueGate.SetValue(0.0)
        EndIf
    Else
        Debug.Trace("[MME Extensions Dialogue] OStim availability GlobalVariable is missing")
    EndIf
EndFunction

GlobalVariable Function GetOStimDialogueAvailabilityGlobal() Global
    Return MMEExtensionsNative.GetFormByEditorID("MMEExt_OStimDialogueAvailable") as GlobalVariable
EndFunction

; Records Milkmaids already present when this version starts to avoid false creation reports.
Function BaselineKnownMilkmaids()
    ; Baseline is intentionally cell-local and startup-only. The native scanner
    ; discovers future nearby actors; a permanent second actor scan is wasteful.
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
    If candidate == None || StorageUtil.GetIntValue(candidate, "MMEExtensions.PendingMilkmaid", 0) != 1
        Return False
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEExtensions.PendingMilkmaid.EffectOwned", 0) != 1
        Return True
    EndIf
    If candidate.IsUnconscious() || HasMilkmaidCreationEffect(candidate)
        Return True
    EndIf
    ; Self-heal a save/load or interrupted native removal callback.
    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.PendingMilkmaid")
    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.PendingMilkmaid.EffectOwned")
    Return False
EndFunction

Bool Function HasMilkmaidCreationEffect(Actor candidate) Global
    If candidate == None
        Return False
    EndIf
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
    Return (makeMaidEffect != None && candidate.HasMagicEffect(makeMaidEffect)) || (lactacidEffect != None && candidate.HasMagicEffect(lactacidEffect))
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
    If StorageUtil.GetIntValue(candidate, KnownMilkmaidKey, 0) == 1
        Return
    EndIf
    StorageUtil.SetIntValue(candidate, PendingMilkmaidKey, 1)
    StorageUtil.SetIntValue(candidate, EffectOwnedMilkmaidKey, 1)
    CheckMilkmaidCreation(candidate, "MME effect", False)
EndEvent

; Keeps armor introductions out of MME's complete Lactacid conversion window.
Event OnMMEEffectRemoved(String eventName, String pluginName, Float localEffectForm, Form sender)
    Actor candidate = sender as Actor
    If candidate != None && IsMilkmaidCreationEffect(localEffectForm as Int)
        StorageUtil.UnsetIntValue(candidate, PendingMilkmaidKey)
        StorageUtil.UnsetIntValue(candidate, EffectOwnedMilkmaidKey)
        Debug.Trace("[MME Extensions] MME Milkmaid conversion effect ended for " + GetActorName(candidate))
    EndIf
EndEvent

; Native TESTopicInfoEvent observation schedules the snapshot after MME
; Fragment_00. Raw events stay in the log; the HUD reports only the resulting
; route state.
Event OnDialogueInfoSelected(String eventName, String topicEditorID, Float localInfoForm, Form sender)
    ; Phase 1: resolve enabled diagnostics and keep MME's registrar cache fresh.
    ; The native event is observational; it never changes INFO eligibility.
    Bool dialogueDebug = JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0) == 1
    Bool sexLabBFDebug = JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0) == 1
    Bool ostimBFDebug = JsonUtil.GetIntValue(SettingsFile, "enableOStimDebug", 0) == 1
    If !IsExtensionsEnabled()
        Return
    EndIf
    RefreshMMESexLabAnimationGate("dialogue event " + topicEditorID)
    Int selectedInfo = localInfoForm as Int
    If selectedInfo == 0x05FE12 || selectedInfo == 0x05FE0E
        Actor source = sender as Actor
        Actor drinker = Game.GetPlayer()
        If selectedInfo == 0x05FE0E
            source = Game.GetPlayer()
            drinker = sender as Actor
        EndIf
        MMEDebug breastfeedingService = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
        If breastfeedingService != None
            breastfeedingService.ObserveDialogueSexLabBreastfeeding(source, drinker)
        Else
            Debug.Trace("[MME SexLab Dialogue] FAIL: persistent breastfeeding service unavailable")
        EndIf
        Return
    EndIf
    If !dialogueDebug && !sexLabBFDebug && !ostimBFDebug
        Return
    EndIf
    ; Phase 2: treat selection of either independent OStim DIAL as terminal
    ; evidence that the option was visible. Never schedule another visibility
    ; snapshot here: Skyrim has already advanced beyond the choice list.
    Debug.Trace("[MME Extensions Dialogue] INFO event | topic=" + topicEditorID + " info=" + (localInfoForm as Int) + " speaker=" + sender)
    ; Observe the two original MME SexLab breastfeeding INFOs after their own
    ; fragment runs. This deliberately does not call StartSex a second time.
    Bool ostimPlayerSelected = topicEditorID == "MMEExt_OStimBreastfeeding_PlayerDrinksTopic"
    Bool ostimNPCSelected = topicEditorID == "MMEExt_OStimBreastfeeding_NPCDrinksTopic"
    If ostimPlayerSelected || ostimNPCSelected
        String selectedRoute = "Player drinks from NPC"
        If ostimNPCSelected
            selectedRoute = "NPC drinks from Player"
        EndIf
        Debug.Trace("[MME Extensions OStim BF Dialogue] option SELECTED | " + selectedRoute + " | INFO=" + (localInfoForm as Int))
        If ostimBFDebug
            Debug.Notification("OStim BF DEBUG: option SELECTED; starting scene")
        EndIf
        Return
    EndIf
    ; Only the MME opening INFO constructs the choice list we are auditing.
    ; Scheduling from later INFOs observes an already-advanced/closed menu and
    ; turns a successful selection into a false NOT SHOWN verdict.
    If topicEditorID != "MME_Hello_Dialogue_Topic"
        Return
    EndIf
    ; Phase 3: the MME opening fragment refreshes shared MilkQC values and then
    ; constructs the menu. Debounce one short post-fragment snapshot through the
    ; controller scheduler; this avoids dialogue polling and repeated HUD spam.
    Actor dialogueActor = sender as Actor
    If dialogueActor == None
        dialogueActor = MMEExtensionsNative.GetDialogueTarget()
    EndIf
    MMEOpeningRefreshObserved = True
    PendingDialogueDiagnosticActor = dialogueActor
    MMEOpeningRefreshSnapshotAt = Utility.GetCurrentRealTime() + 0.25
    NextDialogueDiagnosticUpdate = MMEOpeningRefreshSnapshotAt
    Debug.Trace("[MME Extensions Dialogue] MME opening refresh INFO executed; scheduling authoritative post-Fragment_00 snapshot")
    ScheduleNextUpdate()
EndEvent

; Resolves the exact equipped ARMO published by the native global equip sink.
Event OnArmorEquipped(String eventName, String pluginName, Float localArmorForm, Form sender)
    ; Native events cross the DLL/Papyrus boundary as plugin name + local ID so
    ; load order is irrelevant. Resolve the actual ARMO here, then delegate all
    ; classification, settings, reactions, and narration to MMEArmorScript.
    If !IsExtensionsEnabled()
        Return
    EndIf
    Actor wearer = sender as Actor
    Bool diagnostic = MMEArmorScript.GetArmorDiagnostic()
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
Function CheckMilkmaidCreation(Actor candidate, String source, Bool ownsPendingMarker = True)
    ; This routine reconciles several creation signals that may arrive in either
    ; order. MilkQUEST membership is authoritative; effect/pending markers only
    ; explain whether conversion is still underway and who may clear the state.
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
    If ownsPendingMarker && StorageUtil.GetIntValue(candidate, PendingMilkmaidKey, 0) == 1
        Return
    EndIf
    If ownsPendingMarker
        StorageUtil.SetIntValue(candidate, PendingMilkmaidKey, 1)
    EndIf
    If diagnostic
        Debug.Notification("Milkmaid Creation: detected " + source + " on " + GetActorName(candidate))
    EndIf
    Utility.Wait(1.5)
    If ownsPendingMarker
        StorageUtil.UnsetIntValue(candidate, PendingMilkmaidKey)
    EndIf
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
    RefreshMMESexLabAnimationGate("lifecycle " + reason)
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

; Subscribes to the DHLP Suspend/Resume convention used by other mods before
; they temporarily claim the player. MME Extensions only listens: it never
; sends dhlp-Suspend or dhlp-Resume, so it takes on no ownership or cleanup
; responsibilities beyond clearing its own transient flag.
Function RegisterDhlpEvents()
    ; Registration is idempotent for the same reason as the other controller
    ; ModEvents: unregister first so reloads and MCM upgrades cannot accumulate
    ; duplicate callbacks. A fresh registration also clears any stale suspend
    ; state left behind by a mod that never resumed before the save was loaded.
    UnregisterForModEvent("dhlp-Suspend")
    RegisterForModEvent("dhlp-Suspend", "OnDhlpSuspend")
    UnregisterForModEvent("dhlp-Resume")
    RegisterForModEvent("dhlp-Resume", "OnDhlpResume")
    StorageUtil.UnsetIntValue(None, DhlpSuspendedKey)
EndFunction

; Records an external mod's request to treat the player as temporarily claimed.
Event OnDhlpSuspend(String eventName, String strArg, Float numArg, Form sender)
    SetDhlpSuspended(True, sender)
EndEvent

; Releases the external claim so player reactions may start again.
Event OnDhlpResume(String eventName, String strArg, Float numArg, Form sender)
    SetDhlpSuspended(False, sender)
EndEvent

; Single writer for the transient DHLP flag. StorageUtil keeps the value
; readable from the Global safety gate without needing a controller reference.
Function SetDhlpSuspended(Bool suspended, Form sender)
    If suspended
        StorageUtil.SetIntValue(None, DhlpSuspendedKey, 1)
        Debug.Trace("[MME Extensions DHLP] suspended by " + DhlpSenderLabel(sender))
    Else
        StorageUtil.UnsetIntValue(None, DhlpSuspendedKey)
        Debug.Trace("[MME Extensions DHLP] resumed by " + DhlpSenderLabel(sender))
    EndIf
EndFunction

String Function DhlpSenderLabel(Form sender)
    If sender == None
        Return "<unknown>"
    EndIf
    String label = sender.GetName()
    If label == ""
        label = "<unnamed form>"
    EndIf
    Return label
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
    ; Rebuild absolute deadlines from MCM settings. This function owns the only
    ; recurring capacity/Skyrim.Net/debug schedules; dialogue and armor checks
    ; remain event-driven one-shots inserted into the same deadline set.
    UnregisterForUpdate()
    If !IsExtensionsEnabled()
        NextCapacityUpdate = 0.0
        NextSkyrimNetUpdate = 0.0
        NextDebugUpdate = 0.0
        NextDialogueDiagnosticUpdate = 0.0
        LastDialogueDiagnosticActor = None
        PendingDialogueDiagnosticActor = None
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
    If JsonUtil.GetIntValue(SettingsFile, "enableSkyrimNetMilkStatuses", 1) == 1 || JsonUtil.GetIntValue(SettingsFile, "enableNearbyMilkArmorStatus", 1) == 1
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
        ; The native TESTopicInfoEvent sink schedules this precisely when the
        ; player selects MME's opening dialogue. No active-INFO polling needed.
        NextDialogueDiagnosticUpdate = 0.0
    Else
        NextDialogueDiagnosticUpdate = 0.0
        LastDialogueDiagnosticActor = None
        PendingDialogueDiagnosticActor = None
        LastDialogueDiagnosticState = ""
        MMEOpeningRefreshObserved = False
        MMEOpeningRefreshSnapshotAt = 0.0
    EndIf
    ScheduleNextUpdate()
EndFunction

; Schedules the debounced player armor stripping check three seconds from now.
; Re-scheduling cancels the previous single update, so rapid successive drinks
; collapse into one check timed after the most recent drink.
Function RequestPlayerArmorCheck()
    ; Debounce at the deadline level. Rapid drinks overwrite NextArmorCheck, but
    ; the StorageUtil generation token remains the authority consumed by the
    ; eventual Armor Stripping Check.
    Float now = Utility.GetCurrentRealTime()
    NextArmorCheck = now + 3.0
    MMEArmorScript.Report(MMEArmorScript.GetDiagnostic(), "timer armed | delay=3 seconds | due=" + NextArmorCheck)
    ScheduleNextUpdate()
EndFunction

Function RequestOStimBreastfeedingWatchdog()
    NextOStimBreastfeedingWatchdog = Utility.GetCurrentRealTime() + 1.0
    ScheduleNextUpdate()
EndFunction

Function ScheduleNextUpdate()
    ; Select the earliest absolute deadline across all controller-owned work.
    ; Overdue candidates are clamped positive: RegisterForSingleUpdate ignores
    ; non-positive delays, which previously allowed a due armor check to vanish.
    Float now = Utility.GetCurrentRealTime()
    Float delay = 0.0
    Float candidate = 0.0
    If NextCapacityUpdate > 0.0
        candidate = NextCapacityUpdate - now
        If candidate <= 0.0
            candidate = 0.01
        EndIf
        delay = candidate
    EndIf
    If NextSkyrimNetUpdate > 0.0
        candidate = NextSkyrimNetUpdate - now
        If candidate <= 0.0
            candidate = 0.01
        EndIf
        If delay <= 0.0 || candidate < delay
            delay = candidate
        EndIf
    EndIf
    If NextDebugUpdate > 0.0
        candidate = NextDebugUpdate - now
        If candidate <= 0.0
            candidate = 0.01
        EndIf
        If delay <= 0.0 || candidate < delay
            delay = candidate
        EndIf
    EndIf
    If NextArmorCheck > 0.0
        candidate = NextArmorCheck - now
        If candidate <= 0.0
            candidate = 0.01
        EndIf
        If delay <= 0.0 || candidate < delay
            delay = candidate
        EndIf
    EndIf
    If NextDialogueDiagnosticUpdate > 0.0
        candidate = NextDialogueDiagnosticUpdate - now
        If candidate <= 0.0
            candidate = 0.01
        EndIf
        If delay <= 0.0 || candidate < delay
            delay = candidate
        EndIf
    EndIf
    If NextOStimBreastfeedingWatchdog > 0.0
        candidate = NextOStimBreastfeedingWatchdog - now
        If candidate <= 0.0
            candidate = 0.01
        EndIf
        If delay <= 0.0 || candidate < delay
            delay = candidate
        EndIf
    EndIf
    If delay > 0.0
        ; Dialogue needs a quarter-second post-fragment snapshot. All other work
        ; is intentionally throttled to one second to avoid tight Papyrus loops.
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
    ; Snapshot due flags before executing work so each deadline is serviced at
    ; most once per callback. Capacity and Skyrim.Net share the same actor scan.
    If !IsExtensionsEnabled()
        NextArmorCheck = 0.0
        MMEArmorScript.CancelPlayerArmorCheck(Game.GetPlayer())
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Bool capacityDue = NextCapacityUpdate > 0.0 && now >= NextCapacityUpdate
    Bool skyrimNetDue = NextSkyrimNetUpdate > 0.0 && now >= NextSkyrimNetUpdate
    Bool debugDue = NextDebugUpdate > 0.0 && now >= NextDebugUpdate
    Bool dialogueDiagnosticDue = NextDialogueDiagnosticUpdate > 0.0 && now >= NextDialogueDiagnosticUpdate
    Bool ostimBreastfeedingDue = NextOStimBreastfeedingWatchdog > 0.0 && now >= NextOStimBreastfeedingWatchdog
    If capacityDue || skyrimNetDue
        ScanNearbyMilkMaids(skyrimNetDue, capacityDue)
    EndIf
    ; Advance recurring deadlines from this callback's timestamp. One-shot
    ; dialogue and armor deadlines are cleared only when their work is consumed.
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
        ; Prefer Skyrim's live speaker at evaluation time. The event sender is a
        ; fallback because noisy INFO transitions may report a stale lastSpeaker.
        Actor dialogueTarget = PendingDialogueDiagnosticActor
        ; At evaluation time Skyrim's menu speaker is the CTDA Subject. Prefer
        ; that live value over a speaker captured by an earlier noisy event.
        Actor liveDialogueTarget = MMEExtensionsNative.GetDialogueTarget()
        If liveDialogueTarget != None
            dialogueTarget = liveDialogueTarget
        EndIf
        If dialogueTarget == None
            Debug.Trace("[MME Extensions Dialogue] opening refresh observed, but speaker was unavailable for post-refresh snapshot")
        Else
            If JsonUtil.GetIntValue(SettingsFile, "enableDialogueDiagnostic", 0) == 1
                ShowDialogueEligibilitySnapshot(dialogueTarget, True)
            EndIf
            If JsonUtil.GetIntValue(SettingsFile, "enableSexLabBreastfeedingDebug", 0) == 1
                ShowSexLabBreastfeedingDiagnostic(dialogueTarget)
            EndIf
            If JsonUtil.GetIntValue(SettingsFile, "enableOStimDebug", 0) == 1
                ShowOStimBreastfeedingDiagnostic(dialogueTarget)
            EndIf
        EndIf
        NextDialogueDiagnosticUpdate = 0.0
        MMEOpeningRefreshSnapshotAt = 0.0
        PendingDialogueDiagnosticActor = None
    EndIf
    If ostimBreastfeedingDue
        NextOStimBreastfeedingWatchdog = 0.0
        MMEDebug breastfeedingService = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
        If breastfeedingService != None
            breastfeedingService.HandleWatchdogUpdate()
        EndIf
    EndIf
    ; Earlier scan/diagnostic work may be latent. Re-read real time so an
    ; armor timer that became due during this update fires in this same pass.
    now = Utility.GetCurrentRealTime()
    Bool armorDue = NextArmorCheck > 0.0 && now >= NextArmorCheck
    If armorDue
        ; Clear the deadline before calling the armor script. That script may
        ; trigger animation/equip activity, which must not re-enter this check.
        NextArmorCheck = 0.0
        MMEArmorScript.Report(MMEArmorScript.GetDiagnostic(), "timer fired")
        MMEArmorScript.CheckPlayerArmorNow(Game.GetPlayer())
    EndIf
    ; Recompute from all remaining deadlines. ScheduleNextUpdate handles work
    ; that became overdue while a latent scan or diagnostic was running.
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

String Function ConditionLabel(String route, Int index)
    If route == "PlayerSexLab"
        If index == 0
            Return "SexLab gate"
        ElseIf index == 1
            Return "NPC milk"
        ElseIf index == 2
            Return "NPC MilkExhaustion"
        ElseIf index == 3
            Return "NPC MentalExhaustion"
        ElseIf index == 4
            Return "NPC BeingMilked"
        ElseIf index == 5
            Return "NPC LivingArmor"
        EndIf
    ElseIf route == "NPCSexLab"
        If index == 0
            Return "SexLab gate"
        ElseIf index == 1
            Return "Player milk"
        ElseIf index == 2
            Return "Player BeingMilked"
        ElseIf index == 3
            Return "Player LivingArmor"
        ElseIf index == 4
            Return "Player MilkExhaustion"
        ElseIf index == 5
            Return "Player MentalExhaustion"
        EndIf
    ElseIf route == "PlayerOStim"
        If index == 0
            Return "NPC milk"
        ElseIf index == 1
            Return "NPC MilkExhaustion"
        ElseIf index == 2
            Return "NPC MentalExhaustion"
        ElseIf index == 3
            Return "NPC BeingMilked"
        ElseIf index == 4
            Return "NPC LivingArmor"
        ElseIf index == 5
            Return "OStim availability global"
        EndIf
    ElseIf route == "NPCOStim"
        If index == 0
            Return "Player milk"
        ElseIf index == 1
            Return "Player BeingMilked"
        ElseIf index == 2
            Return "Player LivingArmor"
        ElseIf index == 3
            Return "Player MilkExhaustion"
        ElseIf index == 4
            Return "Player MentalExhaustion"
        ElseIf index == 5
            Return "OStim availability global"
        EndIf
    EndIf
    Return "condition C" + index
EndFunction

String Function ConditionDescriptions(String[] values)
    If values == None || values.Length == 0
        Return "missing"
    EndIf
    String result = ""
    Int i = 0
    While i < values.Length
        If result != ""
            result += " | "
        EndIf
        result += "C" + i + " " + values[i]
        i += 1
    EndWhile
    Return result
EndFunction

String Function FirstFailedCondition(Int[] values, String[] descriptions, String route)
    If values == None || values.Length == 0
        Return "INFO/conditions unavailable"
    EndIf
    Int i = 0
    While i < values.Length
        If values[i] == 0
            If descriptions != None && i < descriptions.Length
                Return "C" + i + " " + descriptions[i]
            EndIf
            Return ConditionLabel(route, i)
        EndIf
        i += 1
    EndWhile
    Return "none"
EndFunction

String Function RouteResult(Bool eligible, Bool visible, Int[] values, String[] descriptions, String route)
    If !eligible
        Return "FAIL " + FirstFailedCondition(values, descriptions, route)
    ElseIf visible
        Return "PASS shown"
    EndIf
    Return "PASS NOT SHOWN"
EndFunction

String Function ShortRouteResult(Bool eligible, Bool visible, Int[] values, String route)
    If !eligible
        Return "FAIL " + FirstFailedCondition(values, None, route)
    ElseIf visible
        Return "PASS shown"
    EndIf
    Return "PASS NOT SHOWN"
EndFunction

Function ReportDialogueStructure(Actor subject, Actor playerActor)
    ; Resolve both original MME records and extension records by their stable
    ; source identities, then inspect runtime topic arrays/PNAM links. This is a
    ; topology audit only; it never edits or forces a dialogue record.
    Form playerDrinksTopic = Game.GetFormFromFile(0x062E91, "MilkModNEW.esp")
    Form npcDrinksTopic = Game.GetFormFromFile(0x062E8F, "MilkModNEW.esp")
    Form playerDrinksSexLab = Game.GetFormFromFile(0x05FE12, "MilkModNEW.esp")
    Form npcDrinksSexLab = Game.GetFormFromFile(0x05FE0E, "MilkModNEW.esp")
    Form playerDrinksOStim = Game.GetFormFromFile(0x00085F, "MMEAlert.esp")
    Form npcDrinksOStim = Game.GetFormFromFile(0x000860, "MMEAlert.esp")
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
    String[] playerSexLabDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(playerDrinksSexLab)
    String[] npcSexLabDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(npcDrinksSexLab)
    String[] playerOStimDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(playerDrinksOStim)
    String[] npcOStimDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(npcDrinksOStim)
    Bool playerSexLabEligible = MMEExtensionsNative.EvaluateTopicInfo(playerDrinksSexLab, subject, playerActor)
    Bool npcSexLabEligible = MMEExtensionsNative.EvaluateTopicInfo(npcDrinksSexLab, subject, playerActor)
    Bool playerOStimEligible = MMEExtensionsNative.EvaluateTopicInfo(playerDrinksOStim, subject, playerActor)
    Bool npcOStimEligible = MMEExtensionsNative.EvaluateTopicInfo(npcDrinksOStim, subject, playerActor)
    Form[] visibleInfos = MMEExtensionsNative.GetVisibleDialogueInfos()
    Int visibleInfoCount = 0
    Bool playerSexLabVisible = False
    Bool npcSexLabVisible = False
    Bool playerOStimVisible = False
    Bool npcOStimVisible = False
    If visibleInfos != None
        visibleInfoCount = visibleInfos.Length
        playerSexLabVisible = visibleInfos.Find(playerDrinksSexLab) >= 0
        npcSexLabVisible = visibleInfos.Find(npcDrinksSexLab) >= 0
        playerOStimVisible = visibleInfos.Find(playerDrinksOStim) >= 0
        npcOStimVisible = visibleInfos.Find(npcDrinksOStim) >= 0
    EndIf
    String exact1 = "Player drinks SexLab values: " + ConditionResults(playerSexLabConditions) + " | " + ConditionDescriptions(playerSexLabDescriptions)
    String exact2 = "NPC drinks SexLab values: " + ConditionResults(npcSexLabConditions) + " | " + ConditionDescriptions(npcSexLabDescriptions)
    String exact3 = "Player drinks OStim values: " + ConditionResults(playerOStimConditions) + " | " + ConditionDescriptions(playerOStimDescriptions)
    String exact4 = "NPC drinks OStim values: " + ConditionResults(npcOStimConditions) + " | " + ConditionDescriptions(npcOStimDescriptions)
    Debug.Trace("[MME Extensions Dialogue] " + exact1)
    Debug.Trace("[MME Extensions Dialogue] " + exact2)
    Debug.Trace("[MME Extensions Dialogue] " + exact3)
    Debug.Trace("[MME Extensions Dialogue] " + exact4)
    String playerResults = "Player drinks: SexLab " + RouteResult(playerSexLabEligible, playerSexLabVisible, playerSexLabConditions, playerSexLabDescriptions, "PlayerSexLab") + " | OStim " + RouteResult(playerOStimEligible, playerOStimVisible, playerOStimConditions, playerOStimDescriptions, "PlayerOStim")
    String npcResults = "NPC drinks: SexLab " + RouteResult(npcSexLabEligible, npcSexLabVisible, npcSexLabConditions, npcSexLabDescriptions, "NPCSexLab") + " | OStim " + RouteResult(npcOStimEligible, npcOStimVisible, npcOStimConditions, npcOStimDescriptions, "NPCOStim")
    Debug.Trace("[MME Extensions Dialogue] visible INFO count=" + visibleInfoCount + " | " + playerResults)
    Debug.Trace("[MME Extensions Dialogue] " + npcResults)
    Debug.Notification("Dialogue DEBUG: " + playerResults)
    Debug.Notification("Dialogue DEBUG: " + npcResults)
    If (playerSexLabEligible && !playerSexLabVisible) || (npcSexLabEligible && !npcSexLabVisible) || (playerOStimEligible && !playerOStimVisible) || (npcOStimEligible && !npcOStimVisible)
        Debug.Notification("Dialogue DEBUG: conditions PASS but INFO not shown")
        Debug.Trace("[MME Extensions Dialogue] conditions PASS but INFO not shown; investigate merged topic array, PNAM ordering, VMAD, and menu construction")
    EndIf
EndFunction

String Function SourceFileSummary(Form target)
    String[] files = MMEExtensionsNative.GetFormSourceFiles(target)
    If files == None || files.Length == 0
        Return "missing"
    EndIf
    String result = files[0]
    Int i = 1
    While i < files.Length
        result += " -> " + files[i]
        i += 1
    EndWhile
    Return result
EndFunction

; Audits MME's original SexLab breastfeeding route only. This runs from the
; native Hey there INFO event after Fragment_00 has refreshed MME's condition
; quest; it observes live records and state but never starts or alters a scene.
Function ShowSexLabBreastfeedingDiagnostic(Actor subject)
    ; Phase 1: resolve the exact original MME interfaces, registrars, INFOs, and
    ; cached milk values used by the SexLab lane. Do not substitute OStim state.
    Actor playerActor = Game.GetPlayer()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Form playerDrinksTopic = Game.GetFormFromFile(0x062E91, "MilkModNEW.esp")
    Form npcDrinksTopic = Game.GetFormFromFile(0x062E8F, "MilkModNEW.esp")
    Form playerDrinksInfo = Game.GetFormFromFile(0x05FE12, "MilkModNEW.esp")
    Form npcDrinksInfo = Game.GetFormFromFile(0x05FE0E, "MilkModNEW.esp")

    Bool frameworkAvailable = milkController != None && milkController.SexLab != None
    Bool interfaceValid = frameworkAvailable && milkController.SexLab.AnimSlots != None
    sslBaseAnimation straightAnimation = None
    sslBaseAnimation lesbianAnimation = None
    If interfaceValid
        ; MME_Dialogues names Var as its straight/male-drinker branch.
        straightAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar")
        lesbianAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding")
    EndIf
    Bool straightResolved = straightAnimation != None
    Bool lesbianResolved = lesbianAnimation != None

    If milkController == None || milkController.MilkQC == None
        Debug.Notification("SexLab BF DEBUG: MME interface=FAIL")
        Debug.Trace("[MME Extensions SexLab BF] MME_MilkQUEST or MilkQC unavailable")
        Return
    EndIf
    MilkQUEST_Conditions conditions = milkController.MilkQC
    Float playerMilk = MME_Storage.getMilkCurrent(playerActor)
    Float npcMilk = MME_Storage.getMilkCurrent(subject)
    String playerBlockers = GetMilkBlockers(playerActor, milkController)
    String npcBlockers = GetMilkBlockers(subject, milkController)
    Bool playerInfoExists = playerDrinksInfo != None
    Bool npcInfoExists = npcDrinksInfo != None
    Bool playerInfoInTopic = playerInfoExists && MMEExtensionsNative.GetTopicInfos(playerDrinksTopic).Find(playerDrinksInfo) >= 0
    Bool npcInfoInTopic = npcInfoExists && MMEExtensionsNative.GetTopicInfos(npcDrinksTopic).Find(npcDrinksInfo) >= 0
    Int[] playerConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(playerDrinksInfo, subject, playerActor)
    Int[] npcConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(npcDrinksInfo, subject, playerActor)
    String[] playerDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(playerDrinksInfo)
    String[] npcDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(npcDrinksInfo)
    Bool playerEligible = playerInfoExists && MMEExtensionsNative.EvaluateTopicInfo(playerDrinksInfo, subject, playerActor)
    Bool npcEligible = npcInfoExists && MMEExtensionsNative.EvaluateTopicInfo(npcDrinksInfo, subject, playerActor)
    Form[] visibleInfos = MMEExtensionsNative.GetVisibleDialogueInfos()
    Bool playerVisible = visibleInfos != None && visibleInfos.Find(playerDrinksInfo) >= 0
    Bool npcVisible = visibleInfos != None && visibleInfos.Find(npcDrinksInfo) >= 0

    ; Phase 2: keep technical CTDA/override detail in the Papyrus log. The HUD
    ; reports only framework state and the first meaningful route failure.
    Debug.Trace("[MME Extensions SexLab BF] actor=" + subject + " player=" + playerActor)
    Debug.Trace("[MME Extensions SexLab BF] Framework=" + DiagnosticBool(frameworkAvailable) + " AnimSlots=" + DiagnosticBool(interfaceValid) + " zjBreastFeedingVar(Straight)=" + straightAnimation + " zjBreastFeeding(Lesbian)=" + lesbianAnimation)
    Debug.Trace("[MME Extensions SexLab BF] gate=" + DiagnosticBool(conditions.MME_BreasfeedingAnimationsCheck) + " DialogueMilking=" + DiagnosticBool(conditions.MME_DialogueMilking) + " Player milk=" + playerMilk + "/TargetMilk=" + conditions.MME_TargetMilk + " blockers=" + playerBlockers + " NPC milk=" + npcMilk + "/SubjectMilk=" + conditions.MME_SubjectMilk + " blockers=" + npcBlockers)
    Debug.Trace("[MME Extensions SexLab BF] Player-drinks INFO=" + playerDrinksInfo + " topicMember=" + DiagnosticBool(playerInfoInTopic) + " sources=" + SourceFileSummary(playerDrinksInfo))
    Debug.Trace("[MME Extensions SexLab BF] Player-drinks CTDA=" + ConditionResults(playerConditions) + " | " + ConditionDescriptions(playerDescriptions) + " | eligible=" + DiagnosticBool(playerEligible) + " visible=" + DiagnosticBool(playerVisible))
    Debug.Trace("[MME Extensions SexLab BF] NPC-drinks INFO=" + npcDrinksInfo + " topicMember=" + DiagnosticBool(npcInfoInTopic) + " sources=" + SourceFileSummary(npcDrinksInfo))
    Debug.Trace("[MME Extensions SexLab BF] NPC-drinks CTDA=" + ConditionResults(npcConditions) + " | " + ConditionDescriptions(npcDescriptions) + " | eligible=" + DiagnosticBool(npcEligible) + " visible=" + DiagnosticBool(npcVisible))
    Debug.Trace("[MME Extensions SexLab BF] MMEAlert touches Player-drinks=" + DiagnosticBool(StringUtil.Find(SourceFileSummary(playerDrinksInfo), "MMEAlert.esp") >= 0) + " NPC-drinks=" + DiagnosticBool(StringUtil.Find(SourceFileSummary(npcDrinksInfo), "MMEAlert.esp") >= 0))

    Debug.Notification("SexLab BF DEBUG: Framework=" + DiagnosticBool(frameworkAvailable) + " Straight=" + DiagnosticBool(straightResolved) + " Lesbian=" + DiagnosticBool(lesbianResolved) + " MME gate=" + DiagnosticBool(conditions.MME_BreasfeedingAnimationsCheck))
    Debug.Notification("SexLab BF DEBUG: NPC milk=" + DiagnosticBool(conditions.MME_SubjectMilk >= 1.0 && npcBlockers == "none") + " Player milk=" + DiagnosticBool(conditions.MME_TargetMilk >= 1.0 && playerBlockers == "none"))
    Debug.Notification("SexLab BF DEBUG: Player drinks=" + ShortRouteResult(playerEligible, playerVisible, playerConditions, "PlayerSexLab") + " | NPC drinks=" + ShortRouteResult(npcEligible, npcVisible, npcConditions, "NPCSexLab"))
    If !frameworkAvailable
        Debug.Notification("SexLab BF DEBUG: first failure=SexLab framework missing")
    ElseIf !interfaceValid
        Debug.Notification("SexLab BF DEBUG: first failure=MME AnimSlots invalid")
    ElseIf !straightResolved
        Debug.Notification("SexLab BF DEBUG: first failure=zjBreastFeedingVar missing")
    ElseIf !lesbianResolved
        Debug.Notification("SexLab BF DEBUG: first failure=zjBreastFeeding missing")
    ElseIf !conditions.MME_BreasfeedingAnimationsCheck
        Debug.Notification("SexLab BF DEBUG: first failure=MME animation gate")
    ElseIf !playerInfoExists || !npcInfoExists
        Debug.Notification("SexLab BF DEBUG: first failure=original INFO missing")
    ElseIf !playerInfoInTopic || !npcInfoInTopic
        Debug.Notification("SexLab BF DEBUG: first failure=INFO absent from topic")
    ElseIf !playerEligible && !npcEligible
        Debug.Notification("SexLab BF DEBUG: first failure=INFO conditions")
    ElseIf (playerEligible && !playerVisible) || (npcEligible && !npcVisible)
        Debug.Notification("SexLab BF DEBUG: conditions PASS, INFO visible=NO")
    Else
        Debug.Notification("SexLab BF DEBUG: eligible INFO visible=YES")
    EndIf
EndFunction

; Audits only the independent OStim alternatives. A route can pass its CTDAs
; yet remain absent when its INFO was incorrectly placed in an original MME
; response chain; that structural distinction is deliberately surfaced.
Function ShowOStimBreastfeedingDiagnostic(Actor subject)
    ; Phase 1: gather live MME milk, cached MilkQC values, the independent OStim
    ; INFOs/topics, and the framework availability Global used by their CTDAs.
    Actor playerActor = Game.GetPlayer()
    If subject == None || playerActor == None
        Debug.Trace("[MME Extensions OStim BF Dialogue] evaluation actor unavailable")
        Debug.Notification("OStim BF DEBUG: FAIL dialogue actors unavailable")
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    MilkQUEST_Conditions conditions = None
    Float subjectMilk = -1.0
    Float playerMilk = -1.0
    Float subjectSnapshot = -1.0
    Float playerSnapshot = -1.0
    If milkController != None
        conditions = milkController.MilkQC
        subjectMilk = MME_Storage.getMilkCurrent(subject)
        playerMilk = MME_Storage.getMilkCurrent(playerActor)
    EndIf
    If conditions != None
        subjectSnapshot = conditions.MME_SubjectMilk
        playerSnapshot = conditions.MME_TargetMilk
    EndIf
    Form originalPlayerTopic = Game.GetFormFromFile(0x062E91, "MilkModNEW.esp")
    Form originalNPCTopic = Game.GetFormFromFile(0x062E8F, "MilkModNEW.esp")
    Form playerInfo = MMEExtensionsNative.GetFormByEditorID("MMEExt_OStimBreastfeeding_PlayerDrinks")
    Form npcInfo = MMEExtensionsNative.GetFormByEditorID("MMEExt_OStimBreastfeeding_NPCDrinks")
    Form playerTopic = MMEExtensionsNative.GetParentTopic(playerInfo)
    Form npcTopic = MMEExtensionsNative.GetParentTopic(npcInfo)
    Bool playerIndependent = playerTopic != None && playerTopic != originalPlayerTopic
    Bool npcIndependent = npcTopic != None && npcTopic != originalNPCTopic
    Bool detected = MMEOStimBreastfeeding.IsOStimDetected()
    Bool setting = JsonUtil.GetIntValue(SettingsFile, "enableOStimBreastfeeding", 0) == 1
    GlobalVariable gate = GetOStimDialogueAvailabilityGlobal()
    Float gateValue = -1.0
    If gate != None
        gateValue = gate.GetValue()
    EndIf
    ; Phase 2: evaluate with Skyrim's real dialogue roles: speaker is Subject,
    ; player is Target for both opposite directions. Direction changes which
    ; cached milk value the copied MME condition tests, not the CTDA role order.
    ; Skyrim evaluates both choice INFOs with the dialogue speaker as Subject
    ; and the player as Target. MME's Fragment_00 maps those roles to
    ; SubjectMilk (NPC) and TargetMilk (player), respectively.
    Int[] playerConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(playerInfo, subject, playerActor)
    Int[] npcConditions = MMEExtensionsNative.EvaluateTopicInfoConditions(npcInfo, subject, playerActor)
    String[] playerDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(playerInfo)
    String[] npcDescriptions = MMEExtensionsNative.DescribeTopicInfoConditions(npcInfo)
    Bool playerEligible = playerInfo != None && MMEExtensionsNative.EvaluateTopicInfo(playerInfo, subject, playerActor)
    Bool npcEligible = npcInfo != None && MMEExtensionsNative.EvaluateTopicInfo(npcInfo, subject, playerActor)
    Form[] visibleInfos = MMEExtensionsNative.GetVisibleDialogueInfos()
    Int visibleInfoCount = 0
    If visibleInfos != None
        visibleInfoCount = visibleInfos.Length
    EndIf
    Bool visibilityAvailable = visibleInfoCount > 0
    Bool playerVisible = visibleInfos != None && visibleInfos.Find(playerInfo) >= 0
    Bool npcVisible = visibleInfos != None && visibleInfos.Find(npcInfo) >= 0

    ; Phase 3: distinguish a real populated-menu absence from an unknowable
    ; post-dialogue state. An empty list after selection is not evidence that a
    ; choice was never shown; selection/start events provide stronger evidence.
    Debug.Trace("[MME Extensions OStim BF Dialogue] detected=" + DiagnosticBool(detected) + " setting=" + DiagnosticBool(setting) + " global=" + gate + " value=" + gateValue)
    Debug.Trace("[MME Extensions OStim BF Dialogue] CTDA roles: Subject=speaker " + subject + " (milk live=" + subjectMilk + ", MME_SubjectMilk=" + subjectSnapshot + "); Target=player " + playerActor + " (milk live=" + playerMilk + ", MME_TargetMilk=" + playerSnapshot + ")")
    Debug.Trace("[MME Extensions OStim BF Dialogue] Player INFO=" + playerInfo + " topic=" + playerTopic + " independent=" + DiagnosticBool(playerIndependent) + " sources=" + SourceFileSummary(playerInfo))
    Debug.Trace("[MME Extensions OStim BF Dialogue] visible list available=" + DiagnosticBool(visibilityAvailable) + " count=" + visibleInfoCount)
    Debug.Trace("[MME Extensions OStim BF Dialogue] Player CTDA=" + ConditionResults(playerConditions) + " | " + ConditionDescriptions(playerDescriptions) + " eligible=" + DiagnosticBool(playerEligible) + " visible=" + DiagnosticBool(playerVisible))
    Debug.Trace("[MME Extensions OStim BF Dialogue] NPC INFO=" + npcInfo + " topic=" + npcTopic + " independent=" + DiagnosticBool(npcIndependent) + " sources=" + SourceFileSummary(npcInfo))
    Debug.Trace("[MME Extensions OStim BF Dialogue] NPC CTDA=" + ConditionResults(npcConditions) + " | " + ConditionDescriptions(npcDescriptions) + " eligible=" + DiagnosticBool(npcEligible) + " visible=" + DiagnosticBool(npcVisible))

    If !detected
        Debug.Notification("OStim BF DEBUG: UNAVAILABLE - OStim not detected")
    ElseIf !setting
        Debug.Notification("OStim BF DEBUG: UNAVAILABLE - setting OFF")
    ElseIf gate == None || gateValue < 1.0
        Debug.Notification("OStim BF DEBUG: UNAVAILABLE - dialogue gate OFF")
    ElseIf !playerIndependent || !npcIndependent
        Debug.Notification("OStim BF DEBUG: FAIL options are not independent DIALs")
    Else
        If visibilityAvailable
            Debug.Notification("OStim BF DEBUG: Player<-NPC=" + ShortRouteResult(playerEligible, playerVisible, playerConditions, "PlayerOStim") + " | NPC<-Player=" + ShortRouteResult(npcEligible, npcVisible, npcConditions, "NPCOStim"))
        ElseIf playerEligible || npcEligible
            Debug.Notification("OStim BF DEBUG: conditions PASS; visibility unavailable")
            Debug.Trace("[MME Extensions OStim BF Dialogue] visibility cannot be determined because the dialogue choice list has already progressed or closed")
        Else
            Debug.Notification("OStim BF DEBUG: conditions FAIL | Player=" + ShortRouteResult(playerEligible, False, playerConditions, "PlayerOStim") + " | NPC=" + ShortRouteResult(npcEligible, False, npcConditions, "NPCOStim"))
        EndIf
        If visibilityAvailable && ((playerEligible && !playerVisible) || (npcEligible && !npcVisible))
            Debug.Notification("OStim BF DEBUG: conditions PASS but option NOT SHOWN")
        ElseIf conditions != None && subjectMilk >= 1.0 && subjectSnapshot < 1.0
            Debug.Notification("OStim BF DEBUG: NPC milk live PASS, MME SubjectMilk stale")
        ElseIf conditions != None && playerMilk >= 1.0 && playerSnapshot < 1.0
            Debug.Notification("OStim BF DEBUG: Player milk live PASS, MME TargetMilk stale")
        EndIf
    EndIf
EndFunction

; Reports the exact live values used by MME's two breastfeeding INFOs. The
; snapshot repeats only when its state changes, so selecting MME's opening
; line exposes the before/after Fragment_00 refresh without notification spam.
Function ShowDialogueEligibilitySnapshot(Actor subject, Bool postRefresh = False)
    ; Compare live MME storage against Fragment_00's cached MilkQC snapshot.
    ; This reveals stale dialogue inputs without rewriting them or bypassing any
    ; original MME blocker spells, sex rules, or Milk Maid membership checks.
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
    GlobalVariable ostimDialogueGate = GetOStimDialogueAvailabilityGlobal()
    Float ostimDialogueGateValue = -1.0
    If ostimDialogueGate != None
        ostimDialogueGateValue = ostimDialogueGate.GetValue()
    EndIf
    Bool sexLabPlayerDrinks = subjectShared && conditions.MME_BreasfeedingAnimationsCheck
    Bool sexLabNPCDrinks = playerShared && conditions.MME_BreasfeedingAnimationsCheck
    Bool ostimPlayerDrinks = subjectShared && OStimDialogueAvailable
    Bool ostimNPCDrinks = playerShared && OStimDialogueAvailable
    Bool milkSnapshotsRefreshed = conditions.MME_TargetMilk == playerMilk && conditions.MME_SubjectMilk == subjectMilk
    String snapshotState = postRefresh + ":" + subject.GetFormID() + ":" + playerMilk + ":" + subjectMilk + ":" + conditions.MME_TargetMilk + ":" + conditions.MME_SubjectMilk + ":" + subjectBlockers + ":" + playerBlockers + ":" + conditions.MME_DialogueMilking + ":" + conditions.MME_BreasfeedingAnimationsCheck + ":" + OStimDialogueAvailable + ":" + ostimDialogueGateValue
    If subject == LastDialogueDiagnosticActor && snapshotState == LastDialogueDiagnosticState
        Return
    EndIf
    LastDialogueDiagnosticActor = subject
    LastDialogueDiagnosticState = snapshotState

    String line0 = "MME opening INFO observed=" + DiagnosticBool(MMEOpeningRefreshObserved) + " / post-refresh snapshot=" + DiagnosticBool(postRefresh)
    String line1 = "Player milk=" + playerMilk + " / TargetMilk=" + conditions.MME_TargetMilk + " | NPC milk=" + subjectMilk + " / SubjectMilk=" + conditions.MME_SubjectMilk
    String line2 = "NPC maid=" + DiagnosticBool(subjectMaid) + " / SubjectMaid=" + DiagnosticBool(conditions.MME_SubjectMaid) + " / SubjectSlave=" + DiagnosticBool(conditions.MME_SubjectSlave) + " | refresh NPC=" + DiagnosticBool(subjectRefreshAllowed) + " Player=" + DiagnosticBool(playerRefreshAllowed)
    String line3 = "blockers NPC=" + subjectBlockers + " | Player=" + playerBlockers + " | SexLabAnim=" + DiagnosticBool(conditions.MME_BreasfeedingAnimationsCheck)
    String line4 = "DialogueMilking=" + DiagnosticBool(conditions.MME_DialogueMilking) + " / root=" + DiagnosticBool(rootEligible) + " | OStim detected=" + DiagnosticBool(ostimDetected) + " setting=" + DiagnosticBool(ostimSetting) + " property=" + DiagnosticBool(OStimDialogueAvailable) + " global=" + ostimDialogueGateValue
    String line5 = "Player drinks: SexLab=" + DiagnosticBool(sexLabPlayerDrinks) + " OStim=" + DiagnosticBool(ostimPlayerDrinks) + " | NPC drinks: SexLab=" + DiagnosticBool(sexLabNPCDrinks) + " OStim=" + DiagnosticBool(ostimNPCDrinks)
    Debug.Trace("[MME Extensions Dialogue] " + GetActorName(subject) + " | " + line0)
    Debug.Trace("[MME Extensions Dialogue] " + line1)
    Debug.Trace("[MME Extensions Dialogue] " + line2)
    Debug.Trace("[MME Extensions Dialogue] " + line3)
    Debug.Trace("[MME Extensions Dialogue] " + line4)
    Debug.Trace("[MME Extensions Dialogue] " + line5)
    Debug.Notification("Dialogue DEBUG: Hey there refresh=" + DiagnosticBool(MMEOpeningRefreshObserved) + " / milk snapshots refreshed=" + DiagnosticBool(milkSnapshotsRefreshed))
    Debug.Notification("Dialogue DEBUG: SexLab gate=" + DiagnosticBool(conditions.MME_BreasfeedingAnimationsCheck) + " / OStim property=" + DiagnosticBool(OStimDialogueAvailable) + " global=" + ostimDialogueGateValue)
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
            Debug.Notification(GetActorName(candidate) + " is completely milky. Watch the furniture, those things have momentum!")
        Else
            Debug.Notification(GetActorName(candidate) + " is half-milky. Her boobs are getting heavy enough that walking normally is becoming optional.")
        EndIf
    EndIf
    Return crossing
EndFunction

; Scans the current cell and selects one highest-priority capacity sound.
Function ScanNearbyMilkMaids(Bool publishSkyrimNet = False, Bool processReactions = True)
    ; Phase 1: scan the player and current cell once for all consumers. Only
    ; loaded actors inside NearbyRange are considered; MME membership is checked
    ; again by ProcessActor/Skyrim.Net helpers before publication.
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
    ; Phase 2: accumulate capacity crossings and short-lived context text during
    ; the scan. Skyrim.Net receives one combined Player-attached event rather
    ; than one event per NPC, keeping context bounded and replaceable.
    String milkStatuses = ""
    String armorStatuses = ""
    Int milkmaidCount = 0
    Int armorCount = 0
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
        ; Configurable stripping piggybacks on the shared scan but is player-only
        ; for now. NPCs keep MME's original stripping until a later version.
        If processReactions && candidate == Game.GetPlayer() && MMEArmorScript.IsConfigurableArmorStrippingEnabled()
            MMEArmorScript.EvaluateArmorStrippingForActor(candidate, MME_Storage.getMilkCurrent(candidate), "poll")
        EndIf
        String status = EvaluateMilkMaidFlavor(candidate)
        If status != ""
            If milkStatuses != ""
                milkStatuses = milkStatuses + " "
            EndIf
            milkStatuses = milkStatuses + status
            milkmaidCount += 1
        EndIf
        If publishSkyrimNet
            String armorStatus = MMEAlertsSkyrimNet.BuildNearbyArmorStatus(candidate)
            If armorStatus != ""
                If armorStatuses != ""
                    armorStatuses = armorStatuses + "\n"
                EndIf
                armorStatuses = armorStatuses + armorStatus
                armorCount += 1
            EndIf
        EndIf
        i += 1
    EndWhile
    If publishSkyrimNet
        MMEAlertsSkyrimNet.SendNearbyMilkStatuses(Game.GetPlayer(), milkStatuses, nearbyActors.Length, milkmaidCount)
        MMEAlertsSkyrimNet.SendNearbyArmorStatuses(Game.GetPlayer(), armorStatuses, armorCount)
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

    ; Phase 3: play reactions after enumeration. Delaying animation work until
    ; the scan ends avoids actor-state mutations while iterating references.
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
