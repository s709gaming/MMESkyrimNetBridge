Scriptname MMEAlertsFlatRateDefaults extends Quest

; TEMPORARY DEVELOPMENT DEFAULTS.
; These values are applied once per save. Later player MCM choices are not overwritten.
Bool defaultsApplied = False
Int defaultsVersion = 0

Event OnInit()
    ApplyDefaults()
EndEvent

Function ApplyDefaults()
    If defaultsVersion >= 2
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

    defaultsApplied = True
    defaultsVersion = 2
    Debug.Notification("MME Alerts TEST - flat-rate MME defaults applied once.")
    Debug.Trace("[MMEAlert Defaults] fixed=True, gen=.30, prod=100, belly=False, boobMax=0, increments=.2, gush=100")
EndFunction
