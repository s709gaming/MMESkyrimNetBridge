Scriptname MMEDwemerArmor Hidden

; Independent fourth armor category. MME remains authoritative for capacity,
; milk removal, bottles, pain, progression, sounds, and completion events.
; This script owns only Dwemer detection, the 90% threshold, presentation,
; and the small Mode-3 finishing behavior omitted by MME's external Mode 4.

String Function GetConfigFile() Global
    Return "/MMEAlerts/DwemerArmorStories"
EndFunction

String Function GetThresholdLatchKey() Global
    Return "MMEExtensions.DwemerArmor.ThresholdLatched"
EndFunction

String Function GetPreparedAnimationKey() Global
    Return "MMEExtensions.DwemerArmor.PreparedAnimation"
EndFunction

String Function GetAnimationDispatchedKey() Global
    Return "MMEExtensions.DwemerArmor.AnimationDispatched"
EndFunction

String Function GetSequenceKey() Global
    Return "MMEExtensions.DwemerArmor.InProgress"
EndFunction

String Function GetGlobalBusyKey() Global
    Return "MMEExtensions.DwemerArmor.GlobalBusy"
EndFunction

String Function GetAnimationOwner() Global
    Return "DwemerArmorMilking"
EndFunction

; Vanilla's direct blue sibling to the green shader used by MME's
; MilkForSpriggan effect. Resolving Skyrim.esm keeps this presentation
; dependency-free and applies equally to every independent class-4 armor.
EffectShader Function GetActivationShader() Global
    Return Game.GetFormFromFile(0x0005D608, "Skyrim.esm") as EffectShader
EndFunction

Function ValidateConfiguration() Global
    String configFile = GetConfigFile()
    If !JsonUtil.JsonExists(configFile) || !JsonUtil.IsGood(configFile)
        MMELog.Alarm("[MME Extensions Dwemer Armor] story JSON is missing or malformed")
        Return
    EndIf
    If JsonUtil.StringListCount(configFile, "dwemerarmorstart") <= 0
        MMELog.Alarm("[MME Extensions Dwemer Armor] start story pool is missing or empty")
    EndIf
    If JsonUtil.StringListCount(configFile, "dwemerarmorend") <= 0
        MMELog.Alarm("[MME Extensions Dwemer Armor] end story pool is missing or empty")
    EndIf
    Report("configuration validated | story pools checked | event-driven 90% threshold ready")
EndFunction

Function ProcessNearbyDwemerArmor() Global
    If StorageUtil.GetIntValue(None, GetGlobalBusyKey(), 0) == 1
        Report("production cycle skipped | another Dwemer sequence is active")
        Return
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Dwemer Armor] production cycle skipped | MME controller unavailable")
        Return
    EndIf

    ; One native scan per MME production cycle replaces a separate polling loop.
    ; The native order is player first, then loaded actors in the same cell.
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(2000.0)
    Report("completion scan | nearby actor count=" + nearbyActors.Length)
    Int index = 0
    While index < nearbyActors.Length
        If TryCandidate(nearbyActors[index], milkController)
            ; Serialize the long latent MME transaction. Another eligible actor
            ; remains available on the next normal MME production cycle.
            Return
        EndIf
        index += 1
    EndWhile
    Report("completion scan ended | no candidate accepted")
EndFunction

