Scriptname MMEOriginalSettings Hidden

; Per-actor mirror of original MilkMCM.Debug_MM_Maid_MilkingMode.
; Original Off (1) remains readable; this two-choice facade writes only 0/2.
Int Function GetMilkingMode(Actor candidate) Global
    If candidate == None
        Return -1
    EndIf
    Int currentMode = StorageUtil.GetIntValue(candidate, "MME.MilkMaid.MilkingMode", 0)
    Failure("modeInvalid." + candidate, currentMode < 0 || currentMode > 2, "read milking mode", candidate, "unknown original MME mode=" + currentMode)
    Return currentMode
EndFunction

String Function MilkingModeBlockReason(Actor candidate) Global
    If candidate == None
        Return "actor unavailable"
    EndIf
    If candidate.IsDeleted() || candidate.IsDead() || candidate.IsChild()
        Return "actor unavailable"
    EndIf
    MilkQUEST milk = Resolve()
    If milk == None
        Return "MME controller unavailable"
    EndIf
    Actor[] maids = milk.MilkMaid
    Failure("modeMaids", maids.Length == 0, "validate milking mode target", candidate, "MilkMaid array unavailable")
    If maids.Length == 0
        Return "MME maid list unavailable"
    EndIf
    If maids.Find(candidate) < 0
        Return "actor is no longer an MME Milk Maid"
    EndIf
    Int currentMode = GetMilkingMode(candidate)
    If currentMode < 0 || currentMode > 2
        Return "original MME mode is invalid"
    EndIf
    ; Preferences do not require milk, armor, proximity, loaded 3D or idle scenes.
    Return ""
EndFunction

Bool Function SetMilkingMode(Actor candidate, Int requestedMode) Global
    MMELog.MasterDiagnostic("[MME Original Settings] mode entry | actor=" + candidate + " | requested=" + requestedMode)
    Failure("modeRequest", requestedMode != 0 && requestedMode != 2, "set milking mode", candidate, "two-choice mirror accepts Manual=0 or Auto=2; requested=" + requestedMode)
    If requestedMode != 0 && requestedMode != 2
        Return False
    EndIf
    String reason = MilkingModeBlockReason(candidate)
    MMELog.MasterDiagnostic("[MME Original Settings] mode eligibility | actor=" + candidate + " | eligible=" + (reason == "") + " | reason=" + reason)
    If reason != ""
        Return False
    EndIf
    Int previousMode = GetMilkingMode(candidate)
    If previousMode == requestedMode
        MMELog.MasterDiagnostic("[MME Original Settings] mode skip | actor=" + candidate + " | already selected=" + previousMode)
        Return True
    EndIf
    StorageUtil.SetIntValue(candidate, "MME.MilkMaid.MilkingMode", requestedMode)
    Int actualMode = GetMilkingMode(candidate)
    Bool success = actualMode == requestedMode
    Failure("modeReadback." + candidate, !success, "set milking mode", candidate, "requested=" + requestedMode + " actual=" + actualMode)
    MMELog.MasterDiagnostic("[MME Original Settings] mode result | actor=" + candidate + " | old=" + previousMode + " | requested=" + requestedMode + " | actual=" + actualMode + " | success=" + success)
    Return success
EndFunction

; Thin MME facade: the original quest, StorageUtil mastery and player spells
; remain authoritative. Preferred milk has a one-time default marker, not a settings copy.
MilkQUEST Function Resolve() Global
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    Failure("quest", milk == None, "resolve settings", None, "MME_MilkQUEST script unavailable")
    Return milk
EndFunction

Function Failure(String settingName, Bool failed, String operation, Actor target, String reason) Global
    String alarmKey = "MMEExtensions.QuickSettings.Alarm." + settingName
    If failed
        If StorageUtil.GetIntValue(None, alarmKey, 0) == 0
            MMELog.Alarm("[MME Original Settings] failure | operation=" + operation + " | actor=" + target + " | reason=" + reason)
            StorageUtil.SetIntValue(None, alarmKey, 1)
        EndIf
    ElseIf StorageUtil.GetIntValue(None, alarmKey, 0) != 0
        StorageUtil.SetIntValue(None, alarmKey, 0)
    EndIf
EndFunction

