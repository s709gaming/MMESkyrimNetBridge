Scriptname MMEVendorServices extends TopicInfo Hidden

; ---------------------------------------------------------------------------
; Shared vendor-service dialogue backend
; ---------------------------------------------------------------------------
; This first implementation is intentionally Blacksmith-only. The service
; writes directly to MME's live MilkQ.MilkingEquipment string array and uses a
; single transient StorageUtil form value only to prove that the slot-32 armor
; selected at offer time is still worn at commit time. It is not an armor
; registry and is overwritten whenever the service dialogue is opened.

; Root dialogue fragment. Its linked choices read the globals populated here:
; 0 unavailable, 1 normal armor/modification, 2 registered armor/removal,
; 3 armor inherently handled by MME.
Function Fragment_Prepare(ObjectReference akSpeakerRef)
    PrepareBlacksmithService(akSpeakerRef as Actor)
EndFunction

; Confirmation fragments commit only after rechecking the exact armor form.
Function Fragment_Modify(ObjectReference akSpeakerRef)
    ModifyPendingArmor(akSpeakerRef as Actor)
EndFunction

Function Fragment_Remove(ObjectReference akSpeakerRef)
    RemovePendingArmor(akSpeakerRef as Actor)
EndFunction

Function Fragment_Cancel(ObjectReference akSpeakerRef)
    ClearPendingService()
EndFunction

; Synchronizes the root INFO's Global condition with the MME Extensions master
; toggle. The controller calls this during initialization and shutdown.
Function RefreshAvailability() Global
    Bool enabled = MMEAlertsController.IsExtensionsEnabled()
    SetGlobalValue("MMEExt_BlacksmithServiceAvailable", enabled as Int)
    If !enabled
        SetGlobalValue("MMEExt_BlacksmithServiceState", 0)
        SetGlobalValue("MMEExt_BlacksmithHasMilk", 0)
        SetGlobalValue("MMEExt_BlacksmithHasFreeSlot", 0)
        Actor playerActor = Game.GetPlayer()
        If playerActor != None
            StorageUtil.UnsetFormValue(playerActor, "MMEExtensions.VendorServices.PendingArmor")
        EndIf
    EndIf
    Debug.Trace("[MME Extensions Blacksmith] service availability=" + enabled)
EndFunction

; Shutdown must fail closed even if it was invoked before the persisted master
; setting changed. This explicit path prevents a stale conditioned INFO from
; remaining visible during controller teardown.
Function DisableAvailability() Global
    SetGlobalValue("MMEExt_BlacksmithServiceAvailable", 0)
    ResetDialogueState(Game.GetPlayer())
    Debug.Trace("[MME Extensions Blacksmith] service availability=False (shutdown)")
EndFunction

