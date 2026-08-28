Scriptname MMEAlertsSkyrimNet extends Quest

; ---------------------------------------------------------------------------
; Optional Skyrim.Net publication boundary
; ---------------------------------------------------------------------------
; This script owns all direct SkyrimNetApi calls. Gameplay scripts pass verified
; actors/events here, but every public entry point still rechecks the master
; toggle and optional plugin. Short-lived context events never call narration;
; DirectNarration paths are token-using, separately toggled, and cooldown-bound.

Bool Function IsAvailable() Global
    Return Game.GetModByName("SkyrimNet.esp") != 255
EndFunction

Bool Function IsExtensionsEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
EndFunction

; Registers callbacks used by actor-specific MME prompt modules.
Function RegisterPromptDecorator() Global
    ; Registration may be repeated after load/MCM upgrades. Skyrim.Net's return
    ; code can therefore mean "already registered" and is logged, not fatal.
    If !IsExtensionsEnabled()
        Return
    EndIf
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetPromptDiagnostic", 1) == 1
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Prompt: registration skipped - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid prompt decorator skipped; SkyrimNet not detected")
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterDecorator("mme_milkmaid_prompt_debug", "MMEAlertsSkyrimNet", "MilkmaidPromptDebug")
    If diagnostic
        If result == 0
            Debug.Notification("Skyrim.Net Prompt: debug callback registered [0]")
        Else
            Debug.Notification("Skyrim.Net Prompt: registration returned [" + result + "] - it may already be registered")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milkmaid prompt decorator registration result " + result)
    Int breastfeedingResult = SkyrimNetApi.RegisterDecorator("mme_breastfeeding_role", "MMEAlertsSkyrimNet", "BreastfeedingPromptRole")
    Debug.Trace("[MMEAlert SkyrimNet] Breastfeeding prompt decorator registration result " + breastfeedingResult)
EndFunction

Function SetBreastfeedingPromptState(Actor participant, String role, Int threadID) Global
    If participant == None || (role != "source" && role != "drinker") || threadID < 0
        Return
    EndIf
    StorageUtil.SetStringValue(participant, "MME.Extensions.SexLabBreastfeeding.Role", role)
    StorageUtil.SetIntValue(participant, "MME.Extensions.SexLabBreastfeeding.Thread", threadID)
    Debug.Trace("[MMEAlert SkyrimNet BF Prompt] state SET | actor=" + ResolveActorName(participant, "unnamed actor") + " | role=" + role + " | thread=" + threadID)
EndFunction

Function ClearBreastfeedingPromptState(Actor participant, Int expectedThreadID = -1) Global
    If participant == None || !StorageUtil.HasStringValue(participant, "MME.Extensions.SexLabBreastfeeding.Role")
        Return
    EndIf
    Int storedThreadID = StorageUtil.GetIntValue(participant, "MME.Extensions.SexLabBreastfeeding.Thread", -1)
    If expectedThreadID >= 0 && storedThreadID != expectedThreadID
        Return
    EndIf
    StorageUtil.UnsetStringValue(participant, "MME.Extensions.SexLabBreastfeeding.Role")
    StorageUtil.UnsetIntValue(participant, "MME.Extensions.SexLabBreastfeeding.Thread")
    Debug.Trace("[MMEAlert SkyrimNet BF Prompt] state CLEARED | actor=" + ResolveActorName(participant, "unnamed actor") + " | thread=" + storedThreadID)
EndFunction

String Function BreastfeedingPromptRole(Actor participant) Global
    If !IsExtensionsEnabled() || participant == None
        Return ""
    EndIf
    String role = StorageUtil.GetStringValue(participant, "MME.Extensions.SexLabBreastfeeding.Role", "")
    Int threadID = StorageUtil.GetIntValue(participant, "MME.Extensions.SexLabBreastfeeding.Thread", -1)
    If role == "" || threadID < 0
        Return ""
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    sslThreadController thread = None
    If milkController != None && milkController.SexLab != None
        thread = milkController.SexLab.GetActorController(participant)
    EndIf
    If thread == None || thread.tid != threadID || thread.Positions == None || thread.Positions.Find(participant) < 0 || !milkController.SexLab.IsActorActive(participant)
        ClearBreastfeedingPromptState(participant, threadID)
        Return ""
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet BF Prompt] prompt rendered | actor=" + ResolveActorName(participant, "unnamed actor") + " | role=" + role + " | thread=" + threadID)
    Return role
EndFunction

; Uses MME's authoritative runtime list rather than an inferred StorageUtil value.
Bool Function IsRealMMEMilkmaid(Actor candidate) Global
    If candidate == None
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return False
    EndIf
    ; MME's MilkMaid list is a typed Actor[] on MilkQUEST. Delegate to the
    ; None-safe membership check shared with armor classification.
    Return MMEArmorScript.IsMilkMaidMember(candidate, milkController.MilkMaid)
EndFunction

; Returns an explicit string gate because prompt values may not preserve Papyrus numeric types.
String Function MilkmaidPromptDebug(Actor milkMaid) Global
    If !IsExtensionsEnabled()
        Return ""
    EndIf
    If milkMaid == None
        Return ""
    EndIf
    If !IsRealMMEMilkmaid(milkMaid)
        Return ""
    EndIf

    Float level = StorageUtil.GetFloatValue(milkMaid, "MME.MilkMaid.Level", -1.0)
    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "unnamed actor"
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetPromptDiagnostic", 1) == 1
        Debug.Notification("Skyrim.Net Prompt: Milkmaid lore rendered for " + actorName + " | MME level " + level)
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milkmaid lore rendered for " + actorName + " | MME level " + level)
    Return "true"
EndFunction

; Global entry points let the established controller call SkyrimNet directly.
; They do not depend on a newly attached quest-script instance in existing saves.
Function SendMilkingStart(Actor milkMaid) Global
    SendMilkingEvent(milkMaid, "startMessage")
EndFunction

Function SendMilkingEnd(Actor milkMaid) Global
    SendMilkingEvent(milkMaid, "endMessage")
EndFunction

