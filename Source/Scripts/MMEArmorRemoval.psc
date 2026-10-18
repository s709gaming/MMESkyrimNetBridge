Scriptname MMEArmorRemoval Hidden

String Function GetPendingActorsKey() Global
    Return "MMEExtensions.ArmorRemoval.PendingActors"
EndFunction

String Function GetPendingArmorKey() Global
    Return "MMEExtensions.ArmorRemoval.PendingArmor"
EndFunction

String Function GetPendingDeadlineKey() Global
    Return "MMEExtensions.ArmorRemoval.PendingDeadline"
EndFunction

Float Function GetVerificationDelay() Global
    Return 3.0
EndFunction

Bool Function ReleasePlayerArmor(String source = "Public API/Player Armor Removal") Global
    Return RequestActorRemoval(Game.GetPlayer(), source, False)
EndFunction

Int Function ReleaseNearbyNPCArmor(Float radius = 2000.0, String source = "Public API/NPC Armor Removal") Global
    Actor playerActor = Game.GetPlayer()
    If playerActor == None
        Alarm("nearby NPC removal could not resolve the player | source=" + source)
        Return 0
    EndIf
    If radius < 0.0
        radius = 0.0
    ElseIf radius > 10000.0
        radius = 10000.0
    EndIf
    Cell currentCell = playerActor.GetParentCell()
    If currentCell == None
        Alarm("nearby NPC removal could not resolve the player cell | source=" + source)
        Return 0
    EndIf

    Int accepted = 0
    Int refs = currentCell.GetNumRefs(43)
    Int index = 0
    While index < refs
        Actor candidate = currentCell.GetNthRef(index, 43) as Actor
        If candidate != None && candidate != playerActor && IsEligibleAlly(candidate, playerActor, radius)
            String failure = GetActorRemovalFailure(candidate, True)
            If failure == ""
                If RequestActorRemoval(candidate, source, True)
                    accepted += 1
                EndIf
            Else
                Trace("candidate skipped | actor=" + GetActorName(candidate) + " | reason=" + failure + " | source=" + source)
            EndIf
        EndIf
        index += 1
    EndWhile
    Trace("nearby NPC removal complete | accepted=" + accepted + " | radius=" + radius + " | source=" + source)
    Return accepted
EndFunction

Bool Function RequestActorRemoval(Actor target, String source = "Internal", Bool requireSafety = True) Global
    String failure = GetActorRemovalFailure(target, requireSafety)
    If failure != ""
        Trace("request rejected | actor=" + GetActorName(target) + " | reason=" + failure + " | source=" + source)
        Return False
    EndIf
    Armor targetArmor = GetRemovableArmor(target)
    Bool ownedLock = MMETimedArmorLock.IsLocked(target) && MMETimedArmorLock.GetLockedArmor(target) == targetArmor
    If ownedLock
        MMETimedArmorLock.ReleaseQuiet(target, source)
    Else
        target.UnequipItem(targetArmor, False, True)
    EndIf
    QueueVerification(target, targetArmor, source)
    Trace("removal accepted | actor=" + GetActorName(target) + " | armor=" + GetArmorName(targetArmor) + " | timed lock=" + ownedLock + " | source=" + source)
    Return True
EndFunction

String Function GetActorRemovalFailure(Actor target, Bool requireSafety = True) Global
    If target == None || target.IsDead() || target.IsDisabled()
        Return "actor unavailable"
    ElseIf !MMEForcedMilkDrink.IsEligibleActor(target)
        Return "not a loaded adult humanoid"
    EndIf
    If requireSafety
        MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
        String busyReason = MMEAnimationSafety.GetStartBlockReason(target, milkController, False)
        If busyReason != ""
            Return busyReason
        EndIf
    EndIf
    If GetRemovableArmor(target) == None
        Return "no supported Living, Parasite, or Dwemer body armor"
    EndIf
    Return ""
EndFunction

Armor Function GetRemovableArmor(Actor target) Global
    If target == None
        Return None
    EndIf
    Armor lockedArmor = MMETimedArmorLock.GetLockedArmor(target)
    If MMETimedArmorLock.IsLocked(target) && lockedArmor != None && target.IsEquipped(lockedArmor)
        Int lockedClass = MMETimedArmorLock.GetRegisteredArmorClass(lockedArmor)
        If lockedClass == 2 || lockedClass == 3 || lockedClass == 4
            Return lockedArmor
        EndIf
    EndIf
    Armor wornArmor = target.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = MMEArmorScript.ClassifyArmor(Quest.GetQuest("MME_MilkQUEST") as MilkQUEST, wornArmor, "armor-removal", target)
    If armorClass == 2 || armorClass == 3 || armorClass == 4
        Return wornArmor
    EndIf
    Return None
