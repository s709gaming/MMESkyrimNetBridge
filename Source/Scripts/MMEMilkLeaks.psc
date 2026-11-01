Scriptname MMEMilkLeaks extends Quest

Armor Property LowArmor Auto
Armor Property MediumArmor Auto
Armor Property HighArmor Auto
Armor Property ExternalArmor Auto
Actor[] tracked
ObjectReference[] visuals
Float[] started
Int[] maximumStages
Int[] visibleStages
Bool[] busy
Bool initialized = False
Int epoch = 0
Float lastNarration = -1200.0
String settings = "/MMEAlerts/Settings"

Event OnInit()
    Maintenance()
EndEvent

Function Trace(String reportText)
    MMELog.MasterDiagnostic("[MME Milk Leaks] " + reportText)
EndFunction

Function Alarm(String alarmKey, Actor target, String reason)
    Float now = Utility.GetCurrentRealTime()
    String stamp = "MMELeaks.Alarm." + alarmKey
    If now - StorageUtil.GetFloatValue(target, stamp, -300.0) >= 60.0
        StorageUtil.SetFloatValue(target, stamp, now)
        MMELog.Alarm("[MME Milk Leaks] operation=" + alarmKey + " | actor=" + target + " | failure=" + reason)
    EndIf
EndFunction

Function Maintenance()
    epoch += 1
    If !initialized
        tracked = new Actor[32]
        visuals = new ObjectReference[32]
        started = new Float[32]
        maximumStages = new Int[32]
        visibleStages = new Int[32]
        busy = new Bool[32]
        initialized = True
    Else
        Int i = 0
        While i < tracked.Length
            busy[i] = False
            Cleanup(i, "load/reset")
            i += 1
        EndWhile
    EndIf
    lastNarration = -1200.0
    MMEMilkLeakAPI.EnsureDefaults()
    Actor[] nearby = MMEExtensionsNative.GetNearbyActors(2000.0)
    Int resetIndex = 0
    While resetIndex < nearby.Length
        If nearby[resetIndex] != None
            StorageUtil.UnsetIntValue(nearby[resetIndex], "MMELeaks.ThresholdLatched")
            StorageUtil.UnsetFloatValue(nearby[resetIndex], "MMELeaks.ExternalUntil")
        EndIf
        resetIndex += 1
    EndWhile
    UnregisterForModEvent("OLactis.Lactating")
    RegisterForModEvent("OLactis.Lactating", "OnExternalRequest")
    UnregisterForModEvent("OLactis.Unequipped")
    RegisterForModEvent("OLactis.Unequipped", "OnExternalEnd")
    RegisterForSingleUpdate(1.0)
    Trace("initialized | external detection only; no external cleanup")
EndFunction

Bool Function Enabled()
    Return MMEMilkLeakAPI.IsDetected() && JsonUtil.GetIntValue(settings, "enableMMEExtensions", 1) == 1 && JsonUtil.GetIntValue(settings, "enableMilkLeaks", 1) == 1
EndFunction

Int Function GetLeakSource(Actor target)
    If target == None || !target.Is3DLoaded()
        Return 0
    EndIf
    If ExternalArmor != None && target.IsEquipped(ExternalArmor)
        Return 2
    EndIf
    If (LowArmor != None && target.IsEquipped(LowArmor)) || (MediumArmor != None && target.IsEquipped(MediumArmor)) || (HighArmor != None && target.IsEquipped(HighArmor))
        Return 1
    EndIf
    Return 0
EndFunction

Int Function GetLeakIntensity(Actor target)
    If GetLeakSource(target) != 1
        Return -1
    ElseIf target.IsEquipped(HighArmor)
        Return 2
    ElseIf target.IsEquipped(MediumArmor)
        Return 1
    EndIf
    Return 0
EndFunction

String Function BlockReason(Actor target)
    If target == None
        Return "missing actor"
    EndIf
    If target.IsChild() || target.IsDead() || target.IsDisabled() || !target.Is3DLoaded() || target.GetDistance(Game.GetPlayer()) > 2000.0
        Return "actor unavailable"
    EndIf
    If target.IsInCombat() || target.GetCurrentScene() != None || target.GetAnimationVariableBool("bInFurniture")
        Return "combat/scene/furniture"
    EndIf
    If MMEOStimIntegration.IsActorBusy(target)
        Return "framework scene"
    EndIf
    Return MMESelfMilking.GetInvalidReason(target, True, False, True)
EndFunction

