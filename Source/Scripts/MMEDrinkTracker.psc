Scriptname MMEDrinkTracker extends ReferenceAlias

String SettingsFile = "/MMEAlerts/Settings"
Float lastDrinkTime = -10.0
Form lastDrinkItem = None

Event OnInit()
    RegisterNativeNPCDrink()
EndEvent

Event OnPlayerLoadGame()
    RegisterNativeNPCDrink()
EndEvent

Function RegisterNativeNPCDrink()
    UnregisterForModEvent("MMEExtensions_NPCPotionConsumed")
    RegisterForModEvent("MMEExtensions_NPCPotionConsumed", "OnNativeNPCPotionConsumed")
EndFunction

; Handles alias equip events; currently only the player alias is supported.
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    Actor drinker = GetActorReference()
    If drinker == None || akBaseObject == None
        Return
    EndIf

    Int drinkKind = GetSupportedDrinkKind(akBaseObject)
    If drinkKind == 0
        ; Useful rejection diagnostic while the drink report toggle is enabled.
        If (akBaseObject as Potion) != None && JsonUtil.GetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1) == 1
            Debug.Notification("MME Alerts DRINK TEST - potion equip received but unsupported: " + akBaseObject.GetName())
        EndIf
        Return
    EndIf
    If !IsEligibleDrinker(drinker)
        Return
    EndIf

    ; Technical duplicate filter only: it is not a gameplay cooldown.
    Float now = Utility.GetCurrentRealTime()
    If lastDrinkItem == akBaseObject && now - lastDrinkTime < 1.0
        Return
    EndIf
    lastDrinkItem = akBaseObject
    lastDrinkTime = now
    HandleDrinkDetected(drinker, akBaseObject, drinkKind)
EndEvent

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

; Receives low-cost native potion-equip events and processes only supported NPC milk.
Event OnNativeNPCPotionConsumed(String eventName, String pluginName, Float localFormID, Form sender)
    If JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkEffects", 1) != 1
        Return
    EndIf
    Bool diagnostic = JsonUtil.GetIntValue(SettingsFile, "enableNPCMilkConsumptionDiagnostic", 0) == 1
    Actor drinker = sender as Actor
    If drinker == None || drinker == Game.GetPlayer() || drinker.IsDead() || drinker.IsDisabled()
        Return
    EndIf
    Form drinkItem = Game.GetFormFromFile(localFormID as Int, pluginName)
    Int drinkKind = GetSupportedDrinkKind(drinkItem)
    If drinkKind == 0
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

    Float lastTime = StorageUtil.GetFloatValue(drinker, "MMEExtensions.NPCDrink.LastTime", -10.0)
    Int lastForm = StorageUtil.GetIntValue(drinker, "MMEExtensions.NPCDrink.LastForm", 0)
    If lastForm == drinkItem.GetFormID() && now - lastTime < 1.0
        If diagnostic
            Debug.Notification("NPC Milk: duplicate native event suppressed")
        EndIf
        Return
    EndIf
    StorageUtil.SetFloatValue(drinker, "MMEExtensions.NPCDrink.LastTime", now)
    StorageUtil.SetIntValue(drinker, "MMEExtensions.NPCDrink.LastForm", drinkItem.GetFormID())

    Float milkBefore = MME_Storage.getMilkCurrent(drinker)
    Float milkAdded = MMEMilkBoost.ApplyMilkDrinkBonusForActor(drinker, drinkKind, diagnostic)
    Float milkAfter = MME_Storage.getMilkCurrent(drinker)
    Int arousalBefore = MMEArousalBridge.GetCurrentArousal(drinker)
    Bool arousalSent = MMEArousalBridge.ApplyMilkDrinkArousalForActor(drinker, drinkItem, diagnostic)
    Int arousalAfter = MMEArousalBridge.GetCurrentArousal(drinker)
    MMEMilkDrinkEffects.PlayDrinkReaction(drinker, diagnostic)
    If diagnostic
        String arousalResult = "off/unavailable"
        If arousalSent
            arousalResult = arousalBefore + " -> " + arousalAfter
        EndIf
        Debug.Notification("NPC Milk: applied to " + actorName + " | milk " + milkBefore + " -> " + milkAfter + " (+" + milkAdded + ") | arousal " + arousalResult)
    EndIf
    Debug.Trace("[MMEAlert NPC Drink] processed " + actorName + " | " + pluginName + ":" + localFormID)
EndEvent

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
Function HandleDrinkDetected(Actor drinker, Form drinkItem, Int drinkKind)
    Bool addMilkDebug = JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1
    If addMilkDebug
        String itemName = drinkItem.GetName()
        If itemName == ""
            itemName = "<unnamed>"
        EndIf
        Debug.Notification("Milk Debug: detected " + itemName + " [form " + drinkItem.GetFormID() + ", kind " + drinkKind + "]")
    EndIf
    ; Keep the proven reaction path first so an optional gameplay integration
    ; cannot prevent the consumption sound from running.
    MMEMilkDrinkEffects.PlayDrinkReaction(drinker, JsonUtil.GetIntValue(SettingsFile, "enableAddMilkDebug", 0) == 1)
    ; MME milk and regular milk use the normal formula; Lactacid uses 2x flat.
    MMEMilkBoost.ApplyMilkDrinkBonus(drinker, drinkKind)
    MMEArousalBridge.ApplyMilkDrinkArousal(drinker, drinkItem)
    MMEAlertsSkyrimNet.SendMilkDrink(drinker, drinkItem)
    PublishDrinkEvent(drinker, drinkItem, drinkKind)
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
