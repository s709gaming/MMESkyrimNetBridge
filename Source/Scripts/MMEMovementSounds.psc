Scriptname MMEMovementSounds Hidden

; Four routes: low normal movement, low sprinting, full normal movement, full sprinting.
; Sound IDs: 0 None, 1 slow slaps, 2 fast slaps, 3 slow flops, 4 fast flops.
String Function Key(Int route, String suffix) Global
    Return "movementSound" + route + suffix
EndFunction

Int Function Route(Actor player, Float current, Float maximum) Global
    Int result = 0
    If current >= maximum * 0.5
        result = 2
    EndIf
    If !player.IsSneaking() && player.IsSprinting()
        result += 1
    EndIf
    Return result
EndFunction

Int Function Selection(Int route) Global
    Int choice = JsonUtil.GetIntValue("/MMEAlerts/Settings", Key(route, "Selection"), route + 1)
    If choice < 0 || choice > 4
        Return route + 1
    EndIf
    Return choice
EndFunction

String Function Name(Int choice) Global
    If choice == 1
        Return MMELocalization.Text("Slow slaps")
    ElseIf choice == 2
        Return MMELocalization.Text("Fast slaps")
    ElseIf choice == 3
        Return MMELocalization.Text("Slow flops")
    ElseIf choice == 4
        Return MMELocalization.Text("Fast flops")
    EndIf
    Return MMELocalization.Text("None")
EndFunction

Sound Function Resolve(Int choice) Global
    Int formID = 0
    If choice == 1
        formID = 0x0008D4
    ElseIf choice == 2
        formID = 0x0008D6
    ElseIf choice == 3
        formID = 0x0008D8
    ElseIf choice == 4
        formID = 0x0008C5
    Else
        Return None
    EndIf
    Return Game.GetFormFromFile(formID, "MMEAlert.esp") as Sound
EndFunction

Float Function Gain(Int route, Bool sneaking) Global
    Float legacy = JsonUtil.GetFloatValue("/MMEAlerts/Settings", "movementSlapVolume", 100.0)
    Float value = JsonUtil.GetFloatValue("/MMEAlerts/Settings", Key(route, "Volume"), legacy)
    value *= JsonUtil.GetFloatValue("/MMEAlerts/Settings", "reactionSoundVolume", 100.0) / 100.0
    If sneaking
        value *= JsonUtil.GetFloatValue("/MMEAlerts/Settings", "movementSoundSneakVolume", 50.0) / 100.0
    EndIf
    ; Assets are the maximum reference level: half amplitude at user 100%.
    ; All multipliers combined cap at 200%, never exceeding the engine clamp.
    If value < 0.0
        value = 0.0
    ElseIf value > 200.0
        value = 200.0
    EndIf
    Return value / 200.0
EndFunction
