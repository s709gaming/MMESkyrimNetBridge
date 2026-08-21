Scriptname MMEArmorScript Hidden

; ---------------------------------------------------------------------------
; Player post-drink Armor Stripping Check
; ---------------------------------------------------------------------------
; The first half of this file mirrors only MME's capacity-related slot-32 strip
; decision after an Extensions-managed drink. It does not run MilkCycle because
; MilkCycle also changes production, progression, effects, and arousal. The
; second half is an independent per-equip reaction/classification pipeline.

; Records the post-drink value before MME's storage API can clamp it. Rapid
; drinks share one debounce window, so retain the highest attempt until the
; delayed pass consumes it. The overflow bit remains separate because it also
; controls MME's leak reconciliation.
Function MarkPlayerDrinkAttempt(Actor target, Float attemptedMilk, Bool attemptedOverflow) Global
    If target == Game.GetPlayer()
        Float pendingAttempt = StorageUtil.GetFloatValue(target, "MMEExtensions.ArmorCheck.AttemptedMilk", attemptedMilk)
        If !StorageUtil.HasFloatValue(target, "MMEExtensions.ArmorCheck.AttemptedMilk") || attemptedMilk > pendingAttempt
            StorageUtil.SetFloatValue(target, "MMEExtensions.ArmorCheck.AttemptedMilk", attemptedMilk)
        EndIf
        If attemptedOverflow
            StorageUtil.SetIntValue(target, "MMEExtensions.PostDrinkOverflow.Pending", 1)
        EndIf
        Report(False, "drink attempt retained | attemptedMilk=" + attemptedMilk + " | overflowAttempt=" + attemptedOverflow)
    EndIf
EndFunction

Bool Function HasPendingPlayerOverflow(Actor target) Global
    Return target == Game.GetPlayer() && StorageUtil.GetIntValue(target, "MMEExtensions.PostDrinkOverflow.Pending", 0) == 1
EndFunction

Bool Function HasPendingPlayerDrinkAttempt(Actor target) Global
    Return target == Game.GetPlayer() && StorageUtil.HasFloatValue(target, "MMEExtensions.ArmorCheck.AttemptedMilk")
EndFunction

Function ClearPendingPlayerDrinkAttempt(Actor target) Global
    If target == Game.GetPlayer()
        StorageUtil.UnsetFloatValue(target, "MMEExtensions.ArmorCheck.AttemptedMilk")
        StorageUtil.UnsetIntValue(target, "MMEExtensions.PostDrinkOverflow.Pending")
    EndIf
EndFunction

; Cancels both halves of the deferred transaction. Controller shutdown uses
; this so a disabled/re-enabled extension cannot consume an old drink attempt.
Function CancelPlayerArmorCheck(Actor target) Global
    If target == Game.GetPlayer()
        StorageUtil.UnsetIntValue(target, "MMEExtensions.ArmorCheck.Generation")
        ClearPendingPlayerDrinkAttempt(target)
    EndIf
EndFunction

; Queues the debounced player post-drink pass after a real milk gain or an
; attempted overflow. This function is non-latent: it only bumps a token and
; asks the controller quest to schedule its own single update.
Function SchedulePlayerArmorCheck(Actor target) Global
    ; Phase 1: only player drinks own this delayed strip path. NPC drinks use
    ; MME's normal actor processing and must not share the player's debounce key.
    If target != Game.GetPlayer()
        Return
    EndIf
    Bool diagnostic = GetDiagnostic()
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller == None
        Report(diagnostic, "PLAYER armor check skipped: controller unavailable")
        ClearPendingPlayerDrinkAttempt(target)
        Return
    EndIf
    ; Phase 2: bump a persistent generation before arming the controller timer.
    ; Multiple drinks collapse to the latest deadline; the token proves there is
    ; still real work when a stale/duplicate OnUpdate callback eventually fires.
    If StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0) > 0
        Report(diagnostic, "PLAYER armor check superseded by newer drink")
    EndIf
    StorageUtil.SetIntValue(target, "MMEExtensions.ArmorCheck.Generation", StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0) + 1)
    controller.RequestPlayerArmorCheck()
    Report(diagnostic, "queued | generation=" + StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0))
EndFunction

