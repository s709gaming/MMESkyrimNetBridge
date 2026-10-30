Scriptname MMEMaidRosterUI extends Quest

Quest Property ExtensionsController Auto
Int ViewId = 0
Int Generation = 0
Form[] SnapshotActors
Int SnapshotRevision = 0
Bool ActionBusy = False
Actor PendingActor
String PendingAction = ""
Actor RunningActor
Actor ConfirmActor
Float ConfirmDeadline = 0.0
Float LastCloseTime = -10.0
Int BoundKey = -1
Bool Ready = False
Bool PendingOpen = False
Bool Refreshing = False
Int RefreshGeneration = -1
Bool Initializing = False
String Settings = "/MMEAlerts/Settings"

Function Trace(String detail)
    MMELog.MasterDiagnostic("[MME Maid Roster UI] " + detail)
EndFunction

Function Alarm(String detail)
    If !StorageUtil.StringListHas(Self, "MMEMaidRoster.Alarms", detail)
        StorageUtil.StringListAdd(Self, "MMEMaidRoster.Alarms", detail)
        MMELog.Alarm("[MME Maid Roster UI] operation=UI | " + detail)
    EndIf
EndFunction

Bool Function Enabled()
    Return ExtensionsController != None && JsonUtil.GetIntValue(Settings, "enableMMEExtensions", 1) == 1 && JsonUtil.GetIntValue(Settings, "maidRosterUiEnabled", 1) == 1
EndFunction

Bool Function HostReady()
    If SKSE.GetPluginVersion("Magelight") < 0
        Trace("skip | Magelight host absent")
        Return False
    EndIf
    If Magelight.GetVersion() < 10500 || !Magelight.IsReady()
        Trace("skip | Magelight unavailable or older than 1.5.0")
        Return False
    EndIf
    Return True
EndFunction

Event OnInit()
    Initialize()
EndEvent

Function RecoverAfterLoad()
    ; These locks were serialized by Papyrus; their native UI work was not.
    Initializing = False
    Refreshing = False
    RefreshGeneration = -1
    Initialize()
EndFunction

Function Initialize()
    If Initializing
        Return
    EndIf
    Initializing = True
    ActionBusy = False
    PendingActor = None
    PendingAction = ""
    ConfirmActor = None
    RunningActor = None
    ConfirmDeadline = 0.0
    SnapshotActors = Utility.CreateFormArray(0)
    SnapshotRevision += 1
    UnregisterForUpdate()
    Generation += 1
    StorageUtil.StringListClear(Self, "MMEMaidRoster.Alarms")
    PendingOpen = False
    Refreshing = False
    Ready = False
    ViewId = 0
    UnregisterForAllKeys()
    BoundKey = -1
    LastCloseTime = -10.0
    RegisterForModEvent("MMEExtensions_RosterOpen", "OnOpenRequest")
    RegisterForModEvent("MMEExtensions_RosterSettings", "OnSettingsChanged")
    RegisterForModEvent("Magelight_ViewDomReady", "OnDomReady")
    RegisterForModEvent("Magelight_ViewLoadFailed", "OnViewFailed")
    RegisterForModEvent("Magelight_ViewDestroyed", "OnViewDestroyed")
    RegisterForModEvent("Magelight_RenderDead", "OnViewFailed")
    RegisterForModEvent("Magelight_UIModeExited", "OnUiExited")
    RegisterForModEvent("Magelight_JS_mmeRosterRefresh", "OnRefreshClick")
    RegisterForModEvent("Magelight_JS_mmeRosterClose", "OnCloseClick")
    RegisterForModEvent("Magelight_JS_mmeRosterError", "OnPageError")
    RegisterForModEvent("Magelight_JS_mmeRosterAction", "OnActionClick")
    RegisterForModEvent("Magelight_JS_mmeLoreRequest", "OnLoreRequest")
    RegisterForModEvent("MMEExtensions_NarrationEditorResult", "OnLoreResult")
    RegisterForModEvent("MilkQuest.StartMilkingMachine", "OnManualMilkingStart")
    RegisterForModEvent("MilkQuest.StopMilkingMachine", "OnManualMilkingStop")
    RegisterForModEvent("MME_MilkingDone", "OnManualMilkingDone")
    RegisterForMenu("Journal Menu")
    If HostReady()
        ; Resolve by owned name; never trust a view id serialized in a save.
        Int previousView = Magelight.FindView("mmeextensions", "maidRoster")
        If previousView > 0
            If Magelight.GetUIModeView() == previousView
                Magelight.ReleaseUIMode("mmeextensions")
            EndIf
            Magelight.DestroyView(previousView)
        EndIf
    EndIf
    RebindKey()
    Trace("initialize complete | generation=" + Generation)
    Initializing = False
