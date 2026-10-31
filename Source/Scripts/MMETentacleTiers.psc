Scriptname MMETentacleTiers Hidden

; Save-owned actor deadlines; only the established controller registers updates.
String Function Root() Global
    Return "MMEExtensions.Tentacle."
EndFunction

String Function Name(Int tier) Global
    If tier == 1
        Return "low"
    ElseIf tier == 2
        Return "medium"
    ElseIf tier == 3
        Return "high"
    EndIf
    Return "extreme"
EndFunction

Int Function DefaultChance(Int tier) Global
    If tier == 1
        Return 50
    ElseIf tier == 2
        Return 30
    ElseIf tier == 3
        Return 15
    EndIf
    Return 5
EndFunction

String Function ChanceKey(Int tier) Global
    Return "tentacleTierChance_" + Name(tier)
EndFunction

String Function DurationKey(Int tier) Global
    Return "tentacleTierDuration_" + Name(tier)
EndFunction

Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Tentacle Effects] " + detail)
EndFunction

Function Alarm(String reason, Actor subject = None) Global
    String stamp = Root() + "Alarm." + reason
    If StorageUtil.GetIntValue(subject, stamp, 0) != 1
        StorageUtil.SetIntValue(subject, stamp, 1)
        MMELog.Alarm("[MME Extensions Tentacle Effects] operation=effect | actor=" + subject + " | failure=" + reason)
    EndIf
EndFunction

; Largest remainders in twenty 5% units. Fixed tie order makes edits stable.
Int[] Function Balance(Int[] weights, Int edited = -1, Int requested = 0) Global
    Int[] result = new Int[4]
    Float[] remainders = new Float[4]
    Int i = 0
    Int total = 0
    While i < 4
        If weights[i] < 0
            weights[i] = 0
        ElseIf weights[i] > 100
            weights[i] = 100
        EndIf
        If i != edited
            total += weights[i]
        EndIf
        i += 1
    EndWhile
    Int remaining = 20
    If edited >= 0 && edited < 4
        requested = ((requested + 2) / 5)
        If requested < 0
            requested = 0
        ElseIf requested > 20
            requested = 20
        EndIf
        result[edited] = requested
        remaining -= requested
    EndIf
    If total == 0
        i = 0
        While i < 4
            weights[i] = DefaultChance(i + 1)
            If i != edited
                total += weights[i]
            EndIf
            i += 1
        EndWhile
    EndIf
    Int allocated = 0
    i = 0
    While i < 4
        remainders[i] = -1.0
        If i != edited
            Float share = (weights[i] * remaining) as Float / total
            result[i] = share as Int
            remainders[i] = share - result[i]
            allocated += result[i]
        EndIf
        i += 1
    EndWhile
    While allocated < remaining
        Int best = -1
        i = 0
        While i < 4
            If i != edited && (best < 0 || remainders[i] > remainders[best])
                best = i
            EndIf
            i += 1
        EndWhile
        result[best] = result[best] + 1
        remainders[best] = -1.0
        allocated += 1
    EndWhile
    i = 0
    While i < 4
        result[i] = result[i] * 5
        i += 1
    EndWhile
    Return result
EndFunction

Function Configure(Int edited = -1, Int requested = 0) Global
    String settings = "/MMEAlerts/Settings"
    Int[] weights = new Int[4]
    Int i = 0
    While i < 4
        weights[i] = JsonUtil.GetIntValue(settings, ChanceKey(i + 1), DefaultChance(i + 1))
        i += 1
    EndWhile
    Int[] balanced = Balance(weights, edited, requested)
    Bool changed = False
    i = 0
    While i < 4
        String chanceSetting = ChanceKey(i + 1)
        If !JsonUtil.HasIntValue(settings, chanceSetting) || JsonUtil.GetIntValue(settings, chanceSetting) != balanced[i]
            JsonUtil.SetIntValue(settings, chanceSetting, balanced[i])
            changed = True
        EndIf
        String durationSetting = DurationKey(i + 1)
        Float duration = Duration(i + 1)
        If !JsonUtil.HasFloatValue(settings, durationSetting) || JsonUtil.GetFloatValue(settings, durationSetting) != duration
            JsonUtil.SetFloatValue(settings, durationSetting, duration)
            changed = True
        EndIf
        i += 1
    EndWhile
    If changed
        JsonUtil.Save(settings, False)
        Trace("operation=configure | edited=" + edited + " | weights=" + balanced[0] + "/" + balanced[1] + "/" + balanced[2] + "/" + balanced[3] + " | total=100")
    EndIf