; Runs the deferred check using only the current live state.
Function CheckPlayerArmorNow(Actor target) Global
    ; Phase 1: consume exactly one queued request and its attempted-overflow bit.
    ; Clear both before further work so every early exit remains one-shot.
    If target != Game.GetPlayer()
        Return
    EndIf
    Bool diagnostic = GetDiagnostic()
    If StorageUtil.GetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0) <= 0
        Report(diagnostic, "timer fired but request token was missing")
        ClearPendingPlayerDrinkAttempt(target)
        Return
    EndIf
    StorageUtil.SetIntValue(target, "MMEExtensions.ArmorCheck.Generation", 0)
    Bool attemptedOverflow = HasPendingPlayerOverflow(target)
    Float attemptedMilk = StorageUtil.GetFloatValue(target, "MMEExtensions.ArmorCheck.AttemptedMilk", MME_Storage.getMilkCurrent(target))
    ClearPendingPlayerDrinkAttempt(target)
    Report(False, "running | actor=PLAYER | storedMilk=" + MME_Storage.getMilkCurrent(target) + " | attemptedMilk=" + attemptedMilk + " | overflowAttempt=" + attemptedOverflow)

    ; Phase 2: resolve live MME state and verify Player membership. MilkQUEST and
    ; its MilkMaid array are authoritative; a StorageUtil milk value alone does
    ; not make an actor eligible for MME armor behavior.
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Report(diagnostic, "decision=BLOCKED | MME controller unavailable")
        Return
    EndIf
    If !IsValidMilkMaid(target, milkController)
        Report(diagnostic, "decision=BLOCKED | actor is not a valid Milk Maid")
        Return
    EndIf

    ; Reproduce only MilkCycle's over-capacity branch before checking armor.
    ; Do not run MilkCycle itself: it also generates milk and changes lactacid,
    ; pain, progression, arousal, effects, events, and messages.
    ReconcileMMEOverflow(target, milkController, attemptedOverflow, diagnostic)

    ; Phase 3: apply MME/global compatibility gates before inspecting thresholds.
    ; Protected MME, DD, TITS, SexLab-no-strip, Living, Parasite, and milking
    ; equipment must remain equipped even at extreme milk values.
    If milkController.ArmorStrippingDisabled
        Report(diagnostic, "decision=BLOCKED | MME armor stripping disabled")
        Return
    EndIf

    Int bodyMask = Armor.GetMaskForSlot(32)
    Armor slotArmor = target.GetWornForm(bodyMask) as Armor
    If slotArmor == None
        Report(diagnostic, "slot=32 | armor=<none> | decision=BLOCKED")
        Return
    EndIf
    Report(diagnostic, "slot=32 | armor=" + GetArmorName(slotArmor))
    String protectionReason = GetMMEArmorProtectionReason(milkController, slotArmor)
    If protectionReason != ""
        ReportDecision(diagnostic, "decision=BLOCKED | protection=" + protectionReason)
        Return
    EndIf
    If milkController.DDi != None && milkController.DDi.IsMilkingBlocked_Suit(target)
        ReportDecision(diagnostic, "decision=BLOCKED | protection=DD/special armor")
        Return
    EndIf
    If !IsStripSafeByFramework(milkController, slotArmor)
        ReportDecision(diagnostic, "decision=BLOCKED | protection=SexLab no-strip")
        Return
    EndIf

    ; Phase 4: classify the ordinary body armor with MME's original thresholds.
    ; The strict greater-than comparison is intentional and preserves the
    ; existing heavy=4, light=8, clothing=12 behavior exactly.
    Float storedMilk = MME_Storage.getMilkCurrent(target)
    Float effectiveMilk = storedMilk
    If attemptedMilk > effectiveMilk
        effectiveMilk = attemptedMilk
    EndIf
    Float threshold = GetArmorThreshold(slotArmor)
    String armorKind = "clothes"
    If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD2, "Skyrim.esm") as Keyword)
        armorKind = "heavy armor"
    ElseIf slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD3, "Skyrim.esm") as Keyword)
        armorKind = "light armor"
    EndIf
    If threshold <= 0.0
        Report(diagnostic, "decision=BLOCKED | unclassified armor")
        Return
    EndIf
    If effectiveMilk <= threshold
        ReportDecision(diagnostic, "type=" + armorKind + " | storedMilk=" + storedMilk + " | attemptedMilk=" + attemptedMilk + " | effectiveMilk=" + effectiveMilk + " | threshold=" + threshold + " | decision=BLOCKED")
        Return
    EndIf

    ; Phase 5: request the unequip, then verify Skyrim actually changed slot 32.
    ; A successful Papyrus call is not proof: quests or equipment systems may
    ; immediately retain/re-equip an item, which diagnostics must report honestly.
    ; Exactly one mutually-exclusive strip decision and one notification.
    ReportDecision(diagnostic, "type=" + armorKind + " | storedMilk=" + storedMilk + " | attemptedMilk=" + attemptedMilk + " | effectiveMilk=" + effectiveMilk + " | threshold=" + threshold + " | decision=ALLOWED")
    target.UnequipItem(slotArmor)
    If target.GetWornForm(bodyMask) == slotArmor
        Report(diagnostic, "result=BLOCKED | engine retained " + armorKind)
        Return
    EndIf
    Debug.Notification("Your breasts are too big to fit into your " + armorKind)
    Report(diagnostic, "result=STRIPPED | " + armorKind + " | effectiveMilk=" + effectiveMilk + " > " + threshold)
