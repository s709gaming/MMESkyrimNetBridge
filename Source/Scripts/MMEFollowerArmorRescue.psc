Scriptname MMEFollowerArmorRescue Hidden

Float Function GetScanRadius() Global
    Return 2000.0
EndFunction

Int Function GetLiveServiceState(Actor blacksmith) Global
    String vendorFailure = GetBlacksmithFailure(blacksmith)
    If vendorFailure != ""
        Trace("option unavailable | " + vendorFailure)
        Return 0
    EndIf
    ; The scan only runs when the player opens this service dialogue. Preserve
    ; per-candidate master traces so a hidden option explains itself in logs.
    Int eligible = CountEligibleCompanions(blacksmith, True)
    Trace("opening scan complete | blacksmith=" + GetActorName(blacksmith) + " | eligible companions=" + eligible)
    If eligible > 0
        Return 1
    EndIf
    Return 0
EndFunction

Bool Function TryRescueNearbyCompanions(Actor blacksmith) Global
    String vendorFailure = GetBlacksmithFailure(blacksmith)
    If vendorFailure != ""
        Trace("service rejected | " + vendorFailure)
        Debug.Notification("Nobody nearby still needs rescuing.")
        Return False
    EndIf

    ; Validate the vendor above, but scan from the player. Followers can stand
    ; in a neighboring exterior cell even while the blacksmith remains close
    ; enough for dialogue; the MCM route already proved this anchor reliable.
    Return RescueNearbyCompanionsFromAnchor(Game.GetPlayer(), "Follower Blacksmith Assistance", True)
EndFunction

Bool Function TryDebugRescueNearbyCompanions() Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Trace("MCM NPC debug release rejected | MME Extensions disabled")
        Debug.Notification("Nobody nearby still needs rescuing.")
        Return False
    EndIf
    Actor playerActor = Game.GetPlayer()
    If playerActor == None
        Alarm("MCM NPC debug release could not resolve the player")
        Debug.Notification("Nobody nearby still needs rescuing.")
        Return False
    EndIf
    Trace("MCM NPC debug release requested")
    Return RescueNearbyCompanionsFromAnchor(playerActor, "MCM NPC Debug", False)
EndFunction

Bool Function RescueNearbyCompanionsFromAnchor(Actor anchor, String source, Bool blacksmithMessages) Global
    Actor playerActor = Game.GetPlayer()
    If playerActor == None || anchor == None
        Alarm(source + " could not resolve player, scan anchor, or cell")
        Debug.Notification("Nobody nearby still needs rescuing.")
        Return False
    EndIf
    Cell currentCell = anchor.GetParentCell()
    If currentCell == None
        Alarm(source + " could not resolve scan cell")
        Debug.Notification("Nobody nearby still needs rescuing.")
        Return False
    EndIf

    Int rescued = 0
    String rescuedName = ""
    Int refs = currentCell.GetNumRefs(43)
    Int index = 0
    While index < refs
        Actor candidate = currentCell.GetNthRef(index, 43) as Actor
        If candidate != None && candidate != playerActor && IsNearbyAlly(candidate, anchor)
            String failure = GetCandidateFailure(candidate, anchor)
            If failure == ""
                Armor targetArmor = GetRescuableArmor(candidate)
                If RescueExactArmor(candidate, targetArmor, source)
                    rescued += 1
                    rescuedName = GetActorName(candidate)
                EndIf
            Else
                Trace("candidate skipped | actor=" + GetActorName(candidate) + " | reason=" + failure)
            EndIf
        ElseIf candidate != None && candidate != playerActor && IsKnownAlly(candidate)
            Trace("known ally outside rescue scan | actor=" + GetActorName(candidate) + " | reason=" + GetNearbyAllyFailure(candidate, anchor))
        EndIf
        index += 1
    EndWhile

    If rescued == 1
        If blacksmithMessages
            Debug.Notification("The blacksmith frees " + rescuedName + " from her overly affectionate armor.")
        Else
            Debug.Notification(rescuedName + " is released from her overly affectionate armor.")
        EndIf
    ElseIf rescued > 1
        If blacksmithMessages
            Debug.Notification("The blacksmith frees " + rescued + " companions from their overly affectionate armor.")
        Else
            Debug.Notification(rescued + " nearby companions are released from their overly affectionate armor.")
        EndIf
    Else
        Debug.Notification("Nobody nearby still needs rescuing.")
    EndIf
    Trace("service complete | source=" + source + " | anchor=" + GetActorName(anchor) + " | rescued=" + rescued)
    Return rescued > 0
EndFunction

