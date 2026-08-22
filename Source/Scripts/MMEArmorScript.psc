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
; delayed pass consumes it. The overflow bit is diagnostic only: it records
; whether the attempt exceeded MME capacity without mutating MME state.
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

    ; Phase 2: the configurable stripping feature owns the player strip decision.
    ; This delayed pass observes stored and attempted milk only; it never writes
    ; MME's MilkCurrent. MME's own MilkCycle owns any overflow/leak math.
    If !IsConfigurableArmorStrippingEnabled()
        Report(diagnostic, "decision=BLOCKED | configurable armor stripping is disabled")
        Return
    EndIf

    ; Phase 3: reuse the same strip path as the capacity polling loop. The
    ; effective value is the higher of stored and attempted milk so an
    ; MME-clamped write still triggers the correct threshold decision.
    Float storedMilk = MME_Storage.getMilkCurrent(target)
    Float effectiveMilk = storedMilk
    If attemptedMilk > effectiveMilk
        effectiveMilk = attemptedMilk
    EndIf
    EvaluateArmorStrippingForActor(target, effectiveMilk, "drink")
EndFunction

; True when the configurable armor-stripping feature replaces MME's original
; slot-32 stripping. The same toggle drives ApplyArmorStrippingMasterToggle.
Bool Function IsConfigurableArmorStrippingEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableExtensionsArmorStripping", 1) == 1
EndFunction

; Reusable configurable strip path shared by the delayed post-drink check and
; the capacity polling loop. Observes milk only; never writes MME milk state.
Bool Function EvaluateArmorStrippingForActor(Actor target, Float effectiveMilk, String sourceLabel) Global
    Bool diagnostic = GetDiagnostic()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Debug.Trace("[MMEAlert Armor Stripping] MME controller unavailable; cannot evaluate stripping")
        Return False
    EndIf
    If !IsValidMilkMaid(target, milkController)
        ReportArmorStrip(diagnostic, sourceLabel + " decision=BLOCKED | actor is not a valid Milk Maid")
        Return False
    EndIf

    Int bodyMask = Armor.GetMaskForSlot(32)
    Armor slotArmor = target.GetWornForm(bodyMask) as Armor
    If slotArmor == None
        ReportArmorStrip(diagnostic, sourceLabel + " slot=32 | armor=<none> | decision=BLOCKED")
        Return False
    EndIf
    ReportArmorStrip(diagnostic, sourceLabel + " slot=32 | armor=" + GetArmorName(slotArmor))
    String ignoredRegistration = GetIgnoredAmbiguousRegistration(milkController, slotArmor)
    If ignoredRegistration != ""
        ReportArmorStrip(diagnostic, "ignoring ambiguous generic-name registration | " + ignoredRegistration)
    EndIf
    String protectionReason = GetMMEArmorProtectionReason(milkController, slotArmor)
    If protectionReason != ""
        ReportArmorStrip(diagnostic, sourceLabel + " decision=BLOCKED | protection=" + protectionReason)
        Return False
    EndIf
    If milkController.DDi != None && milkController.DDi.IsMilkingBlocked_Suit(target)
        ReportArmorStrip(diagnostic, sourceLabel + " decision=BLOCKED | protection=DD/special armor")
        Return False
    EndIf
    If !IsStripSafeByFramework(milkController, slotArmor)
        ReportArmorStrip(diagnostic, sourceLabel + " decision=BLOCKED | protection=SexLab no-strip")
        Return False
    EndIf

    Float threshold = GetArmorThreshold(slotArmor)
    String armorKind = "clothes"
    If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD2, "Skyrim.esm") as Keyword)
        armorKind = "heavy armor"
    ElseIf slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD3, "Skyrim.esm") as Keyword)
        armorKind = "light armor"
    EndIf
    ; A configured threshold of 0 is valid: strip whenever milk > 0. The slot-32
    ; armor is always classified here (heavy/light/clothing), and the missing-
    ; armor case was already handled above, so no unclassified guard is needed.
    If effectiveMilk <= threshold
        ReportArmorStrip(diagnostic, sourceLabel + " type=" + armorKind + " | milk=" + effectiveMilk + " | threshold=" + threshold + " | decision=BLOCKED")
        Return False
    EndIf

    ; Strip, then verify Skyrim actually changed slot 32. A successful Papyrus
    ; call is not proof: quests or equipment systems may re-equip immediately.
    ReportArmorStrip(diagnostic, sourceLabel + " type=" + armorKind + " | milk=" + effectiveMilk + " | threshold=" + threshold + " | decision=ALLOWED")
    target.UnequipItem(slotArmor)
    If target.GetWornForm(bodyMask) == slotArmor
        ReportArmorStrip(diagnostic, sourceLabel + " result=BLOCKED | engine retained " + armorKind)
        Return False
    EndIf
    If target == Game.GetPlayer()
        Debug.Notification("Your breasts are too big to fit into your " + armorKind)
    EndIf
    ReportArmorStrip(diagnostic, sourceLabel + " result=STRIPPED | " + armorKind + " | milk=" + effectiveMilk + " > " + threshold)
    Return True
