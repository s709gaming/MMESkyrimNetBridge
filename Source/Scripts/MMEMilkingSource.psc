Scriptname MMEMilkingSource Hidden

; Actor-local metadata only. MME owns all milking, milk, equipment and inventory.
; Methods: 0 Generic, 1 Hands, 2 Pump, 3 Equipment, 4 Living Tendrils, 5 Dwemer.
Bool Function Enabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
EndFunction

Function Trace(String reportText) Global
    MMELog.MasterDiagnostic("[MME Milking Source] " + reportText)
EndFunction

Function Alarm(Actor target, String operation, String reason) Global
    String alarmKey = "MME.Source.Alarm." + operation
    Float now = Utility.GetCurrentRealTime()
    Float previous = StorageUtil.GetFloatValue(target, alarmKey, -300.0)
    If now < previous || now - previous >= 60.0
        StorageUtil.SetFloatValue(target, alarmKey, now)
        MMELog.Alarm("[MME Milking Source] actor=" + target + " | operation=" + operation + " | failure=" + reason)
    EndIf
EndFunction

String Function MethodName(Int method) Global
    If method == 1
        Return "Hands"
    ElseIf method == 2
        Return "Pump"
    ElseIf method == 3
        Return "Milking Equipment"
    ElseIf method == 4
        Return "Living Tendrils"
    ElseIf method == 5
        Return "Dwemer Machinery"
    EndIf
    Return "Generic"
EndFunction

Int Function ResolveMethod(Actor target, Int mode) Global
    If mode == 0
        Return 2
    ElseIf mode == 1
        Return 1
    ElseIf mode == 2
        Return 3
    ElseIf mode == 3
        Return 4
    ElseIf mode == 4 && StorageUtil.GetIntValue(target, "MMEExtensions.DwemerArmor.InProgress", 0) == 1
        Return 5
    EndIf
    Return 0
EndFunction

