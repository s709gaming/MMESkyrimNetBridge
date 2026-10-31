.info
  .source "JUGs_MakeAMaid1C024.psc"
  .modifyTime 1792806730
  .compileTime 1793365982
  .user "Donald"
  .computer "DESKTOP-TQJH8KD"
.endInfo
.userFlagsRef
  .flag conditional 1
  .flag hidden 0
.endUserFlagsRef
.objectTable
  .object JUGs_MakeAMaid1C024 TopicInfo
    .userFlags 1
    .docString ""
    .autoState 
    .variableTable
      .variable ::SexLab_var sexlabframework
        .userFlags 0
        .initialValue None
      .endVariable
      .variable ::Jugs_var jugsmain
        .userFlags 0
        .initialValue None
      .endVariable
    .endVariableTable
    .propertyTable
	  .property SexLab SexLabFramework auto
	    .userFlags 0
	    .docString ""
	    .autoVar ::SexLab_var
	  .endProperty
	  .property Jugs JugsMain auto
	    .userFlags 0
	    .docString ""
	    .autoVar ::Jugs_var
	  .endProperty
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
        .function Fragment_0 
          .userFlags 0
          .docString ""
          .return NONE
          .paramTable
            .param akSpeakerRef ObjectReference
          .endParamTable
          .localTable
            .local ::temp0 actor
            .local ::temp1 bool
            .local ::temp3 string
            .local target Actor
            .local ::nonevar none
            .local ::temp2 string
            .local created Bool
          .endLocalTable
          .code
            CAST ::temp0 akSpeakerRef ;@line 4
            ASSIGN target ::temp0 ;@line 4
            CAST ::temp0 None ;@line 5
            COMPAREEQ ::temp1 target ::temp0 ;@line 5
            JUMPF ::temp1 label1 ;@line 5
            CALLSTATIC mmelog Alarm ::nonevar "[MME Extensions JUGS] make-a-maid request rejected: dialogue target missing" 2 ;@line 6
            RETURN none ;@line 7
            JUMP label0
            label1:
            label0:
            CALLSTATIC mmeextensionsapi IsMilkMaid ::temp1 target ;@line 9
            JUMPF ::temp1 label3 ;@line 9
            CALLMETHOD GetDisplayName target ::temp2  ;@line 10
            STRCAT ::temp2 "[MME Extensions JUGS] make-a-maid request ignored: already a Milk Maid | actor=" ::temp2 ;@line 10
            CALLSTATIC mmelog MasterDiagnostic ::nonevar ::temp2 0 ;@line 10
            RETURN none ;@line 11
            JUMP label2
            label3:
            label2:
            CALLSTATIC mmeextensionsapi TryCreateMilkMaidForcedAnimated ::temp1 target ;@line 14
            ASSIGN created ::temp1 ;@line 14
            CAST ::temp2 created ;@line 15
            STRCAT ::temp2 "[MME Extensions JUGS] make-a-maid result=" ::temp2 ;@line 15
            STRCAT ::temp2 ::temp2 " | actor=" ;@line 15
            CALLMETHOD GetDisplayName target ::temp3  ;@line 15
            STRCAT ::temp2 ::temp2 ::temp3 ;@line 15
            CALLSTATIC mmelog MasterDiagnostic ::nonevar ::temp2 0 ;@line 15
          .endCode
        .endFunction
      .endState
    .endStateTable
  .endObject
.endObjectTable