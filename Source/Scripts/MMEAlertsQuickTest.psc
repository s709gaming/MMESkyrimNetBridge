Scriptname MMEAlertsQuickTest extends Quest

; Release-safe placeholder. The Recommended FOMOD choice replaces this with
; its isolated QuickStart variant; all other installs grant no starter items.
; Keep the public functions because the ESP and established saves reference this
; script shape even when the selected installer profile deliberately does nothing.
Bool testSetupApplied = False
Bool milkVarietyGranted = False

Event OnInit()
    ScheduleTestSetup()
EndEvent

Function ScheduleTestSetup()
    Return
EndFunction

Function ApplyTestSetup()
    Return
EndFunction

Function GrantMilkVariety(Actor playerActor, Potion regularMilk, Potion succubusMilk, Potion werewolfMilk, Potion vampireMilk)
    Return
EndFunction