EndFunction

; Applies MME MilkCycle's overflow math and leak calls to the current player
; state after a direct drink. An attempted-overflow marker reconstructs the
; branch when MME's enforcing storage call already clamped milk to the maximum.
Function ReconcileMMEOverflow(Actor target, MilkQUEST milkController, Bool attemptedOverflow, Bool diagnostic) Global
    ; Phase 1: reconstruct only the overflow branch that direct storage writes
    ; bypass. When BreastScaleLimit clamps the write to exactly maximum, the
    ; attemptedOverflow marker distinguishes a real overflow from normal fullness.
    Float milk = MME_Storage.getMilkCurrent(target)
    Float maximum = MME_Storage.getMilkMaximum(target)
    If maximum <= 0.0 || milk < maximum || (milk == maximum && !attemptedOverflow)
        Report(diagnostic, "PLAYER MME overflow skipped: milk " + milk + " / " + maximum)
        Return
    EndIf
    If milkController.PiercingCheck(target) == 2
        Report(diagnostic, "PLAYER MME overflow skipped: nipple plug blocks leaking")
        Return
    EndIf

    ; Phase 2: preserve MME's fixed/dynamic maid-level arithmetic and container
    ; routing. This math is intentionally not replaced with a simpler clamp.
    Float reconciledMilk = milk
    Float overflowMilk = 0.0
    If milk > maximum
        If milkController.BreastScaleLimit
            reconciledMilk = maximum
        Else
            Int maidLevel = 0
            ; MilkCycle leaves MaidLevel at its default zero in fixed mode;
            ; its dynamic-production path refreshes the real level.
            If !milkController.FixedMilkGen
                maidLevel = MME_Storage.getMaidLevel(target)
            EndIf
            overflowMilk = milk - maximum - ((milk / maximum) - 1.0) * maidLevel
            reconciledMilk = milk - overflowMilk
            Armor wornArmor = target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
            If IsMMEOverflowContainerArmor(milkController, wornArmor)
                StorageUtil.AdjustFloatValue(target, "MME.MilkMaid.MilkingContainerMilksSUM", overflowMilk)
            EndIf
        EndIf
    EndIf

    ; Phase 3: reproduce MME's visible leak/size side effects, then commit the
    ; reconciled amount through MME_Storage so MME remains state owner.
    If target.IsNearPlayer()
        milkController.AddMilkFx(target, 1)
        milkController.AddLeak(target)
    EndIf
    MME_Storage.setMilkCurrent(target, reconciledMilk, milkController.BreastScaleLimit)
    milkController.CurrentSize(target)
    Report(diagnostic, "PLAYER MME overflow reconciled | milk " + milk + " -> " + MME_Storage.getMilkCurrent(target) + " | leaked " + overflowMilk)
EndFunction

