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

; Temporary workaround: when enabled, the configurable strip path ignores MME
; armor protection classification and strips slot 32 whenever the fullness
; threshold says strip. Framework safety (DD, SexLab no-strip) still applies.
Bool Function IsStripAllArmorEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableStripAllArmor", 0) == 1
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
    String protectionReason = ""
    If IsStripAllArmorEnabled()
        ; Temporary override: bypass MME armor protection classification. The
        ; reason is still resolved so diagnostics can prove what was ignored.
        String bypassedProtection = GetMMEArmorProtectionReason(milkController, slotArmor, sourceLabel, target)
        If bypassedProtection != "" && diagnostic
            Debug.Trace("[MMEAlert Armor Stripping] " + sourceLabel + " override=Strip All Armor | actor=" + GetActorName(target) + " | armor=" + GetArmorName(slotArmor) + " | formID=" + slotArmor.GetFormID() + " | MME protection ignored=" + bypassedProtection)
        EndIf
    Else
        protectionReason = GetMMEArmorProtectionReason(milkController, slotArmor, sourceLabel, target)
    EndIf
    If protectionReason != ""
        ReportArmorStrip(diagnostic, sourceLabel + " decision=BLOCKED | protection=" + protectionReason)
        If diagnostic
            Debug.Trace("[MMEAlert Armor Stripping] " + sourceLabel + " actor=" + GetActorName(target) + " | armor=" + GetArmorName(slotArmor) + " | formID=" + slotArmor.GetFormID() + " | protection=" + protectionReason)
        EndIf
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
    ; Thresholds are fullness percentages (0-100). 0 means the armor type is
    ; forbidden, 100 means strip at full, and fullness can legitimately exceed
    ; 100% when MME stores more milk than the current maximum.
    Float maximum = MME_Storage.getMilkMaximum(target)
    If maximum <= 0.0
        ReportArmorStrip(diagnostic, sourceLabel + " decision=BLOCKED | milk maximum unavailable")
        Return False
    EndIf
    Float fullnessPct = (effectiveMilk / maximum) * 100.0
    If fullnessPct < threshold
        ReportArmorStrip(diagnostic, sourceLabel + " type=" + armorKind + " | fullness=" + fullnessPct + "% | threshold=" + threshold + "% | decision=KEEP")
        Return False
    EndIf

    ; Strip, then verify Skyrim actually changed slot 32. A successful Papyrus
    ; call is not proof: quests or equipment systems may re-equip immediately.
    ReportArmorStrip(diagnostic, sourceLabel + " type=" + armorKind + " | fullness=" + fullnessPct + "% | threshold=" + threshold + "% | decision=STRIP")
    target.UnequipItem(slotArmor)
    If target.GetWornForm(bodyMask) == slotArmor
        ReportArmorStrip(diagnostic, sourceLabel + " result=BLOCKED | engine retained " + armorKind)
        Return False
    EndIf
    ReportArmorStrip(diagnostic, sourceLabel + " result=STRIPPED | " + armorKind + " | fullness=" + fullnessPct + "% >= " + threshold + "%")
    ; Only a verified removal may trigger the optional post-strip reactions.
    HandleSuccessfulArmorStrip(target, slotArmor, fullnessPct, threshold, sourceLabel)
    Return True
EndFunction

; Dispatches the optional post-strip reactions once the shared evaluator has
; verified that the armor actually left slot 32. Reachable from every route
; (drink/equip/poll) through the one shared evaluator.
Function HandleSuccessfulArmorStrip(Actor wearer, Armor strippedArmor, Float fullnessPct, Float thresholdPct, String sourceLabel) Global
    HandleArmorStripNotification(wearer, strippedArmor)
    PlayArmorStripMoan(wearer)
    MMEAlertsSkyrimNet.NarrateArmorStrip(wearer, strippedArmor, sourceLabel, fullnessPct, thresholdPct)
EndFunction

; Normal gameplay notification, independent of diagnostics and Skyrim.Net.
Function HandleArmorStripNotification(Actor wearer, Armor strippedArmor) Global
    Bool diagnostic = GetArmorStripNotificationDiagnostic()
    String armorName = ""
    If strippedArmor != None
        armorName = strippedArmor.GetName()
    EndIf
    If armorName == ""
        armorName = "armor"
    EndIf
    ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Notification]", "Armor Strip Notification: trigger | " + armorName)
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorStripNotification", 1) != 1
        ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Notification]", "Armor Strip Notification: skipped - feature disabled")
        Return
    EndIf
    Debug.Notification("Your " + armorName + " flies off! Your tits exceeded its rated capacity!")
    ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Notification]", "Armor Strip Notification: SHOWN | " + armorName)
