"""Execute actual expiry/cleanup source; template render tests cover consumption."""
from pathlib import Path
from types import SimpleNamespace as NS
import re,unittest
from test_tentacle_tiers import translate,Memory
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMEActorPromptState.psc').read_text()
class Store(Memory):
 GetStringValue=Memory.GetFloatValue
 SetStringValue=Memory.SetFloatValue
 UnsetStringValue=Memory.UnsetFloatValue
 def FormListClear(self,a,k):self.lists[a,k]=[]
class Expiry(unittest.TestCase):
 def setUp(self):
  self.store=Store();self.now=100.0
  self.ns={'StorageUtil':self.store,'Utility':NS(GetCurrentRealTime=lambda:self.now),'MMELog':NS(MasterDiagnostic=lambda *a:None)}
  src=re.sub(r'(?m)^.*MMELog.MasterDiagnostic[^\n]*','',SOURCE)
  for name,args in [('NextExpiry',''),('TrackRecent','target'),('ExpireRecent',''),('Invalidate','target,reason="test"')]:exec(translate(name,args,src),self.ns)
 def mark(self,a,time):
  self.store.SetFloatValue(a,'MME.Extensions.SkyrimNet.RecentMilkDrink',time)
  self.store.SetIntValue(a,'MME.Prompt.Recent',1)
  self.store.SetStringValue(a,'MME.Prompt.Lore','lore')
  self.ns['TrackRecent'](a)
 def test_exact_expiry_and_maid_lore_preserved(self):
  self.mark('player',100);self.mark('npc',120)
  self.store.SetIntValue('player','MME.Prompt.IsMaid',1)
  self.now=189.9;self.ns['ExpireRecent']();self.assertEqual(self.store.GetIntValue('player','MME.Prompt.Recent'),1)
  self.now=190;self.ns['ExpireRecent']();self.assertEqual(self.store.GetIntValue('player','MME.Prompt.Recent'),0)
  self.assertEqual(self.store.GetStringValue('player','MME.Prompt.Lore'),'lore')
  self.assertEqual(self.store.GetIntValue('npc','MME.Prompt.Recent'),1)
  self.now=210;self.ns['ExpireRecent']();self.assertEqual(self.store.GetStringValue('npc','MME.Prompt.Lore'),'')
  self.assertEqual(self.ns['NextExpiry'](),0)
 def test_repeated_drink_and_clock_rollback(self):
  self.mark('player',100);self.mark('player',150)
  self.now=191;self.ns['ExpireRecent']();self.assertEqual(self.store.GetIntValue('player','MME.Prompt.Recent'),1)
  self.assertEqual(self.ns['NextExpiry'](),240)
  self.now=10;self.ns['ExpireRecent']();self.assertEqual(self.store.GetIntValue('player','MME.Prompt.Recent'),0)
 def test_invalidation_drops_ready_and_actor_text(self):
  self.store.SetIntValue('player','MME.Prompt.Ready',1);self.store.SetStringValue('player','MME.Prompt.Lore','old')
  self.store.SetStringValue('npc','MME.Prompt.Lore','other')
  self.ns['Invalidate']('player');self.assertEqual(self.store.GetIntValue('player','MME.Prompt.Ready'),0)
  self.assertFalse(('player','MME.Prompt.Lore') in self.store.values)
  self.assertEqual(self.store.GetStringValue('npc','MME.Prompt.Lore'),'other')
 def test_lifecycle_and_no_cache_dependency(self):
  bridge=(R/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text()
  self.assertNotIn('SkyrimNetApi.RegisterDecorator(',bridge)
  for p in (R/'SkyrimNetPrompts').glob('*.prompt'):
   self.assertNotRegex(p.read_text(),r'mme_(milkmaid_prompt_debug|recent_milk_drinker|actor_milk_state|milk_lore_text|breastfeeding_role|breastfeeding_guidance_text)\(')
  for file,token in [('MMEAlertsController','MMEActorPromptState.Observe(nearbyActors)'),('MMEAlertsMCM','Event OnConfigClose()'),('MMENarrationText','MMEActorPromptState.Initialize()'),('MMEDebug','MMEActorPromptState.Refresh(promptSource)'),('MMEMilkLeaks','MMEActorPromptState.Refresh(target)')]:self.assertIn(token,(R/'Source/Scripts'/f'{file}.psc').read_text())
  quest=(R/'Source/MMECompatibilityOverrides/MilkQUEST.psc').read_text()
  removal=re.search(r'(?ms)^Function MaidRemove\(Actor akActor\)\n.*?^EndFunction',quest)[0]
  self.assertEqual(removal.count('MMEActorPromptState.Invalidate('),2)
  self.assertIn('MMEActorPromptState.Invalidate(akActor, "MME maid removal")',removal)
  self.assertIn('MMEActorPromptState.Invalidate(akActor, "MME maid removal complete")',removal)

class Publishing(unittest.TestCase):
 def setUp(self):
  self.store=Store();self.present=True;self.enabled=1;self.maid=set();self.hits=[]
  self.player=type('Actor',(),{'IsDead':lambda a:False,'IsDisabled':lambda a:False})()
  self.ns={'StorageUtil':self.store,'Game':NS(GetModByName=lambda n:1 if self.present else 255),'JsonUtil':NS(GetIntValue=lambda *a:self.enabled),
           'MMEAlertsSkyrimNet':NS(IsRealMMEMilkmaid=lambda a:a in self.maid,RecentMilkDrinkerPrompt=lambda a:'',MilkLoreText=lambda a:'edited lore',BreastfeedingPromptRole=lambda a:'',BreastfeedingGuidanceText=lambda a:''),
           'MMELog':NS(MasterDiagnostic=lambda *a:None),'GetActorState':lambda a:self.hits.append(a),'TrackRecent':lambda a:None}
  src=re.sub(r'(?m)^.*MMELog.MasterDiagnostic[^\n]*','',SOURCE).replace(' as Int','')
  body=src.split('Function Refresh(Actor target) Global',1)[1].split('EndFunction',1)[0].split('    String signature',1)[0]
  src=src[:src.index('Function Refresh(Actor target) Global')]+'Function Refresh(Actor target) Global'+body+'EndFunction'
  for name,args in [('RefreshConfig',''),('Invalidate','target,reason="test"'),('Refresh','target')]:exec(translate(name,args,src),self.ns)
 def test_optional_absent_and_disabled_fail_closed(self):
  self.present=False;self.ns['Refresh'](self.player)
  self.assertEqual(self.store.GetIntValue(self.player,'MME.Prompt.Ready'),0);self.assertEqual(self.hits,[])
  self.present=True;self.enabled=0;self.ns['Refresh'](self.player)
  self.assertEqual(self.store.GetIntValue(None,'MME.Prompt.Enabled'),0);self.assertEqual(self.hits,[])
 def test_load_during_publication_invalidates(self):
  self.store.SetIntValue(None,'MME.Prompt.Epoch',9)
  self.ns['GetActorState']=lambda a:self.store.SetIntValue(None,'MME.Prompt.Epoch',10)
  self.ns['Refresh'](self.player)
  self.assertEqual(self.store.GetIntValue(self.player,'MME.Prompt.Ready'),0)
 def test_fresh_actor_identity_and_editable_lore(self):
  self.store.SetIntValue(None,'MME.Prompt.Epoch',9);self.maid.add(self.player);self.ns['Refresh'](self.player)
  self.assertEqual(self.store.GetIntValue(self.player,'MME.Prompt.IsMaid'),1)
  self.assertEqual(self.store.GetStringValue(self.player,'MME.Prompt.Lore'),'edited lore')
  self.assertEqual(self.store.GetIntValue(self.player,'MME.Prompt.Epoch'),9)
  self.assertEqual(self.store.GetIntValue(self.player,'MME.Prompt.Ready'),1)
  self.maid.clear();self.ns['Refresh'](self.player)
  self.assertEqual(self.store.GetIntValue(self.player,'MME.Prompt.IsMaid'),0)
  self.assertEqual(self.store.GetStringValue(self.player,'MME.Prompt.Lore'),'')

if __name__=='__main__':unittest.main()
