Scriptname MMEReactionSounds Hidden

; Stable SOUN marker IDs authored by CreateMMEAlertMinimalSounds.pas.
Int Function GetMarkerFormID(Actor sourceActor, Int femaleMarkerFormID) Global
    If sourceActor == None
        Return femaleMarkerFormID
    EndIf

    ActorBase sourceBase = sourceActor.GetActorBase()
    If sourceBase == None || sourceBase.GetSex() != 0
        Return femaleMarkerFormID
    EndIf

    If femaleMarkerFormID == 0x000854
        Return 0x000899 ; Male Mild
    ElseIf femaleMarkerFormID == 0x000855
        Return 0x00089A ; Male Medium
    ElseIf femaleMarkerFormID == 0x000856
        Return 0x00089B ; Male Hot
    EndIf
    Return femaleMarkerFormID
EndFunction

Sound Function Resolve(Actor sourceActor, Int femaleMarkerFormID) Global
    Int localFormID = GetMarkerFormID(sourceActor, femaleMarkerFormID)
    Return Game.GetFormFromFile(localFormID, "MMEAlert.esp") as Sound
EndFunction

; Plays the shared sex-aware high pool once near the beginning of a confirmed
; Milk Maid conversion. MME can report the same transition through both its
; effect and public event, while the forced API confirms it directly, so an
; actor-local creation marker prevents an overlapping second moan even when a
; player leaves either game-pausing story box open for an arbitrary duration.
; Sound failure is deliberately nonfatal: creation, cleanup, events, and
; Skyrim.Net narration must always continue.
Int Function PlayNewMilkMaidMoan(Actor sourceActor) Global
    String settingsFile = "/MMEAlerts/Settings"
    If sourceActor == None || sourceActor.IsDead() || sourceActor.IsDisabled() || !sourceActor.Is3DLoaded()
        MMELog.MasterDiagnostic("[MME Extensions New Milk Maid Sound] skipped: actor unavailable")
        Return -1
    EndIf
    If JsonUtil.GetIntValue(settingsFile, "enableReactionSounds", 1) != 1 || JsonUtil.GetIntValue(settingsFile, "enableNewMilkMaidMoans", 1) != 1
        MMELog.MasterDiagnostic("[MME Extensions New Milk Maid Sound] skipped: sound disabled | actor=" + sourceActor)
        Return 0
    EndIf

    String markerKey = "MMEExtensions.NewMilkMaid.MoanPlayed"
    If StorageUtil.GetIntValue(sourceActor, markerKey, 0) == 1
        MMELog.MasterDiagnostic("[MME Extensions New Milk Maid Sound] skipped: duplicate signal | actor=" + sourceActor)
        Return 0
    EndIf

    Sound reaction = Resolve(sourceActor, 0x000856) ; Hot/high SOUN marker
    If reaction == None
        MMELog.Alarm("[MME Extensions New Milk Maid Sound] failed: high sound marker unresolved | actor=" + sourceActor)
        Return -1
    EndIf
    Int instance = reaction.Play(sourceActor)
    If instance <= 0
        MMELog.MasterDiagnostic("[MME Extensions New Milk Maid Sound] failed: Sound.Play returned " + instance + " | actor=" + sourceActor)
        Return -1
    EndIf
    Sound.SetInstanceVolume(instance, JsonUtil.GetFloatValue(settingsFile, "reactionSoundVolume", 100.0) / 100.0)
    StorageUtil.SetIntValue(sourceActor, markerKey, 1)
    MMELog.MasterDiagnostic("[MME Extensions New Milk Maid Sound] played high moan | instance=" + instance + " | actor=" + sourceActor)
    Return instance
EndFunction
