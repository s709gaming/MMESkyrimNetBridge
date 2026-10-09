Scriptname ELV_DiaGreets_PlayerAliasScript extends ReferenceAlias

ELVMain Property ELV Auto Conditional
SexLabFramework Property SexLab Auto Conditional
Quest Property ELV_Dia_Greet Auto
Actor Property PlayerRef Auto
CheckStats Property Stats Auto

Event OnInit()
    MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] greeting alias initialized")
    OnPlayerLoadGame()
EndEvent

Event OnPlayerLoadGame()
    If !Stats
        Stats = Game.GetFormFromFile(0x005E57, "CP_Elsie.esp") as CheckStats
        MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] greeting Stats property repaired at runtime")
    EndIf
    If Stats
        Stats.Maintenance()
        MMELog.MasterDiagnostic("[MME Extensions Elsie Fix] greeting maintenance completed")
    Else
        MMELog.Alarm("[MME Extensions Elsie Fix] ROUTE CLOG | greeting Stats property is missing")
    EndIf
EndEvent
