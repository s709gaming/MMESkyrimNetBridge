Scriptname MMESelfMilking Hidden

; One dependency-neutral facade for every route that starts MME's existing
; self-milking spell. This script validates and dispatches; MME still owns the
; actual scene, milk removal, animations, and authoritative start/end events.

Bool Function IsAutoEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableAutoSelfMilking", 1) == 1
EndFunction

Float Function GetAutoDelayHours() Global
    Float delayHours = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "autoSelfMilkingDelayHours", 1.0)
    If delayHours < 0.0
        Return 0.0
    ElseIf delayHours > 24.0
        Return 24.0
    EndIf
    Return delayHours
EndFunction

String Function GetActorName(Actor candidate) Global
    If candidate == None
        Return "Unknown actor"
    EndIf
    String actorName = candidate.GetDisplayName()
    If actorName == ""
        actorName = candidate.GetLeveledActorBase().GetName()
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

; Returns an empty string when the actor can safely enter MME's MilkSelf route.
; Callers use the reason for concise, master-gated Papyrus footprints.
String Function GetInvalidReason(Actor candidate, Bool allowPlayer = True, Bool requireFull = False, Bool requireNearby = False) Global
    If candidate == None
        Return "actor unavailable"
    EndIf
    If !allowPlayer && candidate == Game.GetPlayer()
        Return "player is not valid for this route"
    EndIf
    If candidate.IsDead()
        Return "actor is dead"
    EndIf
    If candidate.IsDisabled()
        Return "actor is disabled"
    EndIf
    If !candidate.Is3DLoaded()
        Return "actor is not loaded"
    EndIf
    If requireNearby && Game.GetPlayer().GetDistance(candidate) > 2000.0
        Return "actor is no longer nearby"
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return "MME controller unavailable"
    EndIf
    If milkController.MilkSelf == None
        Return "MME MilkSelf spell unavailable"
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        Return "actor is no longer an MME Milk Maid"
    EndIf
    If StorageUtil.GetIntValue(candidate, "MMEAlerts.IsMilking", 0) == 1
        Return "actor is already milking"
    EndIf
    If milkController.BeingMilkedPassive != None && candidate.HasSpell(milkController.BeingMilkedPassive)
        Return "MME reports actor is already being milked"
    EndIf
    If requireFull
        Float maximum = MME_Storage.getMilkMaximum(candidate)
        If maximum <= 0.0
            Return "actor has no valid milk capacity"
        EndIf
        If MME_Storage.getMilkCurrent(candidate) < maximum
            Return "actor is no longer full"
        EndIf
    EndIf
    Return ""
EndFunction

Bool Function IsEligible(Actor candidate, Bool allowPlayer = True, Bool requireFull = False, Bool requireNearby = False) Global
    Return GetInvalidReason(candidate, allowPlayer, requireFull, requireNearby) == ""
EndFunction

; Cast returns no success value, so acceptance means validation passed and the
; existing MME spell was dispatched. MME's start event confirms scene startup.
Bool Function StartExisting(Actor candidate, Bool allowPlayer = True, Bool requireFull = False, Bool requireNearby = False) Global
    If GetInvalidReason(candidate, allowPlayer, requireFull, requireNearby) != ""
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    milkController.MilkSelf.Cast(candidate)
    Return True
EndFunction

; Extensions-owned automatic route. Special body armor keeps control of slot
; 32, preventing original MilkSelf from replacing trapped armor with MilkCuirass.
Bool Function StartCompatible(Actor candidate, Bool allowPlayer = True, Bool requireFull = False, Bool requireNearby = False) Global
    If GetInvalidReason(candidate, allowPlayer, requireFull, requireNearby) != ""
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Armor wornArmor = candidate.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, wornArmor, "automatic self-milking", candidate)
    If armorClass == 4
        MMELog.MasterDiagnostic("[MME Extensions Auto Self-Milking] Dwemer armor retained; dedicated milking requested | actor=" + GetActorName(candidate))
        Return MMEDwemerArmor.TryCandidate(candidate, milkController)
    ElseIf armorClass == 2 || armorClass == 3
        MMELog.MasterDiagnostic("[MME Extensions Auto Self-Milking] Living/Parasite armor retained; ordinary MilkSelf suppressed | actor=" + GetActorName(candidate))
        Return True
    EndIf
    Return StartExisting(candidate, allowPlayer, requireFull, requireNearby)
EndFunction
