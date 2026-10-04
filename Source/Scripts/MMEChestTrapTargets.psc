Scriptname MMEChestTrapTargets Hidden

; One bounded same-cell scan shared by every treasure-chest outcome.
; mode: 1 timed armor, 2 new Milk Maid, 3 forced milk drink.
Actor Function SelectTarget(Actor center, Int mode, Float radius = 1500.0) Global
    If center == None
        Return None
    EndIf
    Actor[] candidates = new Actor[128]
    Int count = 0
    Actor playerActor = Game.GetPlayer()
    If IsEligible(playerActor, center, mode, radius)
        candidates[count] = playerActor
        count += 1
    EndIf
    Cell currentCell = center.GetParentCell()
    If currentCell != None
        Int refs = currentCell.GetNumRefs(43)
        Int index = 0
        While index < refs && count < 128
            Actor candidate = currentCell.GetNthRef(index, 43) as Actor
            If candidate != None && candidate != playerActor && IsEligible(candidate, center, mode, radius)
                candidates[count] = candidate
                count += 1
            EndIf
            index += 1
        EndWhile
    EndIf
    Trace("scan | mode=" + mode + " | center=" + GetActorName(center) + " | eligible allied females=" + count)
    If count <= 0
        Return None
    EndIf
    Actor selected = candidates[Utility.RandomInt(0, count - 1)]
    Trace("selected | mode=" + mode + " | actor=" + GetActorName(selected))
    Return selected
EndFunction

Bool Function IsEligible(Actor candidate, Actor center, Int mode, Float radius) Global
    If !MMEForcedMilkDrink.IsEligibleActor(candidate) || center == None \
        || candidate.GetParentCell() != center.GetParentCell() || center.GetDistance(candidate) > radius
        Return False
    EndIf
    ActorBase baseInfo = candidate.GetLeveledActorBase()
    If baseInfo == None || baseInfo.GetSex() != 1
        Return False
    EndIf
    Actor playerActor = Game.GetPlayer()
    If candidate != playerActor && !candidate.IsPlayerTeammate() && candidate.GetRelationshipRank(playerActor) < 1
        Return False
    EndIf
    If candidate.IsHostileToActor(playerActor)
        Return False
    EndIf
    If mode == 1
        Return !MMETimedArmorLock.IsLocked(candidate)
    ElseIf mode == 2
        Return !MMEExtensionsAPI.IsMilkMaid(candidate)
    EndIf
    Return True
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Chest Targets] " + detail)
EndFunction
