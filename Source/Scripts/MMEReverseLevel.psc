Scriptname MMEReverseLevel extends Quest

; Dedicated quest: update registrations on a shared quest would cancel the
; other attached scripts' timers. All entry points use this one service.
Spell Property ReverseAbility Auto
Actor playerActor
MilkQUEST milkController
MMEReverseLevelEffect effectInstance
Bool active = False
Bool busy = False
Float expiresAt = 0.0
Float baseline = 0.0
Int baselineLevel = 0
Int multiplier = 0
Int candidateLevel = -1
Float candidateProgress = -1.0
Bool milkingDone = False
Float candidateSince = 0.0
Int mechanicsVersion = 0
String progressKey = "MME.MilkMaid.TimesMilked"

MMEReverseLevel Function GetService() Global
    Return Quest.GetQuest("MMEExt_ReverseLevelQuest") as MMEReverseLevel
EndFunction

Int Function GetDuration() Global
    Int hours = JsonUtil.GetIntValue("/MMEAlerts/Settings", "reverseLevelingDuration", 24)
    If hours < 1
        Return 1
    ElseIf hours > 72
        Return 72
    EndIf
    Return hours
EndFunction

Int Function GetRequiredLevel() Global
    Int requiredLevel = JsonUtil.GetIntValue("/MMEAlerts/Settings", "reversePlayerMaidLevel", 5)
    If requiredLevel < 1
        Return 1
    ElseIf requiredLevel > 10
        Return 10
    EndIf
    Return requiredLevel
EndFunction

Function TraceState(String traceMessage)
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableReverseLevelTrace", 0) == 1
        Debug.Trace("[MME Reverse Level] " + traceMessage)
    EndIf
EndFunction

Bool Function IsPlayerMaid() Global
    MilkQUEST milkQ = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkQ == None || milkQ.MilkMaidFaction == None
        Return False
    EndIf
    Return Game.GetPlayer().IsInFaction(milkQ.MilkMaidFaction)
EndFunction

; Reference MME MaidLevelCheck consumes (level + 1) * TimesMilkedMult.
; Accumulated thresholds below level L sum to M * L * (L + 1) / 2.
Float Function LevelBase(Int level, Int scale) Global
    Return (level as Float) * (level + 1) * scale * 0.5
EndFunction

Bool Function ApplyReverseLeveling()
    If busy
        Debug.Notification("Reverse leveling is updating; try again in a moment.")
        Return False
    EndIf
    playerActor = Game.GetPlayer()
    milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If ReverseAbility == None || !MMEAlertsController.IsExtensionsEnabled() || !IsPlayerMaid() \
        || milkController == None || milkController.TimesMilkedMult <= 0
        Debug.Notification("Reverse leveling needs its installed ability and an active Milk Maid.")
        Return False
    EndIf
    busy = True
    ; Applying/refreshing is setup, never a milking completion. Discard any
    ; pending sample so vendor dialogue cannot spend an earlier completion.
    multiplier = milkController.TimesMilkedMult
    CaptureBaseline()
    mechanicsVersion = 3
    expiresAt = Utility.GetCurrentGameTime() + GetDuration() / 24.0
    active = True
    If !playerActor.HasSpell(ReverseAbility)
        If !playerActor.AddSpell(ReverseAbility, False)
            active = False
            busy = False
            StopMonitoring()
            Debug.Notification("Reverse leveling ability could not be applied.")
            Return False
        EndIf
    EndIf
    ArmMonitoring()
    TraceState("APPLY duration=" + GetDuration() + " baselineLevel=" + baselineLevel)
    busy = False
    Debug.Notification("For the next " + GetDuration() + " hours, each milking will lower your Milk Maid level by 1.")
    Return True
EndFunction

Function RemoveReverseLeveling(Bool notifyPlayer = True)
    ; Invalidate first, so queued callbacks cannot write after removal.
    TraceState("REMOVE")
    active = False
    milkingDone = False
    expiresAt = 0.0
    effectInstance = None
    StopMonitoring()
    If playerActor == None
        playerActor = Game.GetPlayer()
    EndIf
    If ReverseAbility != None && playerActor.HasSpell(ReverseAbility)
        playerActor.RemoveSpell(ReverseAbility)
    EndIf
    If notifyPlayer
        Debug.Notification("Reverse leveling removed.")
    EndIf
EndFunction

Function EffectStarted(MMEReverseLevelEffect instance, Actor target)
    If active && target == playerActor
        effectInstance = instance
    EndIf
EndFunction

Function EffectFinished(MMEReverseLevelEffect instance)
    ; A late finish from a removed ability must not cancel a new application.
    If instance == effectInstance
        RemoveReverseLeveling(False)
    EndIf
EndFunction

Function RecoverAfterLoad()
    ; The extension's existing player load callback invokes this; quest scripts
    ; do not receive OnPlayerLoadGame themselves. Keep the saved baseline/deadline.
    busy = False
    playerActor = Game.GetPlayer()
    milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    StopMonitoring()
    If CanMonitor()
        If mechanicsVersion < 3
            multiplier = milkController.TimesMilkedMult
            CaptureBaseline()
            mechanicsVersion = 3
        EndIf
        TraceState("LOAD baselineLevel=" + baselineLevel)
        ArmMonitoring()
    Else
        RemoveReverseLeveling(False)
    EndIf
EndFunction

Bool Function CanMonitor()
    If !active || playerActor == None || milkController == None || ReverseAbility == None
        Return False
    EndIf
    If milkController.MilkMaidFaction == None
        Return False
    EndIf
    Return Utility.GetCurrentGameTime() < expiresAt && playerActor.HasSpell(ReverseAbility) \
        && MMEAlertsController.IsExtensionsEnabled() && playerActor.IsInFaction(milkController.MilkMaidFaction)