; Direct narration for one supported armor equip. Classification is repeated
; here so narration never trusts a caller's label or a hardcoded armor name.
Int Function NarrateArmorEquip(Actor wearer, Armor equippedArmor) Global
    ; Phase 1: revalidate actor membership and classify the actual equipped ARMO.
    ; Never trust a caller-provided label: MME's live arrays are source of truth.
    Bool diagnostic = MMEArmorScript.GetArmorDiagnostic()
    If !IsExtensionsEnabled()
        Return -1
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If wearer == None || equippedArmor == None || milkController == None || !MMEArmorScript.IsMilkMaidMember(wearer, milkController.MilkMaid)
        MMEArmorScript.ReportArmor(diagnostic, "equip narration rejected: actor/armor missing or actor not an MME Milk Maid")
        Return -2
    EndIf

    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, equippedArmor, "equip-narration", wearer)
    String armorType = MMEArmorScript.GetArmorTypeLabel(armorClass)
    String matchSource = MMEArmorScript.GetArmorClassificationSource(milkController, equippedArmor)
    Bool isPlayer = wearer == Game.GetPlayer()
    String role = "NPC"
    String narrationToggle = "enableNPCMilkArmorEquipNarration"
    If isPlayer
        role = "PLAYER"
        narrationToggle = "enablePlayerMilkArmorEquipNarration"
    EndIf
    String actorName = ResolveActorName(wearer, "The Milk Maid")
    MMEArmorScript.ReportArmor(diagnostic, "equip narration detected | actor=" + actorName + " | role=" + role + " | armor=" + equippedArmor.GetName() + " | matched=" + matchSource + " | classification=" + armorType)
    If armorClass == 0
        MMEArmorScript.ReportArmor(diagnostic, "equip narration skipped: Unsupported")
        Return -3
    EndIf
    ; Phase 2: select the independent Player/NPC toggle after classification.
    Bool narrationEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", narrationToggle, 1) == 1
    MMEArmorScript.ReportArmor(diagnostic, "equip narration enabled=" + narrationEnabled + " | role=" + role + " | type=" + armorType)
    If !narrationEnabled
        Return -4
    EndIf
    If !IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        MMEArmorScript.ReportArmor(diagnostic, "equip narration failed: Skyrim.Net unavailable")
        Return -5
    EndIf
    If isPlayer && !SkyrimNetApi.GetConfigBool("PlayerDialogue", "enabled", True)
        MMEArmorScript.ReportArmor(diagnostic, "equip narration skipped: Skyrim.Net PlayerDialogue disabled")
        Return -7
    EndIf

    ; Phase 3: enforce role-specific real-time cooldowns. CurrentRealTime resets
    ; between Skyrim sessions, so a saved future timestamp must be discarded.
    String cooldownKey = "npcMilkingArmorNarrationCooldown"
    String lastKey = "lastNPCMilkingArmorNarrationRealTime"
    Float defaultCooldown = 300.0
    If isPlayer
        cooldownKey = "playerMilkingArmorNarrationCooldown"
        lastKey = "lastPlayerMilkingArmorNarrationRealTime"
        defaultCooldown = 120.0
    EndIf
    Float cooldown = JsonUtil.GetFloatValue("/MMEAlerts/Settings", cooldownKey, defaultCooldown)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue("/MMEAlerts/Settings", lastKey, -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        Int remaining = (cooldown - (now - last)) as Int
        MMEArmorScript.ReportArmor(diagnostic, "equip narration skipped by " + role + " cooldown | " + remaining + "s | type=" + armorType)
        Return -6
    EndIf

    ; Phase 4: build class-specific narration and route it through the API path
    ; appropriate to the wearer. Persist cooldown only after Skyrim.Net accepts
    ; the final dialogue request (code 0).
    String narrationType = "Milking Armor"
    String content = actorName + " has equipped Milking Armor. The suction cups are on her breasts and she looks thrilled with the hands-free attention. React creatively with playful, suggestive humor. Don't simply restate the event."
    If armorClass == 2
        narrationType = "Living Armor"
        content = actorName + " has equipped Living Armor. Its living tendrils tease her body and breasts, and she is clearly thrilled by the experience. Treat it as kinky and fun, not frightening. React creatively with playful, suggestive humor. Don't simply restate the event."
    ElseIf armorClass == 3
        narrationType = "Living Parasite"
        content = actorName + " has equipped Living Parasite armor. Its tentacles tease her body and breasts, and she seems delighted with the arrangement. Treat it as kinky and fun, not frightening. React creatively with playful, suggestive humor. Don't simply restate the event."
    EndIf
    Int result = 1
    If isPlayer
        ; PlayerDialogue generates the player's own line from current context.
        ; Publish the equip fact first so the autonomous response knows what
        ; happened without forcing a prewritten player utterance.
        Int contextResult = SkyrimNetApi.RegisterShortLivedEvent("mme_armor_equip_player", "mme_armor_equip", content, "{}", 45000, wearer, None)
        If contextResult == 0
            result = SkyrimNetApi.TriggerPlayerDialogue()
        Else
            MMEArmorScript.ReportArmor(diagnostic, "equip narration failed: player context event rejected | result=" + contextResult)
        EndIf
    Else
        ; Let Skyrim.Net choose a nearby NPC speaker and address the wearer.
        ; The NPC wearer is never forced to narrate their own equip event.
        result = SkyrimNetApi.DirectNarration(content, None, wearer)
    EndIf
    If result == 0
        JsonUtil.SetFloatValue("/MMEAlerts/Settings", lastKey, now)
        JsonUtil.Save("/MMEAlerts/Settings", False)
        MMEArmorScript.ReportArmor(diagnostic, "equip narration sent | actor=" + actorName + " | role=" + role + " | type=" + narrationType + " | result=0")
    Else
        MMEArmorScript.ReportArmor(diagnostic, "equip narration failed | actor=" + actorName + " | role=" + role + " | type=" + narrationType + " | result=" + result)
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Armor equip narration result " + result + " | " + role + " | " + narrationType + " | cooldown " + cooldown + " | " + content)
    Return result
EndFunction

; Requests one forced narration after a verified armor strip. The world reacts
; to the stripped Milk Maid; the player is never forced to speak. Cooldown is
; committed only after Skyrim.Net accepts the request.
Int Function NarrateArmorStrip(Actor wearer, Armor strippedArmor, String sourceLabel, Float fullnessPct, Float thresholdPct) Global
    If !IsExtensionsEnabled() || wearer == None
        Return -1
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableArmorStripNarrationDiagnostic", 0) == 1
    ReportArmorStripNarration(diagnostic, "Armor Strip Narration: trigger | source=" + sourceLabel)
    String armorName = ""
    If strippedArmor != None
        armorName = strippedArmor.GetName()
    EndIf
    If armorName == ""
        armorName = "armor"
    EndIf
    String actorName = ResolveActorName(wearer, "The Milk Maid")
    ReportArmorStripNarration(diagnostic, "Armor Strip Narration: actor=" + actorName + " | armor=" + armorName)
    ReportArmorStripNarration(diagnostic, "Armor Strip Narration: fullness=" + (fullnessPct as Int) + "% | threshold=" + (thresholdPct as Int) + "%")
    If JsonUtil.GetIntValue(settingsFile, "enableArmorStripNarration", 1) != 1
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: skipped - feature disabled")
        Return -2
    EndIf
    If !IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: failed - Skyrim.Net unavailable")
        Return -3
    EndIf

    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "armorStripNarrationCooldown", 300.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastArmorStripNarrationRealTime", -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        Int remaining = (cooldown - (now - last)) as Int
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: skipped - cooldown " + remaining + "s remaining")
        Return -6
    EndIf
    ReportArmorStripNarration(diagnostic, "Armor Strip Narration: cooldown READY")

    Int chance = JsonUtil.GetIntValue(settingsFile, "armorStripNarrationChance", 100)
    If chance < 0
        chance = 0
    ElseIf chance > 100
        chance = 100
    EndIf
    If chance == 0
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: skipped - chance 0%")
        Return -4
    EndIf
    Int roll = Utility.RandomInt(1, 100)
    If roll > chance
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: skipped - chance roll " + roll + " > " + chance)
        Return -5
    EndIf
    ReportArmorStripNarration(diagnostic, "Armor Strip Narration: chance roll " + roll + " <= " + chance + " PASS")

    String content = actorName + "'s " + armorName + " has flown right off her body because her milk-swollen breasts have gotten far too big for it. React creatively with exaggerated, playful, suggestive humor. Don't simply restate the event."
    ReportArmorStripNarration(diagnostic, "Armor Strip Narration: sending DirectNarration")
    Int result = SkyrimNetApi.DirectNarration(content, None, wearer)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastArmorStripNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: ACCEPTED [0] | cooldown started | " + (cooldown as Int) + "s")
    Else
        ReportArmorStripNarration(diagnostic, "Armor Strip Narration: REJECTED [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Armor strip DirectNarration result " + result + " | " + content)
    Return result
EndFunction

; Narration diagnostics: log plus HUD only while the dedicated toggle is on.
Function ReportArmorStripNarration(Bool diagnostic, String reportText) Global
    If !diagnostic
        Return
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet Armor Strip] " + reportText)
    Debug.Notification(reportText)