Function Observe(Actor[] nearby)
    If !initialized || !Enabled()
        Return
    EndIf
    Int i = 0
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milk == None
        Alarm("observe", None, "MME controller missing")
        Return
    EndIf
    While i < nearby.Length
        Actor target = nearby[i]
        If target != None && !target.IsChild() && MMEArmorScript.IsMMEMilkMaid(target, milk)
            Float capacity = MME_Storage.getMilkMaximum(target)
            If capacity > 0.0
                Float percent = 100.0 * MME_Storage.getMilkCurrent(target) / capacity
                Float threshold = JsonUtil.GetFloatValue(settings, "milkLeakThreshold", 100.0)
                If threshold < 1.0
                    threshold = 1.0
                ElseIf threshold > 100.0
                    threshold = 100.0
                EndIf
                String latch = "MMELeaks.ThresholdLatched"
                If percent < threshold
                    StorageUtil.UnsetIntValue(target, latch)
                ElseIf StorageUtil.GetIntValue(target, latch, 0) == 0 && tracked.Find(target) < 0
                    String reason = BlockReason(target)
                    If GetLeakSource(target) > 0
                        reason = "existing spray"
                    EndIf
                    If StorageUtil.GetFloatValue(target, "MMELeaks.ExternalUntil", 0.0) > Utility.GetCurrentRealTime()
                        reason = "external spray pending"
                    EndIf
                    If target.GetWornForm(0x00000004) != None && JsonUtil.GetIntValue(settings, "milkLeakThroughClothing", 1) != 1
                        reason = "covered; clothing leaks disabled"
                    EndIf
                    If reason == ""
                        Trace("entry | actor=" + target + " | fullness=" + percent + " | eligible=True")
                        StartLeak(target)
                    ElseIf StorageUtil.GetStringValue(target, "MMELeaks.Skip", "") != reason
                        StorageUtil.SetStringValue(target, "MMELeaks.Skip", reason)
                        Trace("eligibility | actor=" + target + " | skip=" + reason)
                    EndIf
                EndIf
            EndIf
        EndIf
        i += 1
    EndWhile
EndFunction

Function StartLeak(Actor target)
    Int requestEpoch = epoch
    Int slot = tracked.Find(None)
    If slot < 0
        Trace("skip | actor=" + target + " | all leak slots occupied")
        Return
    EndIf
    If LowArmor == None || MediumArmor == None || HighArmor == None || ExternalArmor == None
        Alarm("start", target, "required effect armor missing")
        Return
    EndIf
    tracked[slot] = target
    started[slot] = Utility.GetCurrentRealTime()
    Int level = JsonUtil.GetIntValue(settings, "milkLeakIntensity", 2)
    If level < 0
        level = 0
    ElseIf level > 2
        level = 2
    EndIf
    maximumStages[slot] = level
    visibleStages[slot] = -1
    Advance(slot)
    If requestEpoch != epoch || tracked[slot] != target
        Return
    EndIf
    If tracked[slot] != None && GetLeakSource(target) == 1
        StorageUtil.SetIntValue(target, "MMELeaks.ThresholdLatched", 1)
        StorageUtil.UnsetStringValue(target, "MMELeaks.Skip")
        Narrate(target)
    EndIf
    RegisterForSingleUpdate(1.0)
EndFunction

