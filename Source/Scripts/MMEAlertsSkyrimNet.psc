Scriptname MMEAlertsSkyrimNet extends Quest

Bool Function IsAvailable() Global
    Return Game.GetModByName("SkyrimNet.esp") != 255
EndFunction

; Global entry points let the established controller call SkyrimNet directly.
; They do not depend on a newly attached quest-script instance in existing saves.
Function SendMilkingStart(Actor milkMaid) Global
    SendMilkingEvent(milkMaid, "startMessage")
EndFunction

Function SendMilkingEnd(Actor milkMaid) Global
    SendMilkingEvent(milkMaid, "endMessage")
EndFunction

; Publishes the player's latest drink into scene context for ninety seconds.
Function SendMilkDrink(Actor drinker, Form drinkItem) Global
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetDiagnostic", 1) == 1
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; drink event skipped")
        Return
    EndIf
    If drinker == None || drinkItem == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: missing drinker or item")
        EndIf
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: bridge disabled in JSON")
        EndIf
        Return
    EndIf

    String itemName = drinkItem.GetName()
    If itemName == ""
        itemName = "an unnamed milk"
    EndIf
    String actorName = drinker.GetDisplayName()
    If actorName == ""
        actorName = "The player"
    EndIf

    String template = JsonUtil.GetStringValue(settingsFile, "drinkMessage", "{actor} drank {item}.")
    String content = RenderToken(template, "{actor}", actorName)
    content = RenderToken(content, "{item}", itemName)
    If diagnostic
        String buildVersion = SkyrimNetApi.GetBuildVersion()
        String buildType = SkyrimNetApi.GetBuildType()
        String actorUuid = SkyrimNetApi.GetEntityUUID(drinker)
        If actorUuid == ""
            actorUuid = "<empty>"
        EndIf
        Debug.Notification("Skyrim.Net Diagnostic: v" + buildVersion + " " + buildType + " | player UUID " + actorUuid)
        Debug.Notification("Skyrim.Net Diagnostic payload: " + content)
    EndIf
    Int ttlMs = JsonUtil.GetIntValue(settingsFile, "drinkTtlMs", 90000)
    Int result = SkyrimNetApi.RegisterShortLivedEvent("mme_milk_drink_player", "mme_milk_drink", content, "{}", ttlMs, drinker, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: short-lived event rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected milk drink event for " + actorName + " (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: short-lived event accepted [0]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent 90-second milk drink event: " + content)
    EndIf
EndFunction

Function SendMilkingEvent(Actor milkMaid, String messageKey) Global
    If !IsAvailable()
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; milking event skipped")
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    If milkMaid == None || JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        Return
    EndIf

    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "The Milk Maid"
    EndIf

    String template = JsonUtil.GetStringValue(settingsFile, messageKey, "")
    If template == ""
        Debug.Trace("[MMEAlert SkyrimNet] Empty message for " + messageKey + "; event skipped")
        Return
    EndIf

    String content = RenderMessage(template, actorName)
    Int result = SkyrimNetApi.RegisterPersistentEvent(content, milkMaid, None)
    If result != 0
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected " + messageKey + " for " + actorName + " (code " + result + ")")
    Else
        Debug.Trace("[MMEAlert SkyrimNet] Sent persistent event: " + content)
    EndIf
EndFunction

String Function RenderMessage(String template, String actorName) Global
    Return RenderToken(template, "{actor}", actorName)
EndFunction

String Function RenderToken(String template, String token, String value) Global
    Int tokenIndex = StringUtil.Find(template, token)
    If tokenIndex < 0
        Return template
    EndIf

    String beforeToken = ""
    If tokenIndex > 0
        beforeToken = StringUtil.Substring(template, 0, tokenIndex)
    EndIf
    String afterToken = StringUtil.Substring(template, tokenIndex + StringUtil.GetLength(token))
    Return beforeToken + value + afterToken
EndFunction