EndFunction

; Strong reaction moan after a verified strip. Reuses the HOT pool and the
; shared reaction-sounds switch and volume.
Int Function PlayArmorStripMoan(Actor wearer) Global
    Bool diagnostic = GetArmorStripMoanDiagnostic()
    ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: trigger detected")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorStripMoan", 1) != 1
        ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: skipped - feature disabled")
        Return 0
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableReactionSounds", 1) != 1
        ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: skipped - global sounds disabled")
        Return 0
    EndIf
    If wearer == None || wearer.IsDead() || wearer.IsDisabled() || !wearer.Is3DLoaded()
        ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: failed - actor unavailable")
        Return -1
    EndIf
    Sound reaction = Game.GetFormFromFile(0x000856, "MMEAlert.esp") as Sound
    If reaction == None
        ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: failed - HOT sound unresolved")
        Return -1
    EndIf
    Int instance = reaction.Play(wearer)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue("/MMEAlerts/Settings", "reactionSoundVolume", 100.0) / 100.0)
        ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: PLAYED | instance=" + instance)
        Return 1
    EndIf
    ReportArmorStripReaction(diagnostic, "[MME Extensions Armor Strip Moan]", "Armor Strip Moan: failed - Sound.Play returned " + instance)
    Return -1
EndFunction

Bool Function GetArmorStripNotificationDiagnostic() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorStripNotificationDiagnostic", 0) == 1
EndFunction

Bool Function GetArmorStripMoanDiagnostic() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorStripMoanDiagnostic", 0) == 1
EndFunction

; Reaction diagnostics emit a matching log line plus a HUD notification only
; while the dedicated diagnostic toggle is enabled. Never affects gameplay.
Function ReportArmorStripReaction(Bool diagnostic, String logChannel, String reportText) Global
    If !diagnostic
        Return
    EndIf
    Debug.Trace(logChannel + " | " + reportText)
    Debug.Notification(reportText)
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

; Classifies slot-32 armor and returns the active fullness-percentage
; threshold. When the configurable stripping feature is enabled the MCM sliders
; supply the values; otherwise MME's fixed thresholds apply.
Float Function GetArmorThreshold(Armor slotArmor) Global
    If slotArmor == None
        Return 0.0
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    If JsonUtil.GetIntValue(settingsFile, "enableExtensionsArmorStripping", 1) == 1
        If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD2, "Skyrim.esm") as Keyword)
            Return JsonUtil.GetFloatValue(settingsFile, "armorStripHeavyPercent", 100.0)
        EndIf
        If slotArmor.HasKeyword(Game.GetFormFromFile(0x6BBD3, "Skyrim.esm") as Keyword)
            Return JsonUtil.GetFloatValue(settingsFile, "armorStripLightPercent", 100.0)
        EndIf
        Return JsonUtil.GetFloatValue(settingsFile, "armorStripClothingPercent", 100.0)
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
; `source`/`wearer` are forensic labels only: they tag the Papyrus log with the
; caller path (drink/poll/equip) and the actor being evaluated, without
; changing the decision.
String Function GetMMEArmorProtectionReason(MilkQUEST milkController, Armor slotArmor, String source = "unknown", Actor wearer = None) Global
    Return ResolveArmorProtectionReason(milkController, slotArmor, source, wearer, True)
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

String Function GetNativeMMEArmorProtectionReason(MilkQUEST milkController, Armor slotArmor, String source = "unknown", Actor wearer = None) Global
    Return ResolveArmorProtectionReason(milkController, slotArmor, source, wearer, False)
EndFunction

