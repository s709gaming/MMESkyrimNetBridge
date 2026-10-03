; Compile-only interface extracted from installed source; never packaged.
scriptname sslBaseObject extends ReferenceAlias hidden
int property SlotID auto hidden
string property Name auto hidden
bool property Enabled auto hidden
string property Registry auto hidden
Form property Storage auto hidden
string[] Function GetRawTags() Native
string[] Function GetTags() Native
bool Function HasTag(string Tag) Native
bool Function AddTag(string Tag) Native
bool Function RemoveTag(string Tag) Native
Function AddTags(string[] TagList) Native
Function SetTags(string TagList) Native
bool Function ToggleTag(string Tag) Native
bool Function AddTagConditional(string Tag, bool AddTag) Native
bool Function CheckTags(string[] CheckTags, bool RequireAll = true, bool Suppress = false) Native
bool Function ParseTags(string[] TagList, bool RequireAll = true) Native
bool Function TagSearch(string[] TagList, string[] Suppress, bool RequireAll) Native
bool Function HasOneTag(string[] TagList) Native
bool Function HasAllTag(string[] TagList) Native
Function MakeEphemeral(string Token, Form OwnerForm) Native
string Function Key(string type = "") Native
Function Log(string Log, string Type = "NOTICE") Native
Function Save(int id = -1) Native
Function Initialize() Native
