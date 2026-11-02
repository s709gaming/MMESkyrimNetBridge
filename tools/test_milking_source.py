"""Execute actual tracker branches with mocked engine storage; live VM QA is separate."""
from pathlib import Path
from types import SimpleNamespace as NS
import re,unittest
from test_tentacle_tiers import translate
ROOT=Path(__file__).resolve().parents[1]
SOURCE=(ROOT/'Source/Scripts/MMEMilkingSource.psc').read_text()
QUEST=(ROOT/'Source/MMECompatibilityOverrides/MilkQUEST.psc').read_text()

class Actor:
    def __init__(self,child=False):self.child=child;self.milking=True
    def IsChild(self):return self.child
    def HasSpell(self,spell):return self.milking

class Store:
    def __init__(self):self.data={}
    def GetFloatValue(self,a,k,d=0):return self.data.get((a,k),d)
    GetIntValue=GetFloatValue
    GetFormValue=GetFloatValue
    def SetFloatValue(self,a,k,v):self.data[a,k]=v
    SetIntValue=SetFloatValue
    SetFormValue=SetFloatValue
    def UnsetFloatValue(self,a,k):self.data.pop((a,k),None)
    UnsetIntValue=UnsetFloatValue
    UnsetFormValue=UnsetFloatValue
    def HasFloatValue(self,a,k):return (a,k) in self.data

class Tracking(unittest.TestCase):
    def setUp(self):
        self.store=Store();self.enabled=1;self.dwemer=set();self.alarms=[];self.completions=[]
        self.ns={'StorageUtil':self.store,'JsonUtil':NS(GetIntValue=lambda *a:self.enabled),
                 'Utility':NS(GetCurrentGameTime=lambda:123.0),
                 'Quest':NS(GetQuest=lambda name:NS(BeingMilkedPassive='passive')),
                 'MMEDwemerArmor':NS(IsSequenceActive=lambda actor:actor in self.dwemer),
                 'MMEPostMilking':NS(RecordCompletion=lambda *args:self.completions.append(args)),
                 'Noop':lambda:None,'Alarm':lambda *a:self.alarms.append(a)}
        # Diagnostics are separately checked below; don't emulate Papyrus string casts.
        source=re.sub(r'(?m)^\s*Trace\(.*$', '    Noop()',SOURCE)
        source=re.sub(r'(?m)^(\s*)Alarm\(.*$',r'\1Alarm(None,"test","test")',source)
        functions={'Enabled':'','MethodName':'method','ResolveMethod':'target,mode','ClearActive':'target',
                   'Begin':'target,mode,equipment','Complete':'target,sessionId,bottles,boobgasms,cumCount',
                   'IsMilking':'target','GetCurrentSession':'target','GetCurrentMethod':'target','GetLastMethod':'target','GetLastSession':'target',
                   'WasMilkRemoved':'target','GetLastNetMilkRemoved':'target','GetLastFinishedDays':'target'}
        for name,args in functions.items():exec(translate(name,args,source),self.ns)
    def actor(self,milk=10,child=False):
        actor=Actor(child);self.store.SetFloatValue(actor,'MME.MilkMaid.Level',1)
        self.store.SetFloatValue(actor,'MME.MilkMaid.MilkCount',milk);return actor
    def test_all_modes_generic_and_dwemer(self):
        a=self.actor()
        for mode,expected in [(0,2),(1,1),(2,3),(3,4),(4,0)]:
            token=self.ns['Begin'](a,mode,'outfit')
            self.assertEqual(self.ns['GetCurrentMethod'](a),expected)
            self.ns['Complete'](a,token,0,0,0)
            self.assertEqual(self.ns['GetLastMethod'](a),expected)
        self.store.SetIntValue(a,'MMEExtensions.DwemerArmor.InProgress',1);self.ns['Begin'](a,4,'machine')
        self.assertEqual(self.ns['GetCurrentMethod'](a),5)
        self.assertEqual(self.ns['ResolveMethod'](a,99),0)
    def test_actor_isolation_and_clothing_snapshot(self):
        player,npc=self.actor(),self.actor();p=self.ns['Begin'](player,0,'pump');n=self.ns['Begin'](npc,3,'living')
        self.store.SetFloatValue(player,'MME.MilkMaid.MilkCount',2)
        self.ns['Complete'](player,p,8,0,0)
        self.assertEqual(self.ns['GetLastMethod'](player),2)
        self.assertEqual(self.ns['GetLastMethod'](npc),0)
        self.assertEqual(self.ns['GetCurrentMethod'](npc),4)
        self.assertEqual(self.store.GetFormValue(player,'MME.Source.LastEquipment'),'pump')
        self.assertTrue(self.ns['WasMilkRemoved'](player));self.assertEqual(self.ns['GetLastNetMilkRemoved'](player),8)
        self.assertEqual(self.store.GetFloatValue(player,'MME.Source.LastAfter'),2)
        self.assertEqual(self.completions[-1],(player,p,2,2,8,1))
        self.ns['Complete'](npc,n,0,0,0);self.assertFalse(self.ns['WasMilkRemoved'](npc))
    def test_duplicate_late_and_interrupted(self):
        a=self.actor();old=self.ns['Begin'](a,1,None);new=self.ns['Begin'](a,3,'living')
        self.ns['Complete'](a,old,4,0,0)
        self.assertEqual(self.ns['GetLastSession'](a),0)
        self.assertEqual(self.ns['GetCurrentMethod'](a),4)
        a.milking=False;self.assertFalse(self.ns['IsMilking'](a));self.assertEqual(self.ns['GetCurrentMethod'](a),0)
        a.milking=True;self.ns['Complete'](a,new,3,0,0)
        self.ns['Complete'](a,new,99,0,0)
        self.assertEqual(self.store.GetIntValue(a,'MME.Source.LastBottles'),3)
        self.assertEqual(self.ns['GetLastFinishedDays'](a),123)
    def test_old_save_disabled_children_and_no_conversion(self):
        a=self.actor();self.assertTrue(self.ns['IsMilking'](a));self.assertEqual(self.ns['GetCurrentMethod'](a),0)
        self.assertEqual(self.ns['GetLastSession'](a),0)
        token=self.ns['Begin'](a,2,'equipment');self.enabled=0;self.ns['Complete'](a,token,2,0,0)
        self.assertEqual(self.store.GetIntValue(a,'MME.Source.Active'),0)
        self.assertEqual(self.ns['Begin'](a,1,None),0)
        self.enabled=1;self.assertEqual(self.ns['Begin'](self.actor(child=True),1,None),0)
        outsider=Actor();self.assertEqual(self.ns['Begin'](outsider,1,None),0)
        self.assertFalse(self.store.HasFloatValue(outsider,'MME.MilkMaid.Level'))
    def test_extraction_is_not_necessarily_net_reduction(self):
        a=self.actor();token=self.ns['Begin'](a,0,None)
        self.store.SetFloatValue(a,'MME.MilkMaid.MilkCount',12)
        self.ns['Complete'](a,token,2,0,0)
        self.assertTrue(self.ns['WasMilkRemoved'](a));self.assertEqual(self.ns['GetLastNetMilkRemoved'](a),-2)
    def test_invalid_counts_and_future_token(self):
        a=self.actor();t=self.ns['Begin'](a,1,None)
        self.ns['Complete'](a,t+1,1,0,0);self.assertEqual(len(self.alarms),1)
        self.ns['Complete'](a,t,-1,0,0);self.assertEqual(len(self.alarms),2)
        self.assertEqual(self.ns['GetLastSession'](a),0)

