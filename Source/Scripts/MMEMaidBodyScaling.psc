Scriptname MMEMaidBodyScaling Hidden

; Cosmetic contribution only. MME remains authoritative for Maid level and breasts.
String Function SettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

String Function ManagedKey() Global
    Return "MMEExtensions.MaidBody.Managed"
EndFunction

Bool Function IsEnabled() Global
    Return MMEAlertsController.IsExtensionsEnabled() && JsonUtil.GetIntValue(SettingsFile(), "enableMaidBodyScaling", 0) == 1
EndFunction

Int Function GetMaxLevel() Global
    Int value = JsonUtil.GetIntValue(SettingsFile(), "maidBodyScalingMaxLevel", 100)
    If value < 10
        Return 10
    ElseIf value > 100
        Return 100
    EndIf
    Return value
EndFunction

String[] Function MorphNames() Global
    String[] names = new String[10]
    names[0] = "Hips"
    names[1] = "Butt"
    names[2] = "Thighs"
    names[3] = "CalfSize"
    names[4] = "Waist"
    names[5] = "Belly"
    names[6] = "BigBelly"
    names[7] = "ChubbyArms"
    names[8] = "ChubbyLegs"
    names[9] = "ChubbyWaist"
    Return names
EndFunction

Float Function GetMaximum(String morph) Global
    Float value = JsonUtil.GetFloatValue(SettingsFile(), "maidBodyMorph" + morph, 0.0)
    If value < 0.0
        Return 0.0
    ElseIf value > 100.0
        Return 100.0
    EndIf
    Return value
EndFunction

Float Function GetProgress(Int level, Int maximum) Global
    If maximum < 10
        maximum = 10
    ElseIf maximum > 100
        maximum = 100
    EndIf
    If level <= 0
        Return 0.0
    ElseIf level >= maximum
        Return 1.0
    EndIf
    Return (level as Float) / maximum
EndFunction

Function SettingsChanged() Global
    JsonUtil.SetIntValue(SettingsFile(), "maidBodyScalingRevision", JsonUtil.GetIntValue(SettingsFile(), "maidBodyScalingRevision", 0) + 1)
    JsonUtil.Save(SettingsFile(), False)
    ReconcileAll("MCM settings changed")
EndFunction

Function ReconcileAll(String source = "unspecified", Bool afterLoad = False) Global
    If afterLoad
        Int session = MMEExtensionsNative.GetMovementSlapSession()
        If StorageUtil.GetIntValue(None, "MMEExtensions.MaidBody.Session", -1) == session
            afterLoad = False
        Else
            StorageUtil.SetIntValue(None, "MMEExtensions.MaidBody.Session", session)
        EndIf
    EndIf
    ; Managed actors include unloaded NPCs: clear their stored key immediately;
    ; RaceMenu rebuilds their visible body when their 3D is loaded again.
    Int i = StorageUtil.FormListCount(None, ManagedKey()) - 1
    While i >= 0
        Actor candidate = StorageUtil.FormListGet(None, ManagedKey(), i) as Actor
        If candidate == None
            StorageUtil.FormListRemoveAt(None, ManagedKey(), i)
        Else
            If afterLoad
                Trace("load recovery | actor=" + candidate + " | invalidating token=" + StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Token", 0) + " | interrupted=" + StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Pending", 0))
                StorageUtil.AdjustIntValue(candidate, "MMEExtensions.MaidBody.Token", 1)
                StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Busy")
                StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Revision")
                StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Pending")
                ; Deduplicate within a session, but expose the first fresh failure after load.
                StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Failure")
            EndIf
            ReconcileActor(candidate, source)
        EndIf
        i -= 1
    EndWhile
    If !IsEnabled()
        Return
    EndIf
    ReconcileActor(Game.GetPlayer(), source)
    ; Discover pre-existing NPC maids without reading MME's parallel arrays.
    Actor[] nearby = MMEExtensionsNative.GetNearbyActors(4000.0)
    i = 0
    While i < nearby.Length
        If nearby[i] != None && nearby[i] != Game.GetPlayer()
            ReconcileActor(nearby[i], source)
        EndIf
        i += 1
    EndWhile
EndFunction

Function ReconcileActor(Actor candidate, String source = "unspecified") Global
    If candidate == None
        Return
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Busy", 0) == 1
        StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.Dirty", 1)
        Return
    EndIf
    StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.Busy", 1)
    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Dirty")
    If !ApplyActor(candidate, source)
        FinishActor(candidate)
    EndIf
EndFunction