EndFunction

Float Function Duration(Int tier) Global
    Float fallback = 3.0
    If tier == 4
        fallback = 4.0
    EndIf
    Float value = JsonUtil.GetFloatValue("/MMEAlerts/Settings", DurationKey(tier), fallback)
    If value < 1.0
        Return 1.0
    ElseIf value > 10.0
        Return 10.0
    EndIf
    Return (Math.Floor(value * 2.0 + 0.5) as Float) / 2.0
EndFunction

Int Function Roll(Actor subject = None) Global
    Int roll = Utility.RandomInt(1, 100)
    Int threshold = 0
    Int tier = 1
    While tier <= 4
        threshold += JsonUtil.GetIntValue("/MMEAlerts/Settings", ChanceKey(tier), DefaultChance(tier))
        If roll <= threshold
            Trace("operation=intensity | actor=" + subject + " | roll=" + roll + " | tier=" + tier)
            Return tier
        EndIf
        tier += 1
    EndWhile
    Alarm("tier distribution did not cover roll")
    Return 4
EndFunction

Float Function Interval() Global
    Return MMETentacleEffects.CalculateNextInterval(JsonUtil.GetFloatValue("/MMEAlerts/Settings", "armorInjectionInterval", 12.0), JsonUtil.GetFloatValue("/MMEAlerts/Settings", "armorInjectionVariation", 4.0)) / 24.0
EndFunction

Function Seed(Actor subject, Float now, String reason) Global
    Float due = now + Interval()
    StorageUtil.SetFloatValue(subject, Root() + "Due", due)
    Trace("operation=schedule | actor=" + subject + " | reason=" + reason + " | nowGameDays=" + now + " | dueGameDays=" + due)
EndFunction

; A shared scan updates presence without generating an effect or a trace per tick.
Function Observe(Actor[] actors) Global
    If !MMETentacleEffects.IsEnabled()
        Return
    EndIf
    ; An empty scanner result is not proof that every tracked actor departed.
    ; Keep deadlines until a usable snapshot or an actual lifecycle/range check.
    If actors.Length == 0
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Float now = Utility.GetCurrentGameTime()
    ; Detect absence from the shared nearby snapshot, never from game-time age.
    ; Waiting/sleeping or a high timescale can advance hours between callbacks
    ; without the actor ever leaving. Retire only actors actually missing here.
    Int trackedIndex = StorageUtil.FormListCount(None, Root() + "Actors") - 1
    While trackedIndex >= 0
        Actor tracked = StorageUtil.FormListGet(None, Root() + "Actors", trackedIndex) as Actor
        If tracked == None || actors.Find(tracked) < 0
            ; Remove by actor identity: another shared callback may have changed
            ; registry indices since this snapshot was taken.
            StorageUtil.FormListRemove(None, Root() + "Actors", tracked, True)
            If tracked != None
                StorageUtil.UnsetFloatValue(tracked, Root() + "Due")
                StorageUtil.UnsetFloatValue(tracked, Root() + "Seen")
                Trace("operation=schedule retired | actor=" + tracked + " | reason=absent from nearby snapshot")
            EndIf
        EndIf
        trackedIndex -= 1
    EndWhile
    Int i = 0
    While i < actors.Length
        Actor subject = actors[i]
        If MMETentacleEffects.IsValidCandidate(subject, milkController)
            Int armorClass = MMEArmorScript.ClassifyArmor(milkController, subject.GetWornForm(Armor.GetMaskForSlot(32)) as Armor, "injection", subject)
            If armorClass == 2 || armorClass == 3
                Float due = StorageUtil.GetFloatValue(subject, Root() + "Due", 0.0)
                If due <= 0.0
                    Seed(subject, now, "discovery/re-entry")
                EndIf
                If StorageUtil.FormListCount(None, Root() + "Actors") < 128 || StorageUtil.FormListHas(None, Root() + "Actors", subject)
                    StorageUtil.FormListAdd(None, Root() + "Actors", subject, False)
                EndIf
                StorageUtil.SetFloatValue(subject, Root() + "Seen", now)
            Else
                StorageUtil.UnsetFloatValue(subject, Root() + "Due")
                StorageUtil.FormListRemove(None, Root() + "Actors", subject, True)
            EndIf
        EndIf
        i += 1
    EndWhile
