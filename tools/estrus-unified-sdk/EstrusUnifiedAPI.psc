Scriptname EstrusUnifiedAPI Hidden

; Author-supplied public API subset. Compile-only; never ship this as a runtime replacement.
Bool Function IsReady() Global Native
; 0 none, 1 Chaurus, 2 Spider, 3 Dwemer. The target is the actual player or NPC.
Int Function GetPregnancyType(Actor target) Global Native
