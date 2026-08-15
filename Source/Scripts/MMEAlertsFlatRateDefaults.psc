Scriptname MMEAlertsFlatRateDefaults extends Quest

; PERSONAL MME DEFAULTS
; ---------------------
; This optional profile reproduces a small set of personal MME preferences:
;   1. Fixed milk production. With otherwise-normal MME settings this naturally
;      produces the desired near-24-hour filling cycle and needs no Lactacid.
;   2. Milkmaid level limiting enabled. MME's own natural cap remains 10.
;   3. Novice progression. MME implements this as TimesMilkedMult = 10.
;
; Milk-generation value and production multiplier remain under MME and the
; player's MCM choices. The preferred body, gush, and MME-debug values below are
; included deliberately and documented beside their assignments.
;
; Earlier project decisions also keep the MME progression convenience at 10 and
; provide MME's own utility spells. Those additions are listed explicitly below
; so future developers can distinguish them from milk-production preferences.
String InstallerFile = "/MMEAlerts/Installer"

; Quest variables persist in the save and allow the FOMOD choice to be undone.
Bool defaultsApplied = False
Bool originalValuesCaptured = False
Int defaultsVersion = 0

; Only settings actually owned by this profile are captured and restored.
Bool originalFixedMilkGen
Bool originalMaidLvlCap
Int originalTimesMilkedMult
Float originalProgressionLevel
Bool originalBellyScale
Bool originalBreastScaleLimit
Float originalBoobMAX
Float originalBoobIncr
Float originalBoobPerLvl
Int originalGushPct
Int originalConditionDebug
Bool originallyHadMakeMilkmaid
Bool originallyHadMilkSelf
Bool originallyHadMilkTarget
Bool originallyHadMilkEquipment

Event OnInit()
    ApplyDefaults()
EndEvent

; Called after loading as well, allowing the dedicated installer choice to be
; honored without touching MME Extensions' ordinary MCM configuration.
Function ApplyDefaults()
    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Debug.Trace("[MME Extensions Defaults] MME_MilkQUEST was not found; no settings changed")
        Return
    EndIf

    Actor playerActor = Game.GetPlayer()
    Spell milkEquipment = Game.GetFormFromFile(0x0597A1, "MilkModNEW.esp") as Spell
    Bool personalDefaultsEnabled = JsonUtil.GetIntValue(InstallerFile, "enablePersonalDefaults", 1) == 1

    If !personalDefaultsEnabled
        If defaultsApplied && originalValuesCaptured
            RestoreOriginalValues(milkController, playerActor, milkEquipment)
        Else
            Debug.Trace("[MME Extensions Defaults] standard MME settings selected; nothing changed")
        EndIf
        Return
    EndIf

    ; Version 8 restores the preferred body, gush, and MME-debug defaults.
    If defaultsApplied && defaultsVersion >= 8
        Return
    EndIf
    If !originalValuesCaptured
        CaptureOriginalValues(milkController, playerActor, milkEquipment)
    EndIf

    ; Fixed mode uses MME's normal fixed-production formula. We deliberately do
    ; not alter MilkGenValue or MilkProdMod; no Lactacid is required in this mode.
    milkController.FixedMilkGen = True
    ; Turn on MME's own level limiter. MilkLvlCap is not rewritten because MME
    ; initializes it to the desired natural cap of 10.
    milkController.MaidLvlCap = True
    ; MME's Difficulty menu maps Novice to ten milkings per progression unit.
    milkController.TimesMilkedMult = 10

    ; Personal body defaults: no belly scaling, no enforced breast-scale ceiling,
    ; and consistent 0.20 growth increments for milk and Milkmaid levels.
    milkController.BellyScale = False
    milkController.BreastScaleLimit = False
    milkController.BoobMAX = 0.0
    milkController.BoobIncr = 0.20
    milkController.BoobPerLvl = 0.20
    ; Every eligible full milking uses MME's gush behavior.
    milkController.GushPct = 100
    ; Retain the preferred MME condition debug setting. This is separate from
    ; MME Extensions' in-game diagnostic notifications.
    If milkController.MilkQC != None
        milkController.MilkQC.Debug_enabled = 1
    EndIf

    ; Convenience choice retained from earlier testing: unlock MME progression.
    StorageUtil.SetFloatValue(None, "MME.Progression.Level", 10.0)
    ; Add only missing MME utility spells; never duplicate existing entries.
    AddSpellIfMissing(playerActor, milkController.MME_MakeMilkmaid_Spell)
    AddSpellIfMissing(playerActor, milkController.MilkSelf)
    AddSpellIfMissing(playerActor, milkController.MilkTarget)
    ; Optional Armor Management MilkEquipment spell; a missing form is harmless.
    AddSpellIfMissing(playerActor, milkEquipment)

    defaultsApplied = True
    defaultsVersion = 8
    Debug.Trace("[MME Extensions Defaults] fixed production, level cap, and Novice profile applied")
