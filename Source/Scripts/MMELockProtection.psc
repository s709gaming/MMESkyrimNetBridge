Scriptname MMELockProtection Hidden

Bool Function IsEnabled() Global
    Return JsonUtil.GetIntValue("/MMEAlerts/Settings", "enableMMEExtensions", 1) == 1
EndFunction

; No framework script types: OStim and SexLab are independently optional.
; Native work is bounded and confirmed, never confused with queue acceptance.
Int Function Apply(Actor target, Armor targetArmor) Global
    If target == None
        Return -1
    EndIf
    If targetArmor != None && !IsEnabled()
        Return -2
    EndIf
    Int token = MMEExtensionsNative.QueueLockProtection(target, targetArmor)
    Int result = -1
    If token > 0
        result = MMEExtensionsNative.GetLockProtectionResult(target, token)
        Int attempts = 0
        While result == 0 && attempts < 40
            Utility.WaitMenuMode(0.05)
            result = MMEExtensionsNative.GetLockProtectionResult(target, token)
            attempts += 1
        EndWhile
    EndIf
    If result == 1
        StorageUtil.UnsetIntValue(target, "MMEExtensions.LockProtection.Failed")
        MMELog.MasterDiagnostic("[MME Lock Protection] operation complete | actor=" + target + " | armor=" + targetArmor + " | none armor=release")
    ElseIf result == -2
        MMELog.MasterDiagnostic("[MME Lock Protection] operation cancelled | actor=" + target + " | armor=" + targetArmor + " | superseded or save/session changed")
    ElseIf StorageUtil.GetIntValue(target, "MMEExtensions.LockProtection.Failed", 0) == 0
        StorageUtil.SetIntValue(target, "MMEExtensions.LockProtection.Failed", 1)
        MMELog.Alarm("[MME Lock Protection] SMOKE ALARM | operation=apply/release | actor=" + target + " | armor=" + targetArmor + " | native request failed or completion timed out | result=" + result)
    EndIf
    Return result
EndFunction

Bool Function EnsureActor(Actor target) Global
    If target == None || !IsEnabled()
        Return False
    EndIf
    ; Read only this subsystem's established saved ownership fields. Calling the
    ; full timed-lock/controller scripts here would import framework-specific
    ; gameplay graphs into the isolated P+ and optional compatibility compiles.
    If StorageUtil.GetIntValue(target, "MMEExtensions.TimedArmor.Locked", 0) != 1
        Return True
    EndIf
    Armor targetArmor = StorageUtil.GetFormValue(target, "MMEExtensions.TimedArmor.Armor", None) as Armor
    If StorageUtil.GetFloatValue(target, "MMEExtensions.TimedArmor.Deadline", 0.0) <= Utility.GetCurrentGameTime()
        ; Release runtime tags now; the existing scheduler still owns class-aware
        ; expiry, notifications and the parasite's retained equipped state.
        Return Apply(target, None) == 1 && IsEnabled()
    EndIf
    If targetArmor == None || Apply(target, targetArmor) != 1
        Return False
    EndIf
    Return IsEnabled() && StorageUtil.GetIntValue(target, "MMEExtensions.TimedArmor.Locked", 0) == 1 && StorageUtil.GetFormValue(target, "MMEExtensions.TimedArmor.Armor", None) == targetArmor
EndFunction

Bool Function EnsurePair(Actor firstActor, Actor secondActor) Global
    Return EnsureActor(firstActor) && EnsureActor(secondActor)
EndFunction
