"""Execute the actual consent gate against mocked UI/storage/engine boundaries."""
from pathlib import Path
from types import SimpleNamespace as NS
import unittest
from test_tentacle_tiers import translate
from test_post_milking import CastInt,Storage
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMESkyrimNetVoiceControls.psc').read_text()
# Only normalize Papyrus types/array construction for the narrow source executor.
EXEC=SOURCE.replace('Message question','Actor question').replace(' as Message','').replace('new Actor[2]','[None, None]').replace('+ eligible)', '+ str(eligible))')
class Consent(unittest.TestCase):
 def setUp(self):
  self.store=Storage();self.generation=42;self.now=100.;self.answer=0;self.shown=[];self.alarms=[];self.hook=lambda:None
  self.enabled=True;self.eligible=True;self.cooldown=0;self.ostim=False;self.backend=True;self.missing=False
  self.ns={'Game':NS(GetPlayer=lambda:'Player',GetFormFromFile=self.form),'Quest':NS(GetQuest=lambda _:object()),
   'StorageUtil':self.store,'Utility':NS(GetCurrentRealTime=lambda:self.now),
   'MMEExtensionsNative':NS(GetMovementSlapSession=lambda:CastInt(self.generation)),
   'MMEAlertsController':NS(IsExtensionsEnabled=lambda:self.enabled),'JsonUtil':NS(GetIntValue=lambda *a:1),
   'MMEOStimBreastfeeding':NS(IsBreastfeedingEnabled=lambda:self.ostim),
   'MMESexLabBreastfeedingBackend':NS(IsAvailable=lambda _:self.backend),
   'MMEOStimIntegration':NS(ValidatePairForCommit=lambda *a:self.eligible),
   'MMELog':NS(MasterDiagnostic=lambda *a:None,Alarm=self.alarms.append),
   'GetBreastfeedingActionCooldownRemaining':lambda:self.cooldown}
  for name,args in [('CanCommitConfirmedBreastfeeding','milkSource, drinker'),('ConsentAlarm','reason, milkSource, drinker'),('ConfirmPlayerBreastfeeding','milkSource, drinker')]:exec(translate(name,args,EXEC),self.ns)
 def form(self,id,plugin):
  if self.missing:return None
  def show():
   self.shown.append(id);self.hook();return self.answer
  return NS(Show=show)
 def call(self,source='Maid',drinker='Player'):return self.ns['ConfirmPlayerBreastfeeding'](source,drinker)
 def test_roles_and_both_backends(self):
  for ostim in [False,True]:
   self.ostim=ostim;self.assertTrue(self.call());self.assertEqual(self.shown[-1],0x8D1)
   self.assertTrue(self.call('Player','Maid'));self.assertEqual(self.shown[-1],0x8D2)
 def test_npc_only_no_ui(self):self.assertTrue(self.call('Maid','NPC'));self.assertEqual(self.shown,[])
 def test_decline_backoff_and_expiry(self):
  self.answer=1;self.assertFalse(self.call());self.assertFalse(self.call());self.assertEqual(len(self.shown),1)
  self.now+=16;self.answer=0;self.assertTrue(self.call());self.assertEqual(self.alarms,[])
 def test_duplicate_is_not_queued(self):
  results=[];self.hook=lambda:results.append(self.call());self.assertTrue(self.call());self.assertEqual(results,[False]);self.assertEqual(len(self.shown),1)
 def test_world_change_after_yes(self):
  self.hook=lambda:setattr(self,'eligible',False);self.assertFalse(self.call())
 def test_disable_after_yes(self):
  self.hook=lambda:setattr(self,'enabled',False);self.assertFalse(self.call())
 def test_cooldown_after_yes(self):
  self.hook=lambda:setattr(self,'cooldown',10);self.assertFalse(self.call())
 def test_load_invalidates_reply_and_recovers(self):
  self.hook=lambda:setattr(self,'generation',43);self.assertFalse(self.call());self.hook=lambda:None;self.assertTrue(self.call())
 def test_missing_message_fails_closed_alarm_deduplicated(self):
  self.missing=True;self.assertFalse(self.call());self.assertFalse(self.call());self.assertEqual(len(self.alarms),1)
 def test_ui_failure_fails_closed(self):
  self.answer=-1;self.assertFalse(self.call());self.assertEqual(len(self.alarms),1)
 def test_invalid_and_absent_backend_no_prompt(self):
  self.eligible=False;self.assertFalse(self.call());self.eligible=True;self.backend=False;self.assertFalse(self.call());self.assertEqual(self.shown,[])
 def test_backend_removed_while_menu_open(self):
  self.hook=lambda:setattr(self,'backend',False);self.assertFalse(self.call())
 def test_message_records_match_script_roles(self):
  import sys,struct
  sys.path.insert(0,str(R/'tools/localization'))
  from common import records,fields
  expected={0x8D1:("MME_BF_PlayerDrinksConfirm","Drink milk directly from this character's breast?"),0x8D2:("MME_BF_PlayerProvidesConfirm","Allow this character to drink directly from your breast?")}
  seen=set()
  for sig,header,body in records((R/'MMEAlert.esp').read_bytes()):
   id=struct.unpack_from('<I',header,12)[0]&0xffffff
   if sig!=b'MESG' or id not in expected:continue
   data=list(fields(body));edid=dict(data)[b'EDID'].rstrip(b'\0').decode();text=dict(data)[b'DESC'].rstrip(b'\0').decode()
   self.assertEqual((edid,text),expected[id]);self.assertEqual([v.rstrip(b'\0').decode() for k,v in data if k==b'ITXT'],['Yes','No']);seen.add(id)
  self.assertEqual(seen,set(expected))
 def test_shared_gate_precedes_both_backend_calls(self):
  body=SOURCE.split('Function StartBreastfeedingMilkShare(',1)[1].split('EndFunction',1)[0]
  gate=body.index('ConfirmPlayerBreastfeeding(milkSource, drinker)')
  for call in ['ostimService.StartBreastfeeding(', 'service.StartSexLabBreastfeeding(']:self.assertLess(gate,body.index(call))
  self.assertEqual(body.count('MarkBreastfeedingActionCooldown()'),2)
if __name__=='__main__':unittest.main()
