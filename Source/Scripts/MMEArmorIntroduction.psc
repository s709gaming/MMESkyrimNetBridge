Scriptname MMEArmorIntroduction Hidden

; One-time, per-actor presentation for Living, Parasite, and Dwemer armor.
; This facade never creates a Milk Maid and never polls. Automatic equip use is
; player-only because Debug.MessageBox pauses the player's game globally.

String Function GetConfigFile() Global
    Return "/MMEAlerts/ArmorIntroductionStories"
EndFunction

String Function GetPlayerMovementLockKey() Global
    Return "MMEExtensions.ArmorIntroduction.PlayerMovementLocked"
EndFunction

String Function GetMarkerKey(Int armorClass) Global
    If armorClass == 2
        Return "MMEExtensions.ArmorIntroduction.Living"
    ElseIf armorClass == 3
        Return "MMEExtensions.ArmorIntroduction.Parasite"
    ElseIf armorClass == 4
        Return "MMEExtensions.ArmorIntroduction.Dwemer"
    EndIf
    Return ""
EndFunction

String Function GetStoryPool(Int armorClass) Global
    If armorClass == 2
        Return "living_first_equip"
    ElseIf armorClass == 3
        Return "parasite_first_equip"
    ElseIf armorClass == 4
        Return "dwemer_first_equip"
    EndIf
    Return ""
EndFunction

String Function GetFallbackStory(Int armorClass) Global
    If armorClass == 2
        Return "{ActorName} feels the living armor awaken and tighten into place."
    ElseIf armorClass == 3
        Return "{ActorName} shudders as the parasite armor recognizes its new wearer."
    ElseIf armorClass == 4
        Return "{ActorName} feels ancient Dwemer machinery stir against their body."
    EndIf
    Return ""
EndFunction

Bool Function IsSupportedClass(Int armorClass) Global
    Return armorClass == 2 || armorClass == 3 || armorClass == 4
EndFunction

Bool Function HasSeen(Actor target, Int armorClass) Global
    String markerKey = GetMarkerKey(armorClass)
    If target == None || markerKey == ""
        Return False
    EndIf
    Return StorageUtil.GetIntValue(target, markerKey, 0) == 1
EndFunction

String Function GetDwemerProfileMarkerKey(Armor equippedArmor) Global
    String profile = MMECustomArmorRegistry.GetDwemerPresentationProfile(equippedArmor)
    If profile == "deviousSuit"
        Return "MMEExtensions.ArmorIntroduction.DwemerSuit"
    EndIf
    Return "MMEExtensions.ArmorIntroduction.DwemerAttachment"
EndFunction

Bool Function HasSeenArmor(Actor target, Int armorClass, Armor equippedArmor) Global
    If armorClass != 4
        Return HasSeen(target, armorClass)
    EndIf
    If target == None
        Return False
    EndIf
    Return StorageUtil.GetIntValue(target, GetDwemerProfileMarkerKey(equippedArmor), 0) == 1
EndFunction

Function MarkSeenArmor(Actor target, Int armorClass, Armor equippedArmor, String source = "internal") Global
    If armorClass != 4
        MarkSeen(target, armorClass, source)
        Return
    EndIf
    If target == None
        Return
    EndIf
    String markerKey = GetDwemerProfileMarkerKey(equippedArmor)
    StorageUtil.SetIntValue(target, markerKey, 1)
    Report("profile marker written | actor=" + GetActorName(target) + " | profile=" + MMECustomArmorRegistry.GetDwemerPresentationProfile(equippedArmor) + " | source=" + source)
EndFunction

Function MarkSeen(Actor target, Int armorClass, String source = "internal") Global
    String markerKey = GetMarkerKey(armorClass)
    If target == None || markerKey == ""
        Return
    EndIf
    StorageUtil.SetIntValue(target, markerKey, 1)
    Report("marker written | actor=" + GetActorName(target) + " | class=" + MMEArmorScript.GetArmorTypeLabel(armorClass) + " | source=" + source)
EndFunction

Bool Function Reset(Actor target, Int armorClass) Global
    String markerKey = GetMarkerKey(armorClass)
    If target == None || markerKey == ""
        Report("reset rejected | actor=" + GetActorName(target) + " | class=" + armorClass)
        Return False
    EndIf
    StorageUtil.UnsetIntValue(target, markerKey)
    Report("marker reset | actor=" + GetActorName(target) + " | class=" + MMEArmorScript.GetArmorTypeLabel(armorClass))
    Return True
EndFunction

Bool Function TryAutomatic(Actor target, Armor equippedArmor) Global
    If target != Game.GetPlayer()
        Return False
    EndIf
    Return TryIntroduction(target, equippedArmor, "Automatic Equip")
