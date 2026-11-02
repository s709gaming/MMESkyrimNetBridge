"""Execute the actual one-shot publisher against mocked storage/engine/API boundaries."""
from pathlib import Path
from types import SimpleNamespace as NS
import json,re,unittest
from test_tentacle_tiers import translate
from test_milking_source import Store
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMEPostMilking.psc').read_text()
class CastInt(int):
 def __radd__(self,other):
  return other+str(self) if isinstance(other,str) else int(other)+int(self)
class Storage(Store):
 def GetIntValue(self,a,k,d=0):return CastInt(super().GetIntValue(a,k,d))
 def AdjustIntValue(self,a,k,amount):
  value=self.GetIntValue(a,k)+amount;self.SetIntValue(a,k,value);return CastInt(value)
 GetStringValue=Store.GetFloatValue
 SetStringValue=Store.SetFloatValue
 UnsetStringValue=Store.UnsetFloatValue
class Actor:
 def __init__(self,name):self.name=name;self.dead=False;self.loaded=True;self.combat=False;self.scene=None
 def IsDeleted(self):return False
 def IsChild(self):return False
 def IsDead(self):return self.dead
 def IsDisabled(self):return False
 def Is3DLoaded(self):return self.loaded
 def IsInCombat(self):return self.combat
 def GetCurrentScene(self):return self.scene