Bool Function EnsurePreferredMilkDefault() Global
    ; A per-save latch only: the original MilkQC property remains authoritative.
    ; VarSetup resets it to False; wait until original MME initialization is done.
    String defaultKey = "MMEExtensions.PreferredMilk.DefaultApplied"
    If StorageUtil.GetIntValue(None, defaultKey, 0) == 1
        Return True
    EndIf
    If !MMEAlertsController.IsExtensionsEnabled()
        Return False
    EndIf
    MilkQUEST milk = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milk == None
        Return False
    EndIf
    If milk.MilkQC == None || !milk.MilkFlag
        Return False
    EndIf
    Bool previous = milk.MilkQC.MME_SimpleMilkPotions
    milk.MilkQC.MME_SimpleMilkPotions = True
    Bool applied = milk.MilkQC.MME_SimpleMilkPotions
    Failure("preferredMilkDefault", !applied, "initialize preferred milk", None, "original MME setting did not retain True")
    If !applied
        Return False
    EndIf
    StorageUtil.SetIntValue(None, defaultKey, 1)
    MMELog.MasterDiagnostic("[MME Original Settings] preferred milk default applied | old=" + previous + " | actual=" + applied)
    Return True
EndFunction

Function DrawGeneral(SKI_ConfigBase menu) Global
    DrawGeneralAt(menu, 0)
EndFunction

Function DrawGeneralAt(SKI_ConfigBase menu, Int firstRow) Global
    menu.SetCursorPosition(firstRow * 2)
    MilkQUEST milk = Resolve()
    menu.AddHeaderOption(MMELocalization.Text("MME Quick Settings"))
    If milk == None
        menu.AddTextOption(MMELocalization.Text("Original MME settings"), MMELocalization.Text("Unavailable"), 1)
        Return
    EndIf
    menu.AddHeaderOption(MMELocalization.Text("Spells & Progression"))
    Int spellFlags = 0
    If milk.PlayerREF == None || milk.MilkSelf == None || milk.MilkTarget == None
        spellFlags = 1
    EndIf
    Failure("spellPrerequisites", spellFlags != 0, "display player spells", milk.PlayerREF, "player or MME spell unavailable")
    Bool selfKnown = False
    Bool friendKnown = False
    If spellFlags == 0
        selfKnown = milk.PlayerREF.HasSpell(milk.MilkSelf)
        friendKnown = milk.PlayerREF.HasSpell(milk.MilkTarget)
    EndIf
    menu.AddToggleOptionST("OGMilkSelf", MMELocalization.Text("Milk Self Spell"), selfKnown, spellFlags)
    menu.AddToggleOptionST("OGMilkFriend", MMELocalization.Text("Milk Friend Spell"), friendKnown, spellFlags)
    menu.AddMenuOptionST("OGLeveling", MMELocalization.Text("Leveling Speed"), DifficultyLabel(milk))
    menu.AddSliderOptionST("OGMastery", MMELocalization.Text("Milk Mastery (Maid Slots)"), Read(milk, "Mastery"), "{0}")
    menu.SetCursorPosition(firstRow * 2 + 1)
    menu.AddHeaderOption(MMELocalization.Text("Milking & Production"))
    menu.AddSliderOptionST("OGSpeed", MMELocalization.Text("Milking Speed"), milk.GushPct, MMELocalization.Text("{0}% per cycle"))
    menu.AddSliderOptionST("OGDuration", MMELocalization.Text("Milking Cycle Duration"), milk.Milking_Duration, MMELocalization.Text("{0} seconds"))
    menu.AddSliderOptionST("OGProduction", MMELocalization.Text("Milk Production Rate"), milk.MilkProdMod, "{0}%")
    menu.AddToggleOptionST("OGFixed", MMELocalization.Text("Fixed Milk Production - All"), milk.FixedMilkGen)
    Int fixedFlags = 0
    If !milk.FixedMilkGen && !milk.FixedMilkGen4Followers
        fixedFlags = 1
    EndIf
    menu.AddToggleOptionST("FixedLactacidEnabled", MMELocalization.Text("Fixed Mode Lactacid Boost"), MMEFixedLactacid.IsEnabled(), fixedFlags)
    Int bonusFlags = fixedFlags
    If !MMEFixedLactacid.IsEnabled()
        bonusFlags = 1
    EndIf
    menu.AddSliderOptionST("FixedLactacidPercent", MMELocalization.Text("Lactacid Production Bonus"), MMEFixedLactacid.BonusPercent(), "+{0}%", bonusFlags)
    Int preferredMilkFlags = 0
    Bool preferredMilk = False
    If milk.MilkQC == None
        preferredMilkFlags = 1
    Else
        preferredMilk = milk.MilkQC.MME_SimpleMilkPotions
        If !milk.MilkFlag
            preferredMilkFlags = 1
        EndIf
    EndIf
    Failure("preferredMilkConditions", milk.MilkQC == None, "display preferred milk", None, "MilkQC unavailable")
    menu.AddToggleOptionST("OGPreferredMilk", MMELocalization.Text("Only Produce Preferred Milk Type"), preferredMilk, preferredMilkFlags)
    menu.AddHeaderOption(MMELocalization.Text("Economy"))
    menu.AddSliderOptionST("OGPrices", MMELocalization.Text("Milk Price Multiplier"), milk.MilkPriceMod, "x{0}")
    ; Both columns finish before the existing General controls begin.
    menu.SetCursorPosition((firstRow + 11) * 2)