EndFunction

Bool Function IsEligibleAlly(Actor candidate, Actor playerActor, Float radius) Global
    Return candidate != None && playerActor != None \
        && candidate.GetParentCell() == playerActor.GetParentCell() \
        && playerActor.GetDistance(candidate) <= radius \
        && (candidate.IsPlayerTeammate() || candidate.GetRelationshipRank(playerActor) >= 1) \
        && !candidate.IsHostileToActor(playerActor)
EndFunction

Function QueueVerification(Actor target, Armor targetArmor, String source) Global
    StorageUtil.SetFormValue(target, GetPendingArmorKey(), targetArmor)
    StorageUtil.SetFloatValue(target, GetPendingDeadlineKey(), Utility.GetCurrentRealTime() + GetVerificationDelay())
    StorageUtil.SetStringValue(target, "MMEExtensions.ArmorRemoval.PendingSource", source)
    StorageUtil.FormListAdd(None, GetPendingActorsKey(), target, False)
    MMEAlertsController controller = Game.GetFormFromFile(0x000800, "MMEAlert.esp") as MMEAlertsController
    If controller != None
        controller.RefreshArmorRemovalScheduling()
    Else
        Alarm("controller unavailable; delayed verification could not be scheduled | actor=" + GetActorName(target))
    EndIf
EndFunction

Float Function GetNextVerificationDeadline() Global
    Float earliest = 0.0
    Int index = StorageUtil.FormListCount(None, GetPendingActorsKey()) - 1
    While index >= 0
        Actor target = StorageUtil.FormListGet(None, GetPendingActorsKey(), index) as Actor
        If target == None
            StorageUtil.FormListRemoveAt(None, GetPendingActorsKey(), index)
        Else
            Float deadline = StorageUtil.GetFloatValue(target, GetPendingDeadlineKey(), 0.0)
            If deadline > 0.0 && (earliest <= 0.0 || deadline < earliest)
                earliest = deadline
            EndIf
        EndIf
        index -= 1
    EndWhile
    Return earliest
EndFunction

Function ResolveDueVerifications(Float now) Global
    Int index = StorageUtil.FormListCount(None, GetPendingActorsKey()) - 1
    While index >= 0
        Actor target = StorageUtil.FormListGet(None, GetPendingActorsKey(), index) as Actor
        If target == None
            StorageUtil.FormListRemoveAt(None, GetPendingActorsKey(), index)
        ElseIf StorageUtil.GetFloatValue(target, GetPendingDeadlineKey(), 0.0) <= now
            Armor targetArmor = StorageUtil.GetFormValue(target, GetPendingArmorKey(), None) as Armor
            String source = StorageUtil.GetStringValue(target, "MMEExtensions.ArmorRemoval.PendingSource", "unknown")
            If targetArmor == None || !target.IsEquipped(targetArmor)
                Trace("removal verified | actor=" + GetActorName(target) + " | armor=" + GetArmorName(targetArmor) + " | source=" + source)
            Else
                Alarm("armor remains equipped after grace period | actor=" + GetActorName(target) + " | armor=" + GetArmorName(targetArmor) + " | source=" + source)
            EndIf
            ClearVerification(target)
        EndIf
        index -= 1
    EndWhile
EndFunction

Function HandleArmorUnequipped(Actor target, Armor targetArmor) Global
    If target != None && targetArmor != None && StorageUtil.GetFormValue(target, GetPendingArmorKey(), None) == targetArmor
        Trace("native unequip confirmed | actor=" + GetActorName(target) + " | armor=" + GetArmorName(targetArmor))
        ClearVerification(target)
    EndIf
EndFunction

Function ClearVerification(Actor target) Global
    If target == None
        Return
    EndIf
    StorageUtil.UnsetFormValue(target, GetPendingArmorKey())
    StorageUtil.UnsetFloatValue(target, GetPendingDeadlineKey())
    StorageUtil.UnsetStringValue(target, "MMEExtensions.ArmorRemoval.PendingSource")
    StorageUtil.FormListRemove(None, GetPendingActorsKey(), target, True)
EndFunction

String Function GetActorName(Actor target) Global
    Return MMEForcedMilkDrink.GetActorName(target)
EndFunction

String Function GetArmorName(Armor targetArmor) Global
    If targetArmor == None || targetArmor.GetName() == ""
        Return "<missing armor>"
    EndIf
    Return targetArmor.GetName()
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Armor Removal] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Armor Removal] FAILURE: " + detail)
EndFunction
