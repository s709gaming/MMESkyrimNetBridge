"""Execute the actual pure Papyrus probability function with Python arithmetic.

The deliberately small translator rejects unsupported constructs. Integration
contracts below complement this; they do not claim Skyrim runtime acceptance.
"""
import itertools
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT/'Source/Scripts/MMETentacleTiers.psc').read_text()

def translate(name, parameters, source=SOURCE):
    body = source.split('Function '+name+'(', 1)[1].split('\n', 1)[1].split('EndFunction', 1)[0]
    lines = [f'def {name}({parameters}):']
    indent = 1
    for raw in body.splitlines():
        text = raw.split(';', 1)[0].strip()
        if not text or text.startswith('Trace('):
            continue
        if text in ('EndIf', 'EndWhile'):
            indent -= 1
            continue
        if text.startswith(('ElseIf ', 'Else')):
            indent -= 1
        text = re.sub(r'^(Int|Float|Bool|Actor|MilkQUEST|String)(\[\])? ', '', text)
        text = re.sub(r'new (?:Int|Float)\[(\d+)\]', r'[0] * \1', text)
        text = re.sub(r'^(\w+(?:\[\w+\])?) = (\w+) as Int$', r'\1 = int(\2)', text)
        text = text.replace(' as Float', '').replace('&&', ' and ').replace('||', ' or ')
        text = text.replace(' as Actor', '').replace(' as Armor', '').replace(' as MilkQUEST', '')
        text = re.sub(r'!(?!=)', 'not ', text).replace('.Length', '.__len__()')
        if text.startswith('requested ='):
            text = 'requested = int('+text.split('=',1)[1]+')'
        keyword = text.split(' ', 1)[0]
        if keyword in ('If', 'ElseIf', 'While'):
            text = {'If':'if','ElseIf':'elif','While':'while'}[keyword] + ' ' + text.split(' ',1)[1] + ':'
        elif text == 'Else':
            text = 'else:'
        elif text.startswith('Return '):
            text = 'return ' + text[7:]
        elif text == 'Return':
            text = 'return'
        if ' as ' in text or re.search(r'\b(?:new|EndIf|EndWhile)\b', text):
            raise AssertionError('Unsupported Papyrus in probability test: '+text)
        lines.append('    '*indent + text)
        if text.endswith(':'):
            indent += 1
    return '\n'.join(lines)

namespace = {}
exec(translate('DefaultChance','tier'), namespace)
exec(translate('Balance','weights, edited=-1, requested=0'), namespace)
balance = namespace['Balance']

class Memory:
    def __init__(self): self.values={};self.lists={}
    def GetFloatValue(self,actor,key,default=0): return self.values.get((actor,key),default)
    GetIntValue=GetFloatValue
    def SetFloatValue(self,actor,key,value): self.values[actor,key]=value
    SetIntValue=SetFloatValue
    def AdjustIntValue(self,actor,key,amount):
        value=self.GetIntValue(actor,key)+amount
        self.SetIntValue(actor,key,value)
        return value
    def UnsetFloatValue(self,actor,key): self.values.pop((actor,key),None)
    def FormListCount(self,actor,key): return len(self.lists.get((actor,key),[]))
    def FormListHas(self,actor,key,value): return value in self.lists.get((actor,key),[])
    def FormListAdd(self,actor,key,value,duplicates):
        items=self.lists.setdefault((actor,key),[])
        if duplicates or value not in items: items.append(value)
    def FormListGet(self,actor,key,index): return self.lists[actor,key][index]
    def FormListRemoveAt(self,actor,key,index): self.lists[actor,key].pop(index)
    def FormListRemove(self,actor,key,value,all):
        self.lists[actor,key]=[x for x in self.lists.get((actor,key),[]) if x!=value]

class ActorSnapshot(list):
    def Find(self,actor):
        try: return self.index(actor)
        except ValueError: return -1

class Wearer:
    def __init__(self,armor=2): self.armor=armor;self.distance=100;self.loaded=True;self.dead=False
    def Is3DLoaded(self): return self.loaded
    def IsDead(self): return self.dead
    def GetWornForm(self,mask): return self.armor
    def GetDistance(self,other): return other.distance

