Scriptname MMENPCDrinkDialogue Hidden

; Adult non-Milkmaid branch for Give Milk plus the shared, data-driven reaction
; renderer used by both ordinary adults and established MME Milkmaids.
Bool Function IsEligible(Actor target, MilkQUEST milkController, Bool diagnostic = False) Global
    If target == None || target == Game.GetPlayer()
        Return False
    EndIf
    If target.IsDead() || target.IsDisabled() || !target.Is3DLoaded() || target.IsChild()
        Return False
    EndIf
    ActorBase baseInfo = target.GetLeveledActorBase()
    Keyword ActorTypeNPC = Game.GetFormFromFile(0x013794, "Skyrim.esm") as Keyword
    If baseInfo == None || baseInfo.GetRace() == None || ActorTypeNPC == None || !baseInfo.GetRace().HasKeyword(ActorTypeNPC)
        Return False
    EndIf
    If milkController != None && MMEArmorScript.IsMMEMilkMaid(target, milkController)
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: non-Milkmaid route received a live MME Milkmaid")
        Return False
    EndIf
    Int sex = baseInfo.GetSex()
    If sex == 0
        Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNonMilkmaidMaleDrinking", 1) == 1
    ElseIf sex == 1
        Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNonMilkmaidFemaleDrinking", 1) == 1
    EndIf
    Return False
EndFunction

Bool Function PlayDrink(Actor target, Bool diagnostic = False) Global
    Float duration = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "npcDrinkAnimationDuration", 3.0)
    Return MMEMinorAnimations.PlayDrink(target, duration, True, diagnostic)
EndFunction

String Function ApplyPostDrink(Actor target, Form drinkItem, Bool diagnostic = False) Global
    If target == None || drinkItem == None
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: post-drink effects received a missing actor or milk item")
        Return ""
    EndIf
    ActorBase baseInfo = target.GetLeveledActorBase()
    If baseInfo == None
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: post-drink effects could not resolve the receiver ActorBase")
        Return ""
    EndIf
    Int sex = baseInfo.GetSex()
    Float amount = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "nonMilkmaidFemaleArousal", 10.0)
    If sex == 0
        amount = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "nonMilkmaidMaleArousal", 10.0)
    EndIf
    MMENPCDialog.TraceDialogueTiming("11A non-Milkmaid arousal dispatch", target)
    Bool arousalSent = MMEArousalBridge.ApplyArousalAmountForActor(target, amount, "drank " + drinkItem.GetName(), diagnostic)
    MMENPCDialog.TraceDialogueTiming("11B non-Milkmaid arousal complete", target)
    MMENPCDialog.TraceDialogueTiming("11C non-Milkmaid reaction sound dispatch", target)
    MMEMilkDrinkEffects.PlayDrinkReaction(target, diagnostic)
    MMENPCDialog.TraceDialogueTiming("11D non-Milkmaid reaction sound returned", target)
    MMENPCDialog.TraceDialogueTiming("11E non-Milkmaid notification dispatch", target)
    String renderedReaction = BuildDrinkReaction(target, drinkItem, False, 0.0, arousalSent)
    ShowNotification(target, renderedReaction)
    MMENPCDialog.TraceDialogueTiming("11F non-Milkmaid notification complete", target)
    Return renderedReaction
EndFunction

Function ShowNotification(Actor target, String renderedReaction) Global
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNonMilkmaidDrinkNotifications", 1) != 1
        Return
    EndIf
    If renderedReaction == ""
        MMELog.Alarm("[MME Extensions Drink Reaction] FAILURE: non-Milkmaid HUD received a blank rendered reaction")
        Return
    EndIf
    Debug.Notification(renderedReaction)
    MMENPCDialog.TraceDialogueTiming("11E6 HUD notification returned", target)
EndFunction

; Breastfeeding has no consumed inventory item, but its verified completion
; reuses the same JSON renderer. Keep player, Milkmaid NPC, and ordinary-adult
; notification preferences independent.
Function ShowBreastfeedingNotification(Actor target, Bool establishedMilkmaid, String renderedReaction) Global
    If target == None
        MMELog.Alarm("[MME Extensions BF Drink] FAILURE: notification received no drinker")
        Return
    EndIf
    String setting = "enableNonMilkmaidDrinkNotifications"
    If target == Game.GetPlayer()
        setting = "enablePlayerDrinkNotifications"
    ElseIf establishedMilkmaid
        setting = "enableNPCDrinkNotifications"
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", setting, 1) != 1
        Return
    EndIf
    If renderedReaction == ""
        MMELog.Alarm("[MME Extensions BF Drink] FAILURE: notification received a blank rendered reaction")
        Return
    EndIf
    Debug.Notification(renderedReaction)
