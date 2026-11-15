"""Execute production NPC playback logic with mocked engine/audio boundaries."""
from pathlib import Path
from types import SimpleNamespace as NS
import re,sys,unittest
from test_tentacle_tiers import translate
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMEMovementSoundPlayback.psc').read_text()
class Store:
 def __init__(self):self.values={}
 def get(self,a,k,d=0):return self.values.get((a,k),d)
 GetIntValue=GetFloatValue=GetStringValue=get
 def put(self,a,k,v):self.values[a,k]=v;return v
 SetIntValue=SetFloatValue=SetStringValue=put
 def unset(self,a,k):self.values.pop((a,k),None)
 UnsetIntValue=UnsetFloatValue=unset
 def HasFloatValue(self,a,k):return (a,k) in self.values
class Actor:
 def __init__(self):self.moving=True;self.maid=True;self.scene=False;self.sneak=False;self.sprint=False;self.distance=100
 def IsSneaking(self):return self.sneak
 def IsSprinting(self):return self.sprint
 def GetParentCell(self):return 1
 def GetDistance(self,_):return self.distance
 def GetDisplayName(self):return 'Lydia'
class Playback(unittest.TestCase):
 def setUp(self):
  self.store=Store();self.player=Actor();self.session=1;self.stops=[];self.plays=[];self.volumes=[];self.notices=[];self.alarms=[];self.block='';self.enabled=True;self.choice=1;self.gain=.5;self.onplay=lambda:None
  self.configured=[];self.removed=[];self.native_instance=-1
  def play(a):
   self.plays.append(a);self.onplay();return len(self.plays)
  self.ns={'StorageUtil':self.store,'MMELog':NS(Alarm=lambda t:self.alarms.append(t)),'Game':NS(GetPlayer=lambda:self.player),'Utility':NS(IsInMenuMode=lambda:False),'MMEExtensionsNative':NS(GetMovementSlapSession=lambda:self.session,IsActorMovingOnFoot=lambda a:a is not None and a.moving),'Enabled':lambda:self.enabled,'MMEArmorScript':NS(IsValidMilkMaid=lambda a,m:a.maid),'MMEAnimationSafety':NS(GetOwner=lambda a:'',IsMMEMilking=lambda a,m:False,GetStartBlockReason=lambda a,m,f:'scene active' if a.scene else self.block),'MMEMovementSounds':NS(Route=lambda a,c,m: (2 if c>=m*.5 else 0)+(1 if a.sprint and not a.sneak else 0),Selection=lambda r:self.choice,GainForActor=lambda *a:self.gain,Resolve=lambda c:NS(Play=play)),'Sound':NS(StopInstance=self.stops.append,SetInstanceVolume=lambda i,g:self.volumes.append((i,g))),'MME_Storage':NS(getMilkMaximum=lambda a:self.store.put(a,'MME.MilkMaid.MilkMaximum',10)),'Notify':lambda *a:self.notices.append(a)}
  self.ns['MMEExtensionsNative'].RemoveMovementAudio=self.removed.append
  self.ns['MMEExtensionsNative'].GetMovementAudioInstance=lambda a:self.native_instance
  self.ns['MMEMovementSounds'].Configure=lambda *args:self.configured.append(args)
  source=SOURCE.replace('Sound selected =','Actor selected =').replace('+ target +','+ str(target) +')
  for name,args in [('Stop','target,reason'),('Alarm','target,reason'),('BlockReason','target,milk'),('UpdateActor','target,milk')]:exec(translate(name,args,source),self.ns)
 def actor(self):
  a=Actor();self.store.put(a,'MME.MilkMaid.MilkMaximum',10.);self.store.put(a,'MME.MilkMaid.MilkCount',8.);return a
 def update(self,a):self.ns['UpdateActor'](a,object())
 def test_stationary_maid_stays_registered_for_native_triggers(self):
  a=self.actor();a.moving=False;self.update(a)
  self.assertEqual(self.configured,[(a,2,True)]);self.assertEqual(self.plays,[])
 def test_normal_scene_and_player_are_excluded(self):
  for mode in ['normal','scene','player']:
   a=self.actor()
   if mode=='normal':a.maid=False
   if mode=='scene':a.scene=True
   if mode=='player':self.player=a
   self.update(a)
  self.assertEqual(self.configured,[])
 def test_fullness_base_uses_original_storage(self):
  a=self.actor();self.store.put(a,'MME.MilkMaid.MilkCount',2.);self.update(a)
  self.assertEqual(self.configured,[(a,0,True)])
 def test_range_exit_and_disabled_withdraw_native_permission(self):
  a=self.actor();a.distance=2500;self.update(a);self.assertIn(a,self.removed)
  a.distance=100;self.enabled=False;self.update(a);self.assertEqual(self.removed.count(a),2)
 def test_native_handle_observed_without_papyrus_play(self):
  a=self.actor();self.native_instance=41;self.update(a);self.update(a)
  self.assertEqual(self.store.get(a,'MME.MovementNPC.Instance'),41)
  self.assertEqual(len(self.notices),1);self.assertEqual(self.plays,[])
 def test_saved_handle_is_not_treated_as_current_playback(self):
  a=self.actor();self.store.put(a,'MME.MovementNPC.Instance',99);self.store.put(a,'MME.MovementNPC.Session',0)
  self.update(a);self.assertEqual(self.store.get(a,'MME.MovementNPC.Instance'),-1);self.assertEqual(self.stops,[])
 def test_reset_menu_and_build_wiring(self):
  c=(R/'Source/Scripts/MMEAlertsController.psc').read_text()
  self.assertIn('MMEMovementSoundPlayback.StopAll("menu opened:',c)
  self.assertIn('MMEMovementSoundPlayback.Reset("load callback")',c)
  self.assertIn('$scriptNames += "MMEMovementSoundPlayback"',(R/'build-package.ps1').read_text())
 def test_notification_names_actor_and_throttles(self):
  class Entries(list):
   @property
   def Length(self):return len(self)
  a=self.actor();b=self.actor();shown=[];clock=[100.]
  self.store.put(a,'MME.MovementNPC.Instance',1);self.store.put(b,'MME.MovementNPC.Instance',2)
  self.ns.update(JsonUtil=NS(GetIntValue=lambda f,k,d:d,GetFloatValue=lambda f,k,d:d),Utility=NS(GetCurrentGameTime=lambda:10.,GetCurrentRealTime=lambda:clock[0],RandomInt=lambda *a:0),MMENarrationOverrides=NS(Pool=lambda *a:Entries(['{actor} moves.'])),MMEThoughts=NS(RenderActorToken=lambda s,n:s.replace('{actor}',n)),Debug=NS(Notification=shown.append),Trace=lambda *a:None)
  exec(translate('Notify','target,current,maximum',SOURCE),self.ns)
  self.ns['Notify'](a,8.,10.);self.ns['Notify'](a,8.,10.);self.ns['Notify'](b,8.,10.)
  self.assertEqual(shown,['Lydia moves.'])
  clock[0]+=11;self.ns['Notify'](b,8.,10.);self.assertEqual(shown,['Lydia moves.','Lydia moves.'])
 def test_half_full_notification_is_skipped(self):
  self.ns.update(JsonUtil=NS(GetIntValue=lambda f,k,d:d),Trace=lambda *a:None)
  exec(translate('Notify','target,current,maximum',SOURCE),self.ns)
  self.ns['Notify'](self.actor(),5.,10.)
if __name__=='__main__':unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout))
