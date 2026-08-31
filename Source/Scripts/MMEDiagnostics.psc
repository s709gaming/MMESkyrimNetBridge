Scriptname MMEDiagnostics Hidden

; Dependency-light, player-triggered audits for the MCM Troubleshoot page.
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
    ElseIf Game.GetFormFromFile(0x00087A, "MMEAlert.esp") == None || Game.GetFormFromFile(0x00087E, "MMEAlert.esp") == None || Game.GetFormFromFile(0x00087D, "MMEAlert.esp") == None || Game.GetFormFromFile(0x00087F, "MMEAlert.esp") == None || Game.GetFormFromFile(0x000880, "MMEAlert.esp") == None
        Return "DIALOGUE MISSING"
    ElseIf Game.GetFormFromFile(0x000881, "MMEAlert.esp") == None || Game.GetFormFromFile(0x000882, "MMEAlert.esp") == None || Game.GetFormFromFile(0x000883, "MMEAlert.esp") == None || Game.GetFormFromFile(0x000884, "MMEAlert.esp") == None || Game.GetFormFromFile(0x000885, "MMEAlert.esp") == None
        Return "BLACKSMITH MISSING"
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

String Function GetSexLabStatus() Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None
        Return "NOT DETECTED"
    ElseIf !milkController.SexLab.Enabled
        Return "NOT ACTIVATED"
    EndIf
    Return "ACTIVE"
EndFunction

MMEDebug Function GetDebugService() Global
    Return Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEDebug
EndFunction

String Function GetNewMilkMaidSexLabBusState() Global
    MMEDebug service = GetDebugService()
    If service == None
        Return "SERVICE MISSING"
    EndIf
    Return service.GetNewMilkMaidSexLabBusState()
EndFunction

String Function GetNewMilkMaidSexLabBusStop() Global
    MMEDebug service = GetDebugService()
    If service == None
        Return "none"
    EndIf
    Return service.GetNewMilkMaidSexLabBusStop()
EndFunction

String Function GetNewMilkMaidSexLabBusFailure() Global
    MMEDebug service = GetDebugService()
    If service == None
        Return "service missing"
    EndIf
    Return service.GetNewMilkMaidSexLabBusFailure()
EndFunction

Bool Function IsBlacksmithDialogueTraceEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableBlacksmithDialogueTrace", 0) == 1
EndFunction

String Function GetBlacksmithDialogueBusState() Global
    MMEDebug service = GetDebugService()
    If service == None
        Return "SERVICE MISSING"
    EndIf
    Return service.GetBlacksmithDialogueBusState()
EndFunction

String Function GetBlacksmithDialogueBusStop() Global
    MMEDebug service = GetDebugService()
    If service == None
        Return "none"
    EndIf
    Return service.GetBlacksmithDialogueBusStop()
EndFunction

String Function GetBlacksmithDialogueBusFailure() Global
    MMEDebug service = GetDebugService()
    If service == None
        Return "service missing"
    EndIf
    Return service.GetBlacksmithDialogueBusFailure()
EndFunction

Function ShowBlacksmithDialogueBusReport(Bool useMessageBox = False) Global
    MMEDebug service = GetDebugService()
    If service == None
        Report("Blacksmith bus FAIL: persistent service is missing", 2)
        Return
    EndIf
    service.ShowBlacksmithDialogueBusReport(useMessageBox)
EndFunction

Function RunBlacksmithDialogueBusTest() Global
    Actor candidate = Game.GetCurrentCrosshairRef() as Actor
    MMEDebug service = GetDebugService()
    If service == None
        Report("Blacksmith bus FAIL: persistent service is missing", 2)
        Return
    EndIf
    RunBlacksmithDialogueBus(candidate, False, False)
    service.ShowBlacksmithDialogueBusReport(True)
EndFunction

; Called immediately after the Blacksmith opening wrapper publishes its state.
; Visibility is intentionally deferred until Skyrim finishes constructing the
; dialogue choice list.
Function ObserveBlacksmithDialogueState(Actor candidate) Global
    If IsBlacksmithDialogueTraceEnabled()
        RunBlacksmithDialogueBus(candidate, True, False)
    EndIf
EndFunction

; Called from the controller's existing post-opening snapshot. This is the only
; phase that treats Skyrim's live visible INFO list as authoritative.
Function ObserveBlacksmithDialogueVisibility(Actor candidate) Global
    If !IsBlacksmithDialogueTraceEnabled()
        Return
    EndIf
    RunBlacksmithDialogueBus(candidate, True, True)
    ShowBlacksmithDialogueBusReport()
