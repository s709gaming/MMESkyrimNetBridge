"""Execute production shared Papyrus facade with mocked engine/VM boundaries."""
from pathlib import Path
from types import SimpleNamespace as NS
import unittest,re
from test_tentacle_tiers import translate,Memory
from test_dwemer_instance_facade import Native,Actor
from test_post_milking import CastInt
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMEItemAttachments.psc').read_text()
class Backend(Native):
 def __init__(self):super().__init__();self.category=0;self.identity='42/1:100:1'
 def QueueItemAttachment(self,*a):self.calls.append(a);return CastInt(1)
 def GetWornItemAttachmentClass(self,*a):return self.category
class Store(Memory):
 def UnsetIntValue(self,a,k):self.values.pop((a,k),None)
class Wearer(Actor):
 def IsDead(self):return False
 def HasSpell(self,_):return getattr(self,'passive',False)
 def AddSpell(self,*_):self.passive=True
 def RemoveSpell(self,*_):self.passive=False
class Shared(unittest.TestCase):
 def setUp(self):
  self.native=Backend();self.actor=Wearer('Player');self.enabled=True;self.locked=False;self.protected='';self.wornLiving=False;self.effects=[];self.alarms=[];self.store=Store()
  self.q=NS(MilkForSprigganPassive='passive');self.busy=''
  self.ns={'MMEExtensionsNative':self.native,'MMEAlertsController':NS(IsExtensionsEnabled=lambda:self.enabled),'JsonUtil':NS(GetIntValue=lambda *a:1),'MMELog':NS(MasterDiagnostic=lambda *a:None,Alarm=self.alarms.append),'Utility':NS(WaitMenuMode=lambda *a:None),'StorageUtil':self.store,'Armor':NS(GetMaskForSlot=lambda _:4),'StringUtil':NS(Find=lambda s,k:s.find(k),Substring=lambda s,i:s[i:]),'MME_Storage':NS(getMaidLevel=lambda _:4),'Quest':NS(GetQuest=lambda _:self.q),'Game':NS(GetPlayer=lambda:self.actor),'MMETimedArmorLock':NS(IsLocked=lambda _:self.locked),'MMEAnimationSafety':NS(GetStartBlockReason=lambda *a:self.busy),'MMEArmorScript':NS(GetMMEArmorProtectionReason=lambda *a:self.protected,IsMMEMilkMaid=lambda *a:True),'MMECustomArmorRegistry':NS(HandleCustomArmorEquipped=lambda *a:self.effects.append('equip'),HasWornLivingArmor=lambda *a:self.wornLiving),'MMEExtensionsAPI':NS(TryRepeatArmorEquipStory=lambda *a:self.effects.append('story')),'MMEArmorIntroduction':NS(TryIntroduction=lambda *a:self.effects.append('first-story'))}
  functions=[('Request','wearer,item,operation,expected="",fittedLevel=0,armorClass=4'),('Identity','wearer,item'),('GetClass','wearer,item'),('GetClassFast','wearer,item'),('Has','wearer,item'),('Capture','wearer,item'),('Install','wearer,item,identity,armorClass=4'),('Remove','wearer,item,identity,armorClass=4'),('Tag','wearer,item'),('NeedsRefit','wearer,item'),('Refit','wearer,item'),('ServiceState','wearer,armorClass'),('ApplyService','wearer,armorClass,adding'),('ToggleWorn','wearer,armorClass'),('Cleanup','wearer'),('Reconcile','wearer')]
  for name,args in functions:
   source=re.sub(r'(?m)^(\s*)Armor (\w+) =',r'\1Actor \2 =',SOURCE.replace('+ operation','+ str(operation)').replace('+ armorClass','+ str(armorClass)').replace('+ adding','+ str(adding)'))
   exec(translate(name,args,source),self.ns)
 def test_all_categories_have_exact_item_transaction(self):
  for category in range(1,5):
   self.assertTrue(self.ns['Install'](self.actor,'armor','ticket',category));self.assertEqual(self.native.calls[-1][2:],(1,'ticket',True,4,category))
   self.assertTrue(self.ns['Remove'](self.actor,'armor','ticket',category));self.assertEqual(self.native.calls[-1][-1],category)
 def test_class_specific_service_menu(self):
  for category in range(1,5):
   self.native.category=category;self.assertEqual(self.ns['ServiceState'](self.actor,category),2);self.assertEqual(self.ns['ServiceState'](self.actor,category%4+1),3)
 def test_no_attachment_and_protected_or_locked(self):
  self.assertEqual(self.ns['ServiceState'](self.actor,1),1);self.locked=True;self.assertEqual(self.ns['ServiceState'](self.actor,1),3)
  self.locked=False;self.protected='dedicated suit';self.assertEqual(self.ns['ServiceState'](self.actor,1),3)
 def test_disabled_does_not_queue_or_classify(self):
  self.enabled=False;self.native.category=2;self.assertEqual(self.ns['GetClass'](self.actor,'armor'),0);self.assertFalse(self.ns['Install'](self.actor,'armor','ticket',2));self.assertEqual(self.native.calls,[])
 def test_busy_combat_scene_guard(self):
  self.busy='SexLab scene active';self.assertEqual(self.ns['ServiceState'](self.actor,1),0)
  self.assertFalse(self.ns['ApplyService'](self.actor,1,True));self.assertEqual(self.native.calls,[])
  self.native.category=2;self.assertFalse(self.ns['ApplyService'](self.actor,2,False));self.assertEqual(self.native.calls,[])
  self.assertEqual(self.ns['ServiceState'](None,1),0)
 def test_cached_polling_has_no_transaction(self):
  self.native.category=3
  for _ in range(8):self.assertEqual(self.ns['GetClassFast'](self.actor,'armor'),3)
  self.assertEqual(self.native.calls,[])
 def test_existing_class_label_reconcile_only_when_pending(self):
  self.native.category=2;self.native.labelPending=True;self.assertEqual(self.ns['GetClass'](self.actor,'armor'),2);self.assertEqual(self.native.calls[-1][2:],(4,'42/1:100:1',True,0,2))
 def test_refit_follows_class(self):
  self.native.category=3;self.assertTrue(self.ns['Refit'](self.actor,'armor'));self.assertEqual(self.native.calls[-1][-1],3)
 def test_living_passive_reconciles_without_story(self):
  for category in [2,3]:
   self.native.category=category;self.actor.passive=False;self.ns['Reconcile'](self.actor);self.assertTrue(self.actor.passive)
  self.assertEqual(self.effects,[])
 def test_cleanup_removes_owned_only_and_respects_other_living(self):
  self.actor.passive=True;self.ns['Cleanup'](self.actor);self.assertTrue(self.actor.passive)
  self.store.SetIntValue(self.actor,'MME.ItemAttachment.OwnsPassive',1);self.wornLiving=True;self.ns['Cleanup'](self.actor);self.assertTrue(self.actor.passive)
  self.wornLiving=False;self.ns['Cleanup'](self.actor);self.assertFalse(self.actor.passive);self.ns['Cleanup'](self.actor);self.assertEqual(self.alarms,[])
 def test_migration_cleanup_unbacked_original_passive(self):
  self.actor.passive=True;self.ns['Reconcile'](self.actor);self.assertFalse(self.actor.passive)
 def test_original_milking_snapshots_fitting_before_stripping(self):
  s=(R/'Source/MMECompatibilityOverrides/MilkQUEST.psc').read_text();body=s.split('Function MilkingToContainer(',1)[1]
  self.assertLess(body.index('Int MMEExtMilkingClass'),body.index('akActor.UnequipItem(cuirass'))
  self.assertIn('MMEExtMilkingClass == 2',body);self.assertIn('MMEExtMilkingClass == 3',body)
 def test_vendor_and_spell_routes_no_global_writes(self):
  for file in ['MMEBlacksmithDialogue','MMEAlchemistDialogue','MMEMageDialogue']:
   s=(R/'Source/Scripts'/f'{file}.psc').read_text();self.assertIn('MMEItemAttachments.ApplyService',s);self.assertNotRegex(s,r'(?:MilkingEquipment|BasicLivingArmor|ParasiteLivingArmor)\[[^]]+\]\s*=')
  for file in ['MilkAMMEScr','MilkAMBLAScr','MilkAMPLAScr']:self.assertIn('MMEItemAttachments.ToggleWorn',(R/'Source/MMECompatibilityOverrides'/f'{file}.psc').read_text())
 def test_original_consumers_and_mcm_cannot_recreate_global_fit(self):
  for file in ['MilkQUEST','MilkPlayerLoadGame','MME_CheckForSpriggan']:
   s=(R/'Source/MMECompatibilityOverrides'/f'{file}.psc').read_text();self.assertNotRegex(s,r'(?i)(?:MilkingEquipment|BasicLivingArmor|ParasiteLivingArmor)\.find\(')
  m=(R/'Source/MMECompatibilityOverrides/MilkMCM.psc').read_text();self.assertIn('MMEItemAttachments.ToggleWorn',m);self.assertNotRegex(m,r'(?:MilkingEquipment|BasicLivingArmor|ParasiteLivingArmor)\[[^\n]+\]\s*= Slots\[2\]')
 def test_array_presence_guards_do_not_cast_none_to_arrays(self):
  for name in ['milkController.MilkingEquipment','milkController.BasicLivingArmor','milkController.ParasiteLivingArmor','actors']:
   self.assertIn('('+name+' as Bool) &&',SOURCE)
   self.assertNotIn(name+' != None',SOURCE)
  self.assertIn('migration inspection | legacy entries=',SOURCE)
if __name__=='__main__':unittest.main()
