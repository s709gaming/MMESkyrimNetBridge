Scriptname MilkQUEST extends Quest
SexLabFramework Property SexLab Auto
MME_DDi Property DDi Auto
Actor Property PlayerREF Auto
Actor[] Property MilkMaid Auto
Actor[] Property MilkSlave Auto
Faction Property MilkMaidFaction Auto
Faction Property MilkSlaveFaction Auto
MilkQUEST_Conditions Property MilkQC Auto
FormList Property MME_Milk_Basic Auto
FormList Property MME_Milk_Race Auto
FormList Property MME_Milk_Special Auto
FormList Property MME_Milk_Succubus Auto
FormList Property MME_Milk_Vampire Auto
FormList Property MME_Milk_Werewolf Auto
FormList Property MME_Util_Potions Auto
Armor Property MilkCuirass Auto
Armor Property MilkCuirassFuta Auto
Armor Property TITS4 Auto
Armor Property TITS6 Auto
Armor Property TITS8 Auto
Sound Property TakeHoldSound Auto
String[] Property MilkingEquipment Auto
String[] Property BasicLivingArmor Auto
String[] Property ParasiteLivingArmor Auto
Bool Property ArmorStrippingDisabled Auto
Bool Property FixedMilkGen Auto
Bool Property MaidLvlCap Auto
Int Property TimesMilkedMult Auto
Float Property MilkGenValue Auto
Float Property MilkProdMod Auto
Bool Property BellyScale Auto
Bool Property BreastScaleLimit Auto
Bool Property MaleMaids Auto
Bool Property MilkStory Auto
Bool Property MobileMilkingAnims Auto
Bool Property PlayerCantBeMilkmaid Auto
Float Property BoobMAX Auto
Float Property BoobIncr Auto
Float Property BoobPerLvl Auto
Int Property GushPct Auto
Spell Property BeingMilkedPassive Auto
Spell Property MilkForSprigganPassive Auto
Spell Property MME_MakeMilkmaid_Spell Auto
Spell Property MilkSelf Auto
Spell Property MilkTarget Auto
FormList Property MME_Spells_Buffs Auto
Function CurrentSize(Actor akActor)
EndFunction
Function AddMilkFx(Actor akActor, Int effectType)
EndFunction
Function AddLeak(Actor akActor)
EndFunction
Int Function PiercingCheck(Actor akActor)
    Return 0
EndFunction
Int Function Milklvl0fix()
    Return 0
EndFunction
Function AssignSlot(Actor akActor)
EndFunction
; Present in MME 20220522. Compile-time declaration for the no-confirmation
; API; the installed MME script owns the runtime implementation.
Function AssignSlotMaid(Actor akActor)
EndFunction
Function SingleMaidReset(Actor akActor)
EndFunction
Function Milking(Actor akActor, Int index, Int mode, Int milkingType)
EndFunction