EndFunction

Function DrawBody(SKI_ConfigBase menu) Global
    MilkQUEST milk = Resolve()
    menu.AddHeaderOption(MMELocalization.Text("Original MME Effects"))
    If milk == None
        menu.AddTextOption(MMELocalization.Text("Original MME settings"), MMELocalization.Text("Unavailable"), 1)
        Return
    EndIf
    Int flags = 0
    Bool buffs = False
    If milk.MilkQC == None
        flags = 1
    Else
        buffs = milk.MilkQC.Buffs
    EndIf
    Failure("conditions", flags != 0, "display original effects", None, "MilkQC unavailable")
    menu.AddToggleOptionST("OGDebuffs", MMELocalization.Text("OG Milk Mod Debuffs"), buffs, flags)
    menu.AddHeaderOption(MMELocalization.Text("Original MME Breast Growth"))
    String units = "{2}"
    If milk.BreastVolumeScale
        units = MMELocalization.Text("{1} volume")
    EndIf
    menu.AddSliderOptionST("OGPerMilk", MMELocalization.Text("Breast Growth per Milk"), milk.BoobIncr, units)
    menu.AddSliderOptionST("OGPerLevel", MMELocalization.Text("Breast Growth per Level"), milk.BoobPerLvl, units)
    menu.AddSliderOptionST("OGMaxSize", MMELocalization.Text("Maximum Breast Size"), milk.BoobMAX, "{2}")
EndFunction

Int Function DifficultyIndex(MilkQUEST milk) Global
    If milk == None
        Return -1
    EndIf
    Int value = milk.TimesMilkedMult
    If value == 150
        Return 0
    ElseIf value == 100
        Return 1
    ElseIf value == 75
        Return 2
    ElseIf value == 50
        Return 3
    ElseIf value == 25
        Return 4
    ElseIf value == 10
        Return 5
    EndIf
    Return -1
EndFunction

String[] Function DifficultyOptions() Global
    String[] choices = new String[6]
    choices[0] = MMELocalization.Text("Very Slow (Legendary)")
    choices[1] = MMELocalization.Text("Slow (Master)")
    choices[2] = MMELocalization.Text("Moderately Slow (Expert)")
    choices[3] = MMELocalization.Text("Normal (Adept)")
    choices[4] = MMELocalization.Text("Fast (Apprentice)")
    choices[5] = MMELocalization.Text("Very Fast (Novice)")
    Return choices
EndFunction

String Function DifficultyLabel(MilkQUEST milk) Global
    Int index = DifficultyIndex(milk)
    If index < 0
        Return MMELocalization.Text("Custom (") + milk.TimesMilkedMult + ")"
    EndIf
    String[] choices = DifficultyOptions()
    Return choices[index]
EndFunction

Function OpenDifficulty(SKI_ConfigBase menu) Global
    MilkQUEST milk = Resolve()
    If milk == None
        Return
    EndIf
    menu.SetMenuDialogOptions(DifficultyOptions())
    menu.SetMenuDialogStartIndex(DifficultyIndex(milk))
    menu.SetMenuDialogDefaultIndex(3)
EndFunction

Function SetDifficulty(SKI_ConfigBase menu, Int index) Global
    MilkQUEST milk = Resolve()
    If milk == None || index < 0 || index > 5
        Return
    EndIf
    Failure("economy", milk.MilkE == None, "set leveling speed", None, "MME economy quest unavailable")
    If milk.MilkE == None
        Return
    EndIf
    Int[] multipliers = new Int[6]
    multipliers[0] = 150
    multipliers[1] = 100
    multipliers[2] = 75
    multipliers[3] = 50
    multipliers[4] = 25
    multipliers[5] = 10
    MMELog.MasterDiagnostic("[MME Original Settings] entry | setting=Leveling | old=" + milk.TimesMilkedMult + " | selected=" + index)
    milk.TimesMilkedMult = multipliers[index]
    ; Preserve the original Difficulty setter's economy reinitialization.
    milk.MilkE.InitializeMilkProperties()
    MMELog.MasterDiagnostic("[MME Original Settings] result | setting=Leveling | multiplier=" + milk.TimesMilkedMult + " | economy refreshed")
    menu.ForcePageReset()
