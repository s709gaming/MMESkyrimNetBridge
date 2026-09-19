Scriptname MMEDrinkTracker extends ReferenceAlias

; ---------------------------------------------------------------------------
; Native potion-event intake and drink pipeline ownership
; ---------------------------------------------------------------------------
; The player alias hosts this listener, while the DLL publishes exact consumed
; ALCH forms for Player and NPC. Native form identity avoids unreliable inventory
; polling. Player and NPC branches converge only on reusable effect helpers.

String SettingsFile = "/MMEAlerts/Settings"

Event OnInit()
    StorageUtil.SetIntValue(None, "MMEExtensions.PlayerDrink.TrackerInitialized", 1)
    StorageUtil.SetFloatValue(None, "MMEExtensions.PlayerDrink.TrackerInitTime", Utility.GetCurrentRealTime())
    RegisterNativeDrink()
EndEvent

Event OnPlayerLoadGame()
    MMEReverseLevel reverseService = MMEReverseLevel.GetService()
    If reverseService != None
        reverseService.RecoverAfterLoad()
    EndIf
    StorageUtil.SetIntValue(None, "MMEExtensions.PlayerDrink.TrackerInitialized", 1)
    StorageUtil.SetFloatValue(None, "MMEExtensions.PlayerDrink.TrackerLoadTime", Utility.GetCurrentRealTime())
    RegisterNativeDrink()
EndEvent

; Registers the native drink listener permanently. The master toggle is
; enforced inside OnNativePotionConsumed, so re-enabling MME Extensions through
; the MCM works immediately without waiting for another load.
Function RegisterNativeDrink()
    ; Re-registration is idempotent and required after load because ModEvent
    ; subscriptions belong to the active script instance, not the save globally.
    UnregisterForModEvent("MMEExtensions_PotionConsumed")
    RegisterForModEvent("MMEExtensions_PotionConsumed", "OnNativePotionConsumed")
EndFunction

; Player consumption is observed by the player quest alias. Skyrim reliably
; sends OnObjectEquipped for a consumed potion to this alias, while the global
; TESEquipEvent source does not publish player potion use on every runtime/menu
; path. The native bridge remains the NPC source only.
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    ; Always leave a low-cost breadcrumb before any setting or item filter. The
    ; staged MCM audit can therefore distinguish a missing alias attachment from
    ; a supported-milk classification or gameplay rejection.
    StorageUtil.SetFloatValue(None, "MMEExtensions.PlayerDrink.LastAliasEventTime", Utility.GetCurrentRealTime())
    If akBaseObject != None
        StorageUtil.SetIntValue(None, "MMEExtensions.PlayerDrink.LastAliasEventForm", akBaseObject.GetFormID())
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled()
        Return
    EndIf
    Actor drinker = GetActorReference()
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1
    If drinker == None || akBaseObject == None
        If diagnostic
            MMELog.Diagnostic("[MMEAlert Player Drink] alias event rejected | missing player or equipped form")
        EndIf
        Return
    EndIf
    Int drinkKind = GetSupportedDrinkKind(akBaseObject)
    If drinkKind == 0
        If diagnostic && (akBaseObject as Potion) != None
            MMELog.Diagnostic("[MMEAlert Player Drink] alias potion ignored | unsupported | " + akBaseObject.GetName() + " | form=" + akBaseObject.GetFormID())
        EndIf
        Return
    EndIf
    If !IsEligibleDrinker(drinker)
        If diagnostic
            Debug.Notification("Milk Debug: drink detected but player is not an eligible MME Milk Maid")
            MMELog.Diagnostic("[MMEAlert Player Drink] alias milk rejected | ineligible player | " + akBaseObject.GetName())
        EndIf
        Return
    EndIf
    If diagnostic
        MMELog.Diagnostic("[MMEAlert Player Drink] alias milk accepted | " + akBaseObject.GetName() + " | form=" + akBaseObject.GetFormID())
    EndIf
    HandlePlayerDrink(drinker, akBaseObject, drinkKind, "PapyrusAlias", akBaseObject.GetFormID() as Float)
