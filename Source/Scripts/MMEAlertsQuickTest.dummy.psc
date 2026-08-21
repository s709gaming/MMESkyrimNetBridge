Scriptname MMEAlertsQuickTest extends Quest

; RELEASE-SAFE PLACEHOLDER FOR THE FORMER DEVELOPMENT ITEM HELPER.
; Keep this script and its public entry point because the ESP and existing saves
; may still reference them. Release builds deliberately grant no test items.
Bool testSetupApplied = False
Bool milkVarietyGranted = False

; The attached quest may still invoke this event; the retained function is inert.
Event OnInit()
    ScheduleTestSetup()
EndEvent

Function ScheduleTestSetup()
    Return
EndFunction

; Intentionally disabled for release. Do not delete without first removing every
; ESP attachment and caller, including references held by existing saves.
Function ApplyTestSetup()
    Return
EndFunction

; Retained only for binary/save compatibility with development versions.
Function GrantMilkVariety(Actor playerActor, Potion regularMilk, Potion succubusMilk, Potion werewolfMilk, Potion vampireMilk)
    Return
EndFunction
