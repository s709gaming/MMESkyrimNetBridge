Scriptname MMEActorPromptState Hidden

; Actor-local prompt data only. No actor scan, timers, MME writes or LLM calls.
; Native papyrus_util reads the milk floats again at actual template render time.
String Function GetActorState(Actor target) Global
    If target == None || target.IsDead() || target.IsDisabled()
        Return "{\"enabled\":false}"
    EndIf
    If !MMEAlertsSkyrimNet.IsExtensionsEnabled() || !MMEAlertsSkyrimNet.IsAvailable()
        Return "{\"enabled\":false}"
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        Return "{\"enabled\":false}"
    EndIf
    Bool milkEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkStatuses", 1) == 1
    Bool armorEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNearbyMilkArmorStatus", 1) == 1
    If !milkEnabled && !armorEnabled
        Return "{\"enabled\":false}"
    EndIf
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milk == None || !MMEArmorScript.IsValidMilkMaid(target, milk)
        Return "{\"enabled\":false}"
    EndIf
    String armorText = ""
    If armorEnabled
        Armor worn = target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
        Int armorClass = MMEArmorScript.ClassifyArmorQuiet(milk, worn, target)
        If armorClass == 1
            armorText = "Wearing milking armor."
        ElseIf armorClass == 2
            armorText = "Wearing living armor."
        ElseIf armorClass == 3
            armorText = "Wearing parasite armor."
        ElseIf armorClass == 4
            If MMECustomArmorRegistry.GetDwemerPresentationProfile(worn) == "deviousSuit"
                armorText = "Wearing Dwemer milking armor."
            Else
                armorText = "Wearing armor with a Dwemer milking attachment; do not describe a full-body Dwemer suit."
            EndIf
        ElseIf worn == None
            armorText = "No body armor is equipped. Other clothing or equipment may still be worn."
        Else
            armorText = "Wearing ordinary or unrecognized body armor; no supported milking armor classification."
        EndIf
        If worn != None
            armorText += " Item: " + worn.GetName() + "."
        EndIf
    EndIf
    String leakText = ""
    If milkEnabled
        If !target.Is3DLoaded() || MMEMilkLeakAPI.Manager() == None
            leakText = "Leaking status unavailable; do not assume leaking from fullness."
        Else
            Int leakSource = MMEMilkLeakAPI.GetLeakSource(target)
            If leakSource == 1
                leakText = "Currently leaking milk: a tracked milk-leak effect is active."
            ElseIf leakSource == 2
                leakText = "Currently leaking milk: an external Oninus spray effect is equipped."
            Else
                leakText = "No tracked milk-leak effect is active. Untracked third-party effects are unknown."
            EndIf
        EndIf
    EndIf
    String name = MMEAlertsSkyrimNet.ResolveActorName(target, "This Milk Maid")
    String result = "{\"enabled\":true,\"milkEnabled\":" + BoolJson(milkEnabled) + ",\"armorEnabled\":" + BoolJson(armorEnabled) + ",\"name\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(name) + "\",\"armor\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(armorText) + "\",\"leak\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(leakText) + "\"}"
    TraceSnapshot(target, result, milkEnabled)
    Return result
EndFunction

String Function BoolJson(Bool value) Global
    If value
        Return "true"
    EndIf
    Return "false"
EndFunction

; Unknown is not empty. Do not invoke original getters that initialize missing milkState.
Int Function GetFullnessState(Actor target) Global
    If target == None || !StorageUtil.HasFloatValue(target, "MME.MilkMaid.MilkCount") || !StorageUtil.HasFloatValue(target, "MME.MilkMaid.MilkMaximum")
        Return -1
    EndIf
    Float current = StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkCount")
    Float maximum = StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkMaximum")
    Int milkState = ClassifyFullness(current, maximum)
    If milkState < 0
        If StorageUtil.GetIntValue(target, "MME.Prompt.InvalidMilkReported", 0) == 0
            StorageUtil.SetIntValue(target, "MME.Prompt.InvalidMilkReported", 1)
            MMELog.Alarm("[MME Actor Prompt] SMOKE ALARM | operation=read milk milkState | actor=" + target + " | invalid stored current/max=" + current + "/" + maximum)
        EndIf
    ElseIf StorageUtil.GetIntValue(target, "MME.Prompt.InvalidMilkReported", 0) == 1
        StorageUtil.UnsetIntValue(target, "MME.Prompt.InvalidMilkReported")
    EndIf
    Return milkState
EndFunction

; -1 unknown/invalid; 0 empty; 1 below half; 2 half; 3 full; 4 over capacity.
Int Function ClassifyFullness(Float current, Float maximum) Global
    If current < 0.0 || maximum <= 0.0
        Return -1
    ElseIf current == 0.0
        Return 0
    ElseIf current > maximum
        Return 4
    ElseIf current == maximum
        Return 3
    ElseIf current >= maximum * 0.5
        Return 2
    EndIf
    Return 1
EndFunction

Function TraceSnapshot(Actor target, String result, Bool milkEnabled) Global
    ; Only owned diagnostic keys are written, never MME/framework milkState.
    Int milkState = -1
    If milkEnabled
        milkState = GetFullnessState(target)
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePapyrusTrace", 0) != 1
        Return
    EndIf
    String signature = result
    If milkEnabled
        signature += " | milk=" + StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkCount", -1.0) + "/" + StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkMaximum", -1.0) + " | milkState=" + milkState
    EndIf
    If StorageUtil.GetStringValue(target, "MME.Prompt.LastDiagnostic", "") != signature
        StorageUtil.SetStringValue(target, "MME.Prompt.LastDiagnostic", signature)
        MMELog.MasterDiagnostic("[MME Actor Prompt] actor snapshot | actor=" + target + " | " + signature)
    Else
        MMELog.Diagnostic("[MME Actor Prompt] render complete | actor=" + target + " | unchanged snapshot")
    EndIf
EndFunction

Function ReportRegistration(Int result) Global
    ; Positive status may represent repeated registration, not a verified failure.
    If result < 0
        If StorageUtil.GetIntValue(None, "MME.Prompt.RegistrationFailure", 0) == 0
            StorageUtil.SetIntValue(None, "MME.Prompt.RegistrationFailure", 1)
            MMELog.Alarm("[MME Actor Prompt] SMOKE ALARM | operation=register decorator | actor=N/A | mme_actor_milk_state result=" + result)
        EndIf
    Else
        StorageUtil.UnsetIntValue(None, "MME.Prompt.RegistrationFailure")
    EndIf
    MMELog.MasterDiagnostic("[MME Actor Prompt] decorator registration | result=" + result + " | periodic AI status events retired")
EndFunction