EndFunction

Function RebindKey()
    UnbindViewHotkey()
    UnregisterForAllKeys()
    BoundKey = -1
    If !Enabled() || !HostReady()
        CloseRoster("settings disabled/unavailable")
        Return
    EndIf
    Int requestedKey = JsonUtil.GetIntValue(Settings, "maidRosterHotkey", -1)
    If requestedKey > 0 && requestedKey < 256 && requestedKey != 201
        BoundKey = requestedKey
        RegisterForKey(BoundKey)
    EndIf
    If ViewId > 0 && Magelight.IsVisible(ViewId)
        BindViewHotkey()
    EndIf
    Trace("key binding refreshed | key=" + BoundKey)
EndFunction

Event OnSettingsChanged(String eventName, String strArg, Float numArg, Form sender)
    RebindKey()
EndEvent

Event OnOpenRequest(String eventName, String strArg, Float numArg, Form sender)
    Trace("open requested | source=MCM")
    PendingOpen = True
    If !UI.IsMenuOpen("Journal Menu")
        OpenRoster()
    EndIf
EndEvent

Event OnMenuClose(String menuName)
    If menuName == "Journal Menu" && PendingOpen
        OpenRoster()
    EndIf
EndEvent

Event OnKeyDown(Int keyCode)
    If keyCode != BoundKey
        Return
    EndIf
    Trace("open/toggle requested | source=hotkey")
    If ViewId > 0 && HostReady() && Magelight.IsVisible(ViewId)
        CloseRoster("hotkey")
    ElseIf !Utility.IsInMenuMode()
        Float now = Utility.GetCurrentRealTime()
        If now >= LastCloseTime && now - LastCloseTime < 0.35
            Trace("hotkey skipped | duplicate close key event")
            Return
        EndIf
        PendingOpen = True
        OpenRoster()
    Else
        Trace("open skipped | another menu active")
    EndIf
EndEvent

Function OpenRoster()
    If !Enabled() || !HostReady()
        PendingOpen = False
        Trace("open skipped | disabled or host unavailable")
        Return
    EndIf
    If Utility.IsInMenuMode()
        PendingOpen = False
        Trace("open skipped | game menu/text entry active")
        Return
    EndIf
    If Magelight.IsUIModeActive() && Magelight.GetUIModeView() != ViewId
        PendingOpen = False
        Trace("open skipped | another view owns focus")
        Return
    EndIf
    If ViewId == 0
        If !Magelight.RegisterMod("mmeextensions", "MME Extensions")
            Alarm("register mod failed | " + Magelight.GetLastError("mmeextensions"))
            PendingOpen = False
            Return
        EndIf
        ViewId = Magelight.CreateView("mmeextensions", "maidRoster", "views/roster/index.html", 0, 0, 0, 0, "panel", "top-left", False, False)
        Ready = False
        If ViewId == 0
            Alarm("create view failed | " + Magelight.GetLastError("mmeextensions"))
            PendingOpen = False
            Return
        EndIf
        Bool refreshListener = Magelight.RegisterListener(ViewId, "mmeRosterRefresh")
        Bool closeListener = Magelight.RegisterListener(ViewId, "mmeRosterClose")
        Bool actionListener = Magelight.RegisterListener(ViewId, "mmeRosterAction")
        Bool errorListener = Magelight.RegisterListener(ViewId, "mmeRosterError")
        Bool loreListener = Magelight.RegisterListener(ViewId, "mmeLoreRequest")
        If !refreshListener || !closeListener || !errorListener || !actionListener || !loreListener
            Alarm("button listener registration failed | view=" + ViewId)
            CloseRoster("listener failure")
            Int rejectedView = ViewId
            ViewId = 0
            Magelight.DestroyView(rejectedView)
            Return
        EndIf
        Trace("view created | view=" + ViewId)
    EndIf
    Generation += 1
    PendingOpen = True
    If Ready
        ShowReadyView()
    EndIf
