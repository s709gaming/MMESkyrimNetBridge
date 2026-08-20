Scriptname MMEExtensionsNative Hidden

; Returns the player followed by loaded actors in the same cell and radius.
Actor[] Function GetNearbyActors(Float radius) Global Native

; Resolves a loaded form by its stable EditorID.
Form Function GetFormByEditorID(String editorID) Global Native

; Returns the actor currently speaking through Skyrim's dialogue manager.
Actor Function GetDialogueTarget() Global Native

; Returns the dialogue manager's current/root/selected INFOs without duplicates.
Form[] Function GetActiveDialogueInfos() Global Native

; Returns the INFOs currently present in Skyrim's visible dialogue choice list.
Form[] Function GetVisibleDialogueInfos() Global Native

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
