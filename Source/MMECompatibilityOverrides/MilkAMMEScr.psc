Scriptname MilkAMMEScr extends activemagiceffect

MilkQUEST Property MilkQ Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    MMEItemAttachments.ToggleWorn(akTarget, 1)
EndEvent