EndFunction

; Publishes actor-specific capacity crossings for two minutes without forcing dialogue.
Function SendCapacityMilestone(Actor milkMaid, Int crossing) Global
    ; Validate feature/plugin state before building payloads. Milestones are
    ; context only: they use stable per-actor IDs and never consume narration.
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetStatusDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkStatuses", 1) != 1
        Return
    EndIf
    If !IsAvailable() || milkMaid == None || JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Milestone: skipped - integration or actor unavailable")
        EndIf
        Return
    EndIf

    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "The Milk Maid"
    EndIf
    String eventType = "milk_half_full"
    String tag = "[half full]"
    String content = tag + " " + actorName + " is halfway full of milk, pleasantly heavy and getting excited."
    If crossing == 2
        eventType = "milk_full"
        tag = "[milk full]"
        content = tag + " " + actorName + " is completely full of milk, deliciously swollen and savoring the ultimate pleasure."
    EndIf
    String restrainedContent = BuildRestrainedCapacityContent(milkMaid, crossing)
    If restrainedContent != ""
        content = tag + " " + restrainedContent
    EndIf

    String actorUuid = SkyrimNetApi.GetEntityUUID(milkMaid)
    If actorUuid == ""
        actorUuid = "form_" + milkMaid.GetFormID()
    EndIf
    String eventId = eventType + "_" + actorUuid
    ; Stable event ID + TTL makes repeated crossings refresh/replace context
    ; rather than grow an unbounded history of transient fullness statements.
    Int ttlMs = JsonUtil.GetIntValue(settingsFile, "capacityMilestoneTtlMs", 120000)
    Int result = SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, content, "{}", ttlMs, milkMaid, None)
    If diagnostic
        If result == 0
            Debug.Notification("Skyrim.Net Milestone: " + tag + " accepted | " + actorName + " | 120s")
        Else
            Debug.Notification("Skyrim.Net Milestone: " + tag + " rejected [" + result + "]")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Capacity milestone " + eventType + " result " + result + " | " + actorName + " | " + content)
EndFunction

