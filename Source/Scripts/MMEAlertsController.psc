Scriptname MMEAlertsController extends Quest

; Skyrim.Net requires an instance callback on an attached quest script.
; Keep all API calls and playback gates inside the publication boundary.
Function OnTentaclePlayerLine(String response, Int success)
    MMEAlertsSkyrimNet.PlayTentaclePlayerLine(response, success)
EndFunction

; ---------------------------------------------------------------------------
; Controller-owned persistent state
; ---------------------------------------------------------------------------
; This quest is the long-lived coordinator for native events and periodic work.
; All timed features share one OnUpdate schedule below; adding an independent
; polling quest should be a last resort. Each Next* value is an absolute real-
; time deadline.
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
Float NextThoughtDebugUpdate = 0.0
Float NextArmorCheck = 0.0
Float NextArmorReminder = 0.0
Int ArmorReminderRetries = 0
Float NextOStimBreastfeedingWatchdog = 0.0
Float NextThoughtGameTime = 0.0
Float NextInjectionGameTime = 0.0
String ArmorCheckReminderShownAtKey = "MMEExtensions.ArmorReminder.ShownAt"
String ArmorCheckReminderAttemptAtKey = "MMEExtensions.ArmorReminder.AttemptAt"
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
    ; The service reminder uses Papyrus's menu event instead of the native
    ; TESTopicInfoEvent observer. Refresh this registration after every load.
    UnregisterForMenu("Dialogue Menu")
    RegisterForMenu("Dialogue Menu")
    ; Reminder timestamps are shared through StorageUtil so redundant controller
    ; initialization cannot clear an active cooldown.
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
    RefreshGameTimeScheduling()
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
        RefreshNewMilkMaidDialogueAvailability(False)
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
    RefreshNewMilkMaidDialogueAvailability(liveGate)
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
    GlobalVariable newMilkMaidGate = GetNewMilkMaidDialogueAvailabilityGlobal()
    If newMilkMaidGate != None
        newMilkMaidGate.SetValue(0.0)
    EndIf
    UnregisterForUpdate()
    UnregisterForModEvent("MMEExtensions_Lifecycle")
    UnregisterForModEvent("MMEExtensions_MMEEffectApplied")
    UnregisterForModEvent("MMEExtensions_MMEEffectRemoved")
    UnregisterForMenu("Dialogue Menu")
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
    NextThoughtDebugUpdate = 0.0
    NextArmorCheck = 0.0
    NextArmorReminder = 0.0
    ArmorReminderRetries = 0
    MMEArmorScript.CancelPlayerArmorCheck(Game.GetPlayer())
    ; Restore MME's own stripping while MME Extensions is disabled.
    MMEArmorScript.ApplyArmorStrippingMasterToggle()
    NextOStimBreastfeedingWatchdog = 0.0
    StopGameTimeScheduling()
EndFunction

; Menu-open is safe but may arrive just before Skyrim publishes its dialogue
; target. Defer resolution through the controller's existing one-shot scheduler
; and retry briefly instead of reading MenuTopicManager's transient pointers.
Event OnMenuOpen(String menuName)
    If menuName == "Dialogue Menu" && IsExtensionsEnabled() && JsonUtil.GetIntValue(SettingsFile, "enableArmorCheckReminder", 1) == 1
        ArmorReminderRetries = 0
        NextArmorReminder = Utility.GetCurrentRealTime() + 0.25
        ScheduleNextUpdate()
    EndIf
EndEvent

