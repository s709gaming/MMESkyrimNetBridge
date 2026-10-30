Scriptname MMEExtensionsNative Hidden

; Versioned editor transport: lowercase hex UTF-8 JSON preserves case across VM interning.
; Queues bounded native worker I/O; completion is a generation/view-scoped ModEvent.
Bool Function QueueNarrationEditorRequest(String payload, Int generation, Int view) Global Native
String Function GetGeneralLoreOverride() Global Native
; One atomic snapshot: element 0 is string/pool, remaining elements are templates (max 64).
String[] Function GetNarrationOverrideValues(String entryId) Global Native
Bool Function HasNarrationPoolOverrides(String fileKey) Global Native
String Function GetNarrationRevision() Global Native
String Function GetNarrationEditorFailure() Global Native
Function ReloadNarrationEditor() Global Native
String Function DescribeNarrationEditorReply(String payload) Global Native

; Read-only player movement state; keyboard, controller and auto-move aware.
Bool Function IsPlayerMovingOnFoot() Global Native

; Session token for rejecting audio instance IDs restored from another load.
Int Function GetMovementSlapSession() Global Native

; Papyrus declarations for the SKSE/CommonLib native bridge. Keep every name and
; signature synchronized with RegisterPapyrus in src/Plugin.cpp; compiled callers
; depend on this ABI. Morph functions edit only our owned runtime morph key; records are never edited.

; Returns the player followed by loaded actors in the same cell and radius.
Actor[] Function GetNearbyActors(Float radius) Global Native

; Resolves a loaded form by its stable EditorID.
Form Function GetFormByEditorID(String editorID) Global Native

; Returns the INFO array Skyrim actually loaded for a DIAL record.
Form[] Function GetTopicInfos(Form topic) Global Native

; Returns an INFO's in-memory PNAM link.
Form Function GetPreviousTopicInfo(Form info) Global Native

; Uses Skyrim's own evaluator for all conditions on an INFO.
Bool Function EvaluateTopicInfo(Form info, Actor subject, Actor target) Global Native

; Uses Skyrim's own evaluator for each CTDA, returned in record order as 1/0.
Int[] Function EvaluateTopicInfoConditions(Form info, Actor subject, Actor target) Global Native

; Describes each live CTDA by function, parameter, run-on object, comparison,
; and OR flag so diagnostics do not have to infer meaning from array position.
String[] Function DescribeTopicInfoConditions(Form info) Global Native

; Returns every plugin contributing the live record, origin first and winner last.
String[] Function GetFormSourceFiles(Form target) Global Native

; Returns the live parent DIAL for an INFO.
Form Function GetParentTopic(Form info) Global Native

; Optional RaceMenu calls are resolved dynamically by the DLL; no NiOverride
; Papyrus dependency. Apply queues ordered clear/set/refresh completion and
; reports its token through MMEExtensions_MaidBodyComplete; no latent save stack.
Bool Function IsBodyMorphAvailable() Global Native
Bool Function ApplyMaidBodyMorphs(Actor target, String[] names, Float[] values, Int token) Global Native

; Actor/token-specific native rejection or readback failure detail.
String Function GetMaidBodyFailureReason(Actor target, Int token) Global Native
