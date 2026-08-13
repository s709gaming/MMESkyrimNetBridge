Scriptname MMEAlertsController extends Quest

String SettingsFile = "/MMEAlerts/Settings"
String StateKey = "MMEAlerts.CapacityState"

Event OnInit()
    InitializeController()
EndEvent

Function InitializeController()
    UnregisterForUpdate()
    Spell monitorAbility = Game.GetFormFromFile(0x000805, "MMEAlert.esp") as Spell
    If monitorAbility != None
        ; Recreate the active effect once when its drink-tracker implementation
        ; changes. Existing saves otherwise keep the pre-tracker effect instance.
        If JsonUtil.GetIntValue(SettingsFile, "playerDrinkMonitorVersion", 0) < 11
            If Game.GetPlayer().HasSpell(monitorAbility)
                Game.GetPlayer().RemoveSpell(monitorAbility)
            EndIf
            Game.GetPlayer().AddSpell(monitorAbility, False)
            JsonUtil.SetIntValue(SettingsFile, "playerDrinkMonitorVersion", 11)
            JsonUtil.Save(SettingsFile, False)
        ElseIf !Game.GetPlayer().HasSpell(monitorAbility)
            Game.GetPlayer().AddSpell(monitorAbility, False)
        EndIf
    EndIf
    UpdatePolling()
EndFunction

Function UpdatePolling()
    UnregisterForUpdate()
    If JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1) == 1
        RegisterForSingleUpdate(JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 5.0))
    EndIf
EndFunction

Event OnUpdate()
    If JsonUtil.GetIntValue(SettingsFile, "enableCapacityPolling", 1) != 1
        Return
    EndIf
    ScanNearbyMilkMaids()
    RegisterForSingleUpdate(JsonUtil.GetFloatValue(SettingsFile, "pollingInterval", 5.0))
EndEvent

Function RefreshCapacity(String reason = "event")
    ScanNearbyMilkMaids()
EndFunction

Bool Function IsMMEMilkMaid(Actor candidate)
    If candidate == None || candidate.IsDead() || candidate.IsDisabled()
        Return False
    EndIf
    Return StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.Level")
EndFunction

String Function GetActorName(Actor candidate)
    String actorName = candidate.GetDisplayName()
    If actorName == ""
        ActorBase baseActor = candidate.GetLeveledActorBase()
        If baseActor != None
            actorName = baseActor.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "This Milk Maid"
    EndIf
    Return actorName
EndFunction

String Function EvaluateMilkMaid(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        Return ""
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return GetActorName(candidate) + ": invalid maximum"
    EndIf
    Float current = MME_Storage.getMilkCurrent(candidate)
    If current >= maximum
        Return GetActorName(candidate) + ": full (100% or above)"
    ElseIf current >= maximum * 0.5
        Return GetActorName(candidate) + ": 50% or above"
    EndIf
    Return GetActorName(candidate) + ": below 50%"
EndFunction

Function ShowDebugCapacitySnapshot()
    Actor playerActor = Game.GetPlayer()
    String report = EvaluateMilkMaid(playerActor)
    Cell currentCell = playerActor.GetParentCell()
    If currentCell != None
        Int count = currentCell.GetNumRefs(43)
        Int i = 0
        While i < count
            Actor candidate = currentCell.GetNthRef(i, 43) as Actor
            If candidate != None && candidate != playerActor && candidate.Is3DLoaded() && playerActor.GetDistance(candidate) <= 2000.0
                String result = EvaluateMilkMaid(candidate)
                If result != ""
                    If report != ""
                        report = report + " | "
                    EndIf
                    report = report + result
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
EndFunction

; Returns 0 for no crossing, 1 for crossing 50%, and 2 for crossing 100%.
; First observation establishes a baseline and never produces a reaction.
Int Function UpdateCapacityState(Actor candidate)
    If !IsMMEMilkMaid(candidate)
        StorageUtil.UnsetIntValue(candidate, StateKey)
        Return 0
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        Return 0
    EndIf
    Float current = MME_Storage.getMilkCurrent(candidate)
    Int currentState = 0
    If current >= maximum
        currentState = 2
    ElseIf current >= maximum * 0.5
        currentState = 1
    EndIf
    Int previousState = StorageUtil.GetIntValue(candidate, StateKey, -1)
    StorageUtil.SetIntValue(candidate, StateKey, currentState)
    If previousState < 0
        Return 0
    ElseIf previousState < 2 && currentState == 2
        Return 2
    ElseIf previousState == 0 && currentState == 1
        Return 1
    EndIf
    Return 0
EndFunction

Function ProcessActor(Actor candidate, Actor[] reactionActors, Int[] reactionKinds)
    If candidate == None || !candidate.Is3DLoaded() || !IsMMEMilkMaid(candidate)
        Return
    EndIf
    Int crossing = UpdateCapacityState(candidate)
    If crossing == 0
        Return
    EndIf
    Int slot = reactionKinds.Find(0)
    If slot >= 0
        reactionActors[slot] = candidate
        reactionKinds[slot] = crossing
    EndIf
    If JsonUtil.GetIntValue(SettingsFile, "enableCapacityNotifications", 1) == 1
        If crossing == 2
            Debug.Notification(GetActorName(candidate) + " is completely milky and teetering on a boobgasm!")
        Else
            Debug.Notification(GetActorName(candidate) + " is now half-milky and building nicely!")
        EndIf
    EndIf
EndFunction

Function ScanNearbyMilkMaids()
    Actor playerActor = Game.GetPlayer()
    Actor[] reactionActors = new Actor[128]
    Int[] reactionKinds = new Int[128]
    ProcessActor(playerActor, reactionActors, reactionKinds)
    Cell currentCell = playerActor.GetParentCell()
    If currentCell != None
        Int count = currentCell.GetNumRefs(43)
        Int i = 0
        While i < count
            Actor candidate = currentCell.GetNthRef(i, 43) as Actor
            If candidate != None && candidate != playerActor && candidate.Is3DLoaded() && playerActor.GetDistance(candidate) <= 2000.0
                ProcessActor(candidate, reactionActors, reactionKinds)
            EndIf
            i += 1
        EndWhile
    EndIf

    ; One sound per scan. A full crossing has priority over a half crossing.
    Actor soundActor = None
    Int soundKind = 0
    Int j = 0
    While j < reactionKinds.Length
        If reactionKinds[j] > soundKind
            soundKind = reactionKinds[j]
            soundActor = reactionActors[j]
        EndIf
        j += 1
    EndWhile
    If soundActor != None && JsonUtil.GetIntValue(SettingsFile, "enableCapacityReactions", 1) == 1
        PlayCapacityReaction(soundActor, soundKind)
    EndIf
EndFunction

Function PlayCapacityReaction(Actor sourceActor, Int crossing)
    If JsonUtil.GetIntValue(SettingsFile, "enableReactionSounds", 1) != 1
        Return
    EndIf
    Int localFormID = 0x000855 ; Medium SOUN marker
    If crossing == 2
        localFormID = 0x000856 ; Hot SOUN marker
    EndIf
    Sound reaction = Game.GetFormFromFile(localFormID, "MMEAlert.esp") as Sound
    If reaction == None
        Debug.Trace("[MMEAlert] capacity sound marker did not resolve: " + localFormID)
        Return
    EndIf
    Int instance = reaction.Play(sourceActor)
    If instance > 0
        Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(SettingsFile, "reactionSoundVolume", 100.0) / 100.0)
    Else
        Debug.Trace("[MMEAlert] capacity Sound.Play returned " + instance)
    EndIf
EndFunction
