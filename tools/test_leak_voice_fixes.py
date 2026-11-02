"""Execute actual cleanup/voice branches against engine-boundary mocks, not a live VM."""
from pathlib import Path
from types import SimpleNamespace as NS
import re,json,unittest
from test_tentacle_tiers import translate
from test_milking_source import Store
R=Path(__file__).resolve().parents[1]
LEAK=(R/'Source/Scripts/MMEMilkLeaks.psc').read_text(encoding='utf-8-sig')
QUEST=(R/'Source/MMECompatibilityOverrides/MilkQUEST.psc').read_text(encoding='utf-8-sig')
VISUAL=(R/'fomod/choices/milk-leaks/Source/Scripts/MMELeakVisual.psc').read_text(encoding='utf-8-sig')

class Inventory:
 def __init__(self):self.items={'low':2,'medium':1,'high':1,'external':1,'clothes':1};self.operations=[];self.inspect=lambda:None
 def GetItemCount(self,item):return self.items.get(item,0)
 def UnequipItem(self,item,*args):self.inspect();self.operations.append(('unequip',item))
 def RemoveItem(self,item,count,*args):self.items[item]-=count;self.operations.append(('remove',item,count))
class DeadReference:
 def __getattr__(self,key):raise AssertionError('Dereferenced stale item: '+key)
class PapyrusInt(int):
 def __radd__(self,other):return other+str(self) if isinstance(other,str) else int(other)+int(self)

class Cleanup(unittest.TestCase):
 def setUp(self):
  self.alarms=[];self.actor=Inventory()
  self.ns={'tracked':[self.actor],'visuals':[DeadReference()],'visibleStages':[2],
   'LowArmor':'low','MediumArmor':'medium','HighArmor':'high','ExternalArmor':'external',
   'Alarm':lambda *a:self.alarms.append(a),'Noop':lambda:None}
  source=re.sub(r'(?m)^\s*Trace\(.*$','    Noop()',LEAK)
  source=re.sub(r'"[^"\n]*"',lambda m:m[0].replace(';',r'\x3b'),source)
  for name,args in [('RemoveOwnedVisual','target,ownedArmor'),('RemoveVisual','slot')]:exec(translate(name,args,source),self.ns)
 def test_stale_reference_tracking_cleared_first_and_repeat(self):
  def inspect():
   self.assertIsNone(self.ns['visuals'][0]);self.assertEqual(self.ns['visibleStages'][0],-1)
  self.actor.inspect=inspect
  self.ns['RemoveVisual'](0);self.ns['RemoveVisual'](0)
  self.assertEqual(self.actor.items,{'low':0,'medium':0,'high':0,'external':1,'clothes':1})
  self.assertEqual(len(self.actor.operations),6);self.assertEqual(self.alarms,[])
 def test_empty_slots_invalid_bounds_and_external_guard(self):
  self.ns['tracked'][0]=None;self.ns['RemoveVisual'](0);self.assertIsNone(self.ns['visuals'][0])
  self.ns['RemoveVisual'](PapyrusInt(-1));self.ns['RemoveVisual'](PapyrusInt(1));self.assertEqual(len(self.alarms),2)
  self.ns['RemoveOwnedVisual'](self.actor,'external');self.assertEqual(self.actor.items['external'],1)
  self.assertEqual(self.actor.operations,[])
 def test_failed_removal_is_a_real_alarm(self):
  self.actor.RemoveItem=lambda *args:None
  self.ns['RemoveOwnedVisual'](self.actor,'low');self.assertEqual(len(self.alarms),1)
 def test_player_npc_slot_isolation(self):
  npc=Inventory();first=DeadReference()
  self.ns.update(tracked=[self.actor,npc],visuals=[first,DeadReference()],visibleStages=[2,1])
  self.ns['RemoveVisual'](1)
  self.assertEqual(self.actor.items['low'],2);self.assertEqual(self.actor.operations,[])
  self.assertIs(self.ns['visuals'][0],first);self.assertIsNone(self.ns['visuals'][1])
  self.assertEqual(npc.items['low'],0);self.assertEqual(npc.items['external'],1)
 def test_visual_callback_never_uses_self_after_wait(self):
  self.assertNotIn('GetBaseObject()',VISUAL.split('Utility.Wait(0.1)',1)[1])
  self.assertIn('wearer == None || !wearer.Is3DLoaded() || !wearer.IsEquipped(visualArmor)',VISUAL)
  self.assertNotRegex(LEAK,r'effectRef\.(?:Delete|GetBaseObject)\(')
  self.assertNotIn('.Delete(',LEAK)
  self.assertIn('now < previous || now - previous >= 60.0',LEAK)

class Actor:
 def __init__(self,child=False):self.child=child
 def IsChild(self):return self.child
 def __radd__(self,other):return other+'<Actor>'

