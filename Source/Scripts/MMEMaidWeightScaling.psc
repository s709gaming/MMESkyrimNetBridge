Scriptname MMEMaidWeightScaling Hidden

String Function SettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

String Function ManagedKey() Global
    Return "MMEExtensions.MaidWeight.Managed"
EndFunction

String Function BaselineKey() Global
    Return "MMEExtensions.MaidWeight.Baseline"
EndFunction

String Function LastAppliedKey() Global
    Return "MMEExtensions.MaidWeight.LastApplied"
EndFunction

String Function OwnedKey() Global
    Return "MMEExtensions.MaidWeight.Owned"
EndFunction

String Function PendingVisualKey() Global
    Return "MMEExtensions.MaidWeight.PendingVisual"
EndFunction

Bool Function IsEnabled() Global
    Return JsonUtil.GetIntValue(SettingsFile(), "enableMaidLevelWeightScaling", 1) == 1
EndFunction

Float Function GetWeightPerLevel() Global
    Float value = JsonUtil.GetFloatValue(SettingsFile(), "maidWeightPerLevel", 1.0)
    If value < 0.0
        Return 0.0
    ElseIf value > 10.0
        Return 10.0
    EndIf
    Return value
EndFunction

Function ReconcileAll(String source = "unspecified") Global
    MilkQUEST controller = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If controller == None
        Alarm("reconcile failed | MME controller unavailable | source=" + source)
        Return
    EndIf
    ; Do not read MilkQUEST.MilkMaid here. Some supported MME builds expose the
    ; property to the compiler but return an uncastable None to external scripts.
    ; Actors enter this managed list through authoritative creation/cycle events.
    Int i = StorageUtil.FormListCount(None, ManagedKey()) - 1
    While i >= 0
        Actor managed = StorageUtil.FormListGet(None, ManagedKey(), i) as Actor
        If managed == None
            StorageUtil.FormListRemoveAt(None, ManagedKey(), i)
        ElseIf !IsEnabled() || !MMEArmorScript.IsMMEMilkMaid(managed, controller)
            RestoreActor(managed, source)
        Else
            ReconcileActor(managed, source)
        EndIf
        i -= 1
    EndWhile
    If !IsEnabled()
        Trace("reconcile complete | scaling disabled; owned changes restored | source=" + source)
        Return
    EndIf
    ; Ensure the player is discovered immediately after enabling the option.
    ; NPC maids are added by their creation/milking/cycle events without polling.
    ReconcileActor(Game.GetPlayer(), source)
    Trace("reconcile complete | managed actors=" + StorageUtil.FormListCount(None, ManagedKey()) + " | source=" + source)
EndFunction