; Captures the live armor state after the player selects the top-level service.
; No inventory or MME array mutation occurs during this preparation phase.
Function PrepareBlacksmithService(Actor blacksmith) Global
    Bool diagnostic = GetDiagnostic()
    Actor playerActor = Game.GetPlayer()
    ResetDialogueState(playerActor)

    ; Phase 1: validate the master toggle, blacksmith faction, and real MME
    ; Milk Maid membership. INFO conditions hide most invalid calls, but runtime
    ; checks remain authoritative because equipment and factions can change.
    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "MME Extensions enabled: FAIL")
        Return
    EndIf
    Bool blacksmithEligible = IsBlacksmith(blacksmith)
    Report(diagnostic, "NPC eligible: " + PassFail(blacksmithEligible))
    If !blacksmithEligible || playerActor == None
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "MME data available: FAIL")
        Return
    EndIf
    Bool milkmaidEligible = milkController.MilkMaid != None && milkController.MilkMaid.Find(playerActor) >= 0
    Report(diagnostic, "Milkmaid: " + PassFail(milkmaidEligible))
    If !milkmaidEligible
        Return
    EndIf

    ; Phase 2: resolve slot 32 and fail closed on malformed array state. MME's
    ; original arrays use the exact sentinel "Empty"; empty strings are not
    ; silently repaired here because MME remains the owner of those arrays.
    Armor wornArmor = GetWornBodyArmor(playerActor)
    String armorName = ""
    If wornArmor != None
        armorName = wornArmor.GetName()
    EndIf
    Report(diagnostic, "Worn armor: " + GetArmorName(wornArmor))
    If wornArmor == None || armorName == "" || armorName == "Empty"
        Report(diagnostic, "slot-32 armor usable: FAIL")
        Return
    EndIf
    If !IsMilkingEquipmentArrayValid(milkController)
        Report(diagnostic, "MilkingEquipment array valid: FAIL")
        Return
    EndIf

    ; Phase 3: classify native/special armor before consulting the removable
    ; MilkingEquipment array. This ordering prevents an accidental duplicate
    ; registration from exposing removal for Living or Parasite armor.
    Bool nativeArmor = MMEArmorScript.IsNativeOrSpecialMMEArmor(milkController, wornArmor)
    Int registeredIndex = milkController.MilkingEquipment.Find(armorName)
    Report(diagnostic, "Native MME armor: " + YesNo(nativeArmor))
    Report(diagnostic, "Registered: " + YesNo(registeredIndex >= 0))

    Int serviceState = 0
    If nativeArmor
        serviceState = 3
    ElseIf registeredIndex >= 0
        serviceState = 2
    Else
        serviceState = 1
    EndIf
    SetGlobalValue("MMEExt_BlacksmithServiceState", serviceState)
    StorageUtil.SetFormValue(playerActor, "MMEExtensions.VendorServices.PendingArmor", wornArmor)

    ; Phase 4: modification-only prerequisites are computed for linked INFO
    ; visibility. Removal is free and intentionally ignores milk/capacity.
    Int freeSlots = CountFreeSlots(milkController.MilkingEquipment)
    Int totalSlots = milkController.MilkingEquipment.Length
    Form paymentMilk = MMENPCDialog.FindFirstSupportedMilk(playerActor, milkController)
    Bool milkAvailable = paymentMilk != None
    SetGlobalValue("MMEExt_BlacksmithHasMilk", milkAvailable as Int)
    SetGlobalValue("MMEExt_BlacksmithHasFreeSlot", (freeSlots > 0) as Int)
    Report(diagnostic, "Free slots: " + freeSlots + " / " + totalSlots)
    Report(diagnostic, "Milk available: " + YesNo(milkAvailable))
    Debug.Trace("[MME Extensions Blacksmith] prepared | NPC=" + GetActorName(blacksmith) + " | armor=" + armorName + " | state=" + serviceState + " | free=" + freeSlots + "/" + totalSlots + " | payment=" + GetFormName(paymentMilk))
EndFunction

; Pays one supported milk and registers the snapshotted armor name in the first
; live "Empty" slot. Every prerequisite is repeated immediately before commit.
Bool Function ModifyPendingArmor(Actor blacksmith) Global
    Bool diagnostic = GetDiagnostic()
    Actor playerActor = Game.GetPlayer()

    ; Phase 1: repeat actor/MME validation instead of trusting dialogue state.
    If !ValidateParticipants(blacksmith, playerActor, diagnostic)
        ClearPendingService()
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || !IsMilkingEquipmentArrayValid(milkController)
        Report(diagnostic, "modify rejected: MME MilkingEquipment unavailable or malformed")
        ClearPendingService()
        Return False
    EndIf

    ; Phase 2: require the exact ARMO form captured by Prepare, not merely the
    ; same display name. This blocks armor swaps between offer and confirmation.
    Armor pendingArmor = StorageUtil.GetFormValue(playerActor, "MMEExtensions.VendorServices.PendingArmor") as Armor
    Armor wornArmor = GetWornBodyArmor(playerActor)
    Bool sameArmor = pendingArmor != None && wornArmor == pendingArmor
    Report(diagnostic, "Same armor check: " + PassFail(sameArmor))
    If !sameArmor
        Report(diagnostic, "modify rejected: worn armor changed")
        ClearPendingService()
        Return False
    EndIf
    String armorName = pendingArmor.GetName()
    If armorName == "" || armorName == "Empty" || MMEArmorScript.IsNativeOrSpecialMMEArmor(milkController, pendingArmor)
        Report(diagnostic, "modify rejected: armor is unnamed, reserved, or inherently handled by MME")
        ClearPendingService()
        Return False
    EndIf
    If milkController.MilkingEquipment.Find(armorName) >= 0
        Report(diagnostic, "modify rejected: duplicate registration")
        ClearPendingService()
        Return False
    EndIf

    ; Phase 3: resolve capacity and payment before removing anything. Selection
    ; reuses Give Milk's authoritative sources and established priority order.
    Int freeIndex = milkController.MilkingEquipment.Find("Empty")
    If freeIndex < 0 || freeIndex >= milkController.MilkingEquipment.Length
        Report(diagnostic, "modify rejected: MilkingEquipment is full")
        ClearPendingService()
        Return False
    EndIf
    Form paymentMilk = MMENPCDialog.FindFirstSupportedMilk(playerActor, milkController)
    If paymentMilk == None
        Report(diagnostic, "modify rejected: no supported milk available")
        ClearPendingService()
        Return False
    EndIf

    ; Phase 4: final same-form check is intentionally adjacent to payment. No
    ; milk is consumed if the player changed armor while navigating dialogue.
    If GetWornBodyArmor(playerActor) != pendingArmor
        Report(diagnostic, "Same armor check: FAIL immediately before payment")
        ClearPendingService()
        Return False
    EndIf
    Int milkBefore = playerActor.GetItemCount(paymentMilk)
    If milkBefore < 1
        Report(diagnostic, "modify rejected: selected milk disappeared before payment")
        ClearPendingService()
        Return False
    EndIf
    playerActor.RemoveItem(paymentMilk, 1, True)
    Int milkAfter = playerActor.GetItemCount(paymentMilk)
    If milkAfter != milkBefore - 1
        If milkAfter < milkBefore
            playerActor.AddItem(paymentMilk, milkBefore - milkAfter, True)
        EndIf
        Report(diagnostic, "modify rejected: milk payment could not be verified")
        ClearPendingService()
        Return False
    EndIf
    Report(diagnostic, "Milk consumed: 1 (" + GetFormName(paymentMilk) + ")")

    ; Phase 5: commit into the first verified Empty slot. If assignment cannot
    ; be proven, restore the sentinel and refund the consumed bottle.
    milkController.MilkingEquipment[freeIndex] = armorName
    Bool addVerified = milkController.MilkingEquipment[freeIndex] == armorName && milkController.MilkingEquipment.Find(armorName) == freeIndex
    Report(diagnostic, "Array add: " + PassFail(addVerified))
    If !addVerified
        milkController.MilkingEquipment[freeIndex] = "Empty"
        playerActor.AddItem(paymentMilk, 1, True)
        Report(diagnostic, "modify failed: array restored and milk refunded")
        ClearPendingService()
        Return False
    EndIf

    ; Phase 6: report actual capacity from the live array, then clear transient
    ; dialogue state. MME sees the new name through its original lookup path.
    Int remaining = CountFreeSlots(milkController.MilkingEquipment)
    Int total = milkController.MilkingEquipment.Length
    Report(diagnostic, "Slots remaining: " + remaining + " / " + total)
    Debug.Notification(armorName + " modified for milking. " + remaining + " of " + total + " slots remain.")
    Debug.Trace("[MME Extensions Blacksmith] modification complete | armor=" + armorName + " | slot=" + freeIndex + " | remaining=" + remaining + "/" + total)
    ClearPendingService()
    Return True