; Makes at most one token-using narration request for a completed scan's full crossings.
Function NarrateMilkFull(Actor milkMaid) Global
    ; Phase 1: resolve toggle, dependency, and one global scan-level cooldown.
    ; The controller selects at most one full actor per scan before calling here.
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableMilkFullNarrationDiagnostic", 0) == 1
    If diagnostic
        Debug.Notification("Milk Full Narration: trigger detected")
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableMilkFullNarration", 1) != 1
        If diagnostic
            Debug.Notification("Milk Full Narration: skipped - feature disabled")
        EndIf
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Milk Full Narration: failed - Skyrim.Net not detected")
        EndIf
        Return
    EndIf

    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "milkFullNarrationCooldown", 60.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastMilkFullNarrationRealTime", -1.0)
    ; GetCurrentRealTime restarts with Skyrim, so discard a timestamp from an older session.
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        If diagnostic
            Int remaining = (cooldown - (now - last)) as Int
            Debug.Notification("Milk Full Narration: skipped - cooldown " + remaining + "s")
        EndIf
        Return
    EndIf

    ; Phase 2: choose restraint-aware prose, submit once, and commit cooldown
    ; only on success so a rejected API call can be retried later.
    String actorName = ResolveActorName(milkMaid, "The Milk Maid")
    String content = actorName + " is completely full. Her breasts are absurdly large and heavy, making ordinary movement increasingly ridiculous. She is near a boobgasm and enjoying the fullness. She can enjoy being full without needing immediate milking. React creatively with exaggerated, playful, suggestive humor. Don't simply restate the event."
    String restrainedContent = BuildRestrainedCapacityContent(milkMaid, 2)
    If restrainedContent != ""
        content = restrainedContent
    EndIf
    If diagnostic
        Debug.Notification("Milk Full Narration: sending general Milk Maid situation")
    EndIf
    Int result = SkyrimNetApi.DirectNarration(content, None, None)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastMilkFullNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        If diagnostic
            Debug.Notification("Milk Full Narration: accepted [0] | cooldown " + (cooldown as Int) + "s")
        EndIf
    Else
        If diagnostic
            Debug.Notification("Milk Full Narration: rejected [" + result + "]")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milk Full DirectNarration result " + result + " | cooldown " + cooldown + " | " + content)
EndFunction

; Makes at most one token-using narration request for a completed scan's half-full crossings.
Function NarrateMilkHalfFull(Actor milkMaid) Global
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableMilkHalfFullNarrationDiagnostic", 0) == 1
    If diagnostic
        Debug.Notification("Half-Full Narration: crossing detected")
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableMilkHalfFullNarration", 1) != 1
        If diagnostic
            Debug.Notification("Half-Full Narration: skipped - feature disabled")
        EndIf
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Half-Full Narration: failed - Skyrim.Net not detected")
        EndIf
        Return
    EndIf

    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "milkHalfFullNarrationCooldown", 60.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastMilkHalfFullNarrationRealTime", -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        If diagnostic
            Int remaining = (cooldown - (now - last)) as Int
            Debug.Notification("Half-Full Narration: skipped - cooldown " + remaining + "s")
        EndIf
        Return
    EndIf

    String actorName = ResolveActorName(milkMaid, "The Milk Maid")
    String content = actorName + " has become half full. Her breasts are noticeably larger, heavier, and bouncier, making everyday movement increasingly awkward. React creatively with playful, suggestive humor. Don't simply restate the event."
    String restrainedContent = BuildRestrainedCapacityContent(milkMaid, 1)
    If restrainedContent != ""
        content = restrainedContent
    EndIf
    If diagnostic
        Debug.Notification("Half-Full Narration: sending general Milk Maid situation")
    EndIf
    Int result = SkyrimNetApi.DirectNarration(content, None, None)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastMilkHalfFullNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        If diagnostic
            Debug.Notification("Half-Full Narration: accepted [0] | cooldown " + (cooldown as Int) + "s")
        EndIf
    ElseIf diagnostic
        Debug.Notification("Half-Full Narration: rejected [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Half-Full DirectNarration result " + result + " | cooldown " + cooldown + " | " + content)
EndFunction

; Requests one actor-specific narration after a verified NPC Milkmaid drink.
Function NarrateNPCMilkDrink(Actor drinker, Bool dialogueDrink = False) Global
    ; Dialogue and native potion paths converge here after their own duplicate
    ; suppression. This function owns only narration gates and cooldown state.
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableNPCDrinkNarrationDiagnostic", 0) == 1
    If drinker == None || drinker == Game.GetPlayer()
        Return
    EndIf

    String actorName = drinker.GetDisplayName()
    If actorName == ""
        actorName = "The Milk Maid"
    EndIf
    If diagnostic
        If dialogueDrink
            Debug.Notification("NPC Drink Narration: dialogue drink detected | " + actorName)
        Else
            Debug.Notification("NPC Drink Narration: drink detected | " + actorName)
        EndIf
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableNPCDrinkNarration", 1) != 1
        If diagnostic
            Debug.Notification("NPC Drink Narration: skipped - narration disabled")
        EndIf
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("NPC Drink Narration: skipped - Skyrim.Net unavailable")
        EndIf
        Return
    EndIf

    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "npcDrinkNarrationCooldown", 60.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastNPCDrinkNarrationRealTime", -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        If diagnostic
            Int remaining = (cooldown - (now - last)) as Int
            Debug.Notification("NPC Drink Narration: skipped - cooldown " + remaining + "s")
        EndIf
        Return
    EndIf

    String content = actorName + " just drank some milk. Her breasts are becoming heavier and more sensitive, and she seems pleased with the effects. React creatively with playful, suggestive humor. Don't simply restate the event."
    If MMEAlertsController.AreArmsRestrained(drinker)
        content = actorName + " just drank some milk despite having her arms restrained. Her breasts are becoming heavier and more sensitive, and she seems pleased with the effects. React creatively with playful, suggestive humor about the situation. Don't simply restate the event."
    EndIf
    Int result = SkyrimNetApi.DirectNarration(content, None, None)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastNPCDrinkNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        If diagnostic
            Debug.Notification("NPC Drink Narration: accepted [0] | cooldown " + (cooldown as Int) + "s")
        EndIf
    ElseIf diagnostic
        Debug.Notification("NPC Drink Narration: rejected [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] NPC drink DirectNarration result " + result + " | " + actorName + " | " + content)
EndFunction

