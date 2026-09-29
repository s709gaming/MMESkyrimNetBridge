Scriptname MMEOManiaCompatibility Hidden

String Function GetConfigFile() Global
    ; JsonUtil filenames are relative to Data/SKSE/Plugins/StorageUtilData.
    Return "MMEAlerts/OManiaCompatibility"
EndFunction

; Optional OMania bridge. Keep every call to the external OMania script in this
; isolated class so installations without OMania never enter its bytecode.
Bool Function IsEnabled() Global
    ; OMania.esp is ESL-flagged. GetModByName only describes the regular
    ; plugin table, so use a load-order-independent form probe instead.
    Return IsRequested() && GetDragonEggConcoction() != None
EndFunction

Potion Function GetDragonEggConcoction() Global
    Return MMEExtensionsNative.GetFormByEditorID("OManiaPotionEggDragon") as Potion
EndFunction

Bool Function IsRequested() Global
    String configFile = GetConfigFile()
    ; The FOMOD installs this file only when the visible compatibility choice
    ; is selected. Its presence is therefore the authoritative opt-in; default
    ; enabled keeps a valid installed marker from being defeated by a stale or
    ; not-yet-loaded JsonUtil cache.
    If !JsonUtil.JsonExists(configFile)
        Return False
    EndIf
    If !JsonUtil.IsGood(configFile)
        JsonUtil.Load(configFile)
    EndIf
    Return JsonUtil.GetIntValue(configFile, "enabled", 1) == 1
EndFunction

Function ReportUnavailableOnce() Global
    If !IsRequested() \
    || IsEnabled() \
    || StorageUtil.GetIntValue(None, "MMEExtensions.OMania.UnavailableAlarmShown", 0) != 0
        Return
    EndIf
    StorageUtil.SetIntValue(None, "MMEExtensions.OMania.UnavailableAlarmShown", 1)
    Debug.Notification("MME/OMania compatibility is installed, but its Dragon Egg Concoction could not be resolved.")
    MMELog.Alarm("[MME Extensions OMania] COMPATIBILITY INACTIVE | marker enabled but OManiaPotionEggDragon could not be resolved; verify OMania.esp and MMEExtensions.dll are loaded")
EndFunction

; OMania 4.0.3 exposes no supported breast-morph settings setter. Record and
; explain that boundary once per save instead of overwriting its private JSON.
; Deliberately do not claim the requested one-shot has completed: a future
; OMania API can replace this function without migrating a false success latch.
Function ReportBreastScalingAPIStatusOnce() Global
    If !IsEnabled() \
    || JsonUtil.GetIntValue(GetConfigFile(), "disableBreastScalingOnce", 1) != 1 \
    || StorageUtil.GetIntValue(None, "MMEExtensions.OMania.BreastScalingNoticeShown", 0) != 0
        Return
    EndIf
    StorageUtil.SetIntValue(None, "MMEExtensions.OMania.BreastScalingNoticeShown", 1)
    Debug.Notification("MME/OMania: disable OMania breast morphs in OMania settings; version 4.0.3 has no setter API.")
    MMELog.Alarm("[MME Extensions OMania] breast scaling was not changed: OMania 4.0.3 exposes no supported settings setter; private OMania_Settings.json was intentionally left untouched")
EndFunction

; Converts at most one loaded pregnancy per pass. The controller owns the
; cadence, while OMania remains the sole pregnancy authority and MME remains
; the sole Milk Maid registry/capacity authority.
Bool Function ConvertOneNearbyPregnancy(Float radius = 2000.0) Global
    If !IsEnabled() \
    || JsonUtil.GetIntValue(GetConfigFile(), "pregnancyCreatesMilkMaid", 1) != 1
        Return False
    EndIf
    Actor[] nearbyActors = MMEExtensionsNative.GetNearbyActors(radius)
    If nearbyActors == None
        Return False
    EndIf
    Int index = 0
    While index < nearbyActors.Length
        Actor candidate = nearbyActors[index]
        If IsSafeCandidate(candidate) \
        && StorageUtil.GetFloatValue(candidate, "MMEExtensions.OMania.ConversionRetryGameTime", 0.0) <= Utility.GetCurrentGameTime() \
        && OMania.IsPregnant(candidate) \
        && !MMEExtensionsAPI.IsMilkMaid(candidate)
            MMELog.Diagnostic("[MME Extensions OMania] pregnancy detected; requesting forced Milk Maid conversion | target=" + candidate)
            Bool converted = MMEExtensionsAPI.TryCreateMilkMaidForcedAnimated(candidate)
            If !converted
                ; Avoid notification churn when MME capacity or an animation
                ; prerequisite is temporarily unavailable.
                StorageUtil.SetFloatValue(candidate, "MMEExtensions.OMania.ConversionRetryGameTime", Utility.GetCurrentGameTime() + 0.006944)
            EndIf
            Return converted
        EndIf
        index += 1
    EndWhile
    Return False
EndFunction

Bool Function IsSafeCandidate(Actor candidate) Global
    If candidate == None \
    || candidate.IsDead() \
    || candidate.IsDisabled() \
    || !candidate.Is3DLoaded() \
    || candidate.IsChild() \
    || candidate.IsInCombat() \
    || candidate.IsOnMount()
        Return False
    EndIf
    ActorBase candidateBase = candidate.GetLeveledActorBase()
    Return candidateBase != None && candidateBase.GetSex() == 1
EndFunction

; Explicit Troubleshoot action. It deliberately has no one-time latch and no
; pregnancy/Milk Maid gate: every successful button press adds exactly one of
; OMania's native test consumables.
Bool Function SpawnDragonEggPotion(Actor target) Global
    If target == None
        Debug.Notification("MME/OMania: player reference is unavailable.")
        MMELog.Alarm("[MME Extensions OMania] potion spawn failed: player reference is unavailable")
        Return False
    EndIf
    Potion concoction = GetDragonEggConcoction()
    If concoction == None
        Debug.Notification("MME/OMania: Dragon Egg Concoction could not be resolved.")
        MMELog.Alarm("[MME Extensions OMania] potion spawn failed: OManiaPotionEggDragon could not be resolved")
        Return False
    EndIf
    Int countBefore = target.GetItemCount(concoction)
    target.AddItem(concoction, 1, False)
    Int countAfter = target.GetItemCount(concoction)
    If countAfter <= countBefore
        Debug.Notification("MME/OMania: potion resolved, but AddItem did not increase its count.")
        MMELog.Alarm("[MME Extensions OMania] potion spawn failed: AddItem did not increase inventory count | before=" + countBefore + " after=" + countAfter)
        Return False
    EndIf
    Debug.Notification("MME/OMania: added one Dragon Egg Concoction.")
    MMELog.Status("[MME Extensions OMania] potion spawned from Troubleshoot | before=" + countBefore + " after=" + countAfter)
    Return True
EndFunction
