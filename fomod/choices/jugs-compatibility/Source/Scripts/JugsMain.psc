Scriptname JugsMain extends Quest Conditional

SexLabFramework Property SexLab Auto
Actor Property PlayerRef Auto
Faction Property JugsFaction Auto
Faction Property JugsMilkMaidFaction Auto
Form[] Property EquipedItems Auto
Form[] Property NPCEquipedItems Auto
ReferenceAlias Property Alias_Follower Auto
ReferenceAlias Property Alias_Player Auto
Faction Property SexLabAnimatingFaction Auto

sgo_QuestController SGO2
dcc_sgo_QuestController SGO3
Actor[] givers
Actor[] receivers
Int numParticipants

Event OnInit()
    If PlayerRef != None && JugsFaction != None && !PlayerRef.IsInFaction(JugsFaction)
        PlayerRef.AddToFaction(JugsFaction)
    EndIf
    Debug.Notification("JUGs is loaded")
    If PlayerRef != None
        Debug.Notification(PlayerRef.GetLeveledActorBase().GetName() + " is in JUGs!")
    EndIf
EndEvent

Function ResetMods()
    SGO2 = None
    SGO3 = None
    givers = new Actor[4]
    receivers = new Actor[4]
    numParticipants = 0
    UnregisterForUpdate()
    MMELog.MasterDiagnostic("[MME Extensions JUGS] milk queue reset")
EndFunction

Function SetSGO2()
    SGO2 = Game.GetFormFromFile(0x12C6, "soulgem-oven.esp") as sgo_QuestController
    If SGO2 == None
        MMELog.Alarm("[MME Extensions JUGS] Soulgem Oven II detected but controller resolution failed")
    EndIf
EndFunction

Function SetSGO3()
    SGO3 = Game.GetFormFromFile(0x0D62, "dcc-soulgem-oven-000.esm") as dcc_sgo_QuestController
    If SGO3 == None
        MMELog.Alarm("[MME Extensions JUGS] Soulgem Oven III detected but controller resolution failed")
    EndIf
EndFunction

Function JugsSGOMilker(Actor giver, Actor receiver)
    If SGO2 == None && SGO3 == None
        MMELog.MasterDiagnostic("[MME Extensions JUGS] SGO transfer skipped: no supported Soulgem Oven controller")
        Return
    EndIf
    If giver == None || receiver == None || giver == receiver
        MMELog.Alarm("[MME Extensions JUGS] SGO transfer rejected: invalid giver or receiver")
        Return
    EndIf
    If !givers || !receivers || givers.Length != receivers.Length
        MMELog.Alarm("[MME Extensions JUGS] SGO queue was invalid and has been rebuilt")
        givers = new Actor[4]
        receivers = new Actor[4]
        numParticipants = 0
    EndIf

    Int i = 0
    While i < numParticipants
        If givers[i] == giver && receivers[i] == receiver
            MMELog.MasterDiagnostic("[MME Extensions JUGS] duplicate SGO pair ignored | giver=" + giver.GetDisplayName() + " | receiver=" + receiver.GetDisplayName())
            Return
        EndIf
        i += 1
    EndWhile

    If numParticipants >= givers.Length
        MMELog.Alarm("[MME Extensions JUGS] SGO queue full; pair rejected | giver=" + giver.GetDisplayName() + " | receiver=" + receiver.GetDisplayName())
        Return
    EndIf

    givers[numParticipants] = giver
    receivers[numParticipants] = receiver
    numParticipants += 1
    UnregisterForUpdate()
    RegisterForSingleUpdate(1.0)
    MMELog.MasterDiagnostic("[MME Extensions JUGS] SGO pair queued | giver=" + giver.GetDisplayName() + " | receiver=" + receiver.GetDisplayName() + " | count=" + numParticipants)
EndFunction

Event OnUpdate()
    If numParticipants <= 0
        UnregisterForUpdate()
        Return
    EndIf

    Int i = 0
    While i < numParticipants
        Actor giver = givers[i]
        Actor receiver = receivers[i]
        Bool removed = False

        If giver == None || receiver == None
            RemoveActors(i)
            removed = True
            MMELog.Alarm("[MME Extensions JUGS] invalid SGO queue entry removed")
        ElseIf SexLabAnimatingFaction == None || !giver.IsInFaction(SexLabAnimatingFaction) || !receiver.IsInFaction(SexLabAnimatingFaction)
            RemoveActors(i)
            removed = True
            MMELog.MasterDiagnostic("[MME Extensions JUGS] SGO pair completed | giver=" + giver.GetDisplayName() + " | receiver=" + receiver.GetDisplayName())
        ElseIf SGO2 != None
            If SGO2.GetMilkCount(giver) >= 1
                SGO2.GiveMilk(giver, receiver, 1, False)
                Utility.Wait(3.0)
            Else
                RemoveActors(i)
                removed = True
                MMELog.MasterDiagnostic("[MME Extensions JUGS] SGO2 pair removed: giver has no milk | giver=" + giver.GetDisplayName())
            EndIf
        ElseIf SGO3 != None
            If SGO3.ActorMilkGetCount(giver) >= 1
                SGO3.ActorMilkGiveTo(giver, receiver, 1)
                Utility.Wait(3.0)
            Else
                RemoveActors(i)
                removed = True
                MMELog.MasterDiagnostic("[MME Extensions JUGS] SGO3 pair removed: giver has no milk | giver=" + giver.GetDisplayName())
            EndIf
        Else
            RemoveActors(i)
            removed = True
            MMELog.Alarm("[MME Extensions JUGS] SGO controller disappeared while processing queue")
        EndIf

        If !removed
            i += 1
        EndIf
    EndWhile

    If numParticipants > 0
        RegisterForSingleUpdate(Utility.RandomFloat(3.0, 5.0))
    Else
        UnregisterForUpdate()
    EndIf
EndEvent

Function RemoveActors(Int position)
    If position < 0 || position >= numParticipants
        MMELog.Alarm("[MME Extensions JUGS] refused invalid SGO queue removal index=" + position + " | count=" + numParticipants)
        Return
    EndIf

    Int lastActive = numParticipants - 1
    If position != lastActive
        givers[position] = givers[lastActive]
        receivers[position] = receivers[lastActive]
    EndIf
    givers[lastActive] = None
    receivers[lastActive] = None
    numParticipants -= 1
EndFunction
