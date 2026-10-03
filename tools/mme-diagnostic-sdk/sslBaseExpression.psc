; Compile-only interface extracted from installed source; never packaged.
scriptname sslBaseExpression extends sslBaseObject
int property Male       = 0 autoreadonly
int property Female     = 1 autoreadonly
int property MaleFemale = -1 autoreadonly
int property Phoneme  = 0 autoreadonly
int property Modifier = 16 autoreadonly
int property Mood     = 30 autoreadonly
int property PhonemeIDs  = 15 autoreadonly
int property ModifierIDs = 13 autoreadonly
int property MoodIDs     = 16 autoreadonly
Function Apply(Actor ActorRef, int Strength, int Gender) Native
Function ApplyPhase(Actor ActorRef, int Phase, int Gender) Native
int Function PickPhase(int Strength, int Gender) Native
float[] Function SelectPhase(int Strength, int Gender) Native
float Function GetModifier(Actor ActorRef, int id) Native Global
float Function GetPhoneme(Actor ActorRef, int id) Native Global
float Function GetExpression(Actor ActorRef, bool getId) Native Global
Function ClearPhoneme(Actor ActorRef) Native Global
Function ClearModifier(Actor ActorRef) Native Global
Function OpenMouth(Actor ActorRef) Native Global
Function CloseMouth(Actor ActorRef) Native Global
bool Function IsMouthOpen(Actor ActorRef) Native Global
Function ClearMFG(Actor ActorRef) Native Global
Function TransitPresetFloats(Actor ActorRef, float[] FromPreset, float[] ToPreset, float Speed = 1.0, float Time = 1.0) Native Global
Function ApplyPresetFloats(Actor ActorRef, float[] Preset) Native Global
float[] Function GetCurrentMFG(Actor ActorRef) Native Global
Function SetIndex(int Phase, int Gender, int Mode, int id, int value) Native
Function SetPreset(int Phase, int Gender, int Mode, int id, int value) Native
Function SetMood(int Phase, int Gender, int id, int value) Native
Function SetModifier(int Phase, int Gender, int id, int value) Native
Function SetPhoneme(int Phase, int Gender, int id, int value) Native
Function EmptyPhase(int Phase, int Gender) Native
Function AddPhase(int Phase, int Gender) Native
bool Function HasPhase(int Phase, Actor ActorRef) Native
float[] Function GenderPhase(int Phase, int Gender) Native
Function SetPhase(int Phase, int Gender, float[] Preset) Native
float[] Function GetPhonemes(int Phase, int Gender) Native
float[] Function GetModifiers(int Phase, int Gender) Native
int Function GetMoodType(int Phase, int Gender) Native
int Function GetMoodAmount(int Phase, int Gender) Native
int Function GetIndex(int Phase, int Gender, int Mode, int id) Native
int Function ValidatePreset(float[] Preset) Native
int[] Function ToIntArray(float[] FloatArray) Native Global
float[] Function ToFloatArray(int[] IntArray) Native Global
Function CountPhases() Native
Function Save(int id = -1) Native
Function Initialize() Native
bool Function ExportJson() Native
bool Function ImportJson() Native
Function ApplyTo(Actor ActorRef, int Strength = 50, bool IsFemale = true, bool OpenMouth = false) Native
int[] Function GetPhase(int Phase, int Gender) Native
int[] Function PickPreset(int Strength, bool IsFemale) Native
int Function CalcPhase(int Strength, bool IsFemale) Native
Function ApplyPreset(Actor ActorRef, int[] Preset) Native Global
