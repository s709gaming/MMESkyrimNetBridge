; Compile-only interface extracted from installed source; never packaged.
Scriptname MME_Storage Hidden

Function initializeActor(actor akActor, float Level = 0.0, float MilkCnt = 0.0) Native Global
Function deregisterActor(actor akActor) Native Global
int Function getBreastRows(actor akActor) Native Global
int Function setBreastRows(actor akActor, int Value) Native Global
float Function getBreastsBaseadjust(actor akActor) Native Global
Function setBreastsBaseadjust(actor akActor, float Value) Native Global
float Function getBreastsBasevalue(actor akActor) Native Global
Function setBreastsBasevalue(actor akActor, float Value) Native Global
float Function getLactacidCurrent(actor akActor) Native Global
bool Function setLactacidCurrent(actor akActor, float Value) Native Global
bool Function changeLactacidCurrent(actor akActor, float Delta) Native Global
float Function getLactacidMaximum(actor akActor) Native Global
int Function getMaidLevel(actor akActor) Native Global
int Function setMaidLevel(actor akActor, int Value) Native Global
float Function getMilkCurrent(actor akActor) Native Global
float Function updateMilkCurrent(actor akActor) Native Global
Function setMilkCurrent(actor akActor, float Value, bool enforceMaxValue) Native Global
Function changeMilkCurrent(actor akActor, float Delta, bool enforceMaxValue) Native Global
float Function getMilkMaximum(actor akActor) Native Global
float Function getMilkMaxBasevalue(actor akActor) Native Global
Function setMilkMaxBasevalue(actor akActor, float Value) Native Global
float Function getMilkMaxScalefactor(actor akActor) Native Global
Function setMilkMaxScalefactor(actor akActor, float Value) Native Global
float Function getMilkProdPerHour(actor akActor) Native Global
float Function setMilkProdPerHour(actor akActor, float MilkProdPerHour) Native Global
float Function getMilkMaxProdPerHour(actor akActor) Native Global
float Function getPainCurrent(actor akActor) Native Global
bool Function setPainCurrent(actor akActor, float Value) Native Global
float Function getPainMaximum(actor akActor) Native Global
float Function getWeightBasevalue(actor akActor) Native Global
Function setWeightBasevalue(actor akActor, float Value) Native Global
float Function getBreastNodeScale(actor akActor) Native Global
float Function calculateMilkLimit(actor akActor, float Level) Native Global
float Function calculateMilkGen(actor akActor, float MilkProdPerHour) Native Global
float Function calculateMilkProdPerHour(actor akActor, float MilkGen) Native Global
Function updateMilkMaximum(actor akActor) Native Global
int Function verifyIntRange(string Caller, int Value, int MinValue, int MaxValue) Native Global
