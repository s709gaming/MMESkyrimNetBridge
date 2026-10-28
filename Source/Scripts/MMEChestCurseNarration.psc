Scriptname MMEChestCurseNarration Hidden

; Explicit chest-only publication boundary. No gameplay or fullness scheduling.
Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Chest Curse Narration] " + detail)
EndFunction

Function AlarmOnce(Actor target, String reason) Global
    String alarmKey = "MMEExtensions.ChestCurseNarration.Alarm." + reason
    Float now = Utility.GetCurrentRealTime()
    Float prior = StorageUtil.GetFloatValue(target, alarmKey, -100.0)
    If now < prior || now - prior >= 60.0
        StorageUtil.SetFloatValue(target, alarmKey, now)
        MMELog.Alarm("[MME Chest Curse Narration] FAILURE | operation=publish/playback | actor=" + target + " | reason=" + reason)
    EndIf
EndFunction

String Function BlockReason(Actor target) Global
    String settings = "/MMEAlerts/Settings"
    If !MMEAlertsSkyrimNet.IsExtensionsEnabled()
        Return "Extensions disabled"
    EndIf
    If JsonUtil.GetIntValue(settings, "enableChestCurseNarration", 1) != 1
        Return "chest narration disabled"
    EndIf
    If JsonUtil.GetIntValue(settings, "enableForcedMilkMaidNarration", 1) != 1
        Return "shared narration master disabled"
    EndIf
    If JsonUtil.GetIntValue(settings, "enableMilkMaidCurseTrap", 1) != 1
        Return "chest curse feature disabled"
    EndIf
    If !MMEAlertsSkyrimNet.IsAvailable() || SKSE.GetPluginVersion("SkyrimNet") < 0 || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        Return "Skyrim.Net absent or disabled"
    EndIf
    If target == None || target.IsDeleted() || target.IsChild() || target.IsDead() || target.IsDisabled() || !target.Is3DLoaded()
        Return "affected actor unavailable"
    EndIf
    Return ""
EndFunction

Function Publish(Actor target, Bool converted, String chestKind, String chestIdentity, Float milkAdded) Global
    Trace("entry | actor=" + target + " | chest=" + chestIdentity + " | kind=" + chestKind + " | converted=" + converted + " | immediate delta=" + milkAdded)
    String reason = BlockReason(target)
    If reason != ""
        Trace("skip | actor=" + target + " | reason=" + reason)
        Return
    EndIf
    If chestIdentity == "" || (chestKind != "boss" && chestKind != "regular")
        AlarmOnce(target, "missing or invalid chest source context")
        Return
    EndIf
    String chestText = "treasure chest"
    If chestKind == "boss"
        chestText = "boss treasure chest"
    EndIf
    String outcome = "She has just become a Milk Maid: her ability to produce milk was newly awakened by the chest's enchantment. This is a conversion, not a measured milk-reserve increase."
    String amountText = "not applicable: milk production newly awakened"
    String outcomeKind = "conversion"
    If !converted
        If milkAdded <= 0.0 || milkAdded != milkAdded || milkAdded > 1000000000.0
            AlarmOnce(target, "no valid measured milk increase for chest surge narration")
            Return
        EndIf
        outcomeKind = "surge"
        amountText = milkAdded as String
        outcome = "She was already a Milk Maid. The chest's enchantment has added milk to her existing reserves, possibly beyond normal capacity. She has not become a Milk Maid again."
    EndIf
    String actorName = MMEAlertsSkyrimNet.ResolveActorName(target, "The affected Milk Maid")
    String prompt = MMENarrationText.Text("MilkMaidCreation", "narrate_chest_milk_maid_curse_1", "actor", actorName, "outcome", outcome, "chest_kind", chestText, "milk_added", amountText)
    Trace("selected route | actor=" + target + " | source=treasure_chest | outcome=" + outcomeKind + " | route=narrate_chest_milk_maid_curse_1")
    If target == Game.GetPlayer()
        MMEAlertsController bridge = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
        If bridge == None
            AlarmOnce(target, "required player narration callback unavailable")
            Return
        EndIf
        String contextJson = "{\"playerInstructions\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(MMENarrationText.Text("Common", "player_instructions", "actor", actorName)) + "\",\"speaker\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(actorName) + "\",\"source\":\"treasure_chest\",\"outcome\":\"" + outcomeKind + "\",\"situation\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(prompt) + "\"}"
        Int queued = SkyrimNetApi.SendCustomPromptToLLM("mme_wearer_self_comment", "dialogue", contextJson, bridge, "MMEAlertsController", "OnChestCursePlayerLine")
        Trace("player request result | actor=" + target + " | chest=" + chestIdentity + " | result=" + queued + " (1=queued); no NPC fallback")
        Return
    EndIf
    Int result = SkyrimNetApi.DirectNarration(prompt, target, Game.GetPlayer())
    Trace("NPC request result | speaker=" + target + " | chest=" + chestIdentity + " | result=" + result + " (0=accepted)")
EndFunction

Function PlayPlayerLine(String response, Int success) Global
    Actor target = Game.GetPlayer()
    String reason = BlockReason(target)
    If reason != ""
        Trace("player playback cancelled | reason=" + reason)
        Return
    EndIf
    If success != 1 || MMETextPool.IsBlank(response)
        Trace("player generation failed or blank | result=" + success + "; no NPC fallback")
        Return
    EndIf
    Int result = SkyrimNetApi.TriggerPlayerTTS(response)
    Trace("player TTS result | actor=" + target + " | result=" + result + " (0=accepted)")
EndFunction
