Scriptname MMEActorPromptState Hidden

; Actor-local prompt data; existing scans/events supply updates, with one load bootstrap.
; No independent polling, MME writes, inventory changes or LLM calls.
; Native papyrus_util reads the milk floats again at actual template render time.
; Decorator metadata: two parts, fullness + recognized equipment; third-person actor name.
; Natural-language AI context, not notifications. Target 90 characters before name substitution.
; Equipped-only prose promises sensations; never establishes active teasing or extraction.
String Function GetActorState(Actor target) Global
    MMEAlertsSkyrimNet.TracePromptCallback("GetActorState", target, "entry")
    If target == None || target.IsDead() || target.IsDisabled()
        Return MMEAlertsSkyrimNet.PromptCallbackReturn("GetActorState", target, "{\"enabled\":false}", "missing, dead, or disabled actor")
    EndIf
    If !MMEAlertsSkyrimNet.IsExtensionsEnabled() || !MMEAlertsSkyrimNet.IsAvailable()
        Return MMEAlertsSkyrimNet.PromptCallbackReturn("GetActorState", target, "{\"enabled\":false}", "Extensions disabled or Skyrim.Net absent")
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        Return MMEAlertsSkyrimNet.PromptCallbackReturn("GetActorState", target, "{\"enabled\":false}", "Skyrim.Net integration disabled")
    EndIf
    Bool milkEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkStatuses", 1) == 1
    Bool armorEnabled = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNearbyMilkArmorStatus", 1) == 1
    If !milkEnabled && !armorEnabled
        Return MMEAlertsSkyrimNet.PromptCallbackReturn("GetActorState", target, "{\"enabled\":false}", "milk and armor status both disabled")
    EndIf
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milk == None || !MMEArmorScript.IsValidMilkMaid(target, milk)
        Return MMEAlertsSkyrimNet.PromptCallbackReturn("GetActorState", target, "{\"enabled\":false}", "missing MilkQUEST or invalid Milk Maid")
    EndIf
    String name = MMEAlertsSkyrimNet.ResolveActorName(target, "This Milk Maid")
    String armorText = ""
    If armorEnabled
        Armor worn = target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
        Int armorClass = MMEArmorScript.ClassifyArmorQuiet(milk, worn, target)
        If armorClass == 1
            armorText = name + " wears milking equipment, promising sweet relief for her treasured bounty."
        ElseIf armorClass == 2
            armorText = name + "'s living attire offers a pulsing embrace and deliciously intimate temptation."
        ElseIf armorClass == 3
            armorText = name + "'s clinging living growths promise intimate teasing in exchange for her milky bounty."
        ElseIf armorClass == 4
            If MMECustomArmorRegistry.GetDwemerPresentationProfile(worn) == "deviousSuit"
                armorText = name + "'s Dwemer suit promises wicked vibrations in exchange for her creamy bounty."
            Else
                armorText = name + "'s Dwemer attachment promises wicked vibrations in exchange for her creamy bounty."
            EndIf
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
    String result = "{\"enabled\":true,\"milkEnabled\":" + BoolJson(milkEnabled) + ",\"armorEnabled\":" + BoolJson(armorEnabled) + ",\"name\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(name) + "\",\"armor\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(armorText) + "\",\"leak\":\"" + MMEAlertsSkyrimNet.EscapeJsonString(leakText) + "\"}"
    StorageUtil.SetIntValue(target, "MME.Prompt.StateEnabled", 1)
    StorageUtil.SetIntValue(target, "MME.Prompt.MilkEnabled", milkEnabled as Int)
    StorageUtil.SetIntValue(target, "MME.Prompt.ArmorEnabled", armorEnabled as Int)
    StorageUtil.SetStringValue(target, "MME.Prompt.Name", name)
    StorageUtil.SetStringValue(target, "MME.Prompt.Armor", armorText)
    StorageUtil.SetStringValue(target, "MME.Prompt.Leak", leakText)
    TraceSnapshot(target, result, milkEnabled)
    Return MMEAlertsSkyrimNet.PromptCallbackReturn("GetActorState", target, result, "current actor state composed")
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

