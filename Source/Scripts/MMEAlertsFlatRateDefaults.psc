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

; This persists in the save so the selected preset is applied only once.
Bool defaultsApplied = False

Event OnInit()
    ApplyDefaults()
EndEvent

; Called after loading as well so the one-time preset can run if MME was not
; available during quest initialization.
Function ApplyDefaults()
    If defaultsApplied
        Return
    EndIf

    Bool personalDefaultsEnabled = JsonUtil.GetIntValue(InstallerFile, "enablePersonalDefaults", 1) == 1
    If !personalDefaultsEnabled
        Debug.Trace("[MME Extensions Defaults] standard MME settings selected; nothing changed")
        Return
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Debug.Trace("[MME Extensions Defaults] MME_MilkQUEST was not found; no settings changed")
        Return
    EndIf

    Actor playerActor = Game.GetPlayer()
    Spell milkEquipment = Game.GetFormFromFile(0x0597A1, "MilkModNEW.esp") as Spell

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
    Debug.Trace("[MME Extensions Defaults] fixed production, level cap, and Novice profile applied")
EndFunction

Function AddSpellIfMissing(Actor playerActor, Spell spellToAdd)
    If playerActor != None && spellToAdd != None && !playerActor.HasSpell(spellToAdd)
        playerActor.AddSpell(spellToAdd, False)
    EndIf
EndFunction