class SchedulerTests(unittest.TestCase):
    def setUp(self):
        from types import SimpleNamespace as NS
        self.memory=Memory();self.now=100.;self.intervals=iter([.4,.6,.5,.7,.8,.9]*20)
        self.ns={'Root':lambda:'T.', 'StorageUtil':self.memory,'Interval':lambda:next(self.intervals),
                 'Utility':NS(GetCurrentGameTime=lambda:self.now),
                 'Game':NS(GetPlayer=lambda:Wearer()),'Quest':NS(GetQuest=lambda _:object()),
                 'Armor':NS(GetMaskForSlot=lambda _:0),
                 'MMETentacleEffects':NS(IsEnabled=lambda:True,IsValidCandidate=lambda a,q:a is not None and a.loaded and not a.dead and getattr(a,'registered',True)),
                 'MMEArmorScript':NS(ClassifyArmor=lambda q,armor,*_:armor),
                 'Configure':lambda:None,'Complete':lambda _:None}
        for name,args in [('Seed','subject, now, reason'),('Observe','actors'),('NextDue','now'),('ConsumeDue','subject, now'),('Recover','reseed=False')]:
            exec(translate(name,args),self.ns)
        observe=self.ns['Observe']
        self.ns['Observe']=lambda actors:observe(ActorSnapshot(actors))
    def due(self,a): return self.memory.GetFloatValue(a,'T.Due')
    def test_independent_deadlines_and_no_catchup(self):
        a,b=Wearer(),Wearer();self.ns['Observe']([a,b])
        self.assertNotEqual(self.due(a),self.due(b))
        first=self.due(a);self.assertFalse(self.ns['ConsumeDue'](a,first-.01))
        self.assertTrue(self.ns['ConsumeDue'](a,first))
        self.assertFalse(self.ns['ConsumeDue'](a,first))
        self.assertGreater(self.due(a),first)
        self.now=150.;self.ns['Observe']([a,b])
        self.assertTrue(self.ns['ConsumeDue'](a,self.now))
        self.assertFalse(self.ns['ConsumeDue'](a,self.now))
        self.assertGreater(self.due(a),self.now)
        self.assertTrue(self.ns['ConsumeDue'](b,self.now))
        self.assertFalse(self.ns['ConsumeDue'](b,self.now))
    def test_one_hour_due_survives_observation_gap(self):
        # Exact logged failure: still loaded/in range/in armor, >1 game hour
        # between observations, then Observe runs before the due effect check.
        self.intervals=iter([1/24]*20)
        for actor in (Wearer(2),Wearer(3)):
            self.ns['Observe']([actor]);original_due=self.due(actor)
            self.now=original_due+0.05/24
            self.ns['Observe']([actor])
            self.assertEqual(self.due(actor),original_due)
            self.assertTrue(self.ns['ConsumeDue'](actor,self.now))
            self.assertFalse(self.ns['ConsumeDue'](actor,self.now))
    def test_next_deadline_does_not_prune_a_present_overdue_actor(self):
        actor=Wearer();self.intervals=iter([1/24]*20)
        self.ns['Observe']([actor]);original_due=self.due(actor)
        self.now=original_due+0.05/24
        self.assertEqual(self.ns['NextDue'](self.now),original_due)
        self.assertEqual(self.due(actor),original_due)
    def test_repeated_one_hour_cycles_and_large_time_jump(self):
        self.intervals=iter([1/24]*20);actor=Wearer()
        self.ns['Observe']([actor])
        for elapsed_hours in (1.05,1.05,24,1.05):
            self.now+=elapsed_hours/24
            self.ns['Observe']([actor])
            self.assertTrue(self.ns['ConsumeDue'](actor,self.now))
            self.assertFalse(self.ns['ConsumeDue'](actor,self.now))
            self.assertAlmostEqual(self.due(actor),self.now+1/24)
    def test_actual_absence_gets_fresh_deadline_and_no_backlog(self):
        actor,other=Wearer(),Wearer()
        self.ns['Observe']([actor,other])
        self.ns['Observe']([other])
        self.assertEqual(self.due(actor),0)
        self.now+=10
        self.ns['Observe']([actor,other])
        self.assertGreater(self.due(actor),self.now)
        self.assertFalse(self.ns['ConsumeDue'](actor,self.now))
    def test_empty_scan_is_not_evidence_of_absence(self):
        actor=Wearer();self.ns['Observe']([actor]);original_due=self.due(actor)
        self.now+=2
        self.ns['Observe']([])
        self.assertEqual(self.due(actor),original_due)
    def test_load_preserves_future_and_rearms_overdue(self):
        a,b=Wearer(),Wearer();self.ns['Observe']([a,b]);future=self.due(b)
        self.now=100.5;self.ns['Recover']()
        self.assertGreater(self.due(a),self.now);self.assertEqual(self.due(b),future)
    def test_range_unload_and_armor_reentry(self):
        a=Wearer();self.ns['Observe']([a]);a.distance=3000
        self.assertEqual(self.ns['NextDue'](self.now),0)
        self.assertEqual(self.due(a),0)
        a.distance=100;self.ns['Observe']([a]);self.assertGreater(self.due(a),self.now)
        a.armor=1;self.ns['Observe']([a]);self.assertEqual(self.due(a),0)
        a.armor=3;self.ns['Observe']([a]);a.loaded=False
        self.assertEqual(self.ns['NextDue'](self.now),0)
        a.loaded=True;self.ns['Observe']([a]);a.registered=False
        self.assertEqual(self.ns['NextDue'](self.now),0)

