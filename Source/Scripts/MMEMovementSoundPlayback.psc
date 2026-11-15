Scriptname MMEMovementSoundPlayback Hidden

; NPC companion to the existing player owner. This list is ours, never an MME
; slot array. Audio IDs are usable only in the native session that created them.
String Function ActorsKey() Global
    Return "MMEExtensions.MovementNPC.Actors"
EndFunction

Function Trace(Actor target, String detail) Global
    MMELog.MasterDiagnostic("[MME Movement NPC] actor=" + target + " | " + detail)
EndFunction

Function Alarm(Actor target, String reason) Global
    If StorageUtil.GetIntValue(target, "MME.MovementNPC.Alarm", 0) == 0
        StorageUtil.SetIntValue(target, "MME.MovementNPC.Alarm", 1)
        MMELog.Alarm("[MME Movement NPC] playback failed | actor=" + target + " | " + reason)
    EndIf
EndFunction

Bool Function Enabled() Global
    String file = "/MMEAlerts/Settings"
    Return MMEAlertsController.IsExtensionsEnabled() && JsonUtil.GetIntValue(file, "enableMovementSlap", 1) == 1 && JsonUtil.GetIntValue(file, "enableReactionSounds", 1) == 1 && JsonUtil.GetIntValue(file, "enableMovementSoundNPC", 1) == 1
EndFunction

Function Stop(Actor target, String reason) Global
    If target == None
        Return
    EndIf
    MMEExtensionsNative.RemoveMovementAudio(target)
    Int instance = StorageUtil.GetIntValue(target, "MME.MovementNPC.Instance", -1)
    Int session = StorageUtil.GetIntValue(target, "MME.MovementNPC.Session", -1)
    StorageUtil.UnsetIntValue(target, "MME.MovementNPC.Instance")
    If instance >= 0 && session == MMEExtensionsNative.GetMovementSlapSession()
        Sound.StopInstance(instance)
        Trace(target, "stop | " + reason)
    EndIf
EndFunction

Function StopAll(String reason) Global
    ; Invalidate starts interrupted by menu/load/settings callbacks.
    StorageUtil.AdjustIntValue(None, "MME.MovementNPC.Generation", 1)
    Form[] tracked = StorageUtil.FormListToArray(None, ActorsKey())
    Int i = 0
    While i < tracked.Length
        Stop(tracked[i] as Actor, reason)
        i += 1
    EndWhile
EndFunction

Function Reset(String reason) Global
    StopAll(reason)
    StorageUtil.FormListClear(None, ActorsKey())
    StorageUtil.UnsetFloatValue(None, "MME.MovementNPC.NextScan")
    StorageUtil.UnsetIntValue(None, "MME.MovementNPC.Updating")
EndFunction

Function Refresh(MilkQUEST milk) Global
    Float now = Utility.GetCurrentRealTime()
    Float deadline = StorageUtil.GetFloatValue(None, "MME.MovementNPC.NextScan", 0.0)
    If deadline > now && deadline < now + 3.0
        Return
    EndIf
    StorageUtil.SetFloatValue(None, "MME.MovementNPC.NextScan", now + 2.0)
    Actor[] nearby = MMEExtensionsNative.GetNearbyActors(2000.0)
    Form[] previous = StorageUtil.FormListToArray(None, ActorsKey())
    Int i = 0
    While i < previous.Length
        Actor old = previous[i] as Actor
        If nearby.Find(old) < 0
            Stop(old, "left nearby set")
        EndIf
        i += 1
    EndWhile
    StorageUtil.FormListClear(None, ActorsKey())
    i = 0
    While i < nearby.Length
        Actor candidate = nearby[i]
        If candidate != None && candidate != Game.GetPlayer() && MMEArmorScript.IsValidMilkMaid(candidate, milk)
            StorageUtil.FormListAdd(None, ActorsKey(), candidate, False)
        ElseIf candidate != None
            Stop(candidate, "not an eligible NPC Milk Maid")
        EndIf
        i += 1
    EndWhile
EndFunction

String Function BlockReason(Actor target, MilkQUEST milk) Global
    If !Enabled() || Utility.IsInMenuMode()
        Return "disabled or menu open"
    EndIf
    If target == Game.GetPlayer() || !MMEArmorScript.IsValidMilkMaid(target, milk)
        Return "not an NPC Milk Maid"
    EndIf
    If target.GetParentCell() != Game.GetPlayer().GetParentCell() || target.GetDistance(Game.GetPlayer()) > 2000.0
        Return "out of range"
    EndIf
    If MMEAnimationSafety.GetOwner(target) != "" || MMEAnimationSafety.IsMMEMilking(target, milk)
        Return "animation or milking owns actor"
    EndIf
    String safety = MMEAnimationSafety.GetStartBlockReason(target, milk, False)
    If safety != ""
        Return safety
    EndIf
    Return ""
EndFunction