EndFunction

Float Function Read(MilkQUEST milk, String settingName) Global
    If settingName == "Mastery"
        Return StorageUtil.GetFloatValue(None, "MME.Progression.Level")
    ElseIf settingName == "Speed"
        Return milk.GushPct
    ElseIf settingName == "Duration"
        Return milk.Milking_Duration
    ElseIf settingName == "Production"
        Return milk.MilkProdMod
    ElseIf settingName == "Prices"
        Return milk.MilkPriceMod
    ElseIf settingName == "PerMilk"
        Return milk.BoobIncr
    ElseIf settingName == "PerLevel"
        Return milk.BoobPerLvl
    ElseIf settingName == "MaxSize"
        Return milk.BoobMAX
    EndIf
    Return 0.0
EndFunction

; [minimum, maximum, step, default], matching original MME slider handlers.
Float[] Function SliderSpec(MilkQUEST milk, String settingName) Global
    Float[] spec = new Float[4]
    spec[2] = 1.0
    If settingName == "Mastery"
        spec[1] = 40.0
    ElseIf settingName == "Speed"
        spec[1] = 100.0
        spec[2] = 5.0
        spec[3] = 10.0
    ElseIf settingName == "Duration"
        spec[0] = 1.0
        spec[1] = 300.0
        spec[3] = 5.0
    ElseIf settingName == "Production"
        spec[1] = 200.0
        spec[2] = 10.0
        spec[3] = 100.0
    ElseIf settingName == "Prices"
        spec[0] = 1.0
        spec[1] = 10.0
        spec[3] = 1.0
    ElseIf settingName == "MaxSize"
        spec[1] = 36.0
        spec[2] = 0.01
        spec[3] = 3.0
    ElseIf settingName == "PerMilk"
        spec[1] = 0.5
        spec[2] = 0.01
        spec[3] = 0.05
        If milk.BreastVolumeScale
            spec[1] = 24.0
            spec[2] = 0.1
            spec[3] = 6.0
        EndIf
    ElseIf settingName == "PerLevel"
        spec[1] = 3.0
        spec[2] = 0.01
        spec[3] = 0.7
        If milk.BreastVolumeScale
            spec[1] = 6.0
            spec[2] = 0.1
            spec[3] = 2.0
        EndIf
    EndIf
    Return spec
EndFunction

Function OpenSlider(SKI_ConfigBase menu, String settingName) Global
    MilkQUEST milk = Resolve()
    If milk == None
        Return
    EndIf
    Float[] spec = SliderSpec(milk, settingName)
    menu.SetSliderDialogStartValue(Read(milk, settingName))
    menu.SetSliderDialogRange(spec[0], spec[1])
    menu.SetSliderDialogInterval(spec[2])
    menu.SetSliderDialogDefaultValue(spec[3])
EndFunction

Function SetSlider(SKI_ConfigBase menu, String settingName, Float value) Global
    MilkQUEST milk = Resolve()
    If milk == None
        Return
    EndIf
    Float[] spec = SliderSpec(milk, settingName)
    If value < spec[0] || value > spec[1]
        Failure("range", True, "set " + settingName, None, "value outside original MME range: " + value)
        Return
    EndIf
    Failure("range", False, "", None, "")
    If settingName == "MaxSize"
        Failure("maids", milk.MilkMaid.Length == 0, "set maximum breast size", None, "MilkMaid array unavailable")
        If milk.MilkMaid.Length == 0
            Return
        EndIf
    EndIf
    MMELog.MasterDiagnostic("[MME Original Settings] entry | setting=" + settingName + " | old=" + Read(milk, settingName) + " | requested=" + value)
    If settingName == "Mastery"
        StorageUtil.SetFloatValue(None, "MME.Progression.Level", value)
    ElseIf settingName == "Speed"
        milk.GushPct = value as Int
    ElseIf settingName == "Duration"
        milk.Milking_Duration = value as Int
    ElseIf settingName == "Production"
        milk.MilkProdMod = value
    ElseIf settingName == "Prices"
        milk.MilkPriceMod = value as Int
    ElseIf settingName == "PerMilk"
        milk.BoobIncr = value
    ElseIf settingName == "PerLevel"
        milk.BoobPerLvl = value
    ElseIf settingName == "MaxSize"
        milk.BoobMAX = value
        RefreshMaids(milk, False)
    EndIf
    MMELog.MasterDiagnostic("[MME Original Settings] result | setting=" + settingName + " | actual=" + Read(milk, settingName))
    menu.ForcePageReset()
