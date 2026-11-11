Scriptname MilkAMBLAScr extends activemagiceffect

MilkQUEST Property MilkQ Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    MMEItemAttachments.ToggleWorn(akTarget, 2)
EndEvent