Function TryShowServiceArmorReminder()
    Actor reminderSpeaker = Game.GetDialogueTarget() as Actor
    If reminderSpeaker == None
        ArmorReminderRetries += 1
        If ArmorReminderRetries < 4
            NextArmorReminder = Utility.GetCurrentRealTime() + 0.25
        Else
            NextArmorReminder = 0.0
            ArmorReminderRetries = 0
        EndIf
        Return
    EndIf

    NextArmorReminder = 0.0
    ArmorReminderRetries = 0
    Float reminderNow = Utility.GetCurrentRealTime()
    Float reminderCooldown = JsonUtil.GetFloatValue(SettingsFile, "armorCheckReminderCooldown", 60.0)
    If reminderCooldown < 0.0
        reminderCooldown = 0.0
    ElseIf reminderCooldown > 300.0
        reminderCooldown = 300.0
    EndIf
    Float lastReminderShown = StorageUtil.GetFloatValue(None, ArmorCheckReminderShownAtKey, -1000.0)
    Float lastReminderAttempt = StorageUtil.GetFloatValue(None, ArmorCheckReminderAttemptAtKey, -1000.0)
    If lastReminderShown > reminderNow
        lastReminderShown = -1000.0
    EndIf
    If lastReminderAttempt > reminderNow
        lastReminderAttempt = -1000.0
    EndIf
    If reminderNow - lastReminderShown >= reminderCooldown && reminderNow - lastReminderAttempt >= 2.0
        StorageUtil.SetFloatValue(None, ArmorCheckReminderAttemptAtKey, reminderNow)
        If MMEServiceArmorReminder.TryShow(reminderSpeaker)
            StorageUtil.SetFloatValue(None, ArmorCheckReminderShownAtKey, reminderNow)
        EndIf
    EndIf
EndFunction

; Own the one game-time registration on this established quest script. Thoughts
; and armor injections keep independent deadlines, but whichever is due first
; owns the next single update. Existing saves already have this VM instance,
; unlike a newly attached timer quest script.
Function RefreshGameTimeScheduling()
    Float now = Utility.GetCurrentGameTime()
    ScheduleNextThought(now)
    ScheduleNextInjection(now)
    ArmNextGameTimeUpdate(now)
EndFunction

; MCM changes refresh only the affected feature's deadline, preserving the
; other feature's already-randomized interval.
Function RefreshThoughtScheduling()
    Float now = Utility.GetCurrentGameTime()
    ScheduleNextThought(now)
    ArmNextGameTimeUpdate(now)
EndFunction

Function RefreshInjectionScheduling()
    Float now = Utility.GetCurrentGameTime()
    ScheduleNextInjection(now)
    ArmNextGameTimeUpdate(now)
EndFunction

Function ScheduleNextThought(Float now)
    If !MMEThoughts.IsNormalThoughtsEnabled()
        NextThoughtGameTime = 0.0
        MMEThoughts.TraceDebug("normal schedule disabled")
        Return
    EndIf
    Float baseInterval = JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsInterval", 12.0)
    Float randomness = JsonUtil.GetFloatValue(SettingsFile, "milkMaidThoughtsRandomness", 4.0)
    Float nextInterval = MMEThoughts.CalculateNextInterval(baseInterval, randomness)
    NextThoughtGameTime = now + (nextInterval / 24.0)
    MMEThoughts.TraceDebug("normal schedule armed | next=" + nextInterval + " game hours")
EndFunction

Function ScheduleNextInjection(Float now)
    If !MMETentacleEffects.IsEnabled()
        NextInjectionGameTime = 0.0
        MMETentacleEffects.TraceDiagnostic(False, "schedule disabled")
        Return
    EndIf
    Float baseInterval = JsonUtil.GetFloatValue(SettingsFile, "armorInjectionInterval", 12.0)
    Float variation = JsonUtil.GetFloatValue(SettingsFile, "armorInjectionVariation", 4.0)
    Float nextInterval = MMETentacleEffects.CalculateNextInterval(baseInterval, variation)
    NextInjectionGameTime = now + (nextInterval / 24.0)
    MMETentacleEffects.TraceDiagnostic(False, "schedule armed | next=" + nextInterval + " game hours")
EndFunction

Function ArmNextGameTimeUpdate(Float now)
    UnregisterForUpdateGameTime()
    Float nextDeadline = 0.0
    If NextThoughtGameTime > 0.0
        nextDeadline = NextThoughtGameTime
    EndIf
    If NextInjectionGameTime > 0.0 && (nextDeadline <= 0.0 || NextInjectionGameTime < nextDeadline)
        nextDeadline = NextInjectionGameTime
    EndIf
    If nextDeadline <= 0.0
        Return
    EndIf
    Float delayHours = (nextDeadline - now) * 24.0
    If delayHours < 0.01
        delayHours = 0.01
    EndIf
    RegisterForSingleUpdateGameTime(delayHours)
