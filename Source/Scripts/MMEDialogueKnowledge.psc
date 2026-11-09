Scriptname MMEDialogueKnowledge Hidden

; Request-local text composition only. No Skyrim.Net import, actor membership
; writes, temporary speaker flags, timers, JSON writes or persisted lore copies.
String Function ForRequest(Actor speaker, String route) Global
    MMEActorPromptState.Refresh(speaker)
    ; General lore belongs to Skyrim.Net knowledge packs, not request text.
    ; Actor identity remains in decorators; player lore is the user's choice.
    String guidance = MMENarrationText.GetRaw("Lore", "shared_guidance")
    If MMENarrationText.IsBlank(guidance)
        AlarmOnce("compose shared knowledge", speaker, "shared narration instructions were empty after normal default resolution")
        Return ""
    EndIf
    If StorageUtil.GetIntValue(None, "MMEExtensions.DialogueKnowledge.Alarm.compose shared knowledge", 0) != 0
        StorageUtil.SetIntValue(None, "MMEExtensions.DialogueKnowledge.Alarm.compose shared knowledge", 0)
    EndIf
    String output = "[MME shared knowledge]\nInstructions; do not read aloud. Actual identity and current game state remain authoritative.\n\n" + "Shared Narration Guidance:\n" + guidance + "\n[End MME shared knowledge]"
    MMELog.MasterDiagnostic("[MME Dialogue Knowledge] compose | route=" + route + " | speaker=" + speaker + " | automatic speaker=" + (speaker == None) + " | characters=" + StringUtil.GetLength(output) + " | entry=Lore.shared_guidance | general lore=Skyrim.Net knowledge pack")
    Return output
EndFunction

String Function Append(String content, Actor speaker) Global
    ; Preserve DirectNarration's empty-content behavior and avoid duplicate blocks.
    If MMENarrationText.IsBlank(content)
        MMELog.MasterDiagnostic("[MME Dialogue Knowledge] skip | speaker=" + speaker + " | reason=empty narration")
        Return content
    EndIf
    If StringUtil.Find(content, "[MME shared knowledge]") >= 0
        MMELog.MasterDiagnostic("[MME Dialogue Knowledge] skip | speaker=" + speaker + " | reason=knowledge already included")
        Return content
    EndIf
    String knowledge = ForRequest(speaker, "DirectNarration")
    If knowledge == ""
        Return content
    EndIf
    Return content + "\n\n" + knowledge
EndFunction

Function AlarmOnce(String operation, Actor speaker, String reason) Global
    String alarmKey = "MMEExtensions.DialogueKnowledge.Alarm." + operation
    If StorageUtil.GetIntValue(None, alarmKey, 0) == 0
        StorageUtil.SetIntValue(None, alarmKey, 1)
        MMELog.Alarm("[MME Dialogue Knowledge] failure | operation=" + operation + " | speaker=" + speaker + " | reason=" + reason)
    EndIf
EndFunction