EndFunction

; Latent: a successful call owns the actor for the ten-second presentation.
Bool Function TryIntroduction(Actor target, Armor equippedArmor, String sourceLabel = "Internal") Global
    If target == None || equippedArmor == None
        Report("request rejected: actor or armor missing | source=" + sourceLabel)
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, equippedArmor, "introduction", target)
    String armorType = MMEArmorScript.GetArmorTypeLabel(armorClass)
    Report("request | actor=" + GetActorName(target) + " | armor=" + GetArmorName(equippedArmor) + " | class=" + armorType + " | source=" + sourceLabel)
    If !IsSupportedClass(armorClass)
        Report("skipped: unsupported armor class | actor=" + GetActorName(target) + " | source=" + sourceLabel)
        Return False
    EndIf
    If HasSeenArmor(target, armorClass, equippedArmor)
        Report("skipped: introduction already seen | actor=" + GetActorName(target) + " | class=" + armorType)
        Return False
    EndIf

    String owner = "ArmorIntroduction." + armorClass
    String requestLabel = "Armor Introduction " + armorType
    Bool animationStarted = MMEReactionAnimation.StartPresentationKneeling(target, owner, requestLabel, True)
    If !animationStarted
        Report("deferred: shared animation safety rejected request | actor=" + GetActorName(target) + " | class=" + armorType)
        Return False
    EndIf

    Bool playerMovementLocked = LockPlayerMovement(target)

    String poolName = GetStoryPool(armorClass)
    Bool storyShown = MMEStoryPopup.ShowRandomStoryPopup(target, GetConfigFile(), poolName, GetFallbackStory(armorClass), requestLabel)
    Report("story result=" + storyShown + " | actor=" + GetActorName(target) + " | pool=" + poolName)
    Int soundResult = MMEReactionSounds.PlayPresentationHighMoan(target, requestLabel)
    Report("sound result=" + soundResult + " | actor=" + GetActorName(target) + " | class=" + armorType)

    If armorClass == 4
        MMEAlertsSkyrimNet.NarrateDwemerSuitEvent(target, equippedArmor, "firstEquip")
    EndIf

    MarkSeenArmor(target, armorClass, equippedArmor, sourceLabel)
    Report("marker written after animation dispatch | actor=" + GetActorName(target) + " | class=" + armorType)
    MMEReactionAnimation.Finish(target, animationStarted, owner, 10.0, requestLabel, True)
    If playerMovementLocked
        UnlockPlayerMovement(target, "normal completion")
    EndIf
    Report("sequence complete | actor=" + GetActorName(target) + " | class=" + armorType)
    Return True
EndFunction

Bool Function LockPlayerMovement(Actor target) Global
    If target != Game.GetPlayer()
        Return False
    EndIf
    target.SetDontMove(True)
    StorageUtil.SetIntValue(target, GetPlayerMovementLockKey(), 1)
    Report("PLAYER movement locked for ten-second introduction")
    Return True
EndFunction

Function UnlockPlayerMovement(Actor target, String reason = "cleanup") Global
    If target != Game.GetPlayer() || StorageUtil.GetIntValue(target, GetPlayerMovementLockKey(), 0) != 1
        Return
    EndIf
    target.SetDontMove(False)
    StorageUtil.UnsetIntValue(target, GetPlayerMovementLockKey())
    Report("PLAYER movement unlocked | reason=" + reason)
EndFunction

; Controller initialization and native load events call this even while the
; extension is disabled, recovering saves interrupted during the latent hold.
Function RestorePlayerMovementIfNeeded(Actor target, String reason = "controller recovery") Global
    If target == Game.GetPlayer() && StorageUtil.GetIntValue(target, GetPlayerMovementLockKey(), 0) == 1
        UnlockPlayerMovement(target, reason)
        Report("PLAYER emergency movement recovery completed | reason=" + reason)
    EndIf
EndFunction

String Function GetActorName(Actor target) Global
    If target == None
        Return "<missing actor>"
    EndIf
    String actorName = target.GetDisplayName()
    If actorName == ""
        ActorBase baseInfo = target.GetLeveledActorBase()
        If baseInfo != None
            actorName = baseInfo.GetName()
        EndIf
    EndIf
    If actorName == ""
        actorName = "Unknown actor"
    EndIf
    Return actorName
EndFunction

String Function GetArmorName(Armor targetArmor) Global
    If targetArmor == None
        Return "<missing armor>"
    EndIf
    String armorName = targetArmor.GetName()
    If armorName == ""
        armorName = "<unnamed armor>"
    EndIf
    Return armorName
EndFunction

Function Report(String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Armor Introduction] " + reportText)
EndFunction
