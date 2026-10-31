.info
  .source "MMEDiagnostics.psc"
  .modifyTime 1793367138
  .compileTime 1793367192
  .user "Donald"
  .computer "DESKTOP-TQJH8KD"
.endInfo
.userFlagsRef
  .flag conditional 1
  .flag hidden 0
.endUserFlagsRef
.objectTable
  .object MMEDiagnostics 
    .userFlags 1
    .docString ""
    .autoState 
    .variableTable
    .endVariableTable
    .propertyTable
    .endPropertyTable
    .stateTable
      .state
        .function GetState
          .userFlags 0
          .docString "Function that returns the current state"
          .return String
          .paramTable
          .endParamTable
          .localTable
          .endLocalTable
          .code
            RETURN ::state
          .endCode
        .endFunction
        .function GotoState
          .userFlags 0
          .docString "Function that switches this object to the specified state"
          .return None
          .paramTable
            .param newState String
          .endParamTable
          .localTable
            .local ::NoneVar None
          .endLocalTable
          .code
            CALLMETHOD onEndState self ::NoneVar
            ASSIGN ::state newState
            CALLMETHOD onBeginState self ::NoneVar
          .endCode
        .endFunction
        .function GetGateStatus static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp0 form
            .local ::temp1 globalvariable
            .local ::temp2 bool
            .local ::temp3 float
            .local ::temp4 bool
            .local gate GlobalVariable
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp0 2138 "MMEAlert.esp" ;@line 9
            CAST ::temp1 ::temp0 ;@line 9
            ASSIGN gate ::temp1 ;@line 9
            CAST ::temp1 None ;@line 10
            COMPAREEQ ::temp2 gate ::temp1 ;@line 10
            JUMPF ::temp2 label2 ;@line 10
            RETURN "MISSING" ;@line 11
            JUMP label0
            label2:
            CALLMETHOD GetValue gate ::temp3  ;@line 12
            COMPAREGTE ::temp4 ::temp3 1.0 ;@line 12
            JUMPF ::temp4 label1 ;@line 12
            RETURN "ON" ;@line 13
            JUMP label0
            label1:
            label0:
            RETURN "OFF" ;@line 15
          .endCode
        .endFunction
        .function GetInstallStatus static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp5 form
            .local ::temp6 form
            .local ::temp7 bool
            .local ::temp8 bool
            .local ::temp9 bool
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp5 2048 "MMEAlert.esp" ;@line 19
            CAST ::temp6 None ;@line 19
            COMPAREEQ ::temp7 ::temp5 ::temp6 ;@line 19
            JUMPF ::temp7 label9 ;@line 19
            RETURN "QUEST MISSING" ;@line 20
            JUMP label3
            label9:
            CALLSTATIC game GetFormFromFile ::temp6 2138 "MMEAlert.esp" ;@line 24
            CAST ::temp5 None ;@line 24
            COMPAREEQ ::temp8 ::temp6 ::temp5 ;@line 24
            CAST ::temp8 ::temp8 ;@line 24
            JUMPT ::temp8 label4 ;@line 24
            CALLSTATIC game GetFormFromFile ::temp5 2173 "MMEAlert.esp" ;@line 24
            CAST ::temp6 None ;@line 24
            COMPAREEQ ::temp9 ::temp5 ::temp6 ;@line 24
            CAST ::temp8 ::temp9 ;@line 24
            label4:
            CAST ::temp8 ::temp8 ;@line 24
            JUMPT ::temp8 label5 ;@line 24
            CALLSTATIC game GetFormFromFile ::temp6 2177 "MMEAlert.esp" ;@line 24
            CAST ::temp5 None ;@line 24
            COMPAREEQ ::temp9 ::temp6 ::temp5 ;@line 24
            CAST ::temp8 ::temp9 ;@line 24
            label5:
            CAST ::temp8 ::temp8 ;@line 24
            JUMPT ::temp8 label6 ;@line 24
            CALLSTATIC game GetFormFromFile ::temp5 2182 "MMEAlert.esp" ;@line 24
            CAST ::temp6 None ;@line 24
            COMPAREEQ ::temp9 ::temp5 ::temp6 ;@line 24
            CAST ::temp8 ::temp9 ;@line 24
            label6:
            CAST ::temp8 ::temp8 ;@line 24
            JUMPT ::temp8 label7 ;@line 24
            CALLSTATIC game GetFormFromFile ::temp6 2187 "MMEAlert.esp" ;@line 24
            CAST ::temp5 None ;@line 24
            COMPAREEQ ::temp9 ::temp6 ::temp5 ;@line 24
            CAST ::temp8 ::temp9 ;@line 24
            label7:
            JUMPF ::temp8 label8 ;@line 24
            RETURN "GATES MISSING" ;@line 25
            JUMP label3
            label8:
            label3:
            RETURN "RECORDS READY" ;@line 27
          .endCode
        .endFunction
        .function GetOStimStatus static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp10 bool
            .local ::temp11 int
            .local ::temp12 bool
          .endLocalTable
          .code
            CALLSTATIC mmeostimbreastfeeding IsOStimDetected ::temp10  ;@line 31
            NOT ::temp10 ::temp10 ;@line 31
            JUMPF ::temp10 label12 ;@line 31
            RETURN "NOT DETECTED" ;@line 32
            JUMP label10
            label12:
            CALLSTATIC jsonutil GetIntValue ::temp11 "/MMEAlerts/Settings" "enableOStimBreastfeeding" 0 ;@line 33
            COMPAREEQ ::temp12 ::temp11 1 ;@line 33
            NOT ::temp12 ::temp12 ;@line 33
            JUMPF ::temp12 label11 ;@line 33
            RETURN "DISABLED" ;@line 34
            JUMP label10
            label11:
            label10:
            RETURN "ENABLED" ;@line 36
          .endCode
        .endFunction
        .function GetSexLabStatus static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
          .endLocalTable
          .code
            RETURN "NOT USED (OStim-only)" ;@line 40
          .endCode
        .endFunction
        .function GetDebugService static
          .userFlags 0
          .docString ""
          .return MMEDebug
          .paramTable
          .endParamTable
          .localTable
            .local ::temp13 form
            .local ::temp14 mmedebug
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp13 2048 "MMEAlert.esp" ;@line 44
            CAST ::temp14 ::temp13 ;@line 44
            RETURN ::temp14 ;@line 44
          .endCode
        .endFunction
        .function GetNewMilkMaidSexLabBusState static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp15 mmedebug
            .local ::temp16 bool
            .local ::temp17 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp15  ;@line 48
            ASSIGN service ::temp15 ;@line 48
            CAST ::temp15 None ;@line 49
            COMPAREEQ ::temp16 service ::temp15 ;@line 49
            JUMPF ::temp16 label14 ;@line 49
            RETURN "SERVICE MISSING" ;@line 50
            JUMP label13
            label14:
            label13:
            CALLMETHOD GetNewMilkMaidSexLabBusState service ::temp17  ;@line 52
            RETURN ::temp17 ;@line 52
          .endCode
        .endFunction
        .function GetNewMilkMaidSexLabBusStop static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp18 mmedebug
            .local ::temp19 bool
            .local ::temp20 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp18  ;@line 56
            ASSIGN service ::temp18 ;@line 56
            CAST ::temp18 None ;@line 57
            COMPAREEQ ::temp19 service ::temp18 ;@line 57
            JUMPF ::temp19 label16 ;@line 57
            RETURN "none" ;@line 58
            JUMP label15
            label16:
            label15:
            CALLMETHOD GetNewMilkMaidSexLabBusStop service ::temp20  ;@line 60
            RETURN ::temp20 ;@line 60
          .endCode
        .endFunction
        .function GetNewMilkMaidSexLabBusFailure static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp21 mmedebug
            .local ::temp22 bool
            .local ::temp23 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp21  ;@line 64
            ASSIGN service ::temp21 ;@line 64
            CAST ::temp21 None ;@line 65
            COMPAREEQ ::temp22 service ::temp21 ;@line 65
            JUMPF ::temp22 label18 ;@line 65
            RETURN "service missing" ;@line 66
            JUMP label17
            label18:
            label17:
            CALLMETHOD GetNewMilkMaidSexLabBusFailure service ::temp23  ;@line 68
            RETURN ::temp23 ;@line 68
          .endCode
        .endFunction
        .function IsBlacksmithDialogueTraceEnabled static
          .userFlags 0
          .docString ""
          .return Bool
          .paramTable
          .endParamTable
          .localTable
            .local ::temp24 int
            .local ::temp25 bool
          .endLocalTable
          .code
            CALLSTATIC jsonutil GetIntValue ::temp24 "/MMEAlerts/Settings" "enableBlacksmithDialogueTrace" 0 ;@line 72
            COMPAREEQ ::temp25 ::temp24 1 ;@line 72
            RETURN ::temp25 ;@line 72
          .endCode
        .endFunction
        .function GetBlacksmithDialogueBusState static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp26 mmedebug
            .local ::temp27 bool
            .local ::temp28 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp26  ;@line 76
            ASSIGN service ::temp26 ;@line 76
            CAST ::temp26 None ;@line 77
            COMPAREEQ ::temp27 service ::temp26 ;@line 77
            JUMPF ::temp27 label20 ;@line 77
            RETURN "SERVICE MISSING" ;@line 78
            JUMP label19
            label20:
            label19:
            CALLMETHOD GetBlacksmithDialogueBusState service ::temp28  ;@line 80
            RETURN ::temp28 ;@line 80
          .endCode
        .endFunction
        .function GetBlacksmithDialogueBusStop static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp29 mmedebug
            .local ::temp30 bool
            .local ::temp31 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp29  ;@line 84
            ASSIGN service ::temp29 ;@line 84
            CAST ::temp29 None ;@line 85
            COMPAREEQ ::temp30 service ::temp29 ;@line 85
            JUMPF ::temp30 label22 ;@line 85
            RETURN "none" ;@line 86
            JUMP label21
            label22:
            label21:
            CALLMETHOD GetBlacksmithDialogueBusStop service ::temp31  ;@line 88
            RETURN ::temp31 ;@line 88
          .endCode
        .endFunction
        .function GetBlacksmithDialogueBusFailure static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp32 mmedebug
            .local ::temp33 bool
            .local ::temp34 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp32  ;@line 92
            ASSIGN service ::temp32 ;@line 92
            CAST ::temp32 None ;@line 93
            COMPAREEQ ::temp33 service ::temp32 ;@line 93
            JUMPF ::temp33 label24 ;@line 93
            RETURN "service missing" ;@line 94
            JUMP label23
            label24:
            label23:
            CALLMETHOD GetBlacksmithDialogueBusFailure service ::temp34  ;@line 96
            RETURN ::temp34 ;@line 96
          .endCode
        .endFunction
        .function ShowBlacksmithDialogueBusReport static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param useMessageBox Bool
          .endParamTable
          .localTable
            .local ::temp35 mmedebug
            .local ::temp36 bool
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp35  ;@line 100
            ASSIGN service ::temp35 ;@line 100
            CAST ::temp35 None ;@line 101
            COMPAREEQ ::temp36 service ::temp35 ;@line 101
            JUMPF ::temp36 label26 ;@line 101
            CALLSTATIC mmediagnostics Report ::nonevar "Blacksmith bus FAIL: persistent service is missing" 2 ;@line 102
            RETURN none ;@line 103
            JUMP label25
            label26:
            label25:
            CALLMETHOD ShowBlacksmithDialogueBusReport service ::nonevar useMessageBox ;@line 105
          .endCode
        .endFunction
        .function RunBlacksmithDialogueBusTest static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp37 objectreference
            .local ::temp38 actor
            .local ::temp39 mmedebug
            .local ::temp40 bool
            .local candidate Actor
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC game GetCurrentCrosshairRef ::temp37  ;@line 109
            CAST ::temp38 ::temp37 ;@line 109
            ASSIGN candidate ::temp38 ;@line 109
            CALLSTATIC mmediagnostics GetDebugService ::temp39  ;@line 110
            ASSIGN service ::temp39 ;@line 110
            CAST ::temp39 None ;@line 111
            COMPAREEQ ::temp40 service ::temp39 ;@line 111
            JUMPF ::temp40 label28 ;@line 111
            CALLSTATIC mmediagnostics Report ::nonevar "Blacksmith bus FAIL: persistent service is missing" 2 ;@line 112
            RETURN none ;@line 113
            JUMP label27
            label28:
            label27:
            CALLSTATIC mmediagnostics RunBlacksmithDialogueBus ::nonevar candidate False ;@line 115
            CALLMETHOD ShowBlacksmithDialogueBusReport service ::nonevar True ;@line 116
          .endCode
        .endFunction
        .function ObserveBlacksmithDialogueState static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param candidate Actor
          .endParamTable
          .localTable
            .local ::temp41 bool
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics IsBlacksmithDialogueTraceEnabled ::temp41  ;@line 123
            JUMPF ::temp41 label30 ;@line 123
            CALLSTATIC mmediagnostics RunBlacksmithDialogueBus ::nonevar candidate True ;@line 124
            JUMP label29
            label30:
            label29:
          .endCode
        .endFunction
        .function RunBlacksmithDialogueBus static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param candidate Actor
            .param openingObserved Bool
          .endParamTable
          .localTable
            .local ::temp42 mmedebug
            .local ::temp43 bool
            .local ::temp44 bool
            .local ::temp45 form
            .local ::temp46 globalvariable
            .local ::temp47 actor
            .local ::temp48 string
            .local ::temp49 faction
            .local ::temp50 quest
            .local ::temp51 milkquest
            .local ::temp52 faction
            .local ::temp53 int
            .local ::temp54 armor
            .local ::temp56 bool
            .local ::temp57 float
            .local service MMEDebug
            .local writeTrace Bool
            .local stateGlobal GlobalVariable
            .local addTopic Form
            .local removeTopic Form
            .local addInfo Form
            .local removeInfo Form
            .local ::nonevar none
            .local blacksmithFaction Faction
            .local merchantFaction Faction
            .local milkController MilkQUEST
            .local playerActor Actor
            .local wornArmor Armor
            .local armorName String
            .local ::temp55 string[]
            .local protectedReason String
            .local matches Int
            .local expectedState Int
            .local expectedRoute String
            .local publishedState Int
            .local ::temp58 string
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp42  ;@line 131
            ASSIGN service ::temp42 ;@line 131
            CAST ::temp42 None ;@line 132
            COMPAREEQ ::temp43 service ::temp42 ;@line 132
            JUMPF ::temp43 label32 ;@line 132
            RETURN none ;@line 133
            JUMP label31
            label32:
            label31:
            CALLSTATIC mmediagnostics IsBlacksmithDialogueTraceEnabled ::temp43  ;@line 135
            CAST ::temp43 ::temp43 ;@line 135
            JUMPT ::temp43 label33 ;@line 135
            CALLSTATIC mmelog IsDiagnosticEnabled ::temp44  ;@line 135
            CAST ::temp43 ::temp44 ;@line 135
            label33:
            ASSIGN writeTrace ::temp43 ;@line 135
            CALLSTATIC game GetFormFromFile ::temp45 2177 "MMEAlert.esp" ;@line 136
            CAST ::temp46 ::temp45 ;@line 136
            ASSIGN stateGlobal ::temp46 ;@line 136
            CALLSTATIC game GetFormFromFile ::temp45 2178 "MMEAlert.esp" ;@line 137
            ASSIGN addTopic ::temp45 ;@line 137
            CALLSTATIC game GetFormFromFile ::temp45 2179 "MMEAlert.esp" ;@line 138
            ASSIGN removeTopic ::temp45 ;@line 138
            CALLSTATIC game GetFormFromFile ::temp45 2180 "MMEAlert.esp" ;@line 139
            ASSIGN addInfo ::temp45 ;@line 139
            CALLSTATIC game GetFormFromFile ::temp45 2181 "MMEAlert.esp" ;@line 140
            ASSIGN removeInfo ::temp45 ;@line 140
            CAST ::temp46 None ;@line 141
            COMPAREEQ ::temp44 stateGlobal ::temp46 ;@line 141
            CAST ::temp44 ::temp44 ;@line 141
            JUMPT ::temp44 label35 ;@line 141
            CAST ::temp45 None ;@line 141
            COMPAREEQ ::temp43 addTopic ::temp45 ;@line 141
            CAST ::temp44 ::temp43 ;@line 141
            label35:
            CAST ::temp44 ::temp44 ;@line 141
            JUMPT ::temp44 label36 ;@line 141
            CAST ::temp45 None ;@line 141
            COMPAREEQ ::temp43 removeTopic ::temp45 ;@line 141
            CAST ::temp44 ::temp43 ;@line 141
            label36:
            CAST ::temp44 ::temp44 ;@line 141
            JUMPT ::temp44 label37 ;@line 141
            CAST ::temp45 None ;@line 141
            COMPAREEQ ::temp43 addInfo ::temp45 ;@line 141
            CAST ::temp44 ::temp43 ;@line 141
            label37:
            CAST ::temp44 ::temp44 ;@line 141
            JUMPT ::temp44 label38 ;@line 141
            CAST ::temp45 None ;@line 141
            COMPAREEQ ::temp43 removeInfo ::temp45 ;@line 141
            CAST ::temp44 ::temp43 ;@line 141
            label38:
            JUMPF ::temp44 label39 ;@line 141
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 1 "production Global/DIAL/INFO records are missing" True False False False writeTrace ;@line 142
            RETURN none ;@line 143
            JUMP label34
            label39:
            label34:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 1 "production records resolved" False False False False writeTrace ;@line 145
            CALLSTATIC mmealertscontroller IsExtensionsEnabled ::temp43  ;@line 147
            NOT ::temp44 ::temp43 ;@line 147
            JUMPF ::temp44 label41 ;@line 147
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 2 "MME Extensions master toggle is off" False True False False writeTrace ;@line 148
            RETURN none ;@line 149
            JUMP label40
            label41:
            label40:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 2 "MME Extensions enabled" False False False False writeTrace ;@line 151
            CAST ::temp47 None ;@line 153
            COMPAREEQ ::temp43 candidate ::temp47 ;@line 153
            JUMPF ::temp43 label43 ;@line 153
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 3 "no NPC under the crosshair/dialogue target unavailable" False True False False writeTrace ;@line 154
            RETURN none ;@line 155
            JUMP label42
            label43:
            label42:
            CALLMETHOD GetName candidate ::temp48  ;@line 157
            STRCAT ::temp48 "target=" ::temp48 ;@line 157
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 3 ::temp48 False False False False writeTrace ;@line 157
            CALLSTATIC game GetFormFromFile ::temp45 330013 "Skyrim.esm" ;@line 159
            CAST ::temp49 ::temp45 ;@line 159
            ASSIGN blacksmithFaction ::temp49 ;@line 159
            CAST ::temp49 None ;@line 160
            COMPAREEQ ::temp44 blacksmithFaction ::temp49 ;@line 160
            JUMPF ::temp44 label46 ;@line 160
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 4 "JobBlacksmithFaction form is missing" True False False False writeTrace ;@line 161
            RETURN none ;@line 162
            JUMP label44
            label46:
            CALLMETHOD IsInFaction candidate ::temp43 blacksmithFaction ;@line 163
            NOT ::temp43 ::temp43 ;@line 163
            JUMPF ::temp43 label45 ;@line 163
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 4 "target is not in JobBlacksmithFaction" False True False False writeTrace ;@line 164
            RETURN none ;@line 165
            JUMP label44
            label45:
            label44:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 4 "JobBlacksmithFaction PASS" False False False False writeTrace ;@line 167
            CALLSTATIC game GetFormFromFile ::temp45 333206 "Skyrim.esm" ;@line 169
            CAST ::temp49 ::temp45 ;@line 169
            ASSIGN merchantFaction ::temp49 ;@line 169
            CAST ::temp49 None ;@line 170
            COMPAREEQ ::temp43 merchantFaction ::temp49 ;@line 170
            JUMPF ::temp43 label49 ;@line 170
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 5 "JobMerchantFaction form is missing" True False False False writeTrace ;@line 171
            RETURN none ;@line 172
            JUMP label47
            label49:
            CALLMETHOD IsInFaction candidate ::temp44 merchantFaction ;@line 173
            NOT ::temp44 ::temp44 ;@line 173
            JUMPF ::temp44 label48 ;@line 173
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 5 "target is not in JobMerchantFaction" False True False False writeTrace ;@line 174
            RETURN none ;@line 175
            JUMP label47
            label48:
            label47:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 5 "JobMerchantFaction PASS" False False False False writeTrace ;@line 177
            CALLSTATIC quest GetQuest ::temp50 "MME_MilkQUEST" ;@line 179
            CAST ::temp51 ::temp50 ;@line 179
            ASSIGN milkController ::temp51 ;@line 179
            CALLSTATIC game GetPlayer ::temp47  ;@line 180
            ASSIGN playerActor ::temp47 ;@line 180
            CAST ::temp51 None ;@line 181
            COMPAREEQ ::temp44 milkController ::temp51 ;@line 181
            CAST ::temp44 ::temp44 ;@line 181
            JUMPT ::temp44 label51 ;@line 181
            CAST ::temp47 None ;@line 181
            COMPAREEQ ::temp43 playerActor ::temp47 ;@line 181
            CAST ::temp44 ::temp43 ;@line 181
            label51:
            CAST ::temp44 ::temp44 ;@line 181
            JUMPT ::temp44 label52 ;@line 181
            PROPGET MilkMaidFaction milkController ::temp49 ;@line 181
            CAST ::temp52 None ;@line 181
            COMPAREEQ ::temp43 ::temp49 ::temp52 ;@line 181
            CAST ::temp44 ::temp43 ;@line 181
            label52:
            CAST ::temp44 ::temp44 ;@line 181
            JUMPT ::temp44 label53 ;@line 181
            PROPGET MilkSlaveFaction milkController ::temp52 ;@line 181
            CAST ::temp49 None ;@line 181
            COMPAREEQ ::temp43 ::temp52 ::temp49 ;@line 181
            CAST ::temp44 ::temp43 ;@line 181
            label53:
            JUMPF ::temp44 label54 ;@line 181
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 6 "MME controller/player/faction properties unavailable" True False False False writeTrace ;@line 182
            RETURN none ;@line 183
            JUMP label50
            label54:
            label50:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 6 "MME controller and faction properties PASS" False False False False writeTrace ;@line 185
            PROPGET MilkMaidFaction milkController ::temp49 ;@line 187
            CALLMETHOD IsInFaction playerActor ::temp43 ::temp49 ;@line 187
            NOT ::temp44 ::temp43 ;@line 187
            JUMPF ::temp44 label56 ;@line 187
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 7 "player is not in MME MilkMaidFaction" False True False False writeTrace ;@line 188
            RETURN none ;@line 189
            JUMP label55
            label56:
            label55:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 7 "player Milk Maid PASS" False False False False writeTrace ;@line 191
            PROPGET MilkSlaveFaction milkController ::temp52 ;@line 193
            CALLMETHOD IsInFaction playerActor ::temp43 ::temp52 ;@line 193
            JUMPF ::temp43 label58 ;@line 193
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 8 "player is an MME Milk Slave" False True False False writeTrace ;@line 194
            RETURN none ;@line 195
            JUMP label57
            label58:
            label57:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 8 "player non-Slave PASS" False False False False writeTrace ;@line 197
            CALLSTATIC armor GetMaskForSlot ::temp53 32 ;@line 199
            CALLMETHOD GetWornForm playerActor ::temp45 ::temp53 ;@line 199
            CAST ::temp54 ::temp45 ;@line 199
            ASSIGN wornArmor ::temp54 ;@line 199
            CAST ::temp54 None ;@line 200
            COMPAREEQ ::temp44 wornArmor ::temp54 ;@line 200
            JUMPF ::temp44 label60 ;@line 200
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 9 "no slot-32 armor is equipped" False True False False writeTrace ;@line 201
            RETURN none ;@line 202
            JUMP label59
            label60:
            label59:
            CALLMETHOD GetName wornArmor ::temp48  ;@line 204
            STRCAT ::temp48 "slot-32 armor=" ::temp48 ;@line 204
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 9 ::temp48 False False False False writeTrace ;@line 204
            CALLMETHOD GetName wornArmor ::temp48  ;@line 206
            ASSIGN armorName ::temp48 ;@line 206
            COMPAREEQ ::temp43 armorName "" ;@line 207
            CAST ::temp43 ::temp43 ;@line 207
            JUMPT ::temp43 label62 ;@line 207
            COMPAREEQ ::temp44 armorName "Empty" ;@line 207
            CAST ::temp43 ::temp44 ;@line 207
            label62:
            CAST ::temp43 ::temp43 ;@line 207
            JUMPT ::temp43 label63 ;@line 207
            COMPAREEQ ::temp44 armorName "empty" ;@line 207
            CAST ::temp43 ::temp44 ;@line 207
            label63:
            JUMPF ::temp43 label64 ;@line 207
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 10 "armor has an unusable display name" False True False False writeTrace ;@line 208
            RETURN none ;@line 209
            JUMP label61
            label64:
            label61:
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 10 "armor identity PASS" False False False False writeTrace ;@line 211
            CALLSTATIC mmearmorscript AreArmorRegistriesSafeForManagement ::temp44 milkController ;@line 213
            NOT ::temp43 ::temp44 ;@line 213
            JUMPF ::temp43 label66 ;@line 213
            PROPGET MilkingEquipment milkController ::temp55 ;@line 214
            ARRAYLENGTH ::temp53 ::temp55 ;@line 214
            CAST ::temp48 ::temp53 ;@line 214
            STRCAT ::temp48 "MilkingEquipment length=" ::temp48 ;@line 214
            STRCAT ::temp48 ::temp48 "; OG requires at least 5" ;@line 214
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 11 ::temp48 True False False False writeTrace ;@line 214
            RETURN none ;@line 215
            JUMP label65
            label66:
            label65:
            CALLSTATIC mmearmorscript GetMMEProtectedArmorReason ::temp48 milkController wornArmor "blacksmith-bus" playerActor ;@line 217
            ASSIGN protectedReason ::temp48 ;@line 217
            COMPAREEQ ::temp44 protectedReason "" ;@line 218
            NOT ::temp44 ::temp44 ;@line 218
            JUMPF ::temp44 label68 ;@line 218
            STRCAT ::temp48 "protected armor: " protectedReason ;@line 219
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 11 ::temp48 False True False False writeTrace ;@line 219
            RETURN none ;@line 220
            JUMP label67
            label68:
            label67:
            CALLSTATIC mmearmorscript CountMilkingEquipmentMatchesDirect ::temp53 milkController armorName ;@line 222
            ASSIGN matches ::temp53 ;@line 222
            ASSIGN expectedState 0 ;@line 223
            ASSIGN expectedRoute "" ;@line 224
            COMPAREEQ ::temp43 matches 1 ;@line 225
            JUMPF ::temp43 label73 ;@line 225
            ASSIGN expectedState 2 ;@line 226
            ASSIGN expectedRoute "REMOVE" ;@line 227
            JUMP label69
            label73:
            COMPAREEQ ::temp44 matches 0 ;@line 228
            CAST ::temp44 ::temp44 ;@line 228
            JUMPF ::temp44 label70 ;@line 228
            CALLSTATIC mmearmorscript FindMilkingEquipmentEmptySlotDirect ::temp53 milkController ;@line 228
            COMPAREGTE ::temp56 ::temp53 0 ;@line 228
            CAST ::temp44 ::temp56 ;@line 228
            label70:
            JUMPF ::temp44 label71 ;@line 228
            ASSIGN expectedState 1 ;@line 229
            ASSIGN expectedRoute "ADD" ;@line 230
            JUMP label69
            label71:
            COMPAREEQ ::temp56 matches 0 ;@line 231
            JUMPF ::temp56 label72 ;@line 231
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 11 "MilkingEquipment is full" False True False False writeTrace ;@line 232
            RETURN none ;@line 233
            JUMP label69
            label72:
            CAST ::temp48 matches ;@line 235
            STRCAT ::temp48 "registration match count is invalid: " ::temp48 ;@line 235
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 11 ::temp48 True False False False writeTrace ;@line 235
            RETURN none ;@line 236
            label69:
            STRCAT ::temp48 "preflight expects " expectedRoute ;@line 238
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 11 ::temp48 False False False False writeTrace ;@line 238
            NOT ::temp44 openingObserved ;@line 240
            JUMPF ::temp44 label75 ;@line 240
            STRCAT ::temp48 "preflight expects " expectedRoute ;@line 241
            STRCAT ::temp48 ::temp48 "; open [MME] Hey there! with live trace enabled" ;@line 241
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 11 ::temp48 False False True False writeTrace ;@line 241
            RETURN none ;@line 242
            JUMP label74
            label75:
            label74:
            CALLMETHOD GetValue stateGlobal ::temp57  ;@line 244
            CAST ::temp53 ::temp57 ;@line 244
            ASSIGN publishedState ::temp53 ;@line 244
            COMPAREEQ ::temp56 publishedState expectedState ;@line 245
            NOT ::temp56 ::temp56 ;@line 245
            JUMPF ::temp56 label77 ;@line 245
            CAST ::temp48 expectedState ;@line 246
            STRCAT ::temp48 "opening state mismatch: expected " ::temp48 ;@line 246
            STRCAT ::temp48 ::temp48 " (" ;@line 246
            STRCAT ::temp48 ::temp48 expectedRoute ;@line 246
            STRCAT ::temp48 ::temp48 ") got " ;@line 246
            CAST ::temp58 publishedState ;@line 246
            STRCAT ::temp58 ::temp48 ::temp58 ;@line 246
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 12 ::temp58 True False False False writeTrace ;@line 246
            RETURN none ;@line 247
            JUMP label76
            label77:
            label76:
            CAST ::temp48 publishedState ;@line 249
            STRCAT ::temp58 "opening state=" ::temp48 ;@line 249
            STRCAT ::temp48 ::temp58 " (" ;@line 249
            STRCAT ::temp58 ::temp48 expectedRoute ;@line 249
            STRCAT ::temp48 ::temp58 ") PASS" ;@line 249
            CALLMETHOD RecordBlacksmithDialogueBusStop service ::nonevar 12 ::temp48 False False False False writeTrace ;@line 249
          .endCode
        .endFunction
        .function IsAlchemistDialogueTraceEnabled static
          .userFlags 0
          .docString ""
          .return Bool
          .paramTable
          .endParamTable
          .localTable
            .local ::temp59 int
            .local ::temp60 bool
          .endLocalTable
          .code
            CALLSTATIC jsonutil GetIntValue ::temp59 "/MMEAlerts/Settings" "enableAlchemistDialogueTrace" 0 ;@line 254
            COMPAREEQ ::temp60 ::temp59 1 ;@line 254
            RETURN ::temp60 ;@line 254
          .endCode
        .endFunction
        .function GetAlchemistDialogueBusState static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp61 mmedebug
            .local ::temp62 bool
            .local ::temp63 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp61  ;@line 258
            ASSIGN service ::temp61 ;@line 258
            CAST ::temp61 None ;@line 259
            COMPAREEQ ::temp62 service ::temp61 ;@line 259
            JUMPF ::temp62 label79 ;@line 259
            RETURN "SERVICE MISSING" ;@line 260
            JUMP label78
            label79:
            label78:
            CALLMETHOD GetAlchemistDialogueBusState service ::temp63  ;@line 262
            RETURN ::temp63 ;@line 262
          .endCode
        .endFunction
        .function GetAlchemistDialogueBusStop static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp64 mmedebug
            .local ::temp65 bool
            .local ::temp66 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp64  ;@line 266
            ASSIGN service ::temp64 ;@line 266
            CAST ::temp64 None ;@line 267
            COMPAREEQ ::temp65 service ::temp64 ;@line 267
            JUMPF ::temp65 label81 ;@line 267
            RETURN "none" ;@line 268
            JUMP label80
            label81:
            label80:
            CALLMETHOD GetAlchemistDialogueBusStop service ::temp66  ;@line 270
            RETURN ::temp66 ;@line 270
          .endCode
        .endFunction
        .function GetAlchemistDialogueBusFailure static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp67 mmedebug
            .local ::temp68 bool
            .local ::temp69 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp67  ;@line 274
            ASSIGN service ::temp67 ;@line 274
            CAST ::temp67 None ;@line 275
            COMPAREEQ ::temp68 service ::temp67 ;@line 275
            JUMPF ::temp68 label83 ;@line 275
            RETURN "service missing" ;@line 276
            JUMP label82
            label83:
            label82:
            CALLMETHOD GetAlchemistDialogueBusFailure service ::temp69  ;@line 278
            RETURN ::temp69 ;@line 278
          .endCode
        .endFunction
        .function ShowAlchemistDialogueBusReport static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param useMessageBox Bool
          .endParamTable
          .localTable
            .local ::temp70 mmedebug
            .local ::temp71 bool
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp70  ;@line 282
            ASSIGN service ::temp70 ;@line 282
            CAST ::temp70 None ;@line 283
            COMPAREEQ ::temp71 service ::temp70 ;@line 283
            JUMPF ::temp71 label85 ;@line 283
            CALLSTATIC mmediagnostics Report ::nonevar "Alchemist bus FAIL: persistent service is missing" 2 ;@line 284
            RETURN none ;@line 285
            JUMP label84
            label85:
            label84:
            CALLMETHOD ShowAlchemistDialogueBusReport service ::nonevar useMessageBox ;@line 287
          .endCode
        .endFunction
        .function RunAlchemistDialogueBusTest static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp72 objectreference
            .local ::temp73 actor
            .local ::temp74 mmedebug
            .local ::temp75 bool
            .local candidate Actor
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC game GetCurrentCrosshairRef ::temp72  ;@line 291
            CAST ::temp73 ::temp72 ;@line 291
            ASSIGN candidate ::temp73 ;@line 291
            CALLSTATIC mmediagnostics GetDebugService ::temp74  ;@line 292
            ASSIGN service ::temp74 ;@line 292
            CAST ::temp74 None ;@line 293
            COMPAREEQ ::temp75 service ::temp74 ;@line 293
            JUMPF ::temp75 label87 ;@line 293
            CALLSTATIC mmediagnostics Report ::nonevar "Alchemist bus FAIL: persistent service is missing" 2 ;@line 294
            RETURN none ;@line 295
            JUMP label86
            label87:
            label86:
            CALLSTATIC mmediagnostics RunAlchemistDialogueBus ::nonevar candidate False ;@line 297
            CALLMETHOD ShowAlchemistDialogueBusReport service ::nonevar True ;@line 298
          .endCode
        .endFunction
        .function ObserveAlchemistDialogueState static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param candidate Actor
          .endParamTable
          .localTable
            .local ::temp76 bool
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics IsAlchemistDialogueTraceEnabled ::temp76  ;@line 305
            JUMPF ::temp76 label89 ;@line 305
            CALLSTATIC mmediagnostics RunAlchemistDialogueBus ::nonevar candidate True ;@line 306
            JUMP label88
            label89:
            label88:
          .endCode
        .endFunction
        .function RunAlchemistDialogueBus static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param candidate Actor
            .param openingObserved Bool
          .endParamTable
          .localTable
            .local ::temp77 mmedebug
            .local ::temp78 bool
            .local ::temp79 bool
            .local ::temp80 form
            .local ::temp81 globalvariable
            .local ::temp82 actor
            .local ::temp83 string
            .local ::temp84 faction
            .local ::temp85 quest
            .local ::temp86 milkquest
            .local ::temp87 faction
            .local ::temp88 int
            .local ::temp89 armor
            .local ::temp91 bool
            .local ::temp92 float
            .local service MMEDebug
            .local writeTrace Bool
            .local stateGlobal GlobalVariable
            .local addTopic Form
            .local removeTopic Form
            .local addInfo Form
            .local removeInfo Form
            .local ::nonevar none
            .local alchemistFaction Faction
            .local merchantFaction Faction
            .local milkController MilkQUEST
            .local playerActor Actor
            .local wornArmor Armor
            .local armorName String
            .local ::temp90 string[]
            .local protectedReason String
            .local matches Int
            .local expectedState Int
            .local expectedRoute String
            .local publishedState Int
            .local ::temp93 string
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp77  ;@line 313
            ASSIGN service ::temp77 ;@line 313
            CAST ::temp77 None ;@line 314
            COMPAREEQ ::temp78 service ::temp77 ;@line 314
            JUMPF ::temp78 label91 ;@line 314
            RETURN none ;@line 315
            JUMP label90
            label91:
            label90:
            CALLSTATIC mmediagnostics IsAlchemistDialogueTraceEnabled ::temp78  ;@line 317
            CAST ::temp78 ::temp78 ;@line 317
            JUMPT ::temp78 label92 ;@line 317
            CALLSTATIC mmelog IsDiagnosticEnabled ::temp79  ;@line 317
            CAST ::temp78 ::temp79 ;@line 317
            label92:
            ASSIGN writeTrace ::temp78 ;@line 317
            CALLSTATIC game GetFormFromFile ::temp80 2182 "MMEAlert.esp" ;@line 318
            CAST ::temp81 ::temp80 ;@line 318
            ASSIGN stateGlobal ::temp81 ;@line 318
            CALLSTATIC game GetFormFromFile ::temp80 2183 "MMEAlert.esp" ;@line 319
            ASSIGN addTopic ::temp80 ;@line 319
            CALLSTATIC game GetFormFromFile ::temp80 2184 "MMEAlert.esp" ;@line 320
            ASSIGN removeTopic ::temp80 ;@line 320
            CALLSTATIC game GetFormFromFile ::temp80 2185 "MMEAlert.esp" ;@line 321
            ASSIGN addInfo ::temp80 ;@line 321
            CALLSTATIC game GetFormFromFile ::temp80 2186 "MMEAlert.esp" ;@line 322
            ASSIGN removeInfo ::temp80 ;@line 322
            CAST ::temp81 None ;@line 323
            COMPAREEQ ::temp79 stateGlobal ::temp81 ;@line 323
            CAST ::temp79 ::temp79 ;@line 323
            JUMPT ::temp79 label94 ;@line 323
            CAST ::temp80 None ;@line 323
            COMPAREEQ ::temp78 addTopic ::temp80 ;@line 323
            CAST ::temp79 ::temp78 ;@line 323
            label94:
            CAST ::temp79 ::temp79 ;@line 323
            JUMPT ::temp79 label95 ;@line 323
            CAST ::temp80 None ;@line 323
            COMPAREEQ ::temp78 removeTopic ::temp80 ;@line 323
            CAST ::temp79 ::temp78 ;@line 323
            label95:
            CAST ::temp79 ::temp79 ;@line 323
            JUMPT ::temp79 label96 ;@line 323
            CAST ::temp80 None ;@line 323
            COMPAREEQ ::temp78 addInfo ::temp80 ;@line 323
            CAST ::temp79 ::temp78 ;@line 323
            label96:
            CAST ::temp79 ::temp79 ;@line 323
            JUMPT ::temp79 label97 ;@line 323
            CAST ::temp80 None ;@line 323
            COMPAREEQ ::temp78 removeInfo ::temp80 ;@line 323
            CAST ::temp79 ::temp78 ;@line 323
            label97:
            JUMPF ::temp79 label98 ;@line 323
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 1 "production Global/DIAL/INFO records are missing" True False False False writeTrace ;@line 324
            RETURN none ;@line 325
            JUMP label93
            label98:
            label93:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 1 "production records resolved" False False False False writeTrace ;@line 327
            CALLSTATIC mmealertscontroller IsExtensionsEnabled ::temp78  ;@line 329
            NOT ::temp79 ::temp78 ;@line 329
            JUMPF ::temp79 label100 ;@line 329
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 2 "MME Extensions master toggle is off" False True False False writeTrace ;@line 330
            RETURN none ;@line 331
            JUMP label99
            label100:
            label99:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 2 "MME Extensions enabled" False False False False writeTrace ;@line 333
            CAST ::temp82 None ;@line 335
            COMPAREEQ ::temp78 candidate ::temp82 ;@line 335
            JUMPF ::temp78 label102 ;@line 335
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 3 "no NPC under the crosshair/dialogue target unavailable" False True False False writeTrace ;@line 336
            RETURN none ;@line 337
            JUMP label101
            label102:
            label101:
            CALLMETHOD GetName candidate ::temp83  ;@line 339
            STRCAT ::temp83 "target=" ::temp83 ;@line 339
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 3 ::temp83 False False False False writeTrace ;@line 339
            CALLSTATIC game GetFormFromFile ::temp80 330012 "Skyrim.esm" ;@line 341
            CAST ::temp84 ::temp80 ;@line 341
            ASSIGN alchemistFaction ::temp84 ;@line 341
            CAST ::temp84 None ;@line 342
            COMPAREEQ ::temp79 alchemistFaction ::temp84 ;@line 342
            JUMPF ::temp79 label105 ;@line 342
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 4 "JobApothecaryFaction form is missing" True False False False writeTrace ;@line 343
            RETURN none ;@line 344
            JUMP label103
            label105:
            CALLMETHOD IsInFaction candidate ::temp78 alchemistFaction ;@line 345
            NOT ::temp78 ::temp78 ;@line 345
            JUMPF ::temp78 label104 ;@line 345
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 4 "target is not in JobApothecaryFaction" False True False False writeTrace ;@line 346
            RETURN none ;@line 347
            JUMP label103
            label104:
            label103:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 4 "JobApothecaryFaction PASS" False False False False writeTrace ;@line 349
            CALLSTATIC game GetFormFromFile ::temp80 333206 "Skyrim.esm" ;@line 351
            CAST ::temp84 ::temp80 ;@line 351
            ASSIGN merchantFaction ::temp84 ;@line 351
            CAST ::temp84 None ;@line 352
            COMPAREEQ ::temp78 merchantFaction ::temp84 ;@line 352
            JUMPF ::temp78 label108 ;@line 352
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 5 "JobMerchantFaction form is missing" True False False False writeTrace ;@line 353
            RETURN none ;@line 354
            JUMP label106
            label108:
            CALLMETHOD IsInFaction candidate ::temp79 merchantFaction ;@line 355
            NOT ::temp79 ::temp79 ;@line 355
            JUMPF ::temp79 label107 ;@line 355
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 5 "target is not in JobMerchantFaction" False True False False writeTrace ;@line 356
            RETURN none ;@line 357
            JUMP label106
            label107:
            label106:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 5 "JobMerchantFaction PASS" False False False False writeTrace ;@line 359
            CALLSTATIC quest GetQuest ::temp85 "MME_MilkQUEST" ;@line 361
            CAST ::temp86 ::temp85 ;@line 361
            ASSIGN milkController ::temp86 ;@line 361
            CALLSTATIC game GetPlayer ::temp82  ;@line 362
            ASSIGN playerActor ::temp82 ;@line 362
            CAST ::temp86 None ;@line 363
            COMPAREEQ ::temp79 milkController ::temp86 ;@line 363
            CAST ::temp79 ::temp79 ;@line 363
            JUMPT ::temp79 label110 ;@line 363
            CAST ::temp82 None ;@line 363
            COMPAREEQ ::temp78 playerActor ::temp82 ;@line 363
            CAST ::temp79 ::temp78 ;@line 363
            label110:
            CAST ::temp79 ::temp79 ;@line 363
            JUMPT ::temp79 label111 ;@line 363
            PROPGET MilkMaidFaction milkController ::temp84 ;@line 363
            CAST ::temp87 None ;@line 363
            COMPAREEQ ::temp78 ::temp84 ::temp87 ;@line 363
            CAST ::temp79 ::temp78 ;@line 363
            label111:
            CAST ::temp79 ::temp79 ;@line 363
            JUMPT ::temp79 label112 ;@line 363
            PROPGET MilkSlaveFaction milkController ::temp87 ;@line 363
            CAST ::temp84 None ;@line 363
            COMPAREEQ ::temp78 ::temp87 ::temp84 ;@line 363
            CAST ::temp79 ::temp78 ;@line 363
            label112:
            JUMPF ::temp79 label113 ;@line 363
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 6 "MME controller/player/faction properties unavailable" True False False False writeTrace ;@line 364
            RETURN none ;@line 365
            JUMP label109
            label113:
            label109:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 6 "MME controller and faction properties PASS" False False False False writeTrace ;@line 367
            PROPGET MilkMaidFaction milkController ::temp84 ;@line 369
            CALLMETHOD IsInFaction playerActor ::temp78 ::temp84 ;@line 369
            NOT ::temp79 ::temp78 ;@line 369
            JUMPF ::temp79 label115 ;@line 369
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 7 "player is not in MME MilkMaidFaction" False True False False writeTrace ;@line 370
            RETURN none ;@line 371
            JUMP label114
            label115:
            label114:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 7 "player Milk Maid PASS" False False False False writeTrace ;@line 373
            PROPGET MilkSlaveFaction milkController ::temp87 ;@line 375
            CALLMETHOD IsInFaction playerActor ::temp78 ::temp87 ;@line 375
            JUMPF ::temp78 label117 ;@line 375
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 8 "player is an MME Milk Slave" False True False False writeTrace ;@line 376
            RETURN none ;@line 377
            JUMP label116
            label117:
            label116:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 8 "player non-Slave PASS" False False False False writeTrace ;@line 379
            CALLSTATIC armor GetMaskForSlot ::temp88 32 ;@line 381
            CALLMETHOD GetWornForm playerActor ::temp80 ::temp88 ;@line 381
            CAST ::temp89 ::temp80 ;@line 381
            ASSIGN wornArmor ::temp89 ;@line 381
            CAST ::temp89 None ;@line 382
            COMPAREEQ ::temp79 wornArmor ::temp89 ;@line 382
            JUMPF ::temp79 label119 ;@line 382
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 9 "no slot-32 armor is equipped" False True False False writeTrace ;@line 383
            RETURN none ;@line 384
            JUMP label118
            label119:
            label118:
            CALLMETHOD GetName wornArmor ::temp83  ;@line 386
            STRCAT ::temp83 "slot-32 armor=" ::temp83 ;@line 386
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 9 ::temp83 False False False False writeTrace ;@line 386
            CALLMETHOD GetName wornArmor ::temp83  ;@line 388
            ASSIGN armorName ::temp83 ;@line 388
            COMPAREEQ ::temp78 armorName "" ;@line 389
            CAST ::temp78 ::temp78 ;@line 389
            JUMPT ::temp78 label121 ;@line 389
            COMPAREEQ ::temp79 armorName "Empty" ;@line 389
            CAST ::temp78 ::temp79 ;@line 389
            label121:
            CAST ::temp78 ::temp78 ;@line 389
            JUMPT ::temp78 label122 ;@line 389
            COMPAREEQ ::temp79 armorName "empty" ;@line 389
            CAST ::temp78 ::temp79 ;@line 389
            label122:
            JUMPF ::temp78 label123 ;@line 389
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 10 "armor has an unusable display name" False True False False writeTrace ;@line 390
            RETURN none ;@line 391
            JUMP label120
            label123:
            label120:
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 10 "armor identity PASS" False False False False writeTrace ;@line 393
            CALLSTATIC mmearmorscript IsBasicLivingArmorRegistrySafeForManagement ::temp79 milkController ;@line 395
            NOT ::temp78 ::temp79 ;@line 395
            JUMPF ::temp78 label125 ;@line 395
            PROPGET BasicLivingArmor milkController ::temp90 ;@line 396
            ARRAYLENGTH ::temp88 ::temp90 ;@line 396
            CAST ::temp83 ::temp88 ;@line 396
            STRCAT ::temp83 "BasicLivingArmor length=" ::temp83 ;@line 396
            STRCAT ::temp83 ::temp83 "; OG requires at least 5" ;@line 396
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 11 ::temp83 True False False False writeTrace ;@line 396
            RETURN none ;@line 397
            JUMP label124
            label125:
            label124:
            CALLSTATIC mmearmorscript GetMMEProtectedForBasicLivingArmorReason ::temp83 milkController wornArmor ;@line 399
            ASSIGN protectedReason ::temp83 ;@line 399
            COMPAREEQ ::temp79 protectedReason "" ;@line 400
            NOT ::temp79 ::temp79 ;@line 400
            JUMPF ::temp79 label127 ;@line 400
            STRCAT ::temp83 "protected armor: " protectedReason ;@line 401
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 11 ::temp83 False True False False writeTrace ;@line 401
            RETURN none ;@line 402
            JUMP label126
            label127:
            label126:
            CALLSTATIC mmearmorscript CountBasicLivingArmorMatchesDirect ::temp88 milkController armorName ;@line 404
            ASSIGN matches ::temp88 ;@line 404
            ASSIGN expectedState 0 ;@line 405
            ASSIGN expectedRoute "" ;@line 406
            COMPAREEQ ::temp78 matches 1 ;@line 407
            JUMPF ::temp78 label132 ;@line 407
            ASSIGN expectedState 2 ;@line 408
            ASSIGN expectedRoute "REMOVE" ;@line 409
            JUMP label128
            label132:
            COMPAREEQ ::temp79 matches 0 ;@line 410
            CAST ::temp79 ::temp79 ;@line 410
            JUMPF ::temp79 label129 ;@line 410
            CALLSTATIC mmearmorscript FindBasicLivingArmorEmptySlotDirect ::temp88 milkController ;@line 410
            COMPAREGTE ::temp91 ::temp88 0 ;@line 410
            CAST ::temp79 ::temp91 ;@line 410
            label129:
            JUMPF ::temp79 label130 ;@line 410
            ASSIGN expectedState 1 ;@line 411
            ASSIGN expectedRoute "ADD" ;@line 412
            JUMP label128
            label130:
            COMPAREEQ ::temp91 matches 0 ;@line 413
            JUMPF ::temp91 label131 ;@line 413
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 11 "BasicLivingArmor is full" False True False False writeTrace ;@line 414
            RETURN none ;@line 415
            JUMP label128
            label131:
            CAST ::temp83 matches ;@line 417
            STRCAT ::temp83 "registration match count is invalid: " ::temp83 ;@line 417
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 11 ::temp83 True False False False writeTrace ;@line 417
            RETURN none ;@line 418
            label128:
            STRCAT ::temp83 "preflight expects " expectedRoute ;@line 420
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 11 ::temp83 False False False False writeTrace ;@line 420
            NOT ::temp79 openingObserved ;@line 422
            JUMPF ::temp79 label134 ;@line 422
            STRCAT ::temp83 "preflight expects " expectedRoute ;@line 423
            STRCAT ::temp83 ::temp83 "; open [MME] Hey there! with live trace enabled" ;@line 423
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 11 ::temp83 False False True False writeTrace ;@line 423
            RETURN none ;@line 424
            JUMP label133
            label134:
            label133:
            CALLMETHOD GetValue stateGlobal ::temp92  ;@line 426
            CAST ::temp88 ::temp92 ;@line 426
            ASSIGN publishedState ::temp88 ;@line 426
            COMPAREEQ ::temp91 publishedState expectedState ;@line 427
            NOT ::temp91 ::temp91 ;@line 427
            JUMPF ::temp91 label136 ;@line 427
            CAST ::temp83 expectedState ;@line 428
            STRCAT ::temp83 "opening state mismatch: expected " ::temp83 ;@line 428
            STRCAT ::temp83 ::temp83 " (" ;@line 428
            STRCAT ::temp83 ::temp83 expectedRoute ;@line 428
            STRCAT ::temp83 ::temp83 ") got " ;@line 428
            CAST ::temp93 publishedState ;@line 428
            STRCAT ::temp93 ::temp83 ::temp93 ;@line 428
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 12 ::temp93 True False False False writeTrace ;@line 428
            RETURN none ;@line 429
            JUMP label135
            label136:
            label135:
            CAST ::temp83 publishedState ;@line 431
            STRCAT ::temp93 "opening state=" ::temp83 ;@line 431
            STRCAT ::temp83 ::temp93 " (" ;@line 431
            STRCAT ::temp93 ::temp83 expectedRoute ;@line 431
            STRCAT ::temp83 ::temp93 ") PASS" ;@line 431
            CALLMETHOD RecordAlchemistDialogueBusStop service ::nonevar 12 ::temp83 False False False False writeTrace ;@line 431
          .endCode
        .endFunction
        .function IsMageDialogueTraceEnabled static
          .userFlags 0
          .docString ""
          .return Bool
          .paramTable
          .endParamTable
          .localTable
            .local ::temp94 int
            .local ::temp95 bool
          .endLocalTable
          .code
            CALLSTATIC jsonutil GetIntValue ::temp94 "/MMEAlerts/Settings" "enableMageDialogueTrace" 0 ;@line 436
            COMPAREEQ ::temp95 ::temp94 1 ;@line 436
            RETURN ::temp95 ;@line 436
          .endCode
        .endFunction
        .function GetMageDialogueBusState static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp96 mmedebug
            .local ::temp97 bool
            .local ::temp98 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp96  ;@line 440
            ASSIGN service ::temp96 ;@line 440
            CAST ::temp96 None ;@line 441
            COMPAREEQ ::temp97 service ::temp96 ;@line 441
            JUMPF ::temp97 label138 ;@line 441
            RETURN "SERVICE MISSING" ;@line 442
            JUMP label137
            label138:
            label137:
            CALLMETHOD GetMageDialogueBusState service ::temp98  ;@line 444
            RETURN ::temp98 ;@line 444
          .endCode
        .endFunction
        .function GetMageDialogueBusStop static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp99 mmedebug
            .local ::temp100 bool
            .local ::temp101 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp99  ;@line 448
            ASSIGN service ::temp99 ;@line 448
            CAST ::temp99 None ;@line 449
            COMPAREEQ ::temp100 service ::temp99 ;@line 449
            JUMPF ::temp100 label140 ;@line 449
            RETURN "none" ;@line 450
            JUMP label139
            label140:
            label139:
            CALLMETHOD GetMageDialogueBusStop service ::temp101  ;@line 452
            RETURN ::temp101 ;@line 452
          .endCode
        .endFunction
        .function GetMageDialogueBusFailure static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
          .endParamTable
          .localTable
            .local ::temp102 mmedebug
            .local ::temp103 bool
            .local ::temp104 string
            .local service MMEDebug
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp102  ;@line 456
            ASSIGN service ::temp102 ;@line 456
            CAST ::temp102 None ;@line 457
            COMPAREEQ ::temp103 service ::temp102 ;@line 457
            JUMPF ::temp103 label142 ;@line 457
            RETURN "service missing" ;@line 458
            JUMP label141
            label142:
            label141:
            CALLMETHOD GetMageDialogueBusFailure service ::temp104  ;@line 460
            RETURN ::temp104 ;@line 460
          .endCode
        .endFunction
        .function ShowMageDialogueBusReport static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param useMessageBox Bool
          .endParamTable
          .localTable
            .local ::temp105 mmedebug
            .local ::temp106 bool
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp105  ;@line 464
            ASSIGN service ::temp105 ;@line 464
            CAST ::temp105 None ;@line 465
            COMPAREEQ ::temp106 service ::temp105 ;@line 465
            JUMPF ::temp106 label144 ;@line 465
            CALLSTATIC mmediagnostics Report ::nonevar "Mage bus FAIL: persistent service is missing" 2 ;@line 466
            RETURN none ;@line 467
            JUMP label143
            label144:
            label143:
            CALLMETHOD ShowMageDialogueBusReport service ::nonevar useMessageBox ;@line 469
          .endCode
        .endFunction
        .function RunMageDialogueBusTest static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp107 objectreference
            .local ::temp108 actor
            .local ::temp109 mmedebug
            .local ::temp110 bool
            .local candidate Actor
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC game GetCurrentCrosshairRef ::temp107  ;@line 473
            CAST ::temp108 ::temp107 ;@line 473
            ASSIGN candidate ::temp108 ;@line 473
            CALLSTATIC mmediagnostics GetDebugService ::temp109  ;@line 474
            ASSIGN service ::temp109 ;@line 474
            CAST ::temp109 None ;@line 475
            COMPAREEQ ::temp110 service ::temp109 ;@line 475
            JUMPF ::temp110 label146 ;@line 475
            CALLSTATIC mmediagnostics Report ::nonevar "Mage bus FAIL: persistent service is missing" 2 ;@line 476
            RETURN none ;@line 477
            JUMP label145
            label146:
            label145:
            CALLSTATIC mmediagnostics RunMageDialogueBus ::nonevar candidate False ;@line 479
            CALLMETHOD ShowMageDialogueBusReport service ::nonevar True ;@line 480
          .endCode
        .endFunction
        .function ObserveMageDialogueState static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param candidate Actor
          .endParamTable
          .localTable
            .local ::temp111 bool
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics IsMageDialogueTraceEnabled ::temp111  ;@line 487
            JUMPF ::temp111 label148 ;@line 487
            CALLSTATIC mmediagnostics RunMageDialogueBus ::nonevar candidate True ;@line 488
            JUMP label147
            label148:
            label147:
          .endCode
        .endFunction
        .function RunMageDialogueBus static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param candidate Actor
            .param openingObserved Bool
          .endParamTable
          .localTable
            .local ::temp112 mmedebug
            .local ::temp113 bool
            .local ::temp114 bool
            .local ::temp115 form
            .local ::temp116 globalvariable
            .local ::temp117 actor
            .local ::temp118 string
            .local ::temp119 faction
            .local ::temp120 quest
            .local ::temp121 milkquest
            .local ::temp122 faction
            .local ::temp123 int
            .local ::temp124 armor
            .local ::temp126 bool
            .local ::temp127 float
            .local service MMEDebug
            .local writeTrace Bool
            .local stateGlobal GlobalVariable
            .local addTopic Form
            .local removeTopic Form
            .local addInfo Form
            .local removeInfo Form
            .local ::nonevar none
            .local mageFaction Faction
            .local merchantFaction Faction
            .local milkController MilkQUEST
            .local playerActor Actor
            .local wornArmor Armor
            .local armorName String
            .local ::temp125 string[]
            .local protectedReason String
            .local matches Int
            .local expectedState Int
            .local expectedRoute String
            .local publishedState Int
            .local ::temp128 string
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp112  ;@line 495
            ASSIGN service ::temp112 ;@line 495
            CAST ::temp112 None ;@line 496
            COMPAREEQ ::temp113 service ::temp112 ;@line 496
            JUMPF ::temp113 label150 ;@line 496
            RETURN none ;@line 497
            JUMP label149
            label150:
            label149:
            CALLSTATIC mmediagnostics IsMageDialogueTraceEnabled ::temp113  ;@line 499
            CAST ::temp113 ::temp113 ;@line 499
            JUMPT ::temp113 label151 ;@line 499
            CALLSTATIC mmelog IsDiagnosticEnabled ::temp114  ;@line 499
            CAST ::temp113 ::temp114 ;@line 499
            label151:
            ASSIGN writeTrace ::temp113 ;@line 499
            CALLSTATIC game GetFormFromFile ::temp115 2187 "MMEAlert.esp" ;@line 500
            CAST ::temp116 ::temp115 ;@line 500
            ASSIGN stateGlobal ::temp116 ;@line 500
            CALLSTATIC game GetFormFromFile ::temp115 2188 "MMEAlert.esp" ;@line 501
            ASSIGN addTopic ::temp115 ;@line 501
            CALLSTATIC game GetFormFromFile ::temp115 2189 "MMEAlert.esp" ;@line 502
            ASSIGN removeTopic ::temp115 ;@line 502
            CALLSTATIC game GetFormFromFile ::temp115 2190 "MMEAlert.esp" ;@line 503
            ASSIGN addInfo ::temp115 ;@line 503
            CALLSTATIC game GetFormFromFile ::temp115 2191 "MMEAlert.esp" ;@line 504
            ASSIGN removeInfo ::temp115 ;@line 504
            CAST ::temp116 None ;@line 505
            COMPAREEQ ::temp114 stateGlobal ::temp116 ;@line 505
            CAST ::temp114 ::temp114 ;@line 505
            JUMPT ::temp114 label153 ;@line 505
            CAST ::temp115 None ;@line 505
            COMPAREEQ ::temp113 addTopic ::temp115 ;@line 505
            CAST ::temp114 ::temp113 ;@line 505
            label153:
            CAST ::temp114 ::temp114 ;@line 505
            JUMPT ::temp114 label154 ;@line 505
            CAST ::temp115 None ;@line 505
            COMPAREEQ ::temp113 removeTopic ::temp115 ;@line 505
            CAST ::temp114 ::temp113 ;@line 505
            label154:
            CAST ::temp114 ::temp114 ;@line 505
            JUMPT ::temp114 label155 ;@line 505
            CAST ::temp115 None ;@line 505
            COMPAREEQ ::temp113 addInfo ::temp115 ;@line 505
            CAST ::temp114 ::temp113 ;@line 505
            label155:
            CAST ::temp114 ::temp114 ;@line 505
            JUMPT ::temp114 label156 ;@line 505
            CAST ::temp115 None ;@line 505
            COMPAREEQ ::temp113 removeInfo ::temp115 ;@line 505
            CAST ::temp114 ::temp113 ;@line 505
            label156:
            JUMPF ::temp114 label157 ;@line 505
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 1 "production Global/DIAL/INFO records are missing" True False False False writeTrace ;@line 506
            RETURN none ;@line 507
            JUMP label152
            label157:
            label152:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 1 "production records resolved" False False False False writeTrace ;@line 509
            CALLSTATIC mmealertscontroller IsExtensionsEnabled ::temp113  ;@line 511
            NOT ::temp114 ::temp113 ;@line 511
            JUMPF ::temp114 label159 ;@line 511
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 2 "MME Extensions master toggle is off" False True False False writeTrace ;@line 512
            RETURN none ;@line 513
            JUMP label158
            label159:
            label158:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 2 "MME Extensions enabled" False False False False writeTrace ;@line 515
            CAST ::temp117 None ;@line 517
            COMPAREEQ ::temp113 candidate ::temp117 ;@line 517
            JUMPF ::temp113 label161 ;@line 517
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 3 "no NPC under the crosshair/dialogue target unavailable" False True False False writeTrace ;@line 518
            RETURN none ;@line 519
            JUMP label160
            label161:
            label160:
            CALLMETHOD GetName candidate ::temp118  ;@line 521
            STRCAT ::temp118 "target=" ::temp118 ;@line 521
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 3 ::temp118 False False False False writeTrace ;@line 521
            CALLSTATIC game GetFormFromFile ::temp115 330014 "Skyrim.esm" ;@line 523
            CAST ::temp119 ::temp115 ;@line 523
            ASSIGN mageFaction ::temp119 ;@line 523
            CAST ::temp119 None ;@line 524
            COMPAREEQ ::temp114 mageFaction ::temp119 ;@line 524
            JUMPF ::temp114 label164 ;@line 524
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 4 "JobCourtWizardFaction form is missing" True False False False writeTrace ;@line 525
            RETURN none ;@line 526
            JUMP label162
            label164:
            CALLMETHOD IsInFaction candidate ::temp113 mageFaction ;@line 527
            NOT ::temp113 ::temp113 ;@line 527
            JUMPF ::temp113 label163 ;@line 527
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 4 "target is not in JobCourtWizardFaction" False True False False writeTrace ;@line 528
            RETURN none ;@line 529
            JUMP label162
            label163:
            label162:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 4 "JobCourtWizardFaction PASS" False False False False writeTrace ;@line 531
            CALLSTATIC game GetFormFromFile ::temp115 333206 "Skyrim.esm" ;@line 533
            CAST ::temp119 ::temp115 ;@line 533
            ASSIGN merchantFaction ::temp119 ;@line 533
            CAST ::temp119 None ;@line 534
            COMPAREEQ ::temp113 merchantFaction ::temp119 ;@line 534
            JUMPF ::temp113 label167 ;@line 534
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 5 "JobMerchantFaction form is missing" True False False False writeTrace ;@line 535
            RETURN none ;@line 536
            JUMP label165
            label167:
            CALLMETHOD IsInFaction candidate ::temp114 merchantFaction ;@line 537
            NOT ::temp114 ::temp114 ;@line 537
            JUMPF ::temp114 label166 ;@line 537
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 5 "target is not in JobMerchantFaction" False True False False writeTrace ;@line 538
            RETURN none ;@line 539
            JUMP label165
            label166:
            label165:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 5 "JobMerchantFaction PASS" False False False False writeTrace ;@line 541
            CALLSTATIC quest GetQuest ::temp120 "MME_MilkQUEST" ;@line 543
            CAST ::temp121 ::temp120 ;@line 543
            ASSIGN milkController ::temp121 ;@line 543
            CALLSTATIC game GetPlayer ::temp117  ;@line 544
            ASSIGN playerActor ::temp117 ;@line 544
            CAST ::temp121 None ;@line 545
            COMPAREEQ ::temp114 milkController ::temp121 ;@line 545
            CAST ::temp114 ::temp114 ;@line 545
            JUMPT ::temp114 label169 ;@line 545
            CAST ::temp117 None ;@line 545
            COMPAREEQ ::temp113 playerActor ::temp117 ;@line 545
            CAST ::temp114 ::temp113 ;@line 545
            label169:
            CAST ::temp114 ::temp114 ;@line 545
            JUMPT ::temp114 label170 ;@line 545
            PROPGET MilkMaidFaction milkController ::temp119 ;@line 545
            CAST ::temp122 None ;@line 545
            COMPAREEQ ::temp113 ::temp119 ::temp122 ;@line 545
            CAST ::temp114 ::temp113 ;@line 545
            label170:
            CAST ::temp114 ::temp114 ;@line 545
            JUMPT ::temp114 label171 ;@line 545
            PROPGET MilkSlaveFaction milkController ::temp122 ;@line 545
            CAST ::temp119 None ;@line 545
            COMPAREEQ ::temp113 ::temp122 ::temp119 ;@line 545
            CAST ::temp114 ::temp113 ;@line 545
            label171:
            JUMPF ::temp114 label172 ;@line 545
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 6 "MME controller/player/faction properties unavailable" True False False False writeTrace ;@line 546
            RETURN none ;@line 547
            JUMP label168
            label172:
            label168:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 6 "MME controller and faction properties PASS" False False False False writeTrace ;@line 549
            PROPGET MilkMaidFaction milkController ::temp119 ;@line 551
            CALLMETHOD IsInFaction playerActor ::temp113 ::temp119 ;@line 551
            NOT ::temp114 ::temp113 ;@line 551
            JUMPF ::temp114 label174 ;@line 551
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 7 "player is not in MME MilkMaidFaction" False True False False writeTrace ;@line 552
            RETURN none ;@line 553
            JUMP label173
            label174:
            label173:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 7 "player Milk Maid PASS" False False False False writeTrace ;@line 555
            PROPGET MilkSlaveFaction milkController ::temp122 ;@line 557
            CALLMETHOD IsInFaction playerActor ::temp113 ::temp122 ;@line 557
            JUMPF ::temp113 label176 ;@line 557
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 8 "player is an MME Milk Slave" False True False False writeTrace ;@line 558
            RETURN none ;@line 559
            JUMP label175
            label176:
            label175:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 8 "player non-Slave PASS" False False False False writeTrace ;@line 561
            CALLSTATIC armor GetMaskForSlot ::temp123 32 ;@line 563
            CALLMETHOD GetWornForm playerActor ::temp115 ::temp123 ;@line 563
            CAST ::temp124 ::temp115 ;@line 563
            ASSIGN wornArmor ::temp124 ;@line 563
            CAST ::temp124 None ;@line 564
            COMPAREEQ ::temp114 wornArmor ::temp124 ;@line 564
            JUMPF ::temp114 label178 ;@line 564
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 9 "no slot-32 armor is equipped" False True False False writeTrace ;@line 565
            RETURN none ;@line 566
            JUMP label177
            label178:
            label177:
            CALLMETHOD GetName wornArmor ::temp118  ;@line 568
            STRCAT ::temp118 "slot-32 armor=" ::temp118 ;@line 568
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 9 ::temp118 False False False False writeTrace ;@line 568
            CALLMETHOD GetName wornArmor ::temp118  ;@line 570
            ASSIGN armorName ::temp118 ;@line 570
            COMPAREEQ ::temp113 armorName "" ;@line 571
            CAST ::temp113 ::temp113 ;@line 571
            JUMPT ::temp113 label180 ;@line 571
            COMPAREEQ ::temp114 armorName "Empty" ;@line 571
            CAST ::temp113 ::temp114 ;@line 571
            label180:
            CAST ::temp113 ::temp113 ;@line 571
            JUMPT ::temp113 label181 ;@line 571
            COMPAREEQ ::temp114 armorName "empty" ;@line 571
            CAST ::temp113 ::temp114 ;@line 571
            label181:
            JUMPF ::temp113 label182 ;@line 571
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 10 "armor has an unusable display name" False True False False writeTrace ;@line 572
            RETURN none ;@line 573
            JUMP label179
            label182:
            label179:
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 10 "armor identity PASS" False False False False writeTrace ;@line 575
            CALLSTATIC mmearmorscript IsParasiteLivingArmorRegistrySafeForManagement ::temp114 milkController ;@line 577
            NOT ::temp113 ::temp114 ;@line 577
            JUMPF ::temp113 label184 ;@line 577
            PROPGET ParasiteLivingArmor milkController ::temp125 ;@line 578
            ARRAYLENGTH ::temp123 ::temp125 ;@line 578
            CAST ::temp118 ::temp123 ;@line 578
            STRCAT ::temp118 "ParasiteLivingArmor length=" ::temp118 ;@line 578
            STRCAT ::temp118 ::temp118 "; OG requires at least 5" ;@line 578
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 11 ::temp118 True False False False writeTrace ;@line 578
            RETURN none ;@line 579
            JUMP label183
            label184:
            label183:
            CALLSTATIC mmearmorscript GetMMEProtectedForParasiteLivingArmorReason ::temp118 milkController wornArmor ;@line 581
            ASSIGN protectedReason ::temp118 ;@line 581
            COMPAREEQ ::temp114 protectedReason "" ;@line 582
            NOT ::temp114 ::temp114 ;@line 582
            JUMPF ::temp114 label186 ;@line 582
            STRCAT ::temp118 "protected armor: " protectedReason ;@line 583
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 11 ::temp118 False True False False writeTrace ;@line 583
            RETURN none ;@line 584
            JUMP label185
            label186:
            label185:
            CALLSTATIC mmearmorscript CountParasiteLivingArmorMatchesDirect ::temp123 milkController armorName ;@line 586
            ASSIGN matches ::temp123 ;@line 586
            ASSIGN expectedState 0 ;@line 587
            ASSIGN expectedRoute "" ;@line 588
            COMPAREEQ ::temp113 matches 1 ;@line 589
            JUMPF ::temp113 label191 ;@line 589
            ASSIGN expectedState 2 ;@line 590
            ASSIGN expectedRoute "REMOVE" ;@line 591
            JUMP label187
            label191:
            COMPAREEQ ::temp114 matches 0 ;@line 592
            CAST ::temp114 ::temp114 ;@line 592
            JUMPF ::temp114 label188 ;@line 592
            CALLSTATIC mmearmorscript FindParasiteLivingArmorEmptySlotDirect ::temp123 milkController ;@line 592
            COMPAREGTE ::temp126 ::temp123 0 ;@line 592
            CAST ::temp114 ::temp126 ;@line 592
            label188:
            JUMPF ::temp114 label189 ;@line 592
            ASSIGN expectedState 1 ;@line 593
            ASSIGN expectedRoute "ADD" ;@line 594
            JUMP label187
            label189:
            COMPAREEQ ::temp126 matches 0 ;@line 595
            JUMPF ::temp126 label190 ;@line 595
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 11 "ParasiteLivingArmor is full" False True False False writeTrace ;@line 596
            RETURN none ;@line 597
            JUMP label187
            label190:
            CAST ::temp118 matches ;@line 599
            STRCAT ::temp118 "registration match count is invalid: " ::temp118 ;@line 599
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 11 ::temp118 True False False False writeTrace ;@line 599
            RETURN none ;@line 600
            label187:
            STRCAT ::temp118 "preflight expects " expectedRoute ;@line 602
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 11 ::temp118 False False False False writeTrace ;@line 602
            NOT ::temp114 openingObserved ;@line 604
            JUMPF ::temp114 label193 ;@line 604
            STRCAT ::temp118 "preflight expects " expectedRoute ;@line 605
            STRCAT ::temp118 ::temp118 "; open [MME] Hey there! with live trace enabled" ;@line 605
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 11 ::temp118 False False True False writeTrace ;@line 605
            RETURN none ;@line 606
            JUMP label192
            label193:
            label192:
            CALLMETHOD GetValue stateGlobal ::temp127  ;@line 608
            CAST ::temp123 ::temp127 ;@line 608
            ASSIGN publishedState ::temp123 ;@line 608
            COMPAREEQ ::temp126 publishedState expectedState ;@line 609
            NOT ::temp126 ::temp126 ;@line 609
            JUMPF ::temp126 label195 ;@line 609
            CAST ::temp118 expectedState ;@line 610
            STRCAT ::temp118 "opening state mismatch: expected " ::temp118 ;@line 610
            STRCAT ::temp118 ::temp118 " (" ;@line 610
            STRCAT ::temp118 ::temp118 expectedRoute ;@line 610
            STRCAT ::temp118 ::temp118 ") got " ;@line 610
            CAST ::temp128 publishedState ;@line 610
            STRCAT ::temp128 ::temp118 ::temp128 ;@line 610
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 12 ::temp128 True False False False writeTrace ;@line 610
            RETURN none ;@line 611
            JUMP label194
            label195:
            label194:
            CAST ::temp118 publishedState ;@line 613
            STRCAT ::temp128 "opening state=" ::temp118 ;@line 613
            STRCAT ::temp118 ::temp128 " (" ;@line 613
            STRCAT ::temp128 ::temp118 expectedRoute ;@line 613
            STRCAT ::temp118 ::temp128 ") PASS" ;@line 613
            CALLMETHOD RecordMageDialogueBusStop service ::nonevar 12 ::temp118 False False False False writeTrace ;@line 613
          .endCode
        .endFunction
        .function RefreshNewMilkMaidSexLabBus static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp129 mmedebug
            .local ::temp130 bool
            .local ::temp131 form
            .local ::temp132 mmealertscontroller
            .local service MMEDebug
            .local ::nonevar none
            .local controller MMEAlertsController
            .local ::temp133 bool
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp129  ;@line 618
            ASSIGN service ::temp129 ;@line 618
            CAST ::temp129 None ;@line 619
            COMPAREEQ ::temp130 service ::temp129 ;@line 619
            JUMPF ::temp130 label197 ;@line 619
            CALLSTATIC mmediagnostics Report ::nonevar "SexLab bus FAIL: persistent service is missing" 2 ;@line 620
            RETURN none ;@line 621
            JUMP label196
            label197:
            label196:
            CALLMETHOD EnsureNewMilkMaidSexLabListeners service ::nonevar True ;@line 623
            CALLSTATIC game GetFormFromFile ::temp131 2048 "MMEAlert.esp" ;@line 624
            CAST ::temp132 ::temp131 ;@line 624
            ASSIGN controller ::temp132 ;@line 624
            CAST ::temp132 None ;@line 625
            COMPAREEQ ::temp130 controller ::temp132 ;@line 625
            NOT ::temp130 ::temp130 ;@line 625
            JUMPF ::temp130 label199 ;@line 625
            CALLMETHOD RefreshMMESexLabAnimationGate controller ::temp133 "manual New Milk Maid bus" ;@line 626
            JUMP label198
            label199:
            label198:
          .endCode
        .endFunction
        .function ShowNewMilkMaidSexLabBusReport static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp134 mmedebug
            .local ::temp135 bool
            .local service MMEDebug
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp134  ;@line 631
            ASSIGN service ::temp134 ;@line 631
            CAST ::temp134 None ;@line 632
            COMPAREEQ ::temp135 service ::temp134 ;@line 632
            JUMPF ::temp135 label201 ;@line 632
            CALLSTATIC mmediagnostics Report ::nonevar "SexLab bus FAIL: persistent service is missing" 2 ;@line 633
            RETURN none ;@line 634
            JUMP label200
            label201:
            label200:
            CALLMETHOD ShowNewMilkMaidSexLabBusReport service ::nonevar  ;@line 636
          .endCode
        .endFunction
        .function RefreshDialogueGate static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp136 form
            .local ::temp137 mmealertscontroller
            .local ::temp138 bool
            .local ::temp139 string
            .local controller MMEAlertsController
            .local ::nonevar none
            .local gateStatus String
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp136 2048 "MMEAlert.esp" ;@line 640
            CAST ::temp137 ::temp136 ;@line 640
            ASSIGN controller ::temp137 ;@line 640
            CAST ::temp137 None ;@line 641
            COMPAREEQ ::temp138 controller ::temp137 ;@line 641
            JUMPF ::temp138 label203 ;@line 641
            CALLSTATIC mmediagnostics Report ::nonevar "FAIL: controller quest is missing" 2 ;@line 642
            RETURN none ;@line 643
            JUMP label202
            label203:
            label202:
            CALLMETHOD RefreshOStimDialogueAvailability controller ::nonevar  ;@line 645
            CALLSTATIC mmediagnostics GetGateStatus ::temp139  ;@line 646
            ASSIGN gateStatus ::temp139 ;@line 646
            COMPAREEQ ::temp138 gateStatus "ON" ;@line 647
            JUMPF ::temp138 label205 ;@line 647
            CALLSTATIC mmediagnostics Report ::nonevar "PASS: OStim dialogue gate refreshed ON" 0 ;@line 648
            JUMP label204
            label205:
            STRCAT ::temp139 "FAIL: OStim dialogue gate refreshed " gateStatus ;@line 650
            CALLSTATIC mmediagnostics Report ::nonevar ::temp139 2 ;@line 650
            label204:
          .endCode
        .endFunction
        .function RunInstallAudit static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp140 form
            .local ::temp141 form
            .local ::temp142 bool
            .local ::temp143 bool
            .local ::temp144 quest
            .local ::temp145 quest
            .local ::temp146 int
            .local ::temp147 string
            .local ::temp148 string
            .local ::nonevar none
            .local controllerReady Bool
            .local gateReady Bool
            .local newMaidGateReady Bool
            .local vendorGatesReady Bool
            .local mmeReady Bool
            .local ostimReady Bool
            .local settingReady Bool
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp140 2048 "MMEAlert.esp" ;@line 655
            CAST ::temp141 None ;@line 655
            COMPAREEQ ::temp142 ::temp140 ::temp141 ;@line 655
            NOT ::temp142 ::temp142 ;@line 655
            ASSIGN controllerReady ::temp142 ;@line 655
            CALLSTATIC game GetFormFromFile ::temp141 2138 "MMEAlert.esp" ;@line 656
            CAST ::temp140 None ;@line 656
            COMPAREEQ ::temp142 ::temp141 ::temp140 ;@line 656
            NOT ::temp142 ::temp142 ;@line 656
            ASSIGN gateReady ::temp142 ;@line 656
            CALLSTATIC game GetFormFromFile ::temp140 2173 "MMEAlert.esp" ;@line 657
            CAST ::temp141 None ;@line 657
            COMPAREEQ ::temp142 ::temp140 ::temp141 ;@line 657
            NOT ::temp142 ::temp142 ;@line 657
            ASSIGN newMaidGateReady ::temp142 ;@line 657
            CALLSTATIC game GetFormFromFile ::temp141 2177 "MMEAlert.esp" ;@line 658
            CAST ::temp140 None ;@line 658
            COMPAREEQ ::temp142 ::temp141 ::temp140 ;@line 658
            NOT ::temp142 ::temp142 ;@line 658
            CAST ::temp142 ::temp142 ;@line 658
            JUMPF ::temp142 label206 ;@line 658
            CALLSTATIC game GetFormFromFile ::temp140 2182 "MMEAlert.esp" ;@line 658
            CAST ::temp141 None ;@line 658
            COMPAREEQ ::temp143 ::temp140 ::temp141 ;@line 658
            NOT ::temp143 ::temp143 ;@line 658
            CAST ::temp142 ::temp143 ;@line 658
            label206:
            CAST ::temp142 ::temp142 ;@line 658
            JUMPF ::temp142 label207 ;@line 658
            CALLSTATIC game GetFormFromFile ::temp141 2187 "MMEAlert.esp" ;@line 658
            CAST ::temp140 None ;@line 658
            COMPAREEQ ::temp143 ::temp141 ::temp140 ;@line 658
            NOT ::temp143 ::temp143 ;@line 658
            CAST ::temp142 ::temp143 ;@line 658
            label207:
            ASSIGN vendorGatesReady ::temp142 ;@line 658
            CALLSTATIC quest GetQuest ::temp144 "MME_MilkQUEST" ;@line 659
            CAST ::temp145 None ;@line 659
            COMPAREEQ ::temp143 ::temp144 ::temp145 ;@line 659
            NOT ::temp143 ::temp143 ;@line 659
            ASSIGN mmeReady ::temp143 ;@line 659
            CALLSTATIC mmeostimbreastfeeding IsOStimDetected ::temp142  ;@line 660
            ASSIGN ostimReady ::temp142 ;@line 660
            CALLSTATIC jsonutil GetIntValue ::temp146 "/MMEAlerts/Settings" "enableOStimBreastfeeding" 0 ;@line 661
            COMPAREEQ ::temp143 ::temp146 1 ;@line 661
            ASSIGN settingReady ::temp143 ;@line 661
            CALLSTATIC mmediagnostics YesNo ::temp147 controllerReady ;@line 663
            STRCAT ::temp147 "Install: controller=" ::temp147 ;@line 663
            STRCAT ::temp147 ::temp147 " MME=" ;@line 663
            CALLSTATIC mmediagnostics YesNo ::temp148 mmeReady ;@line 663
            STRCAT ::temp147 ::temp147 ::temp148 ;@line 663
            STRCAT ::temp148 ::temp147 " OStim=" ;@line 663
            CALLSTATIC mmediagnostics YesNo ::temp147 ostimReady ;@line 663
            STRCAT ::temp148 ::temp148 ::temp147 ;@line 663
            CALLSTATIC mmediagnostics Report ::nonevar ::temp148 0 ;@line 663
            CALLSTATIC mmediagnostics YesNo ::temp147 gateReady ;@line 664
            STRCAT ::temp148 "Script-visible records: OStim gate=" ::temp147 ;@line 664
            STRCAT ::temp147 ::temp148 " New Milk Maid gate=" ;@line 664
            CALLSTATIC mmediagnostics YesNo ::temp148 newMaidGateReady ;@line 664
            STRCAT ::temp147 ::temp147 ::temp148 ;@line 664
            STRCAT ::temp148 ::temp147 " vendor gates=" ;@line 664
            CALLSTATIC mmediagnostics YesNo ::temp147 vendorGatesReady ;@line 664
            STRCAT ::temp148 ::temp148 ::temp147 ;@line 664
            CALLSTATIC mmediagnostics Report ::nonevar ::temp148 0 ;@line 664
            CALLSTATIC mmediagnostics Report ::nonevar "Dialogue DIAL/INFO structure: verified when this package was built" 0 ;@line 665
            CALLSTATIC mmediagnostics YesNo ::temp147 settingReady ;@line 666
            STRCAT ::temp148 "Runtime: setting=" ::temp147 ;@line 666
            STRCAT ::temp147 ::temp148 " dialogue gate=" ;@line 666
            CALLSTATIC mmediagnostics GetGateStatus ::temp148  ;@line 666
            STRCAT ::temp147 ::temp147 ::temp148 ;@line 666
            CALLSTATIC mmediagnostics Report ::nonevar ::temp147 0 ;@line 666
            CAST ::temp142 controllerReady ;@line 667
            JUMPF ::temp142 label209 ;@line 667
            CAST ::temp142 gateReady ;@line 667
            label209:
            CAST ::temp143 ::temp142 ;@line 667
            JUMPF ::temp143 label210 ;@line 667
            CAST ::temp143 newMaidGateReady ;@line 667
            label210:
            CAST ::temp142 ::temp143 ;@line 667
            JUMPF ::temp142 label211 ;@line 667
            CAST ::temp142 vendorGatesReady ;@line 667
            label211:
            CAST ::temp143 ::temp142 ;@line 667
            JUMPF ::temp143 label212 ;@line 667
            CAST ::temp143 mmeReady ;@line 667
            label212:
            CAST ::temp142 ::temp143 ;@line 667
            JUMPF ::temp142 label213 ;@line 667
            CAST ::temp142 ostimReady ;@line 667
            label213:
            CAST ::temp143 ::temp142 ;@line 667
            JUMPF ::temp143 label214 ;@line 667
            CAST ::temp143 settingReady ;@line 667
            label214:
            CAST ::temp143 ::temp143 ;@line 667
            JUMPF ::temp143 label215 ;@line 667
            CALLSTATIC mmediagnostics GetGateStatus ::temp148  ;@line 667
            COMPAREEQ ::temp142 ::temp148 "ON" ;@line 667
            CAST ::temp143 ::temp142 ;@line 667
            label215:
            JUMPF ::temp143 label216 ;@line 667
            CALLSTATIC mmediagnostics Report ::nonevar "PASS: installed dialogue runtime is ready" 0 ;@line 668
            JUMP label208
            label216:
            CALLSTATIC mmediagnostics Report ::nonevar "FAIL: install/runtime audit found a blocker" 2 ;@line 670
            label208:
          .endCode
        .endFunction
        .function RunMilkDrinkAudit static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp149 form
            .local ::temp150 quest
            .local ::temp151 bool
            .local ::temp152 alias
            .local ::temp153 referencealias
            .local ::temp154 actor
            .local ::temp155 mmedrinktracker
            .local ::temp156 int
            .local ::temp157 string
            .local ::temp158 string
            .local ::temp159 formlist
            .local ::temp160 bool
            .local ::temp161 float
            .local controllerQuest Quest
            .local ::nonevar none
            .local playerAlias ReferenceAlias
            .local aliasActor Actor
            .local tracker MMEDrinkTracker
            .local masterEnabled Bool
            .local debugEnabled Bool
            .local lactacid Form
            .local hearthfireMilk Form
            .local mmeMilks FormList
            .local formsReady Bool
            .local lastEventTime Float
            .local lastAcceptedTime Float
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp149 2048 "MMEAlert.esp" ;@line 677
            CAST ::temp150 ::temp149 ;@line 677
            ASSIGN controllerQuest ::temp150 ;@line 677
            CAST ::temp150 None ;@line 678
            COMPAREEQ ::temp151 controllerQuest ::temp150 ;@line 678
            JUMPF ::temp151 label218 ;@line 678
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 1 FAIL: MMEAlertDebugQuest is missing" 2 ;@line 679
            RETURN none ;@line 680
            JUMP label217
            label218:
            label217:
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 1 PASS: controller quest resolved" 0 ;@line 682
            CALLMETHOD GetAlias controllerQuest ::temp152 1 ;@line 684
            CAST ::temp153 ::temp152 ;@line 684
            ASSIGN playerAlias ::temp153 ;@line 684
            CAST ::temp153 None ;@line 685
            COMPAREEQ ::temp151 playerAlias ::temp153 ;@line 685
            JUMPF ::temp151 label220 ;@line 685
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 2 FAIL: player alias ID 1 is missing" 2 ;@line 686
            RETURN none ;@line 687
            JUMP label219
            label220:
            label219:
            CALLMETHOD GetActorReference playerAlias ::temp154  ;@line 689
            ASSIGN aliasActor ::temp154 ;@line 689
            CALLSTATIC game GetPlayer ::temp154  ;@line 690
            COMPAREEQ ::temp151 aliasActor ::temp154 ;@line 690
            NOT ::temp151 ::temp151 ;@line 690
            JUMPF ::temp151 label222 ;@line 690
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 3 FAIL: alias ID 1 is not filled by the player" 2 ;@line 691
            RETURN none ;@line 692
            JUMP label221
            label222:
            label221:
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 2-3 PASS: alias ID 1 contains the player" 0 ;@line 694
            CAST ::temp155 playerAlias ;@line 696
            ASSIGN tracker ::temp155 ;@line 696
            CAST ::temp155 None ;@line 697
            COMPAREEQ ::temp151 tracker ::temp155 ;@line 697
            JUMPF ::temp151 label224 ;@line 697
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 4 FAIL: MMEDrinkTracker is not attached to alias ID 1" 2 ;@line 698
            RETURN none ;@line 699
            JUMP label223
            label224:
            label223:
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 4 PASS: MMEDrinkTracker is attached" 0 ;@line 701
            CALLSTATIC mmealertscontroller IsExtensionsEnabled ::temp151  ;@line 703
            ASSIGN masterEnabled ::temp151 ;@line 703
            CALLSTATIC jsonutil GetIntValue ::temp156 "/MMEAlerts/Settings" "enableAddMilkDebug" 0 ;@line 704
            COMPAREEQ ::temp151 ::temp156 1 ;@line 704
            ASSIGN debugEnabled ::temp151 ;@line 704
            CALLSTATIC mmediagnostics YesNo ::temp157 masterEnabled ;@line 705
            STRCAT ::temp157 "Drink stop 5: extensions=" ::temp157 ;@line 705
            STRCAT ::temp157 ::temp157 " diagnostics=" ;@line 705
            CALLSTATIC mmediagnostics YesNo ::temp158 debugEnabled ;@line 705
            STRCAT ::temp157 ::temp157 ::temp158 ;@line 705
            CALLSTATIC mmediagnostics Report ::nonevar ::temp157 0 ;@line 705
            CALLSTATIC game GetFormFromFile ::temp149 214002 "MilkModNEW.esp" ;@line 707
            ASSIGN lactacid ::temp149 ;@line 707
            CALLSTATIC game GetFormFromFile ::temp149 13620 "HearthFires.esm" ;@line 708
            ASSIGN hearthfireMilk ::temp149 ;@line 708
            CALLSTATIC game GetFormFromFile ::temp149 378908 "MilkModNEW.esp" ;@line 709
            CAST ::temp159 ::temp149 ;@line 709
            ASSIGN mmeMilks ::temp159 ;@line 709
            CAST ::temp149 None ;@line 710
            COMPAREEQ ::temp151 lactacid ::temp149 ;@line 710
            NOT ::temp151 ::temp151 ;@line 710
            CAST ::temp151 ::temp151 ;@line 710
            JUMPF ::temp151 label225 ;@line 710
            CAST ::temp149 None ;@line 710
            COMPAREEQ ::temp160 hearthfireMilk ::temp149 ;@line 710
            NOT ::temp160 ::temp160 ;@line 710
            CAST ::temp151 ::temp160 ;@line 710
            label225:
            CAST ::temp151 ::temp151 ;@line 710
            JUMPF ::temp151 label226 ;@line 710
            CAST ::temp159 None ;@line 710
            COMPAREEQ ::temp160 mmeMilks ::temp159 ;@line 710
            NOT ::temp160 ::temp160 ;@line 710
            CAST ::temp151 ::temp160 ;@line 710
            label226:
            ASSIGN formsReady ::temp151 ;@line 710
            CAST ::temp149 None ;@line 711
            COMPAREEQ ::temp160 lactacid ::temp149 ;@line 711
            NOT ::temp160 ::temp160 ;@line 711
            CALLSTATIC mmediagnostics YesNo ::temp158 ::temp160 ;@line 711
            STRCAT ::temp157 "Drink stop 6: Lactacid=" ::temp158 ;@line 711
            STRCAT ::temp158 ::temp157 " HearthFires milk=" ;@line 711
            CAST ::temp149 None ;@line 711
            COMPAREEQ ::temp151 hearthfireMilk ::temp149 ;@line 711
            NOT ::temp151 ::temp151 ;@line 711
            CALLSTATIC mmediagnostics YesNo ::temp157 ::temp151 ;@line 711
            STRCAT ::temp158 ::temp158 ::temp157 ;@line 711
            STRCAT ::temp157 ::temp158 " MME milk list=" ;@line 711
            CAST ::temp159 None ;@line 711
            COMPAREEQ ::temp160 mmeMilks ::temp159 ;@line 711
            NOT ::temp160 ::temp160 ;@line 711
            CALLSTATIC mmediagnostics YesNo ::temp158 ::temp160 ;@line 711
            STRCAT ::temp157 ::temp157 ::temp158 ;@line 711
            CALLSTATIC mmediagnostics Report ::nonevar ::temp157 0 ;@line 711
            NOT ::temp151 formsReady ;@line 712
            JUMPF ::temp151 label228 ;@line 712
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 6 FAIL: supported milk forms did not resolve" 2 ;@line 713
            RETURN none ;@line 714
            JUMP label227
            label228:
            label227:
            CAST ::temp149 None ;@line 717
            CALLSTATIC storageutil GetFloatValue ::temp161 ::temp149 "MMEExtensions.PlayerDrink.LastAliasEventTime" -1.0 ;@line 717
            ASSIGN lastEventTime ::temp161 ;@line 717
            CAST ::temp149 None ;@line 718
            CALLSTATIC storageutil GetFloatValue ::temp161 ::temp149 "MMEExtensions.PlayerDrink.LastAcceptedTime" -1.0 ;@line 718
            ASSIGN lastAcceptedTime ::temp161 ;@line 718
            COMPARELT ::temp160 lastEventTime 0.0 ;@line 719
            JUMPF ::temp160 label230 ;@line 719
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 7 WAITING: no player equip event observed yet" 0 ;@line 720
            JUMP label229
            label230:
            CALLSTATIC utility GetCurrentRealTime ::temp161  ;@line 722
            FSUBTRACT ::temp161 ::temp161 lastEventTime ;@line 722
            CAST ::temp158 ::temp161 ;@line 722
            STRCAT ::temp157 "Drink stop 7 PASS: equip event observed " ::temp158 ;@line 722
            STRCAT ::temp158 ::temp157 " seconds ago; form=" ;@line 722
            CAST ::temp149 None ;@line 722
            CALLSTATIC storageutil GetIntValue ::temp156 ::temp149 "MMEExtensions.PlayerDrink.LastAliasEventForm" 0 ;@line 722
            CAST ::temp157 ::temp156 ;@line 722
            STRCAT ::temp157 ::temp158 ::temp157 ;@line 722
            CALLSTATIC mmediagnostics Report ::nonevar ::temp157 0 ;@line 722
            label229:
            COMPARELT ::temp151 lastAcceptedTime 0.0 ;@line 724
            JUMPF ::temp151 label232 ;@line 724
            CALLSTATIC mmediagnostics Report ::nonevar "Drink stop 8 WAITING: no supported milk accepted yet" 0 ;@line 725
            JUMP label231
            label232:
            CALLSTATIC utility GetCurrentRealTime ::temp161  ;@line 727
            FSUBTRACT ::temp161 ::temp161 lastAcceptedTime ;@line 727
            CAST ::temp158 ::temp161 ;@line 727
            STRCAT ::temp157 "Drink stop 8 PASS: milk accepted " ::temp158 ;@line 727
            STRCAT ::temp158 ::temp157 " seconds ago; form=" ;@line 727
            CAST ::temp149 None ;@line 727
            CALLSTATIC storageutil GetIntValue ::temp156 ::temp149 "MMEExtensions.PlayerDrink.LastAcceptedForm" 0 ;@line 727
            CAST ::temp157 ::temp156 ;@line 727
            STRCAT ::temp157 ::temp158 ::temp157 ;@line 727
            CALLSTATIC mmediagnostics Report ::nonevar ::temp157 0 ;@line 727
            label231:
          .endCode
        .endFunction
        .function RunGlobalNPCDrinkTest static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp162 form
            .local ::temp163 quest
            .local ::temp164 bool
            .local ::temp165 alias
            .local ::temp166 referencealias
            .local ::temp167 mmedrinktracker
            .local controllerQuest Quest
            .local ::nonevar none
            .local playerAlias ReferenceAlias
            .local tracker MMEDrinkTracker
          .endLocalTable
          .code
            CALLSTATIC game GetFormFromFile ::temp162 2048 "MMEAlert.esp" ;@line 734
            CAST ::temp163 ::temp162 ;@line 734
            ASSIGN controllerQuest ::temp163 ;@line 734
            CAST ::temp163 None ;@line 735
            COMPAREEQ ::temp164 controllerQuest ::temp163 ;@line 735
            JUMPF ::temp164 label234 ;@line 735
            CALLSTATIC mmediagnostics Report ::nonevar "Global NPC drink test FAIL: controller quest is missing" 2 ;@line 736
            RETURN none ;@line 737
            JUMP label233
            label234:
            label233:
            CALLMETHOD GetAlias controllerQuest ::temp165 1 ;@line 739
            CAST ::temp166 ::temp165 ;@line 739
            ASSIGN playerAlias ::temp166 ;@line 739
            CAST ::temp167 playerAlias ;@line 740
            ASSIGN tracker ::temp167 ;@line 740
            CAST ::temp167 None ;@line 741
            COMPAREEQ ::temp164 tracker ::temp167 ;@line 741
            JUMPF ::temp164 label236 ;@line 741
            CALLSTATIC mmediagnostics Report ::nonevar "Global NPC drink test FAIL: MMEDrinkTracker is not attached to player alias ID 1" 2 ;@line 742
            RETURN none ;@line 743
            JUMP label235
            label236:
            label235:
            CALLMETHOD RunCrosshairNPCDrinkTest tracker ::nonevar  ;@line 745
          .endCode
        .endFunction
        .function RunCrosshairDialogueAudit static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp168 objectreference
            .local ::temp169 actor
            .local ::temp170 quest
            .local ::temp171 milkquest
            .local ::temp172 bool
            .local ::temp173 bool
            .local ::temp174 form
            .local ::temp175 faction
            .local ::temp176 faction
            .local ::temp177 milkquest_conditions
            .local ::temp178 milkquest_conditions
            .local ::temp180 float
            .local ::temp181 string
            .local ::temp182 string
            .local candidate Actor
            .local playerActor Actor
            .local milkController MilkQUEST
            .local ::nonevar none
            .local playerMaid Bool
            .local candidateMaid Bool
            .local candidateSlave Bool
            .local candidateStorage Bool
            .local candidateMaidFaction Bool
            .local candidateSlaveFaction Bool
            .local cachedSubjectMaid Bool
            .local cachedSubjectSlave Bool
            .local cachedFreeSlots Int
            .local ::temp179 int
            .local candidateAvailable Bool
            .local playerMilk Float
            .local candidateMilk Float
            .local playerSourceValid Bool
            .local candidateSourceValid Bool
            .local gateOpen Bool
            .local ostimPlayerDrinksEligible Bool
            .local ostimNPCDrinksEligible Bool
            .local blocker String
          .endLocalTable
          .code
            CALLSTATIC game GetCurrentCrosshairRef ::temp168  ;@line 749
            CAST ::temp169 ::temp168 ;@line 749
            ASSIGN candidate ::temp169 ;@line 749
            CALLSTATIC game GetPlayer ::temp169  ;@line 750
            ASSIGN playerActor ::temp169 ;@line 750
            CALLSTATIC quest GetQuest ::temp170 "MME_MilkQUEST" ;@line 751
            CAST ::temp171 ::temp170 ;@line 751
            ASSIGN milkController ::temp171 ;@line 751
            CAST ::temp169 None ;@line 752
            COMPAREEQ ::temp172 candidate ::temp169 ;@line 752
            JUMPF ::temp172 label238 ;@line 752
            CALLSTATIC mmediagnostics Report ::nonevar "FAIL: no NPC under the crosshair" 2 ;@line 753
            CALLSTATIC mmediagnostics Report ::nonevar "Close MCM, aim at the NPC, reopen, then run this audit" 0 ;@line 754
            RETURN none ;@line 755
            JUMP label237
            label238:
            label237:
            CAST ::temp169 None ;@line 757
            COMPAREEQ ::temp172 playerActor ::temp169 ;@line 757
            CAST ::temp172 ::temp172 ;@line 757
            JUMPT ::temp172 label240 ;@line 757
            CAST ::temp171 None ;@line 757
            COMPAREEQ ::temp173 milkController ::temp171 ;@line 757
            CAST ::temp172 ::temp173 ;@line 757
            label240:
            JUMPF ::temp172 label241 ;@line 757
            CALLSTATIC mmediagnostics Report ::nonevar "FAIL: player or MME controller is unavailable" 2 ;@line 758
            RETURN none ;@line 759
            JUMP label239
            label241:
            label239:
            CALLSTATIC mmearmorscript IsMMEMilkMaid ::temp173 playerActor milkController ;@line 765
            ASSIGN playerMaid ::temp173 ;@line 765
            CALLSTATIC mmearmorscript IsMMEMilkMaid ::temp172 candidate milkController ;@line 766
            ASSIGN candidateMaid ::temp172 ;@line 766
            CALLSTATIC mmearmorscript IsMMEMilkSlave ::temp173 candidate milkController ;@line 767
            ASSIGN candidateSlave ::temp173 ;@line 767
            CAST ::temp174 candidate ;@line 768
            CALLSTATIC storageutil HasFloatValue ::temp172 ::temp174 "MME.MilkMaid.Level" ;@line 768
            ASSIGN candidateStorage ::temp172 ;@line 768
            PROPGET MilkMaidFaction milkController ::temp175 ;@line 769
            CAST ::temp176 None ;@line 769
            COMPAREEQ ::temp173 ::temp175 ::temp176 ;@line 769
            NOT ::temp173 ::temp173 ;@line 769
            CAST ::temp173 ::temp173 ;@line 769
            JUMPF ::temp173 label242 ;@line 769
            PROPGET MilkMaidFaction milkController ::temp176 ;@line 769
            CALLMETHOD IsInFaction candidate ::temp172 ::temp176 ;@line 769
            CAST ::temp173 ::temp172 ;@line 769
            label242:
            ASSIGN candidateMaidFaction ::temp173 ;@line 769
            PROPGET MilkSlaveFaction milkController ::temp175 ;@line 770
            CAST ::temp176 None ;@line 770
            COMPAREEQ ::temp172 ::temp175 ::temp176 ;@line 770
            NOT ::temp172 ::temp172 ;@line 770
            CAST ::temp172 ::temp172 ;@line 770
            JUMPF ::temp172 label243 ;@line 770
            PROPGET MilkSlaveFaction milkController ::temp176 ;@line 770
            CALLMETHOD IsInFaction candidate ::temp173 ::temp176 ;@line 770
            CAST ::temp172 ::temp173 ;@line 770
            label243:
            ASSIGN candidateSlaveFaction ::temp172 ;@line 770
            PROPGET MilkQC milkController ::temp177 ;@line 771
            CAST ::temp178 None ;@line 771
            COMPAREEQ ::temp173 ::temp177 ::temp178 ;@line 771
            NOT ::temp173 ::temp173 ;@line 771
            CAST ::temp173 ::temp173 ;@line 771
            JUMPF ::temp173 label244 ;@line 771
            PROPGET MilkQC milkController ::temp178 ;@line 771
            PROPGET MME_SubjectMaid ::temp178 ::temp172 ;@line 771
            CAST ::temp173 ::temp172 ;@line 771
            label244:
            ASSIGN cachedSubjectMaid ::temp173 ;@line 771
            PROPGET MilkQC milkController ::temp177 ;@line 772
            CAST ::temp178 None ;@line 772
            COMPAREEQ ::temp172 ::temp177 ::temp178 ;@line 772
            NOT ::temp172 ::temp172 ;@line 772
            CAST ::temp172 ::temp172 ;@line 772
            JUMPF ::temp172 label245 ;@line 772
            PROPGET MilkQC milkController ::temp178 ;@line 772
            PROPGET MME_SubjectSlave ::temp178 ::temp173 ;@line 772
            CAST ::temp172 ::temp173 ;@line 772
            label245:
            ASSIGN cachedSubjectSlave ::temp172 ;@line 772
            ASSIGN cachedFreeSlots -1 ;@line 773
            PROPGET MilkQC milkController ::temp177 ;@line 774
            CAST ::temp178 None ;@line 774
            COMPAREEQ ::temp173 ::temp177 ::temp178 ;@line 774
            NOT ::temp173 ::temp173 ;@line 774
            JUMPF ::temp173 label247 ;@line 774
            PROPGET MilkQC milkController ::temp178 ;@line 775
            PROPGET MME_FreeMaidSlots ::temp178 ::temp179 ;@line 775
            ASSIGN cachedFreeSlots ::temp179 ;@line 775
            JUMP label246
            label247:
            label246:
            CALLSTATIC mmedebug IsActorAvailable ::temp172 candidate ;@line 777
            ASSIGN candidateAvailable ::temp172 ;@line 777
            CALLSTATIC mme_storage getMilkCurrent ::temp180 playerActor ;@line 778
            ASSIGN playerMilk ::temp180 ;@line 778
            CALLSTATIC mme_storage getMilkCurrent ::temp180 candidate ;@line 779
            ASSIGN candidateMilk ::temp180 ;@line 779
            CALLSTATIC mmeostimbreastfeeding ValidateMilkSource ::temp173 playerActor milkController False ;@line 780
            ASSIGN playerSourceValid ::temp173 ;@line 780
            CALLSTATIC mmeostimbreastfeeding ValidateMilkSource ::temp172 candidate milkController False ;@line 781
            ASSIGN candidateSourceValid ::temp172 ;@line 781
            CALLSTATIC mmediagnostics GetGateStatus ::temp181  ;@line 782
            COMPAREEQ ::temp173 ::temp181 "ON" ;@line 782
            ASSIGN gateOpen ::temp173 ;@line 782
            CAST ::temp172 gateOpen ;@line 783
            JUMPF ::temp172 label248 ;@line 783
            CAST ::temp172 candidateSourceValid ;@line 783
            label248:
            CAST ::temp172 ::temp172 ;@line 783
            JUMPF ::temp172 label249 ;@line 783
            COMPAREGTE ::temp173 candidateMilk 1.0 ;@line 783
            CAST ::temp172 ::temp173 ;@line 783
            label249:
            ASSIGN ostimPlayerDrinksEligible ::temp172 ;@line 783
            CAST ::temp173 gateOpen ;@line 784
            JUMPF ::temp173 label250 ;@line 784
            CAST ::temp173 playerSourceValid ;@line 784
            label250:
            CAST ::temp173 ::temp173 ;@line 784
            JUMPF ::temp173 label251 ;@line 784
            COMPAREGTE ::temp172 playerMilk 1.0 ;@line 784
            CAST ::temp173 ::temp172 ;@line 784
            label251:
            ASSIGN ostimNPCDrinksEligible ::temp173 ;@line 784
            ASSIGN blocker "none" ;@line 785
            NOT ::temp172 gateOpen ;@line 786
            JUMPF ::temp172 label258 ;@line 786
            CALLSTATIC mmediagnostics GetGateStatus ::temp181  ;@line 787
            STRCAT ::temp181 "OStim dialogue gate is " ::temp181 ;@line 787
            ASSIGN blocker ::temp181 ;@line 787
            JUMP label252
            label258:
            NOT ::temp173 playerMaid ;@line 788
            JUMPF ::temp173 label253 ;@line 788
            ASSIGN blocker "player is not an MME Milk Maid" ;@line 789
            JUMP label252
            label253:
            COMPARELT ::temp173 playerMilk 1.0 ;@line 790
            JUMPF ::temp173 label254 ;@line 790
            ASSIGN blocker "player has less than one milk" ;@line 791
            JUMP label252
            label254:
            NOT ::temp173 playerSourceValid ;@line 792
            JUMPF ::temp173 label255 ;@line 792
            ASSIGN blocker "player is not a usable milk source" ;@line 793
            JUMP label252
            label255:
            NOT ::temp173 candidateAvailable ;@line 794
            JUMPF ::temp173 label256 ;@line 794
            ASSIGN blocker "crosshair NPC is dead, disabled, or unloaded" ;@line 795
            JUMP label252
            label256:
            JUMPF candidateMaid label257 ;@line 796
            ASSIGN blocker "crosshair NPC is already a Milk Maid" ;@line 797
            JUMP label252
            label257:
            label252:
            CALLSTATIC mmenewmilkmaid GetActorName ::temp181 candidate ;@line 800
            STRCAT ::temp181 "Target: " ::temp181 ;@line 800
            STRCAT ::temp181 ::temp181 " formID=" ;@line 800
            CALLMETHOD GetFormID candidate ::temp179  ;@line 800
            CAST ::temp182 ::temp179 ;@line 800
            STRCAT ::temp182 ::temp181 ::temp182 ;@line 800
            STRCAT ::temp181 ::temp182 " available=" ;@line 800
            CALLSTATIC mmediagnostics YesNo ::temp182 candidateAvailable ;@line 800
            STRCAT ::temp181 ::temp181 ::temp182 ;@line 800
            CALLSTATIC mmediagnostics Report ::nonevar ::temp181 0 ;@line 800
            CALLSTATIC mmediagnostics YesNo ::temp182 candidateMaid ;@line 801
            STRCAT ::temp181 "Target maid truth: resolved=" ::temp182 ;@line 801
            STRCAT ::temp182 ::temp181 " faction=" ;@line 801
            CALLSTATIC mmediagnostics YesNo ::temp181 candidateMaidFaction ;@line 801
            STRCAT ::temp182 ::temp182 ::temp181 ;@line 801
            STRCAT ::temp181 ::temp182 " storage=" ;@line 801
            CALLSTATIC mmediagnostics YesNo ::temp182 candidateStorage ;@line 801
            STRCAT ::temp181 ::temp181 ::temp182 ;@line 801
            CALLSTATIC mmediagnostics Report ::nonevar ::temp181 0 ;@line 801
            CALLSTATIC mmediagnostics YesNo ::temp182 candidateSlave ;@line 802
            STRCAT ::temp181 "Target slave truth: resolved=" ::temp182 ;@line 802
            STRCAT ::temp182 ::temp181 " faction=" ;@line 802
            CALLSTATIC mmediagnostics YesNo ::temp181 candidateSlaveFaction ;@line 802
            STRCAT ::temp182 ::temp182 ::temp181 ;@line 802
            STRCAT ::temp181 ::temp182 " storageFlag=" ;@line 802
            CAST ::temp174 candidate ;@line 802
            CALLSTATIC storageutil GetIntValue ::temp179 ::temp174 "MME.MilkMaid.IsSlave" 0 ;@line 802
            CAST ::temp182 ::temp179 ;@line 802
            STRCAT ::temp182 ::temp181 ::temp182 ;@line 802
            CALLSTATIC mmediagnostics Report ::nonevar ::temp182 0 ;@line 802
            CALLSTATIC mmediagnostics YesNo ::temp181 cachedSubjectMaid ;@line 803
            STRCAT ::temp182 "Dialogue cache: subjectMaid=" ::temp181 ;@line 803
            STRCAT ::temp181 ::temp182 " subjectSlave=" ;@line 803
            CALLSTATIC mmediagnostics YesNo ::temp182 cachedSubjectSlave ;@line 803
            STRCAT ::temp181 ::temp181 ::temp182 ;@line 803
            STRCAT ::temp182 ::temp181 " freeSlots=" ;@line 803
            CAST ::temp181 cachedFreeSlots ;@line 803
            STRCAT ::temp181 ::temp182 ::temp181 ;@line 803
            CALLSTATIC mmediagnostics Report ::nonevar ::temp181 0 ;@line 803
            COMPAREEQ ::temp173 candidateMaid cachedSubjectMaid ;@line 804
            NOT ::temp173 ::temp173 ;@line 804
            CAST ::temp173 ::temp173 ;@line 804
            JUMPT ::temp173 label260 ;@line 804
            COMPAREEQ ::temp172 candidateSlave cachedSubjectSlave ;@line 804
            NOT ::temp172 ::temp172 ;@line 804
            CAST ::temp173 ::temp172 ;@line 804
            label260:
            JUMPF ::temp173 label261 ;@line 804
            CALLSTATIC mmediagnostics Report ::nonevar "CACHE MISMATCH: MME opening dialogue state disagrees with faction/storage state" 2 ;@line 805
            JUMP label259
            label261:
            CALLSTATIC mmediagnostics Report ::nonevar "Cache check PASS: dialogue state agrees with faction/storage state" 0 ;@line 807
            label259:
            CALLSTATIC mmediagnostics YesNo ::temp182 playerMaid ;@line 809
            STRCAT ::temp181 "Player: maid=" ::temp182 ;@line 809
            STRCAT ::temp182 ::temp181 " milk=" ;@line 809
            CAST ::temp181 playerMilk ;@line 809
            STRCAT ::temp181 ::temp182 ::temp181 ;@line 809
            STRCAT ::temp182 ::temp181 " source valid=" ;@line 809
            CALLSTATIC mmediagnostics YesNo ::temp181 playerSourceValid ;@line 809
            STRCAT ::temp182 ::temp182 ::temp181 ;@line 809
            CALLSTATIC mmediagnostics Report ::nonevar ::temp182 0 ;@line 809
            CAST ::temp181 candidateMilk ;@line 810
            STRCAT ::temp182 "NPC: milk=" ::temp181 ;@line 810
            STRCAT ::temp181 ::temp182 " source valid=" ;@line 810
            CALLSTATIC mmediagnostics YesNo ::temp182 candidateSourceValid ;@line 810
            STRCAT ::temp181 ::temp181 ::temp182 ;@line 810
            CALLSTATIC mmediagnostics Report ::nonevar ::temp181 0 ;@line 810
            CALLSTATIC mmediagnostics PassFail ::temp182 ostimPlayerDrinksEligible ;@line 811
            STRCAT ::temp181 "OStim choices: player drinks=" ::temp182 ;@line 811
            STRCAT ::temp182 ::temp181 " NPC drinks=" ;@line 811
            CALLSTATIC mmediagnostics PassFail ::temp181 ostimNPCDrinksEligible ;@line 811
            STRCAT ::temp182 ::temp182 ::temp181 ;@line 811
            CALLSTATIC mmediagnostics Report ::nonevar ::temp182 0 ;@line 811
            CALLSTATIC mmediagnostics Report ::nonevar "New Milk Maid capacity: delegated to native MME Lactacid effect" 0 ;@line 812
            COMPAREEQ ::temp172 blocker "none" ;@line 813
            JUMPF ::temp172 label263 ;@line 813
            CALLSTATIC mmediagnostics Report ::nonevar "PASS: New Milk Maid route is runtime-eligible" 0 ;@line 814
            JUMP label262
            label263:
            STRCAT ::temp181 "FAIL: " blocker ;@line 816
            CALLSTATIC mmediagnostics Report ::nonevar ::temp181 2 ;@line 816
            label262:
          .endCode
        .endFunction
        .function RunNewMilkMaidSexLabBusTest static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
          .endParamTable
          .localTable
            .local ::temp183 mmedebug
            .local ::temp184 bool
            .local ::temp185 objectreference
            .local ::temp186 actor
            .local service MMEDebug
            .local ::nonevar none
            .local candidate Actor
          .endLocalTable
          .code
            CALLSTATIC mmediagnostics GetDebugService ::temp183  ;@line 821
            ASSIGN service ::temp183 ;@line 821
            CAST ::temp183 None ;@line 822
            COMPAREEQ ::temp184 service ::temp183 ;@line 822
            JUMPF ::temp184 label265 ;@line 822
            CALLSTATIC mmediagnostics Report ::nonevar "SexLab bus FAIL: persistent service is missing" 2 ;@line 823
            RETURN none ;@line 824
            JUMP label264
            label265:
            label264:
            CALLSTATIC game GetCurrentCrosshairRef ::temp185  ;@line 826
            CAST ::temp186 ::temp185 ;@line 826
            ASSIGN candidate ::temp186 ;@line 826
            CAST ::temp186 None ;@line 827
            COMPAREEQ ::temp184 candidate ::temp186 ;@line 827
            JUMPF ::temp184 label267 ;@line 827
            CALLMETHOD RecordNewMilkMaidSexLabBusStop service ::nonevar 1 "no NPC under the crosshair; close MCM, aim at the NPC, reopen, then run the test" True False ;@line 828
            CALLMETHOD ShowNewMilkMaidSexLabBusReport service ::nonevar  ;@line 829
            RETURN none ;@line 830
            JUMP label266
            label267:
            label266:
            CALLSTATIC mmediagnostics RefreshNewMilkMaidSexLabBus ::nonevar  ;@line 832
            CALLSTATIC mmeostimbreastfeeding IsBreastfeedingEnabled ::temp184  ;@line 833
            JUMPF ::temp184 label269 ;@line 833
            CALLSTATIC mmenewmilkmaid RunOStimBusPreflight ::nonevar candidate ;@line 834
            JUMP label268
            label269:
            CALLSTATIC mmenewmilkmaid RunSexLabBusPreflight ::nonevar candidate ;@line 836
            label268:
            CALLMETHOD ShowNewMilkMaidSexLabBusReport service ::nonevar  ;@line 838
          .endCode
        .endFunction
        .function Report static
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param reportText String
            .param severity Int
          .endParamTable
          .localTable
            .local ::temp187 int
            .local ::temp188 bool
            .local ::temp189 string
            .local ::nonevar none
          .endLocalTable
          .code
            CALLSTATIC jsonutil GetIntValue ::temp187 "/MMEAlerts/Settings" "enableDiagnosticNotifications" 1 ;@line 842
            COMPAREEQ ::temp188 ::temp187 1 ;@line 842
            JUMPF ::temp188 label271 ;@line 842
            STRCAT ::temp189 "MME Diagnostics: " reportText ;@line 843
            CALLSTATIC debug Notification ::nonevar ::temp189 ;@line 843
            JUMP label270
            label271:
            label270:
            CALLSTATIC mmelog IsDiagnosticEnabled ::temp188  ;@line 845
            JUMPF ::temp188 label273 ;@line 845
            STRCAT ::temp189 "[MME Extensions Diagnostics] " reportText ;@line 846
            CALLSTATIC mmelog Diagnostic ::nonevar ::temp189 severity ;@line 846
            JUMP label272
            label273:
            label272:
          .endCode
        .endFunction
        .function YesNo static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
            .param value Bool
          .endParamTable
          .localTable
          .endLocalTable
          .code
            JUMPF value label275 ;@line 851
            RETURN "yes" ;@line 852
            JUMP label274
            label275:
            label274:
            RETURN "no" ;@line 854
          .endCode
        .endFunction
        .function PassFail static
          .userFlags 0
          .docString ""
          .return String
          .paramTable
            .param value Bool
          .endParamTable
          .localTable
          .endLocalTable
          .code
            JUMPF value label277 ;@line 858
            RETURN "PASS" ;@line 859
            JUMP label276
            label277:
            label276:
            RETURN "FAIL" ;@line 861
          .endCode
        .endFunction
        .function onBeginState
          .userFlags 0
          .docString "Event received when this state is switched to"
          .return None
          .paramTable
          .endParamTable
          .localTable
          .endLocalTable
          .code
          .endCode
        .endFunction
        .function onEndState
          .userFlags 0
          .docString "Event received when this state is switched away from"
          .return None
          .paramTable
          .endParamTable
          .localTable
          .endLocalTable
          .code
          .endCode
        .endFunction
      .endState
    .endStateTable
  .endObject
.endObjectTable