EndFunction

Function ShowReadyView()
    If !Enabled() || !HostReady() || ViewId == 0
        PendingOpen = False
        Return
    EndIf
    Magelight.ShowView(ViewId, True)
    If !Magelight.RequestUIMode(ViewId, False)
        Trace("open skipped | focus refused | " + Magelight.GetLastError("mmeextensions"))
        Magelight.ShowView(ViewId, False)
        PendingOpen = False
        Return
    EndIf
    PendingOpen = False
    BindViewHotkey()
    Trace("focus acquired | view=" + ViewId)
    RefreshRoster()
EndFunction

Bool Function OwnHostEvent(String strArg, Float numArg)
    Bool sameMod = strArg == "mmeextensions" || StringUtil.Find(strArg, "mmeextensions|") == 0
    Return sameMod && ViewId > 0 && (numArg as Int) == ViewId
EndFunction

Event OnDomReady(String eventName, String strArg, Float numArg, Form sender)
    If !OwnHostEvent(strArg, numArg)
        Return
    EndIf
    Ready = True
    Trace("DOM ready | view=" + ViewId)
    If PendingOpen
        ShowReadyView()
    EndIf
EndEvent

Event OnViewFailed(String eventName, String strArg, Float numArg, Form sender)
    If OwnHostEvent(strArg, numArg)
        Alarm("page/render failed | " + strArg)
        CloseRoster("page failure")
        Int failedView = ViewId
        ViewId = 0
        Ready = False
        Generation += 1
        Magelight.DestroyView(failedView)
    EndIf
EndEvent

Event OnViewDestroyed(String eventName, String strArg, Float numArg, Form sender)
    If OwnHostEvent(strArg, numArg)
        ViewId = 0
        Ready = False
        PendingOpen = False
        Generation += 1
        Trace("view destroyed | session invalidated")
    EndIf
EndEvent

Event OnUiExited(String eventName, String strArg, Float numArg, Form sender)
    If OwnHostEvent(strArg, numArg)
        CloseRoster("UI mode exited")
    EndIf
EndEvent

Event OnRefreshClick(String eventName, String strArg, Float numArg, Form sender)
    If ViewId > 0 && (numArg as Int) == ViewId && (strArg == "" || strArg == (Generation as String))
        RefreshRoster()
    EndIf
EndEvent

Event OnCloseClick(String eventName, String strArg, Float numArg, Form sender)
    If ViewId > 0 && (numArg as Int) == ViewId && (strArg == "" || strArg == (Generation as String))
        CloseRoster("Close/Escape")
    EndIf
EndEvent

Event OnPageError(String eventName, String strArg, Float numArg, Form sender)
    If ViewId > 0 && (numArg as Int) == ViewId
        Alarm("page rejected roster payload | view=" + ViewId + " | reason=" + StringUtil.Substring(strArg, 0, 600))
    EndIf
EndEvent

