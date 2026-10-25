Scriptname MME_zbf extends Quest Hidden

; Isolated MME bridge: same public API, actual ZaZ keywords, no ZaZ script types.
Event OnInit()
    StorageUtil.SetIntValue(None, "MME.PluginsCheck.zbf", 2)
    MMELog.MasterDiagnostic("[MME Extensions ZaZ Bridge] initialized | keyword-only OStim variant")
EndEvent

Bool Function IsIntegraged()
    Return Game.GetModByName("ZaZAnimationPack.esm") != 255
EndFunction

Bool Function IsWearingZaZGag_Open(Actor akActor)
    Return CheckKeyword(akActor, 0x019FDA)
EndFunction

Bool Function IsWearingZaZGag(Actor akActor)
    Return CheckKeyword(akActor, 0x008A4D)
EndFunction

Bool MissingKeywordReported = False
Bool Function CheckKeyword(Actor target, Int localID)
    If target == None || !IsIntegraged()
        Return False
    EndIf
    Keyword wornKeyword = Game.GetFormFromFile(localID, "ZaZAnimationPack.esm") as Keyword
    If wornKeyword == None
        If !MissingKeywordReported
            MMELog.Alarm("[MME Extensions ZaZ Bridge] operation=resolve keyword | actor=" + target + " | local ID=" + localID + " | installed ZaZ is missing required keyword")
            MissingKeywordReported = True
        EndIf
        Return False
    EndIf
    Return target.WornHasKeyword(wornKeyword)
EndFunction