EndEvent

; Native CommonLib entry point for both player and NPC potion consumption.
Event OnNativePotionConsumed(String eventName, String pluginName, Float localFormID, Form sender)
    ; Phase 1: reconstruct the consumed form from load-order-independent source
    ; data, then reject non-milk items before any effects or narration occur.
    If !MMEAlertsController.IsExtensionsEnabled()
        Return
    EndIf
    Actor drinker = sender as Actor
    If drinker == None
        MMELog.Alarm("[MME Extensions Global NPC Drink] FAILURE: native potion event sender was not an Actor | " + pluginName + ":" + (localFormID as Int))
        Return
    EndIf
    Form drinkItem = Game.GetFormFromFile(localFormID as Int, pluginName)
    If drinkItem == None
        MMELog.Alarm("[MME Extensions Global NPC Drink] FAILURE: consumed form could not be reconstructed | actor=" + GetActorName(drinker) + " | " + pluginName + ":" + (localFormID as Int))
        Return
    EndIf
    Int drinkKind = GetSupportedDrinkKind(drinkItem)
    If drinkKind == 0
        Return
    EndIf
    ; MME/OStim breastfeeding equips a real basic-milk item as native parity.
    ; A validated breastfeeding session owns its narrow completion effects, so
    ; do not route that synthetic equip through the full ordinary drink pipeline.
    MMEDebug breastfeedingService = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
    If breastfeedingService != None && breastfeedingService.ShouldSuppressBreastfeedingDrink(drinker)
        Return
    EndIf
    If drinker == Game.GetPlayer()
        ; Defensive compatibility only. The native bridge intentionally filters
        ; the player so this branch should not run in the deployed build.
        HandlePlayerDrink(drinker, drinkItem, drinkKind, pluginName, localFormID)
    Else
        HandleNativeNPCDrink(drinker, drinkItem, drinkKind, pluginName, localFormID)
    EndIf
EndEvent

; Returns True when this native event is a duplicate within the given window.
Bool Function IsDuplicateDrink(Actor drinker, Form drinkItem, String keyPrefix, Float window)
    ; Used only by the NPC path, where dialogue-driven consumption and the
    ; native potion event can describe the same item close together. Per-actor
    ; form/time keys suppress that narrow duplicate window. The player path no
    ; longer uses this because its native event is one-per-consumption.
    Float now = Utility.GetCurrentRealTime()
    Float lastTime = StorageUtil.GetFloatValue(drinker, keyPrefix + ".LastTime", -10.0)
    Int lastForm = StorageUtil.GetIntValue(drinker, keyPrefix + ".LastForm", 0)
    If lastForm == drinkItem.GetFormID() && now - lastTime < window
        Return True
    EndIf
    StorageUtil.SetFloatValue(drinker, keyPrefix + ".LastTime", now)
    StorageUtil.SetIntValue(drinker, keyPrefix + ".LastForm", drinkItem.GetFormID())
    Return False
EndFunction