Event OnLoreRequest(String eventName, String strArg, Float numArg, Form sender)
    If ViewId <= 0 || (numArg as Int) != ViewId || !Enabled() || !Ready
        Return
    EndIf
    Int separator = StringUtil.Find(strArg, "|")
    If separator <= 0 || StringUtil.Substring(strArg, 0, separator) != (Generation as String)
        MMELog.MasterDiagnostic("[MME Narration Editor] operation=request | skip=stale session")
        Return
    EndIf
    If SKSE.GetPluginVersion("MMEExtensions") < 0
        EditorAlarm("operation=request | actor=N/A | native MMEExtensions host absent", "native host absent")
        Return
    EndIf
    If !HostReady() || !Magelight.IsVisible(ViewId) || Magelight.GetUIModeView() != ViewId
        MMELog.MasterDiagnostic("[MME Narration Editor] operation=request | skip=view does not own focus")
        Return
    EndIf
    ; Chunk acknowledgements are deliberately silent; the completed operation is traced below.
    If !MMEExtensionsNative.QueueNarrationEditorRequest(StringUtil.Substring(strArg, separator + 1), Generation, ViewId)
        MMELog.MasterDiagnostic("[MME Narration Editor] operation=request | skip=native queue busy/unavailable")
        Magelight.Call(ViewId, "loreEditorUnavailable", "Save queue is busy. Reopen or reload to check committed lore.")
    EndIf
EndEvent

Event OnLoreResult(String eventName, String strArg, Float numArg, Form sender)
    Int separator = StringUtil.Find(strArg, "|")
    If separator <= 0 || ViewId <= 0 || (numArg as Int) != ViewId || !Ready || !Enabled()
        MMELog.MasterDiagnostic("[MME Narration Editor] operation=response | cleanup=closed/disabled view")
        Return
    EndIf
    If StringUtil.Substring(strArg, 0, separator) != (Generation as String)
        MMELog.MasterDiagnostic("[MME Narration Editor] operation=response | cleanup=stale session")
        Return
    EndIf
    String reply = StringUtil.Substring(strArg, separator + 1)
    String summary = MMEExtensionsNative.DescribeNarrationEditorReply(reply)
    If summary != "transport"
        MMELog.MasterDiagnostic("[MME Narration Editor] " + summary)
    EndIf
    Int failure = StringUtil.Find(summary, "result=failure")
    If failure >= 0
        EditorAlarm(summary, StringUtil.Substring(summary, failure))
    EndIf
    Magelight.Call(ViewId, "setLoreEditor", reply)
    If summary != "transport"
        MMELog.MasterDiagnostic("[MME Narration Editor] operation=request | response delivered | generation=" + Generation)
    EndIf
EndEvent

Function EditorAlarm(String detail, String reason)
    String alarmKey = "NarrationEditor." + reason
    If !StorageUtil.StringListHas(Self, "MMEMaidRoster.Alarms", alarmKey)
        StorageUtil.StringListAdd(Self, "MMEMaidRoster.Alarms", alarmKey)
        MMELog.Alarm("[MME Narration Editor] " + detail)
    EndIf
EndFunction

Function CloseRoster(String reason)
    LastCloseTime = Utility.GetCurrentRealTime()
    UnbindViewHotkey()
    PendingOpen = False
    SnapshotActors = Utility.CreateFormArray(0)
    SnapshotRevision += 1
    If ViewId > 0 && SKSE.GetPluginVersion("Magelight") >= 0
        If Magelight.GetUIModeView() == ViewId
            Magelight.ReleaseUIMode("mmeextensions")
        EndIf
        Magelight.ShowView(ViewId, False)
    EndIf
    Trace("cleanup complete | reason=" + reason)
EndFunction

String Function ReplaceText(String value, String needle, String replacement)
    String output = ""
    Int position = 0
    Int found = StringUtil.Find(value, needle)
    While found >= 0
        If found > position
            output += StringUtil.Substring(value, position, found - position)
        EndIf
        output += replacement
        position = found + StringUtil.GetLength(needle)
        found = StringUtil.Find(value, needle, position)
    EndWhile
    If position < StringUtil.GetLength(value)
        output += StringUtil.Substring(value, position)
    EndIf
    Return output
EndFunction

