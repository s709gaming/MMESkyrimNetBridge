Scriptname MMEBreastBounceEffects Hidden

; Stateless presentation and candidate selection for the controller-owned
; breast-bounce schedule. No movement polling is performed: the notification
; is periodic flavor, not a claim that an OnMove event was observed.

String Function GetSettingsFile() Global
    Return "/MMEAlerts/Settings"
EndFunction

Bool Function IsEnabled() Global
    String settingsFile = GetSettingsFile()
    Return JsonUtil.GetIntValue(settingsFile, "enableMMEExtensions", 1) == 1 \
        && (JsonUtil.GetIntValue(settingsFile, "enableBreastBounceNotifications", 1) == 1 \
        || JsonUtil.GetIntValue(settingsFile, "enableBreastBounceSounds", 1) == 1)
EndFunction

Float Function CalculateNextInterval() Global
    String settingsFile = GetSettingsFile()
    Float baseInterval = JsonUtil.GetFloatValue(settingsFile, "breastBounceIntervalHours", 24.0)
    Float variation = JsonUtil.GetFloatValue(settingsFile, "breastBounceVariationHours", 4.0)
    If baseInterval < 1.0
        baseInterval = 1.0
    ElseIf baseInterval > 36.0
        baseInterval = 36.0
    EndIf
    If variation < 0.0
        variation = 0.0
    ElseIf variation > 12.0
        variation = 12.0
    EndIf
    Float allowedVariation = baseInterval - 1.0
    If variation > allowedVariation
        variation = allowedVariation
    EndIf
    Float result = baseInterval
    If variation > 0.0
        result = baseInterval + Utility.RandomFloat(-variation, variation)
    EndIf
    If result < 1.0
        result = 1.0
    EndIf
    Return result
EndFunction

Float Function CalculatePresentationDelay() Global
    Float maximumDelay = JsonUtil.GetFloatValue(GetSettingsFile(), "breastBounceMaximumDelaySeconds", 30.0)
    If maximumDelay < 0.0
        maximumDelay = 0.0
    ElseIf maximumDelay > 60.0
        maximumDelay = 60.0
    EndIf
    If maximumDelay <= 0.0
        Return 0.0
    EndIf
    Return Utility.RandomFloat(0.0, maximumDelay)
EndFunction

Actor Function SelectCandidate(Actor[] scannedActors) Global
    If scannedActors.Length == 0
        Report("cycle skipped: nearby scan returned no actors")
        Return None
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        MMELog.Alarm("[MME Extensions Breast Bounce] FAILURE: MME_MilkQUEST is unavailable")
        Return None
    EndIf
    Actor selected = None
    Int eligibleCount = 0
    Int i = 0
    While i < scannedActors.Length
        Actor candidate = scannedActors[i]
        If IsValidCandidate(candidate, milkController)
            eligibleCount += 1
            ; Reservoir sampling chooses uniformly without allocating another array.
            If Utility.RandomInt(1, eligibleCount) == 1
                selected = candidate
            EndIf
        EndIf
        i += 1
    EndWhile
    If selected == None
        Report("cycle skipped: no nearby adult female Milk Maid")
    Else
        Report("candidate selected | actor=" + GetActorName(selected) + " | eligible=" + eligibleCount)
    EndIf
    Return selected
EndFunction

Bool Function IsValidCandidate(Actor candidate, MilkQUEST milkController) Global
    If candidate == None || !candidate.Is3DLoaded() || candidate.IsChild()
        Return False
    EndIf
    ActorBase baseData = candidate.GetActorBase()
    If baseData == None || baseData.GetSex() != 1
        Return False
    EndIf
    Return MMEArmorScript.IsValidMilkMaid(candidate, milkController)
EndFunction

Bool Function Present(Actor candidate) Global
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If !IsEnabled()
        Report("presentation canceled: feature disabled during delay")
        Return False
    EndIf
    If !IsValidCandidate(candidate, milkController)
        Report("presentation skipped: selected actor is no longer available")
        Return False
    EndIf
    Float maximum = MME_Storage.getMilkMaximum(candidate)
    If maximum <= 0.0
        MMELog.Alarm("[MME Extensions Breast Bounce] FAILURE: invalid maximum milk | actor=" + GetActorName(candidate) + " | maximum=" + maximum)
        Return False
    EndIf
    Float current = MME_Storage.getMilkCurrent(candidate)
    Bool high = (current / maximum) >= 0.5
    String tier = "low"
    If high
        tier = "high"
    EndIf
    String settingsFile = GetSettingsFile()
    If JsonUtil.GetIntValue(settingsFile, "enableBreastBounceNotifications", 1) == 1
        String notificationText = GetNotification(candidate, tier)
        If notificationText != ""
            Debug.Notification(notificationText)
        EndIf
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableBreastBounceSounds", 1) == 1 \
            && JsonUtil.GetIntValue(settingsFile, "enableReactionSounds", 1) == 1
        PlaySounds(candidate, high)
    EndIf
    Report("presentation complete | actor=" + GetActorName(candidate) + " | tier=" + tier + " | milk=" + current + "/" + maximum)
    Return True
EndFunction

String Function GetNotification(Actor candidate, String tier) Global
    String configFile = "/MMEAlerts/BreastBounceNotifications"
    If !MMENarrationOverrides.FileAvailable(configFile)
        MMELog.Alarm("[MME Extensions Breast Bounce] FAILURE: BreastBounceNotifications.json is missing or malformed")
        Return ""
    EndIf
    String[] entries = MMENarrationOverrides.Pool(configFile, "." + tier, candidate)
    If entries.Length == 0
        MMELog.Alarm("[MME Extensions Breast Bounce] FAILURE: notification pool is empty | tier=" + tier)
        Return ""
    EndIf
    String rendered = MMEThoughts.RenderActorToken(entries[Utility.RandomInt(0, entries.Length - 1)], GetActorName(candidate))
    If rendered == ""
        MMELog.Alarm("[MME Extensions Breast Bounce] FAILURE: notification is missing a usable {actor} token | tier=" + tier)
    EndIf
    Return rendered
EndFunction

Function PlaySounds(Actor candidate, Bool high) Global
    Int moanMarker = 0x000854
    If high
        moanMarker = 0x000855
    EndIf
    PlayMarker(candidate, moanMarker, "moan")
    If high
        PlayMarker(candidate, 0x0008B1, "breast slap")
    EndIf
EndFunction

Function PlayMarker(Actor candidate, Int markerFormID, String label, String pluginName = "MMEAlert.esp") Global
    Sound reaction = Game.GetFormFromFile(markerFormID, pluginName) as Sound
    If reaction == None
        MMELog.Alarm("[MME Extensions Breast Bounce] FAILURE: " + label + " sound marker unresolved | form=" + markerFormID)
        Return
    EndIf
    Int instance = reaction.Play(candidate)
    If instance <= 0
        Report(label + " sound did not start | actor=" + GetActorName(candidate))
        Return
    EndIf
    Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(GetSettingsFile(), "reactionSoundVolume", 100.0) / 100.0)
EndFunction

String Function GetActorName(Actor candidate) Global
    Return MMEThoughts.ResolveActorName(candidate)
EndFunction

Function Report(String reportText) Global
    MMELog.MasterDiagnostic("[MME Extensions Breast Bounce] " + reportText)
EndFunction
