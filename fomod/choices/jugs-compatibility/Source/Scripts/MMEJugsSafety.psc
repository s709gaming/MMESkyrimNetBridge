Scriptname MMEJugsSafety Hidden

String Function GetThreadKey() Global
    Return "MME.Extensions.JUGS.Thread"
EndFunction

String Function GetRoleKey() Global
    Return "MME.Extensions.JUGS.Role"
EndFunction

Bool Function TryStart(SexLabFramework sexLab, Actor[] actors, sslBaseAnimation[] animations, String routeName) Global
    String prefix = "[MME Extensions JUGS] "

    If sexLab == None
        MMELog.MasterDiagnostic(prefix + "scene rejected: SexLab API unavailable | route=" + routeName, 1)
        Return False
    EndIf
    If sexLab.GetState() != "Enabled"
        MMELog.MasterDiagnostic(prefix + "scene rejected: SexLab is not ready | route=" + routeName + " | state=" + sexLab.GetState(), 1)
        Return False
    EndIf
    If !actors || actors.Length < 2
        MMELog.Alarm(prefix + "scene rejected: malformed actor array | route=" + routeName)
        Return False
    EndIf

    Int i = 0
    While i < actors.Length
        Actor candidate = actors[i]
        If candidate == None
            MMELog.Alarm(prefix + "scene rejected: missing actor at index " + i + " | route=" + routeName)
            Return False
        EndIf
        If candidate.IsDead() || candidate.IsDisabled() || candidate.IsDeleted()
            MMELog.MasterDiagnostic(prefix + "scene rejected: unavailable actor " + candidate.GetDisplayName() + " | route=" + routeName, 1)
            Return False
        EndIf
        If !sexLab.IsValidActor(candidate)
            MMELog.MasterDiagnostic(prefix + "scene rejected: SexLab does not accept " + candidate.GetDisplayName() + " | route=" + routeName, 1)
            Return False
        EndIf
        i += 1
    EndWhile

    If !animations || animations.Length < 1
        MMELog.MasterDiagnostic(prefix + "scene rejected: animation lookup returned no matches | route=" + routeName, 1)
        Return False
    EndIf

    Bool foundAnimation = False
    i = 0
    While i < animations.Length
        If animations[i] != None
            foundAnimation = True
        EndIf
        i += 1
    EndWhile
    If !foundAnimation
        MMELog.MasterDiagnostic(prefix + "scene rejected: requested animation is not registered | route=" + routeName, 1)
        Return False
    EndIf

    Int threadID = sexLab.StartSex(actors, animations)
    If threadID < 0
        MMELog.MasterDiagnostic(prefix + "scene rejected by SexLab | route=" + routeName + " | result=" + threadID, 1)
        Return False
    EndIf

    ; Mark the exact accepted thread before its start hook is dispatched. The
    ; listener can then distinguish JUGS-owned scenes from unrelated animations
    ; carrying the same broad BreastFeeding tag.
    StorageUtil.SetIntValue(actors[0], GetThreadKey(), threadID)
    StorageUtil.SetStringValue(actors[0], GetRoleKey(), "source")
    StorageUtil.SetIntValue(actors[1], GetThreadKey(), threadID)
    StorageUtil.SetStringValue(actors[1], GetRoleKey(), "drinker")
    MMELog.MasterDiagnostic(prefix + "scene accepted | route=" + routeName + " | thread=" + threadID)
    Return True
EndFunction

Bool Function IsOwnedParticipant(Actor participant, Int threadID) Global
    Return participant != None && StorageUtil.GetIntValue(participant, GetThreadKey(), -1) == threadID
EndFunction

String Function GetOwnedRole(Actor participant, Int threadID) Global
    If !IsOwnedParticipant(participant, threadID)
        Return ""
    EndIf
    Return StorageUtil.GetStringValue(participant, GetRoleKey(), "")
EndFunction

Function ClearOwnedParticipant(Actor participant, Int threadID) Global
    If IsOwnedParticipant(participant, threadID)
        StorageUtil.UnsetIntValue(participant, GetThreadKey())
        StorageUtil.UnsetStringValue(participant, GetRoleKey())
    EndIf
EndFunction