EndFunction

; Gated strip reporter. Both the log line and the HUD notification respect the
; single Armor Stripping diagnostic toggle so the polling route stays quiet
; when diagnostics are disabled.
Function ReportArmorStrip(Bool showNotification, String reportText) Global
    If !showNotification
        Return
    EndIf
    Debug.Trace("[MMEAlert Armor Stripping] " + reportText)
    Debug.Notification("Armor Stripping: " + reportText)
EndFunction

; Applies the override master toggle without destroying MME's own setting.
; While the override is owned, MME stripping is forced off; when ownership ends
; the previously saved MME ArmorStrippingDisabled state is restored once.
Function ApplyArmorStrippingMasterToggle() Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return
    EndIf
    String ownershipKey = "MMEExtensions.ArmorStripping.Overriding"
    String savedStateKey = "MMEExtensions.ArmorStripping.SavedMMEState"
    Bool extensionsEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
    Bool overrideActive = extensionsEnabled && IsConfigurableArmorStrippingEnabled()
    Bool currentlyOwned = StorageUtil.GetIntValue(None, ownershipKey, 0) == 1
    If overrideActive
        If !currentlyOwned
            ; Take ownership exactly once: remember MME's live setting before
            ; forcing it off. Reloads and re-inits never overwrite the snapshot.
            StorageUtil.SetIntValue(None, savedStateKey, milkController.ArmorStrippingDisabled as Int)
            StorageUtil.SetIntValue(None, ownershipKey, 1)
        EndIf
        milkController.ArmorStrippingDisabled = True
    ElseIf currentlyOwned
        ; Release ownership and restore MME's previous stripping state.
        milkController.ArmorStrippingDisabled = StorageUtil.GetIntValue(None, savedStateKey, 0) == 1
        StorageUtil.UnsetIntValue(None, ownershipKey)
        StorageUtil.UnsetIntValue(None, savedStateKey)
    EndIf
EndFunction

; Classifies slot-32 armor and returns the active milk threshold. When the
; configurable stripping feature is enabled the MCM sliders supply the values
; (defaulting to MME's 4/8/12); otherwise MME's fixed thresholds apply.
Float Function GetArmorThreshold(Armor slotArmor) Global
    If slotArmor == None
        Return 0.0
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    If JsonUtil.GetIntValue(settingsFile, "enableExtensionsArmorStripping", 1) == 1
        If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD2, "Skyrim.esm") as Keyword)
            Return JsonUtil.GetFloatValue(settingsFile, "armorStripHeavyThreshold", 4.0)
        EndIf
        If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD3, "Skyrim.esm") as Keyword)
            Return JsonUtil.GetFloatValue(settingsFile, "armorStripLightThreshold", 8.0)
        EndIf
        Return JsonUtil.GetFloatValue(settingsFile, "armorStripClothingThreshold", 12.0)
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
    If armorName == "" || armorName == "Empty" || IsAmbiguousOrdinaryArmorName(armorName) || milkController.MilkingEquipment == None
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
    ; MME arrays store only display names. Generic names such as "clothes" can
    ; therefore leak from a stale/mistaken registration onto unrelated forms.
    ; Direct MME forms above and framework protections below remain unaffected.
    If IsAmbiguousOrdinaryArmorName(armorName)
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

; These generic labels do not carry enough identity to safely classify every
; same-named ARMO form as custom living/parasite/milking equipment. Keep this
; list deliberately narrow so MME's normal display-name registries still work.
Bool Function IsAmbiguousOrdinaryArmorName(String armorName) Global
    Return armorName == "clothes" || armorName == "Clothes" || armorName == "cloths" || armorName == "Cloths"
EndFunction

; Diagnostic-only evidence explaining when a bad generic-name array entry was
; ignored. This never mutates MME's authoritative arrays or Blacksmith state.
String Function GetIgnoredAmbiguousRegistration(MilkQUEST milkController, Armor slotArmor) Global
    If milkController == None || slotArmor == None
        Return ""
    EndIf
    String armorName = slotArmor.GetName()
    If !IsAmbiguousOrdinaryArmorName(armorName)
        Return ""
    EndIf
    If milkController.MilkingEquipment != None
        Int milkingIndex = milkController.MilkingEquipment.Find(armorName)
        If milkingIndex >= 0
            Return "registry=MilkingEquipment | index=" + milkingIndex + " | name=" + armorName
        EndIf
    EndIf
    If milkController.BasicLivingArmor != None
        Int livingIndex = milkController.BasicLivingArmor.Find(armorName)
        If livingIndex >= 0
            Return "registry=BasicLivingArmor | index=" + livingIndex + " | name=" + armorName
        EndIf
    EndIf
    If milkController.ParasiteLivingArmor != None
        Int parasiteIndex = milkController.ParasiteLivingArmor.Find(armorName)
        If parasiteIndex >= 0
            Return "registry=ParasiteLivingArmor | index=" + parasiteIndex + " | name=" + armorName
        EndIf
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
    Debug.Trace("[MMEAlert Armor Stripping] " + reportText)