Function Advance(Int slot)
    If busy[slot] || tracked[slot] == None
        Return
    EndIf
    busy[slot] = True
    Int requestEpoch = epoch
    Actor target = tracked[slot]
    Float elapsed = Utility.GetCurrentRealTime() - started[slot]
    Int stage = maximumStages[slot] - Math.Floor(elapsed / 5.0)
    String reason = BlockReason(target)
    If !Enabled()
        reason = "feature/master/dependency disabled"
    ElseIf ExternalArmor != None && target.IsEquipped(ExternalArmor)
        reason = "yield to external spray"
    ElseIf StorageUtil.GetFloatValue(target, "MMELeaks.ExternalUntil", 0.0) > Utility.GetCurrentRealTime()
        reason = "yield to external request"
    EndIf
    If stage < 0 || reason != ""
        Cleanup(slot, reason + " / sequence complete")
        busy[slot] = False
        Return
    EndIf
    If target.GetWornForm(0x00000004) != None
        If JsonUtil.GetIntValue(settings, "milkLeakThroughClothing", 1) != 1
            Cleanup(slot, "clothing leaks disabled")
            busy[slot] = False
            Return
        EndIf
        stage = 0
    EndIf
    If visibleStages[slot] != stage
        RemoveVisual(slot)
        Armor effectArmor = LowArmor
        If stage == 2
            effectArmor = HighArmor
        ElseIf stage == 1
            effectArmor = MediumArmor
        EndIf
        ObjectReference effectRef = target.PlaceAtMe(effectArmor, 1, True)
        If effectRef == None
            Alarm("start", target, "effect reference creation failed")
            Cleanup(slot, "setup failure")
        Else
            visuals[slot] = effectRef
            target.AddItem(effectRef, 1, True)
            target.EquipItem(effectArmor, False, True)
            Utility.Wait(0.15)
            ; Loading may have cleaned/reused this slot while this stack slept.
            If epoch != requestEpoch || tracked[slot] != target || visuals[slot] != effectRef
                Return
            EndIf
            ; A latent equip may overlap an external request: recheck before accepting.
            If !Enabled() || target.IsEquipped(ExternalArmor) || StorageUtil.GetFloatValue(target, "MMELeaks.ExternalUntil", 0.0) > Utility.GetCurrentRealTime()
                Cleanup(slot, "external request/disabled during setup")
            ElseIf !target.IsEquipped(effectArmor)
                Alarm("equip", target, "own visual armor did not equip")
                Cleanup(slot, "setup failure")
            Else
                visibleStages[slot] = stage
                Trace("action result | actor=" + target + " | stage=" + stage + " | equipped=True")
            EndIf
        EndIf
    EndIf
    busy[slot] = False
EndFunction

Function RemoveVisual(Int slot)
    Actor target = tracked[slot]
    ObjectReference effectRef = visuals[slot]
    If target != None && effectRef != None
        target.UnequipItem(effectRef.GetBaseObject(), False, True)
        target.RemoveItem(effectRef, 1, True)
        effectRef.Delete()
    EndIf
    visuals[slot] = None
    visibleStages[slot] = -1
EndFunction

Function Cleanup(Int slot, String reason)
    Actor target = tracked[slot]
    RemoveVisual(slot)
    If target != None
        Trace("cleanup | actor=" + target + " | reason=" + reason)
        If target.IsEquipped(LowArmor) || target.IsEquipped(MediumArmor) || target.IsEquipped(HighArmor)
            Alarm("cleanup", target, "own visual remains equipped")
        EndIf
    EndIf
    tracked[slot] = None
EndFunction

Event OnUpdate()
    Int i = 0
    Bool active = False
    While i < tracked.Length
        If tracked[i] != None
            Advance(i)
            active = active || tracked[i] != None
        EndIf
        i += 1
    EndWhile
    If active
        RegisterForSingleUpdate(1.0)
    EndIf
EndEvent

Function OnExternalRequest(Form who, Int duration, Int stage)
    Actor target = who as Actor
    If target == None
        Return
    EndIf
    ; Request reservation prevents races but is not exposed as an active leak.
    StorageUtil.SetFloatValue(target, "MMELeaks.ExternalUntil", Utility.GetCurrentRealTime() + 3.0)
    Int slot = tracked.Find(target)
    If slot >= 0 && !busy[slot]
        Cleanup(slot, "external Oninus request; yield")
    EndIf
    Trace("external request | actor=" + target + " | stage=" + stage + " | pending; not confirmed")
EndFunction

Function OnExternalEnd(Form who)
    Actor target = who as Actor
    If target != None
        Trace("external removal event | actor=" + target + " | source now=" + GetLeakSource(target))
    EndIf
EndFunction

Function Narrate(Actor target)
    Float now = Utility.GetCurrentRealTime()
    Float cooldown = JsonUtil.GetFloatValue(settings, "milkLeakNarrationCooldown", 30.0)
    If cooldown < 0.0
        cooldown = 0.0
    ElseIf cooldown > 1200.0
        cooldown = 1200.0
    EndIf
    If JsonUtil.GetIntValue(settings, "milkLeakNarration", 1) != 1 || now - lastNarration < cooldown || !MMEAlertsSkyrimNet.IsAvailable() || JsonUtil.GetIntValue("/MMEAlerts/SkyrimNet", "enabled", 1) != 1
        Trace("narration skip | actor=" + target + " | disabled/cooldown/optional dependency")
        Return
    EndIf
    String content = MMENarrationText.Render(MMENarrationText.GetRaw("MilkLeaks", "start"), "actor", target.GetDisplayName())
    content += " " + MMENarrationText.GetRaw("MilkLeaks", "instructions")
    Int result = SkyrimNetApi.DirectNarration(content, None, target)
    If result == 0
        lastNarration = now
    EndIf
    Trace("narration result | actor=" + target + " | result=" + result)
EndFunction
