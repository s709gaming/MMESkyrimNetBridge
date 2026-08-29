Scriptname MMEDiagnostics Hidden

; Dependency-light, player-triggered audits for the MCM Diagnostics page.
; Every MME Extensions form is resolved by plugin-local FormID so these checks
; keep working when the optional MMEExtensions.dll native bridge is unavailable.

String Function GetGateStatus() Global
    GlobalVariable gate = Game.GetFormFromFile(0x00085A, "MMEAlert.esp") as GlobalVariable
    If gate == None
        Return "MISSING"
    ElseIf gate.GetValue() >= 1.0
        Return "ON"
    EndIf
    Return "OFF"
EndFunction

String Function GetInstallStatus() Global
    If Game.GetFormFromFile(0x000800, "MMEAlert.esp") == None
        Return "QUEST MISSING"
    ElseIf Game.GetFormFromFile(0x00087A, "MMEAlert.esp") == None || Game.GetFormFromFile(0x00087B, "MMEAlert.esp") == None
        Return "DIALOGUE MISSING"
    EndIf
    Return "RECORDS READY"
EndFunction

String Function GetOStimStatus() Global
    If !MMEOStimBreastfeeding.IsOStimDetected()
        Return "NOT DETECTED"
    ElseIf JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) != 1
        Return "DISABLED"
    EndIf
    Return "ENABLED"
EndFunction

Function RefreshDialogueGate() Global
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller == None
        Report("FAIL: controller quest is missing", 2)
        Return
    EndIf
    controller.RefreshOStimDialogueAvailability()
    String gateStatus = GetGateStatus()
    If gateStatus == "ON"
        Report("PASS: OStim dialogue gate refreshed ON")
    Else
        Report("FAIL: OStim dialogue gate refreshed " + gateStatus, 2)
    EndIf
EndFunction

Function RunInstallAudit() Global
    Bool controllerReady = Game.GetFormFromFile(0x000800, "MMEAlert.esp") != None
    Bool gateReady = Game.GetFormFromFile(0x00085A, "MMEAlert.esp") != None
    Bool oldOStimReady = Game.GetFormFromFile(0x00085B, "MMEAlert.esp") != None && Game.GetFormFromFile(0x00085D, "MMEAlert.esp") != None && Game.GetFormFromFile(0x00085F, "MMEAlert.esp") != None && Game.GetFormFromFile(0x000860, "MMEAlert.esp") != None
    Bool newMaidReady = Game.GetFormFromFile(0x00087A, "MMEAlert.esp") != None && Game.GetFormFromFile(0x00087B, "MMEAlert.esp") != None
    Bool mmeReady = Quest.GetQuest("MME_MilkQUEST") != None
    Bool ostimReady = MMEOStimBreastfeeding.IsOStimDetected()
    Bool settingReady = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) == 1

    Report("Install: controller=" + YesNo(controllerReady) + " MME=" + YesNo(mmeReady) + " OStim=" + YesNo(ostimReady))
    Report("Records: gate=" + YesNo(gateReady) + " OStim choices=" + YesNo(oldOStimReady) + " new maid=" + YesNo(newMaidReady))
    Report("Runtime: setting=" + YesNo(settingReady) + " dialogue gate=" + GetGateStatus())
    If controllerReady && gateReady && oldOStimReady && newMaidReady && mmeReady && ostimReady && settingReady && GetGateStatus() == "ON"
        Report("PASS: installed dialogue runtime is ready")
    Else
        Report("FAIL: install/runtime audit found a blocker", 2)
    EndIf
EndFunction

Function RunCrosshairDialogueAudit() Global
    Actor candidate = Game.GetCurrentCrosshairRef() as Actor
    Actor playerActor = Game.GetPlayer()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If candidate == None
        Report("FAIL: no NPC under the crosshair", 2)
        Report("Close MCM, aim at the NPC, reopen, then run this audit")
        Return
    EndIf
    If playerActor == None || milkController == None
        Report("FAIL: player or MME controller is unavailable", 2)
        Return
    EndIf

    Bool playerMaid = StorageUtil.HasFloatValue(playerActor, "MME.MilkMaid.Level")
    Bool candidateMaid = StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.Level")
    Bool candidateAvailable = MMEDebug.IsActorAvailable(candidate)
    Float playerMilk = MME_Storage.getMilkCurrent(playerActor)
    Float candidateMilk = MME_Storage.getMilkCurrent(candidate)
    Bool playerSourceValid = MMEOStimBreastfeeding.ValidateMilkSource(playerActor, milkController, False)
    Bool candidateSourceValid = MMEOStimBreastfeeding.ValidateMilkSource(candidate, milkController, False)
    Bool gateOpen = GetGateStatus() == "ON"
    Bool ostimPlayerDrinksEligible = gateOpen && candidateSourceValid && candidateMilk >= 1.0
    Bool ostimNPCDrinksEligible = gateOpen && playerSourceValid && playerMilk >= 1.0
    String blocker = "none"
    If !gateOpen
        blocker = "OStim dialogue gate is " + GetGateStatus()
    ElseIf !playerMaid
        blocker = "player is not an MME Milk Maid"
    ElseIf playerMilk < 1.0
        blocker = "player has less than one milk"
    ElseIf !playerSourceValid
        blocker = "player is not a usable milk source"
    ElseIf !candidateAvailable
        blocker = "crosshair NPC is dead, disabled, or unloaded"
    ElseIf candidateMaid
        blocker = "crosshair NPC is already a Milk Maid"
    EndIf

    Report("Target: " + MMENewMilkMaid.GetActorName(candidate) + " available=" + YesNo(candidateAvailable) + " already maid=" + YesNo(candidateMaid))
    Report("Player: maid=" + YesNo(playerMaid) + " milk=" + playerMilk + " source valid=" + YesNo(playerSourceValid))
    Report("NPC: milk=" + candidateMilk + " source valid=" + YesNo(candidateSourceValid))
    Report("OStim choices: player drinks=" + PassFail(ostimPlayerDrinksEligible) + " NPC drinks=" + PassFail(ostimNPCDrinksEligible))
    If blocker == "none"
        Report("PASS: New Milk Maid route is runtime-eligible")
    Else
        Report("FAIL: " + blocker, 2)
    EndIf
EndFunction

Function Report(String reportText, Int severity = 0) Global
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableDiagnosticNotifications", 1) == 1
        Debug.Notification("MME Diagnostics: " + reportText)
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableDiagnosticPapyrusTrace", 0) == 1
        Debug.Trace("[MME Extensions Diagnostics] " + reportText, severity)
    EndIf
EndFunction

String Function YesNo(Bool value) Global
    If value
        Return "yes"
    EndIf
    Return "no"
EndFunction

String Function PassFail(Bool value) Global
    If value
        Return "PASS"
    EndIf
    Return "FAIL"
EndFunction