; Single implementation behind both protection entry points. includeUserRegistry
; only gates the trailing MilkingEquipment decision; the native/special checks
; are identical in both. Every array lookup happens exactly once here, and the
; exact same local variables drive both the forensic log and the decision, so
; the evidence can never disagree with the code path that actually ran.
String Function ResolveArmorProtectionReason(MilkQUEST milkController, Armor slotArmor, String source, Actor wearer, Bool includeUserRegistry) Global
    If milkController == None || slotArmor == None
        Return "invalid MME/armor state"
    EndIf
    ; Direct MME form properties are unambiguous and never consult the arrays.
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
    ; Compute each lookup exactly once. These are the values logged below and
    ; also the values used for the protection decision.
    Int milkingIndex = -1
    If milkController.MilkingEquipment != None
        milkingIndex = milkController.MilkingEquipment.Find(armorName)
    EndIf
    Int basicIndex = -1
    If milkController.BasicLivingArmor != None
        basicIndex = milkController.BasicLivingArmor.Find(armorName)
    EndIf
    Int parasiteIndex = -1
    If milkController.ParasiteLivingArmor != None
        parasiteIndex = milkController.ParasiteLivingArmor.Find(armorName)
    EndIf
    ; Native arrays and MME's established name rules always outrank the
    ; user-managed MilkingEquipment registry.
    String reason = ""
    If basicIndex >= 0
        reason = "registry=BasicLivingArmor | index=" + basicIndex + " | storedName=" + milkController.BasicLivingArmor[basicIndex]
    ElseIf parasiteIndex >= 0
        reason = "registry=ParasiteLivingArmor | index=" + parasiteIndex + " | storedName=" + milkController.ParasiteLivingArmor[parasiteIndex]
    ElseIf StringUtil.Find(armorName, "Milk") >= 0
        reason = "MME name rule=Milk"
    ElseIf StringUtil.Find(armorName, "Cow") >= 0
        reason = "MME name rule=Cow"
    ElseIf StringUtil.Find(armorName, "Spriggan") >= 0 \
    || StringUtil.Find(armorName, "Living Arm") >= 0 \
    || StringUtil.Find(armorName, "Hermaeus Mora") >= 0 \
    || StringUtil.Find(armorName, "HM Priestess") >= 0 \
    || StringUtil.Find(armorName, "Tentacle Armor") >= 0 \
    || StringUtil.Find(armorName, "Tentacle Parasite") >= 0 \
    || StringUtil.Find(armorName, "Dwemer milking device") >= 0 \
    || StringUtil.Find(armorName, "Cow Harness") >= 0 \
    || StringUtil.Find(armorName, "Milking Cuirass") >= 0 \
    || StringUtil.Find(armorName, "Milker") >= 0
        reason = "MME special name rule"
    ElseIf includeUserRegistry && milkingIndex >= 0
        reason = "registry=MilkingEquipment | index=" + milkingIndex + " | storedName=" + milkController.MilkingEquipment[milkingIndex]
    EndIf
    If GetArmorLookupDiagnostic()
        ReportArmorLookupForensics(milkController, slotArmor, source, wearer, armorName, milkingIndex, basicIndex, parasiteIndex, reason)
    EndIf
    Return reason
EndFunction

; Diagnostic gate for the point-in-time armor lookup forensics. Log-only, off
; by default, and independent of the HUD-spamming stripping diagnostics.
Bool Function GetArmorLookupDiagnostic() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorLookupForensics", 0) == 1
EndFunction

; Forensic log emitted at the exact instant an armor protection/classification
; decision is made. The find results passed in are the SAME locals the caller
; used for its decision. Papyrus log only; never a HUD notification.
Function ReportArmorLookupForensics(MilkQUEST milkController, Armor slotArmor, String source, Actor wearer, String armorName, Int milkingIndex, Int basicIndex, Int parasiteIndex, String decision) Global
    String actorLabel = "<none>"
    If wearer != None
        If wearer == Game.GetPlayer()
            actorLabel = "Player"
        Else
            actorLabel = wearer.GetDisplayName()
        EndIf
    EndIf
    String controllerIdentity = "<none>"
    If milkController != None
        controllerIdentity = milkController.GetName() + " | formID=" + milkController.GetFormID()
    EndIf
    Debug.Trace("[MME Extensions Armor Lookup]")
    Debug.Trace("[MME Extensions Armor Lookup] source=" + source)
    Debug.Trace("[MME Extensions Armor Lookup] actor=" + actorLabel)
    Debug.Trace("[MME Extensions Armor Lookup] armor=" + armorName)
    If slotArmor != None
        Debug.Trace("[MME Extensions Armor Lookup] armorFormID=" + slotArmor.GetFormID())
    EndIf
    Debug.Trace("[MME Extensions Armor Lookup] milkController=" + controllerIdentity)
    DumpArmorLookupArray("MilkingEquipment", milkController.MilkingEquipment, armorName, milkingIndex)
    DumpArmorLookupArray("BasicLivingArmor", milkController.BasicLivingArmor, armorName, basicIndex)
    DumpArmorLookupArray("ParasiteLivingArmor", milkController.ParasiteLivingArmor, armorName, parasiteIndex)
    String decisionLabel = decision
    If decisionLabel == ""
        decisionLabel = "<none>"
    EndIf
    Debug.Trace("[MME Extensions Armor Lookup] decision=" + decisionLabel)