EndFunction

; Removes only a user MilkingEquipment registration. Living-armor arrays and
; MME's native/special name behavior are never written by this function.
Bool Function RemovePendingArmor(Actor blacksmith) Global
    Bool diagnostic = GetDiagnostic()
    Actor playerActor = Game.GetPlayer()
    If !ValidateParticipants(blacksmith, playerActor, diagnostic)
        ClearPendingService()
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || !IsMilkingEquipmentArrayValid(milkController)
        Report(diagnostic, "removal rejected: MME MilkingEquipment unavailable or malformed")
        ClearPendingService()
        Return False
    EndIf

    ; Recheck the exact armor form and native classification before touching
    ; the array. Native, BasicLivingArmor, and ParasiteLivingArmor always win.
    Armor pendingArmor = StorageUtil.GetFormValue(playerActor, "MMEExtensions.VendorServices.PendingArmor") as Armor
    Armor wornArmor = GetWornBodyArmor(playerActor)
    Bool sameArmor = pendingArmor != None && wornArmor == pendingArmor
    Report(diagnostic, "Removal same armor check: " + PassFail(sameArmor))
    If !sameArmor
        Report(diagnostic, "removal rejected: worn armor changed")
        ClearPendingService()
        Return False
    EndIf
    String armorName = pendingArmor.GetName()
    If armorName == "" || armorName == "Empty" || MMEArmorScript.IsNativeOrSpecialMMEArmor(milkController, pendingArmor)
        Report(diagnostic, "removal rejected: native/special MME armor is protected")
        ClearPendingService()
        Return False
    EndIf
    Int registeredIndex = milkController.MilkingEquipment.Find(armorName)
    If registeredIndex < 0 || registeredIndex >= milkController.MilkingEquipment.Length
        Report(diagnostic, "removal rejected: armor is not registered")
        ClearPendingService()
        Return False
    EndIf

    ; Replace the one matching entry with MME's exact sentinel and verify that
    ; no duplicate remains. A duplicate indicates malformed state and is rolled
    ; back rather than partially removing a registration.
    milkController.MilkingEquipment[registeredIndex] = "Empty"
    Bool removeVerified = milkController.MilkingEquipment[registeredIndex] == "Empty" && milkController.MilkingEquipment.Find(armorName) == -1
    Report(diagnostic, "Array removal: " + PassFail(removeVerified))
    If !removeVerified
        milkController.MilkingEquipment[registeredIndex] = armorName
        Report(diagnostic, "removal failed: original entry restored")
        ClearPendingService()
        Return False
    EndIf

    Int remaining = CountFreeSlots(milkController.MilkingEquipment)
    Int total = milkController.MilkingEquipment.Length
    Report(diagnostic, "Slots remaining: " + remaining + " / " + total)
    Debug.Notification(armorName + " removed from Milking Equipment. " + remaining + " of " + total + " slots remain.")
    Debug.Trace("[MME Extensions Blacksmith] removal complete | armor=" + armorName + " | slot=" + registeredIndex + " | remaining=" + remaining + "/" + total)
    ClearPendingService()
    Return True