; Matches the milking-container classification used by MilkCycle's overflow
; branch, without broadening it to the armor protection rules below.
Bool Function IsMMEOverflowContainerArmor(MilkQUEST milkController, Armor wornArmor) Global
    If milkController == None || wornArmor == None
        Return False
    EndIf
    If wornArmor == milkController.MilkCuirass || wornArmor == milkController.MilkCuirassFuta
        Return True
    EndIf
    String armorName = wornArmor.GetName()
    Return milkController.MilkingEquipment.Find(armorName) != -1 || StringUtil.Find(armorName, "Milk") >= 0 || StringUtil.Find(armorName, "Cow") >= 0
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
    ; User-added MilkingEquipment entries are protected just like MME's native
    ; armor. Vendor services need to distinguish these removable entries from
    ; inherent MME recognition, so the native portion lives in the helper below.
    Return GetMMEArmorProtectionReason(milkController, slotArmor) != ""
EndFunction

; Returns a stable diagnostic reason for the first applicable MME protection.
; MME's arrays intentionally use display-name identity, including names added
; by the Blacksmith service. Empty names and MME's "Empty" sentinel are never
; armor identities and must not match malformed or unused array entries.
String Function GetMMEArmorProtectionReason(MilkQUEST milkController, Armor slotArmor) Global
    If milkController == None || slotArmor == None
        Return "invalid MME/armor state"
    EndIf
    String nativeReason = GetNativeMMEArmorProtectionReason(milkController, slotArmor)
    If nativeReason != ""
        Return nativeReason
    EndIf
    String armorName = slotArmor.GetName()
    If armorName == "" || armorName == "Empty" || milkController.MilkingEquipment == None
        Return ""
    EndIf
    Int registeredIndex = milkController.MilkingEquipment.Find(armorName)
    If registeredIndex >= 0
        Return "MilkingEquipment | index=" + registeredIndex
    EndIf
    Return ""
EndFunction

; Returns only armor MME already recognizes without a user MilkingEquipment
; registration. Blacksmith removal must never erase BasicLivingArmor or
; ParasiteLivingArmor, and adding any of these names would waste array capacity.
Bool Function IsNativeOrSpecialMMEArmor(MilkQUEST milkController, Armor slotArmor) Global
    ; Explicit quest properties and MME-configured living-armor arrays come
    ; first. Name fragments reproduce the checks in MME's MilkPlayerLoadGame
    ; and overflow paths, including long-established third-party integrations.
    Return GetNativeMMEArmorProtectionReason(milkController, slotArmor) != ""
EndFunction

String Function GetNativeMMEArmorProtectionReason(MilkQUEST milkController, Armor slotArmor) Global
    If milkController == None || slotArmor == None
        Return "invalid MME/armor state"
    EndIf
    If slotArmor == milkController.MilkCuirass
        Return "MilkCuirass"
    ElseIf slotArmor == milkController.MilkCuirassFuta
        Return "MilkCuirassFuta"
    ElseIf slotArmor == milkController.TITS4 || slotArmor == milkController.TITS6 || slotArmor == milkController.TITS8
        Return "MME breast armor"
    EndIf
    String armorName = slotArmor.GetName()
    If armorName == "" || armorName == "Empty"
        Return ""
    EndIf
    If milkController.BasicLivingArmor != None
        Int livingIndex = milkController.BasicLivingArmor.Find(armorName)
        If livingIndex >= 0
            Return "BasicLivingArmor | index=" + livingIndex
        EndIf
    EndIf
    If milkController.ParasiteLivingArmor != None
        Int parasiteIndex = milkController.ParasiteLivingArmor.Find(armorName)
        If parasiteIndex >= 0
            Return "ParasiteLivingArmor | index=" + parasiteIndex
        EndIf
    EndIf
    If StringUtil.Find(armorName, "Milk") >= 0
        Return "MME name rule=Milk"
    ElseIf StringUtil.Find(armorName, "Cow") >= 0
        Return "MME name rule=Cow"
    EndIf
    If StringUtil.Find(armorName, "Spriggan") >= 0 \
    || StringUtil.Find(armorName, "Living Arm") >= 0 \
    || StringUtil.Find(armorName, "Hermaeus Mora") >= 0 \
    || StringUtil.Find(armorName, "HM Priestess") >= 0 \
    || StringUtil.Find(armorName, "Tentacle Armor") >= 0 \
    || StringUtil.Find(armorName, "Tentacle Parasite") >= 0 \
    || StringUtil.Find(armorName, "Dwemer milking device") >= 0 \
    || StringUtil.Find(armorName, "Cow Harness") >= 0 \
    || StringUtil.Find(armorName, "Milking Cuirass") >= 0 \
    || StringUtil.Find(armorName, "Milker") >= 0
        Return "MME special name rule"
    EndIf
    Return ""