; Called by the verified MilkQUEST hook after mode selection and all early exits.
Int Function Begin(Actor target, Int mode, Armor equipment) Global
    If !Enabled()
        If target != None
            ClearActive(target)
        EndIf
        Return 0
    EndIf
    If target == None
        Alarm(None, "begin", "missing actor")
        Return 0
    EndIf
    If target.IsChild() || !StorageUtil.HasFloatValue(target, "MME.MilkMaid.Level")
        Trace("skip | actor=" + target + " | not an adult Milk Maid")
        Return 0
    EndIf
    Int previous = StorageUtil.GetIntValue(target, "MME.Source.Active", 0)
    If previous > 0
        ; MME already rejects overlapping milking. A leftover tracker is stale;
        ; do not turn an interrupted session into a successful completion.
        Trace("cleanup | actor=" + target + " | abandoned session=" + previous)
        ClearActive(target)
    EndIf
    Int sessionId = StorageUtil.GetIntValue(target, "MME.Source.Counter", 0) + 1
    If sessionId <= 0
        Alarm(target, "begin", "session counter exhausted or corrupt")
        ClearActive(target)
        Return 0
    EndIf
    Int method = ResolveMethod(target, mode)
    If mode < 0 || mode > 4
        Alarm(target, "classify", "invalid MME mode=" + mode + "; Generic used")
    EndIf
    StorageUtil.SetIntValue(target, "MME.Source.Counter", sessionId)
    StorageUtil.SetIntValue(target, "MME.Source.Method", method)
    StorageUtil.SetFormValue(target, "MME.Source.Equipment", equipment)
    ; Exact read performed by original MME_Storage.getMilkCurrent, without spam.
    StorageUtil.SetFloatValue(target, "MME.Source.Before", StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkCount", 0.0))
    ; Publish the token only after its facts are ready.
    StorageUtil.SetIntValue(target, "MME.Source.Active", sessionId)
    Trace("START | actor=" + target + " | session=" + sessionId + " | mode=" + mode + " | method=" + MethodName(method) + " | equipment=" + equipment)
    Return sessionId
EndFunction

Function ClearActive(Actor target) Global
    StorageUtil.UnsetIntValue(target, "MME.Source.Active")
    StorageUtil.UnsetIntValue(target, "MME.Source.Method")
    StorageUtil.UnsetFormValue(target, "MME.Source.Equipment")
    StorageUtil.UnsetFloatValue(target, "MME.Source.Before")
EndFunction

; Local token survives the original MME stack/save. Stop is not completion.
Function Complete(Actor target, Int sessionId, Int bottles, Int boobgasms, Int cumCount) Global
    If sessionId <= 0
        Return
    EndIf
    If target == None
        Alarm(None, "complete", "missing actor for session=" + sessionId)
        Return
    EndIf
    Int active = StorageUtil.GetIntValue(target, "MME.Source.Active", 0)
    If active != sessionId
        If sessionId > StorageUtil.GetIntValue(target, "MME.Source.Counter", 0)
            Alarm(target, "complete", "completion token was never issued: " + sessionId)
        Else
            Trace("skip | actor=" + target + " | late/duplicate completion=" + sessionId + " | active=" + active)
        EndIf
        Return
    EndIf
    If !Enabled()
        ClearActive(target)
        Trace("cleanup | actor=" + target + " | session=" + sessionId + " | Extensions disabled")
        Return
    EndIf
    If bottles < 0 || boobgasms < 0 || cumCount < 0
        Alarm(target, "complete", "invalid negative completion counts | session=" + sessionId)
        ClearActive(target)
        Return
    EndIf
    Int method = StorageUtil.GetIntValue(target, "MME.Source.Method", 0)
    Float beforeMilk = StorageUtil.GetFloatValue(target, "MME.Source.Before", 0.0)
    Float afterMilk = StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkCount", 0.0)
    Int removed = 0
    If bottles > 0 || afterMilk < beforeMilk
        removed = 1
    EndIf
    StorageUtil.UnsetIntValue(target, "MME.Source.LastSession")
    StorageUtil.SetIntValue(target, "MME.Source.LastMethod", method)
    StorageUtil.SetIntValue(target, "MME.Source.LastRemoved", removed)
    StorageUtil.SetIntValue(target, "MME.Source.LastBottles", bottles)
    StorageUtil.SetFloatValue(target, "MME.Source.LastDelta", beforeMilk - afterMilk)
    StorageUtil.SetFloatValue(target, "MME.Source.LastAfter", afterMilk)
    StorageUtil.SetFloatValue(target, "MME.Source.LastFinishedDays", Utility.GetCurrentGameTime())
    StorageUtil.SetFormValue(target, "MME.Source.LastEquipment", StorageUtil.GetFormValue(target, "MME.Source.Equipment"))
    StorageUtil.SetIntValue(target, "MME.Source.LastSession", sessionId)
    ClearActive(target)
    Trace("COMPLETE | actor=" + target + " | session=" + sessionId + " | method=" + MethodName(method) + " | bottles=" + bottles + " | milkRemoved=" + removed + " | before=" + beforeMilk + " | after=" + afterMilk)
    MMEPostMilking.RecordCompletion(target, sessionId, method, afterMilk, beforeMilk - afterMilk, removed)
EndFunction

; Original passive spell is authority, including old saves with no tracker yet.
Bool Function IsMilking(Actor target) Global
    If target == None || !Enabled()
        Return False
    EndIf
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milk == None || milk.BeingMilkedPassive == None
        Alarm(target, "query", "MME controller or milking passive unavailable")
        Return False
    EndIf
    Return target.HasSpell(milk.BeingMilkedPassive)
EndFunction

Int Function GetCurrentSession(Actor target) Global
    If !IsMilking(target)
        Return 0
    EndIf
    Return StorageUtil.GetIntValue(target, "MME.Source.Active", 0)
EndFunction

Int Function GetCurrentMethod(Actor target) Global
    If GetCurrentSession(target) <= 0
        Return 0
    EndIf
    Return StorageUtil.GetIntValue(target, "MME.Source.Method", 0)
EndFunction

Int Function GetLastMethod(Actor target) Global
    If GetLastSession(target) <= 0
        Return 0
    EndIf
    Return StorageUtil.GetIntValue(target, "MME.Source.LastMethod", 0)
EndFunction

Int Function GetLastSession(Actor target) Global
    If target == None || !Enabled()
        Return 0
    EndIf
    Return StorageUtil.GetIntValue(target, "MME.Source.LastSession", 0)
EndFunction

Bool Function WasMilkRemoved(Actor target) Global
    Return GetLastSession(target) > 0 && StorageUtil.GetIntValue(target, "MME.Source.LastRemoved", 0) == 1
EndFunction

Float Function GetLastNetMilkRemoved(Actor target) Global
    If GetLastSession(target) <= 0
        Return 0.0
    EndIf
    Return StorageUtil.GetFloatValue(target, "MME.Source.LastDelta", 0.0)
EndFunction

Float Function GetLastFinishedDays(Actor target) Global
    If GetLastSession(target) <= 0
        Return 0.0
    EndIf
    Return StorageUtil.GetFloatValue(target, "MME.Source.LastFinishedDays", 0.0)
EndFunction