Bool Function ApplyActor(Actor candidate, String source) Global
    Bool owned = StorageUtil.FormListFind(None, ManagedKey(), candidate) >= 0
    Bool eligible = IsEnabled()
    MilkQUEST controller = None
    If eligible
        controller = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
        If controller == None
            Alarm(candidate, "reconcile", "MME controller unavailable", source)
            Return False
        EndIf
        eligible = MMEArmorScript.IsMMEMilkMaid(candidate, controller)
    EndIf
    If !eligible && !owned
        Return False
    EndIf
    If !MMEExtensionsNative.IsBodyMorphAvailable()
        ; Missing optional RaceMenu is expected. Retain ownership for cleanup
        ; if it returns; never silently forget an actor's outstanding changes.
        If StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Missing", 0) == 0
            Trace("skip | actor=" + candidate + " | optional RaceMenu unavailable | source=" + source)
            StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.Missing", 1)
        EndIf
        Return False
    EndIf
    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Missing")
    Int level = 0
    Float progress = 0.0
    Int revision = JsonUtil.GetIntValue(SettingsFile(), "maidBodyScalingRevision", 0)
    String[] names
    Float[] values
    If eligible
        ; Verified MME API uses actor-keyed StorageUtil, not an array index.
        level = MME_Storage.getMaidLevel(candidate)
        progress = GetProgress(level, GetMaxLevel())
        If owned && StorageUtil.GetFloatValue(candidate, "MMEExtensions.MaidBody.Progress", -1.0) == progress && StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Revision", -1) == revision
            Return False
        EndIf
        names = MorphNames()
        values = new Float[10]
        String calculated = ""
        Int i = 0
        While i < names.Length
            values[i] = progress * GetMaximum(names[i]) / 100.0
            calculated += " " + names[i] + "=" + values[i]
            i += 1
        EndWhile
        Trace("calculated | actor=" + candidate + " |" + calculated)
        ; Record ownership before the asynchronous transaction, including partial failure.
        StorageUtil.FormListAdd(None, ManagedKey(), candidate, False)
    EndIf
    Trace("entry | actor=" + candidate + " | eligible=" + eligible + " | level=" + level + " | cap=" + GetMaxLevel() + " | progress=" + progress + " | source=" + source)
    Int token = StorageUtil.AdjustIntValue(candidate, "MMEExtensions.MaidBody.Token", 1)
    StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.Pending", 1)
    StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.RequestEligible", eligible as Int)
    StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.RequestRevision", revision)
    StorageUtil.SetFloatValue(candidate, "MMEExtensions.MaidBody.RequestProgress", progress)
    Bool accepted = MMEExtensionsNative.ApplyMaidBodyMorphs(candidate, names, values, token)
    If !accepted
        StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Pending")
        Alarm(candidate, "queue apply/cleanup", "token=" + token + " | " + MMEExtensionsNative.GetMaidBodyFailureReason(candidate, token) + " | ownership retained for retry", source)
    EndIf
    Return accepted
EndFunction

; Token matching rejects callbacks from old requests or saves. No gameplay
; Papyrus stack waits on a native callback across save/load.
Function CompleteActor(Actor candidate, Int token, Bool success) Global
    If candidate == None
        Trace("completion skipped | target=None | token=" + token)
        Return
    EndIf
    Int currentToken = StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Token", 0)
    If currentToken != token
        Trace("stale completion discarded | actor=" + candidate + " | received token=" + token + " | current token=" + currentToken)
        Return
    EndIf
    If success
        StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Failure")
        If StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.RequestEligible", 0) == 1
            StorageUtil.SetFloatValue(candidate, "MMEExtensions.MaidBody.Progress", StorageUtil.GetFloatValue(candidate, "MMEExtensions.MaidBody.RequestProgress", 0.0))
            StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.Revision", StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.RequestRevision", -1))
            Trace("applied and readback verified | actor=" + candidate + " | token=" + token + " | progress=" + StorageUtil.GetFloatValue(candidate, "MMEExtensions.MaidBody.Progress", 0.0))
        Else
            StorageUtil.FormListRemove(None, ManagedKey(), candidate, True)
            StorageUtil.UnsetFloatValue(candidate, "MMEExtensions.MaidBody.Progress")
            StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Revision")
            Trace("cleanup complete and key absence verified | actor=" + candidate + " | token=" + token + " | disabled or no longer a Milk Maid | only owned morph key removed")
        EndIf
    Else
        Alarm(candidate, "apply/cleanup", "token=" + token + " | " + MMEExtensionsNative.GetMaidBodyFailureReason(candidate, token) + " | ownership retained for retry", "native completion")
    EndIf
    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Pending")
    FinishActor(candidate)
EndFunction

Function FinishActor(Actor candidate) Global
    StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Busy")
    If StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Dirty", 0) == 1
        StorageUtil.UnsetIntValue(candidate, "MMEExtensions.MaidBody.Dirty")
        ReconcileActor(candidate, "overlapping request recovery")
    EndIf
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Maid Body] " + detail)
EndFunction

Function Alarm(Actor candidate, String operation, String reason, String source) Global
    If StorageUtil.GetIntValue(candidate, "MMEExtensions.MaidBody.Failure", 0) == 0
        StorageUtil.SetIntValue(candidate, "MMEExtensions.MaidBody.Failure", 1)
        MMELog.Alarm("[MME Extensions Maid Body] FAILURE: operation=" + operation + " | actor=" + candidate + " | reason=" + reason + " | source=" + source)
    EndIf
EndFunction
