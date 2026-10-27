Scriptname MMEMilkCurse Hidden

; Conversion-free presentation and established-maid curse service.
Function Trace(String detail) Global
    MMELog.MasterDiagnostic("[MME Extensions Milk Maid Curse] " + detail)
EndFunction

Function AlarmOnce(Actor target, String reason) Global
    Float now = Utility.GetCurrentRealTime()
    String alarmKey = "MMEExtensions.MilkCurse.Alarm." + reason
    Float prior = StorageUtil.GetFloatValue(target, alarmKey, -100.0)
    If now < prior || now - prior >= 60.0
        StorageUtil.SetFloatValue(target, alarmKey, now)
        MMELog.Alarm("[MME Extensions Milk Maid Curse] FAILURE | actor=" + target + " | reason=" + reason)
    EndIf
EndFunction

String Function NewOwner(Actor target, String prefix) Global
    Int sequence = StorageUtil.AdjustIntValue(target, "MMEExtensions.MilkCurse.Sequence", 1)
    Return prefix + "." + sequence
EndFunction

String Function GetBlockReason(Actor target) Global
    If !MMEAlertsController.IsExtensionsEnabled()
        Return "Extensions disabled"
    EndIf
    If target == None || target.IsChild() || target.IsDeleted()
        Return "actor unavailable"
    EndIf
    If Game.GetModByName("ZaZAnimationPack.esm") == 255
        Return "ZaZ animation dependency unavailable"
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Return "MME controller unavailable"
    EndIf
    Return MMEAnimationSafety.GetStartBlockReason(target, milkController, True)
EndFunction

; Caller already owns animation: do not reacquire, convert or choose stories.
; Movement recovery is registered in the existing controller load path.
Bool Function PlayOwnedReaction(Actor target, String owner) Global
    If target == None || !MMEAnimationSafety.Owns(target, owner)
        AlarmOnce(target, "reaction attempted without actor ownership")
        Return False
    EndIf
    String blocked = MMEAnimationSafety.GetResetBlockReason(target, Quest.GetQuest("MME_MilkQUEST") as MilkQUEST, owner)
    If blocked != "" || !MMEAlertsController.IsExtensionsEnabled()
        Trace("reaction skipped before dispatch | actor=" + target + " | reason=" + blocked)
        Return False
    EndIf
    MMEReactionAnimation.LockMovement(target, owner, "Milk Maid curse")
    If target != Game.GetPlayer()
        target.EvaluatePackage()
    EndIf
    If target == Game.GetPlayer()
        Game.ForceThirdPerson()
    EndIf
    Debug.SendAnimationEvent(target, "ZaZAPCHorFd")
    Trace("reaction dispatched | actor=" + target + " | owner=" + owner + " | duration=10; graph playback not confirmed")
    If StringUtil.Find(owner, "ForcedMilkMaidConversion.") == 0
        MMEReactionSounds.PlayNewMilkMaidMoan(target)
    ElseIf JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNewMilkMaidMoans", 1) == 1
        MMEReactionSounds.PlayPresentationHighMoan(target, "Milk Maid curse")
    EndIf
    If target == Game.GetPlayer()
        Int startHandle = ModEvent.Create("PlayerOrgasmStart")
        If startHandle
            ModEvent.Send(startHandle)
        EndIf
    EndIf
    Utility.Wait(10.0)
    If target == Game.GetPlayer()
        Int endHandle = ModEvent.Create("PlayerOrgasmEnd")
        If endHandle
            ModEvent.Send(endHandle)
        EndIf
    EndIf
    MMEReactionAnimation.Reset(target, owner, "Milk Maid curse", False)
    Trace("reaction cleanup | actor=" + target + " | owner=" + owner)
    Return True
EndFunction

Bool Function PlayReaction(Actor target) Global
    String reason = GetBlockReason(target)
    Trace("reaction request | actor=" + target + " | reason=" + reason)
    If reason != ""
        Return False
    EndIf
    String owner = NewOwner(target, "MilkCurse.Presentation")
    If !MMEAnimationSafety.TryAcquire(target, owner)
        Return False
    EndIf
    Bool dispatched = PlayOwnedReaction(target, owner)
    MMEAnimationSafety.Release(target, owner)
    Return dispatched
EndFunction

