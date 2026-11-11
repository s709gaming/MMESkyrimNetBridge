; Compile-only declarations extracted from installed MME/P+ source; never package.
Scriptname MilkQUEST extends Quest
SexLabFramework property SexLab auto
MilkECON Property MilkE Auto
MilkQUEST_Conditions Property MilkQC Auto
MME_DDi property DDi auto
MME_SLSD property SLSD auto
MME_RND property RND auto
Actor Property PlayerREF Auto
SPELL Property BeingMilkedPassive Auto
Armor Property MilkCuirass auto
Armor Property MilkCuirassFuta auto
Actor[] Property MilkMaid Auto
Actor[] Property MilkSlave Auto
String[] Property MilkingEquipment Auto
String[] Property BasicLivingArmor Auto
String[] Property ParasiteLivingArmor Auto
Bool Property MilkFlag = False Auto
Bool Property EconFlag = False Auto
Bool Property MilkMsgs = False Auto
Bool Property BreastScaleLimit = False Auto
Bool Property MaleMaids = False Auto
Bool Property CumProduction = true Auto
Int Property BreastScale = 0 Auto
Int Property MilkPoll Auto
Int Property GushPct = 10 Auto
Float Property MilkGenValue Auto
FormList Property MME_Cums Auto
FormList Property MME_Foods Auto
FormList Property MME_Milks Auto
FormList Property MME_Milk_Basic Auto
FormList Property MME_Util_Potions Auto
Faction Property MilkSlaveFaction Auto
Function AssignSlotMaid(Actor akActor)
EndFunction
Function AssignSlotSlave(Actor akActor, Int Level, Float Milk)
EndFunction
Function CurrentSize(Actor akActor)
EndFunction
Function Milking(Actor akActor, int i, int Mode, int MilkingType)
EndFunction
Function PostMilk(Actor akActor)
EndFunction
Function Strings_setup()
EndFunction
String Function formatString(String src, String part1 = "", String part2 = "", String part3 = "", String part4 = "", String part5 = "")
EndFunction
Function MultiBreastChange(Actor akActor)
EndFunction
Function DLCcheck()
EndFunction
Function AddMilkFx(Actor akActor, int i)
EndFunction
Function AddLeak(Actor akActor)
EndFunction
Function MaidReset()
EndFunction
Function SlaveReset()
EndFunction
bool Function VarSetup()
EndFunction
string Function akActorSex(Actor akActor)
EndFunction
bool Function isVampire(Actor akActor)
EndFunction
bool Function isSuccubus(Actor akActor)
EndFunction

; Exact guarded helpers from the repository MilkQUEST compatibility source.
Bool Function MMEExtDDCheck(Actor target, String checkName)
EndFunction
Bool Function MMEExtSLSDCheck(Actor target)
EndFunction