EndFunction

Float Function NextDue(Float now) Global
    Float next = 0.0
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Int i = StorageUtil.FormListCount(None, Root() + "Actors") - 1
    While i >= 0
        Actor subject = StorageUtil.FormListGet(None, Root() + "Actors", i) as Actor
        If !MMETentacleEffects.IsValidCandidate(subject, milkController) || Game.GetPlayer().GetDistance(subject) > 2000.0
            StorageUtil.FormListRemove(None, Root() + "Actors", subject, True)
            If subject != None
                StorageUtil.UnsetFloatValue(subject, Root() + "Due")
                Trace("operation=schedule retired | actor=" + subject + " | reason=actor unavailable, ineligible or out of range")
            EndIf
        Else
            Float due = StorageUtil.GetFloatValue(subject, Root() + "Due", 0.0)
            If due > 0.0 && (next <= 0.0 || due < next)
                next = due
            EndIf
        EndIf
        i -= 1
    EndWhile
    Return next
EndFunction

Bool Function ConsumeDue(Actor subject, Float now) Global
    Float due = StorageUtil.GetFloatValue(subject, Root() + "Due", 0.0)
    If due <= 0.0 || now < due
        Return False
    EndIf
    Trace("operation=due | actor=" + subject + " | dueGameDays=" + due + " | nowGameDays=" + now + " | overdueHours=" + ((now - due) * 24.0))
    Seed(subject, now, "opportunity consumed")
    Return True
EndFunction

; Restore future deadlines; overdue saved opportunities never replay after load.
Function Recover(Bool reseed = False) Global
    StorageUtil.AdjustIntValue(None, Root() + "Generation", 1)
    Configure()
    Complete(True)
    Float now = Utility.GetCurrentGameTime()
    Int i = StorageUtil.FormListCount(None, Root() + "Actors") - 1
    While i >= 0
        Actor subject = StorageUtil.FormListGet(None, Root() + "Actors", i) as Actor
        If subject != None
            If reseed || StorageUtil.GetFloatValue(subject, Root() + "Due", 0.0) <= now
                Seed(subject, now, "load/settings refresh")
            EndIf
        EndIf
        i -= 1
    EndWhile
    StorageUtil.SetIntValue(None, Root() + "Busy", 0)
    Trace("operation=recover | tracked=" + StorageUtil.FormListCount(None, Root() + "Actors"))
EndFunction