; commitKey belongs to the chest service, never a public client-supplied key.
; Mark before mutation: an interrupted save cannot repeat committed gameplay.
Bool Function ApplySurge(Actor target, Float percentage, String commitKey) Global
    String reason = GetBlockReason(target)
    Trace("surge entry | actor=" + target + " | percent=" + percentage + " | reason=" + reason)
    If reason != "" || percentage <= 0.0
        Return False
    EndIf
    If percentage != percentage || percentage > 100.0
        AlarmOnce(target, "invalid surge percentage")
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If !MMEArmorScript.IsMMEMilkMaid(target, milkController)
        Trace("surge skipped | actor is not an established Milk Maid | actor=" + target)
        Return False
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(target)
    If maximum <= 0.0 || maximum > 1000000000.0 || maximum != maximum
        AlarmOnce(target, "invalid registered Milk Maid capacity")
        Return False
    EndIf
    String owner = NewOwner(target, "MilkCurse.Surge")
    If !MMEAnimationSafety.TryAcquire(target, owner)
        Trace("surge skipped | actor busy | actor=" + target)
        Return False
    EndIf
    If !MMEArmorScript.IsMMEMilkMaid(target, milkController) || !MMEAlertsController.IsExtensionsEnabled()
        MMEAnimationSafety.Release(target, owner)
        Trace("surge skipped | eligibility changed | actor=" + target)
        Return False
    EndIf
    String finalBlock = MMEAnimationSafety.GetResetBlockReason(target, milkController, owner)
    maximum = MME_Storage.getMilkMaximum(target)
    Float beforeMilk = MME_Storage.getMilkCurrent(target)
    If finalBlock != "" || MMEAlertsController.IsFreeArmAnimationBlocked(target)
        MMEAnimationSafety.Release(target, owner)
        Trace("surge skipped before commit | actor=" + target + " | reason=" + finalBlock)
        Return False
    EndIf
    If maximum <= 0.0 || maximum > 1000000000.0 || maximum != maximum || beforeMilk != beforeMilk || beforeMilk < 0.0 || beforeMilk > 1000000000000.0
        MMEAnimationSafety.Release(target, owner)
        AlarmOnce(target, "invalid milk/capacity before surge commit")
        Return False
    EndIf
    Float addition = maximum * percentage / 100.0
    If commitKey != ""
        StorageUtil.SetIntValue(None, commitKey, 1)
    EndIf
    MME_Storage.changeMilkCurrent(target, addition, False)
    Float afterMilk = MME_Storage.getMilkCurrent(target)
    Trace("surge committed | actor=" + target + " | max=" + maximum + " | requested=" + addition + " | before=" + beforeMilk + " | after=" + afterMilk + " | actual=" + (afterMilk - beforeMilk))
    If afterMilk <= beforeMilk
        AlarmOnce(target, "committed surge did not increase stored milk; chest will not replay")
    EndIf
    milkController.CurrentSize(target)
    ShowStory(target)
    PlayOwnedReaction(target, owner)
    MMEReactionAnimation.UnlockMovement(target, owner, "Curse final cleanup")
    MMEAnimationSafety.Release(target, owner)
    If target == Game.GetPlayer()
        MMEBodyEffects.Reconcile("Milk Maid curse surge")
    EndIf
    If !target.IsDead() && !target.IsDisabled() && target.Is3DLoaded()
        MMEArmorScript.EvaluateArmorStrippingForActor(target, MME_Storage.getMilkCurrent(target), "curse surge")
    EndIf
    Feedback(target, False)
    Trace("surge cleanup complete | actor=" + target)
    Return True
EndFunction

Function ShowStory(Actor target) Global
    If target != Game.GetPlayer() || JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableForcedMilkMaidStory", 1) != 1
        Return
    EndIf
    String config = "/MMEAlerts/ForcedMilkMaidConversion"
    Int count = JsonUtil.StringListCount(config, "chestCurseStories")
    Int selected = -1
    String story = "A mysterious enchantment washes over {actor}. Her breasts tingle with warmth and the promise of a wonderfully abundant harvest!"
    If count > 0
        selected = Utility.RandomInt(0, count - 1)
        String configured = JsonUtil.StringListGet(config, "chestCurseStories", selected)
        If configured != ""
            story = configured
        EndIf
    EndIf
    Trace("story selected | actor=" + target + " | index=" + selected)
    Debug.MessageBox(MMEAlertsSkyrimNet.RenderMessage(story, MMENewMilkMaid.GetActorName(target)))
EndFunction

Function Feedback(Actor target, Bool converted) Global
    If target == None || !MMEAlertsController.IsExtensionsEnabled()
        Return
    EndIf
    String config = "/MMEAlerts/ForcedMilkMaidConversion"
    String text = "{actor} feels strange magic coursing through their breasts!"
    Int count = JsonUtil.StringListCount(config, "conversionMessages")
    If count > 0
        String configured = JsonUtil.StringListGet(config, "conversionMessages", Utility.RandomInt(0, count - 1))
        If configured != ""
            text = configured
        EndIf
    EndIf
    text = MMEAlertsSkyrimNet.RenderMessage(text, MMENewMilkMaid.GetActorName(target))
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableForcedMilkMaidNotification", 1) == 1
        Debug.Notification(text)
    EndIf
    If converted
        MMEAlertsSkyrimNet.NarrateForcedMilkMaidConversion(target, text)
    Else
        MMEAlertsSkyrimNet.NarrateMilkMaidCurse(target, text)
    EndIf
EndFunction
