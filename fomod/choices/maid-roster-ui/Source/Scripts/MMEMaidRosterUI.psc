Scriptname MMEMaidRosterUI extends Quest

Quest Property ExtensionsController Auto
Int ViewId = 0
Int Generation = 0
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
    Generation += 1
    StorageUtil.StringListClear(Self, "MMEMaidRoster.Alarms")
    PendingOpen = False
    Refreshing = False
    Ready = False
    ViewId = 0
    UnregisterForAllKeys()
    BoundKey = -1
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
        Bool errorListener = Magelight.RegisterListener(ViewId, "mmeRosterError")
        If !refreshListener || !closeListener || !errorListener
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
        Alarm("page rejected roster payload | view=" + ViewId)
    EndIf
EndEvent

Function CloseRoster(String reason)
    PendingOpen = False
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
    Int rowCount = 0
    Int skipped = 0
    String statusMessage = ""
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        statusMessage = "Milk Mod Economy is not ready."
        Alarm("refresh roster | MME controller unavailable")
    Else
        Actor[] maids = milkController.MilkMaid
        If maids != None && maids.Length > 0
            Form[] seen = Utility.CreateFormArray(maids.Length)
            Int scanIndex = 0
            While scanIndex < maids.Length
                Actor candidate = maids[scanIndex]
                If candidate != None && !candidate.IsDeleted() && !candidate.IsChild() && seen.Find(candidate) < 0
                    seen[rowCount] = candidate
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
                    rows += "{\"name\":\"" + Escape(actorName) + "\",\"milk\":" + (currentMilk as String) + ",\"capacity\":" + capacityJson + ",\"percent\":" + percentJson + ",\"status\":\"" + actorStatus + "\"}"
                    rowCount += 1
                Else
                    skipped += 1
                EndIf
                scanIndex += 1
            EndWhile
        EndIf
    EndIf
    If requestGeneration == Generation && requestView == ViewId && Enabled() && Magelight.IsVisible(ViewId)
        String payload = "{\"session\":\"" + (Generation as String) + "\",\"message\":\"" + Escape(statusMessage) + "\",\"rows\":[" + rows + "]}"
        Magelight.Call(ViewId, "setRoster", payload)
        Trace("refresh complete | rows=" + rowCount + " | skipped=" + skipped + " | view=" + ViewId)
    Else
        Trace("refresh discarded | closed or session changed")
    EndIf
    If RefreshGeneration == requestGeneration
        Refreshing = False
    EndIf
EndFunction
