; ARCHIVED: conversational actions are intentionally excluded from release builds.
; Skyrim.Net/LLM world-context choices made both experimental actions unreliable.
Scriptname MMESkyrimNetVoiceControls Hidden

String SettingsFile = "/MMEAlerts/Settings"

; Registers the optional conversational hand-milking action.
Function RegisterVoiceMilkingAction() Global
    If !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilking", 0) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("StartMilkingSelf", "Use only when the player clearly asks you, an MME Milkmaid, to milk yourself. This means extracting your own breast milk; it does not mean drinking or receiving a milk item.", "MMESkyrimNetVoiceControls", "VoiceMilkingIsEligible", "MMESkyrimNetVoiceControls", "VoiceMilkingExecute", "", "PAPYRUS", 1, "")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilkingDiagnostic", 0) == 1
        Debug.Notification("Voice Milking: action registration returned [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Voice Milking action registration result " + result)
EndFunction

; Registers the opt-in action that reuses the tested NPC dialogue pipeline.
Function RegisterGiveMilkAction() Global
    If !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterAction("GiveMilkToMilkmaid", "Use when the player naturally offers milk or Lactacid to the current MME Milkmaid. Give and consume one supported milk item from the player's inventory. Never use on a non-Milkmaid.", "MMESkyrimNetVoiceControls", "VoiceGiveMilkIsEligible", "MMESkyrimNetVoiceControls", "VoiceGiveMilkExecute", "", "PAPYRUS", 1, "")
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
        Debug.Notification("Give Milk Voice: registration returned [" + result + "]")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Give Milk action registration result " + result)
EndFunction

; SkyrimNet checks each conversational actor before exposing the action.
Bool Function VoiceGiveMilkIsEligible(Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return False
    EndIf
    If candidate == None || candidate == Game.GetPlayer() || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If diagnostic
            Debug.Notification("Give Milk Voice: rejected - invalid target")
        EndIf
        Return False
    EndIf
    String actorName = candidate.GetDisplayName()
    If !MMEAlertsSkyrimNet.IsRealMMEMilkmaid(candidate)
        If diagnostic
            Debug.Notification("Give Milk Voice: " + actorName + " rejected - not a Milkmaid")
        EndIf
        Return False
    EndIf
    If diagnostic
        Debug.Notification("Give Milk Voice: " + actorName + " eligible")
    EndIf
    Return True
EndFunction

; Revalidates and delegates inventory selection, transfer, and effects to MMENPCDialog.
Function VoiceGiveMilkExecute(Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilkDiagnostic", 1) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceGiveMilk", 0) != 1
        Return
    EndIf
    If diagnostic
        Debug.Notification("Give Milk Voice: action attempted")
    EndIf
    Bool success = MMENPCDialog.GiveMilkToTarget(candidate, diagnostic)
    If diagnostic
        If success
            Debug.Notification("Give Milk Voice: item successfully processed")
        Else
            Debug.Notification("Give Milk Voice: failed; see preceding reason")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Give Milk action completed | success=" + success)
EndFunction

; SkyrimNet calls this while preparing actions for each conversational actor.
Bool Function VoiceMilkingIsEligible(Actor candidate) Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilkingDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilking", 0) != 1
        Return False
    EndIf
    If candidate == None || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        Return False
    EndIf
    String actorName = candidate.GetDisplayName()
    If !MMEAlertsSkyrimNet.IsRealMMEMilkmaid(candidate)
        If diagnostic
            Debug.Notification("Voice Milking: " + actorName + " rejected - not an MME Milkmaid")
        EndIf
        Return False
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEAlerts.IsMilking", 0) == 1
        If diagnostic
            Debug.Notification("Voice Milking: " + actorName + " rejected - already milking")
        EndIf
        Return False
    EndIf
    If diagnostic
        Debug.Notification("Voice Milking: " + actorName + " eligible")
    EndIf
    Return True
EndFunction

; Revalidates the selected actor, then lets MME enforce milk and equipment rules.
Function VoiceMilkingExecute(Actor candidate) Global
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilking", 0) != 1
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If candidate == None || milkController == None || milkController.MilkMaid.Find(candidate) == -1
        If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilkingDiagnostic", 0) == 1
            Debug.Notification("Voice Milking: execution blocked - invalid target")
        EndIf
        Return
    EndIf
    String actorName = candidate.GetDisplayName()
    If candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilkingDiagnostic", 0) == 1
            Debug.Notification("Voice Milking: execution blocked - " + actorName + " unavailable")
        EndIf
        Return
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEAlerts.IsMilking", 0) == 1
        If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilkingDiagnostic", 0) == 1
            Debug.Notification("Voice Milking: execution blocked - " + actorName + " already milking")
        EndIf
        Return
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableVoiceMilkingDiagnostic", 0) == 1
        Debug.Notification("Voice Milking: selected " + actorName + " - MME Milk Self cast requested")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Voice Milking casting MME MilkSelf on " + actorName)
    milkController.MilkSelf.Cast(candidate)
EndFunction
