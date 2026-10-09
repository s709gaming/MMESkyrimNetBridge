Scriptname ELVPlayerAliasscript extends ReferenceAlias

ELVMain Property ELV Auto Conditional
SexLabFramework Property SexLab Auto Conditional
CheckStats Property Stats Auto Conditional
QSCheck Property QS Auto
Actor Property PlayerRef Auto
Spell Property CellTracker Auto
ReferenceAlias Property MC_PlayerRef Auto
ReferenceAlias Property MC_Elsie Auto
Quest Property ELV_MakeCows Auto

Event OnInit()
    MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] player alias initialized")
    OnPlayerLoadGame()
EndEvent

Event OnPlayerLoadGame()
    MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] player-load maintenance started")
    RepairMissingProperties()

    If Stats
        Stats.Maintenance()
    Else
        MMELog.Alarm("[MME Extensions Elsie Fix] ROUTE CLOG | player alias Stats property is missing")
    EndIf

    If QS
        QS.StopDialogueQuests()
        MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] stale dialogue quests stopped")
    Else
        MMELog.Alarm("[MME Extensions Elsie Fix] ROUTE CLOG | QS cleanup property is missing")
    EndIf

    If ELV_MakeCows && ELV_MakeCows.IsRunning()
        If MC_Elsie && MC_Elsie.GetReference() == None
            MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] restarting unfilled Make Cows quest")
            ELV_MakeCows.Stop()
            Utility.Wait(5.0)
            ELV_MakeCows.Start()
        ElseIf !MC_Elsie
            MMELog.Alarm("[MME Extensions Elsie Fix] ROUTE CLOG | Make Cows alias property is missing")
        EndIf
    EndIf

    Int ionIndex = Game.GetModByName("Ion_follower.esp")
    If ionIndex != 255 && ionIndex != -1
        If ELV
            ELV.FindIon()
        Else
            MMELog.Alarm("[MME Extensions Elsie Fix] ROUTE CLOG | Elsie controller missing during Ion refresh")
        EndIf
    EndIf

    MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] player-load maintenance completed")
EndEvent

Function RepairMissingProperties()
    Bool repaired = False
    If !Stats
        Stats = Game.GetFormFromFile(0x005E57, "CP_Elsie.esp") as CheckStats
        repaired = True
    EndIf
    If !QS
        QS = Game.GetFormFromFile(0x005E57, "CP_Elsie.esp") as QSCheck
        repaired = True
    EndIf
    If !ELV
        ELV = Game.GetFormFromFile(0x005E57, "CP_Elsie.esp") as ELVMain
        repaired = True
    EndIf
    If !PlayerRef
        PlayerRef = Game.GetPlayer()
        repaired = True
    EndIf
    If !CellTracker
        CellTracker = Game.GetFormFromFile(0x088D24, "CP_Elsie.esp") as Spell
        repaired = True
    EndIf
    If !ELV_MakeCows
        ELV_MakeCows = Game.GetFormFromFile(0x09D64A, "CP_Elsie.esp") as Quest
        repaired = True
    EndIf
    If ELV_MakeCows
        If !MC_Elsie
            MC_Elsie = ELV_MakeCows.GetAlias(1) as ReferenceAlias
            repaired = True
        EndIf
        If !MC_PlayerRef
            MC_PlayerRef = ELV_MakeCows.GetAlias(2) as ReferenceAlias
            repaired = True
        EndIf
    EndIf
    If repaired
        MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] repaired missing player-alias properties at runtime")
    EndIf
EndFunction
