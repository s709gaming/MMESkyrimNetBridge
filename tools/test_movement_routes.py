"""Behavioral settings/route checks plus binary record and loop-asset isolation."""
import array,struct,subprocess,unittest,wave
from pathlib import Path
from types import SimpleNamespace as NS
from test_tentacle_tiers import translate
from prepare_movement_routes import build,ROUTES
from prepare_movement_slap import records,subrecords
ROOT=Path(__file__).resolve().parents[1]
SOURCE=(ROOT/'Source/Scripts/MMEMovementSounds.psc').read_text()
class MovementRoutes(unittest.TestCase):
 def setUp(self):
  self.settings={};self.ns={'JsonUtil':NS(GetFloatValue=lambda f,k,d:self.settings.get(k,d),GetIntValue=lambda f,k,d:self.settings.get(k,d))}
  src=SOURCE.replace('+ route +','+ str(route) +')
  for name,args in [('Key','route,suffix'),('Route','player,current,maximum'),('Selection','route'),('Gain','route,sneaking')]:exec(translate(name,args,src),self.ns)
 def test_fullness_and_motion_matrix(self):
  for milk,base in [(0,0),(49.99,0),(50,2),(100,2),(110,2)]:
   for run,sprint,sneak,offset in [(False,False,False,0),(True,False,False,1),(False,True,False,1),(True,True,True,0)]:
    actor=NS(IsSneaking=lambda:sneak,IsRunning=lambda:run,IsSprinting=lambda:sprint)
    self.assertEqual(self.ns['Route'](actor,milk,100),base+offset)
 def test_selections_defaults_none_and_corruption(self):
  for route in range(4):
   self.assertEqual(self.ns['Selection'](route),route+1)
   for choice in range(5):self.settings[f'movementSound{route}Selection']=choice;self.assertEqual(self.ns['Selection'](route),choice)
   self.settings[f'movementSound{route}Selection']=99;self.assertEqual(self.ns['Selection'](route),route+1)
 def test_volume_migration_sneak_and_combined_cap(self):
  self.assertEqual(self.ns['Gain'](0,False),.5);self.assertEqual(self.ns['Gain'](0,True),.25)
  self.settings['movementSlapVolume']=60;self.assertEqual(self.ns['Gain'](3,False),.3)
  self.settings['movementSound3Volume']=200;self.settings['movementSoundSneakVolume']=200
  self.assertEqual(self.ns['Gain'](3,True),1)
  self.settings['reactionSoundVolume']=0;self.assertEqual(self.ns['Gain'](3,False),0)
  self.settings['reactionSoundVolume']=100;self.settings['movementSound3Volume']=-10;self.assertEqual(self.ns['Gain'](3,False),0)
 def test_records_repeatable_and_isolated(self):
  old=subprocess.check_output(['git','show','HEAD:MMEAlert.esp'],cwd=ROOT);now=(ROOT/'MMEAlert.esp').read_bytes();self.assertEqual(build(old),now);self.assertEqual(build(now),now)
  baseline={r[12:16]:r for r in records(old) if r[:4]!=b'TES4'};current={r[12:16]:r for r in records(now) if r[:4]!=b'TES4'}
  added=sum(1 for desc,mark,_,_ in ROUTES for identifier in (desc,mark) if not any((struct.unpack("<I",key)[0]&0xffffff)==identifier for key in baseline))
  self.assertEqual(len(current),len(baseline)+added)
  for key,value in baseline.items():
   if struct.unpack('<I',key)[0]&0xffffff!=0x8C4:self.assertEqual(current[key],value)
  collision=now.replace(b'MMEAlerts_SNDR_SlowSlaps',b'MMEAlerts_SNDR_WrongName');self.assertEqual(len(collision),len(now))
  with self.assertRaisesRegex(AssertionError,'collision'):build(collision)
 def test_four_assets_and_marker_links(self):
  local={struct.unpack_from('<I',r,12)[0]&0xffffff:r for r in records((ROOT/'MMEAlert.esp').read_bytes())}
  for descriptor,marker,label,filename in ROUTES:
   d=dict(subrecords(local[descriptor][24:]));m=dict(subrecords(local[marker][24:]));self.assertEqual(m[b'SDSC'],local[descriptor][12:16]);self.assertEqual(d[b'LNAM'][1]&0x38,8)
   path=d[b'ANAM'].rstrip(b'\0').decode().replace('\\','/');self.assertEqual(path,'fx/MMESkyrimNetBridge/Movement Loops/'+filename)
   with wave.open(str(ROOT/'assets/sounds/Movement Loops'/filename),'rb') as w:
    self.assertEqual((w.getnchannels(),w.getsampwidth(),w.getframerate()),(1,2,44100));self.assertTrue(4<=w.getnframes()/w.getframerate()<=4.5);a=array.array('h',w.readframes(w.getnframes()));self.assertEqual((a[0],a[-1]),(0,0));self.assertLess(max(abs(v) for v in a),32767)
 def test_resolver_matches_authored_markers(self):
  self.ns['Game']=NS(GetFormFromFile=lambda identifier,plugin:(identifier,plugin))
  exec(translate('Resolve','choice',SOURCE.replace(' as Sound','')),self.ns)
  self.assertIsNone(self.ns['Resolve'](0))
  for choice,(_,marker,_,_) in enumerate(ROUTES,1):self.assertEqual(self.ns['Resolve'](choice),(marker,'MMEAlert.esp'))
 def test_unrelated_record_groups_are_byte_identical(self):
  def groups(data):
   pos=24+struct.unpack_from('<I',data,4)[0];result={}
   while pos<len(data):
    self.assertEqual(data[pos:pos+4],b'GRUP');size=struct.unpack_from('<I',data,pos+4)[0];result[data[pos+8:pos+12]]=data[pos:pos+size];pos+=size
   return result
  old=groups(subprocess.check_output(['git','show','HEAD:MMEAlert.esp'],cwd=ROOT));now=groups((ROOT/'MMEAlert.esp').read_bytes());self.assertEqual(set(old),set(now))
  for signature in set(old)-{b'SNDR',b'SOUN'}:self.assertEqual(now[signature],old[signature])
 def test_existing_guards_and_notifications_remain(self):
  s=(ROOT/'Source/Scripts/MMEAlertsController.psc').read_text();self.assertIn('StopMovementSlap("movement/fullness selection changed")',s);self.assertIn('MMEMovementSounds.Gain(route, MovementSlapPlayer.IsSneaking())',s)
  for guard in ['IsPlayerMovingOnFoot','IsDhlpSuspended','IsMMEMilking','IsActorActive','IsActorInScene','MovementSlapGeneration','MovementSlapSession']:self.assertIn(guard,s)
  notification=s.split('Function TryMovementSlapNotification()')[1];self.assertIn('<= milkMaximum * 0.5',notification)
  m=(ROOT/'Source/Scripts/MMEAlertsMCM.psc').read_text();self.assertIn('SetSliderDialogInterval(5.0)',m);self.assertIn('Event OnOptionMenuAccept(Int option, Int index)',m);self.assertIn('index > 4',m)
if __name__=='__main__':unittest.main()
