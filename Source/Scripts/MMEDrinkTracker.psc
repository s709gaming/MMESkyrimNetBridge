Scriptname MMEDrinkTracker extends ReferenceAlias

; ---------------------------------------------------------------------------
; Native potion-event intake and drink pipeline ownership
; ---------------------------------------------------------------------------
; The player alias hosts this listener, while the DLL publishes exact consumed
; ALCH forms for Player and NPC. Native form identity avoids unreliable inventory
; polling. Player and NPC branches converge only on reusable effect helpers.

String SettingsFile = "/MMEAlerts/Settings"

Event OnInit()
    RegisterNativeDrink()
EndEvent

Event OnPlayerLoadGame()
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

; ---------------------------------------------------------------------------
; Old player tracking through the ESP player alias. Kept as a temporary
; rollback/reference path until CommonLib player tracking is fully verified.
; ---------------------------------------------------------------------------
;Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
;    If !MMEAlertsController.IsExtensionsEnabled()
;        Return
;    EndIf
;    Actor drinker = GetActorReference()
;    If drinker == None || akBaseObject == None
;        Return
;    EndIf
;    Int drinkKind = GetSupportedDrinkKind(akBaseObject)
;    If drinkKind == 0
;        Return
;    EndIf
;    If !IsEligibleDrinker(drinker)
;        Return
;    EndIf
;    HandleDrinkDetected(drinker, akBaseObject, drinkKind)
;EndEvent

; Native CommonLib entry point for both player and NPC potion consumption.
Event OnNativePotionConsumed(String eventName, String pluginName, Float localFormID, Form sender)
    ; Phase 1: reconstruct the consumed form from load-order-independent source
    ; data, then reject non-milk items before any effects or narration occur.
    If !MMEAlertsController.IsExtensionsEnabled()
        Return
    EndIf
    Actor drinker = sender as Actor
    If drinker == None
        Return
    EndIf
    Form drinkItem = Game.GetFormFromFile(localFormID as Int, pluginName)
    Int drinkKind = GetSupportedDrinkKind(drinkItem)
    If drinkKind == 0
        Return
    EndIf
    If drinker == Game.GetPlayer()
        HandleNativePlayerDrink(drinker, drinkItem, drinkKind, pluginName, localFormID)
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
Function HandleNativePlayerDrink(Actor drinker, Form drinkItem, Int drinkKind, String pluginName, Float localFormID)
    ; Phase 1: the native potion-consumption event is the single authoritative
    ; player source and fires once per real item consumption, so every event is
    ; processed. The same-item debounce remains NPC-only because dialogue and
    ; native paths can both describe one NPC drink there.
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1
    If diagnostic
        String traceDrinkName = drinkItem.GetName()
        If traceDrinkName == ""
            traceDrinkName = "<unnamed>"
        EndIf
        Debug.Trace("[MMEAlert Player Drink] native event accepted | " + pluginName + ":" + (localFormID as Int) + " | " + traceDrinkName + " | t=" + Utility.GetCurrentRealTime())
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
    Debug.Trace("[MMEAlert Player Drink] processed player | " + pluginName + ":" + localFormID)
EndFunction

; Resets a pending player drink animation.
Event OnUpdate()
    MMEDrinkAnimation.ResetAnimation(Game.GetPlayer(), "PLAYER", JsonUtil.GetIntValue(SettingsFile, "enableMilkDrinkAnimationDiagnostic", 0) == 1)
EndEvent