; Handles a supported player drink: effects, then the optional player animation.
Function HandlePlayerDrink(Actor drinker, Form drinkItem, Int drinkKind, String eventSource, Float eventFormID)
    ; Phase 1: player alias consumption is authoritative. eventSource is retained
    ; in diagnostics so a stray native callback is immediately distinguishable.
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1
    StorageUtil.SetFloatValue(None, "MMEExtensions.PlayerDrink.LastAcceptedTime", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(None, "MMEExtensions.PlayerDrink.LastAcceptedForm", drinkItem.GetFormID())
    If diagnostic
        String traceDrinkName = drinkItem.GetName()
        If traceDrinkName == ""
            traceDrinkName = "<unnamed>"
        EndIf
        MMELog.Diagnostic("[MMEAlert Player Drink] event accepted | " + eventSource + ":" + (eventFormID as Int) + " | " + traceDrinkName + " | t=" + Utility.GetCurrentRealTime())
    EndIf
    ; Snapshot established-Milkmaid state before any effects run, because MME's
    ; Lactacid conversion can add a brand-new Milk Maid during this drink. We
    ; only want our ordinary fondle animation for actors who were already
    ; established Milk Maids before this drink, never for a new conversion.
    Bool wasKnownMilkmaid = MMEAlertsController.IsKnownMilkmaid(drinker)
    Float milkDelta = HandleDrinkDetected(drinker, drinkItem, drinkKind)
    ; Phase 2: request the optional shared standing reaction after effects. The
    ; tracker owns completion through its existing single OnUpdate callback.
    Bool animDiagnostic = JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0) == 1
    String drinkLabel = drinkItem.GetName()
    If drinkLabel == ""
        drinkLabel = "<unnamed>"
    EndIf
    Bool animationStarted = MMEDrinkAnimation.StartDrinkAnimation(drinker, "enablePlayerDrinkAnimation", "playerDrinkAnimationDuration", "PLAYER", drinkLabel, animDiagnostic, wasKnownMilkmaid)
    If animationStarted
        RegisterForSingleUpdate(JsonUtil.GetFloatValue(SettingsFile, "playerDrinkAnimationDuration", 3.0))
    EndIf
    ; Phase 3: queue the existing deferred post-drink pass whenever the boost
    ; retained an attempted value, including a write MME clamped completely.
    If milkDelta > 0.0 || MMEArmorScript.HasPendingPlayerDrinkAttempt(drinker)
        MMEArmorScript.SchedulePlayerArmorCheck(drinker)
    EndIf
    MMELog.Diagnostic("[MMEAlert Player Drink] processed player | " + eventSource + ":" + eventFormID)
EndFunction

; Resets a pending player drink animation.
Event OnUpdate()
    MMEDrinkAnimation.ResetAnimation(Game.GetPlayer(), "PLAYER", JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0) == 1)
EndEvent

