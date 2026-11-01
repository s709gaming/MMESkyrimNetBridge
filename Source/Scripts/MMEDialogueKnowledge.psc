Scriptname MMEDialogueKnowledge Hidden

; Request-local text composition only. No Skyrim.Net import, actor membership
; writes, temporary speaker flags, timers, JSON writes or persisted lore copies.
String Function ForRequest(Actor speaker, String route) Global
    String milkLore = MMENarrationText.GetRaw("Lore", "milk_lore")
    ; The existing editable entry still requires {actor}. In shared background
    ; it names an example, never an ordinary NPC who happens to be speaking.
    String maidLore = MMENarrationText.Text("Lore", "milkmaid_lore", "actor", "An example Milk Maid")
    If MMENarrationText.IsBlank(milkLore) || MMENarrationText.IsBlank(maidLore)
        AlarmOnce("compose shared knowledge", speaker, "required lore was empty after normal default resolution")
        Return ""
    EndIf
    If StorageUtil.GetIntValue(None, "MMEExtensions.DialogueKnowledge.Alarm.compose shared knowledge", 0) != 0
        StorageUtil.SetIntValue(None, "MMEExtensions.DialogueKnowledge.Alarm.compose shared knowledge", 0)
    EndIf
    String output = "[MME shared knowledge]\nThe following is background about milk and Milk Maids. Use it to interpret the situation and guide the response, consistent with the speaker's own identity and personality. Do not read these notes aloud. The example Milk Maid described below is not the current speaker. This background does not make the speaker or listener a Milk Maid; actual identity and current game state remain authoritative.\n\n" + milkLore + "\n\n" + maidLore + "\n[End MME shared knowledge]"
    MMELog.MasterDiagnostic("[MME Dialogue Knowledge] compose | route=" + route + " | speaker=" + speaker + " | automatic speaker=" + (speaker == None) + " | characters=" + StringUtil.GetLength(output) + " | entries=Lore.milk_lore,Lore.milkmaid_lore")
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
