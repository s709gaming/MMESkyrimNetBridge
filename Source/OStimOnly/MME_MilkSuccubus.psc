Scriptname MME_MilkSuccubus extends ActiveMagicEffect Hidden

Event OnEffectStart(Actor akTarget, Actor akCaster)
    MMELog.MasterDiagnostic("[MME Extensions Succubus] entry | actor=" + akTarget)
    If akTarget == None
        ReportFailure(akTarget, "invalid target")
        Return
    EndIf
    MilkQUEST MilkQ = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If MilkQ == None
        ReportFailure(akTarget, "required MME quest missing")
        Return
    EndIf
    Actor PlayerRef = Game.GetPlayer()
    If PlayerRef == None
        ReportFailure(akTarget, "player reference missing")
        Return
    EndIf
    ; Preserve original transformation ownership and event semantics.
    If akTarget == PlayerRef && MilkQ.MilkSuccubusTransform
        If MilkQ.Plugin_PSQ && MilkQ.PSQ != None
            If !(StorageUtil.GetIntValue(akTarget, "PSQ_PlayerIsSuccubus") > 0)
                MilkQ.PSQ.BecomeSuccubus()
            EndIf
        EndIf
        SendModEvent("HoSLDD_GivePlayerPowers")
        If !(StorageUtil.GetIntValue(akTarget, "Angrim_iSuccubusCurse") > 0)
            SendModEvent("HoSLDD_GivePlayerPowers")
        EndIf
    EndIf
    If MilkQ.SLA == None || Quest.GetQuest("sla_Framework") == None
        MMELog.MasterDiagnostic("[MME Extensions Succubus] skip arousal | actor=" + akTarget + " | optional arousal framework unavailable")
        Return
    EndIf
    Cell scanCell = PlayerRef.GetParentCell()
    If scanCell == None
        MMELog.MasterDiagnostic("[MME Extensions Succubus] skip scan | actor=" + akTarget + " | player cell unavailable")
        Return
    EndIf
    Int count = scanCell.GetNumRefs(43)
    Int index = 0
    Int affected = 0
    While index < count
        Actor candidate = scanCell.GetNthRef(index, 43) as Actor
        If candidate != None && candidate.HasLOS(akTarget)
            MilkQ.SLA.UpdateActorExposure(candidate, 25)
            affected += 1
        EndIf
        index += 1
    EndWhile
    MMELog.MasterDiagnostic("[MME Extensions Succubus] complete | actor=" + akTarget + " | scanned=" + count + " | arousal targets=" + affected)
EndEvent

Function ReportFailure(Actor target, String reason)
    String failureKey = "MMEExtensions.Succubus.Failure"
    Float now = Utility.GetCurrentRealTime()
    Float previous = StorageUtil.GetFloatValue(target, failureKey, -1000.0)
    If now < previous || now - previous >= 60.0
        StorageUtil.SetFloatValue(target, failureKey, now)
        MMELog.Alarm("[MME Extensions Succubus] operation=effect start | actor=" + target + " | reason=" + reason)
    EndIf
EndFunction