String Function Escape(String value)
    ; Escape chunks rather than intern every character as a case-insensitive string.
    value = ReplaceText(value, "\\", "\\\\")
    value = ReplaceText(value, "\"", "\\\"")
    value = ReplaceText(value, "\n", "\\n")
    value = ReplaceText(value, StringUtil.AsChar(13), "\\r")
    value = ReplaceText(value, StringUtil.AsChar(9), "\\t")
    Int control = 1
    While control < 32
        If control != 9 && control != 10 && control != 13
            value = ReplaceText(value, StringUtil.AsChar(control), "")
        EndIf
        control += 1
    EndWhile
    Return value
EndFunction

; Resolve optional read support per snapshot, without loading any SLA/OSL types here.
Bool Function ArousalReaderAvailable()
    If !MMEArousalBridge.IsAvailable()
        Return False
    EndIf
    Quest readerQuest = Game.GetFormFromFile(0x04290F, "SexLabAroused.esm") as Quest
    Faction readerFaction = Game.GetFormFromFile(0x03FC36, "SexLabAroused.esm") as Faction
    Return readerQuest != None || readerFaction != None
EndFunction

Function RefreshRoster()
    If Refreshing && RefreshGeneration == Generation
        Trace("refresh coalesced | request already running")
        Return
    EndIf
    If !Enabled() || !HostReady()
        CloseRoster("refresh disabled/unavailable")
        Return
    EndIf
    If ViewId == 0 || !Ready || !Magelight.IsVisible(ViewId)
        Return
    EndIf
    Refreshing = True
    RefreshGeneration = Generation
    Int requestGeneration = Generation
    Int requestView = ViewId
    String rows = ""
    Int nextRevision = SnapshotRevision + 1
    Form[] nextActors
    Int rowCount = 0
    Int skipped = 0
    Bool arousalReadable = ArousalReaderAvailable()
    String arousalAvailableJson = "0"
    If arousalReadable
        arousalAvailableJson = "1"
    EndIf
    Int arousalKnown = 0
    Int arousalUnknown = 0
    String statusMessage = ""
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        statusMessage = "Milk Mod Economy is not ready."
        Alarm("refresh roster | MME controller unavailable")
    Else
        Actor[] maids = milkController.MilkMaid
        If maids.Length > 0
            nextActors = Utility.CreateFormArray(maids.Length)
            Form[] seen = Utility.CreateFormArray(maids.Length)
            Int scanIndex = 0
            While scanIndex < maids.Length
                Actor candidate = maids[scanIndex]
                If candidate != None && !candidate.IsDeleted() && !candidate.IsChild() && seen.Find(candidate) < 0
                    seen[rowCount] = candidate
                    nextActors[rowCount] = candidate
                    String actorName = candidate.GetDisplayName()
                    If actorName == ""
                        actorName = "Unnamed Milk Maid"
                    EndIf
                    Float currentMilk = MME_Storage.getMilkCurrent(candidate)
                    String capacityJson = "null"
                    String percentJson = "null"
                    If StorageUtil.HasFloatValue(candidate, "MME.MilkMaid.MilkMaximum")
                        ; Verified original getter storage key. Read directly to avoid its lazy-init
                        ; write if MME removes capacity between our VM calls. No formula duplicated.
                        Float capacityMilk = StorageUtil.GetFloatValue(candidate, "MME.MilkMaid.MilkMaximum", 0.0)
                        If capacityMilk > 0.0
                            capacityJson = capacityMilk as String
                            percentJson = ((currentMilk / capacityMilk) * 100.0) as String
                        EndIf
                    EndIf
                    If rowCount > 0
                        rows += ","
                    EndIf
                    String actorStatus = ""
                    If !candidate.Is3DLoaded()
                        actorStatus = "Last stored values"
                    ElseIf candidate.IsDead() || candidate.IsDisabled()
                        actorStatus = "Unavailable"
                    EndIf
                    ; Numeric flags avoid Papyrus case-insensitive string interning of true/false.
                    String playerJson = "0"
                    If candidate == Game.GetPlayer()
                        playerJson = "1"
                    EndIf
                    String availableJson = "0"
                    If candidate.Is3DLoaded() && !candidate.IsDead() && !candidate.IsDisabled() && !candidate.IsInCombat() && Game.GetPlayer().GetDistance(candidate) <= 2000.0
                        availableJson = "1"
                    EndIf
                    String selfReason = MMEExtensionsAPI.GetSelfMilkBlockReason(candidate)
                    String arousalJson = "null"
                    If arousalReadable
                        ; A read-only snapshot; never apply exposure, reactions or animations.
                        Int arousalValue = -1
                        If !candidate.IsDead() && !candidate.IsDisabled()
                            arousalValue = MMEArousalBridge.GetCurrentArousal(candidate)
                        EndIf
                        If arousalValue >= 0 && arousalValue <= 100
                            arousalJson = arousalValue as String
                            arousalKnown += 1
                        Else
                            arousalUnknown += 1
                        EndIf
                    EndIf
                    rows += "{\"token\":\"" + (nextRevision as String) + ":" + (rowCount as String) + "\",\"player\":" + playerJson + ",\"available\":" + availableJson + ",\"selfReason\":\"" + Escape(selfReason) + "\",\"name\":\"" + Escape(actorName) + "\",\"milk\":" + (currentMilk as String) + ",\"capacity\":" + capacityJson + ",\"percent\":" + percentJson + ",\"arousal\":" + arousalJson + ",\"status\":\"" + actorStatus + "\"}"
                    rowCount += 1
                Else
                    skipped += 1
                EndIf
                scanIndex += 1
            EndWhile
        EndIf
    EndIf
    If requestGeneration == Generation && requestView == ViewId && Enabled() && Magelight.IsVisible(ViewId)
        SnapshotActors = nextActors
        SnapshotRevision = nextRevision
        String payload = "{\"session\":\"" + (Generation as String) + "\",\"message\":\"" + Escape(statusMessage) + "\",\"arousalAvailable\":" + arousalAvailableJson + ",\"rows\":[" + rows + "]}"
        Magelight.Call(ViewId, "setRoster", payload)
        Trace("refresh complete | rows=" + rowCount + " | skipped=" + skipped + " | view=" + ViewId + " | arousal reader=" + arousalAvailableJson + " | arousal known=" + arousalKnown + " | arousal unknown=" + arousalUnknown)
    Else
        Trace("refresh discarded | closed or session changed")
    EndIf
    If RefreshGeneration == requestGeneration
        Refreshing = False
    EndIf