; Processes a supported NPC milk drink through the native event pipeline.
; diagnosticTest bypasses event deduplication only for the explicit Troubleshoot
; action; both paths otherwise share this exact validation/effects implementation.
Function HandleNativeNPCDrink(Actor drinker, Form drinkItem, Int drinkKind, String pluginName, Float localFormID, Bool diagnosticTest = False)
    ; Phase 1: validate a live adult NPC and suppress dialogue/native duplication
    ; before changing milk, arousal, sound, or notification state.
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0) == 1
    If diagnosticTest
        diagnostic = True
    EndIf
    If drinker == None || drinkItem == None
        MMELog.Alarm("[MME Extensions Global NPC Drink] FAILURE: handler received a missing actor or milk item")
        Return
    EndIf
    String actorName = GetActorName(drinker)
    StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "detected")
    StorageUtil.SetFloatValue(drinker, "MMEExtensions.NPCDrink.LastStageTime", Utility.GetCurrentRealTime())
    StorageUtil.SetIntValue(drinker, "MMEExtensions.NPCDrink.LastStageForm", drinkItem.GetFormID())
    If diagnostic
        ReportNPCDrink(diagnostic, diagnosticTest, "01 DETECTED | " + actorName + " | " + drinkItem.GetName() + " | source=" + pluginName + ":" + (localFormID as Int))
    EndIf
    If drinker == Game.GetPlayer() || drinker.IsDead() || drinker.IsDisabled() || !drinker.Is3DLoaded() || drinker.IsChild()
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "rejected actor state")
        If diagnostic
            ReportNPCDrink(diagnostic, diagnosticTest, "02 REJECTED | actor is player, dead, disabled, unloaded, or a child")
        EndIf
        Return
    EndIf

    ; Dialogue-driven NPC consumption suppresses the native event so the
    ; dialogue pipeline remains the sole owner of those extension effects.
    Float now = Utility.GetCurrentRealTime()
    Float suppressTime = StorageUtil.GetFloatValue(drinker, "MMEExtensions.NPCDrink.SuppressTime", -10.0)
    Int suppressForm = StorageUtil.GetIntValue(drinker, "MMEExtensions.NPCDrink.SuppressForm", 0)
    If !diagnosticTest && suppressForm == drinkItem.GetFormID() && now - suppressTime < 2.0
        StorageUtil.UnsetFloatValue(drinker, "MMEExtensions.NPCDrink.SuppressTime")
        StorageUtil.UnsetIntValue(drinker, "MMEExtensions.NPCDrink.SuppressForm")
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "dialogue duplicate suppressed")
        If diagnostic
            Debug.Notification("NPC Milk: duplicate dialogue event suppressed")
        EndIf
        Return
    EndIf

    If !diagnosticTest && IsDuplicateDrink(drinker, drinkItem, "MMEExtensions.NPCDrink", 1.0)
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "native duplicate suppressed")
        If diagnostic
            Debug.Notification("NPC Milk: duplicate native event suppressed")
        EndIf
        Return
    EndIf

    ActorBase baseInfo = drinker.GetLeveledActorBase()
    Keyword actorTypeNPC = Game.GetFormFromFile(0x013794, "Skyrim.esm") as Keyword
    If baseInfo == None || baseInfo.GetRace() == None || actorTypeNPC == None || !baseInfo.GetRace().HasKeyword(actorTypeNPC)
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "rejected non-NPC race")
        If diagnostic
            ReportNPCDrink(diagnostic, diagnosticTest, "02 REJECTED | ActorBase, race, or ActorTypeNPC validation failed")
        EndIf
        Return
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Bool establishedMilkmaid = milkController != None && MMEArmorScript.IsMMEMilkMaid(drinker, milkController)
    Int actorSex = baseInfo.GetSex()
    ; A non-Milkmaid Lactacid drink belongs to MME's conversion effect. The
    ; equip event can arrive before that effect finishes assigning the new maid,
    ; so treating it as an ordinary milk drink would add a second reaction while
    ; MME is still converting the actor.
    If drinkKind == 2 && !establishedMilkmaid
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "MME Lactacid conversion owned")
        ReportNPCDrink(diagnostic, diagnosticTest, "02 DELEGATED | non-Milkmaid Lactacid belongs to MME conversion")
        Return
    EndIf
    If !establishedMilkmaid
        If actorSex == 0 && JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidMaleDrinking", 1) != 1
            StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "male route disabled")
            If diagnostic
                ReportNPCDrink(diagnostic, diagnosticTest, "02 REJECTED | Allow Adult Men is off")
            EndIf
            Return
        ElseIf actorSex == 1 && JsonUtil.GetIntValue(SettingsFile, "enableNonMilkmaidFemaleDrinking", 1) != 1
            StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "female route disabled")
            If diagnostic
                ReportNPCDrink(diagnostic, diagnosticTest, "02 REJECTED | Allow Adult Women is off")
            EndIf
            Return
        ElseIf actorSex != 0 && actorSex != 1
            StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "unsupported sex")
            If diagnostic
                ReportNPCDrink(diagnostic, diagnosticTest, "02 REJECTED | unsupported ActorBase sex value " + actorSex)
            EndIf
            Return
        EndIf
    EndIf
    StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "validated")
    If diagnostic
        ReportNPCDrink(diagnostic, diagnosticTest, "02 VALIDATED | Milkmaid=" + establishedMilkmaid + " | sex=" + actorSex)
    EndIf

    ; Phase 2: select one factual reaction after the actual outcome is known.
    ; Disabling effects must not erase the verified drink or its local reaction.
    If JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1) != 1
        If diagnostic
            Debug.Notification("NPC Milk: effects disabled for " + actorName)
        EndIf
        String genericReaction = MMENPCDrinkDialogue.BuildDrinkReaction(drinker, drinkItem, establishedMilkmaid, 0.0, False)
        If establishedMilkmaid
            ShowNPCDrinkNotification(drinker, drinkItem, 0.0, False, genericReaction)
        Else
            MMENPCDrinkDialogue.ShowNotification(drinker, genericReaction)
        EndIf
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "complete effects disabled")
        ReportNPCDrink(diagnostic, diagnosticTest, "03 COMPLETE | effects disabled; reaction only")
        MMEAlertsSkyrimNet.NarrateNPCMilkDrink(drinker, False, genericReaction, diagnosticTest, establishedMilkmaid)
        Return
    EndIf

    ; Phase 3: ordinary adults use the same sex-specific arousal/reaction path
    ; proven by Give Milk. Only established Milkmaids receive MME milk gain.
    If !establishedMilkmaid
        String ordinaryReaction = MMENPCDrinkDialogue.ApplyPostDrink(drinker, drinkItem, diagnostic)
        If ordinaryReaction == ""
            MMELog.Alarm("[MME Extensions Global NPC Drink] FAILURE: ordinary-adult reaction pipeline returned blank | actor=" + actorName)
            StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "failed blank ordinary reaction")
            Return
        EndIf
        StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "complete ordinary adult")
        ReportNPCDrink(diagnostic, diagnosticTest, "03 COMPLETE | ordinary adult | no MME milk gain")
        MMEAlertsSkyrimNet.NarrateNPCMilkDrink(drinker, False, ordinaryReaction, diagnosticTest, False)
        MMELog.Diagnostic("[MMEAlert NPC Drink] processed ordinary adult " + actorName + " | " + pluginName + ":" + localFormID)
        Return
    EndIf

    ; Established Milkmaids retain the existing milk/arousal/sound behavior.
    Float milkBefore = MME_Storage.getMilkCurrent(drinker)
    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(drinker, drinkKind, diagnostic)
    Float milkAfter = MME_Storage.getMilkCurrent(drinker)
    Int arousalBefore = MMEArousalBridge.GetCurrentArousal(drinker)
    Bool arousalSent = MMEArousalBridge.ApplyMilkDrinkArousalForActor(drinker, drinkItem, diagnostic)
    Int arousalAfter = MMEArousalBridge.GetCurrentArousal(drinker)
    MMEMilkDrinkEffects.PlayDrinkReaction(drinker, diagnostic)
    String renderedReaction = MMENPCDrinkDialogue.BuildDrinkReaction(drinker, drinkItem, True, milkAdded, arousalSent)
    ShowNPCDrinkNotification(drinker, drinkItem, milkAdded, arousalSent, renderedReaction)
    If diagnostic
        String arousalResult = "off/unavailable"
        If arousalSent
            arousalResult = arousalBefore + " -> " + arousalAfter
        EndIf
        Debug.Notification("NPC Milk: applied to " + actorName + " | milk " + milkBefore + " -> " + milkAfter + " (+" + milkAdded + ") | arousal " + arousalResult)
    EndIf
    StorageUtil.SetStringValue(drinker, "MMEExtensions.NPCDrink.LastStage", "complete Milkmaid")
    ReportNPCDrink(diagnostic, diagnosticTest, "03 COMPLETE | Milkmaid | milk " + milkBefore + " -> " + milkAfter)
    MMEAlertsSkyrimNet.NarrateNPCMilkDrink(drinker, False, renderedReaction, diagnosticTest, True)
    MMELog.Diagnostic("[MMEAlert NPC Drink] processed " + actorName + " | " + pluginName + ":" + localFormID)
