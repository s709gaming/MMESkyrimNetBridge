Scriptname MMEArmorScript Hidden

; Queues a debounced player armor-overflow check. Call only after a real milk
; gain so the immediate drink pipeline is never delayed. This function is
; non-latent: it only bumps a token and asks the controller quest to schedule
; its own single update.
Function SchedulePlayerArmorCheck(Actor target) Global
    If target != Game.GetPlayer()
        Return
    EndIf
    Bool diagnostic = GetDiagnostic()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller == None
        Report(diagnostic, "PLAYER armor check skipped: controller unavailable")
        Return
    EndIf
    If StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0) > 0
        Report(diagnostic, "PLAYER armor check superseded by newer drink")
    EndIf
    StorageUtil.SetIntValue(target, "MMEExtensions.ArmorCheck.Generation", StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0) + 1)
    controller.RequestPlayerArmorCheck()
    Report(diagnostic, "PLAYER armor check queued")
EndFunction

; Runs the deferred check using only the current live state.
Function CheckPlayerArmorNow(Actor target) Global
    If target != Game.GetPlayer()
        Return
    EndIf
    If StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0) <= 0
        Return
    EndIf
    StorageUtil.SetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0)
    Bool diagnostic = GetDiagnostic()
    Report(diagnostic, "PLAYER armor check running | milk " + MME_Storage.getMilkCurrent(target))

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "PLAYER armor check skipped: MME controller unavailable")
        Return
    EndIf
    If !IsValidMilkMaid(target, milkController)
        Report(diagnostic, "PLAYER armor check skipped: not a valid Milkmaid")
        Return
    EndIf
    If milkController.ArmorStrippingDisabled
        Report(diagnostic, "PLAYER armor check skipped: MME armor stripping disabled")
        Return
    EndIf

    Armor slotArmor = target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    If slotArmor == None
        Report(diagnostic, "PLAYER armor check skipped: no slot-32 armor")
        Return
    EndIf
    If IsSpecialMMEArmor(milkController, slotArmor)
        Report(diagnostic, "PLAYER armor check skipped: protected MME armor")
        Return
    EndIf
    If slotArmor == milkController.TITS4 || slotArmor == milkController.TITS6 || slotArmor == milkController.TITS8
        Report(diagnostic, "PLAYER armor check skipped: protected MME armor")
        Return
    EndIf
    If milkController.DDi != None && milkController.DDi.IsMilkingBlocked_Suit(target)
        Report(diagnostic, "PLAYER armor check skipped: protected DD/special armor")
        Return
    EndIf
    If !IsStripSafeByFramework(milkController, slotArmor)
        Report(diagnostic, "PLAYER armor check skipped: not strippable")
        Return
    EndIf

    Float milk = MME_Storage.getMilkCurrent(target)
    Float threshold = GetArmorThreshold(slotArmor)
    If threshold <= 0.0
        Report(diagnostic, "PLAYER armor check skipped: unclassified armor")
        Return
    EndIf
    If milk <= threshold
        Report(diagnostic, "PLAYER armor check skipped: milk " + milk + " not above " + threshold)
        Return
    EndIf

    ; Exactly one mutually-exclusive strip decision and one notification.
    String armorKind = "clothes"
    If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD2, "Skyrim.esm") as Keyword)
        armorKind = "heavy armor"
    ElseIf slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD3, "Skyrim.esm") as Keyword)
        armorKind = "light armor"
    EndIf
    target.UnequipItem(slotArmor)
    Debug.Notification("Your breasts are too big to fit into your " + armorKind)
    Report(diagnostic, "PLAYER " + armorKind + " stripped | milk " + milk + " > " + threshold)
EndFunction

; Classifies slot-32 armor and returns MME's raw-milk overflow threshold.
Float Function GetArmorThreshold(Armor slotArmor) Global
    If slotArmor == None
        Return 0.0
    EndIf
    If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD2, "Skyrim.esm") as Keyword)
        Return 4.0
    EndIf
    If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD3, "Skyrim.esm") as Keyword)
        Return 8.0
    EndIf
    Return 12.0
EndFunction

; Framework-neutral overflow gate: protects MME's milking/living/special armor.
Bool Function IsSpecialMMEArmor(MilkQUEST milkController, Armor slotArmor) Global
    If milkController == None || slotArmor == None
        Return True
    EndIf
    If slotArmor == milkController.MilkCuirass || slotArmor == milkController.MilkCuirassFuta
        Return True
    EndIf
    String armorName = slotArmor.GetName()
    If milkController.MilkingEquipment.Find(armorName) >= 0
        Return True
    EndIf
    If milkController.BasicLivingArmor.Find(armorName) >= 0
        Return True
    EndIf
    If milkController.ParasiteLivingArmor.Find(armorName) >= 0
        Return True
    EndIf
    If StringUtil.Find(armorName, "Milk") >= 0 || StringUtil.Find(armorName, "Cow") >= 0
        Return True
    EndIf
    If StringUtil.Find(armorName, "Spriggan Armor") >= 0 \
    || StringUtil.Find(armorName, "Spriggan Host") >= 0 \
    || StringUtil.Find(armorName, "Living Arm") >= 0 \
    || StringUtil.Find(armorName, "Hermaeus Mora") >= 0 \
    || StringUtil.Find(armorName, "HM Priestess") >= 0 \
    || StringUtil.Find(armorName, "Tentacle Armor") >= 0 \
    || StringUtil.Find(armorName, "Tentacle Parasite") >= 0 \
    || StringUtil.Find(armorName, "Dwemer milking device") >= 0 \
    || StringUtil.Find(armorName, "Cow Harness") >= 0 \
    || StringUtil.Find(armorName, "Milking Cuirass") >= 0 \
    || StringUtil.Find(armorName, "Milker") >= 0
        Return True
    EndIf
    Return False
EndFunction

; Isolates the framework-specific strippability gate so the overflow algorithm
; stays framework-neutral. Returns True when a strip is permitted.
Bool Function IsStripSafeByFramework(MilkQUEST milkController, Armor slotArmor) Global
    If milkController == None || milkController.SexLab == None
        Return True
    EndIf
    Return milkController.SexLab.IsStrippable(slotArmor)
EndFunction

Bool Function IsValidMilkMaid(Actor target, MilkQUEST milkController) Global
    Return target != None && !target.IsDead() && !target.IsDisabled() && milkController.MilkMaid.Find(target) != -1
EndFunction

Bool Function GetDiagnostic() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorOverflowDiagnostic", 0) == 1
EndFunction

Function Report(Bool showNotification, String reportText) Global
    Debug.Trace("[MMEAlert Armor Overflow] " + reportText)
    If showNotification
        Debug.Notification("Armor Overflow: " + reportText)
    EndIf
EndFunction