; Requests an opt-in narration after a confirmed player milk drink.
Function NarratePlayerMilkDrink(Actor drinker, Form drinkItem) Global
    ; Chance is evaluated before the cooldown/API call. This keeps an ineligible
    ; random roll from consuming cooldown and preserves the opt-in default.
    If !IsExtensionsEnabled() || drinker != Game.GetPlayer() || drinkItem == None
        Return
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enablePlayerDrinkNarrationDiagnostic", 0) == 1
    If diagnostic
        Debug.Notification("Player Drink Narration: drink detected")
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enablePlayerDrinkNarration", 0) != 1
        If diagnostic
            Debug.Notification("Player Drink Narration: skipped - narration disabled")
        EndIf
        Return
    EndIf
    Int chance = JsonUtil.GetIntValue(settingsFile, "playerDrinkNarrationChance", 25)
    If chance < 0
        chance = 0
    ElseIf chance > 100
        chance = 100
    EndIf
    If chance == 0 || Utility.RandomInt(1, 100) > chance
        If diagnostic
            Debug.Notification("Player Drink Narration: skipped - chance " + chance + "%")
        EndIf
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Player Drink Narration: skipped - Skyrim.Net unavailable")
        EndIf
        Return
    EndIf

    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "playerDrinkNarrationCooldown", 60.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastPlayerDrinkNarrationRealTime", -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        If diagnostic
            Int remaining = (cooldown - (now - last)) as Int
            Debug.Notification("Player Drink Narration: skipped - cooldown " + remaining + "s")
        EndIf
        Return
    EndIf

    String drinkName = drinkItem.GetName()
    If drinkName == ""
        drinkName = "some milk"
    EndIf
    String content = "The player just drank " + drinkName + ". Their breasts are becoming heavier and more sensitive. React creatively with playful, suggestive humor. Don't simply restate the event."
    String restrainedContent = BuildRestrainedPlayerDrinkContent(drinker, drinkName)
    If restrainedContent != ""
        content = restrainedContent
    EndIf
    Int result = SkyrimNetApi.DirectNarration(content, None, None)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastPlayerDrinkNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        If diagnostic
            Debug.Notification("Player Drink Narration: accepted [0] | cooldown " + (cooldown as Int) + "s")
        EndIf
    ElseIf diagnostic
        Debug.Notification("Player Drink Narration: rejected [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Player drink DirectNarration result " + result + " | " + content)
EndFunction

; Requests one narration after the controller confirms a new Milk Maid transition.
Function NarrateMilkmaidCreated(Actor milkMaid) Global
    If !IsExtensionsEnabled() || milkMaid == None
        Return
    EndIf
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "enableMilkmaidCreatedNarrationDiagnostic", 0) == 1
    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "A Milk Maid"
    EndIf
    If diagnostic
        Debug.Notification("New Milk Maid Narration: creation detected | " + actorName)
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableMilkmaidCreatedNarration", 1) != 1
        If diagnostic
            Debug.Notification("New Milk Maid Narration: skipped - feature disabled")
        EndIf
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("New Milk Maid Narration: skipped - Skyrim.Net unavailable")
        EndIf
        Return
    EndIf

    Float cooldown = JsonUtil.GetFloatValue(settingsFile, "milkmaidCreatedNarrationCooldown", 60.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastMilkmaidCreatedNarrationRealTime", -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        If diagnostic
            Int remaining = (cooldown - (now - last)) as Int
            Debug.Notification("New Milk Maid Narration: skipped - cooldown " + remaining + "s")
        EndIf
        Return
    EndIf

    String content = actorName + " has just become a Milk Maid. Her body can now produce and store milk, and her breasts are becoming more sensitive. React creatively with playful, congratulatory, suggestive humor. Don't simply restate the event."
    If diagnostic
        Debug.Notification("New Milk Maid Narration: sending")
    EndIf
    Int result = SkyrimNetApi.DirectNarration(content, None, None)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastMilkmaidCreatedNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        If diagnostic
            Debug.Notification("New Milk Maid Narration: accepted [0] | cooldown " + (cooldown as Int) + "s")
        EndIf
    ElseIf diagnostic
        Debug.Notification("New Milk Maid Narration: rejected [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] New Milk Maid DirectNarration result " + result + " | " + content)
EndFunction

; Builds one line for the existing nearby scan. This never publishes or calls
; DirectNarration; SendNearbyArmorStatuses performs the single combined write.
String Function BuildNearbyArmorStatus(Actor candidate) Global
    ; Phase 1: require a real MME Milk Maid and inspect the currently worn slot-32
    ; form. This is called inside the existing 15-second nearby scan; do not add
    ; a second polling loop for armor status.
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNearbyMilkArmorStatus", 1) != 1 || !IsRealMMEMilkmaid(candidate)
        Return ""
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return ""
    EndIf
    Armor wornArmor = candidate.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "poll", candidate)
    String armorType = MMEArmorScript.GetArmorTypeLabel(armorClass)
    String matchSource = MMEArmorScript.GetArmorClassificationSource(milkController, wornArmor)
    String actorName = ResolveActorName(candidate, "The Milk Maid")
    String armorName = "<none>"
    If wornArmor != None
        armorName = wornArmor.GetName()
        If armorName == ""
            armorName = "<unnamed armor>"
        EndIf
    EndIf
    Bool diagnostic = MMEArmorScript.GetArmorDiagnostic()
    MMEArmorScript.ReportArmor(diagnostic, "nearby tracker checked | actor=" + actorName + " | armor=" + armorName + " | matched=" + matchSource + " | classification=" + armorType)
    If armorClass == 0
        Return ""
    EndIf

    ; Phase 2: return one line only. The controller concatenates all qualifying
    ; actors and SendNearbyArmorStatuses performs the single external write.
    String content = "[Milking Armor] " + actorName + " is wearing Milking Armor. Suction cups are attached to her nipples for milking."
    If armorClass == 2
        content = "[Living Armor] " + actorName + " is wearing Living Armor. Living tendrils are buried into her nipples, injecting stimulants and pleasurably draining milk."
    ElseIf armorClass == 3
        content = "[Living Parasite] " + actorName + " is wearing Living Parasite armor. Parasitic tendrils are buried into her nipples, injecting stimulants and pleasurably draining milk."
    EndIf
    MMEArmorScript.ReportArmor(diagnostic, "nearby tracker queued | actor=" + actorName + " | armor=" + armorName + " | matched=" + matchSource + " | classification=" + armorType)
    Return content
