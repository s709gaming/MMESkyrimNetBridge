"""Narration data/transport regression checks; live Papyrus acceptance is separate."""
import hashlib,json,re,unittest
from pathlib import Path
import generate_narration_defaults as defaults
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/Narration'

def render(template, values):
    # Test oracle: replacement values are never parsed as new placeholders.
    return re.sub(r'\{([^{}]+)\}',lambda m:values.get('actor' if m[1] in ('ACTOR','ActorName') else m[1],'<MISSING>'),template)

class NarrationContracts(unittest.TestCase):
    def setUp(self):
        self.source=(ROOT/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text(encoding='utf-8-sig')
        self.helper=(ROOT/'Source/Scripts/MMENarrationText.psc').read_text(encoding='utf-8-sig')
        self.schema=json.loads((ROOT/'tools/narration-schema.json').read_text(encoding='utf-8-sig'))
        self.data={p.stem:json.loads(p.read_text(encoding='utf-8-sig')) for p in DATA.glob('*.json')}
    def test_baseline_prose_and_supplied_values(self):
        fixture=json.loads((ROOT/'tools/narration-baseline-contracts.json').read_text(encoding='utf-8-sig'))
        for row in fixture['extracted']:
            text=self.data[row['file']]['routes'][row['key']]['template']
            self.assertEqual(hashlib.sha256(text.encode()).hexdigest(),row['sha256'],row['key'])
            call=f'MMENarrationText.Text("{row["file"]}", "{row["key"]}"'
            for token,var in row['args']:call+=f', "{token}", {var}'
            self.assertIn(call+')',self.source)
        for row in fixture['promptAndSummary']:
            text=self.data[row['file']]['routes'][row['key']]['template']
            self.assertEqual(hashlib.sha256(text.encode()).hexdigest(),row['sha256'],row['key'])
        for name,calls in fixture['nativeCalls'].items():
            self.assertEqual(re.findall(r'SkyrimNetApi\.'+name+r'\([^\n]*',self.source),calls,name)
    def test_legacy_mappings_and_defaults(self):
        for row in json.loads((ROOT/'tools/narration-legacy-map.json').read_text(encoding='utf-8-sig')):
            old=json.loads((DATA.parent/(row['legacyFile']+'.json')).read_text(encoding='utf-8-sig'))
            self.assertEqual(self.data[row['file']]['routes'][row['key']]['template'],old[row['legacyKey']])
        for file,routes in self.schema.items():
            self.assertEqual(set(routes),set(self.data[file]['routes']))
            for route,meta in routes.items():
                value=self.data[file]['routes'][route]['template']
                for text in value if isinstance(value,list) else [value]:
                    self.assertEqual(defaults.tokens(text),set(meta['tokens']))
                    self.assertFalse(re.search(r'[{}]',re.sub(r'\{[^{}]+\}','',text)))
                    self.assertTrue(text.strip())
    def test_read_only_normal_path_and_single_pass(self):
        normal=self.helper.split('String Function ImportLegacy()',1)[0]
        self.assertNotRegex(normal,r'JsonUtil\.(Save|Set\w+)\(')
        self.assertIn('JsonUtil.Unload(FilePath(fileKey), False, False)',normal)
        self.assertNotRegex(normal,r'Utility\.Wait|RegisterForUpdate|SkyrimNetApi\.|Debug\.Notification')
        self.assertIn('position = closeIndex + 1',normal)
        self.assertIn('output += replacement',normal)
        self.assertIn('If delimiter > position',normal)
        defaults.validate_document({'schemaVersion':1,'routes':{'route':{'template':'Plain instructions.'}}},{'route':{'tokens':[]}},'Fixture')
        self.assertIn('While valid && item < entries.Length',normal)
        self.assertIn('While routeIndex < MMENarrationDefaults.RouteCount(fileKey)',normal)
        for alias in ('actor','ACTOR','ActorName'):
            self.assertEqual(render('{'+alias+'} / {'+alias+'}',{'actor':'A {item} "é›ª"'}),'A {item} "é›ª" / A {item} "é›ª"')
        self.assertEqual(json.loads(json.dumps({'text':render('{actor}\n{item}',{'actor':'é›ª','item':'a "cup"\\'})}))['text'],'é›ª\na "cup"\\')
    def test_prompt_adapters_and_file_packaging(self):
        for decorator in ('mme_milk_lore_text','mme_breastfeeding_guidance_text'):
            self.assertIn('RegisterDecorator("'+decorator+'"',self.source)
        prompts=[p.read_text(encoding='utf-8-sig') for p in (ROOT/'SkyrimNetPrompts').glob('*.prompt')]
        self.assertTrue(any('{{ playerInstructions }}' in p for p in prompts))
        self.assertTrue(any('{{ mme_milk_lore_text(actorUUID) }}' in p for p in prompts))
        self.assertTrue(any('{{ mme_breastfeeding_guidance_text(actorUUID) }}' in p for p in prompts))
        build=(ROOT/'build-package.ps1').read_text(encoding='utf-8-sig')
        self.assertIn('MMEAlerts\\Narration',build)
        for helper in ('MMENarrationText','MMENarrationDefaults'):self.assertIn('"'+helper+'"',build)
        self.assertTrue((DATA/'EditingGuide.txt').is_file())
    def test_invalid_templates_are_rejected(self):
        schema={'route':{'tokens':['actor']}}
        for value in ('', '   ', [], 12, None, ['{actor}', 1], '{unknown}', 'hello', '{{actor}}', '{actor}}', '{actor} {unclosed'):
            with self.subTest(value=value),self.assertRaises(ValueError):
                defaults.validate_document({'schemaVersion':1,'routes':{'route':{'template':value}}},schema,'Fixture')
        for value in ('{actor} / {actor}', '{ACTOR}', '{ActorName}', ['{actor} says "?"\\']):
            defaults.validate_document({'schemaVersion':1,'routes':{'route':{'template':value}}},schema,'Fixture')
        with self.assertRaises(ValueError):defaults.validate_document({'schemaVersion':2,'routes':{}},schema,'Fixture')
        with self.assertRaises(json.JSONDecodeError):json.loads('{"routes":')
        self.assertIn('!SameText(values[index]',self.helper)
        self.assertIn('Bool saved = JsonUtil.Save',self.helper)
        self.assertIn('If verified',self.helper)
    def test_duplicate_keys_rejected(self):
        with self.assertRaises(ValueError):json.loads('{"x":1,"x":2}',object_pairs_hook=defaults.unique)

if __name__=='__main__':unittest.main()