Function UpdateActor(Actor target, MilkQUEST milk) Global
    String reason = BlockReason(target, milk)
    If reason != StorageUtil.GetStringValue(target, "MME.MovementNPC.Reason", "<unchecked>")
        Trace(target, "eligibility | " + reason)
        StorageUtil.SetStringValue(target, "MME.MovementNPC.Reason", reason)
    EndIf
    If reason != ""
        Stop(target, reason)
        Return
    EndIf
    If !StorageUtil.HasFloatValue(target, "MME.MilkMaid.MilkMaximum")
        MME_Storage.getMilkMaximum(target)
    EndIf
    Float maximum = StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkMaximum", 0.0)
    Float current = StorageUtil.GetFloatValue(target, "MME.MilkMaid.MilkCount", 0.0)
    If maximum <= 0.0
        Stop(target, "milk capacity unavailable")
        Return
    EndIf
    Int baseRoute = 0
    If current >= maximum * 0.5
        baseRoute = 2
    EndIf
    MMEMovementSounds.Configure(target, baseRoute, True)
    Int instance = MMEExtensionsNative.GetMovementAudioInstance(target)
    Int previous = StorageUtil.GetIntValue(target, "MME.MovementNPC.Instance", -1)
    StorageUtil.SetIntValue(target, "MME.MovementNPC.Session", MMEExtensionsNative.GetMovementSlapSession())
    StorageUtil.SetIntValue(target, "MME.MovementNPC.Instance", instance)
    If instance >= 0 && instance != previous
        Notify(target, current, maximum)
    EndIf
EndFunction

Function Notify(Actor target, Float current, Float maximum) Global
    Int generation = StorageUtil.GetIntValue(None, "MME.MovementNPC.Generation", 0)
    Int instance = StorageUtil.GetIntValue(target, "MME.MovementNPC.Instance", -1)
    String file = "/MMEAlerts/Settings"
    If current <= maximum * 0.5 || JsonUtil.GetIntValue(file, "enableMovementSlapNotifications", 1) != 1
        Return
    EndIf
    Float now = Utility.GetCurrentGameTime()
    Float hours = JsonUtil.GetFloatValue(file, "movementSlapNotificationCooldownHours", 8.0)
    If hours < 0.0
        hours = 0.0
    ElseIf hours > 48.0
        hours = 48.0
    EndIf
    Float previous = StorageUtil.GetFloatValue(target, "MMEExtensions.MovementSlap.LastNotification", -100.0)
    If now >= previous && (now - previous) * 24.0 < hours
        Return
    EndIf
    Float shared = StorageUtil.GetFloatValue(None, "MME.MovementNPC.LastHUD", -100.0)
    Float real = Utility.GetCurrentRealTime()
    If real >= shared && real - shared < 10.0
        Return
    EndIf
    String[] pool = MMENarrationOverrides.Pool("/MMEAlerts/BreastBounceNotifications", ".movement_npc", target)
    If pool.Length == 0
        If StorageUtil.GetIntValue(target, "MME.MovementNPC.NotificationAlarm", 0) == 0
            StorageUtil.SetIntValue(target, "MME.MovementNPC.NotificationAlarm", 1)
            MMELog.Alarm("[MME Movement NPC] notification failed | actor=" + target + " | NPC movement pool empty")
        EndIf
        Return
    EndIf
    If generation != StorageUtil.GetIntValue(None, "MME.MovementNPC.Generation", 0) || instance < 0 || instance != StorageUtil.GetIntValue(target, "MME.MovementNPC.Instance", -1)
        Return
    EndIf
    StorageUtil.UnsetIntValue(target, "MME.MovementNPC.NotificationAlarm")
    StorageUtil.SetFloatValue(target, "MMEExtensions.MovementSlap.LastNotification", now)
    StorageUtil.SetFloatValue(None, "MME.MovementNPC.LastHUD", real)
    Debug.Notification(MMEThoughts.RenderActorToken(pool[Utility.RandomInt(0, pool.Length - 1)], target.GetDisplayName()))
    Trace(target, "notification shown")
EndFunction

Function Update() Global
    If !Enabled() || Utility.IsInMenuMode()
        If StorageUtil.FormListCount(None, ActorsKey()) > 0
            Reset("disabled or menu")
        EndIf
        Return
    EndIf
    If StorageUtil.GetIntValue(None, "MME.MovementNPC.Updating", 0) == 1
        Return
    EndIf
    StorageUtil.SetIntValue(None, "MME.MovementNPC.Updating", 1)
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milk != None
        Refresh(milk)
        Form[] tracked = StorageUtil.FormListToArray(None, ActorsKey())
        Int i = 0
        While i < tracked.Length
            UpdateActor(tracked[i] as Actor, milk)
            i += 1
        EndWhile
    Else
        StopAll("MME unavailable")
    EndIf
    StorageUtil.UnsetIntValue(None, "MME.MovementNPC.Updating")
EndFunction