Bool Function TryCandidate(Actor candidate, MilkQUEST milkController) Global
    If candidate == None || candidate.IsDead() || candidate.IsDisabled() || !candidate.Is3DLoaded()
        Report("candidate skipped | missing/dead/disabled/unloaded | actor=" + candidate)
        Return False
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(candidate, milkController)
        Report("candidate skipped | not an MME maid | actor=" + candidate)
        Return False
    EndIf

    Armor wornArmor = candidate.GetWornForm(Armor.GetMaskForSlot(32)) as Armor
    If MMECustomArmorRegistry.ClassifyCustomArmor(wornArmor) != 4
        Report("candidate skipped | slot32 is not Dwemer | actor=" + candidate + " | armor=" + wornArmor)
        If StorageUtil.GetIntValue(candidate, GetThresholdLatchKey(), 0) == 1
            StorageUtil.UnsetIntValue(candidate, GetThresholdLatchKey())
            Report("threshold latch cleared | Dwemer armor no longer worn | actor=" + GetActorName(candidate))
        EndIf
        Return False
    EndIf

    Float maximumMilk = MME_Storage.getMilkMaximum(candidate)
    If maximumMilk <= 0.0
        MMELog.Alarm("[MME Extensions Dwemer Armor] threshold skipped | invalid maximum=" + maximumMilk + " | actor=" + GetActorName(candidate))
        Return False
    EndIf
    Float currentMilk = MME_Storage.getMilkCurrent(candidate)
    Float thresholdMilk = maximumMilk * 0.90
    Report("threshold check | actor=" + GetActorName(candidate) + " | current=" + currentMilk + " | maximum=" + maximumMilk + " | threshold=" + thresholdMilk)

    If currentMilk < thresholdMilk
        If StorageUtil.GetIntValue(candidate, GetThresholdLatchKey(), 0) == 1
            StorageUtil.UnsetIntValue(candidate, GetThresholdLatchKey())
            Report("threshold latch rearmed | actor=" + GetActorName(candidate))
        EndIf
        Return False
    EndIf
    If StorageUtil.GetIntValue(candidate, GetSequenceKey(), 0) == 1
        Report("threshold skipped | actor sequence already active | actor=" + GetActorName(candidate))
        Return False
    EndIf
    If milkController.BeingMilkedPassive != None && candidate.HasSpell(milkController.BeingMilkedPassive)
        Report("threshold skipped | MME already milking actor=" + GetActorName(candidate))
        Return False
    EndIf
    If milkController.SexLab != None && milkController.SexLab.IsActorActive(candidate)
        Report("threshold skipped | SexLab owns actor=" + GetActorName(candidate))
        Return False
    EndIf
    If MMEOStimIntegration.IsActorInScene(candidate)
        Report("threshold skipped | OStim owns actor=" + GetActorName(candidate))
        Return False
    EndIf
    If candidate == Game.GetPlayer() && MMEAlertsController.IsDhlpSuspended()
        Report("threshold skipped | DHLP owns player")
        Return False
    EndIf
    If StorageUtil.GetIntValue(None, GetGlobalBusyKey(), 0) == 1
        Report("threshold skipped | another Dwemer sequence became active")
        Return False
    EndIf
    If !MMEAnimationSafety.TryAcquire(candidate, GetAnimationOwner())
        Report("threshold skipped | another MME Extensions animation owns actor=" + GetActorName(candidate))
        Return False
    EndIf

    ; Old builds persisted a threshold latch until a later below-threshold
    ; production cycle. Clear it here so an actor refilled between cycles can
    ; never remain blocked. The sequence/global locks provide all re-entry
    ; protection needed during the transaction itself.
    If StorageUtil.GetIntValue(candidate, GetThresholdLatchKey(), 0) == 1
        StorageUtil.UnsetIntValue(candidate, GetThresholdLatchKey())
        Report("legacy threshold latch cleared | actor=" + GetActorName(candidate))
    EndIf
    StorageUtil.SetIntValue(candidate, GetSequenceKey(), 1)
    StorageUtil.SetIntValue(None, GetGlobalBusyKey(), 1)
    Report("automatic milking trigger | actor=" + GetActorName(candidate) + " | current=" + currentMilk + " | threshold=" + thresholdMilk)
    RunDwemerMilking(candidate, milkController, currentMilk)
    Return True
EndFunction

