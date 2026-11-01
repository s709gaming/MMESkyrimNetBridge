; Compile-only interface extracted from installed source; never packaged.
scriptname SexLabFramework extends Quest
bool Function IsValidActor(Actor ActorRef) Native
string property ModName auto
Faction property AnimatingFaction auto hidden
Actor property PlayerRef auto hidden
int Function GetGender(Actor ActorRef) Native
bool Function IsActorActive(Actor ActorRef) Native
Function ForbidActor(Actor ActorRef) Native
Function AllowActor(Actor ActorRef) Native
bool Function IsStrippable(Form ItemRef) Native
sslBaseVoice Function PickVoice(Actor ActorRef) Native
sslBaseExpression Function GetExpressionByName(string findName) Native
Function ClearMFG(Actor ActorRef) Native
Function Log(string Log, string Type = "NOTICE") Native

; Additional verified 1.66d interfaces needed by the direct prompt facade's
; common gameplay dependencies. Compile-only declarations, never shipped.
sslAnimationSlots Property AnimSlots Auto Hidden
sslThreadModel Function NewThread(Float TimeOut = 30.0) Native
sslThreadController Function GetController(Int tid) Native
sslThreadController Function GetActorController(Actor ActorRef) Native
Int Function StartSex(Actor[] Positions, sslBaseAnimation[] Anims, Actor Victim = None, ObjectReference CenterOn = None, Bool AllowBed = True, String Hook = "") Native
