Scriptname MMEDrinkTracker extends ReferenceAlias

String SettingsFile = "/MMEAlerts/Settings"
Float lastDrinkTime = -10.0
Form lastDrinkItem = None

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
