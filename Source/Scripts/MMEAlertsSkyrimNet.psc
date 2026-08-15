Scriptname MMEAlertsSkyrimNet extends Quest

Bool Function IsAvailable() Global
    Return Game.GetModByName("SkyrimNet.esp") != 255
EndFunction

; Registers the callback used by the optional actor-specific Milkmaid bio prompt.
Function RegisterPromptDecorator() Global
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetPromptDiagnostic", 1) == 1
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Prompt: registration skipped - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid prompt decorator skipped; SkyrimNet not detected")
        Return
    EndIf
    Int result = SkyrimNetApi.RegisterDecorator("mme_milkmaid_prompt_debug", "MMEAlertsSkyrimNet", "MilkmaidPromptDebug")
    If diagnostic
        If result == 0
            Debug.Notification("Skyrim.Net Prompt: debug callback registered [0]")
        Else
            Debug.Notification("Skyrim.Net Prompt: registration returned [" + result + "] - it may already be registered")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milkmaid prompt decorator registration result " + result)
EndFunction

; Returns an explicit string gate because prompt values may not preserve Papyrus numeric types.
String Function MilkmaidPromptDebug(Actor milkMaid) Global
    If milkMaid == None
        Return ""
    EndIf
    If !StorageUtil.HasFloatValue(milkMaid, "MME.MilkMaid.Level")
        Return ""
    EndIf

    Float level = StorageUtil.GetFloatValue(milkMaid, "MME.MilkMaid.Level", -1.0)
    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "unnamed actor"
    EndIf
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetPromptDiagnostic", 1) == 1
        Debug.Notification("Skyrim.Net Prompt: Milkmaid lore rendered for " + actorName + " | MME level " + level)
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Milkmaid lore rendered for " + actorName + " | MME level " + level)
    Return "true"
EndFunction

; Global entry points let the established controller call SkyrimNet directly.
; They do not depend on a newly attached quest-script instance in existing saves.
Function SendMilkingStart(Actor milkMaid) Global
    SendMilkingEvent(milkMaid, "startMessage")
EndFunction

Function SendMilkingEnd(Actor milkMaid) Global
    SendMilkingEvent(milkMaid, "endMessage")
EndFunction