class TierTests(unittest.TestCase):
    def test_all_distributions_and_slider_edits(self):
        for low in range(21):
            for medium in range(21-low):
                for high in range(21-low-medium):
                    original = [low*5,medium*5,high*5,(20-low-medium-high)*5]
                    self.assertEqual(balance(original.copy()), original)
                    for edited, units in itertools.product(range(4),range(21)):
                        result = balance(original.copy(),edited,units*5)
                        self.assertEqual(sum(result),100)
                        self.assertEqual(result[edited],units*5)
                        self.assertTrue(all(0<=w<=100 and w%5==0 for w in result))
    def test_corrupt_weights_and_degenerate_distribution(self):
        for weights in ([0]*4,[-40,900,7,3],[1]*4,[100]*4):
            result=balance(list(weights))
            self.assertEqual(sum(result),100)
            self.assertTrue(all(0<=w<=100 and w%5==0 for w in result))
        self.assertEqual(balance([0]*4),[50,30,15,5])
    def test_nonlatent_owned_animation_and_existing_math(self):
        self.assertNotIn('Utility.Wait(',SOURCE)
        self.assertNotIn('RegisterFor',SOURCE)
        self.assertIn('MMEReactionAnimation.StartCustomEvent',SOURCE)
        self.assertIn('MMEReactionAnimation.Reset',SOURCE)
        self.assertIn('"ZaZAPCHorFd"',SOURCE)
        effects=(ROOT/'Source/Scripts/MMETentacleEffects.psc').read_text()
        self.assertIn('MMEMilkBoost.ApplyMilkDrinkBonusForActor(candidate, 1, False, False)',effects)
        self.assertIn('MMEArousalBridge.ApplyConfiguredMilkArousalForActor(candidate, "armor injection", False)',effects)
        self.assertNotIn('TryCreateMilkMaid',SOURCE)
    def test_master_logging_without_diagnostic_hud(self):
        self.assertIn('MMELog.MasterDiagnostic',SOURCE)
        self.assertNotIn('Debug.Notification',SOURCE)
        self.assertNotIn('Debug.Trace',SOURCE)
        report=(ROOT/'Source/Scripts/MMETentacleEffects.psc').read_text().split('Function Report(',1)[1]
        self.assertNotIn('Debug.Notification',report)
    def test_actual_logger_master_verbose_matrix(self):
        from types import SimpleNamespace as NS
        logger=(ROOT/'Source/Scripts/MMELog.psc').read_text()
        for master,verbose in itertools.product((0,1),repeat=2):
            traces=[]
            ns={'JsonUtil':NS(GetIntValue=lambda file,key,default:master if key=='enablePapyrusTrace' else verbose),
                'GetSettingsFile':lambda:'settings', 'Debug':NS(Trace=lambda text,severity:traces.append(text))}
            exec(translate('IsDiagnosticEnabled','',logger),ns)
            exec(translate('MasterDiagnostic','reportText, severity=0',logger),ns)
            ns['MasterDiagnostic']('tier boundary')
            self.assertEqual(traces,['tier boundary'] if master else [])
            self.assertEqual(ns['IsDiagnosticEnabled'](),bool(master and verbose))

if __name__=='__main__':
    unittest.main()
