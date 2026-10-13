Scriptname MMEElsieBreastfeeding Hidden

String Function GetConfigFile() Global
    Return "MMEAlerts/ElsieCompatibility"
EndFunction

Bool Function IsDetected() Global
    ; Elsie 3.4 owns this stable controller quest. The form probe also remains
    ; valid if a user later ESL-flags the plugin, unlike a regular-index test.
    Return Game.GetFormFromFile(0x005E57, "CP_Elsie.esp") != None
EndFunction

Bool Function IsPatchInstalled() Global
    String configFile = GetConfigFile()
    If !JsonUtil.JsonExists(configFile)
        Return False
    EndIf
    If !JsonUtil.IsGood(configFile)
        JsonUtil.Load(configFile)
    EndIf
    Return JsonUtil.GetIntValue(configFile, "enabled", 1) == 1
EndFunction

Bool Function IsAvailable() Global
    Return IsDetected() && IsPatchInstalled()
EndFunction

Bool Function IsEnabled() Global
    Return IsAvailable() && JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableElsieBreastfeedingMilkEffects", 1) == 1
EndFunction

; Elsie uses its private ELV_Taste registrar for autonomous milk-tasting scenes.
; Keep that identity inside this compatibility facade so the generic SexLab
; transaction does not acquire Elsie-specific form or configuration knowledge.
Bool Function IsTasteAnimation(MilkQUEST milkController, sslThreadController thread) Global
    If !IsDetected() || milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None || thread == None
        Return False
    EndIf
    sslBaseAnimation tasteAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("ELV_Taste")
    Return tasteAnimation != None && thread.Animation == tasteAnimation
EndFunction

Bool Function IsSafeParticipant(Actor participant) Global
    Return participant != None && !participant.IsDead() && !participant.IsDisabled() && participant.Is3DLoaded() && !participant.IsChild()
EndFunction

Int Function StartAutonomousFeed(Actor milkSource, Actor drinker, String caller = "Elsie") Global
    String prefix = "[MME Extensions Elsie BF] "
    MMELog.MasterDiagnostic(prefix + "request | caller=" + caller + " | source=" + milkSource + " | drinker=" + drinker)

    If !IsAvailable()
        MMELog.Alarm(prefix + "ROUTE CLOG | autonomous feed requested without Elsie compatibility patch | caller=" + caller)
        Return -1
    EndIf
    If !IsSafeParticipant(milkSource)
        MMELog.Alarm(prefix + "ROUTE CLOG | invalid or unloaded Milk Maid source | caller=" + caller + " | source=" + milkSource)
        Return -1
    EndIf
    If !IsSafeParticipant(drinker)
        MMELog.Alarm(prefix + "ROUTE CLOG | invalid or unloaded customer | caller=" + caller + " | drinker=" + drinker)
        Return -1
    EndIf
    If milkSource == drinker
        MMELog.Alarm(prefix + "ROUTE CLOG | source and customer resolve to the same actor | caller=" + caller + " | actor=" + milkSource)
        Return -1
    EndIf
    If !StorageUtil.HasFloatValue(milkSource, "MME.MilkMaid.Level")
        MMELog.Alarm(prefix + "ROUTE CLOG | autonomous source is not an MME Milk Maid | caller=" + caller + " | source=" + milkSource)
        Return -1
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        MMELog.Alarm(prefix + "FAILURE | MME or SexLab could not resolve | caller=" + caller)
        Return -1
    EndIf
    If milkController.SexLab.IsActorActive(milkSource) || milkController.SexLab.IsActorActive(drinker)
        MMELog.MasterDiagnostic(prefix + "skipped | participant already active in SexLab | caller=" + caller + " | source=" + milkSource + " | drinker=" + drinker)
        Return -1
    EndIf

    String backend = MMESexLabBreastfeedingBackend.GetBackendName()
    MMELog.MasterDiagnostic(prefix + "starting SexLab scene | caller=" + caller + " | backend=" + backend + " | source=" + milkSource + " | drinker=" + drinker)
    Int threadID = MMESexLabBreastfeedingBackend.StartBreastfeeding(milkController, milkSource, drinker, "MMEExtensionsElsieBreastfeeding")
    ; ELV_Taste is a legacy Elsie registrar and has no known SLSB conversion.
    ; Preserve it only as a Standard SexLab fallback.
    If threadID < 0 && !MMESexLabBreastfeedingBackend.IsPPlus()
        sslBaseAnimation tasteAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("ELV_Taste")
        If tasteAnimation != None
            Actor[] participants = new Actor[2]
            participants[0] = milkSource
            participants[1] = drinker
            sslBaseAnimation[] animations = new sslBaseAnimation[1]
            animations[0] = tasteAnimation
            threadID = milkController.SexLab.StartSex(participants, animations)
        EndIf
    EndIf
    If threadID < 0
        MMELog.Alarm(prefix + "FAILURE | SexLab rejected autonomous breastfeeding scene | caller=" + caller + " | backend=" + backend)
        Return -1
    EndIf
    MMELog.MasterDiagnostic(prefix + "scene start accepted | caller=" + caller + " | backend=" + backend + " | thread=" + threadID)
    Return threadID
EndFunction

Bool Function RunNearbyTest() Global
    Actor playerActor = Game.GetPlayer()
    Actor milkSource = None
    Actor drinker = None
    ; Papyrus can emit an invalid None-to-Actor[] cast for direct array
    ; initialization. Keep declaration and assignment separate.
    Actor[] nearbyActors
    nearbyActors = MMEExtensionsNative.GetNearbyActors(2000.0)
    Int index = 0
    ; The native function always returns a vector (empty only if runtime
    ; singletons are unavailable), so the length check is the safe guard.
    While index < nearbyActors.Length
        Actor candidate = nearbyActors[index]
        If candidate != playerActor && IsSafeParticipant(candidate)
            If milkSource == None && StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.Level")
                milkSource = candidate
            ElseIf drinker == None
                drinker = candidate
            EndIf
        EndIf
        index += 1
    EndWhile

    If milkSource != None
        drinker = playerActor
    ElseIf IsSafeParticipant(playerActor) && StorageUtil.HasFloatValue(playerActor, "MME.MilkMaid.Level")
        milkSource = playerActor
    EndIf
    If milkSource == playerActor && (drinker == None || drinker == playerActor)
        index = 0
        While index < nearbyActors.Length && drinker == None
            Actor candidate = nearbyActors[index]
            If candidate != playerActor && IsSafeParticipant(candidate)
                drinker = candidate
            EndIf
            index += 1
        EndWhile
    EndIf
    If milkSource == None || drinker == None || milkSource == drinker
        MMELog.Alarm("[MME Extensions Elsie BF] TEST FAILURE | no nearby Milk Maid/customer pair could be selected")
        Debug.Notification("Elsie test failed: no nearby Milk Maid and customer.")
        Return False
    EndIf

    Int threadID = StartAutonomousFeed(milkSource, drinker, "MCM Test")
    If threadID < 0
        Debug.Notification("Elsie breastfeeding test could not start. Check Papyrus log.")
        Return False
    EndIf
    Debug.Notification("Elsie breastfeeding test started.")
    Return True
EndFunction
