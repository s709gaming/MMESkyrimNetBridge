Scriptname MME_StartMilking extends ActiveMagicEffect Hidden

; Same original effect eligibility and routes; diagnostics only.
Event OnEffectStart(Actor akTarget, Actor akCaster)
    MilkQUEST MilkQ = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    MMEMilkingDiagnostics.Trace("MilkForSpriggan effect entry | target=" + akTarget + " | caster=" + akCaster)
    If MilkQ == None || akTarget == None
        MMEMilkingDiagnostics.AlarmOnce("effectForms", "effect target or MME controller missing")
    EndIf
    If !akTarget.HasSpell(MilkQ.BeingMilkedPassive) && !akTarget.IsInCombat() && !akTarget.IsOnMount() && MilkQ.SexLab.IsValidActor(akTarget)
        MMEMilkingDiagnostics.Trace("effect accepted | hand route mode1")
        MilkQ.Milking(akTarget, 0, 1, 1)
        MMEMilkingDiagnostics.Trace("effect milking returned | mode1")
    ElseIf !akTarget.HasSpell(MilkQ.BeingMilkedPassive) && (akTarget.IsInCombat() || akTarget.IsOnMount())
        MMEMilkingDiagnostics.Trace("effect accepted | external route mode4")
        MilkQ.Milking(akTarget, 0, 4, 0)
        MMEMilkingDiagnostics.Trace("effect milking returned | mode4")
    Else
        MMEMilkingDiagnostics.Trace("effect rejected | passive=" + akTarget.HasSpell(MilkQ.BeingMilkedPassive) + " | combat=" + akTarget.IsInCombat() + " | mount=" + akTarget.IsOnMount() + " | validSexLabActor=" + MilkQ.SexLab.IsValidActor(akTarget))
    EndIf
EndEvent
