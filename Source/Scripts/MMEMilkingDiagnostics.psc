Scriptname MMEMilkingDiagnostics Hidden

; Observational only: never retries, unlocks actors, or changes MME eligibility.
Bool Function Enabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePapyrusTrace", 0) == 1
EndFunction

Function Trace(String details) Global
    If Enabled()
        MMELog.MasterDiagnostic("[MME Milking Diagnostic] " + details)
    EndIf
EndFunction

Function AlarmOnce(String alarmKey, String details) Global
    String storageKey = "MMEExtensions.MilkingDiagnostic.Alarm." + alarmKey
    Float now = Utility.GetCurrentRealTime()
    Float previous = StorageUtil.GetFloatValue(None, storageKey, -1000.0)
    If now < previous || now - previous >= 300.0
        StorageUtil.SetFloatValue(None, storageKey, now)
        MMELog.Alarm("[MME Milking Diagnostic] SMOKE ALARM | " + details)
    EndIf
EndFunction

Function BeginCycle(Int hours) Global
    If Enabled()
        Trace("cycle start | elapsedHours=" + hours)
        StorageUtil.SetFloatValue(None, "MMEExtensions.MilkingDiagnostic.Cycle", Utility.GetCurrentRealTime())
    EndIf
EndFunction

Function EndCycle() Global
    StorageUtil.SetFloatValue(None, "MMEExtensions.MilkingDiagnostic.Cycle", -1.0)
EndFunction

Function ResetWatchdogs() Global
    EndCycle()
    StorageUtil.SetFloatValue(Game.GetPlayer(), "MMEExtensions.MilkingDiagnostic.Trigger", -1.0)
    Trace("watchdogs reset at event registration; timers do not carry across load")
EndFunction

Function Trigger(Actor target) Global
    Trace("accepted living trigger; casting MilkForSpriggan | actor=" + target)
    If Enabled() && target == Game.GetPlayer()
        StorageUtil.SetFloatValue(target, "MMEExtensions.MilkingDiagnostic.Trigger", Utility.GetCurrentRealTime())
    EndIf
EndFunction

Function EnterMilking(Actor target, Int mode) Global
    Trace("Milking entry | actor=" + target + " | mode=" + mode)
    StorageUtil.SetFloatValue(target, "MMEExtensions.MilkingDiagnostic.Trigger", -1.0)
EndFunction

Function ArmorSnapshot(Actor target, Form wornArmor, Float milk, Float maximum, Bool equipment, Bool baby, MilkQUEST controller) Global
    If !Enabled()
        Return
    EndIf
    String armorName = "None"
    If wornArmor != None
        armorName = wornArmor.GetName()
    EndIf
    Trace("armor gate | actor=" + target + " | slot32=" + wornArmor + " | name=" + armorName + " | milk=" + milk + " | max=" + maximum + " | rows=" + MME_Storage.getBreastRows(target) + " | equipment=" + equipment + " | baby=" + baby + " | basicIndex=" + controller.BasicLivingArmor.Find(armorName) + " | parasiteIndex=" + controller.ParasiteLivingArmor.Find(armorName))
    Trace("living name gate | recognized=" + (StringUtil.Find(armorName, "Spriggan") >= 0 || StringUtil.Find(armorName, "Living Arm") >= 0 || StringUtil.Find(armorName, "Hermaeus Mora") >= 0 || StringUtil.Find(armorName, "HM Priestess") >= 0 || StringUtil.Find(armorName, "Tentacle Armor") >= 0 || StringUtil.Find(armorName, "Tentacle Parasite") >= 0 || controller.BasicLivingArmor.Find(armorName) >= 0 || controller.ParasiteLivingArmor.Find(armorName) >= 0))
EndFunction

; Reuses the existing Extensions callback; no new polling registration.
; Player dispatch watchdog covers the reported test. NPCs retain entry traces.
Function CheckWatchdogs() Global
    If !Enabled()
        EndCycle()
        StorageUtil.SetFloatValue(Game.GetPlayer(), "MMEExtensions.MilkingDiagnostic.Trigger", -1.0)
        Return
    EndIf
    Float now = Utility.GetCurrentRealTime()
    Float cycleStart = StorageUtil.GetFloatValue(None, "MMEExtensions.MilkingDiagnostic.Cycle", -1.0)
    If cycleStart >= 0.0 && now - cycleStart >= 300.0
        AlarmOnce("cycle", "MME cycle has not completed after 300 real seconds; it may be waiting in milking/story, not necessarily broken")
        EndCycle()
    ElseIf cycleStart > now
        EndCycle()
    EndIf
    Actor playerActor = Game.GetPlayer()
    Float triggerStart = StorageUtil.GetFloatValue(playerActor, "MMEExtensions.MilkingDiagnostic.Trigger", -1.0)
    If triggerStart >= 0.0 && now - triggerStart >= 60.0
        AlarmOnce("dispatch", "player MilkForSpriggan trigger did not reach Milking entry within 60 real seconds; check effect gate footprints")
        StorageUtil.SetFloatValue(playerActor, "MMEExtensions.MilkingDiagnostic.Trigger", -1.0)
    ElseIf triggerStart > now
        StorageUtil.SetFloatValue(playerActor, "MMEExtensions.MilkingDiagnostic.Trigger", -1.0)
    EndIf
EndFunction