EndFunction

Function CaptureOriginalValues(MilkQUEST milkController, Actor playerActor, Spell milkEquipment)
    originalFixedMilkGen = milkController.FixedMilkGen
    originalMaidLvlCap = milkController.MaidLvlCap
    originalTimesMilkedMult = milkController.TimesMilkedMult
    originalProgressionLevel = StorageUtil.GetFloatValue(None, "MME.Progression.Level", 0.0)
    originalBellyScale = milkController.BellyScale
    originalBreastScaleLimit = milkController.BreastScaleLimit
    originalBoobMAX = milkController.BoobMAX
    originalBoobIncr = milkController.BoobIncr
    originalBoobPerLvl = milkController.BoobPerLvl
    originalGushPct = milkController.GushPct
    If milkController.MilkQC != None
        originalConditionDebug = milkController.MilkQC.Debug_enabled
    EndIf
    originallyHadMakeMilkmaid = HasSpellSafe(playerActor, milkController.MME_MakeMilkmaid_Spell)
    originallyHadMilkSelf = HasSpellSafe(playerActor, milkController.MilkSelf)
    originallyHadMilkTarget = HasSpellSafe(playerActor, milkController.MilkTarget)
    originallyHadMilkEquipment = HasSpellSafe(playerActor, milkEquipment)
    originalValuesCaptured = True
    Debug.Trace("[MME Extensions Defaults] original owned values captured")
EndFunction

Function RestoreOriginalValues(MilkQUEST milkController, Actor playerActor, Spell milkEquipment)
    milkController.FixedMilkGen = originalFixedMilkGen
    milkController.MaidLvlCap = originalMaidLvlCap
    milkController.TimesMilkedMult = originalTimesMilkedMult
    StorageUtil.SetFloatValue(None, "MME.Progression.Level", originalProgressionLevel)
    milkController.BellyScale = originalBellyScale
    milkController.BreastScaleLimit = originalBreastScaleLimit
    milkController.BoobMAX = originalBoobMAX
    milkController.BoobIncr = originalBoobIncr
    milkController.BoobPerLvl = originalBoobPerLvl
    milkController.GushPct = originalGushPct
    If milkController.MilkQC != None
        milkController.MilkQC.Debug_enabled = originalConditionDebug
    EndIf
    RemoveAddedSpell(playerActor, milkController.MME_MakeMilkmaid_Spell, originallyHadMakeMilkmaid)
    RemoveAddedSpell(playerActor, milkController.MilkSelf, originallyHadMilkSelf)
    RemoveAddedSpell(playerActor, milkController.MilkTarget, originallyHadMilkTarget)
    RemoveAddedSpell(playerActor, milkEquipment, originallyHadMilkEquipment)
    defaultsApplied = False
    defaultsVersion = 8
    Debug.Trace("[MME Extensions Defaults] original owned values restored")
EndFunction

Function AddSpellIfMissing(Actor playerActor, Spell spellToAdd)
    If playerActor != None && spellToAdd != None && !playerActor.HasSpell(spellToAdd)
        playerActor.AddSpell(spellToAdd, False)
    EndIf
EndFunction

Bool Function HasSpellSafe(Actor playerActor, Spell spellToCheck)
    Return playerActor != None && spellToCheck != None && playerActor.HasSpell(spellToCheck)
EndFunction

Function RemoveAddedSpell(Actor playerActor, Spell suppliedSpell, Bool originallyOwned)
    If playerActor != None && suppliedSpell != None && !originallyOwned && playerActor.HasSpell(suppliedSpell)
        playerActor.RemoveSpell(suppliedSpell)
    EndIf
EndFunction