class Publisher(unittest.TestCase):
 def setUp(self):
  self.store=Storage();self.settings={};self.events=[];self.lines=[];self.playerRequests=[];self.tts=[];self.alarms=[]
  self.now=500.;self.generation=42;self.available=True;self.master=True;self.busy=False;self.owner='';self.player=Actor('Player');self.result=0;self.roll=1
  self.data={p.stem:json.loads(p.read_text(encoding='utf-8'))['routes'] for p in (R/'SKSE/Plugins/StorageUtilData/MMEAlerts/Narration').glob('*.json')}
  def raw(f,k):return self.data[f][k]['template']
  def text(f,k,*args):
   mapping=dict(zip(args[::2],args[1::2]));return re.sub(r'\{(.*?)\}',lambda m:str(mapping[m[1]]),raw(f,k))
  def saveEvent(content,origin,target):self.events.append((content,origin,target));return CastInt(self.result)
  def speak(content,origin,target):self.lines.append((content,origin,target));return CastInt(self.result)
  def request(*args):self.playerRequests.append(args);return 1
  self.ns={'StorageUtil':self.store,'JsonUtil':NS(GetIntValue=lambda f,k,d=0:self.settings.get(k,d),GetFloatValue=lambda f,k,d=0:self.settings.get(k,d)),
   'Utility':NS(GetCurrentRealTime=lambda:self.now,RandomInt=lambda a,b:self.roll),
   'SKSE':NS(GetPluginVersion=lambda p:1 if self.available else -1),
   'MMEAlertsSkyrimNet':NS(IsExtensionsEnabled=lambda:self.master,IsAvailable=lambda:self.available,ResolveActorName=lambda a,d:a.name,EscapeJsonString=lambda s:json.dumps(s)[1:-1]),
   'MMEOStimIntegration':NS(IsActorBusy=lambda a:self.busy),'MMEAnimationSafety':NS(GetOwner=lambda a:self.owner),
   'MMEExtensionsNative':NS(GetMovementSlapSession=lambda:CastInt(self.generation)),
   'MMEMilkingSource':NS(MethodName=lambda m:['Generic','Hands','Pump','Milking Equipment','Living Tendrils','Dwemer Machinery'][m]),
   'MMENarrationText':NS(GetRaw=raw,Text=text,IsBlank=lambda s:not s.strip()),
   'MMEDialogueKnowledge':NS(Append=lambda s,a:s+' SHARED',ForRequest=lambda *args:'SHARED'),
   'Game':NS(GetPlayer=lambda:self.player,GetFormFromFile=lambda *args:object()),
   'StringUtil':NS(Find=lambda s,x:s.find(x),GetLength=len,Substring=lambda s,start:s[start:]),
   'SkyrimNetApi':NS(RegisterPersistentEvent=saveEvent,DirectNarration=speak,SendCustomPromptToLLM=request,TriggerPlayerTTS=lambda s:self.tts.append(s) or 0),
   'Noop':lambda:None,'AlarmOnce':lambda *args:self.alarms.append(args)}
  source=re.sub(r'(?m)^\s*Trace\(.*$','    Noop()',SOURCE).replace(' as MMEAlertsController','').replace('MMEAlertsController bridge =','Actor bridge =')
  for name,args in [('IntegrationBlock','target'),('NarrationBlock','target'),('RouteForMethod','method'),('RecordCompletion','target,sessionId,method,afterMilk,netRemoved,extracted'),('RecordFull','target'),('AcquireNarrationGate',''),('ReleaseNarrationGate','lockKey'),('NarrateLast','target'),('PlayPlayerLine','response,success')]:
   exec(translate(name,args,source),self.ns)
 def record(self,a,method=4,after=0,delta=10,extracted=1,token=1):
  self.store.SetIntValue(a,'MME.Source.LastSession',token)
  self.ns['RecordCompletion'](a,CastInt(token),method,after,delta,extracted)
 def test_sources_results_and_actor_isolation(self):
  for method in range(6):
   a=Actor('NPC'+str(method));self.record(a,method)
   content,origin,target=self.events[-1];self.assertIs(origin,a);self.assertIsNone(target)
   self.assertIn('empty at completion',content)
   self.ns['NarrateLast'](a);self.assertIs(self.lines[-1][1],a)
   self.now+=120
  self.assertIn('Living tendrils',self.events[4][0]);self.assertIn('Dwemer mechanism',self.events[5][0])
 def test_partial_productive_failed_and_duplicate(self):
  a=Actor('Lydia');self.record(a,after=3);self.assertIn('Some milk remained',self.events[-1][0])
  self.record(a,after=20,delta=-10,token=2);self.assertIn('no net reduction',self.events[-1][0]);self.assertNotIn('empty',self.events[-1][0])
  self.record(a,extracted=0,token=3);self.assertEqual(len(self.events),2)
  self.ns['NarrateLast'](a);self.assertEqual(self.lines,[])
  self.record(a,token=4);self.record(a,token=4);self.assertEqual(len(self.events),3)
 def test_history_independent_of_speech_controls(self):
  a=Actor('Lydia');self.settings['enablePostMilkingNarration']=0;self.record(a);self.ns['NarrateLast'](a)
  self.assertEqual(len(self.events),1);self.assertEqual(self.lines,[])
  self.settings['enablePostMilkingNarration']=1;self.settings['postMilkingNarrationChance']=0
  self.record(a,token=2);self.ns['NarrateLast'](a);self.assertEqual(len(self.events),2);self.assertEqual(self.lines,[])
  self.settings['postMilkingNarrationChance']=100;self.record(a,token=3);self.ns['NarrateLast'](a);self.assertEqual(len(self.lines),1)
  self.record(a,token=4);self.ns['NarrateLast'](a);self.assertEqual(len(self.events),4);self.assertEqual(len(self.lines),1)
  b=Actor('Other');self.record(b);self.ns['NarrateLast'](b);self.assertEqual(len(self.lines),1)
  self.assertEqual(len(self.events),5)
  self.now+=120;self.record(a,token=5);self.ns['NarrateLast'](a);self.ns['NarrateLast'](a);self.assertEqual(len(self.lines),2)
 def test_full_history_does_not_require_narration(self):
  for a in [Actor('Player'),Actor('NPC')]:self.ns['RecordFull'](a)
  self.assertEqual(len(self.events),2);self.assertTrue(all('began leaking' in e[0] for e in self.events));self.assertEqual(self.lines,[])
  self.settings['enableSkyrimNetFullEvents']=0;self.ns['RecordFull'](Actor('Third'));self.assertEqual(len(self.events),2)
 def test_optional_disabled_busy_stale_and_api_failure(self):
  for attr in ['available','master']:
   a=Actor(attr);setattr(self,attr,False);self.record(a);self.ns['NarrateLast'](a);self.assertEqual(self.events,[]);setattr(self,attr,True)
  for attr,value in [('busy',True),('owner','animation')]:
   a=Actor(attr);setattr(self,attr,value);self.record(a);self.ns['NarrateLast'](a);self.assertEqual(self.lines,[]);setattr(self,attr,False if attr=='busy' else '')
  a=Actor('Stale');self.record(a);self.now+=121;self.ns['NarrateLast'](a);self.assertEqual(self.lines,[])
  self.record(a,token=2);self.generation+=1;self.ns['NarrateLast'](a);self.assertEqual(self.lines,[])
  self.result=1;self.record(a,token=3);self.ns['NarrateLast'](a);self.assertTrue(self.alarms)
  self.assertEqual(self.store.GetFloatValue(None,'MME.After.LastNarrationGlobal',-1),-1)
 def test_global_gate_reentrancy_failure_release_and_new_load(self):
  gate=self.ns['AcquireNarrationGate']();self.assertTrue(gate)
  self.assertEqual(self.ns['AcquireNarrationGate'](),'')
  self.assertEqual(self.store.GetIntValue(None,gate),1)
  self.ns['ReleaseNarrationGate'](gate);self.assertEqual(self.store.GetIntValue(None,gate),0)
  self.generation+=1;new=self.ns['AcquireNarrationGate']();self.assertNotEqual(new,gate)
  self.assertNotIn((None,gate),self.store.data)
  self.ns['ReleaseNarrationGate'](gate);self.assertEqual(self.store.GetIntValue(None,new),1)
  self.ns['ReleaseNarrationGate'](new)
  a,b=Actor('First'),Actor('Second');self.result=1;self.record(a);self.ns['NarrateLast'](a)
  self.assertEqual(self.store.GetIntValue(None,new),0)
  self.result=0;self.record(b);self.ns['NarrateLast'](b);self.assertEqual(len(self.lines),2)
 def test_player_private_reply_correlation_and_cleanup(self):
  a=self.player;self.record(a);self.ns['NarrateLast'](a)
  self.assertEqual(len(self.playerRequests),1);self.assertEqual(self.lines,[])
  context=json.loads(self.playerRequests[0][2]);self.assertIn('SHARED',context['milkKnowledge'])
  marker=self.store.GetStringValue(a,'MME.After.PendingMarker')
  self.ns['PlayPlayerLine']('[[MME:old]]Wrong reply',1);self.assertEqual(self.tts,[])
  self.assertEqual(self.store.GetIntValue(a,'MME.After.PendingPlayer'),1)
  self.ns['PlayPlayerLine'](marker+'What a harvest!',1);self.assertEqual(self.tts,['What a harvest!'])
  self.assertEqual(self.store.GetIntValue(a,'MME.After.PendingPlayer'),0)
  self.now+=120;self.record(a,token=2);self.ns['NarrateLast'](a);marker=self.store.GetStringValue(a,'MME.After.PendingMarker');self.generation+=1
  self.ns['PlayPlayerLine'](marker+'Old load',1);self.assertEqual(len(self.tts),1)
 def test_chance_and_current_busy_guards(self):
  a=Actor('Lydia');self.settings['postMilkingNarrationChance']=25;self.roll=26
  self.record(a);self.ns['NarrateLast'](a);self.assertEqual(self.lines,[])
  self.roll=25;self.record(a,token=2);self.ns['NarrateLast'](a);self.assertEqual(len(self.lines),1)
  for attr,value in [('combat',True),('scene',object()),('loaded',False)]:
   b=Actor(attr);setattr(b,attr,value);self.record(b);self.ns['NarrateLast'](b);self.assertEqual(len(self.lines),1)