EndFunction

; Refreshes one stable Player-attached context event. Empty scans intentionally
; do nothing so the last 45-second event expires naturally.
Function SendNearbyArmorStatuses(Actor playerActor, String statuses, Int armorCount) Global
    ; Empty scans deliberately do not publish a clearing event. The previous
    ; 45-second context expires naturally, avoiding needless API traffic.
    If !IsExtensionsEnabled() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNearbyMilkArmorStatus", 1) != 1
        Return
    EndIf
    Bool diagnostic = MMEArmorScript.GetArmorDiagnostic()
    If armorCount <= 0 || statuses == ""
        MMEArmorScript.ReportArmor(diagnostic, "nearby tracker not refreshed: no nearby Milk Maid wears supported armor")
        Return
    EndIf
    If playerActor == None || !IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        MMEArmorScript.ReportArmor(diagnostic, "nearby tracker failed: Player or Skyrim.Net unavailable")
        Return
    EndIf

    ; One stable ID attached to Player replaces the previous combined snapshot.
    ; Never split this into per-NPC events and never call DirectNarration here.
    Int result = SkyrimNetApi.RegisterShortLivedEvent("nearby_milk_armor_status_player", "nearby_milk_armor_status", statuses, "{}", 45000, playerActor, None)
    MMEArmorScript.ReportArmor(diagnostic, "nearby tracker publish result=" + result + " | entries=" + armorCount + " | attached=Player | TTL=45s")
    Debug.Trace("[MMEAlert SkyrimNet] Nearby armor status result " + result + " | entries " + armorCount + " | " + statuses)
EndFunction

; Requests one AI-generated reaction to the semantic state selected by a normal
; game-time Thought. The rapid 15-second test never calls this function.
Function NarrateMilkMaidThought(Actor milkMaid, Bool halfPlus, Int armorClass) Global
    String settingsFile = "/MMEAlerts/Settings"
    Bool diagnostic = JsonUtil.GetIntValue(settingsFile, "traceMilkMaidThoughtsLogic", 0) == 1
    If !IsExtensionsEnabled() || JsonUtil.GetIntValue(settingsFile, "enableMilkMaidThoughtNarration", 1) != 1
        If diagnostic
            Debug.Notification("Thoughts narration: skipped - feature disabled")
        EndIf
        Return
    EndIf
    If milkMaid == None || armorClass < 0 || armorClass > 3
        If diagnostic
            Debug.Notification("Thoughts narration: skipped - invalid actor or armor class")
        EndIf
        Return
    EndIf
    If !IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Thoughts narration: skipped - Skyrim.Net unavailable or disabled")
        EndIf
        Return
    EndIf

    Float cooldown = JsonUtil.GetFloatValue("/MMEAlerts/SkyrimNet", "thoughtNarrationCooldownSeconds", 60.0)
    Float now = Utility.GetCurrentRealTime()
    Float last = JsonUtil.GetFloatValue(settingsFile, "lastMilkMaidThoughtNarrationRealTime", -1.0)
    If last > now
        last = -1.0
    EndIf
    If last >= 0.0 && now - last < cooldown
        If diagnostic
            Int remaining = (cooldown - (now - last)) as Int
            Debug.Notification("Thoughts narration: skipped - cooldown " + remaining + "s")
        EndIf
        Return
    EndIf

    String actorName = ResolveActorName(milkMaid, "The Milk Maid")
    String fullnessSituation = "is below half capacity, and her milk supply is beginning to build again"
    If halfPlus
        fullnessSituation = "is at least half full, with a noticeably heavy and growing milk supply"
    EndIf
    String armorSituation = "wearing no milking equipment"
    If armorClass == 1
        armorSituation = "wearing fitted milking equipment around her breasts"
    ElseIf armorClass == 2
        armorSituation = "wearing living armor whose tendrils eagerly tend her breasts"
    ElseIf armorClass == 3
        armorSituation = "wearing possessive parasite armor curled around her breasts"
    EndIf
    String content = actorName + " is an MME Milk Maid who " + fullnessSituation + ". She is " + armorSituation + ". React creatively with playful, humorous, and suggestive commentary. Do not simply restate the situation."
    If diagnostic
        Debug.Notification("Thoughts narration: sending direct narration")
    EndIf
    Int result = SkyrimNetApi.DirectNarration(content, None, None)
    If result == 0
        JsonUtil.SetFloatValue(settingsFile, "lastMilkMaidThoughtNarrationRealTime", now)
        JsonUtil.Save(settingsFile, False)
        If diagnostic
            Debug.Notification("Thoughts narration: accepted [0]")
        EndIf
    ElseIf diagnostic
        Debug.Notification("Thoughts narration: rejected [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milk Maid Thought DirectNarration result " + result + " | " + content)
EndFunction