EndFunction

; Only tokens from the current published snapshot may resolve an actor.
Event OnActionClick(String eventName, String strArg, Float numArg, Form sender)
    If !Enabled() || ViewId <= 0 || (numArg as Int) != ViewId || !Magelight.IsVisible(ViewId) || ActionBusy || PendingActor != None || ConfirmActor != None
        Trace("action skipped | inactive view or request pending")
        Return
    EndIf
    String[] parts = StringUtil.Split(strArg, "|")
    If parts.Length != 3 || parts[0] != (Generation as String) || SnapshotActors.Length == 0
        Trace("action skipped | stale session")
        Return
    EndIf
    String[] rowToken = StringUtil.Split(parts[1], ":")
    If rowToken.Length != 2 || rowToken[0] != (SnapshotRevision as String)
        Trace("action skipped | stale snapshot")
        Return
    EndIf
    Int rowIndex = rowToken[1] as Int
    If rowIndex < 0 || rowIndex >= SnapshotActors.Length || (rowIndex as String) != rowToken[1]
        Return
    EndIf
    If parts[2] != "drink" && parts[2] != "self"
        Return
    EndIf
    If SnapshotActors[rowIndex] == None
        Return
    EndIf
    ActionBusy = True
    PendingActor = SnapshotActors[rowIndex] as Actor
    PendingAction = parts[2]
    Trace("action entry | actor=" + PendingActor + " | action=" + PendingAction + " | token=" + parts[1])
    CloseRoster("action dispatch")
    RegisterForSingleUpdate(0.1)
