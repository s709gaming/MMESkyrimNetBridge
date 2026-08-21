Scriptname MMEAlertsFlatRateDefaults extends Quest

; Vanilla FOMOD profile override. This script deliberately never changes MME.
; Retain the public ApplyDefaults entry point for the shared player-load hook and
; binary/save compatibility; only the optional personal profile replaces it.
Event OnInit()
EndEvent

Function ApplyDefaults()
    Return
EndFunction
