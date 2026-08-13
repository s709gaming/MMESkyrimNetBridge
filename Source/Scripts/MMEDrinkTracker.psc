Scriptname MMEDrinkTracker extends ReferenceAlias

String SettingsFile = "/MMEAlerts/Settings"
Float lastDrinkTime = -10.0
Form lastDrinkItem = None

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

; 0 = unsupported, 1 = milk, 2 = Lactacid.
Int Function GetSupportedDrinkKind(Form item)
    Form lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp")
    If item == lactacid
        Return 2
    EndIf
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    If item == hearthfireMilk
        Return 1
    EndIf
    FormList mmeMilks = Game.GetFormFromFile(0x05C81C, "MilkModNEW.esp") as FormList
    If mmeMilks != None && mmeMilks.HasForm(item)
        Return 1
    EndIf
    Return 0
EndFunction

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

Function HandleDrinkDetected(Actor drinker, Form drinkItem, Int drinkKind)
    ; This is the single expansion point for future milk-gain behavior.
    PublishDrinkEvent(drinker, drinkItem, drinkKind)
    PlayDrinkReaction(drinker)
    If JsonUtil.GetIntValue(SettingsFile, "enableDrinkDetectionDebug", 1) == 1
        String itemName = drinkItem.GetName()
        If itemName == ""
            itemName = "<unnamed milk item>"
        EndIf
        Debug.Notification("MME Alerts DRINK - " + GetActorName(drinker) + " drank " + itemName + ".")
    EndIf
EndFunction

Function PlayDrinkReaction(Actor drinker)
    If JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) != 1
        Return
    EndIf
    ; Mild randomized SOUN pool for both milk and Lactacid consumption.
    Sound reaction = Game.GetFormFromFile(0x000854, "MMEAlert.esp") as Sound
    If reaction == None
        Debug.Trace("[MMEAlert Drink] mild sound marker 000854 did not resolve")
        Return
    EndIf
    Int instance = reaction.Play(drinker)
    If instance > 0
        Float volume = JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0)
        Sound.SetInstanceVolume(instance, volume / 100.0)
    Else
        Debug.Trace("[MMEAlert Drink] mild Sound.Play returned " + instance)
    EndIf
EndFunction

Function PublishDrinkEvent(Actor drinker, Form drinkItem, Int drinkKind)
    Int handle = ModEvent.Create("MMEAlerts_DrinkDetected")
    If handle
        ModEvent.PushForm(handle, drinker)
        ModEvent.PushForm(handle, drinkItem)
        ModEvent.PushInt(handle, drinkKind)
        ModEvent.Send(handle)
    EndIf
EndFunction