EndFunction

Bool Function ValidateParticipants(Actor blacksmith, Actor playerActor, Bool diagnostic) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Report(diagnostic, "service rejected: MME Extensions disabled")
        Return False
    EndIf
    Bool blacksmithEligible = IsBlacksmith(blacksmith)
    Report(diagnostic, "NPC eligible: " + PassFail(blacksmithEligible))
    If !blacksmithEligible || playerActor == None
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Bool milkmaidEligible = milkController != None && milkController.MilkMaid != None && milkController.MilkMaid.Find(playerActor) >= 0
    Report(diagnostic, "Milkmaid: " + PassFail(milkmaidEligible))
    Return milkmaidEligible
EndFunction

Bool Function IsBlacksmith(Actor candidate) Global
    Faction jobBlacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Return candidate != None && !candidate.IsDead() && !candidate.IsDisabled() && jobBlacksmithFaction != None && candidate.IsInFaction(jobBlacksmithFaction)
EndFunction

Armor Function GetWornBodyArmor(Actor target) Global
    If target == None
        Return None
    EndIf
    Return target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
EndFunction

Bool Function IsMilkingEquipmentArrayValid(MilkQUEST milkController) Global
    If milkController == None || milkController.MilkingEquipment == None || milkController.MilkingEquipment.Length <= 0
        Return False
    EndIf
    Int index = 0
    While index < milkController.MilkingEquipment.Length
        If milkController.MilkingEquipment[index] == ""
            Return False
        EndIf
        index += 1
    EndWhile
    Return True
EndFunction

Int Function CountFreeSlots(String[] equipment) Global
    If equipment == None
        Return 0
    EndIf
    Int freeSlots = 0
    Int index = 0
    While index < equipment.Length
        If equipment[index] == "Empty"
            freeSlots += 1
        EndIf
        index += 1
    EndWhile
    Return freeSlots
EndFunction

Function ResetDialogueState(Actor playerActor) Global
    SetGlobalValue("MMEExt_BlacksmithServiceState", 0)
    SetGlobalValue("MMEExt_BlacksmithHasMilk", 0)
    SetGlobalValue("MMEExt_BlacksmithHasFreeSlot", 0)
    If playerActor != None
        StorageUtil.UnsetFormValue(playerActor, "MMEExtensions.VendorServices.PendingArmor")
    EndIf
EndFunction

Function ClearPendingService() Global
    ResetDialogueState(Game.GetPlayer())
EndFunction

Function SetGlobalValue(String editorID, Int value) Global
    GlobalVariable targetGlobal = MMEExtensionsNative.GetFormByEditorID(editorID) as GlobalVariable
    If targetGlobal != None
        targetGlobal.SetValue(value as Float)
    Else
        Debug.Trace("[MME Extensions Blacksmith] missing dialogue global " + editorID)
    EndIf
EndFunction

Bool Function GetDiagnostic() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableBlacksmithDebug", 0) == 1
EndFunction

String Function GetArmorName(Armor target) Global
    If target == None
        Return "<none>"
    EndIf
    String result = target.GetName()
    If result == ""
        Return "<unnamed armor>"
    EndIf
    Return result
EndFunction

String Function GetFormName(Form target) Global
    If target == None
        Return "<none>"
    EndIf
    String result = target.GetName()
    If result == ""
        Return "<unnamed form>"
    EndIf
    Return result
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<no actor>"
    EndIf
    String result = target.GetDisplayName()
    If result == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            result = baseInfo.GetName()
        EndIf
    EndIf
    If result == ""
        result = "Unknown actor"
    EndIf
    Return result
EndFunction

String Function PassFail(Bool value) Global
    If value
        Return "PASS"
    EndIf
    Return "FAIL"
EndFunction

String Function YesNo(Bool value) Global
    If value
        Return "YES"
    EndIf
    Return "NO"
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MME Extensions Blacksmith] " + reportText)
    If showNotification
        Debug.Notification("[Blacksmith] " + reportText)
    EndIf
EndFunction
