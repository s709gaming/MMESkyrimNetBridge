Scriptname MMEMilkLeakAPI Hidden

Bool Function IsDetected() Global
    Return Game.GetModByName("OninusLactis.esp") != 255
EndFunction

MMEMilkLeaks Function Manager() Global
    If Game.GetModByName("MME Extensions - Milk Leaks.esp") == 255
        Return None
    EndIf
    Return Quest.GetQuest("MMEExt_MilkLeaks") as MMEMilkLeaks
EndFunction

; 0=none, 1=ours, 2=external Oninus spray. A request is never proof.
Int Function GetLeakSource(Actor target) Global
    MMEMilkLeaks service = Manager()
    If service != None && target != None
        Return service.GetLeakSource(target)
    EndIf
    Return 0
EndFunction

Bool Function IsLeaking(Actor target) Global
    Return GetLeakSource(target) > 0
EndFunction

; -1=none/unknown, 0=Low, 1=Medium, 2=High. External intensity is unknown.
Int Function GetLeakIntensity(Actor target) Global
    MMEMilkLeaks service = Manager()
    If service != None && target != None
        Return service.GetLeakIntensity(target)
    EndIf
    Return -1
EndFunction

Function Observe(Actor[] nearby) Global
    MMEMilkLeaks service = Manager()
    If service != None
        service.Observe(nearby)
    EndIf
EndFunction

; Fresh snapshot of nearby loaded leaking actors, bounded to our scan range.
Actor[] Function GetLeakingActors() Global
    Actor[] result = new Actor[128]
    Actor[] nearby = MMEExtensionsNative.GetNearbyActors(2000.0)
    Int i = 0
    Int count = 0
    While i < nearby.Length && count < result.Length
        If nearby[i] != None && IsLeaking(nearby[i])
            result[count] = nearby[i]
            count += 1
        EndIf
        i += 1
    EndWhile
    Return result
EndFunction

Function EnsureDefaults() Global
    String settings = "/MMEAlerts/Settings"
    If !JsonUtil.HasIntValue(settings, "enableMilkLeaks")
        JsonUtil.SetIntValue(settings, "enableMilkLeaks", 1)
    EndIf
    If !JsonUtil.HasIntValue(settings, "milkLeakIntensity")
        JsonUtil.SetIntValue(settings, "milkLeakIntensity", 2)
    EndIf
    If !JsonUtil.HasIntValue(settings, "milkLeakThroughClothing")
        JsonUtil.SetIntValue(settings, "milkLeakThroughClothing", 1)
    EndIf
    If !JsonUtil.HasIntValue(settings, "milkLeakNarration")
        JsonUtil.SetIntValue(settings, "milkLeakNarration", 1)
    EndIf
    If !JsonUtil.HasFloatValue(settings, "milkLeakThreshold")
        JsonUtil.SetFloatValue(settings, "milkLeakThreshold", 100.0)
    EndIf
    If !JsonUtil.HasFloatValue(settings, "milkLeakNarrationCooldown")
        JsonUtil.SetFloatValue(settings, "milkLeakNarrationCooldown", 30.0)
    EndIf
    JsonUtil.Save(settings, False)
EndFunction