class Contracts(unittest.TestCase):
    def test_hook_placement_and_original_behavior_preserved(self):
        self.assertEqual(QUEST.count('MMEMilkingSource.Begin('),1)
        self.assertEqual(QUEST.count('MMEMilkingSource.Complete('),1)
        begin=QUEST.index('MMEMilkingSource.Begin(');stop=QUEST.index('sendVibrationEvent("StopMilkingMachine"');complete=QUEST.index('MMEMilkingSource.Complete(')
        self.assertLess(begin,QUEST.index('sendVibrationEvent("StartMilkingMachine"'))
        self.assertLess(stop,complete)
        self.assertLess(complete,QUEST.index('ModEvent.Create("MME_MilkingDone")'))
        self.assertNotRegex(SOURCE,r'RegisterFor|Utility.Wait|Debug.Notification|SkyrimNetApi|AssignSlot')
        writes=re.findall(r'StorageUtil\.(?:Set|Unset)\w+\(target, "([^"]+)"',SOURCE)
        self.assertTrue(writes);self.assertTrue(all(k.startswith('MME.Source.') for k in writes))
        self.assertIn('MMELog.MasterDiagnostic',SOURCE);self.assertIn('MMELog.Alarm',SOURCE)
        self.assertIn('>= 60.0',SOURCE)
        self.assertGreater(SOURCE.index('SetIntValue(target, "MME.Source.Active", sessionId)'),SOURCE.index('SetFloatValue(target, "MME.Source.Before"'))
        self.assertGreater(SOURCE.index('SetIntValue(target, "MME.Source.LastSession", sessionId)'),SOURCE.index('SetFormValue(target, "MME.Source.LastEquipment"'))
        dwemer=(ROOT/'Source/Scripts/MMEDwemerArmor.psc').read_text()
        self.assertIn('Return \"MMEExtensions.DwemerArmor.InProgress\"',dwemer)
        self.assertIn('MMEExtensions.DwemerArmor.InProgress',SOURCE)

if __name__=='__main__':unittest.main()