EndFunction

; Explicit Troubleshoot harness. It simulates the post-consumption callback with
; HearthFires milk and intentionally applies the same gameplay effects as a real
; global event, but does not add, remove, or equip an inventory item.
Function RunCrosshairNPCDrinkTest()
    Actor candidate = Game.GetCurrentCrosshairRef() as Actor
    If candidate == None
        MMELog.Status("[MME Extensions Global NPC Drink Test] 00 FAIL | no NPC under crosshair")
        Debug.Notification("Global NPC Drink Test: no NPC under crosshair")
        Return
    EndIf
    Form testMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    If testMilk == None
        MMELog.Alarm("[MME Extensions Global NPC Drink Test] 00 FAIL | HearthFires Jug of Milk did not resolve")
        Debug.Notification("Global NPC Drink Test: HearthFires milk missing")
        Return
    EndIf
    MMELog.Status("[MME Extensions Global NPC Drink Test] 00 START | actor=" + GetActorName(candidate) + " | simulated post-consumption event")
    Debug.Notification("Global NPC Drink Test: simulating Jug of Milk for " + GetActorName(candidate))
    HandleNativeNPCDrink(candidate, testMilk, 3, "MCMTest", 0x003534, True)
EndFunction

Function ReportNPCDrink(Bool diagnostic, Bool diagnosticTest, String reportText)
    If !diagnostic
        Return
    EndIf
    If diagnosticTest
        MMELog.Status("[MME Extensions Global NPC Drink Test] " + reportText)
    Else
        MMELog.Diagnostic("[MMEAlert NPC Drink] " + reportText)
        Debug.Notification("NPC Milk: " + reportText)
    EndIf