; Publishes one replaceable five-minute summary from the existing capacity scan.
Function SendNearbyMilkStatuses(Actor playerActor, String statuses, Int scannedCount, Int milkmaidCount) Global
    ; This is the milk-state sibling of nearby armor context. It consumes the
    ; same controller scan and publishes one replaceable Player-attached summary.
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetStatusDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkStatuses", 1) != 1
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses failed - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; milk statuses skipped")
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses failed - bridge disabled in JSON")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milk statuses skipped; JSON bridge disabled")
        Return
    EndIf
    If playerActor == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses failed - player missing")
        EndIf
        Return
    EndIf
    If milkmaidCount <= 0 || statuses == ""
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses skipped - no nearby Milkmaids")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milk statuses skipped; no nearby Milkmaids")
        Return
    EndIf

    String content = "**Current milk levels:** " + statuses
    Float interval = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "skyrimNetStatusInterval", 15.0)
    Int ttlMs = (interval * 1000.0) as Int
    Debug.Trace("[MMEAlert SkyrimNet] Calling milk_statuses_player | interval " + interval + " | TTL " + ttlMs + " | " + content)
    Int result = SkyrimNetApi.RegisterShortLivedEvent("milk_statuses_player", "milk_statuses", content, "{}", ttlMs, playerActor, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected milk statuses (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Status: accepted | " + milkmaidCount + " Milkmaids | " + interval + "s")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent timed milk statuses event: " + content)
    EndIf
EndFunction

; Records a confirmed false-to-true Milkmaid transition in SkyrimNet history.
Function SendMilkmaidCreated(Actor milkMaid) Global
    ; Creation is persistent history rather than temporary context. Validate the
    ; schema and JSON-escape rendered content before calling RegisterEvent.
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetCreationDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkmaidCreated", 1) != 1
        Return
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created handler reached")
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; Milkmaid creation event skipped")
        Return
    EndIf
    If milkMaid == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - actor missing")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid creation event skipped; actor was None")
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - bridge disabled in JSON")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid creation event skipped; JSON bridge disabled")
        Return
    EndIf

    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "The actor"
    EndIf
    String defaultMessage = "{actor} has become a Milk Maid! Her breasts now feel pleasantly heavy, full, and faintly thrilling."
    String template = JsonUtil.GetStringValue(settingsFile, "milkmaidCreatedMessage", defaultMessage)
    If template == ""
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - message empty")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid creation event skipped; message was empty")
        Return
    EndIf
    String content = RenderMessage(template, actorName)
    EnsureMilkmaidCreatedSchema(diagnostic)
    String actorUuid = SkyrimNetApi.GetEntityUUID(milkMaid)
    If actorUuid == ""
        actorUuid = "<empty>"
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created | " + actorName + " | UUID " + actorUuid)
        Debug.Notification("Skyrim.Net Diagnostic payload: " + content)
    EndIf
    String eventData = "{\"content\":\"" + EscapeJsonString(content) + "\"}"
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic event data: " + eventData)
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Calling persistent milkmaid_created | actor " + actorName + " | UUID " + actorUuid + " | " + eventData)
    Int result = SkyrimNetApi.RegisterEvent("milkmaid_created", eventData, milkMaid, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: persistent event rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected milkmaid_created for " + actorName + " (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: persistent event accepted [0]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent persistent milkmaid_created event: " + content)
    EndIf
EndFunction

; Escapes user-facing actor names before embedding them in structured event JSON.
String Function EscapeJsonString(String value) Global
    value = ReplaceAll(value, "\\", "\\\\")
    value = ReplaceAll(value, "\"", "\\\"")
    Return value
EndFunction

String Function ReplaceAll(String value, String token, String replacement) Global
    Int tokenLength = StringUtil.GetLength(token)
    If tokenLength <= 0
        Return value
    EndIf
    String result = ""
    Int start = 0
    Int found = StringUtil.Find(value, token, start)
    While found >= 0
        result = result + StringUtil.Substring(value, start, found - start) + replacement
        start = found + tokenLength
        found = StringUtil.Find(value, token, start)
    EndWhile
    Return result + StringUtil.Substring(value, start)
EndFunction

; Gives SkyrimNet a clean body format instead of its unknown-type [event_type] fallback.
Function EnsureMilkmaidCreatedSchema(Bool diagnostic) Global
    ; Schema registration is idempotent and performed lazily so Skyrim.Net load
    ; order cannot make quest initialization permanently miss the event type.
    If SkyrimNetApi.IsEventTypeRegistered("milkmaid_created")
        Return
    EndIf
    String fieldsJson = "[{\"name\":\"content\",\"type\":0,\"required\":true,\"description\":\"Milkmaid creation description\"}]"
    String formatsJson = "{\"recent_events\":\"{{content}}\",\"raw\":\"{{content}}\",\"compact\":\"{{content}}\",\"verbose\":\"{{content}}\"}"
    Int result = SkyrimNetApi.RegisterEventSchema("milkmaid_created", "milkmaid created", "An actor became an MME Milkmaid.", fieldsJson, formatsJson, False, 0)
    If diagnostic
        If result == 0
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid schema registered [0]")
        Else
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid schema rejected [" + result + "]")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] milkmaid_created schema result " + result)
EndFunction

; Publishes the player's latest drink into scene context for ninety seconds.
Function SendMilkDrink(Actor drinker, Form drinkItem) Global
    ; Build one bounded Player context event after the drink pipeline confirms a
    ; supported item. Restraint changes prose only; it never changes milk effects.
    If !IsExtensionsEnabled()
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetDrinkDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkDrinks", 1) != 1
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; drink event skipped")
        Return
    EndIf
    If drinker == None || drinkItem == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: missing drinker or item")
        EndIf
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: bridge disabled in JSON")
        EndIf
        Return
    EndIf

    String itemName = drinkItem.GetName()
    If itemName == ""
        itemName = "an unnamed milk"
    EndIf
    String actorName = drinker.GetDisplayName()
    If actorName == ""
        actorName = "The player"
    EndIf

    String template = JsonUtil.GetStringValue(settingsFile, "drinkMessage", "{actor} drank {item}.")
    String content = RenderToken(template, "{actor}", actorName)
    content = RenderToken(content, "{item}", itemName)
    String restrainedContent = BuildRestrainedPlayerDrinkContent(drinker, itemName)
    If restrainedContent != ""
        content = restrainedContent
    EndIf
    If diagnostic
        String buildVersion = SkyrimNetApi.GetBuildVersion()
        String buildType = SkyrimNetApi.GetBuildType()
        String actorUuid = SkyrimNetApi.GetEntityUUID(drinker)
        If actorUuid == ""
            actorUuid = "<empty>"
        EndIf
        Debug.Notification("Skyrim.Net Diagnostic: v" + buildVersion + " " + buildType + " | player UUID " + actorUuid)
        Debug.Notification("Skyrim.Net Diagnostic payload: " + content)
    EndIf
    Int ttlMs = JsonUtil.GetIntValue(settingsFile, "drinkTtlMs", 90000)
    Int result = SkyrimNetApi.RegisterShortLivedEvent("milk_drink_player", "milk_drink", content, "{}", ttlMs, drinker, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: short-lived event rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected milk drink event for " + actorName + " (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: short-lived event accepted [0]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent 90-second milk drink event: " + content)
    EndIf
EndFunction

Function SendMilkingEvent(Actor milkMaid, String messageKey) Global
    ; Start/end share one implementation but retain distinct stable event IDs.
    ; Validate all gates before rendering configurable templates or calling API.
    If !IsExtensionsEnabled()
        Return
    EndIf
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkingDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkingEvents", 1) != 1
        Return
    EndIf
    String eventId = "milking_start"
    String eventType = "milking_start"
    If messageKey == "endMessage"
        eventId = "milking_end"
        eventType = "milking_end"
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " handler reached")
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; milking event skipped")
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    If milkMaid == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - actor missing")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] " + eventType + " skipped; actor was None")
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - bridge disabled in JSON")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] " + eventType + " skipped; JSON bridge disabled")
        Return
    EndIf

    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "The Milk Maid"
    EndIf

    String defaultMessage = "{actor} has started milking herself, eagerly releasing the pressure."
    If messageKey == "endMessage"
        defaultMessage = "{actor} finished milking and is empty again, deeply relieved and completely satisfied."
    EndIf
    String template = JsonUtil.GetStringValue(settingsFile, messageKey, defaultMessage)
    If template == ""
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - message empty")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Empty message for " + messageKey + "; event skipped")
        Return
    EndIf

    String content = RenderMessage(template, actorName)
    Int ttlMs = JsonUtil.GetIntValue(settingsFile, "milkingTtlMs", 60000)
    String actorUuid = SkyrimNetApi.GetEntityUUID(milkMaid)
    If actorUuid == ""
        actorUuid = "<empty>"
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " | " + actorName + " | UUID " + actorUuid + " | TTL " + ttlMs)
        Debug.Notification("Skyrim.Net Diagnostic payload: " + content)
        Debug.Notification("Skyrim.Net Diagnostic: calling short-lived API")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Calling " + eventType + " | actor " + actorName + " | UUID " + actorUuid + " | TTL " + ttlMs + " | " + content)
    Int result = SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, content, "{}", ttlMs, milkMaid, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected " + messageKey + " for " + actorName + " (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " accepted [0]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent 60-second " + eventType + " event: " + content)
    EndIf