class VisualCallback(unittest.TestCase):
 def test_removal_during_wait_and_current_positioning(self):
  for removed in [False,True]:
   bound=[True];equipped=[True];positions=[];failures=[]
   wearer=NS(Is3DLoaded=lambda:True,IsEquipped=lambda armor:equipped[0])
   def base():
    self.assertTrue(bound[0],'Callback touched its deleted reference after waiting')
    return 'own armor'
   def wait(seconds):bound[0]=False;equipped[0]=not removed
   original=NS(NippleOffsetL=[1.,2.,3.],EmitterScale=1.,GlobalEmitterScale=1.,actorStorage=None)
   ns={'GetBaseObject':base,'Utility':NS(Wait=wait),'Quest':NS(GetQuest=lambda name:original),
       'NetImmerse':NS(SetNodeLocalPosition=lambda actor,node,offset,fp:positions.append((node,offset.copy())),SetNodeScale=lambda *args:None),
       'ReportFailure':lambda *args:failures.append(args)}
   source=VISUAL.replace('Event OnContainerChanged','Function OnContainerChanged').replace('EndEvent','EndFunction').replace('Form visualArmor =','String visualArmor =').replace('OninusLactis original =','Actor original =').replace(' as OninusLactis','')
   exec(translate('OnContainerChanged','newContainer,oldContainer',source),ns)
   ns['OnContainerChanged'](wearer,None)
   self.assertEqual(positions,[] if removed else [('Lactis Group L',[1.,2.,3.]),('Lactis Group R',[-1.,2.,3.])])
   self.assertEqual(original.NippleOffsetL,[1.,2.,3.]);self.assertEqual(failures,[])

class Voice:
 def __init__(self):self.calls=[]
 def Moan(self,*args):self.calls.append(args)
class StoreText(Store):
 GetStringValue=Store.GetFloatValue
 SetStringValue=Store.SetFloatValue

class Voices(unittest.TestCase):
 def setUp(self):
  self.voice=Voice();self.calls=[];self.traces=[];self.alarms=[];self.master=True;self.selected=self.voice
  def pick(a):self.calls.append(('pick',a));return self.selected
  def random(a,b):self.calls.append(('random',a,b));return a
  self.framework=NS(Enabled=True,PickVoice=pick)
  self.ns={'SexLab':self.framework,'StorageUtil':StoreText(),'MMEExtMissingVoiceActorReported':False,
   'Utility':NS(RandomInt=random),'MMELog':NS(Alarm=lambda t:self.alarms.append(t),MasterDiagnostic=lambda t:self.traces.append(t) if self.master else None)}
  # Erase types only. All branch bodies remain the authored Papyrus source.
  source=QUEST.replace('sslBaseVoice voice =','Actor voice =')
  for name,args in [('MMEExtTraceMilkingVoice','akActor,status'),('MMEExtPlayMilkingVoiceSafe','akActor,minimumStrength,maximumStrength,isVictim')]:
   code=translate(name,args,source)
   if name=='MMEExtPlayMilkingVoiceSafe':code=code.replace('\n','\n    global MMEExtMissingVoiceActorReported\n',1)
   exec(code,self.ns)
 def play(self,a,low=30,high=100,victim=False):self.ns['MMEExtPlayMilkingVoiceSafe'](a,low,high,victim)
 def test_valid_player_npc_preserves_order_strength_and_victim(self):
  a,b=Actor(),Actor();self.play(a,70,100,True);self.play(b,30,100,False)
  self.assertEqual(self.voice.calls,[(a,70,True),(b,30,False)])
  self.assertEqual([x[0] for x in self.calls],['pick','random','pick','random'])
 def test_missing_voice_is_quiet_and_can_recover(self):
  a=Actor();self.selected=None
  for _ in range(50):self.play(a)
  self.assertEqual(self.voice.calls,[]);self.assertEqual(len(self.traces),1);self.assertEqual(self.alarms,[])
  self.selected=self.voice;self.play(a);self.assertEqual(len(self.traces),2);self.assertEqual(len(self.voice.calls),1)
 def test_absent_disabled_child_and_logging_off(self):
  a=Actor();self.ns['SexLab']=None;self.play(a)
  self.ns['SexLab']=self.framework;self.framework.Enabled=False;self.play(a);self.assertEqual(self.calls,[])
  self.framework.Enabled=True;self.play(Actor(child=True));self.assertEqual(self.calls,[])
  self.master=False;before=len(self.traces);self.selected=None;self.play(Actor());self.assertEqual(len(self.traces),before);self.assertEqual(self.alarms,[])
 def test_invalid_actor_alarm_deduplicates_without_master(self):
  self.master=False
  for _ in range(50):self.play(None)
  self.assertEqual(len(self.alarms),1);self.assertEqual(self.traces,[])
 def test_all_seven_caller_parameters_preserved(self):
  # Captured from installed/original MME 20220522 during preflight.
  expected=[('70','100','true'),('30','100','true'),('30','100','false')]*2+[('70','100','false')]
  actual=re.findall(r'MMEExtPlayMilkingVoiceSafe\(akActor, (\d+), (\d+), (true|false)\)',QUEST)
  self.assertEqual(len(actual),7);self.assertEqual(actual,expected)
  self.assertNotRegex(QUEST,r'PickVoice\(akActor\)\.Moan')
 def test_no_new_gameplay_and_lore_changes(self):
  helper=QUEST.split('Function MMEExtPlayMilkingVoiceSafe(',1)[1].split('EndFunction',1)[0]
  self.assertNotRegex(helper,r'Utility.Wait|RegisterFor|setMilk|AssignSlot|StartSex|RemoveItem')
  lore=json.loads((R/'SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/Lore.json').read_text(encoding='utf-8'))['routes']
  self.assertIn('Milk Maids love the satisfying heaviness of being full of milk.',lore['milk_lore']['template'])
  self.assertEqual(lore['shared_guidance']['template'], 'Be playful, erotic, and teasing. Favor innuendo, cheeky metaphors, and varied euphemisms over explicit sexual vocabulary. Keep reactions brief, natural, and non-graphic. Match the speaker and scene; nearby characters may occasionally chime in. Keep clear whose body and experience they describe.')
  self.assertEqual(lore['milkmaid_lore']['template'],'## Milk Maid Status\n\n{actor} is a Milk Maid and produces milk.')

if __name__=='__main__':unittest.main()