EndFunction

; Classifies drinks: 0 unsupported, 1 MME milk, 2 Lactacid, 3 HearthFires milk.
Int Function GetSupportedDrinkKind(Form item)
    Form lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp")
    If item == lactacid
        Return 2
    EndIf
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    If item == hearthfireMilk
        Return 3
    EndIf
    FormList mmeMilks = Game.GetFormFromFile(0x05C81C, "MilkModNEW.esp") as FormList
    If mmeMilks != None && mmeMilks.HasForm(item)
        Return 1
    EndIf
    Return 0
EndFunction

; NPC drink processing moved to HandleNativeNPCDrink above.

; Shows one concise result after a confirmed NPC drink and its extension effects.
Function ShowNPCDrinkNotification(Actor drinker, Form drinkItem, Float milkAdded, Bool arousalSent, String renderedReaction = "") Global
    String configFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(configFile, "enableNPCDrinkNotificationsDiagnostic", 0) == 1
    If JsonUtil.GetIntValue(configFile, "enableNPCDrinkNotifications", 1) != 1
        If diagnostic
            Debug.Notification("NPC Drink Notification: skipped - feature disabled")
        EndIf
        Return
    EndIf
    If drinker == None || drinkItem == None
        If diagnostic
            Debug.Notification("NPC Drink Notification: skipped - drinker or item missing")
        EndIf
        Return
    EndIf

    If renderedReaction == ""
        renderedReaction = MMENPCDrinkDialogue.BuildDrinkReaction(drinker, drinkItem, True, milkAdded, arousalSent)
    EndIf
    If renderedReaction == ""
        MMELog.Alarm("[MME Extensions Drink Reaction] FAILURE: Milkmaid HUD received a blank rendered reaction")
        Return
    EndIf
    Debug.Notification(renderedReaction)
    If diagnostic
        Debug.Notification("NPC Drink Notification: shown | milk +" + milkAdded + " | arousal " + arousalSent)
    EndIf
EndFunction

; Limits reactions to the player until broad NPC/SPID monitoring is validated.
Bool Function IsEligibleDrinker(Actor drinker)
    Actor playerActor = Game.GetPlayer()
    If drinker == playerActor
        Return True
    EndIf
    ; NPC DRINK DETECTION DISABLED FOR NOW.
    ; The event-time validation is retained here for later SPID testing:
    ;If drinker.IsDead() || drinker.IsDisabled() || !drinker.Is3DLoaded()
    ;    Return False
    ;EndIf
    ;If playerActor.GetDistance(drinker) > 2000.0
    ;    Return False
    ;EndIf
    ;Return True
    Return False
EndFunction

; Produces safe display text for event notifications and future bridge payloads.
String Function GetActorName(Actor actorRef) Global
    String result = actorRef.GetDisplayName()
    If result == ""
        ActorBase baseInfo = actorRef.GetLeveledActorBase()
        If baseInfo != None
            result = baseInfo.GetName()
        EndIf
    EndIf
    If result == ""
        result = "Unknown actor"
    EndIf
    Return result
