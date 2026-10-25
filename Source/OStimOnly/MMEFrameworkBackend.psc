Scriptname MMEFrameworkBackend Hidden

String Function Name() Global
    Return "OStim-only"
EndFunction

Bool Function IsReady() Global
    Return Game.GetModByName("OStim.esp") != 255 && MMEOStimIntegration.IsSupportedVersion()
EndFunction

Function Initialize() Global
    MMELog.MasterDiagnostic("[MME Extensions Backend] initialize | backend=OStim-only | ready=" + IsReady() + " | SexLab intentionally unused")
    If !IsReady() && StorageUtil.GetIntValue(None, "MMEExtensions.Backend.MissingReported", 0) == 0
        StorageUtil.SetIntValue(None, "MMEExtensions.Backend.MissingReported", 1)
        MMELog.Alarm("[MME Extensions Backend] SMOKE ALARM | operation=initialize | backend=OStim-only | required OStim.esp unavailable")
    ElseIf IsReady()
        StorageUtil.UnsetIntValue(None, "MMEExtensions.Backend.MissingReported")
    EndIf
EndFunction

Bool Function IsValidActor(Actor target) Global
    If target == None || target.IsChild() || target.IsDead() || target.IsDisabled() || target.GetLeveledActorBase() == None
        MMELog.MasterDiagnostic("[MME Extensions Backend] actor rejected | actor=" + target + " | invalid, child, dead, disabled, or no base")
        Return False
    EndIf
    ; The installed OActor API verifies participant support without starting a scene.
    If !IsReady()
        Return False
    EndIf
    Actor[] participants = new Actor[1]
    participants[0] = target
    Bool eligible = OActor.VerifyActors(participants)
    MMELog.MasterDiagnostic("[MME Extensions Backend] actor validation | actor=" + target + " | eligible=" + eligible)
    Return eligible
EndFunction

Bool Function IsActorActive(Actor target) Global
    If target == None || !IsReady()
        Return False
    EndIf
    Return OActor.IsInOStim(target)
EndFunction

Bool Function IsStrippable(Form item) Global
    If item == None
        Return False
    EndIf
    Keyword protection = Keyword.GetKeyword("MMEExtNoStrip")
    If protection == None
        ; Fail closed: the replacement plugin must provide the protection keyword.
        If StorageUtil.GetIntValue(None, "MMEExtensions.Backend.KeywordReported", 0) == 0
            StorageUtil.SetIntValue(None, "MMEExtensions.Backend.KeywordReported", 1)
            MMELog.Alarm("[MME Extensions Backend] SMOKE ALARM | operation=armor policy | item=" + item + " | local no-strip keyword missing")
        EndIf
        Return False
    EndIf
    If !IsReady() || item.HasKeyword(protection)
        Return False
    EndIf
    Bool allowed = OUndress.CanUndress(item)
    MMELog.MasterDiagnostic("[MME Extensions Backend] armor policy | item=" + item + " | allowed=" + allowed)
    Return allowed
EndFunction

Int Function GetGender(Actor target) Global
    If target == None || target.GetLeveledActorBase() == None
        Return -1
    EndIf
    ; MME retains its own SOS and equipped-schlong detection in akActorSex.
    ; Explicit overrides allow the same classification independently of SexLab.
    Int overrideSex = StorageUtil.GetIntValue(target, "MMEExtensions.Backend.Gender", -1)
    If overrideSex >= 0 && overrideSex <= 2
        Return overrideSex
    EndIf
    Return target.GetLeveledActorBase().GetSex()
EndFunction

Function ForbidActor(Actor target) Global
    If target != None
        StorageUtil.SetIntValue(target, "MMEExtensions.Backend.Milking", 1)
        MMELog.MasterDiagnostic("[MME Extensions Backend] milking ownership acquired | actor=" + target)
    EndIf
EndFunction

Function AllowActor(Actor target) Global
    If target != None
        StorageUtil.UnsetIntValue(target, "MMEExtensions.Backend.Milking")
        MMELog.MasterDiagnostic("[MME Extensions Backend] milking ownership released | actor=" + target)
    EndIf
EndFunction

Function PresentationSkipped(Actor target) Global
    If target != None && StorageUtil.GetIntValue(target, "MMEExtensions.Backend.PresentationReported", 0) == 0
        StorageUtil.SetIntValue(target, "MMEExtensions.Backend.PresentationReported", 1)
        MMELog.MasterDiagnostic("[MME Extensions Backend] optional SexLab voice/expression skipped | actor=" + target + " | backend=OStim-only; OStim owns scene presentation")
    EndIf
EndFunction

Function ClearMFG(Actor target) Global
    ; Do not clear expressions owned by an OStim scene.
EndFunction

Bool Function IsReserved(Actor target) Global
    If target == None || StorageUtil.GetIntValue(target, "MMEExtensions.Backend.Milking", 0) == 0
        Return False
    EndIf
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController != None && milkController.BeingMilkedPassive != None && target.HasSpell(milkController.BeingMilkedPassive)
        Return True
    EndIf
    StorageUtil.UnsetIntValue(target, "MMEExtensions.Backend.Milking")
    MMELog.MasterDiagnostic("[MME Extensions Backend] stale milking ownership cleared | actor=" + target)
    Return False
EndFunction

; Backend-neutral entry point for MME and future Elsie/JUGS adapters.
; The persistent service owns request tokens and asynchronous cleanup.
Bool Function StartBreastfeeding(Actor milkSource, Actor drinker, String caller = "API") Global
    MMELog.MasterDiagnostic("[MME Extensions Backend] request | operation=breastfeeding | caller=" + caller + " | source=" + milkSource + " | drinker=" + drinker)
    If !IsReady()
        Initialize()
        Return False
    EndIf
    Return MMEOStimBreastfeeding.StartSharedBreastfeeding(milkSource, drinker, caller)
EndFunction

Bool Function SceneHasTag(String sceneID, String tag) Global
    If !IsReady() || sceneID == ""
        Return False
    EndIf
    If OMetadata.HasSceneTag(sceneID, tag)
        Return True
    EndIf
    If tag == "Anal"
        Return OMetadata.FindAction(sceneID, "analsex") >= 0
    ElseIf tag == "Vaginal"
        Return OMetadata.FindAction(sceneID, "vaginalsex") >= 0
    ElseIf tag == "Masturbation"
        Return OMetadata.FindAction(sceneID, "malemasturbation") >= 0 || OMetadata.FindAction(sceneID, "femalemasturbation") >= 0
    ElseIf tag == "Fisting"
        Return OMetadata.FindAction(sceneID, "analfisting") >= 0 || OMetadata.FindAction(sceneID, "vaginalfisting") >= 0
    ElseIf tag == "Breast"
        Return OMetadata.FindAction(sceneID, "suckingnipple") >= 0 || OMetadata.FindAction(sceneID, "suckingnipples") >= 0 || OMetadata.FindAction(sceneID, "lickingnipple") >= 0
    EndIf
    Return False
EndFunction