EndFunction

; Isolates the framework-specific strippability gate so the overflow algorithm
; stays framework-neutral. Returns True when a strip is permitted.
Bool Function IsStripSafeByFramework(MilkQUEST milkController, Armor slotArmor) Global
    ; SexLab is optional. When present, its no-strip policy is authoritative;
    ; when absent, lack of SexLab must not disable ordinary MME armor stripping.
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
    Debug.Trace("[MMEAlert Armor Stripping Check] " + reportText)
EndFunction

; Keep the full trace in Papyrus, but show only the useful threshold decision
; on the HUD when the diagnostic is enabled.
Function ReportDecision(Bool showNotification, String reportText) Global
    Report(False, reportText)
    If showNotification
        Debug.Notification("Armor Stripping Check: " + reportText)
    EndIf
EndFunction

; MME's own configured armor-name arrays are the source of truth.
; 0 unsupported, 1 Milking Armor, 2 AM Living Armor, 3 AM Living Parasite.
Int Function ClassifyArmor(MilkQUEST milkController, Armor equippedArmor) Global
    ; Direct form properties identify MME's canonical cuirasses even if renamed.
    ; Array matching intentionally uses the live display name because that is how
    ; MME exposes configurable third-party Milking/Living/Parasite equipment.
    If milkController == None || equippedArmor == None
        Return 0
    EndIf
    If equippedArmor == milkController.MilkCuirass || equippedArmor == milkController.MilkCuirassFuta
        Return 1
    EndIf
    String armorName = equippedArmor.GetName()
    If armorName != "" && armorName != "Empty" && milkController.MilkingEquipment.Find(armorName) >= 0
        Return 1
    EndIf
    If armorName != "" && armorName != "Empty" && milkController.BasicLivingArmor.Find(armorName) >= 0
        Return 2
    EndIf
    If armorName != "" && armorName != "Empty" && milkController.ParasiteLivingArmor.Find(armorName) >= 0
        Return 3
    EndIf
    Return 0
EndFunction

String Function GetArmorTypeLabel(Int armorClass) Global
    If armorClass == 1
        Return "Milking Armor"
    ElseIf armorClass == 2
        Return "Living Armor"
    ElseIf armorClass == 3
        Return "Living Parasite"
    EndIf
    Return "Unsupported"
EndFunction

; Technical match detail used by Skyrim.Net armor diagnostics.
String Function GetArmorClassificationSource(MilkQUEST milkController, Armor equippedArmor) Global
    If milkController == None || equippedArmor == None
        Return "none"
    EndIf
    If equippedArmor == milkController.MilkCuirass
        Return "MilkCuirass"
    ElseIf equippedArmor == milkController.MilkCuirassFuta
        Return "MilkCuirassFuta"
    EndIf
    String armorName = equippedArmor.GetName()
    If armorName == "" || armorName == "Empty"
        Return "none"
    EndIf
    If milkController.MilkingEquipment.Find(armorName) >= 0
        Return "MilkingEquipment"
    ElseIf milkController.BasicLivingArmor.Find(armorName) >= 0
        Return "BasicLivingArmor"
    ElseIf milkController.ParasiteLivingArmor.Find(armorName) >= 0
        Return "ParasiteLivingArmor"
    EndIf
    Return "none"
EndFunction