EndFunction

Function Toggle(SKI_ConfigBase menu, String settingName) Global
    MilkQUEST milk = Resolve()
    If milk == None
        Return
    EndIf
    MMELog.MasterDiagnostic("[MME Original Settings] entry | toggle=" + settingName)
    Bool result = False
    If settingName == "Fixed"
        milk.FixedMilkGen = !milk.FixedMilkGen
        result = milk.FixedMilkGen
    ElseIf settingName == "PreferredMilk"
        Failure("preferredMilkConditions", milk.MilkQC == None, "toggle preferred milk", None, "MilkQC unavailable")
        If milk.MilkQC == None
            Return
        EndIf
        If !milk.MilkFlag
            MMELog.MasterDiagnostic("[MME Original Settings] preferred milk skipped | original MME initialization pending")
            Return
        EndIf
        Bool desiredMilk = !milk.MilkQC.MME_SimpleMilkPotions
        milk.MilkQC.MME_SimpleMilkPotions = desiredMilk
        result = milk.MilkQC.MME_SimpleMilkPotions
        Failure("preferredMilkResult", result != desiredMilk, "toggle preferred milk", None, "original MME setting did not retain requested value")
        If result == desiredMilk
            StorageUtil.SetIntValue(None, "MMEExtensions.PreferredMilk.DefaultApplied", 1)
        EndIf
    ElseIf settingName == "Debuffs"
        Failure("conditions", milk.MilkQC == None, "toggle original effects", None, "MilkQC unavailable")
        If milk.MilkQC == None
            Return
        EndIf
        Failure("maids", milk.MilkMaid.Length == 0, "toggle original effects", None, "MilkMaid array unavailable")
        If milk.MilkMaid.Length == 0
            Return
        EndIf
        milk.MilkQC.Buffs = !milk.MilkQC.Buffs
        result = milk.MilkQC.Buffs
        RefreshMaids(milk, True)
    Else
        Actor player = milk.PlayerREF
        Spell selected = milk.MilkSelf
        If settingName == "MilkFriend"
            selected = milk.MilkTarget
        EndIf
        Failure("spellPrerequisites", player == None || selected == None, "toggle " + settingName, player, "player or MME spell unavailable")
        If player == None || selected == None
            Return
        EndIf
        Bool desired = !player.HasSpell(selected)
        If desired
            player.AddSpell(selected, False)
        Else
            player.RemoveSpell(selected)
        EndIf
        result = player.HasSpell(selected)
        Failure("spellResult", result != desired, "toggle " + settingName, player, "spell ownership did not match requested state")
        MMELog.MasterDiagnostic("[MME Original Settings] spell result | actor=" + player + " | spell=" + selected + " | enabled=" + result)
    EndIf
    MMELog.MasterDiagnostic("[MME Original Settings] result | toggle=" + settingName + " | enabled=" + result)
    menu.ForcePageReset()
EndFunction

Function RefreshMaids(MilkQUEST milk, Bool effects) Global
    ; Same slot iteration as original MCM. Do not index parallel MME arrays,
    ; recalculate maid levels, assign slots, convert actors or alter overrides.
    Actor[] maids = milk.MilkMaid
    Failure("maids", maids.Length == 0, "refresh MME maids", None, "MilkMaid array unavailable")
    If maids.Length == 0
        Return
    EndIf
    Int index = 0
    Int refreshed = 0
    While index < maids.Length
        Actor target = maids[index]
        If target != None
            MMELog.MasterDiagnostic("[MME Original Settings] refresh | slot=" + index + " | actor=" + target + " | effects=" + effects)
            If effects
                milk.PostMilk(target)
            Else
                milk.CurrentSize(target)
            EndIf
            refreshed += 1
        EndIf
        index += 1
    EndWhile
    MMELog.MasterDiagnostic("[MME Original Settings] cleanup | refreshed=" + refreshed + " | effects=" + effects)
EndFunction