EndFunction

; MME's own configured armor-name arrays are the source of truth.
; 0 unsupported, 1 Milking Armor, 2 AM Living Armor, 3 AM Living Parasite.
Int Function ClassifyArmor(MilkQUEST milkController, Armor equippedArmor) Global
    ; Direct form properties identify MME's canonical cuirasses even if renamed.
    ; Array matching intentionally uses the live display name because that is how
    ; MME exposes configurable third-party Milking/Living/Parasite equipment.
    ; Generic names such as "Clothes" are never trusted for array matching so a
    ; stale entry cannot turn an ordinary body armor into MME equipment.
    If milkController == None || equippedArmor == None
        Return 0
    EndIf
    If equippedArmor == milkController.MilkCuirass || equippedArmor == milkController.MilkCuirassFuta
        Return 1
    EndIf
    String armorName = equippedArmor.GetName()
    If IsAmbiguousOrdinaryArmorName(armorName)
        Return 0
    EndIf
    If armorName != "" && armorName != "Empty" && milkController.MilkingEquipment != None && milkController.MilkingEquipment.Find(armorName) >= 0
        Return 1
    EndIf
    If armorName != "" && armorName != "Empty" && milkController.BasicLivingArmor != None && milkController.BasicLivingArmor.Find(armorName) >= 0
        Return 2
    EndIf
    If armorName != "" && armorName != "Empty" && milkController.ParasiteLivingArmor != None && milkController.ParasiteLivingArmor.Find(armorName) >= 0
        Return 3
    EndIf
    Return GetSpecialArmorNameClass(armorName)
EndFunction

; Mirrors MME's established display-name compatibility after its exact arrays
; have had priority. Tentacle families use the high-intensity parasite path.
Int Function GetSpecialArmorNameClass(String armorName) Global
    If armorName == "" || armorName == "Empty"
        Return 0
    EndIf
    If StringUtil.Find(armorName, "Tentacle Armor") >= 0 || StringUtil.Find(armorName, "Tentacle Parasite") >= 0
        Return 3
    EndIf
    If StringUtil.Find(armorName, "Spriggan") >= 0 \
    || StringUtil.Find(armorName, "Living Arm") >= 0 \
    || StringUtil.Find(armorName, "Hermaeus Mora") >= 0 \
    || StringUtil.Find(armorName, "HM Priestess") >= 0
        Return 2
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
    If IsAmbiguousOrdinaryArmorName(armorName)
        Return "none"
    EndIf
    If milkController.MilkingEquipment != None && milkController.MilkingEquipment.Find(armorName) >= 0
        Return "MilkingEquipment"
    ElseIf milkController.BasicLivingArmor != None && milkController.BasicLivingArmor.Find(armorName) >= 0
        Return "BasicLivingArmor"
    ElseIf milkController.ParasiteLivingArmor != None && milkController.ParasiteLivingArmor.Find(armorName) >= 0
        Return "ParasiteLivingArmor"
    EndIf
    If StringUtil.Find(armorName, "Tentacle Armor") >= 0
        Return "MME special name rule=Tentacle Armor"
    ElseIf StringUtil.Find(armorName, "Tentacle Parasite") >= 0
        Return "MME special name rule=Tentacle Parasite"
    ElseIf StringUtil.Find(armorName, "Spriggan") >= 0
        Return "MME special name rule=Spriggan"
    ElseIf StringUtil.Find(armorName, "Living Arm") >= 0
        Return "MME special name rule=Living Arm"
    ElseIf StringUtil.Find(armorName, "Hermaeus Mora") >= 0
        Return "MME special name rule=Hermaeus Mora"
    ElseIf StringUtil.Find(armorName, "HM Priestess") >= 0
        Return "MME special name rule=HM Priestess"
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

    ; Equip-time configurable stripping for the player. When the override is on,
    ; a freshly worn ordinary body armor is evaluated immediately so an
    ; over-threshold player does not wait for the next drink or fullness poll.
    ; The shared evaluator declines protected MME/special armor, which then
    ; continues its normal equip reaction path below.
    If wearer == Game.GetPlayer() && IsConfigurableArmorStrippingEnabled() && equippedArmor == wearer.GetWornForm(Armor.GetMaskForSlot(32))
        If EvaluateArmorStrippingForActor(wearer, MME_Storage.getMilkCurrent(wearer), "equip")
            ReportArmor(diagnostic, "equip-time strip removed the body armor; reaction path ends")
            Return
        EndIf
    EndIf

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