; One per-equip reaction path for every supported MME armor family. Armor type
; only selects settings and Standing/Kneeling; safety and playback stay shared.
Function HandleArmorEquipped(Actor wearer, Armor equippedArmor) Global
    ; Phase 1: classify the exact native equip-event ARMO and reject unsupported
    ; items before resolving settings, sounds, animations, or Skyrim.Net work.
    Bool diagnostic = GetArmorDiagnostic()
    String role = "NPC"
    If wearer == Game.GetPlayer()
        role = "PLAYER"
    EndIf
    ReportArmor(diagnostic, "detected | actor=" + GetActorName(wearer) + " | role=" + role + " | armor=" + GetArmorName(equippedArmor))

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Int armorClass = ClassifyArmor(milkController, equippedArmor)
    String armorType = GetArmorTypeLabel(armorClass)
    ReportArmor(diagnostic, "identified=" + armorType)
    If armorClass == 0
        NotifyArmorDebug(diagnostic, role + " | Unsupported | " + GetArmorName(equippedArmor))
        Return
    EndIf
    ; Phase 2: require real live MilkQUEST membership for both Player and NPC.
    ; Classification says what an item is; it does not establish actor eligibility.
    If milkController == None || wearer == None || milkController.MilkMaid.Find(wearer) == -1
        ReportArmor(diagnostic, "reaction does not apply: actor is not an MME Milk Maid | " + role + " | " + armorType)
        NotifyArmorDebug(diagnostic, role + " " + armorType + " | reaction=NO (not Milk Maid)")
        Return
    EndIf
    ReportArmor(diagnostic, "reaction applies | " + role + " | " + armorType)

    ; Phase 3: resolve independent role/type settings and play the equip moan.
    ; Milking Armor uses MILD; both Living families use HIGH because their
    ; invasive equip reaction is intentionally stronger.
    String settingPrefix = GetArmorSettingPrefix(armorClass, wearer == Game.GetPlayer())
    Int moanResult = PlayArmorEquipMoan(wearer, settingPrefix + "EquipMoan", role, armorType, armorClass, diagnostic)
    String moanState = "DISABLED"
    If moanResult > 0
        moanState = "PLAYED"
    ElseIf moanResult < 0
        moanState = "FAILED"
    EndIf

    MMEAlertsSkyrimNet.NarrateArmorEquip(wearer, equippedArmor)

    ; Phase 4: map armor family to the shared reaction executor. Milking Armor
    ; reuses Standing (drink/50% capacity); Living and Parasite reuse Kneeling.
    ; Do not fork per-armor animation ownership or first-equip state here.
    String animationKind = "Standing"
    If armorClass == 2 || armorClass == 3
        animationKind = "Kneeling"
    EndIf
    String animationKey = settingPrefix + "EquipAnimation"
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", animationKey, GetDefaultArmorAnimation(wearer)) != 1
        ReportArmor(diagnostic, "animation disabled | " + role + " | " + armorType + " | requested=" + animationKind)
        NotifyArmorDebug(diagnostic, role + " " + armorType + " | moan=" + moanState + " | animation=OFF | " + animationKind)
        Return
    EndIf

    ; Phase 5: delegate safety, ownership, playback, and restoration to the one
    ; shared animation pipeline. This handler owns only the three-second hold.
    String owner = "ArmorReaction." + role
    String requestLabel = "Armor " + role + " " + armorType
    ReportArmor(diagnostic, "animation requested=" + animationKind + " | " + role + " | " + armorType)
    Bool animationStarted = False
    If animationKind == "Standing"
        animationStarted = MMEReactionAnimation.StartStanding(wearer, owner, requestLabel, diagnostic)
    Else
        animationStarted = MMEReactionAnimation.StartKneeling(wearer, owner, requestLabel, diagnostic)
    EndIf
    If !animationStarted
        ReportArmor(diagnostic, "animation rejected by shared pipeline | " + role + " | " + armorType + " | requested=" + animationKind)
        Return
    EndIf
    ReportArmor(diagnostic, "animation started | " + role + " | " + armorType + " | requested=" + animationKind)
    MMEReactionAnimation.Finish(wearer, animationStarted, owner, 3.0, requestLabel, diagnostic)
    NotifyArmorDebug(diagnostic, role + " " + armorType + " | moan=" + moanState + " | animation=STARTED | " + animationKind)
EndFunction

String Function GetArmorSettingPrefix(Int armorClass, Bool isPlayer) Global
    String rolePrefix = "NPC"
    If isPlayer
        rolePrefix = "Player"
    EndIf
    If armorClass == 2
        Return "enable" + rolePrefix + "LivingArmor"
    ElseIf armorClass == 3
        Return "enable" + rolePrefix + "LivingParasite"
    EndIf
    Return "enable" + rolePrefix + "MilkingArmor"
EndFunction

Int Function GetDefaultArmorAnimation(Actor wearer) Global
    If wearer == Game.GetPlayer()
        Return 0
    EndIf
    Return 1
EndFunction