class Integration(unittest.TestCase):
 def test_full_crossing_baseline_rearm_and_multiple_actors(self):
  controller=(R/'Source/Scripts/MMEAlertsController.psc').read_text()
  store=Storage();events=[];levels={};a,b=object(),object()
  ns={'StorageUtil':store,'StateKey':'capacity','IsMMEMilkMaid':lambda actor:True,
      'MME_Storage':NS(getMilkMaximum=lambda actor:10,getMilkCurrent=lambda actor:levels[actor]),
      'MMEPostMilking':NS(RecordFull=lambda actor:events.append(actor))}
  exec(translate('UpdateCapacityState','candidate',controller),ns)
  levels[a]=10;self.assertEqual(ns['UpdateCapacityState'](a),0);self.assertEqual(events,[])
  levels[a]=4;ns['UpdateCapacityState'](a)
  levels[b]=0;ns['UpdateCapacityState'](b)
  levels[a]=10;levels[b]=12
  self.assertEqual(ns['UpdateCapacityState'](a),2);self.assertEqual(ns['UpdateCapacityState'](b),2)
  self.assertEqual(events,[a,b]);ns['UpdateCapacityState'](a);self.assertEqual(events,[a,b])
 def test_completion_crossing_and_dwemer_ownership(self):
  source=(R/'Source/Scripts/MMEMilkingSource.psc').read_text()
  self.assertLess(source.index('ClearActive(target)',source.index('Function Complete(')),source.index('MMEPostMilking.RecordCompletion('))
  controller=(R/'Source/Scripts/MMEAlertsController.psc').read_text()
  done=controller.split('Event OnMMEMilkingDone(',1)[1].split('EndEvent',1)[0]
  self.assertIn('"MME.Source.LastMethod", 0) != 5',done)
  crossing=controller.split('Int Function UpdateCapacityState(',1)[1].split('EndFunction',1)[0]
  self.assertIn('previousState < 2 && currentState == 2\n        MMEPostMilking.RecordFull(candidate)',crossing)
  dwemer=(R/'Source/Scripts/MMEDwemerArmor.psc').read_text()
  self.assertNotIn('NarrateDwemerSuitEvent(candidate, narrationArmor, "milkingEnd")',dwemer)
  self.assertGreater(dwemer.index('MMEPostMilking.NarrateLast(candidate)'),dwemer.index('CleanupSequence(candidate, milkController, animationStarted, controlsDisabled, npcUnconscious, activationShader)'))
  bridge=(R/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text()
  self.assertNotIn('SendMilkingEvent',bridge.split('Function SendMilkingEnd(',1)[1].split('EndFunction',1)[0])
 def test_defaults_diagnostics_and_no_gameplay_changes(self):
  defaults=SOURCE.split('Function EnsureDefaults()',1)[1].split('EndFunction',1)[0]
  self.assertIn('HasIntValue(settings, "enablePostMilkingNarration")',defaults)
  self.assertIn('"postMilkingNarrationCooldown", 120.0',defaults)
  self.assertIn('"postMilkingNarrationChance", 100',defaults)
  self.assertNotIn('SetFloatValue(settings, "milkFullNarrationCooldown"',defaults)
  self.assertIn('MMELog.MasterDiagnostic',SOURCE);self.assertIn('MMELog.Alarm',SOURCE)
  self.assertNotRegex(SOURCE,r'Utility.Wait|RegisterForUpdate|AssignSlot|setMilkCurrent|Debug.Notification')
  mcm=(R/'Source/Scripts/MMEAlertsMCM.psc').read_text();self.assertIn('Return 172',mcm)
  page=mcm.split('Function DrawSkyrimNetPage()',1)[1].split('EndFunction',1)[0]
  for option in ['postMilkingNarrationOption','postMilkingCooldownOption','postMilkingChanceOption','fullHistoryOption','milkFullNarrationChanceOption']:self.assertIn(option,page)
  bridge=(R/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text()
  full=bridge.split('Function NarrateMilkFull(',1)[1].split('EndFunction',1)[0]
  self.assertIn('"milkFullNarrationCooldown", 120.0',full)
  self.assertIn('"milkFullNarrationChance", 100',full)
  self.assertIn('StorageUtil.GetFloatValue(None, "MME.After.FullNarrationGlobal"',full)
  self.assertIn('StorageUtil.SetFloatValue(None, "MME.After.FullNarrationGlobal", now)',full)
if __name__=='__main__':unittest.main()