EndFunction

String Function BuildDrinkReaction(Actor target, Form drinkItem, Bool establishedMilkmaid, Float milkAdded, Bool arousalSent) Global
    If target == None || drinkItem == None
        MMELog.Alarm("[MME Extensions Drink Reaction] FAILURE: reaction renderer received a missing actor or milk item")
        Return ""
    EndIf
    ActorBase baseInfo = target.GetLeveledActorBase()
    If baseInfo == None
        MMELog.Alarm("[MME Extensions Drink Reaction] FAILURE: reaction renderer could not resolve the drinker's ActorBase")
        Return ""
    EndIf
    String template = SelectNotificationTemplate(target, baseInfo.GetSex(), establishedMilkmaid, milkAdded, arousalSent)
    MMENPCDialog.TraceDialogueTiming("11E1 notification template selected", target)
    String actorName = MMEDrinkTracker.GetActorName(target)
    MMENPCDialog.TraceDialogueTiming("11E2 actor name resolved", target)
    String milkName = drinkItem.GetName()
    If milkName == ""
        milkName = "some milk"
    EndIf
    MMENPCDialog.TraceDialogueTiming("11E3 milk name resolved", target)
    String rendered = RenderToken(template, "{actor}", actorName)
    MMENPCDialog.TraceDialogueTiming("11E4 actor token rendered", target)
    rendered = RenderToken(rendered, "{milk}", milkName)
    MMENPCDialog.TraceDialogueTiming("11E5 milk token rendered", target)
    If rendered == ""
        MMELog.Alarm("[MME Extensions Drink Reaction] FAILURE: JSON reaction rendered as blank")
    EndIf
    Return rendered
EndFunction

String Function SelectNotificationTemplate(Actor target, Int sex, Bool establishedMilkmaid, Float milkAdded, Bool arousalSent) Global
    String configFile = "/MMEAlerts/NonMilkmaidDrinkNotifications"
    String pool = ".female_generic"
    If establishedMilkmaid && milkAdded > 0.0 && arousalSent
        pool = ".female_milk_arousal"
    ElseIf establishedMilkmaid && milkAdded > 0.0
        pool = ".female_milk"
    ElseIf sex == 0 && arousalSent
        pool = ".male_aroused"
    ElseIf sex == 0
        pool = ".male_generic"
    ElseIf arousalSent
        pool = ".female_aroused"
    EndIf

    MMENPCDialog.TraceDialogueTiming("11E0A notification JSON validation", target)
    If !JsonUtil.JsonExists(configFile) || !JsonUtil.IsGood(configFile)
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: notification JSON is missing or malformed; using fallback text")
        Return "{actor} drinks {milk}. It tastes fabulous."
    EndIf
    MMENPCDialog.TraceDialogueTiming("11E0B notification JSON pool read", target)
    String[] entries = JsonUtil.PathStringElements(configFile, pool)
    If entries.Length == 0
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: notification JSON pool is empty: " + pool)
        Return "{actor} drinks {milk}. It tastes fabulous."
    EndIf
    String selected = entries[Utility.RandomInt(0, entries.Length - 1)]
    If selected == ""
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: notification JSON returned a blank entry: " + pool)
        Return "{actor} drinks {milk}. It tastes fabulous."
    EndIf
    MMENPCDialog.TraceDialogueTiming("11E0C notification JSON entry selected", target)
    Return selected
EndFunction

String Function RenderToken(String source, String token, String replacement) Global
    Int tokenIndex = StringUtil.Find(source, token)
    If tokenIndex < 0
        Return source
    EndIf
    String beforeToken = ""
    If tokenIndex > 0
        beforeToken = StringUtil.Substring(source, 0, tokenIndex)
    EndIf
    String afterToken = StringUtil.Substring(source, tokenIndex + StringUtil.GetLength(token))
    Return beforeToken + replacement + afterToken
EndFunction