EndFunction

Function StopGameTimeScheduling()
    UnregisterForUpdateGameTime()
    NextThoughtGameTime = 0.0
    NextInjectionGameTime = 0.0
EndFunction

Event OnUpdateGameTime()
    Float now = Utility.GetCurrentGameTime()
    Bool thoughtDue = NextThoughtGameTime > 0.0 && now >= NextThoughtGameTime
    Bool injectionDue = NextInjectionGameTime > 0.0 && now >= NextInjectionGameTime
    If !thoughtDue && !injectionDue
        ArmNextGameTimeUpdate(now)
        Return
    EndIf
    ; Never cast None to an array: the VM rejects that cast, and the compiler
    ; can reuse its temporary for the native result, causing a type mismatch.
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(NearbyRange)
    If thoughtDue
        MMEThoughts.GenerateAndShowThought(nearbyActors, True)
        ScheduleNextThought(now)
    EndIf
    If injectionDue
        MMETentacleEffects.RunInjectionCheck(nearbyActors, False)
        ScheduleNextInjection(now)
    EndIf
    ArmNextGameTimeUpdate(now)
EndEvent

; Manual MCM action: bypasses only the timer wait and otherwise executes the
; same production validation, chance, effects, and notification path.
Function RunArmorInjectionCheckNow()
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(NearbyRange)
    MMETentacleEffects.RunInjectionCheck(nearbyActors, True)
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
    RefreshNewMilkMaidDialogueAvailability(IsMMESexLabBreastfeedingAvailable())
EndFunction

GlobalVariable Function GetOStimDialogueAvailabilityGlobal() Global
    ; This gate controls only the extension choices that require OStim.
    ; Resolve it through SKSE's stable file/local-ID API so dialogue remains
    ; available even if the optional native bridge fails to load for a session.
    Return Game.GetFormFromFile(0x00085A, "MMEAlert.esp") as GlobalVariable
EndFunction

Bool Function IsMMESexLabBreastfeedingAvailable()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Return MMEDebug.IsOriginalMMESexLabBreastfeedingAvailable(milkController)
EndFunction

; This gate belongs only to the separate SexLab New Milk Maid INFO. The working
; OStim New Milk Maid INFO continues to use the original OStim gate (00085A).
; The two choices therefore remain mutually exclusive in the same choice list.
Function RefreshNewMilkMaidDialogueAvailability(Bool sexLabAvailable)
    Bool available = IsExtensionsEnabled() && !MMEOStimBreastfeeding.IsBreastfeedingEnabled() && sexLabAvailable
    GlobalVariable dialogueGate = GetNewMilkMaidDialogueAvailabilityGlobal()
    If dialogueGate != None
        If available
            dialogueGate.SetValue(1.0)
        Else
            dialogueGate.SetValue(0.0)
        EndIf
    Else
        Debug.Trace("[MME Extensions Dialogue] SexLab New Milk Maid availability GlobalVariable is missing")
    EndIf
EndFunction