Function ReconcileActor(Actor candidate, String source = "unspecified") Global
    If candidate == None
        Return
    EndIf
    If !IsEnabled()
        RestoreActor(candidate, source)
        Return
    EndIf
    MilkQUEST controller = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If controller == None
        Alarm("reconcile deferred | MME controller unavailable | actor=" + GetActorName(candidate) + " | source=" + source)
        Return
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(candidate, controller)
        RestoreActor(candidate, source)
        Return
    EndIf
    ActorBase baseInfo = candidate.GetLeveledActorBase()
    If baseInfo == None
        Alarm("apply failed | ActorBase unavailable | actor=" + GetActorName(candidate) + " | source=" + source)
        Return
    EndIf
    Float currentWeight = baseInfo.GetWeight()
    Float baseline = currentWeight
    If StorageUtil.GetIntValue(candidate, OwnedKey(), 0) == 1
        baseline = StorageUtil.GetFloatValue(candidate, BaselineKey(), currentWeight)
        Float previousApplied = StorageUtil.GetFloatValue(candidate, LastAppliedKey(), currentWeight)
        If currentWeight < previousApplied - 0.01 || currentWeight > previousApplied + 0.01
            baseline = ClampWeight(currentWeight - (previousApplied - baseline))
            StorageUtil.SetFloatValue(candidate, BaselineKey(), baseline)
            Trace("external weight change rebased | actor=" + GetActorName(candidate) + " | baseline=" + baseline + " | source=" + source)
        EndIf
    Else
        StorageUtil.SetFloatValue(candidate, BaselineKey(), baseline)
        StorageUtil.SetIntValue(candidate, OwnedKey(), 1)
        StorageUtil.FormListAdd(None, ManagedKey(), candidate, False)
    EndIf
    Int maidLevel = MME_Storage.getMaidLevel(candidate)
    Float targetWeight = ClampWeight(baseline + (maidLevel * GetWeightPerLevel()))
    Bool changed = currentWeight < targetWeight - 0.01 || currentWeight > targetWeight + 0.01
    If changed
        ApplyWeight(candidate, baseInfo, currentWeight, targetWeight)
    ElseIf candidate.Is3DLoaded() && StorageUtil.GetIntValue(candidate, PendingVisualKey(), 0) == 1
        candidate.UpdateWeight(0.0)
        StorageUtil.UnsetIntValue(candidate, PendingVisualKey())
    EndIf
    StorageUtil.SetFloatValue(candidate, LastAppliedKey(), targetWeight)
    Trace("reconciled | actor=" + GetActorName(candidate) + " | level=" + maidLevel + " | baseline=" + baseline + " | perLevel=" + GetWeightPerLevel() + " | target=" + targetWeight + " | changed=" + changed + " | source=" + source)
EndFunction

Function RestoreActor(Actor candidate, String source = "unspecified") Global
    If candidate == None || StorageUtil.GetIntValue(candidate, OwnedKey(), 0) != 1
        Return
    EndIf
    ActorBase baseInfo = candidate.GetLeveledActorBase()
    If baseInfo == None
        Alarm("restore failed | ActorBase unavailable | actor=" + GetActorName(candidate) + " | source=" + source)
        Return
    EndIf
    Float currentWeight = baseInfo.GetWeight()
    Float baseline = StorageUtil.GetFloatValue(candidate, BaselineKey(), currentWeight)
    Float previousApplied = StorageUtil.GetFloatValue(candidate, LastAppliedKey(), currentWeight)
    If currentWeight < previousApplied - 0.01 || currentWeight > previousApplied + 0.01
        baseline = ClampWeight(currentWeight - (previousApplied - baseline))
        Trace("restore rebased around external change | actor=" + GetActorName(candidate) + " | baseline=" + baseline + " | source=" + source)
    EndIf
    ApplyWeight(candidate, baseInfo, currentWeight, baseline)
    StorageUtil.UnsetFloatValue(candidate, BaselineKey())
    StorageUtil.UnsetFloatValue(candidate, LastAppliedKey())
    StorageUtil.UnsetIntValue(candidate, OwnedKey())
    StorageUtil.FormListRemove(None, ManagedKey(), candidate, True)
    Trace("restored | actor=" + GetActorName(candidate) + " | weight=" + baseline + " | source=" + source)
EndFunction

Function ApplyWeight(Actor candidate, ActorBase baseInfo, Float oldWeight, Float newWeight) Global
    baseInfo.SetWeight(newWeight)
    If candidate.Is3DLoaded()
        candidate.UpdateWeight((oldWeight / 100.0) - (newWeight / 100.0))
        StorageUtil.UnsetIntValue(candidate, PendingVisualKey())
    Else
        StorageUtil.SetIntValue(candidate, PendingVisualKey(), 1)
    EndIf
EndFunction

Float Function ClampWeight(Float value) Global
    If value < 0.0
        Return 0.0
    ElseIf value > 100.0
        Return 100.0
    EndIf
    Return value
EndFunction

String Function GetActorName(Actor candidate) Global
    Return MMEForcedMilkDrink.GetActorName(candidate)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Maid Weight] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Maid Weight] FAILURE: " + detail)
EndFunction
