Scriptname MMEEstrusPregnancyTest Hidden

String Function TypeName(Int kind) Global
    If kind == 1
        Return "Spider"
    ElseIf kind == 2
        Return "Dwemer"
    EndIf
    Return "Chaurus"
EndFunction

String Function RunTest(Int kind) Global
    Actor target = Game.GetPlayer()
    MMELog.MasterDiagnostic("[MME Extensions Estrus Test] entry | actor=" + target + " | kind=" + kind)
    If kind < 0 || kind > 2 || target == None
        MMELog.Alarm("[MME Extensions Estrus Test] SMOKE ALARM | operation=player pregnancy test | actor=" + target + " | invalid target/type=" + kind)
        Return "Invalid target/type"
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float lease = StorageUtil.GetFloatValue(None, "MME.EstrusTest.Lease", -1.0)
    If lease > now && lease < now + 150.0
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | actor=" + target + " | test already pending")
        Return "Test already pending"
    EndIf
    StorageUtil.SetFloatValue(None, "MME.EstrusTest.Lease", now + 140.0)
    String result = ExecuteTest(target, kind)
    StorageUtil.UnsetFloatValue(None, "MME.EstrusTest.Lease")
    MMELog.MasterDiagnostic("[MME Extensions Estrus Test] cleanup | actor=" + target + " | result=" + result)
    Debug.Notification("Estrus test: " + result)
    Return result
EndFunction

String Function ExecuteTest(Actor target, Int kind) Global
    If Game.GetModByName("EstrusUnified.esp") == 255 || SKSE.GetPluginVersion("EstrusUnified") == -1
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | Estrus ESP/DLL absent")
        Return "Estrus ESP/DLL missing"
    EndIf
    If !EstrusUnifiedAPI.IsReady()
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | API not ready")
        Return "Estrus API not ready"
    EndIf
    Debug.Notification("Estrus test queued: close MCM to run on the player.")
    Int remaining = 120
    While Utility.IsInMenuMode() && remaining > 0
        Utility.WaitMenuMode(0.5)
        remaining -= 1
    EndWhile
    If Utility.IsInMenuMode()
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | menu-close timeout")
        Return "Canceled: menu stayed open"
    EndIf
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String blocked = MMEAnimationSafety.GetStartBlockReason(target, milk, False)
    If target.IsChild()
        blocked = "child actor"
    ElseIf target.IsBleedingOut()
        blocked = "bleeding out"
    ElseIf !target.IsAIEnabled()
        blocked = "AI disabled"
    EndIf
    If blocked != ""
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | actor=" + target + " | reason=" + blocked)
        Return "Player unavailable: " + blocked
    EndIf
    If !EstrusUnifiedAPI.IsReady()
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | API became unready before dispatch")
        Return "Estrus API not ready"
    EndIf
    Int before = EstrusUnifiedAPI.GetPregnancyType(target)
    If before < 0 || before > 3
        MMELog.Alarm("[MME Extensions Estrus Test] SMOKE ALARM | operation=eligibility query | actor=" + target + " | invalid API type=" + before)
        Return "Invalid API result"
    EndIf
    If before != 0
        MMELog.MasterDiagnostic("[MME Extensions Estrus Test] skip | actor=" + target + " | existing/API type=" + before)
        Return "Player already pregnant"
    EndIf
    String eventName = "ECStartAnimation"
    If kind == 1
        eventName = "ESStartAnimation"
    ElseIf kind == 2
        eventName = "EDStartAnimation"
    EndIf
    MMELog.MasterDiagnostic("[MME Extensions Estrus Test] eligibility passed | actor=" + target + " | final eligibility owned by Estrus")
    Int handle = ModEvent.Create(eventName)
    If handle == 0
        MMELog.Alarm("[MME Extensions Estrus Test] SMOKE ALARM | operation=create effect event | actor=" + target + " | event=" + eventName + " | allocation failed")
        Return "Event creation failed"
    EndIf
    ModEvent.PushForm(handle, target)
    ModEvent.PushForm(handle, target)
    ModEvent.PushInt(handle, -1)
    ModEvent.PushBool(handle, False)
    ModEvent.PushInt(handle, 0)
    ModEvent.PushBool(handle, False)
    Bool sent = ModEvent.Send(handle)
    MMELog.MasterDiagnostic("[MME Extensions Estrus Test] dispatch | actor=" + target + " | event=" + eventName + " | sent=" + sent)
    If !sent
        MMELog.Alarm("[MME Extensions Estrus Test] SMOKE ALARM | operation=send effect event | actor=" + target + " | event=" + eventName + " | dispatch failed")
        Return "Event dispatch failed"
    EndIf
    remaining = 10
    While remaining > 0
        Utility.WaitMenuMode(1.0)
        Int actual = EstrusUnifiedAPI.GetPregnancyType(target)
        If actual < 0 || actual > 3
            MMELog.Alarm("[MME Extensions Estrus Test] SMOKE ALARM | operation=verify pregnancy | actor=" + target + " | invalid API type=" + actual)
            Return "Invalid API result"
        ElseIf actual == kind + 1
            MMELog.MasterDiagnostic("[MME Extensions Estrus Test] verified | actor=" + target + " | pregnancyType=" + actual)
            Return TypeName(kind) + " pregnancy confirmed"
        ElseIf actual != 0
            MMELog.MasterDiagnostic("[MME Extensions Estrus Test] result mismatch | actor=" + target + " | expected=" + (kind + 1) + " | actual=" + actual)
            Return "Unexpected pregnancy type: " + actual
        EndIf
        remaining -= 1
    EndWhile
    MMELog.MasterDiagnostic("[MME Extensions Estrus Test] unconfirmed | actor=" + target + " | Estrus may have declined request; check its settings/logs")
    Return "Not confirmed; check Estrus settings/logs"
EndFunction
