"""Execute the actual Papyrus wording facade; source checks complement runtime QA."""
import json
from pathlib import Path
import re
from types import SimpleNamespace as NS
import unittest
from test_tentacle_tiers import translate

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT/'Source/Scripts/MMEFlavorText.psc').read_text(encoding='utf-8')
INVENTORY = json.loads((ROOT/'docs/Remaining-Flavor-JSON-Inventory.json').read_text(encoding='utf-8'))['entries']

class FacadeTests(unittest.TestCase):
    def setUp(self):
        self.personal = []
        self.base = ['{actor} meets {armorName}.']
        self.calls = []; self.alarms = []; self.sources = []; self.rolls = []
        self.exists = True; self.good = True; self.member = True
        def roll(low,high): self.rolls.append((low,high)); return high
        self.ns = {
            'StringUtil': NS(GetLength=len,Find=lambda text,needle,start=0:text.find(needle,start), Substring=lambda text,start,length=0:text[start:start+length] if length else text[start:]),
            'MMENarrationOverrides': NS(PersonalPool=lambda *args:self.personal,TraceSource=lambda *args:self.sources.append(args)),
            'JsonUtil': NS(JsonExists=lambda f:self.exists,IsGood=lambda f:self.good,GetErrors=lambda f:'test parse failure',IsPathObject=lambda f,path:path=='.',IsPathArray=lambda *args:isinstance(self.base,list) and self.member,PathCount=lambda *args:len(self.base),IsPathString=lambda *args:isinstance(self.base[0],str),GetPathStringValue=lambda *args:self.base[0]),
            'Utility': NS(RandomInt=roll),
            'IsBlank': lambda text:not text.strip(),
            'HasCanonicalMember': lambda *args:self.member,
            'Entry': lambda f,p,i,ordinary:self.base[i] if isinstance(self.base[i],str) else '',
            'ReportFailure': lambda *args:self.alarms.append(args),
            'Report': lambda *args: self.alarms.append(args),
            'CanonicalToken': lambda token: {'ACTOR':'actor','ActorName':'actor'}.get(token,token),
        }
        picker=(ROOT/'Source/Scripts/MMETextPool.psc').read_text(encoding='utf-8')
        picker=re.sub(r'^\s*MMELog.MasterDiagnostic\(.*$', '', picker, flags=re.M)
        exec(translate('Pick','fileName,pool,fallbackText,subject,sourceLabel',picker),self.ns)
        def pick(*args): self.calls.append(args); return self.ns['Pick'](*args)
        self.ns['MMETextPool']=NS(IsBlank=self.ns['IsBlank'],Pick=pick,ReportFailure=self.ns['ReportFailure'])
        renderer=(ROOT/'Source/Scripts/MMENarrationText.psc').read_text(encoding='utf-8')
        exec(translate('Render','value,k1="",v1="",k2="",v2="",k3="",v3="",k4="",v4="",k5="",v5="",k6="",v6=""',renderer),self.ns)
        self.ns['MMENarrationText']=NS(Render=self.ns['Render'])
        for name,params in [('Select','pool,subject'),('ValidTemplate','template,k1="",k2=""'),('Text','pool,fallbackText,subject=None,k1="",v1="",k2="",v2=""')]:
            exec(translate(name,params,SOURCE),self.ns)
    def text(self):
        return self.ns['Text']('test','ORIGINAL {literal name}', 'NPC','actor','Maid {literal}','armorName','Armor } Snow')
    def test_single_base_no_random_picker_and_names_not_reparsed(self):
        self.assertEqual(self.text(),'Maid {literal} meets Armor } Snow.')
        self.assertFalse(self.calls)
        self.assertFalse(self.rolls)
        self.assertEqual(self.sources[0][1],'base')
    def test_single_personal_wins_without_random_picker(self):
        self.personal=['{armorName} greets {actor}.']
        self.assertEqual(self.text(),'Armor } Snow greets Maid {literal}.')
        self.assertFalse(self.calls)
    def test_multi_variant_uses_existing_picker(self):
        self.base=['{actor} / {armorName}','{armorName} / {actor}']
        self.assertEqual(self.text(),'Armor } Snow / Maid {literal}')
        self.assertEqual(len(self.calls),1)
    def test_missing_pool_and_optional_native_absence_fall_back(self):
        self.base=[]
        self.assertEqual(self.text(),'ORIGINAL {literal name}')
        self.assertEqual(self.sources[-1][1],'compiled fallback')
    def test_file_failures_and_wrong_types(self):
        for base,exists,good in [([],False,True),([],True,False),('wrong type',True,True),([None,5],True,True)]:
            with self.subTest(base=base,exists=exists,good=good):
                self.base=base;self.exists=exists;self.good=good
                self.assertEqual(self.text(),'ORIGINAL {literal name}')
                self.assertTrue(self.alarms)
    def test_multi_personal_and_mixed_base(self):
        self.personal=['{actor} / {armorName}','{armorName} / {actor}']
        self.assertEqual(self.text(),'Armor } Snow / Maid {literal}')
        self.assertEqual(self.rolls[-1],(0,1))
        self.personal=[];self.base=[None,'{actor} / {armorName}',5,'{armorName} / {actor}']
        self.assertEqual(self.text(),'Armor } Snow / Maid {literal}')
        self.assertTrue(any('invalid entries skipped' in a for a in self.alarms))
    def test_invalid_templates_preserve_original(self):
        for template in ['{actor}', '{armorName}', '{actor} {armorName} {unknown}', '{actor} {armorName}}', '{{actor}} {armorName}', '{actor} {armorName', '   ']:
            with self.subTest(template=template):
                self.base=[template]
                self.assertEqual(self.text(),'ORIGINAL {literal name}')
    def test_literal_and_numeric_contracts(self):
        valid=self.ns['ValidTemplate']
        self.assertTrue(valid('Plain text'))
        self.assertTrue(valid('For {hours} hours: {levels} levels.','hours','levels'))
        self.assertFalse(valid('For some hours: {levels} levels.','hours','levels'))
        self.assertFalse(valid('Plain {unknown} text'))
    def test_actor_context_reaches_resolver_and_failure(self):
        self.base=['{actor} {unknown}']
        self.text()
        self.assertEqual(self.alarms[-1][2],'NPC')
        self.assertEqual(self.sources[-1][-1],'NPC')

class InventoryTests(unittest.TestCase):
    def test_schema_defaults_and_exact_26_bindings(self):
        config=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/FlavorNotifications.json').read_text(encoding='utf-8'))
        schema=json.loads((ROOT/'tools/flavor-notification-schema.json').read_text(encoding='utf-8'))
        self.assertEqual(len(config),26)
        self.assertEqual(set(config),set(schema))
        self.assertEqual(sum(e['minor'] for e in INVENTORY),17)
        for e in INVENTORY:
            key=e['proposedId'].split('.')[-1]
            self.assertEqual(config[key],[e['proposedTemplate']])
            self.assertEqual(schema[key]['required'],e['requiredTokens'])
            source=(ROOT/e['source']).read_text(encoding='utf-8')
            matching=[line for line in source.splitlines() if 'MMEFlavorText.Text("'+key+'",' in line]
            self.assertEqual(len(matching),1,key)
            original=e['originalExpression'][len('Debug.Notification('):-1]
            self.assertIn(original,matching[0],key+' retains original rendered fallback')
        self.assertNotRegex(SOURCE,r'JsonUtil\.(Save|Set\w+)|RegisterFor|Utility\.Wait|MilkQUEST|SkyrimNetApi')

if __name__=='__main__':unittest.main()
