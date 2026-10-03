; Compile-only interface extracted from installed source; never packaged.
Scriptname MilkECON extends Quest
MiscObject Property Gold Auto
Location Property DawnstarWindpeakInnLocation Auto
Location Property FalkreathDeadMansDrinkLocation Auto
Location Property OldHroldanInnLocation Auto
Location Property MarkarthSilverBloodInnLocation Auto
Location Property RiftenBeeandBarbLocation Auto
Location Property IvarsteadVilemyrInnLocation Auto
Location Property DragonBridgeFourShieldsTavernLocation Auto
Location Property MorthalMoorsideInnLocation Auto
Location Property SolitudeWinkingSkeeverLocation Auto
Location Property RiverwoodSleepingGiantInnLocation Auto
Location Property WhiterunBanneredMareLocation Auto
Location Property RoriksteadFrostfruitInnLocation Auto
Location Property WindhelmCandlehearthHallLocation Auto
Location Property WindhelmNewGnisisCornerclubLocation Auto
Location Property WinterholdTheFrozenHearthLocation Auto
Location Property KynesgroveBraidwoodInnLocation Auto
Location Property locMorKhazgur Auto
Location Property locDushnikhYal Auto
Location Property locNarzulbur Auto
Location Property locLargashbur Auto
Location Property locDawnstar Auto
Location Property locDawnstarSanctuary Auto
Location Property locFalkreath Auto
Location Property locMarkarth Auto
Location Property locOldHroldan Auto
Location Property locRiften Auto
Location Property locShorsStone Auto
Location Property locSolitude Auto
Location Property locDragonBridge Auto
Location Property locMorthal Auto
Location Property locWhiterun Auto
Location Property locRiverwood Auto
Location Property locRorikstead Auto
Location Property locWindhelm Auto
Location Property locWinterhold Auto
Location Property locCollegeofWinterhold Auto
Location Property locKynesgrove Auto
Location Property locKarthwasten Auto
Location Property locHeljarchenHall Auto
Location Property locWindstadManor Auto
Location Property locLakeviewManor Auto
Location Property locFortDawnguard Auto
Location Property locDayspringCanyon Auto
Location Property locRavenRock Auto
Location Property locSkaalVillage Auto
Location Property locTelMithryn Auto
Location Property locMMEEmpty Auto
Message Property MilkTrade Auto
Message Property MilkTradeDialogue Auto
Message Property MilkTradeDialogue5 Auto
int Property MilkEcoCaravan Auto
int Property MilkEcoDawnstar Auto
int Property MilkEcoFalkreath Auto
int Property MilkEcoMarkarth Auto
int Property MilkEcoOrc Auto
int Property MilkEcoRiften Auto
int Property MilkEcoSolitude Auto
int Property MilkEcoWhiterun Auto
int Property MilkEcoWindhelm Auto
int Property MilkEcoMorrowind Auto
int Property MilkDemandCaravan Auto
int Property MilkDemandDawnstar Auto
int Property MilkDemandFalkreath Auto
int Property MilkDemandMarkarth Auto
int Property MilkDemandOrc Auto
int Property MilkDemandRiften Auto
int Property MilkDemandSolitude Auto
int Property MilkDemandWhiterun Auto
int Property MilkDemandWindhelm Auto
int Property MilkDemandMorrowind Auto
Formlist Property MilkTypeFormList Auto
String[] Property MarketNames Auto
String[] Property MilkNames Auto
int Property divnull = 10 Auto
int Property Updates = 0 Auto
bool Function MilkEconMaintenance() Native
bool Function InitializeMilkProperties() Native
float Function GetCurrentHourOfDay() Native Global
Function RegisterForSingleUpdateGameTimeAt(float GameTime) Native
Function MilkEcoCycle() Native
Function InitiateTradeToContainer(int MilkCount, int boobgasmcount, Actor akActor, Objectreference MilkBarrel) Native
Function InitiateTrade(int MilkCount, int boobgasmcount, Actor akActor, bool mobilemilking) Native
Function InitiateDialogueTrade(Actor akActor, int MilkType) Native
Function RemoveMilk(Actor akActor) Native
Function SellMilkDialogue(int marketIndex, int baseTrade, int milkTax, int upkeep, Actor akActor) Native
Function SellMilk(int marketIndex, int baseTrade, int milkTax, int upkeep, Actor akActor) Native
Function KeepMilkContainer(Potion finalPotion, int finalQty, int upkeep, objectreference MilkBarrel) Native
Function KeepMilk(Potion finalPotion, int finalQty, int upkeep, Actor akActor) Native
int Function GetUpkeepCost(int milkCount) Native
int Function GetMilkQty(int milkCount) Native
Form Function GetMilkType(int milkCount, int boobgasmcount, Actor milkMaid) Native
Form Function GetMilkTypeHelper(int milkCount, Formlist FLST, int MaidLevel) Native
int Function CalculateBaseTrade(Potion finalPotion, int finalQty) Native
int Function CalculateServiceTax(int marketIndex, int basePayout) Native
float Function CalculateServiceTaxHelper(int varEco) Native
int Function GetMarketIndexFromLocation(Location marketLocation) Native
int Function GetRaceIndexFromRace(Race maidRace) Native
int Function GetRaceIndexFromMilk(Potion Milk) Native
Function UpdateEconomy(int marketIndex, int basePayout) Native
Function BeginMilkEcoCycle() Native
Function EndMilkEcoCycle() Native
Function MilkEcoRestore() Native
Function MilkEcoSaturationEvent() Native
Function MilkEcoDemandEvent() Native
