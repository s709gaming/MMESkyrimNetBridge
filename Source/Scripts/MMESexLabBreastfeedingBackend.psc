Scriptname MMESexLabBreastfeedingBackend Hidden

; Standard SexLab implementation. The FOMOD P+ choice replaces only this
; facade with an API-compatible build that knows SLSB scene IDs.

String Function GetBackendName() Global
    Return "Standard SexLab"
EndFunction

Bool Function IsPPlus() Global
    Return False
EndFunction

Bool Function IsAvailable(MilkQUEST milkController) Global
    If milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None
        Return False
    EndIf
    Return milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar") != None && milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding") != None
EndFunction

Int Function StartBreastfeeding(MilkQUEST milkController, Actor milkSource, Actor drinker, String hookName = "MMEExtensionsBreastfeeding") Global
    If !IsAvailable(milkController) || milkSource == None || drinker == None
        Return -1
    EndIf
    String registrar = "zjBreastFeeding"
    ActorBase drinkerBase = drinker.GetLeveledActorBase()
    If drinkerBase != None && drinkerBase.GetSex() == 0
        registrar = "zjBreastFeedingVar"
    EndIf
    sslBaseAnimation animation = milkController.SexLab.AnimSlots.GetbyRegistrar(registrar)
    If animation == None
        Return -1
    EndIf
    sslBaseAnimation[] animations = new sslBaseAnimation[1]
    animations[0] = animation
    sslThreadModel model = milkController.SexLab.NewThread()
    If model == None
        Return -1
    EndIf
    ; Papyrus bytecode records the supplied argument count. SexLab 1.66d's
    ; AddActor contract has four parameters even though the final three have
    ; source-level defaults, so pass all four explicitly for runtime binding.
    If model.AddActor(milkSource, False, None, False) < 0
        model.Initialize()
        Return -1
    EndIf
    If model.AddActor(drinker, False, None, False) < 0
        model.Initialize()
        Return -1
    EndIf
    model.SetAnimations(animations)
    model.SetHook(hookName)
    sslThreadController thread = model.StartThread()
    If thread == None
        model.Initialize()
        Return -1
    EndIf
    Return model.tid
EndFunction

Bool Function IsBreastfeedingThread(MilkQUEST milkController, sslThreadController thread, Int threadID) Global
    If milkController == None || milkController.SexLab == None || milkController.SexLab.AnimSlots == None || thread == None
        Return False
    EndIf
    sslBaseAnimation straightAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeedingVar")
    sslBaseAnimation lesbianAnimation = milkController.SexLab.AnimSlots.GetbyRegistrar("zjBreastFeeding")
    Return (straightAnimation != None && thread.Animation == straightAnimation) || (lesbianAnimation != None && thread.Animation == lesbianAnimation)
EndFunction

Function EndOwnedScene(MilkQUEST milkController, Int threadID) Global
    If milkController == None || milkController.SexLab == None || threadID < 0
        Return
    EndIf
    sslThreadController thread = milkController.SexLab.GetController(threadID)
    If thread != None
        thread.EndAnimation(True)
    EndIf
EndFunction