EndFunction

; Logs one MME string array plus the exact Find() result used for the decision.
; Dumps every entry so stale/duplicate array data is visible in one block.
Function DumpArmorLookupArray(String arrayName, String[] entries, String armorName, Int foundIndex) Global
    If entries == None
        Debug.Trace("[MME Extensions Armor Lookup] " + arrayName + " = <None>")
        Return
    EndIf
    Debug.Trace("[MME Extensions Armor Lookup] " + arrayName + ".length=" + entries.Length)
    Int i = 0
    While i < entries.Length
        String stored = entries[i]
        If stored == ""
            stored = "<empty>"
        EndIf
        Debug.Trace("[MME Extensions Armor Lookup] " + arrayName + "[" + i + "]=" + stored)
        i += 1
    EndWhile
    Debug.Trace("[MME Extensions Armor Lookup] " + arrayName + ".Find(\"" + armorName + "\")=" + foundIndex)
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

; Diagnostic array dump for the Armor Array Check MCM section. Reads the three
; independent toggles and logs every entry of each enabled MME string array.
; Strictly read-only: never modifies, repairs, or replaces MME's arrays.
Function DumpArmorArrays() Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Debug.Trace("[MME Extensions Armor Array] MilkQUEST unavailable; array dump skipped")
        Return
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorArrayMonitorMilking", 0) == 1
        DumpArmorArray("MilkingEquipment", milkController.MilkingEquipment)
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorArrayMonitorBasicLiving", 0) == 1
        DumpArmorArray("BasicLivingArmor", milkController.BasicLivingArmor)
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableArmorArrayMonitorParasiteLiving", 0) == 1
        DumpArmorArray("ParasiteLivingArmor", milkController.ParasiteLivingArmor)
    EndIf
EndFunction

; Logs one MME string array safely, including None, zero-length, and empty
; entries. Empty strings are rendered distinctly from MME's "Empty" sentinel.
Function DumpArmorArray(String arrayName, String[] entries) Global
    If entries == None
        Debug.Trace("[MME Extensions Armor Array] " + arrayName + " = <None>")
        Return
    EndIf
    If entries.Length <= 0
        Debug.Trace("[MME Extensions Armor Array] " + arrayName + " = <empty>")
        Return
    EndIf
    Int i = 0
    While i < entries.Length
        String stored = entries[i]
        If stored == ""
            stored = "<empty>"
        EndIf
        Debug.Trace("[MME Extensions Armor Array] " + arrayName + "[" + i + "] = " + stored)
        i += 1
    EndWhile
EndFunction

; MME's own configured armor-name arrays are the source of truth.
; 0 unsupported, 1 Milking Armor, 2 AM Living Armor, 3 AM Living Parasite.
Int Function ClassifyArmor(MilkQUEST milkController, Armor equippedArmor, String source = "unknown", Actor wearer = None) Global
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
    If armorName == "" || armorName == "Empty" || IsAmbiguousOrdinaryArmorName(armorName)
        Return 0
    EndIf
    ; Compute each lookup exactly once. The same locals drive both the forensic
    ; log and the classification decision.
    Int milkingIndex = -1
    If milkController.MilkingEquipment != None
        milkingIndex = milkController.MilkingEquipment.Find(armorName)
    EndIf
    Int basicIndex = -1
    If milkController.BasicLivingArmor != None
        basicIndex = milkController.BasicLivingArmor.Find(armorName)
    EndIf
    Int parasiteIndex = -1
    If milkController.ParasiteLivingArmor != None
        parasiteIndex = milkController.ParasiteLivingArmor.Find(armorName)
    EndIf
    Int armorClass = 0
    If milkingIndex >= 0
        armorClass = 1
    ElseIf basicIndex >= 0
        armorClass = 2
    ElseIf parasiteIndex >= 0
        armorClass = 3
    Else
        armorClass = GetSpecialArmorNameClass(armorName)
    EndIf
    If GetArmorLookupDiagnostic()
        ReportArmorLookupForensics(milkController, equippedArmor, source, wearer, armorName, milkingIndex, basicIndex, parasiteIndex, GetArmorTypeLabel(armorClass))
    EndIf
    Return armorClass
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
    Int armorClass = ClassifyArmor(milkController, equippedArmor, "equip", wearer)
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
