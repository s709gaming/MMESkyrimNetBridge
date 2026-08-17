Scriptname sslAnimationSlots extends Quest

; Compile-time shim only. The installed SexLab framework owns animation lookup.
sslBaseAnimation Function GetbyRegistrar(String registrar)
    Return None
EndFunction