Function RunDwemerMilking(Actor candidate, MilkQUEST milkController, Float startingMilk) Global
    Bool animationStarted = False
    Bool controlsDisabled = False
    Bool npcUnconscious = False
    Int soundInstance = -1
    EffectShader activationShader = GetActivationShader()

    Report("sequence start | actor=" + GetActorName(candidate))
    If activationShader != None
        activationShader.Play(candidate, 5.0)
        Report("blue activation shader started | actor=" + GetActorName(candidate) + " | shader=EnchBlueFXShader | duration=5s")
        ; Match the original Living Armor possession cadence: its green shader
        ; leads a five-second TakeHoldSound prelude before forced milking begins.
        Utility.Wait(5.0)
        Report("blue activation prelude complete | actor=" + GetActorName(candidate) + " | dispatching milking sequence")
    Else
        MMELog.Alarm("[MME Extensions Dwemer Armor] blue activation shader unavailable | Skyrim.esm:0005D608 | actor=" + GetActorName(candidate))
    EndIf
    ; MilkQUEST.TakeHoldSound is not populated in every MME installation.
    ; Use the bridge's authored, sex-aware sound marker so this presentation
    ; never depends on an optional property from the upstream quest.
    soundInstance = MMEReactionSounds.PlayPresentationHighMoan(candidate, "Dwemer Armor Milking")

    If milkController.MilkStory && candidate == Game.GetPlayer()
        StoryDisplay("start")
    EndIf

    String animationBlock = GetAnimationBlockReason(candidate, milkController)
    If milkController.MobileMilkingAnims && animationBlock == ""
        String animationEvent = PickStandingAnimation()
        If animationEvent != ""
            If candidate == Game.GetPlayer()
                Game.ForceThirdPerson()
                Game.DisablePlayerControls(True, True, False, False, True, True, False)
                controlsDisabled = True
                Utility.Wait(1.0)
            Else
                candidate.SetUnconscious(True)
                npcUnconscious = True
            EndIf
            ; MME clears IsAnimating when MilkingCycle begins. Prepare the
            ; event here, then let the authoritative MME start callback send
            ; it after that reset, matching the original Mode-3 ordering.
            StorageUtil.SetStringValue(candidate, GetPreparedAnimationKey(), animationEvent)
            StorageUtil.UnsetIntValue(candidate, GetAnimationDispatchedKey())
            animationStarted = True
            Report("standing animation prepared | actor=" + GetActorName(candidate) + " | event=" + animationEvent)
        EndIf
    ElseIf !milkController.MobileMilkingAnims
        Report("standing animation skipped | MME Mobile Milking Animations disabled")
    Else
        Report("standing animation skipped | actor=" + GetActorName(candidate) + " | reason=" + animationBlock)
    EndIf

    ; Mode 4 is MME's external-mod route. It preserves MME's milk, bottle,
    ; pain, progression, sound, orgasm, and MME_MilkingDone ownership while
    ; preventing its old three-category classifier from reclassifying Dwemer.
    Report("dispatching MME Milking Mode 4 | actor=" + GetActorName(candidate))
    milkController.Milking(candidate, 0, 4, 0)
    Report("MME Milking Mode 4 returned | actor=" + GetActorName(candidate))
    If animationStarted && StorageUtil.GetIntValue(candidate, GetAnimationDispatchedKey(), 0) != 1
        MMELog.Alarm("[MME Extensions Dwemer Armor] MME start callback did not dispatch the prepared animation | actor=" + GetActorName(candidate))
    EndIf

    ; Mode 3 adds these two forced-armor finish buffs after the common milking
    ; transaction. Mirror that small verified step without copying MilkCycle.
    If milkController.MilkQC != None && milkController.MilkQC.Buffs && MMEArmorScript.IsMMEMilkMaid(candidate, milkController) \
    && milkController.MME_Spells_Buffs != None && milkController.MME_Spells_Buffs.GetSize() > 4
        Spell finishBuff = milkController.MME_Spells_Buffs.GetAt(3) as Spell
        Spell finishEffect = milkController.MME_Spells_Buffs.GetAt(4) as Spell
        If finishBuff != None
            candidate.AddSpell(finishBuff, False)
        EndIf
        If finishEffect != None
            candidate.AddSpell(finishEffect, False)
        EndIf
        Report("Mode 3 finishing buffs mirrored | actor=" + GetActorName(candidate))
    EndIf

    If milkController.MilkStory && candidate == Game.GetPlayer()
        StoryDisplay("end")
    EndIf

    CleanupSequence(candidate, milkController, animationStarted, controlsDisabled, npcUnconscious, activationShader)
    Float endingMilk = MME_Storage.getMilkCurrent(candidate)
    If endingMilk >= startingMilk
        MMELog.Alarm("[MME Extensions Dwemer Armor] MME milking returned without reducing milk | actor=" + GetActorName(candidate) + " | before=" + startingMilk + " | after=" + endingMilk)
    EndIf
    Report("sequence end | actor=" + GetActorName(candidate) + " | milkBefore=" + startingMilk + " | milkAfter=" + endingMilk)
EndFunction

String Function GetAnimationBlockReason(Actor candidate, MilkQUEST milkController) Global
    If candidate.IsInCombat()
        Return "in combat"
    ElseIf candidate.IsOnMount()
        Return "mounted"
    ElseIf candidate.GetSitState() > 0 && candidate.GetSitState() <= 3
        Return "sitting"
    ElseIf StorageUtil.GetIntValue(candidate, "IsBoundStrict", 0) != 0
        Return "strictly bound"
    ElseIf milkController.DDi != None && (milkController.DDi.IsMilkingBlocked_Armbinder(candidate) || milkController.DDi.IsMilkingBlocked_Yoke(candidate))
        Return "arms restrained"
    EndIf
    Return ""
EndFunction

