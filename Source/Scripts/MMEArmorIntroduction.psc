Scriptname MMEArmorIntroduction Hidden

; One-time, per-actor presentation for Milking, Living, Parasite, and Dwemer armor.
; This facade never creates a Milk Maid and never polls. Automatic equip use is
; player-only because Debug.MessageBox pauses the player's game globally.

String Function GetConfigFile() Global
    Return "/MMEAlerts/ArmorIntroductionStories"
EndFunction

String Function GetPlayerMovementLockKey() Global
    Return "MMEExtensions.ArmorIntroduction.PlayerMovementLocked"
EndFunction

String Function GetMarkerKey(Int armorClass) Global
    If armorClass == 1
        Return "MMEExtensions.ArmorIntroduction.Milking"
    ElseIf armorClass == 2
        Return "MMEExtensions.ArmorIntroduction.Living"
    ElseIf armorClass == 3
        Return "MMEExtensions.ArmorIntroduction.Parasite"
    ElseIf armorClass == 4
        Return "MMEExtensions.ArmorIntroduction.Dwemer"
    EndIf
    Return ""
EndFunction

String Function GetStoryPool(Int armorClass) Global
    If armorClass == 1
        Return "milking_first_equip"
    ElseIf armorClass == 2
        Return "living_first_equip"
    ElseIf armorClass == 3
        Return "parasite_first_equip"
    ElseIf armorClass == 4
        Return "dwemer_first_equip"
    EndIf
    Return ""
EndFunction

String Function GetTrapStoryPool(Int armorClass) Global
    If armorClass == 2
        Return "living_trap_equip"
    ElseIf armorClass == 3
        Return "parasite_trap_equip"
    ElseIf armorClass == 4
        Return "dwemer_trap_equip"
    EndIf
    Return ""
EndFunction

String Function GetRepeatStoryPool(Int armorClass) Global
    If armorClass == 1
        Return "milking_repeat_equip"
    ElseIf armorClass == 2
        Return "living_repeat_equip"
    ElseIf armorClass == 3
        Return "parasite_repeat_equip"
    ElseIf armorClass == 4
        Return "dwemer_repeat_equip"
    EndIf
    Return ""
EndFunction

String Function GetFallbackStory(Int armorClass) Global
    If armorClass == 1
        Return "{ActorName} gasps as the milking armor warms and begins its first playful fitting routine."
    ElseIf armorClass == 2
        Return "{ActorName} feels the living armor awaken and tighten into place."
    ElseIf armorClass == 3
        Return "{ActorName} shudders as the parasite armor recognizes its new wearer."
    ElseIf armorClass == 4
        Return "{ActorName} feels ancient Dwemer machinery stir against their body."
    EndIf
    Return ""
EndFunction

Bool Function IsSupportedClass(Int armorClass) Global
    Return armorClass == 1 || armorClass == 2 || armorClass == 3 || armorClass == 4
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
    Return TryPresentation(target, equippedArmor, sourceLabel, False, 0)
EndFunction

; Repeatable presentation reserved for a confirmed treasure-chest trap equip.
; The caller owns origin validation; this facade only presents the event.
Bool Function TryTrapIntroduction(Actor target, Armor equippedArmor, String sourceLabel = "Treasure Chest Trap") Global
    Return TryPresentation(target, equippedArmor, sourceLabel, True, 1)
EndFunction

; Repeatable presentation for an ordinary equip or a successful artisan
; installation. Origin validation remains the caller's responsibility.
Bool Function TryRepeatIntroduction(Actor target, Armor equippedArmor, String sourceLabel = "Ordinary Armor Equip") Global
    Return TryPresentation(target, equippedArmor, sourceLabel, True, 2)
EndFunction

; Latent: a successful call owns the actor for the ten-second presentation.
Bool Function TryPresentation(Actor target, Armor equippedArmor, String sourceLabel, Bool allowRepeat, Int storyMode) Global
    Bool trapStory = storyMode == 1
    If target == None || equippedArmor == None
        Report("request rejected: actor or armor missing | source=" + sourceLabel)
        If trapStory
            MMELog.Alarm("[MME Extensions Armor Introduction] Trap story failed: actor or armor was missing.")
        EndIf
        Return False
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Int armorClass = MMEArmorScript.ClassifyArmor(milkController, equippedArmor, "introduction", target)
    String armorType = MMEArmorScript.GetArmorTypeLabel(armorClass)
    Report("request | actor=" + GetActorName(target) + " | armor=" + GetArmorName(equippedArmor) + " | class=" + armorType + " | source=" + sourceLabel)
    If !IsSupportedClass(armorClass)
        Report("skipped: unsupported armor class | actor=" + GetActorName(target) + " | source=" + sourceLabel)
        If trapStory
            MMELog.Alarm("[MME Extensions Armor Introduction] Trap story failed: equipped armor is not Milking, Living, Parasite, or Dwemer armor.")
        EndIf
        Return False
    EndIf
    ; MME's artisan registries and our Dwemer attachment registry identify
    ; base armor forms or display names, so a generic item such as "clothes"
    ; can match unrelated wearers. Confirmed chest traps have their own origin
    ; marker; every ordinary or artisan story must belong to an actual Maid.
    If !trapStory && !MMEArmorScript.IsMMEMilkMaid(target, milkController)
        Report("skipped: ordinary armor-story wearer is not a Milk Maid | actor=" + GetActorName(target) + " | armor=" + GetArmorName(equippedArmor) + " | class=" + armorType + " | source=" + sourceLabel)
        Return False
    EndIf
    Bool alreadySeen = HasSeenArmor(target, armorClass, equippedArmor)
    If alreadySeen && !allowRepeat
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

    String poolName = GetStoryPool(armorClass)
    If trapStory
        poolName = GetTrapStoryPool(armorClass)
    ElseIf storyMode == 2
        poolName = GetRepeatStoryPool(armorClass)
    EndIf
    Bool storyShown = MMEStoryPopup.ShowRandomStoryPopup(target, GetConfigFile(), poolName, GetFallbackStory(armorClass), requestLabel)
    Report("story result=" + storyShown + " | actor=" + GetActorName(target) + " | pool=" + poolName)
    Int soundResult = MMEReactionSounds.PlayPresentationHighMoan(target, requestLabel)
    Report("sound result=" + soundResult + " | actor=" + GetActorName(target) + " | class=" + armorType)

    If armorClass == 4
        String dwemerEvent = "firstEquip"
        If alreadySeen
            dwemerEvent = "reequip"
        EndIf
        MMEAlertsSkyrimNet.NarrateDwemerSuitEvent(target, equippedArmor, dwemerEvent)
    EndIf

    If !alreadySeen
        MarkSeenArmor(target, armorClass, equippedArmor, sourceLabel)
        Report("marker written after animation dispatch | actor=" + GetActorName(target) + " | class=" + armorType)
    EndIf
    MMEReactionAnimation.Finish(target, animationStarted, owner, 10.0, requestLabel, True)
    Report("sequence complete | actor=" + GetActorName(target) + " | class=" + armorType + " | story mode=" + storyMode + " | previously seen=" + alreadySeen)
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