EndFunction

; Read-only 13-stop audit. No branch writes the Global, registers armor, removes
; armor, casts MME's toggle spell, or changes the player's equipment.
Function RunBlacksmithDialogueBus(Actor candidate, Bool openingObserved = False, Bool checkVisibility = False) Global
    MMEDebug service = GetDebugService()
    If service == None
        Return
    EndIf
    Bool writeTrace = IsBlacksmithDialogueTraceEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableDiagnosticPapyrusTrace", 0) == 1
    GlobalVariable stateGlobal = Game.GetFormFromFile(0x000881, "MMEAlert.esp") as GlobalVariable
    Form addTopic = Game.GetFormFromFile(0x000882, "MMEAlert.esp")
    Form removeTopic = Game.GetFormFromFile(0x000883, "MMEAlert.esp")
    Form addInfo = Game.GetFormFromFile(0x000884, "MMEAlert.esp")
    Form removeInfo = Game.GetFormFromFile(0x000885, "MMEAlert.esp")
    If stateGlobal == None || addTopic == None || removeTopic == None || addInfo == None || removeInfo == None
        service.RecordBlacksmithDialogueBusStop(1, "production Global/DIAL/INFO records are missing", True, False, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(1, "production records resolved", False, False, False, False, writeTrace)

    If !MMEAlertsController.IsExtensionsEnabled()
        service.RecordBlacksmithDialogueBusStop(2, "MME Extensions master toggle is off", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(2, "MME Extensions enabled", False, False, False, False, writeTrace)

    If candidate == None
        service.RecordBlacksmithDialogueBusStop(3, "no NPC under the crosshair/dialogue target unavailable", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(3, "target=" + candidate.GetName(), False, False, False, False, writeTrace)

    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    If blacksmithFaction == None
        service.RecordBlacksmithDialogueBusStop(4, "JobBlacksmithFaction form is missing", True, False, False, False, writeTrace)
        Return
    ElseIf !candidate.IsInFaction(blacksmithFaction)
        service.RecordBlacksmithDialogueBusStop(4, "target is not in JobBlacksmithFaction", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(4, "JobBlacksmithFaction PASS", False, False, False, False, writeTrace)

    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If merchantFaction == None
        service.RecordBlacksmithDialogueBusStop(5, "JobMerchantFaction form is missing", True, False, False, False, writeTrace)
        Return
    ElseIf !candidate.IsInFaction(merchantFaction)
        service.RecordBlacksmithDialogueBusStop(5, "target is not in JobMerchantFaction", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(5, "JobMerchantFaction PASS", False, False, False, False, writeTrace)

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Actor playerActor = Game.GetPlayer()
    If milkController == None || playerActor == None || milkController.MilkMaidFaction == None || milkController.MilkSlaveFaction == None
        service.RecordBlacksmithDialogueBusStop(6, "MME controller/player/faction properties unavailable", True, False, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(6, "MME controller and faction properties PASS", False, False, False, False, writeTrace)

    If !playerActor.IsInFaction(milkController.MilkMaidFaction)
        service.RecordBlacksmithDialogueBusStop(7, "player is not in MME MilkMaidFaction", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(7, "player Milk Maid PASS", False, False, False, False, writeTrace)

    If playerActor.IsInFaction(milkController.MilkSlaveFaction)
        service.RecordBlacksmithDialogueBusStop(8, "player is an MME Milk Slave", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(8, "player non-Slave PASS", False, False, False, False, writeTrace)

    Armor wornArmor = playerActor.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    If wornArmor == None
        service.RecordBlacksmithDialogueBusStop(9, "no slot-32 armor is equipped", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(9, "slot-32 armor=" + wornArmor.GetName(), False, False, False, False, writeTrace)

    String armorName = wornArmor.GetName()
    If armorName == "" || armorName == "Empty" || armorName == "empty"
        service.RecordBlacksmithDialogueBusStop(10, "armor has an unusable display name", False, True, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(10, "armor identity PASS", False, False, False, False, writeTrace)

    If !MMEArmorScript.AreArmorRegistriesSafeForManagement(milkController)
        service.RecordBlacksmithDialogueBusStop(11, "MilkingEquipment length=" + milkController.MilkingEquipment.Length + "; OG requires at least 5", True, False, False, False, writeTrace)
        Return
    EndIf
    String protectedReason = MMEArmorScript.GetMMEProtectedArmorReason(milkController, wornArmor, "blacksmith-bus", playerActor)
    If protectedReason != ""
        service.RecordBlacksmithDialogueBusStop(11, "protected armor: " + protectedReason, False, True, False, False, writeTrace)
        Return
    EndIf
    Int matches = MMEArmorScript.CountMilkingEquipmentMatchesDirect(milkController, armorName)
    Int expectedState = 0
    String expectedRoute = ""
    If matches == 1
        expectedState = 2
        expectedRoute = "REMOVE"
    ElseIf matches == 0 && MMEArmorScript.FindMilkingEquipmentEmptySlotDirect(milkController) >= 0
        expectedState = 1
        expectedRoute = "ADD"
    ElseIf matches == 0
        service.RecordBlacksmithDialogueBusStop(11, "MilkingEquipment is full", False, True, False, False, writeTrace)
        Return
    Else
        service.RecordBlacksmithDialogueBusStop(11, "registration match count is invalid: " + matches, True, False, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(11, "preflight expects " + expectedRoute, False, False, False, False, writeTrace)

    If !openingObserved
        service.RecordBlacksmithDialogueBusStop(11, "preflight expects " + expectedRoute + "; open [MME] Hey there! with live trace enabled", False, False, True, False, writeTrace)
        Return
    EndIf
    Int publishedState = stateGlobal.GetValue() as Int
    If publishedState != expectedState
        service.RecordBlacksmithDialogueBusStop(12, "opening state mismatch: expected " + expectedState + " (" + expectedRoute + ") got " + publishedState, True, False, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(12, "opening state=" + publishedState + " (" + expectedRoute + ") PASS", False, False, False, False, writeTrace)

    If !checkVisibility
        Return
    EndIf
    Form expectedTopic = addTopic
    Form expectedInfo = addInfo
    If expectedState == 2
        expectedTopic = removeTopic
        expectedInfo = removeInfo
    EndIf
    Form[] topicInfos = MMEExtensionsNative.GetTopicInfos(expectedTopic)
    If topicInfos == None || topicInfos.Find(expectedInfo) < 0 || MMEExtensionsNative.GetParentTopic(expectedInfo) != expectedTopic
        service.RecordBlacksmithDialogueBusStop(13, expectedRoute + " INFO is not attached to its runtime DIAL", True, False, False, False, writeTrace)
        Return
    EndIf
    If !MMEExtensionsNative.EvaluateTopicInfo(expectedInfo, candidate, playerActor)
        service.RecordBlacksmithDialogueBusStop(13, expectedRoute + " INFO runtime conditions failed", True, False, False, False, writeTrace)
        Return
    EndIf
    Form[] visibleInfos = MMEExtensionsNative.GetVisibleDialogueInfos()
    If visibleInfos == None
        service.RecordBlacksmithDialogueBusStop(13, "visible INFO snapshot unavailable", True, False, False, False, writeTrace)
        Return
    ElseIf visibleInfos.Find(expectedInfo) < 0
        service.RecordBlacksmithDialogueBusStop(13, expectedRoute + " conditions PASS but INFO is not visible", True, False, False, False, writeTrace)
        Return
    EndIf
    service.RecordBlacksmithDialogueBusStop(13, expectedRoute + " INFO is visible", False, False, False, True, writeTrace)
EndFunction

Function RefreshNewMilkMaidSexLabBus() Global
    MMEDebug service = GetDebugService()
    If service == None
        Report("SexLab bus FAIL: persistent service is missing", 2)
        Return
    EndIf
    service.EnsureNewMilkMaidSexLabListeners(True)
EndFunction

Function ShowNewMilkMaidSexLabBusReport() Global
    MMEDebug service = GetDebugService()
    If service == None
        Report("SexLab bus FAIL: persistent service is missing", 2)
        Return
    EndIf
    service.ShowNewMilkMaidSexLabBusReport()
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
    Bool newMaidReady = Game.GetFormFromFile(0x00087A, "MMEAlert.esp") != None && Game.GetFormFromFile(0x00087E, "MMEAlert.esp") != None && Game.GetFormFromFile(0x00087D, "MMEAlert.esp") != None && Game.GetFormFromFile(0x00087F, "MMEAlert.esp") != None && Game.GetFormFromFile(0x000880, "MMEAlert.esp") != None
    Bool blacksmithReady = Game.GetFormFromFile(0x000881, "MMEAlert.esp") != None && Game.GetFormFromFile(0x000882, "MMEAlert.esp") != None && Game.GetFormFromFile(0x000883, "MMEAlert.esp") != None && Game.GetFormFromFile(0x000884, "MMEAlert.esp") != None && Game.GetFormFromFile(0x000885, "MMEAlert.esp") != None
    Bool retiredNewMaidInfoPresent = Game.GetFormFromFile(0x00087B, "MMEAlert.esp") != None
    Bool mmeReady = Quest.GetQuest("MME_MilkQUEST") != None
    Bool ostimReady = MMEOStimBreastfeeding.IsOStimDetected()
    Bool settingReady = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableOStimBreastfeeding", 0) == 1

    Report("Install: controller=" + YesNo(controllerReady) + " MME=" + YesNo(mmeReady) + " OStim=" + YesNo(ostimReady))
    Report("Records: gate=" + YesNo(gateReady) + " OStim choices=" + YesNo(oldOStimReady) + " new maid=" + YesNo(newMaidReady))
    Report("Records: Blacksmith dialogue=" + YesNo(blacksmithReady))
    Report("Build fingerprint: OStim INFO 87E + SexLab INFO 880=" + YesNo(newMaidReady) + " retired 87B=" + YesNo(retiredNewMaidInfoPresent))
    Report("Runtime: setting=" + YesNo(settingReady) + " dialogue gate=" + GetGateStatus())
    If controllerReady && gateReady && oldOStimReady && newMaidReady && blacksmithReady && mmeReady && ostimReady && settingReady && GetGateStatus() == "ON"
        Report("PASS: installed dialogue runtime is ready")
    Else
        Report("FAIL: install/runtime audit found a blocker", 2)
    EndIf
EndFunction

; Reports each player-drink intake stage separately. This is intentionally
; read-only and event-driven: it does not consume inventory or poll the player.
Function RunMilkDrinkAudit() Global
    Quest controllerQuest = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as Quest
    If controllerQuest == None
        Report("Drink stop 1 FAIL: MMEAlertDebugQuest is missing", 2)
        Return
    EndIf
    Report("Drink stop 1 PASS: controller quest resolved")

    ReferenceAlias playerAlias = controllerQuest.GetAlias(1) as ReferenceAlias
    If playerAlias == None
        Report("Drink stop 2 FAIL: player alias ID 1 is missing", 2)
        Return
    EndIf
    Actor aliasActor = playerAlias.GetActorReference()
    If aliasActor != Game.GetPlayer()
        Report("Drink stop 3 FAIL: alias ID 1 is not filled by the player", 2)
        Return
    EndIf
    Report("Drink stop 2-3 PASS: alias ID 1 contains the player")

    MMEDrinkTracker tracker = playerAlias as MMEDrinkTracker
    If tracker == None
        Report("Drink stop 4 FAIL: MMEDrinkTracker is not attached to alias ID 1", 2)
        Return
    EndIf
    Report("Drink stop 4 PASS: MMEDrinkTracker is attached")

    Bool masterEnabled = MMEAlertsController.IsExtensionsEnabled()
    Bool debugEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableAddMilkDebug", 0) == 1
    Report("Drink stop 5: extensions=" + YesNo(masterEnabled) + " diagnostics=" + YesNo(debugEnabled))

    Form lactacid = Game.GetFormFromFile(0x0343F2, "MilkModNEW.esp")
    Form hearthfireMilk = Game.GetFormFromFile(0x003534, "HearthFires.esm")
    FormList mmeMilks = Game.GetFormFromFile(0x05C81C, "MilkModNEW.esp") as FormList
    Bool formsReady = lactacid != None && hearthfireMilk != None && mmeMilks != None
    Report("Drink stop 6: Lactacid=" + YesNo(lactacid != None) + " HearthFires milk=" + YesNo(hearthfireMilk != None) + " MME milk list=" + YesNo(mmeMilks != None))
    If !formsReady
        Report("Drink stop 6 FAIL: supported milk forms did not resolve", 2)
        Return
    EndIf

    Float lastEventTime = StorageUtil.GetFloatValue(None, "MMEExtensions.PlayerDrink.LastAliasEventTime", -1.0)
    Float lastAcceptedTime = StorageUtil.GetFloatValue(None, "MMEExtensions.PlayerDrink.LastAcceptedTime", -1.0)
    If lastEventTime < 0.0
        Report("Drink stop 7 WAITING: no player equip event observed yet")
    Else
        Report("Drink stop 7 PASS: equip event observed " + (Utility.GetCurrentRealTime() - lastEventTime) + " seconds ago; form=" + StorageUtil.GetIntValue(None, "MMEExtensions.PlayerDrink.LastAliasEventForm", 0))
    EndIf
    If lastAcceptedTime < 0.0
        Report("Drink stop 8 WAITING: no supported milk accepted yet")
    Else
        Report("Drink stop 8 PASS: milk accepted " + (Utility.GetCurrentRealTime() - lastAcceptedTime) + " seconds ago; form=" + StorageUtil.GetIntValue(None, "MMEExtensions.PlayerDrink.LastAcceptedForm", 0))
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

    ; External reads of MilkQUEST's private Actor[] registries can return None
    ; even while MME's own quest sees valid arrays. Diagnose the public state
    ; AssignSlotMaid and MaidRemove maintain instead.
    Bool playerMaid = MMEArmorScript.IsMMEMilkMaid(playerActor, milkController)
    Bool candidateMaid = MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
    Bool candidateSlave = MMEArmorScript.IsMMEMilkSlave(candidate, milkController)
    Bool candidateStorage = StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.Level")
    Bool candidateMaidFaction = milkController.MilkMaidFaction != None && candidate.IsInFaction(milkController.MilkMaidFaction)
    Bool candidateSlaveFaction = milkController.MilkSlaveFaction != None && candidate.IsInFaction(milkController.MilkSlaveFaction)
    Bool cachedSubjectMaid = milkController.MilkQC != None && milkController.MilkQC.MME_SubjectMaid
    Bool cachedSubjectSlave = milkController.MilkQC != None && milkController.MilkQC.MME_SubjectSlave
    Int cachedFreeSlots = -1
    If milkController.MilkQC != None
        cachedFreeSlots = milkController.MilkQC.MME_FreeMaidSlots
    EndIf
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

    Report("Target: " + MMENewMilkMaid.GetActorName(candidate) + " formID=" + candidate.GetFormID() + " available=" + YesNo(candidateAvailable))
    Report("Target maid truth: resolved=" + YesNo(candidateMaid) + " faction=" + YesNo(candidateMaidFaction) + " storage=" + YesNo(candidateStorage))
    Report("Target slave truth: resolved=" + YesNo(candidateSlave) + " faction=" + YesNo(candidateSlaveFaction) + " storageFlag=" + StorageUtil.GetIntValue(candidate, "MME.MilkMaid.IsSlave", 0))
    Report("Dialogue cache: subjectMaid=" + YesNo(cachedSubjectMaid) + " subjectSlave=" + YesNo(cachedSubjectSlave) + " freeSlots=" + cachedFreeSlots)
    If candidateMaid != cachedSubjectMaid || candidateSlave != cachedSubjectSlave
        Report("CACHE MISMATCH: MME opening dialogue state disagrees with faction/storage state", 2)
    Else
        Report("Cache check PASS: dialogue state agrees with faction/storage state")
    EndIf
    Report("Player: maid=" + YesNo(playerMaid) + " milk=" + playerMilk + " source valid=" + YesNo(playerSourceValid))
    Report("NPC: milk=" + candidateMilk + " source valid=" + YesNo(candidateSourceValid))
    Report("OStim choices: player drinks=" + PassFail(ostimPlayerDrinksEligible) + " NPC drinks=" + PassFail(ostimNPCDrinksEligible))
    Report("New Milk Maid capacity: delegated to native MME Lactacid effect")
    If blocker == "none"
        Report("PASS: New Milk Maid route is runtime-eligible")
    Else
        Report("FAIL: " + blocker, 2)
    EndIf
EndFunction

Function RunNewMilkMaidSexLabBusTest() Global
    If !MMENewMilkMaid.IsSexLabTraceEnabled()
        Report("Enable Debug > New Milk Maid SexLab Trace first", 2)
        Return
    EndIf
    Actor candidate = Game.GetCurrentCrosshairRef() as Actor
    If candidate == None
        Report("SexLab bus FAIL: no NPC under the crosshair", 2)
        Report("Close MCM, aim at the NPC, reopen, then run the bus test")
        Return
    EndIf
    RefreshNewMilkMaidSexLabBus()
    MMENewMilkMaid.RunSexLabBusPreflight(candidate)
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