String Function PickStandingAnimation() Global
    Int animationCount = JsonUtil.StringListCount("/MME/Strings", "standingmilkinganimations")
    If animationCount <= 0
        MMELog.Alarm("[MME Extensions Dwemer Armor] MME standing animation pool is missing or empty")
        Return ""
    EndIf
    String animationEvent = JsonUtil.StringListGet("/MME/Strings", "standingmilkinganimations", Utility.RandomInt(0, animationCount - 1))
    If animationEvent == ""
        MMELog.Alarm("[MME Extensions Dwemer Armor] selected MME standing animation is empty")
    EndIf
    Return animationEvent
EndFunction

Function CleanupSequence(Actor candidate, MilkQUEST milkController, Bool animationStarted, Bool controlsDisabled, Bool npcUnconscious, EffectShader activationShader = None) Global
    If candidate != None
        If activationShader != None
            activationShader.Stop(candidate)
            Report("blue activation shader cleanup | actor=" + GetActorName(candidate))
        EndIf
        If animationStarted && StorageUtil.GetIntValue(candidate, GetAnimationDispatchedKey(), 0) == 1
            Utility.Wait(1.0)
            Debug.SendAnimationEvent(candidate, "IdleForceDefaultState")
        EndIf
        StorageUtil.UnsetIntValue(candidate, "MME.MilkMaid.IsAnimating")
        StorageUtil.UnsetStringValue(candidate, GetPreparedAnimationKey())
        StorageUtil.UnsetIntValue(candidate, GetAnimationDispatchedKey())
        StorageUtil.UnsetIntValue(candidate, GetThresholdLatchKey())
        If npcUnconscious && candidate.IsUnconscious()
            candidate.SetUnconscious(False)
        EndIf
        If controlsDisabled && candidate == Game.GetPlayer()
            Game.EnablePlayerControls()
            Game.SetPlayerAIDriven(False)
        EndIf
        StorageUtil.UnsetIntValue(candidate, GetSequenceKey())
        MMEAnimationSafety.Release(candidate, GetAnimationOwner())
    EndIf
    StorageUtil.UnsetIntValue(None, GetGlobalBusyKey())
    Report("sequence cleanup complete | actor=" + GetActorName(candidate))
EndFunction

; MME calls this path from its authoritative StartMilkingMachine event, after
; MilkingCycle has reset MME.MilkMaid.IsAnimating. Only an active Dwemer
; sequence can consume the prepared event, so ordinary MME routes are untouched.
Bool Function HandleMMEMilkingStart(Actor candidate) Global
    If candidate == None || StorageUtil.GetIntValue(candidate, GetSequenceKey(), 0) != 1
        Return False
    EndIf
    String animationEvent = StorageUtil.GetStringValue(candidate, GetPreparedAnimationKey(), "")
    If animationEvent == ""
        MMELog.Alarm("[MME Extensions Dwemer Armor] MME start callback found no prepared animation | actor=" + GetActorName(candidate))
        Return False
    EndIf
    Debug.SendAnimationEvent(candidate, animationEvent)
    StorageUtil.SetIntValue(candidate, "MME.MilkMaid.IsAnimating", 1)
    StorageUtil.SetIntValue(candidate, GetAnimationDispatchedKey(), 1)
    Report("standing animation dispatched from MME start | actor=" + GetActorName(candidate) + " | event=" + animationEvent)
    Return True
EndFunction

Function HandleArmorRemoved(Actor wearer) Global
    If wearer == None
        Return
    EndIf
    StorageUtil.UnsetIntValue(wearer, GetThresholdLatchKey())
    Report("Dwemer armor removal detected | latch cleared | actor=" + GetActorName(wearer))
EndFunction

Function StoryDisplay(String storyState) Global
    If storyState == "start"
        StoryDAS()
    ElseIf storyState == "end"
        StoryDAE()
    EndIf
EndFunction

Function StoryDAS() Global
    ShowStoryPool("dwemerarmorstart")
EndFunction

Function StoryDAE() Global
    ShowStoryPool("dwemerarmorend")
EndFunction

Function ShowStoryPool(String poolName) Global
    Bool shown = MMEStoryPopup.ShowRandomStoryPopup(Game.GetPlayer(), GetConfigFile(), poolName, "", "Dwemer Armor")
    If shown
        Report("story " + poolName + " | player")
    EndIf
EndFunction

String Function GetActorName(Actor candidate) Global
    If candidate == None
        Return "<missing actor>"
    EndIf
    String actorName = candidate.GetDisplayName()
    If actorName == ""
        ActorBase actorBaseInfo = candidate.GetLeveledActorBase()
        If actorBaseInfo != None
            actorName = actorBaseInfo.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

Function Report(String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Dwemer Armor] " + reportText)
EndFunction