EndEvent

Event OnUpdate()
    If PendingActor != None
        Actor target = PendingActor
        String requestedAction = PendingAction
        PendingActor = None
        PendingAction = ""
        MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
        If !Enabled() || Utility.IsInMenuMode() || Magelight.IsUIModeActive() || milkController == None || target.IsDeleted() || target.IsChild() || !target.Is3DLoaded() || target.IsDead() || target.IsDisabled() || target.IsInCombat() || Game.GetPlayer().GetDistance(target) > 2000.0 || milkController.MilkMaid.Length == 0 || milkController.MilkMaid.Find(target) < 0
            ActionBusy = False
            Trace("action skipped | actor=" + target + " | eligibility changed or menu owns focus")
            Return
        EndIf
        Bool accepted = False
        If requestedAction == "self"
            ConfirmActor = target
            ConfirmDeadline = Utility.GetCurrentRealTime() + 12.0
            accepted = MMEExtensionsAPI.TrySelfMilk(target)
            If accepted && ConfirmActor != None
                RegisterForSingleUpdate(12.0)
            ElseIf !accepted
                ConfirmActor = None
            EndIf
            Trace("self dispatch only | actor=" + target + " | accepted=" + accepted)
        ElseIf target == Game.GetPlayer()
            accepted = MMEExtensionsAPI.DrinkAvailableMilk(target)
            Trace("drink result | actor=" + target + " | success=" + accepted)
        Else
            accepted = MMEExtensionsAPI.GiveAvailableMilk(Game.GetPlayer(), target)
            Trace("give result | actor=" + target + " | success=" + accepted)
        EndIf
        ActionBusy = False
        Trace("action cleanup | actor=" + target)
    ElseIf ConfirmActor != None && Utility.GetCurrentRealTime() >= ConfirmDeadline
        Trace("self start not confirmed within request window | actor=" + ConfirmActor)
        ConfirmActor = None
        ConfirmDeadline = 0.0
    EndIf
EndEvent

Event OnManualMilkingStart(Form actorForm, Int animationSpeed, Int milkingType)
    If ConfirmActor != None && actorForm == ConfirmActor
        Trace("self start confirmed by MME | actor=" + ConfirmActor + " | type=" + milkingType)
        RunningActor = ConfirmActor
        ConfirmActor = None
        ConfirmDeadline = 0.0
    EndIf
EndEvent

Event OnManualMilkingStop(Form actorForm, Int animationSpeed, Int milkingType)
    If RunningActor != None && actorForm == RunningActor
        Trace("self end confirmed by MME | actor=" + RunningActor)
        RunningActor = None
    EndIf
EndEvent

Event OnManualMilkingDone(Form actorForm, Int bottles, Int boobgasmCount, Int cumCount)
    If RunningActor != None && actorForm == RunningActor
        Trace("self completion confirmed by MME | actor=" + RunningActor + " | bottles=" + bottles)
        RunningActor = None
    EndIf
EndEvent

; While the page owns keyboard input, Magelight must receive the close key.
; Bind only while visible; hidden views cannot bypass Papyrus opening guards.
Function BindViewHotkey()
    If ViewId > 0 && BoundKey > 0 && HostReady()
        If !Magelight.BindHotkey(ViewId, BoundKey, 1)
            Alarm("bind roster toggle failed | key=" + BoundKey + " | reason=" + Magelight.GetLastError("mmeextensions"))
        Else
            Trace("focused toggle bound | key=" + BoundKey)
        EndIf
    EndIf
EndFunction

Function UnbindViewHotkey()
    If ViewId > 0 && BoundKey > 0 && SKSE.GetPluginVersion("Magelight") >= 0
        Magelight.BindHotkey(ViewId, BoundKey, 0)
    EndIf
EndFunction