GlobalVariable Function GetNewMilkMaidDialogueAvailabilityGlobal() Global
    Return Game.GetFormFromFile(0x00087D, "MMEAlert.esp") as GlobalVariable
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
    If reason == "load"
        UnregisterForMenu("Dialogue Menu")
        RegisterForMenu("Dialogue Menu")
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
    ; recurring capacity/Skyrim.Net/debug schedules; armor checks remain
    ; event-driven one-shots inserted into the same deadline set.
    UnregisterForUpdate()
    If !IsExtensionsEnabled()
        NextCapacityUpdate = 0.0
        NextSkyrimNetUpdate = 0.0
        NextDebugUpdate = 0.0
        NextThoughtDebugUpdate = 0.0
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
    If JsonUtil.GetIntValue(SettingsFile, "enableMilkMaidThoughtsDebug", 0) == 1
        NextThoughtDebugUpdate = now + 15.0
    Else
        NextThoughtDebugUpdate = 0.0
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
    If NextThoughtDebugUpdate > 0.0
        candidate = NextThoughtDebugUpdate - now
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
    If NextArmorReminder > 0.0
        candidate = NextArmorReminder - now
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
        ; The dialogue-menu armor reminder needs a short retry. All other work
        ; is intentionally throttled to one second to avoid tight Papyrus loops.
        Float minimumDelay = 1.0
        If NextArmorReminder > 0.0
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
        NextArmorReminder = 0.0
        ArmorReminderRetries = 0
        MMEArmorScript.CancelPlayerArmorCheck(Game.GetPlayer())
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Bool capacityDue = NextCapacityUpdate > 0.0 && now >= NextCapacityUpdate
    Bool skyrimNetDue = NextSkyrimNetUpdate > 0.0 && now >= NextSkyrimNetUpdate
    Bool debugDue = NextDebugUpdate > 0.0 && now >= NextDebugUpdate
    Bool thoughtDebugDue = NextThoughtDebugUpdate > 0.0 && now >= NextThoughtDebugUpdate
    Bool armorReminderDue = NextArmorReminder > 0.0 && now >= NextArmorReminder
    Bool ostimBreastfeedingDue = NextOStimBreastfeedingWatchdog > 0.0 && now >= NextOStimBreastfeedingWatchdog
    If capacityDue || skyrimNetDue || thoughtDebugDue
        ScanNearbyMilkMaids(skyrimNetDue, capacityDue, thoughtDebugDue)
    EndIf
    ; Advance recurring deadlines from this callback's timestamp. One-shot
    ; armor deadlines are cleared only when their work is consumed.
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
    If thoughtDebugDue
        NextThoughtDebugUpdate = now + 15.0
    EndIf
    If armorReminderDue
        TryShowServiceArmorReminder()
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

; Audits MME's original SexLab breastfeeding route only. This runs from the
; native Hey there INFO event after Fragment_00 has refreshed MME's condition
; quest; it observes live records and state but never starts or alters a scene.
; Audits only the independent OStim alternatives. A route can pass its CTDAs
; yet remain absent when its INFO was incorrectly placed in an original MME
; response chain; that structural distinction is deliberately surfaced.
; Reports the exact live values used by MME's two breastfeeding INFOs. The
; snapshot repeats only when its state changes, so selecting MME's opening
; line exposes the before/after Fragment_00 refresh without notification spam.
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
            Debug.Notification(GetActorName(candidate) + "'s tits are full! Watch out for those watermelons!")
        Else
            Debug.Notification(GetActorName(candidate) + "'s tits are half-full! Walking normally is optional.")
        EndIf
    EndIf
    Return crossing
EndFunction

; Scans the current cell and selects one highest-priority capacity sound.
Function ScanNearbyMilkMaids(Bool publishSkyrimNet = False, Bool processReactions = True, Bool runRapidThought = False)
    ; Phase 1: scan the player and current cell once for all consumers. Only
    ; loaded actors inside NearbyRange are considered; MME membership is checked
    ; again by ProcessActor/Skyrim.Net helpers before publication.
    Actor[] reactionActors = new Actor[128]
    Int[] reactionKinds = new Int[128]
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(NearbyRange)
    If runRapidThought
        MMEThoughts.RunFastDebug(nearbyActors)
    EndIf
    If nearbyActors.Length == 0
        Debug.Trace("[MME Extensions Native Scan] scanner returned no actors; capacity scan skipped")
        If JsonUtil.GetIntValue(SettingsFile, "enableNativeScanDiagnostic", 0) == 1
            Debug.Notification("Native Scan failed: no actors returned")
        EndIf
        Return
    EndIf
    ; Thought-only deadlines exit after the shared pipeline consumes the native
    ; result; capacity/status enumeration remains reserved for its own deadlines.
    If runRapidThought && !publishSkyrimNet && !processReactions
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