Int Function CountEligibleCompanions(Actor blacksmith, Bool traceSkips = True) Global
    Actor playerActor = Game.GetPlayer()
    Cell currentCell = blacksmith.GetParentCell()
    If playerActor == None || currentCell == None
        Return 0
    EndIf
    Int eligible = 0
    Int refs = currentCell.GetNumRefs(43)
    Int index = 0
    While index < refs
        Actor candidate = currentCell.GetNthRef(index, 43) as Actor
        If candidate != None && candidate != playerActor && IsNearbyAlly(candidate, blacksmith)
            String failure = GetCandidateFailure(candidate, blacksmith)
            If failure == ""
                eligible += 1
                Trace("candidate eligible | actor=" + GetActorName(candidate) + " | armor=" + GetArmorName(GetRescuableArmor(candidate)))
            ElseIf traceSkips
                Trace("candidate skipped | actor=" + GetActorName(candidate) + " | reason=" + failure)
            EndIf
        ElseIf traceSkips && candidate != None && candidate != playerActor && IsKnownAlly(candidate)
            Trace("known ally outside opening scan | actor=" + GetActorName(candidate) + " | reason=" + GetNearbyAllyFailure(candidate, blacksmith))
        EndIf
        index += 1
    EndWhile
    Return eligible
EndFunction

String Function GetBlacksmithFailure(Actor blacksmith) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return "MME Extensions disabled"
    ElseIf blacksmith == None || blacksmith.IsDead() || blacksmith.IsDisabled()
        Return "blacksmith unavailable"
    EndIf
    Faction blacksmithFaction = Game.GetFormFromFile(0x05091D, "Skyrim.esm") as Faction
    Faction merchantFaction = Game.GetFormFromFile(0x051596, "Skyrim.esm") as Faction
    If blacksmithFaction == None || merchantFaction == None
        Alarm("Skyrim blacksmith or merchant faction could not resolve")
        Return "service faction missing"
    ElseIf !blacksmith.IsInFaction(blacksmithFaction) || !blacksmith.IsInFaction(merchantFaction)
        Return "speaker is not a merchant blacksmith"
    EndIf
    Return ""
EndFunction

Bool Function IsNearbyAlly(Actor candidate, Actor anchor) Global
    Return GetNearbyAllyFailure(candidate, anchor) == ""
EndFunction

Bool Function IsKnownAlly(Actor candidate) Global
    Actor playerActor = Game.GetPlayer()
    Return candidate != None && playerActor != None \
        && (candidate.IsPlayerTeammate() || candidate.GetRelationshipRank(playerActor) >= 1)
EndFunction

String Function GetNearbyAllyFailure(Actor candidate, Actor anchor) Global
    Actor playerActor = Game.GetPlayer()
    If candidate == None
        Return "missing actor"
    ElseIf anchor == None
        Return "missing scan anchor"
    ElseIf playerActor == None
        Return "missing player"
    ElseIf !IsKnownAlly(candidate)
        Return "not a teammate or friendly relationship"
    ElseIf candidate.GetParentCell() != anchor.GetParentCell()
        Return "different cell"
    ElseIf anchor.GetDistance(candidate) > GetScanRadius()
        Return "farther than " + GetScanRadius() + " units (distance=" + anchor.GetDistance(candidate) + ")"
    ElseIf candidate.IsHostileToActor(playerActor)
        Return "hostile to player"
    EndIf
    Return ""
EndFunction

String Function GetCandidateFailure(Actor candidate, Actor anchor) Global
    If !IsNearbyAlly(candidate, anchor)
        Return "not a nearby ally"
    ElseIf !MMEForcedMilkDrink.IsEligibleActor(candidate)
        Return "not a loaded adult humanoid"
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    String busyReason = MMEAnimationSafety.GetStartBlockReason(candidate, milkController, False)
    If busyReason != ""
        Return busyReason
    EndIf
    Armor targetArmor = GetRescuableArmor(candidate)
    If targetArmor == None
        Return "no supported Living, Parasite, or Dwemer body armor"
    EndIf
    Return ""
EndFunction

Armor Function GetRescuableArmor(Actor candidate) Global
    If candidate == None
        Return None
    EndIf
    Armor lockedArmor = MMETimedArmorLock.GetLockedArmor(candidate)
    If MMETimedArmorLock.IsLocked(candidate) && lockedArmor != None && candidate.IsEquipped(lockedArmor)
        Int lockedClass = MMETimedArmorLock.GetRegisteredArmorClass(lockedArmor)
        If lockedClass == 2 || lockedClass == 3 || lockedClass == 4
            Return lockedArmor
        EndIf
    EndIf
    Armor wornArmor = candidate.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "follower-blacksmith-rescue", candidate)
    If armorClass == 2 || armorClass == 3 || armorClass == 4
        Return wornArmor
    EndIf
    Return None
EndFunction

Bool Function RescueExactArmor(Actor candidate, Armor targetArmor, String source = "Follower Blacksmith Assistance") Global
    If candidate == None || targetArmor == None || !candidate.IsEquipped(targetArmor)
        Trace("removal skipped after revalidation | actor=" + GetActorName(candidate))
        Return False
    EndIf
    Return MMEArmorRemoval.RequestActorRemoval(candidate, source, True)
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
    MMELog.MasterDiagnostic("[MME Extensions Follower Armor Rescue] " + detail)
EndFunction

Function Alarm(String detail) Global
    MMELog.Alarm("[MME Extensions Follower Armor Rescue] FAILURE: " + detail)
EndFunction
