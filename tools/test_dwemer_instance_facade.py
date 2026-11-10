"""Execute the actual facade at mocked native/clock boundaries, plus integration guards."""
from pathlib import Path
from types import SimpleNamespace as NS
import unittest,re
from test_tentacle_tiers import translate,Memory
from test_post_milking import CastInt
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMEDwemerAttachment.psc').read_text()
class Native:
 def __init__(self):self.result='ok|42/1:100:1';self.pending=0;self.calls=[];self.installed=False;self.identity='?';self.cancelled=False
 def QueueDwemerAttachment(self,*a):self.calls.append(a);return CastInt(1)
 def GetDwemerAttachmentResult(self,request,cancel=False):
  if cancel:self.cancelled=True;return 'skip|cancelled before execution'
  if self.pending>0:self.pending-=1;return ''
  return self.result
 def GetMovementSlapSession(self):return CastInt(42)
 def GetDwemerItemIdentity(self,*a):return self.identity
 def HasWornDwemerAttachment(self,*a):return self.installed
 def GetDwemerRefitLevel(self,*a):return 3
 def GetDwemerAttachmentTag(self,*a):return '7' if self.installed else ''
class Store(Memory):pass
class Actor(str):
 def GetWornForm(self,_):return 'armor'
class Facade(unittest.TestCase):
 def setUp(self):
  self.native=Native();self.enabled=True;self.waits=[];self.alarms=[];self.actor=Actor('Player')
  self.ns={'MMEExtensionsNative':self.native,'MMEAlertsController':NS(IsExtensionsEnabled=lambda:self.enabled),'JsonUtil':NS(GetIntValue=lambda *a:1),
   'MMELog':NS(MasterDiagnostic=lambda *a:None,Alarm=self.alarms.append),'Utility':NS(WaitMenuMode=lambda n:self.waits.append(n)),
   'StorageUtil':Store(),'Armor':NS(GetMaskForSlot=lambda _:4),'StringUtil':NS(Find=lambda s,k:s.find(k),Substring=lambda s,i:s[i:]),'MME_Storage':NS(getMaidLevel=lambda _:4)}
  for name,args in [('Request','wearer,item,operation,expected="",fittedLevel=0'),('Identity','wearer,item'),('Has','wearer,item'),('Capture','wearer,item'),('Install','wearer,item,identity'),('Remove','wearer,item,identity'),('Tag','wearer,item'),('NeedsRefit','wearer,item'),('Refit','wearer,item')]:exec(translate(name,args,SOURCE.replace("+ operation", "+ str(operation)")),self.ns)
 def test_capture_and_menu_mode_wait(self):
  self.native.pending=2;self.assertEqual(self.ns['Capture'](self.actor,'armor'),'42/1:100:1');self.assertEqual(len(self.waits),2)
 def test_timeout_cancels_queued_work(self):
  self.native.pending=1000;self.assertEqual(self.ns['Capture'](self.actor,'armor'),'');self.assertTrue(self.native.cancelled)
 def test_native_failure_alarm_deduplicated(self):
  self.native.result='error|bad identity';self.ns['Capture'](self.actor,'armor');self.ns['Capture'](self.actor,'armor');self.assertEqual(len(self.alarms),1)
 def test_expected_skip_is_not_alarm(self):
  self.native.result='skip|item changed';self.assertFalse(self.ns['Install'](self.actor,'armor','token'));self.assertEqual(self.alarms,[])
 def test_disabled_and_missing_target(self):
  self.enabled=False;self.assertFalse(self.ns['Install'](self.actor,'armor','token'));self.assertEqual(self.native.calls,[])
  self.assertEqual(self.ns['Identity'](None,'armor'),'')
 def test_resolve_and_has(self):
  self.native.installed=True;self.assertTrue(self.ns['Has'](self.actor,'armor'));self.assertEqual(self.native.calls[-1][2],-1)
 def test_install_remove_refit_operation_and_identity(self):
  self.assertTrue(self.ns['Install'](self.actor,'armor','ticket'));self.assertEqual(self.native.calls[-1][2:],(1,'ticket',True,4))
  self.assertTrue(self.ns['Remove'](self.actor,'armor','ticket'));self.assertEqual(self.native.calls[-1][2],2)
  self.assertTrue(self.ns['Refit'](self.actor,'armor'));self.assertEqual(self.native.calls[-1][2],3)
 def test_refit_only_installed_item(self):
  self.native.installed=False;self.assertFalse(self.ns['NeedsRefit'](self.actor,'armor'));self.native.installed=True;self.assertTrue(self.ns['NeedsRefit'](self.actor,'armor'));self.assertEqual(self.ns['Tag'](self.actor,'armor'),'7')
 def test_no_identity_never_commits(self):
  self.assertFalse(self.ns['Install'](self.actor,'armor',''));self.assertFalse(self.ns['Remove'](self.actor,'armor','ordinary'));self.assertEqual(self.native.calls,[])
 def test_global_artisan_branch_is_retired(self):
  registry=(R/'Source/Scripts/MMECustomArmorRegistry.psc').read_text();body=registry.split('Int Function ClassifyCustomArmor(',1)[1].split('EndFunction',1)[0]
  self.assertNotIn('IsArtisanDwemerArmor',body);self.assertIn('Function ClassifyForActor',registry)
  body=registry.split('Bool Function RegisterArtisanDwemerArmor(',1)[1].split('EndFunction',1)[0];self.assertIn('Return False',body);self.assertNotIn('FormListAdd',body)
 def test_dedicated_dwemer_consumer_has_actor_context_and_final_guard(self):
  s=(R/'Source/Scripts/MMEDwemerArmor.psc').read_text();self.assertIn('ClassifyForActor(candidate, wornArmor)',s);self.assertIn('exact Dwemer item changed during activation',s)
  self.assertLess(s.index('exact Dwemer item changed during activation'),s.index('milkController.MilkingToContainer('))
 def test_native_storage_and_threads(self):
  s=(R/'src/DwemerAttachmentRegistry.cpp').read_text()
  for token in ['AddTask','SetSaveCallback','SetLoadCallback','SetRevertCallback','TESUniqueIDChangeEvent','TESContainerChangedEvent','GetCount()!=1','r.expected!=std::to_string(generation)']:self.assertIn(token,s)
  self.assertNotIn('SetEnchantment',s);self.assertNotIn('SetDisplayName',s)
if __name__=='__main__':unittest.main()
