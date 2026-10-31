Scriptname MMEEstrusUnified Hidden

; Queries the actual Actor synchronously through our dynamic native facade.
; No Estrus script type/master, saved availability flag or pregnancy-result cache.
Bool Function IsPregnant(Actor target) Global
    MMELog.Diagnostic("[MME Extensions Estrus] pregnancy query entry | actor=" + target)
    Int result = MMEExtensionsNative.GetEstrusUnifiedPregnancyType(target)
    Bool logging = JsonUtil.GetIntValue(MMELog.GetSettingsFile(), "enablePapyrusTrace", 0) == 1
    Int footprints = MMEExtensionsNative.ObserveEstrusUnifiedResult(target, result, logging)
    String reason = "recognized Unified pregnancy; original MME pregnancy rules apply"
    If result == 0
        reason = "no Unified pregnancy; continuing original pregnancy checks"
    ElseIf result == -1
        reason = "optional Unified ESP or DLL absent; continuing original pregnancy checks"
    ElseIf result == -2
        reason = "Unified not ready; continuing original pregnancy checks"
    ElseIf result == -3
        reason = "invalid actor; query rejected"
    ElseIf result == -4
        reason = "Unified API missing, unbound, latent or incompatible; continuing original pregnancy checks"
    ElseIf result == -5
        reason = "Unified readiness call failed; continuing original pregnancy checks"
    ElseIf result == -6
        reason = "Unified readiness returned an invalid type; continuing original pregnancy checks"
    ElseIf result == -7
        reason = "Unified pregnancy call failed; continuing original pregnancy checks"
    ElseIf result == -8
        reason = "Unified pregnancy returned an invalid type or value; continuing original pregnancy checks"
    EndIf
    If footprints == 2 || footprints == 3
        MMELog.Alarm("[MME Extensions Estrus] SMOKE ALARM | operation=pregnancy query | actor=" + target + " | " + reason)
    EndIf
    If footprints == 1 || footprints == 3
        MMELog.MasterDiagnostic("[MME Extensions Estrus] pregnancy query result | actor=" + target + " | type=" + result + " | " + reason)
    EndIf
    MMELog.Diagnostic("[MME Extensions Estrus] pregnancy query complete | actor=" + target + " | type=" + result + " | recognized=" + (result > 0))
    Return result > 0
EndFunction