EndFunction

Function ArmMonitoring()
    RegisterForModEvent("MME_MilkingDone", "OnMilkingDone")
    RegisterForModEvent("MME_MilkCycleComplete", "OnMilkCycleComplete")
    RegisterForSingleUpdate(5.0)
    UnregisterForUpdateGameTime()
    Float remaining = (expiresAt - Utility.GetCurrentGameTime()) * 24.0
    If remaining > 0.0
        RegisterForSingleUpdateGameTime(remaining)
    EndIf
EndFunction

Function StopMonitoring()
    UnregisterForUpdate()
    UnregisterForUpdateGameTime()
    UnregisterForModEvent("MME_MilkingDone")
    UnregisterForModEvent("MME_MilkCycleComplete")
    candidateLevel = -1
    candidateProgress = -1.0
    candidateSince = 0.0
    milkingDone = False
EndFunction

Event OnMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    If active && actorForm == playerActor && bottles > 0
        milkingDone = True
        TraceState("MILKING DONE bottles=" + bottles)
        RegisterForSingleUpdate(1.0)
    EndIf
EndEvent

; This event is SendModEvent, unlike the typed ModEvent above. No actor payload.
Event OnMilkCycleComplete(String eventName, String strArg, Float numArg, Form sender)
    If active
        RegisterForSingleUpdate(1.0)
    EndIf
EndEvent

Event OnUpdateGameTime()
    If active
        If Utility.GetCurrentGameTime() >= expiresAt
            RemoveReverseLeveling(False)
        Else
            RegisterForSingleUpdateGameTime((expiresAt - Utility.GetCurrentGameTime()) * 24.0)
        EndIf
    EndIf
EndEvent

Event OnUpdate()
    If !active
        Return
    EndIf
    If !CanMonitor()
        RemoveReverseLeveling(False)
        Return
    EndIf
    If !busy
        busy = True
        CheckProgress()
        busy = False
    EndIf
    If active
        If candidateLevel >= 0
            RegisterForSingleUpdate(1.0)
        Else
            RegisterForSingleUpdate(5.0)
        EndIf
    EndIf
EndEvent

Function CaptureBaseline()
    baselineLevel = MME_Storage.getMaidLevel(playerActor)
    baseline = LevelBase(baselineLevel, multiplier) \
        + StorageUtil.GetFloatValue(playerActor, progressKey)
    candidateLevel = -1
    candidateProgress = -1.0
    candidateSince = 0.0
    milkingDone = False
EndFunction

Function CheckProgress()
    ; A session may add many gushes and normalize several thresholds. Never
    ; convert that gain into multiple level losses. Wait until milking ends.
    If milkController.BeingMilkedPassive != None && playerActor.HasSpell(milkController.BeingMilkedPassive)
        candidateLevel = -1
        Return
    EndIf
    Int scale = milkController.TimesMilkedMult
    If scale <= 0
        TraceState("STOP invalid progression multiplier")
        RemoveReverseLeveling(False)
        Return
    ElseIf scale != multiplier
        multiplier = scale
        CaptureBaseline()
        TraceState("REBASE difficulty changed")
        Return
    EndIf
    ; Progress can also change during ordinary MME updates and dialogue.
    ; Only a successful player milking completion authorizes a downgrade.
    If !milkingDone
        candidateLevel = -1
        Return
    EndIf
    Int level = StorageUtil.GetFloatValue(playerActor, "MME.MilkMaid.Level") as Int
    Float progress = StorageUtil.GetFloatValue(playerActor, progressKey)
    If level < 0 || progress < 0.0
        candidateLevel = -1
        Return
    EndIf
    Float current = LevelBase(level, scale) + progress
    If current == baseline
        baselineLevel = level
        candidateLevel = -1
        milkingDone = False
        Return
    EndIf
    If level != candidateLevel || progress != candidateProgress
        candidateLevel = level
        candidateProgress = progress
        candidateSince = Utility.GetCurrentRealTime()
        Return
    EndIf
    candidateLevel = -1
    milkingDone = False
    If current < baseline
        baseline = current
        baselineLevel = level
        TraceState("REBASE external progress loss")
        Return
    EndIf
    ; Always subtract exactly one from the observed current level. An old saved
    ; baseline or an external debug level change must never cause a larger drop.
    Int newLevel = level
    If newLevel > 0
        newLevel -= 1
    EndIf
    If !active || Utility.GetCurrentGameTime() >= expiresAt \
        || milkController.TimesMilkedMult != scale \
        || (StorageUtil.GetFloatValue(playerActor, "MME.MilkMaid.Level") as Int) != level \
        || StorageUtil.GetFloatValue(playerActor, progressKey) != progress
        TraceState("DEFER state changed before write")
        Return
    EndIf
    ; Clear this session's earned progress: keeping overflow would immediately
    ; level the maid back up in MME. Never subtract an unbounded continuous delta.
    StorageUtil.SetFloatValue(playerActor, progressKey, 0.0)
    If newLevel != level
        MME_Storage.setMaidLevel(playerActor, newLevel)
    EndIf
    TraceState("DECREASE baseline=" + baselineLevel + " observed=" + level + " target=" + newLevel)
    If level > 0
        Debug.Notification("Your breasts feel lighter. Milk maid level decreased by 1.")
    EndIf
    baseline = LevelBase(newLevel, scale)
    baselineLevel = newLevel
EndFunction
