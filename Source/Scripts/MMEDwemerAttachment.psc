Scriptname MMEDwemerAttachment Hidden

; Exact inventory item facade. Built-in Dwemer suits remain base-form compatibility.
; Operations: -1 read/resolve, 0 capture, 1 install, 2 remove, 3 refit, 4 label.
String Function Request(Actor wearer, Armor item, Int operation, String expected = "", Int fittedLevel = 0) Global
    If wearer == None || item == None || !MMEAlertsController.IsExtensionsEnabled()
        Return "skip|feature disabled or target missing"
    EndIf
    Bool diagnostic = JsonUtil.GetIntValue("/MMEAlerts/Settings", "enablePapyrusTrace", 0) == 1
    Int requestID = MMEExtensionsNative.QueueDwemerAttachment(wearer, item, operation, expected, diagnostic, fittedLevel)
    MMELog.MasterDiagnostic("[MME Dwemer Instance] entry | request=" + requestID + " | actor=" + wearer + " | armor=" + item + " | operation=" + operation)
    If requestID <= 0
        Return "error|native request unavailable"
    EndIf
    String result = ""
    Int remaining = 100
    While result == "" && remaining > 0
        result = MMEExtensionsNative.GetDwemerAttachmentResult(requestID)
        If result == ""
            Utility.WaitMenuMode(0.05)
        EndIf
        remaining -= 1
    EndWhile
    If result == ""
        ; Cancellation atomically returns a completed commit, or removes the queued request.
        result = MMEExtensionsNative.GetDwemerAttachmentResult(requestID, True)
    EndIf
    MMELog.MasterDiagnostic("[MME Dwemer Instance] result/cleanup | request=" + requestID + " | actor=" + wearer + " | " + result)
    If StringUtil.Find(result, "error|") == 0
        Int generation = MMEExtensionsNative.GetMovementSlapSession()
        If StorageUtil.GetIntValue(wearer, "MME.DwemerInstance.Alarm", -1) != generation
            StorageUtil.SetIntValue(wearer, "MME.DwemerInstance.Alarm", generation)
            MMELog.Alarm("[MME Dwemer Instance] operation=" + operation + " | actor=" + wearer + " | armor=" + item + " | failure=" + result)
        EndIf
    EndIf
    Return result
EndFunction

String Function Identity(Actor wearer, Armor item) Global
    If wearer == None || item == None || wearer.GetWornForm(Armor.GetMaskForSlot(32)) != item
        Return ""
    EndIf
    String identity = MMEExtensionsNative.GetDwemerItemIdentity(wearer, item)
    If identity == "?"
        String resolved = Request(wearer, item, -1)
        If StringUtil.Find(resolved, "ok|") != 0
            Return ""
        EndIf
        identity = StringUtil.Substring(resolved, 3)
    EndIf
    Return identity
EndFunction

Bool Function Has(Actor wearer, Armor item) Global
    String identity = Identity(wearer, item)
    If identity == ""
        Return False
    EndIf
    ; Startup/equip consumers already resolve worn items. Reconcile only when the
    ; cached snapshot needs it: no new polling, replayed story or inventory scan.
    If MMEExtensionsNative.HasWornDwemerAttachment(wearer, item) && MMEExtensionsNative.DwemerLabelNeedsUpdate(wearer, item)
        Request(wearer, item, 4, identity)
    EndIf
    Return MMEExtensionsNative.HasWornDwemerAttachment(wearer, item)
EndFunction

String Function Capture(Actor wearer, Armor item) Global
    String result = Request(wearer, item, 0)
    If StringUtil.Find(result, "ok|") == 0
        Return StringUtil.Substring(result, 3)
    EndIf
    Return ""
EndFunction

Bool Function Install(Actor wearer, Armor item, String identity) Global
    If identity == "" || identity == "ordinary"
        Return False
    EndIf
    Return StringUtil.Find(Request(wearer, item, 1, identity, MME_Storage.getMaidLevel(wearer)), "ok|") == 0
EndFunction

Bool Function Remove(Actor wearer, Armor item, String identity) Global
    If identity == "" || identity == "ordinary"
        Return False
    EndIf
    Return StringUtil.Find(Request(wearer, item, 2, identity), "ok|") == 0
EndFunction

String Function Tag(Actor wearer, Armor item) Global
    If !Has(wearer, item)
        Return ""
    EndIf
    Return MMEExtensionsNative.GetDwemerAttachmentTag(wearer, item)
EndFunction

Bool Function NeedsRefit(Actor wearer, Armor item) Global
    If !Has(wearer, item)
        Return False
    EndIf
    Int fitted = MMEExtensionsNative.GetDwemerRefitLevel(wearer, item)
    Return fitted >= 0 && MME_Storage.getMaidLevel(wearer) > fitted
EndFunction

Bool Function Refit(Actor wearer, Armor item) Global
    String identity = Capture(wearer, item)
    If identity == ""
        Return False
    EndIf
    Return StringUtil.Find(Request(wearer, item, 3, identity, MME_Storage.getMaidLevel(wearer)), "ok|") == 0
EndFunction

Function ReportLegacy() Global
    If StorageUtil.FormListCount(None, MMECustomArmorRegistry.GetDwemerArtisanKey()) > 0 && StorageUtil.GetIntValue(None, "MME.DwemerInstance.LegacyNotice", 0) == 0
        StorageUtil.SetIntValue(None, "MME.DwemerInstance.LegacyNotice", 1)
        Debug.Notification(MMELocalization.Text("Old Dwemer attachments need individual reinstallation at a blacksmith."))
        MMELog.MasterDiagnostic("[MME Dwemer Instance] legacy base-form entries dormant; explicit worn-item rebind required")
    EndIf
EndFunction