; Returns 1 when the moan played, 0 when disabled, and -1 on failure.
Int Function PlayArmorEquipMoan(Actor wearer, String moanKey, String role, String armorType, Int armorClass, Bool diagnostic) Global
    ; Select the sound pool from classification before applying toggles so debug
    ; output remains useful even when playback is disabled.
    Int localSoundForm = 0x000854
    String soundPool = "MILD"
    If armorClass == 2 || armorClass == 3
        localSoundForm = 0x000856
        soundPool = "HIGH"
    EndIf
    ReportArmor(diagnostic, "equip moan pool=" + soundPool + " | " + role + " | " + armorType)
    ; The global sound switch and per-role/per-family switch are both required.
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableReactionSounds", 1) != 1 || JsonUtil.GetIntValue("/MMEAlerts/Settings", moanKey, 1) != 1
        ReportArmor(diagnostic, "equip moan disabled | pool=" + soundPool + " | " + role + " | " + armorType)
        Return 0
    EndIf
    If wearer == None || wearer.IsDead() || wearer.IsDisabled() || !wearer.Is3DLoaded()
        ReportArmor(diagnostic, "equip moan failed: actor unavailable | pool=" + soundPool + " | " + role + " | " + armorType)
        Return -1
    EndIf
    Sound reaction = Game.GetFormFromFile(localSoundForm, "MMEAlert.esp") as Sound
    If reaction == None
        ReportArmor(diagnostic, "equip moan failed: " + soundPool + " sound form unresolved | " + role + " | " + armorType)
        Return -1
    EndIf
    ; Sound.Play returns an instance handle, which is required for the shared
    ; volume setting. A non-positive handle is a real playback failure.
    Int instance = reaction.Play(wearer)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue("/MMEAlerts/Settings", "reactionSoundVolume", 100.0) / 100.0)
        ReportArmor(diagnostic, "equip moan played | pool=" + soundPool + " | " + role + " | " + armorType + " | instance=" + instance)
        Return 1
    EndIf
    ReportArmor(diagnostic, "equip moan failed | pool=" + soundPool + " | " + role + " | " + armorType + " | result=" + instance)
    Return -1
EndFunction

; Upgrade recovery for saves made while the retired ZaZ/player-lock armor
; intro was active. New armor reactions never lock player movement.
Function RestorePlayerMovementIfNeeded(Actor wearer, Bool diagnostic = False) Global
    ; Upgrade-only cleanup for saves made by the retired armor intro. Current
    ; reactions never SetDontMove; retaining this recovery prevents a legacy
    ; interrupted animation from permanently immobilizing the Player.
    If wearer != Game.GetPlayer()
        Return
    EndIf
    If StorageUtil.GetIntValue(wearer, "MMEExtensions.MilkingArmor.PlayerMovementLocked", 0) == 1
        wearer.SetDontMove(False)
        StorageUtil.UnsetIntValue(wearer, "MMEExtensions.MilkingArmor.PlayerMovementLocked")
        ReportArmor(diagnostic, "PLAYER movement restored after legacy intro")
    EndIf
    If MMEAnimationSafety.GetOwner(wearer) == "MilkingArmorIntro"
        MMEAnimationSafety.Release(wearer, "MilkingArmorIntro")
        ReportArmor(diagnostic, "PLAYER legacy armor animation ownership released")
    EndIf
EndFunction

String Function GetActorName(Actor wearer) Global
    If wearer == None
        Return "<missing actor>"
    EndIf
    String actorName = wearer.GetDisplayName()
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

String Function GetArmorName(Armor equippedArmor) Global
    If equippedArmor == None
        Return "<missing armor>"
    EndIf
    String armorName = equippedArmor.GetName()
    If armorName == ""
        armorName = "<unnamed armor>"
    EndIf
    Return armorName
EndFunction

Bool Function GetArmorDiagnostic() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorDebug", 0) == 1
EndFunction

Function ReportArmor(Bool diagnostic, String reportText) Global
    If !diagnostic
        Return
    EndIf
    Debug.Trace("[MME Extensions Armor] " + reportText)
EndFunction

Function NotifyArmorDebug(Bool diagnostic, String reportText) Global
    If !diagnostic
        Return
    EndIf
    Debug.Trace("[MME Extensions Armor] " + reportText)
    Debug.Notification("Armor Debug: " + reportText)
EndFunction