EndFunction

; Centralizes drink publication, sound playback, and optional debug output.
; Returns the actual milk delta applied, so callers can gate follow-up effects.
Float Function HandleDrinkDetected(Actor drinker, Form drinkItem, Int drinkKind)
    ; Milk Drinking Diagnostics is the single player-drink diagnostic gate. It is
    ; read once here and propagated to every helper so one toggle reports the
    ; whole transaction: detection, sound, milk math, arousal, and notification.
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1
    If diagnostic
        String itemName = drinkItem.GetName()
        If itemName == ""
            itemName = "<unnamed>"
        EndIf
        Debug.Notification("Milk Debug: detected " + itemName + " [form " + drinkItem.GetFormID() + ", kind " + drinkKind + "]")
    EndIf
    ; Phase 1: keep the proven reaction path first so an optional gameplay integration
    ; cannot prevent the consumption sound from running.
    MMEMilkDrinkEffects.PlayDrinkReaction(drinker, diagnostic)
    ; MME milk and regular milk use the normal formula; Lactacid uses 2x flat.
    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(drinker, drinkKind, diagnostic)
    ; Phase 2: independent integrations observe the same confirmed drink. Their
    ; failures must not roll back MME milk that was already applied.
    Bool arousalSent = MMEArousalBridge.ApplyMilkDrinkArousalForActor(drinker, drinkItem, diagnostic)
    MMEAlertsSkyrimNet.SendMilkDrink(drinker, drinkItem)
    MMEAlertsSkyrimNet.NarratePlayerMilkDrink(drinker, drinkItem)
    ShowPlayerDrinkNotification(drinker, drinkItem, milkAdded, arousalSent, diagnostic)
    PublishDrinkEvent(drinker, drinkItem, drinkKind)
    Return milkAdded
EndFunction

Function ShowPlayerDrinkNotification(Actor drinker, Form drinkItem, Float milkAdded, Bool arousalSent, Bool diagnostic = False) Global
    String configFile = "/MMEAlerts/Settings"
    If JsonUtil.GetIntValue(configFile, "enablePlayerDrinkNotifications", 1) != 1
        If diagnostic
            Debug.Notification("Player Drink Notification: skipped - feature disabled")
        EndIf
        Return
    EndIf
    If drinker == None || drinkItem == None
        If diagnostic
            Debug.Notification("Player Drink Notification: skipped - drinker or item missing")
        EndIf
        Return
    EndIf

    String drinkName = drinkItem.GetName()
    If drinkName == ""
        drinkName = "some milk"
    EndIf
    String actorName = GetActorName(drinker)
    String notificationText = ""
    If milkAdded > 0.0 && arousalSent
        notificationText = actorName + " drank " + drinkName + ". " + actorName + "'s breasts feel heavier. " + actorName + " is feeling horny."
    ElseIf milkAdded > 0.0
        notificationText = actorName + " drank " + drinkName + ". " + actorName + "'s breasts feel heavier."
    ElseIf arousalSent
        notificationText = actorName + " drank " + drinkName + ". " + actorName + " is feeling horny."
    Else
        notificationText = actorName + " drank " + drinkName + ". It was great."
    EndIf
    Debug.Notification(notificationText)
    If diagnostic
        Debug.Notification("Player Drink Notification: shown | milk +" + milkAdded + " | arousal " + arousalSent)
    EndIf
EndFunction

; Broadcasts a normalized drink event for future native/SkyrimNet consumers.
Function PublishDrinkEvent(Actor drinker, Form drinkItem, Int drinkKind)
    Int handle = ModEvent.Create("MMEAlerts_DrinkDetected")
    If handle
        ModEvent.PushForm(handle, drinker)
        ModEvent.PushForm(handle, drinkItem)
        ModEvent.PushInt(handle, drinkKind)
        ModEvent.Send(handle)
    EndIf
EndFunction
