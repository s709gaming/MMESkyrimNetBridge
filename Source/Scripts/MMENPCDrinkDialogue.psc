Scriptname MMENPCDrinkDialogue Hidden

; Adult non-Milkmaid branch for Give Milk. It deliberately owns no MME milk,
; capacity, Lactacid, conversion, or Skyrim.Net behavior.
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

Function ApplyPostDrink(Actor target, Form drinkItem, Bool diagnostic = False) Global
    If target == None || drinkItem == None
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: post-drink effects received a missing actor or milk item")
        Return
    EndIf
    ActorBase baseInfo = target.GetLeveledActorBase()
    If baseInfo == None
        MMELog.Alarm("[MME Extensions Universal Drink] FAILURE: post-drink effects could not resolve the receiver ActorBase")
        Return
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
    ShowNotification(target, drinkItem, sex, arousalSent)
    MMENPCDialog.TraceDialogueTiming("11F non-Milkmaid notification complete", target)
EndFunction

Function ShowNotification(Actor target, Form drinkItem, Int sex, Bool arousalSent) Global
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableNonMilkmaidDrinkNotifications", 1) != 1
        Return
    EndIf
    ; Reuse the proven MMEThoughts JSON pipeline: validate, load one pool,
    ; choose one complete entry, then render it with the one-pass token helper.
    String template = SelectNotificationTemplate(target, sex, arousalSent)
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
    Debug.Notification(rendered)
    MMENPCDialog.TraceDialogueTiming("11E6 HUD notification returned", target)
EndFunction

String Function SelectNotificationTemplate(Actor target, Int sex, Bool arousalSent) Global
    String configFile = "/MMEAlerts/NonMilkmaidDrinkNotifications"
    String pool = ".female_generic"
    If sex == 0 && arousalSent
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
