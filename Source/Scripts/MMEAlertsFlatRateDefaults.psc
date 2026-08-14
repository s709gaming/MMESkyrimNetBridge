Scriptname MMEAlertsFlatRateDefaults extends Quest

; TEMPORARY DEVELOPMENT DEFAULTS.
; These values are applied once per save. Later player MCM choices are not overwritten.
Bool defaultsApplied = False
Int defaultsVersion = 0

; Quest startup applies the development-only MME tuning once per save.
Event OnInit()
    ApplyDefaults()
EndEvent

; Updates MME's controller properties; requires the MME_MilkQUEST quest.
Function ApplyDefaults()
    If defaultsVersion >= 3
        Return
    EndIf

    MilkQUEST milkController = Quest.GetQuest("MME_MilkQUEST") as MilkQUEST
    If milkController == None
        Debug.Trace("[MMEAlert Defaults] MME_MilkQUEST was not found")
        Return
    EndIf

    milkController.FixedMilkGen = True
    milkController.MilkGenValue = 0.30
    milkController.MilkProdMod = 100.0
    milkController.BellyScale = False
    milkController.BreastScaleLimit = False
    milkController.BoobMAX = 0.0
    milkController.BoobIncr = 0.20
    milkController.BoobPerLvl = 0.20
    milkController.GushPct = 100
    If milkController.MilkQC != None
        milkController.MilkQC.Debug_enabled = 1
    Else
        Debug.Trace("[MMEAlert Defaults] MME condition controller was not found; debug was not enabled")
    EndIf

    defaultsApplied = True
    defaultsVersion = 3
    Debug.Trace("[MMEAlert Defaults] fixed=True, gen=.30, prod=100, belly=False, boobMax=0, increments=.2, gush=100, debug=1")
EndFunction
