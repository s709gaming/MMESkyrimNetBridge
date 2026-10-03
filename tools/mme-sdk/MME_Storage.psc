Scriptname MME_Storage Hidden
; Declaration only, verified against the original MME 20220522 source.
; This SDK file must NEVER be compiled/shipped as an MME replacement.
Int Function setMaidLevel(Actor akActor, Int Value) Global
    Return Value
EndFunction
Float Function getMilkCurrent(Actor akActor) Global
    Return 0.0
EndFunction
Float Function getMilkMaximum(Actor akActor) Global
    Return 0.0
EndFunction
Int Function getMaidLevel(Actor akActor) Global
    Return 0
EndFunction
Float Function getLactacidCurrent(Actor akActor) Global
    Return 0.0
EndFunction
Bool Function setLactacidCurrent(Actor akActor, Float Value) Global
    Return False
EndFunction
Bool Function changeLactacidCurrent(Actor akActor, Float Delta) Global
    Return False
EndFunction
Int Function getBreastRows(Actor akActor) Global
    Return 1
EndFunction
Int Function setBreastRows(Actor akActor, Int Value) Global
    Return Value
EndFunction
Function changeMilkCurrent(Actor akActor, Float Delta, Bool enforceMaxValue) Global
EndFunction
Function setMilkCurrent(Actor akActor, Float Value, Bool enforceMaxValue) Global
EndFunction