; Publishes one replaceable five-minute summary from the existing capacity scan.
Function SendNearbyMilkStatuses(Actor playerActor, String statuses, Int scannedCount, Int milkmaidCount) Global
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetStatusDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkStatuses", 1) != 1
        Return
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses failed - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; milk statuses skipped")
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses failed - bridge disabled in JSON")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milk statuses skipped; JSON bridge disabled")
        Return
    EndIf
    If playerActor == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses failed - player missing")
        EndIf
        Return
    EndIf
    If milkmaidCount <= 0 || statuses == ""
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses skipped - no nearby Milkmaids")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milk statuses skipped; no nearby Milkmaids")
        Return
    EndIf

    String content = "**Current milk levels:** " + statuses
    Float interval = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "skyrimNetStatusInterval", 15.0)
    Int ttlMs = (interval * 1000.0) as Int
    Debug.Trace("[MMEAlert SkyrimNet] Calling milk_statuses_player | interval " + interval + " | TTL " + ttlMs + " | " + content)
    Int result = SkyrimNetApi.RegisterShortLivedEvent("milk_statuses_player", "milk_statuses", content, "{}", ttlMs, playerActor, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milk statuses rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected milk statuses (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Status: accepted | " + milkmaidCount + " Milkmaids | " + interval + "s")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent timed milk statuses event: " + content)
    EndIf
EndFunction

; Records a confirmed false-to-true Milkmaid transition in SkyrimNet history.
Function SendMilkmaidCreated(Actor milkMaid) Global
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetCreationDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkmaidCreated", 1) != 1
        Return
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created handler reached")
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; Milkmaid creation event skipped")
        Return
    EndIf
    If milkMaid == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - actor missing")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid creation event skipped; actor was None")
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - bridge disabled in JSON")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid creation event skipped; JSON bridge disabled")
        Return
    EndIf

    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "The actor"
    EndIf
    String defaultMessage = "{actor} has become a Milk Maid! Her breasts now feel pleasantly heavy, full, and faintly thrilling."
    String template = JsonUtil.GetStringValue(settingsFile, "milkmaidCreatedMessage", defaultMessage)
    If template == ""
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created failed - message empty")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Milkmaid creation event skipped; message was empty")
        Return
    EndIf
    String content = RenderMessage(template, actorName)
    EnsureMilkmaidCreatedSchema(diagnostic)
    String actorUuid = SkyrimNetApi.GetEntityUUID(milkMaid)
    If actorUuid == ""
        actorUuid = "<empty>"
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: milkmaid_created | " + actorName + " | UUID " + actorUuid)
        Debug.Notification("Skyrim.Net Diagnostic payload: " + content)
    EndIf
    String eventData = "{\"content\":\"" + EscapeJsonString(content) + "\"}"
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic event data: " + eventData)
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Calling persistent milkmaid_created | actor " + actorName + " | UUID " + actorUuid + " | " + eventData)
    Int result = SkyrimNetApi.RegisterEvent("milkmaid_created", eventData, milkMaid, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: persistent event rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected milkmaid_created for " + actorName + " (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: persistent event accepted [0]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent persistent milkmaid_created event: " + content)
    EndIf
EndFunction

; Escapes user-facing actor names before embedding them in structured event JSON.
String Function EscapeJsonString(String value) Global
    value = ReplaceAll(value, "\\", "\\\\")
    value = ReplaceAll(value, "\"", "\\\"")
    Return value
EndFunction

String Function ReplaceAll(String value, String token, String replacement) Global
    Int tokenLength = StringUtil.GetLength(token)
    If tokenLength <= 0
        Return value
    EndIf
    String result = ""
    Int start = 0
    Int found = StringUtil.Find(value, token, start)
    While found >= 0
        result = result + StringUtil.Substring(value, start, found - start) + replacement
        start = found + tokenLength
        found = StringUtil.Find(value, token, start)
    EndWhile
    Return result + StringUtil.Substring(value, start)
EndFunction

; Gives SkyrimNet a clean body format instead of its unknown-type [event_type] fallback.
Function EnsureMilkmaidCreatedSchema(Bool diagnostic) Global
    If SkyrimNetApi.IsEventTypeRegistered("milkmaid_created")
        Return
    EndIf
    String fieldsJson = "[{\"name\":\"content\",\"type\":0,\"required\":true,\"description\":\"Milkmaid creation description\"}]"
    String formatsJson = "{\"recent_events\":\"{{content}}\",\"raw\":\"{{content}}\",\"compact\":\"{{content}}\",\"verbose\":\"{{content}}\"}"
    Int result = SkyrimNetApi.RegisterEventSchema("milkmaid_created", "milkmaid created", "An actor became an MME Milkmaid.", fieldsJson, formatsJson, False, 0)
    If diagnostic
        If result == 0
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid schema registered [0]")
        Else
            Debug.Notification("Skyrim.Net Diagnostic: milkmaid schema rejected [" + result + "]")
        EndIf
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] milkmaid_created schema result " + result)
EndFunction

; Publishes the player's latest drink into scene context for ninety seconds.
Function SendMilkDrink(Actor drinker, Form drinkItem) Global
    String settingsFile = "/MMEAlerts/SkyrimNet"
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetDrinkDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkDrinks", 1) != 1
        Return
    EndIf
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
    Int result = SkyrimNetApi.RegisterShortLivedEvent("milk_drink_player", "milk_drink", content, "{}", ttlMs, drinker, None)
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
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkingDiagnostic", 0) == 1
    If JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableSkyrimNetMilkingEvents", 1) != 1
        Return
    EndIf
    String eventId = "milking_start"
    String eventType = "milking_start"
    If messageKey == "endMessage"
        eventId = "milking_end"
        eventType = "milking_end"
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " handler reached")
    EndIf
    If !IsAvailable()
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - SkyrimNet not detected")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet.esp is not enabled; milking event skipped")
        Return
    EndIf
    String settingsFile = "/MMEAlerts/SkyrimNet"
    If milkMaid == None
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - actor missing")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] " + eventType + " skipped; actor was None")
        Return
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enabled", 1) != 1
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - bridge disabled in JSON")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] " + eventType + " skipped; JSON bridge disabled")
        Return
    EndIf

    String actorName = milkMaid.GetDisplayName()
    If actorName == ""
        actorName = "The Milk Maid"
    EndIf

    String defaultMessage = "{actor} is milking herself and is feeling orgasmic!"
    If messageKey == "endMessage"
        defaultMessage = "{actor} has finished milking, utterly satisfied."
    EndIf
    String template = JsonUtil.GetStringValue(settingsFile, messageKey, defaultMessage)
    If template == ""
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " failed - message empty")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Empty message for " + messageKey + "; event skipped")
        Return
    EndIf

    String content = RenderMessage(template, actorName)
    Int ttlMs = JsonUtil.GetIntValue(settingsFile, "milkingTtlMs", 60000)
    String actorUuid = SkyrimNetApi.GetEntityUUID(milkMaid)
    If actorUuid == ""
        actorUuid = "<empty>"
    EndIf
    If diagnostic
        Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " | " + actorName + " | UUID " + actorUuid + " | TTL " + ttlMs)
        Debug.Notification("Skyrim.Net Diagnostic payload: " + content)
        Debug.Notification("Skyrim.Net Diagnostic: calling short-lived API")
    EndIf
    Debug.Trace("[MMEAlert SkyrimNet] Calling " + eventType + " | actor " + actorName + " | UUID " + actorUuid + " | TTL " + ttlMs + " | " + content)
    Int result = SkyrimNetApi.RegisterShortLivedEvent(eventId, eventType, content, "{}", ttlMs, milkMaid, None)
    If result != 0
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " rejected [" + result + "]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] SkyrimNet rejected " + messageKey + " for " + actorName + " (code " + result + ")")
    Else
        If diagnostic
            Debug.Notification("Skyrim.Net Diagnostic: " + eventType + " accepted [0]")
        EndIf
        Debug.Trace("[MMEAlert SkyrimNet] Sent 60-second " + eventType + " event: " + content)
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
