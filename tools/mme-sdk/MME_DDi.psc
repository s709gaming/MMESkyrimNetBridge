Scriptname MME_DDi extends Quest Hidden

; Compile-time shim only. Milk Mod Economy provides the runtime implementation.
Bool Function IsMilkingBlocked_Suit(Actor akActor)
    Return False
EndFunction