; Processes a supported NPC milk drink through the native event pipeline.
Function HandleNativeNPCDrink(Actor drinker, Form drinkItem, Int drinkKind, String pluginName, Float localFormID)
    ; Phase 1: require a live real MME Milk Maid and suppress dialogue/native
    ; duplication before changing milk, arousal, sound, or Skyrim.Net context.
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0) == 1
    If drinker.IsDead() || drinker.IsDisabled()
        Return
    EndIf
    String actorName = GetActorName(drinker)
    If diagnostic
        Debug.Notification("NPC Milk: detected " + actorName + " drinking " + drinkItem.GetName())
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.MilkMaid.Find(drinker) == -1
        If diagnostic
            Debug.Notification("NPC Milk: ignored " + actorName + " - not an MME Milkmaid")
        EndIf
        Return
    EndIf

    ; Dialogue-driven NPC consumption suppresses the native event so the
    ; dialogue pipeline remains the sole owner of those extension effects.
    Float now = Utility.GetCurrentRealTime()
    Float suppressTime = StorageUtil.GetFloatValue(drinker, "MMEExtensions.NPCDrink.SuppressTime", -10.0)
    Int suppressForm = StorageUtil.GetIntValue(drinker, "MMEExtensions.NPCDrink.SuppressForm", 0)
    If suppressForm == drinkItem.GetFormID() && now - suppressTime < 2.0
        StorageUtil.UnsetFloatValue(drinker, "MMEExtensions.NPCDrink.SuppressTime")
        StorageUtil.UnsetIntValue(drinker, "MMEExtensions.NPCDrink.SuppressForm")
        If diagnostic
            Debug.Notification("NPC Milk: duplicate dialogue event suppressed")
        EndIf
        Return
    EndIf

    If IsDuplicateDrink(drinker, drinkItem, "MMEExtensions.NPCDrink", 1.0)
        If diagnostic
            Debug.Notification("NPC Milk: duplicate native event suppressed")
        EndIf
        Return
    EndIf

    ; Phase 2: narration observes the confirmed drink independently of optional
    ; Extensions gameplay effects. Disabling effects must not erase the event.
    MMEAlertsSkyrimNet.NarrateNPCMilkDrink(drinker)
    If JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1) != 1
        If diagnostic
            Debug.Notification("NPC Milk: effects disabled for " + actorName)
        EndIf
        ShowNPCDrinkNotification(drinker, drinkItem, 0.0, False)
        Return
    EndIf

    ; Phase 3: apply milk/arousal/sound through actor-safe shared integrations,
    ; then emit one consolidated result notification.
    Float milkBefore = MME_Storage.getMilkCurrent(drinker)
    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(drinker, drinkKind, diagnostic)
    Float milkAfter = MME_Storage.getMilkCurrent(drinker)
    Int arousalBefore = MMEArousalBridge.GetCurrentArousal(drinker)
    Bool arousalSent = MMEArousalBridge.ApplyMilkDrinkArousalForActor(drinker, drinkItem, diagnostic)
    Int arousalAfter = MMEArousalBridge.GetCurrentArousal(drinker)
    MMEMilkDrinkEffects.PlayDrinkReaction(drinker, diagnostic)
    ShowNPCDrinkNotification(drinker, drinkItem, milkAdded, arousalSent)
    If diagnostic
        String arousalResult = "off/unavailable"
        If arousalSent
            arousalResult = arousalBefore + " -> " + arousalAfter
        EndIf
        Debug.Notification("NPC Milk: applied to " + actorName + " | milk " + milkBefore + " -> " + milkAfter + " (+" + milkAdded + ") | arousal " + arousalResult)
    EndIf
    Debug.Trace("[MMEAlert NPC Drink] processed " + actorName + " | " + pluginName + ":" + localFormID)
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
Function ShowNPCDrinkNotification(Actor drinker, Form drinkItem, Float milkAdded, Bool arousalSent) Global
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

    String actorName = drinker.GetDisplayName()
    If actorName == ""
        actorName = "A Milk Maid"
    EndIf
    String drinkName = drinkItem.GetName()
    If drinkName == ""
        drinkName = "some milk"
    EndIf
    String notificationText = ""
    If milkAdded > 0.0 && arousalSent
        notificationText = actorName + " drank " + drinkName + ". She's hornier, heavier, and looking far too pleased with herself."
    ElseIf milkAdded > 0.0
        notificationText = actorName + " drank " + drinkName + ". She's already feeling heavier. This appears to be going according to plan."
    ElseIf arousalSent
        notificationText = actorName + " drank " + drinkName + ". Her milk didn't budge, but her imagination certainly did."
    Else
        notificationText = actorName + " drank " + drinkName + ". Whatever the plan was, she's committed now."
    EndIf
    Debug.Notification(notificationText)
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
String Function GetActorName(Actor actorRef)
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
    String notificationText = ""
    If milkAdded > 0.0 && arousalSent
        notificationText = "You drank " + drinkName + ". Your breasts feel heavier, your thoughts feel dirtier, and this was probably the point."
    ElseIf milkAdded > 0.0
        notificationText = "You drank " + drinkName + ". Your breasts feel heavier. Excellent planning."
    ElseIf arousalSent
        notificationText = "You drank " + drinkName + ". Nothing got heavier, but your thoughts certainly did."
    Else
        notificationText = "You drank " + drinkName + ". Bold strategy. Results pending."
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