; Direct prompt transport. These functions run at existing gameplay boundaries,
; never on Skyrim.Net's render worker or through RegisterDecorator.
Function Invalidate(Actor target, String reason = "state changed") Global
    If target != None
        StorageUtil.AdjustIntValue(target, "MME.Prompt.Version", 1)
        StorageUtil.SetIntValue(target, "MME.Prompt.Ready", 0)
        StorageUtil.SetIntValue(target, "MME.Prompt.StateEnabled", 0)
        StorageUtil.SetStringValue(target, "MME.Prompt.Role", "")
        StorageUtil.SetStringValue(target, "MME.Prompt.Guidance", "")
        StorageUtil.UnsetStringValue(target, "MME.Prompt.Lore")
        StorageUtil.UnsetStringValue(target, "MME.Prompt.Armor")
        StorageUtil.UnsetStringValue(target, "MME.Prompt.Leak")
        StorageUtil.UnsetStringValue(target, "MME.Prompt.Name")
        StorageUtil.UnsetStringValue(target, "MME.Prompt.Published")
        MMELog.MasterDiagnostic("[MME Actor Prompt] direct snapshot invalidated | actor=" + target + " | reason=" + reason)
    EndIf
EndFunction

Function RefreshConfig() Global
    Bool enabled = Game.GetModByName("SkyrimNet.esp") != 255 && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1 && JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) == 1
    StorageUtil.SetIntValue(None, "MME.Prompt.Enabled", enabled as Int)
EndFunction

Function Initialize() Global
    StorageUtil.AdjustIntValue(None, "MME.Prompt.Epoch", 1)
    StorageUtil.FormListClear(None, "MME.Prompt.Expiring")
    StorageUtil.SetFloatValue(None, "MME.Prompt.NextExpiry", 0.0)
    RefreshConfig()
    MMELog.MasterDiagnostic("[MME Actor Prompt] direct transport initialized | old snapshots invalidated; no Papyrus decorators")
    If StorageUtil.GetIntValue(None, "MME.Prompt.Enabled", 0) == 1
        Observe(MMEExtensionsNative.GetNearbyActors(2000.0))
        Refresh(Game.GetPlayer())
    EndIf
EndFunction

Function Observe(Actor[] nearby) Global
    RefreshConfig()
    ; Clear actors that left the observed set instead of retaining stale equipment.
    Int old = StorageUtil.FormListCount(None, "MME.Prompt.Observed")
    While old > 0
        old -= 1
        Actor previous = StorageUtil.FormListGet(None, "MME.Prompt.Observed", old) as Actor
        If previous != None && nearby.Find(previous) < 0
            Invalidate(previous, "left observed area")
        EndIf
    EndWhile
    StorageUtil.FormListClear(None, "MME.Prompt.Observed")
    Int index = 0
    While index < nearby.Length
        Actor target = nearby[index]
        If target != None
            Refresh(target)
            StorageUtil.FormListAdd(None, "MME.Prompt.Observed", target, False)
        EndIf
        index += 1
    EndWhile
EndFunction