Bool Function Start(Actor subject, Int tier) Global
    If !MMETentacleEffects.IsEnabled()
        Return False
    EndIf
    If tier < 1 || tier > 4
        Alarm("invalid intensity", subject)
        Return False
    EndIf
    If StorageUtil.FormListCount(None, Root() + "Holds") >= 128
        Alarm("pending animation capacity exhausted", subject)
        Return False
    EndIf
    Int sequence = StorageUtil.GetIntValue(subject, Root() + "Sequence", 0) + 1
    StorageUtil.SetIntValue(subject, Root() + "Sequence", sequence)
    String owner = "TentacleEffects." + sequence
    String animationEvent = "ZaZAPCHorFd"
    If tier < 4
        ActorBase baseInfo = subject.GetLeveledActorBase()
        animationEvent = MMEArousalAnimations.GetAnimationEvent(tier, baseInfo == None || baseInfo.GetSex() != 0)
    EndIf
    Float holdSeconds = Duration(tier)
    If !MMEReactionAnimation.StartCustomEvent(subject, owner, "Tentacle Effects", animationEvent, True, False)
        Trace("operation=animation | actor=" + subject + " | tier=" + tier + " | result=blocked by animation safety")
        Return False
    EndIf
    StorageUtil.SetStringValue(subject, Root() + "Owner", owner)
    StorageUtil.SetFloatValue(subject, Root() + "End", Utility.GetCurrentRealTime() + holdSeconds)
    StorageUtil.FormListAdd(None, Root() + "Holds", subject, False)
    StorageUtil.SetIntValue(subject, Root() + "SuppressCrossing", 1)
    Trace("operation=animation | actor=" + subject + " | tier=" + tier + " | event=" + animationEvent + " | durationSeconds=" + holdSeconds + " | owner=" + owner + " | result=dispatched")
    Return True
EndFunction

Float Function NextCompletion() Global
    Float next = 0.0
    Int i = 0
    While i < StorageUtil.FormListCount(None, Root() + "Holds")
        Actor subject = StorageUtil.FormListGet(None, Root() + "Holds", i) as Actor
        Float due = StorageUtil.GetFloatValue(subject, Root() + "End", 0.0)
        If due > 0.0 && (next <= 0.0 || due < next)
            next = due
        EndIf
        i += 1
    EndWhile
    Return next
EndFunction

Function Complete(Bool cancel = False) Global
    Float now = Utility.GetCurrentRealTime()
    Int i = StorageUtil.FormListCount(None, Root() + "Holds") - 1
    While i >= 0
        Actor subject = StorageUtil.FormListGet(None, Root() + "Holds", i) as Actor
        If subject == None || cancel || !MMETentacleEffects.IsEnabled() || now >= StorageUtil.GetFloatValue(subject, Root() + "End", 0.0)
            If subject != None
                String owner = StorageUtil.GetStringValue(subject, Root() + "Owner", "")
                MMEReactionAnimation.Reset(subject, owner, "Tentacle Effects", False)
                If StorageUtil.GetStringValue(subject, MMEReactionAnimation.GetPlayerMovementOwnerKey(), "") == owner && owner != ""
                    Alarm("owned movement marker survived cleanup", subject)
                EndIf
                StorageUtil.UnsetStringValue(subject, Root() + "Owner")
                StorageUtil.UnsetFloatValue(subject, Root() + "End")
                ; Keep suppression until the next threshold observation baselines it.
                Trace("operation=cleanup | actor=" + subject + " | owner=" + owner + " | canceled=" + cancel + " | result=released")
            EndIf
            StorageUtil.FormListRemoveAt(None, Root() + "Holds", i)
        EndIf
        i -= 1
    EndWhile
EndFunction

; Effective values are provided by the same native inheritance resolver as UI.
String Function Text(Int tier, String outcome, Actor subject) Global
    String id = "Pools.Injection.tiers." + Name(tier) + ".lines"
    If outcome != "lines"
        id = "Pools.TentacleEffectNarration.tiers." + Name(tier) + "." + outcome
    EndIf
    String[] values = MMENarrationOverrides.Values(id)
    If values.Length > 1
        MMENarrationOverrides.TraceSource(id, "tier/personal/inherited", values.Length - 1, subject)
        Return values[Utility.RandomInt(1, values.Length - 1)]
    EndIf
    Return ""
EndFunction
