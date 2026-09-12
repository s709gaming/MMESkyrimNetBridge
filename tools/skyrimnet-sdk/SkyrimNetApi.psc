Scriptname SkyrimNetApi Hidden

; Compile-time declarations for the optional Skyrim.Net API calls used here.
; Skyrim.Net supplies the runtime script/native implementation when installed.
; Keeping this narrow SDK in the build tree lets the non-Skyrim.Net package
; compile without making Skyrim.Net a runtime requirement.

Int Function RegisterDecorator(String decoratorID, String sourceScript, String functionName) Global Native
Int Function RegisterAction(String actionName, String description, String eligibilityScriptName, String eligibilityFunctionName, String executionScriptName, String executionFunctionName, String triggeringEventTypesCsv, String categoryStr, Int defaultPriority, String parameterSchemaJson, String customCategory = "", String tags = "") Global Native
Int Function UnregisterAction(String actionName) Global Native
Int Function RegisterShortLivedEvent(String eventId, String eventType, String description, String data, Int ttlMs, Actor sourceActor, Actor targetActor) Global Native
Int Function RegisterEvent(String eventType, String content, Actor originatorActor, Actor targetActor) Global Native
Int Function SendCustomPromptToLLM(String promptName, String variant, String contextJson, Quest callbackQuest, String callbackScriptName, String callbackFunctionName) Global Native
Int Function DirectNarration(String content, Actor originatorActor = None, Actor targetActor = None) Global Native
String Function GetEntityUUID(Actor akActor) Global Native
String Function GetBuildVersion() Global Native
String Function GetBuildType() Global Native
Int Function RegisterEventSchema(String eventType, String displayName, String description, String fieldsJson, String formatTemplatesJson, Bool isEphemeral, Int defaultTTLMs, Bool shortLivedEnabled = True, Bool interrupt = False) Global Native
Bool Function IsEventTypeRegistered(String eventType) Global Native
Int Function TriggerPlayerTTS(String dialogue) Global Native
