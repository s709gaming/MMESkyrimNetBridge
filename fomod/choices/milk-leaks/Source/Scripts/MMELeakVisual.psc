Scriptname MMELeakVisual extends ObjectReference

; Own immutable armor/addon forms. Read existing Oninus positioning preferences
; without changing its effects, model paths, actor storage, or timers.
Event OnContainerChanged(ObjectReference newContainer, ObjectReference oldContainer)
    Actor wearer = newContainer as Actor
    If wearer == None || !wearer.Is3DLoaded()
        Return
    EndIf
    Utility.Wait(0.1)
    If !wearer.IsEquipped(GetBaseObject())
        Return
    EndIf
    OninusLactis original = Quest.GetQuest("OninusLactisQuest") as OninusLactis
    If original == None
        ReportFailure(wearer, "Oninus positioning quest unavailable")
        Return
    EndIf
    Float[] offset = original.NippleOffsetL
    Float scale = original.EmitterScale
    If original.actorStorage != None && original.actorStorage.HasNpcStorage(wearer)
        offset = original.actorStorage.GetNpcOffset(wearer)
        scale = original.actorStorage.GetNpcScale(wearer)
    EndIf
    If offset.Length < 3
        ReportFailure(wearer, "invalid nipple offset")
        Return
    EndIf
    NetImmerse.SetNodeLocalPosition(wearer, "Lactis Group L", offset, False)
    NetImmerse.SetNodeLocalPosition(wearer, "Lactis Group R", offset, False)
    NetImmerse.SetNodeScale(wearer, "Lactis Group L", original.GlobalEmitterScale * scale, False)
    NetImmerse.SetNodeScale(wearer, "Lactis Group R", original.GlobalEmitterScale * scale, False)
    NetImmerse.SetNodeScale(wearer, "Lactis Axis L", 0.0, False)
    NetImmerse.SetNodeScale(wearer, "Lactis Axis R", 0.0, False)
EndEvent

Function ReportFailure(Actor wearer, String reason)
    MMEMilkLeaks service = MMEMilkLeakAPI.Manager()
    If service != None
        service.Alarm("position", wearer, reason)
    EndIf
EndFunction