EndFunction

; Returns an empty string unless MME's optional DD bridge positively reports
; armbinder/yoke arm restraint for this exact crossing actor.
String Function BuildRestrainedCapacityContent(Actor milkMaid, Int crossing) Global
    If milkMaid == None || !MMEAlertsController.AreArmsRestrained(milkMaid)
        Return ""
    EndIf
    String actorName = ResolveActorName(milkMaid, "The Milk Maid")
    If crossing == 2
        Return actorName + " is completely full. Her breasts are absurdly large and heavy, and her restrained arms make supporting or adjusting them difficult. She is near a boobgasm and seems to be enjoying herself. React creatively with exaggerated, playful, suggestive humor. Don't simply restate the event."
    ElseIf crossing == 1
        Return actorName + " has become half full. Her breasts are noticeably larger, heavier, and bouncier, while her restrained arms make dealing with them awkward. React creatively with playful, suggestive humor. Don't simply restate the event."
    EndIf
    Return ""
EndFunction

; Builds the actor-specific periodic status and performs exactly one restraint
; selection before returning either the existing normal text or its exact DD variant.
String Function BuildMilkStatus(Actor milkMaid, Int milkState) Global
    If milkMaid == None
        Return ""
    EndIf
    String actorName = ResolveActorName(milkMaid, "This Milk Maid")
    If MMEAlertsController.AreArmsRestrained(milkMaid)
        If milkState == 2
            Return actorName + " is completely full, deliciously heavy and savoring the pleasure near a boobgasm. Her arms are restrained, leaving her unable to freely touch or relieve her milk-heavy breasts, turning the fullness into prolonged erotic teasing and edging that she enjoys."
        ElseIf milkState == 1
            Return actorName + " is over half full, feeling noticeably heavier and warmer. The growing weight makes her instinctively want to touch and handle her breasts, but her restrained arms cannot reach them, making the denied contact even more teasing and pleasurable."
        EndIf
        Return actorName + " is less than half full, feeling pleasantly tingly. Her mind keeps wandering to the growing sensitivity of her breasts, but her restrained arms cannot reach them, turning the temptation into playful erotic teasing."
    EndIf
    If milkState == 2
        Return actorName + " is completely full, deliciously heavy and savoring the pleasure near a boobgasm."
    ElseIf milkState == 1
        Return actorName + " is over half full, feeling heavier and warm."
    EndIf
    Return actorName + " is less than half full, feeling pleasantly tingly."
EndFunction

String Function BuildRestrainedPlayerDrinkContent(Actor playerActor, String drinkName) Global
    If playerActor == None || !MMEAlertsController.AreArmsRestrained(playerActor)
        Return ""
    EndIf
    Return "The player just drank " + drinkName + " despite having their arms restrained. Their breasts are becoming heavier and more sensitive. React creatively with playful, suggestive humor about the situation. Don't simply restate the event."
EndFunction

String Function ResolveActorName(Actor actorRef, String fallbackName) Global
    If actorRef == None
        Return fallbackName
    EndIf
    String actorName = actorRef.GetDisplayName()
    If actorName == ""
        ActorBase baseInfo = actorRef.GetLeveledActorBase()
        If baseInfo != None
            actorName = baseInfo.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = fallbackName
    EndIf
    Return actorName
EndFunction

String Function RenderMessage(String template, String actorName) Global
    Return RenderToken(template, "{actor}", actorName)
EndFunction

String Function RenderToken(String template, String token, String value) Global
    Int tokenIndex = StringUtil.Find(template, token)
    If tokenIndex < 0
        Return template
    EndIf

    String beforeToken = ""
    If tokenIndex > 0
        beforeToken = StringUtil.Substring(template, 0, tokenIndex)
    EndIf
    String afterToken = StringUtil.Substring(template, tokenIndex + StringUtil.GetLength(token))
    Return beforeToken + value + afterToken
EndFunction
