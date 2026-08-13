Scriptname MMEAlertsController extends Quest

; Nearby discovery remains stateless. One small StorageUtil integer on each actor
; remembers the previous capacity band so a real 50% crossing can be recognized.

Event OnInit()
    InitializeController()
EndEvent

Function InitializeController()
    UnregisterForUpdate()
    UnregisterForModEvent("MME_MilkCycleComplete")
    RegisterForModEvent("MME_MilkCycleComplete", "OnMMEMilkCycleComplete")

    Spell monitorAbility = Game.GetFormFromFile(0x000805, "MMEAlert.esp") as Spell
    If monitorAbility != None && !Game.GetPlayer().HasSpell(monitorAbility)
        Game.GetPlayer().AddSpell(monitorAbility, False)
    EndIf
    Debug.Trace("[MMEAlert] controller ready; capacity threshold detection disabled")
EndFunction

Function UpdatePolling()
    ; Production capacity polling is deliberately disabled.
    UnregisterForUpdate()
EndFunction

Function RefreshCapacity(String reason = "event")
    ; Placeholder retained so the player monitor remains safe to compile.
    Debug.Trace("[MMEAlert] ignored capacity refresh while detector is disabled: " + reason)
EndFunction

Bool Function IsMMEMilkMaid(Actor candidate)
    If candidate == None || candidate.IsDead() || candidate.IsDisabled()
        Return False
    EndIf

    ; MME_Storage.initializeActor creates this key during enrollment, including
    ; for level-zero Maids, and deregisterActor removes it during Maid removal.
    Return StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.Level")
EndFunction

String Function GetDebugActorName(Actor candidate)
    If candidate == None
        Return "<invalid actor>"
    EndIf

    String actorName = candidate.GetDisplayName()
    If actorName == ""
        ActorBase baseActor = candidate.GetLeveledActorBase()
        If baseActor != None
            actorName = baseActor.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "<unnamed actor " + candidate + ">"
    EndIf
    Return actorName
EndFunction

String Function EvaluateMilkMaid(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        Return ""
    EndIf

    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return ""
    EndIf

    Float current = MME_Storage.getMilkCurrent(candidate)
    String capacity = "below 50%"
    If current >= maximum
        capacity = "full (100%)"
    ElseIf current >= maximum * 0.5
        capacity = "50% or above"
    EndIf
    Return GetDebugActorName(candidate) + ": " + capacity
EndFunction

Bool Function UpdateCapacityState(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        StorageUtil.UnsetIntValue(candidate, "MMEAlerts.CapacityState")
        Return False
    EndIf

    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return False
    EndIf

    Float current = MME_Storage.getMilkCurrent(candidate)
    Int currentState = 0
    If current >= maximum
        currentState = 2
    ElseIf current >= maximum * 0.5
        currentState = 1
    EndIf

    Int previousState = StorageUtil.GetIntValue(candidate, "MMEAlerts.CapacityState", -1)
    StorageUtil.SetIntValue(candidate, "MMEAlerts.CapacityState", currentState)

    ; First sighting is a silent baseline. Any later jump from below half to at
    ; least half is a crossing, including a large jump directly to full.
    Return previousState == 0 && currentState >= 1
EndFunction

Function PlayHalfCapacityReaction(Actor sourceActor)
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableReactionSounds", 1) != 1
        Return
    EndIf

    ; SSEEdit-built Voice Slot 01 mild pool: 16 randomized WAV files.
    ; This must be the SOUN marker, not its linked SNDR descriptor.
    Sound reaction = Game.GetFormFromFile(0x000854, "MMEAlert.esp") as Sound
    If reaction == None
        Debug.Trace("[MMEAlert] 50% crossing detected, but mild sound marker 000854 did not resolve")
        Return
    EndIf

    Int instance = reaction.Play(sourceActor)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue("/MMEAlerts/Settings", "reactionSoundVolume", 100.0) / 100.0)
    Else
        Debug.Trace("[MMEAlert] mild pool 50% Sound.Play returned " + instance)
    EndIf
EndFunction

Function ShowDebugCapacitySnapshot()
    ; One stateless batch: recognize, evaluate, report, then forget everything.
    Actor playerActor = Game.GetPlayer()
    String report = ""
    String crossingReport = ""
    Actor soundActor = None

    String playerResult = EvaluateMilkMaid(playerActor)
    If playerResult != ""
        report = playerResult
        If UpdateCapacityState(playerActor)
            crossingReport = GetDebugActorName(playerActor)
            soundActor = playerActor
        EndIf
    Else
        StorageUtil.UnsetIntValue(playerActor, "MMEAlerts.CapacityState")
    EndIf

    Cell currentCell = playerActor.GetParentCell()
    If currentCell != None
        ; SKSE form type 43 is Actor. Current-cell enumeration is sufficient for
        ; this recognition test and avoids touching MME's unreliable quest array.
        Int count = currentCell.GetNumRefs(43)
        Int i = 0
        While i < count
            Actor candidate = currentCell.GetNthRef(i, 43) as Actor
            If candidate != None && candidate != playerActor && candidate.Is3DLoaded() && playerActor.GetDistance(candidate) <= 2000.0
                If IsMMEMilkMaid(candidate)
                    String result = EvaluateMilkMaid(candidate)
                    If result != ""
                        If report != ""
                            report = report + " | "
                        EndIf
                        report = report + result
                        If UpdateCapacityState(candidate)
                            If crossingReport != ""
                                crossingReport = crossingReport + ", "
                            EndIf
                            crossingReport = crossingReport + GetDebugActorName(candidate)
                            If soundActor == None
                                soundActor = candidate
                            EndIf
                        EndIf
                    EndIf
                Else
                    StorageUtil.UnsetIntValue(candidate, "MMEAlerts.CapacityState")
                EndIf
            EndIf
            i += 1
        EndWhile
    EndIf

    If report == ""
        Debug.Notification("MME Alerts DEBUG - no evaluable Milk Maids nearby.")
    Else
        Debug.Notification("MME Alerts DEBUG - " + report)
    EndIf

    If crossingReport != "" && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableCapacityReactions", 1) == 1
        Debug.Notification("MME Alerts - " + crossingReport + " crossed 50% milk capacity.")
        PlayHalfCapacityReaction(soundActor)
    EndIf
EndFunction

Event OnMMEMilkCycleComplete(String eventName, String stringArg, Float numberArg, Form sender)
    Debug.Trace("[MMEAlert] received MME_MilkCycleComplete; stateless debug evaluation remains timer-driven")
EndEvent