Function Refresh(Actor target) Global
    If target == None
        Return
    EndIf
    ; Optional Skyrim.Net absent: no calls into its integration script.
    If Game.GetModByName("SkyrimNet.esp") == 255
        StorageUtil.SetIntValue(target, "MME.Prompt.Ready", 0)
        Return
    EndIf
    RefreshConfig()
    If StorageUtil.GetIntValue(None, "MME.Prompt.Enabled", 0) != 1
        Invalidate(target, "integration disabled")
        Return
    EndIf
    If target.IsDead() || target.IsDisabled()
        Invalidate(target, "dead or disabled actor")
        Return
    EndIf
    Int requestEpoch = StorageUtil.GetIntValue(None, "MME.Prompt.Epoch", 0)
    Int requestVersion = StorageUtil.AdjustIntValue(target, "MME.Prompt.Version", 1)
    StorageUtil.SetIntValue(target, "MME.Prompt.Ready", 0)
    StorageUtil.SetIntValue(target, "MME.Prompt.StateEnabled", 0)
    ; Preserve the existing facade's exact eligibility semantics.
    Bool maid = MMEAlertsSkyrimNet.IsRealMMEMilkmaid(target)
    String recent = MMEAlertsSkyrimNet.RecentMilkDrinkerPrompt(target)
    StorageUtil.SetIntValue(target, "MME.Prompt.IsMaid", maid as Int)
    StorageUtil.SetIntValue(target, "MME.Prompt.Recent", (recent == "true") as Int)
    If recent == "true"
        TrackRecent(target)
    EndIf
    String lore = ""
    If maid || recent == "true"
        lore = MMEAlertsSkyrimNet.MilkLoreText(target)
    EndIf
    StorageUtil.SetStringValue(target, "MME.Prompt.Lore", lore)
    String role = MMEAlertsSkyrimNet.BreastfeedingPromptRole(target)
    StorageUtil.SetStringValue(target, "MME.Prompt.Role", role)
    StorageUtil.SetStringValue(target, "MME.Prompt.Guidance", MMEAlertsSkyrimNet.BreastfeedingGuidanceText(target))
    String ignored = GetActorState(target)
    If requestEpoch != StorageUtil.GetIntValue(None, "MME.Prompt.Epoch", 0) || requestVersion != StorageUtil.GetIntValue(target, "MME.Prompt.Version", 0)
        Invalidate(target, "snapshot superseded during load or state change")
        Return
    EndIf
    StorageUtil.SetIntValue(target, "MME.Prompt.Epoch", requestEpoch)
    ; Commit last; readers suppress incomplete snapshots.
    StorageUtil.SetIntValue(target, "MME.Prompt.Ready", 1)
    String signature = (maid as String) + "|" + role + "|" + lore + "|" + ignored
    If StorageUtil.GetStringValue(target, "MME.Prompt.Published", "") != signature
        StorageUtil.SetStringValue(target, "MME.Prompt.Published", signature)
        MMELog.MasterDiagnostic("[MME Actor Prompt] direct snapshot published | actor=" + target + " | maid=" + maid + " | role=" + role)
    EndIf
EndFunction

; One-shot expiry joins the controller's existing deadline scheduler, not polling.
Function TrackRecent(Actor target) Global
    StorageUtil.FormListAdd(None, "MME.Prompt.Expiring", target, False)
    Float deadline = StorageUtil.GetFloatValue(target, "MME.Extensions.SkyrimNet.RecentMilkDrink", -120.0) + 90.0
    Float previous = NextExpiry()
    If previous <= 0.0 || deadline < previous
        StorageUtil.SetFloatValue(None, "MME.Prompt.NextExpiry", deadline)
    EndIf
EndFunction

Float Function NextExpiry() Global
    Return StorageUtil.GetFloatValue(None, "MME.Prompt.NextExpiry", 0.0)
EndFunction

Function ExpireRecent() Global
    Float now = Utility.GetCurrentRealTime()
    Float next = 0.0
    Int index = StorageUtil.FormListCount(None, "MME.Prompt.Expiring")
    While index > 0
        index -= 1
        Actor target = StorageUtil.FormListGet(None, "MME.Prompt.Expiring", index) as Actor
        Float marked = StorageUtil.GetFloatValue(target, "MME.Extensions.SkyrimNet.RecentMilkDrink", -120.0)
        Float deadline = marked + 90.0
        If target == None || marked > now || deadline <= now
            StorageUtil.FormListRemove(None, "MME.Prompt.Expiring", target, True)
            If target != None
                StorageUtil.SetIntValue(target, "MME.Prompt.Recent", 0)
                StorageUtil.UnsetFloatValue(target, "MME.Extensions.SkyrimNet.RecentMilkDrink")
                If StorageUtil.GetIntValue(target, "MME.Prompt.IsMaid", 0) != 1
                    StorageUtil.SetStringValue(target, "MME.Prompt.Lore", "")
                EndIf
                MMELog.MasterDiagnostic("[MME Actor Prompt] recent drink expired | actor=" + target)
            EndIf
        ElseIf next <= 0.0 || deadline < next
            next = deadline
        EndIf
    EndWhile
    StorageUtil.SetFloatValue(None, "MME.Prompt.NextExpiry", next)
EndFunction
