Scriptname JugsPlayerAlias extends ReferenceAlias

JugsMain Property jugsMainQuest Auto
SexLabFramework Property SexLab Auto
Actor Property PlayerRef Auto

Event OnInit()
    MMELog.MasterDiagnostic("[MME Extensions JUGS] player alias initialized")
    OnPlayerLoadGame()
EndEvent

Event OnPlayerLoadGame()
    If jugsMainQuest == None
        MMELog.Alarm("[MME Extensions JUGS] player-load maintenance failed: JugsMain property is missing")
        Return
    EndIf

    jugsMainQuest.ResetMods()
    If Game.GetModByName("soulgem-oven.esp") != 255
        jugsMainQuest.SetSGO2()
    EndIf
    If Game.GetModByName("dcc-soulgem-oven-000.esm") != 255
        jugsMainQuest.SetSGO3()
    EndIf

    UnregisterForModEvent("HookAnimationStart")
    UnregisterForModEvent("AnimationEnding")
    RegisterForModEvent("HookAnimationStart", "HookAnimations")
    RegisterForModEvent("AnimationEnding", "OnJugsAnimationEnding")
    MMELog.MasterDiagnostic("[MME Extensions JUGS] animation listeners registered: start + ending")
EndEvent

Event HookAnimations(Int threadID, Bool hasPlayer)
    If SexLab == None || SexLab.GetState() != "Enabled"
        MMELog.MasterDiagnostic("[MME Extensions JUGS] animation hook ignored: SexLab unavailable | thread=" + threadID, 1)
        Return
    EndIf

    sslBaseAnimation selectedAnimation = SexLab.HookAnimation(threadID)
    If selectedAnimation == None || !selectedAnimation.HasTag("BreastFeeding")
        Return
    EndIf

    Actor[] participants = SexLab.HookActors(threadID)
    If !participants || participants.Length < 2
        MMELog.Alarm("[MME Extensions JUGS] breastfeeding hook returned fewer than two participants | thread=" + threadID)
        Return
    EndIf

    Actor firstActor = participants[0]
    Actor secondActor = participants[1]
    If firstActor == None || secondActor == None
        MMELog.Alarm("[MME Extensions JUGS] breastfeeding hook returned a missing participant | thread=" + threadID)
        Return
    EndIf
    If !MMEJugsSafety.IsOwnedParticipant(firstActor, threadID) || !MMEJugsSafety.IsOwnedParticipant(secondActor, threadID)
        Return
    EndIf
    If jugsMainQuest == None
        MMELog.Alarm("[MME Extensions JUGS] breastfeeding hook cannot reach JugsMain | thread=" + threadID)
        Return
    EndIf

    ; P+ documents returned position order as unspecified. The exact actors and
    ; semantic roles captured by our guarded starter are authoritative here.
    Actor giver = firstActor
    Actor receiver = secondActor
    String firstRole = MMEJugsSafety.GetOwnedRole(firstActor, threadID)
    String secondRole = MMEJugsSafety.GetOwnedRole(secondActor, threadID)
    If firstRole == "drinker" && secondRole == "source"
        giver = secondActor
        receiver = firstActor
    ElseIf firstRole != "source" || secondRole != "drinker"
        MMELog.Alarm("[MME Extensions JUGS] owned breastfeeding thread has corrupt role markers | thread=" + threadID)
        Return
    EndIf

    ActorBase giverBase = giver.GetLeveledActorBase()
    If giverBase == None || giverBase.GetSex() != 1
        MMELog.Alarm("[MME Extensions JUGS] breastfeeding hook rejected an unresolved milk-source role | first=" + firstActor.GetDisplayName() + " | second=" + secondActor.GetDisplayName() + " | thread=" + threadID)
        Return
    EndIf

    Debug.Notification("JUGs: " + receiver.GetDisplayName() + " is milking " + giver.GetDisplayName())
    MMELog.MasterDiagnostic("[MME Extensions JUGS] breastfeeding pair observed | raw0=" + firstActor.GetDisplayName() + " | raw1=" + secondActor.GetDisplayName() + " | giver=" + giver.GetDisplayName() + " | receiver=" + receiver.GetDisplayName() + " | thread=" + threadID)
    jugsMainQuest.JugsSGOMilker(giver, receiver)
EndEvent

Event OnJugsAnimationEnding(String eventName, String threadIDText, Float numArg, Form sender)
    Int threadID = threadIDText as Int
    If SexLab == None
        Return
    EndIf
    Actor[] participants = SexLab.HookActors(threadID)
    If !participants || participants.Length < 2
        Return
    EndIf

    Actor firstActor = participants[0]
    Actor secondActor = participants[1]
    If !MMEJugsSafety.IsOwnedParticipant(firstActor, threadID) || !MMEJugsSafety.IsOwnedParticipant(secondActor, threadID)
        Return
    EndIf

    Actor milkSource = None
    Actor drinker = None
    If MMEJugsSafety.GetOwnedRole(firstActor, threadID) == "source"
        milkSource = firstActor
    ElseIf MMEJugsSafety.GetOwnedRole(firstActor, threadID) == "drinker"
        drinker = firstActor
    EndIf
    If MMEJugsSafety.GetOwnedRole(secondActor, threadID) == "source"
        milkSource = secondActor
    ElseIf MMEJugsSafety.GetOwnedRole(secondActor, threadID) == "drinker"
        drinker = secondActor
    EndIf

    MMEJugsSafety.ClearOwnedParticipant(firstActor, threadID)
    MMEJugsSafety.ClearOwnedParticipant(secondActor, threadID)
    If milkSource == None || drinker == None || milkSource == drinker
        MMELog.Alarm("[MME Extensions JUGS] completed owned thread has invalid role state | thread=" + threadID)
        Return
    EndIf

    MMELog.MasterDiagnostic("[MME Extensions JUGS] completed pair handed to breastfeeding API | source=" + milkSource.GetDisplayName() + " | drinker=" + drinker.GetDisplayName() + " | thread=" + threadID)
    Bool accepted = MMEExtensionsAPI.CompleteBreastfeedingMilkShare(milkSource, drinker, "JUGS/SexLab", threadID)
    If accepted
        MMELog.MasterDiagnostic("[MME Extensions JUGS] breastfeeding milk effects completed | thread=" + threadID)
    Else
        MMELog.MasterDiagnostic("[MME Extensions JUGS] breastfeeding milk effects skipped or rejected | thread=" + threadID, 1)
    EndIf
EndEvent
