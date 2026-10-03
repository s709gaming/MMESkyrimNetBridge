; Compile-only interface extracted from installed source; never packaged.
Scriptname MME_SLA extends Quest Hidden

bool Function IsIntegraged() Native
int Function GetActorArousal(Actor akActor) Native
float Function GetActorExposure(Actor akActor) Native
float Function GetActorExposureRate(Actor akActor) Native
Function UpdateActorExposure(Actor akActor, Int value) Native
Function UpdateActorExposureRate(Actor akActor, Float value) Native
Function UpdateActorOrgasmDate(Actor akActor) Native
