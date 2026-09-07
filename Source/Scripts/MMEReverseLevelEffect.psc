Scriptname MMEReverseLevelEffect extends ActiveMagicEffect

; Lifecycle only; arithmetic, duration, and all user entry points live in
; MMEReverseLevel. No timers on this magic effect.
MMEReverseLevel service

Event OnEffectStart(Actor target, Actor caster)
    service = MMEReverseLevel.GetService()
    If service != None
        service.EffectStarted(Self, target)
    EndIf
EndEvent

Event OnEffectFinish(Actor target, Actor caster)
    If service != None
        service.EffectFinished(Self)
    EndIf
    service = None
EndEvent
