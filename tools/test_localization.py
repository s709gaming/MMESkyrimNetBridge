"""Russian installer/data contracts; no game or installed files are changed."""
import sys,json,re,unittest,xml.etree.ElementTree as ET
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/'localization'))
from common import ROOT,records,fields,is_text,decode
from inventory import catalog
RU=ROOT/'fomod/choices/russian'
class Localization(unittest.TestCase):
 def setUp(self):
  self.tr=json.loads((RU/'core/SKSE/Plugins/StorageUtilData/MMEAlerts/Localization/ru.json').read_text(encoding='utf-8'))['strings']
 def test_placeholder_and_encoding_integrity(self):
  for english,russian in self.tr.items():
   with self.subTest(key=english[:60]):
    self.assertTrue(russian.strip());self.assertNotIn('???',russian)
    self.assertNotRegex(russian,r'ZX(?:PH|ROW)\d')
    self.assertEqual(sorted(re.findall(r'\{[^{}]+\}|<[^>]+>',english)),sorted(re.findall(r'\{[^{}]+\}|<[^>]+>',russian)))
 def test_compiled_display_lookup_coverage(self):
  for folder in ['Source','fomod/choices/ostim-only/Source','fomod/choices/estrus-unified']:
   for p in (ROOT/folder).rglob('*.psc'):
    for value in re.findall(r'MMELocalization.Text\(("(?:\\.|[^"\\])*")\)',p.read_text(encoding='utf-8-sig')):
     self.assertIn(decode(value),self.tr,str(p))
 def test_plugin_changes_are_text_only(self):
  for original,group in [('MMEAlert.esp','core'),('fomod/choices/maid-roster-ui/MME Extensions - Maid Roster.esp','roster'),('fomod/choices/milk-leaks/MME Extensions - Milk Leaks.esp','leaks'),('fomod/choices/elsie-compatibility/MME Extensions - Elsie LaVache Fix.esp','elsie')]:
   p=ROOT/original;a=list(records(p.read_bytes()));b=list(records((RU/group/p.name).read_bytes()));self.assertEqual(len(a),len(b))
   changed=0
   for (sig,h,body),(sig2,h2,body2) in zip(a,b):
    self.assertEqual(sig,sig2);self.assertEqual(h[8:],h2[8:])
    f1=list(fields(body));f2=list(fields(body2));self.assertEqual([x[0] for x in f1],[x[0] for x in f2])
    for (field,value),(_,value2) in zip(f1,f2):
     if is_text(sig,field):
      english=value.rstrip(b'\0').decode('utf-8');self.assertEqual(value2.rstrip(b'\0').decode('utf-8'),self.tr.get(english,english));changed+=value!=value2
     else:self.assertEqual(value,value2,(original,sig,field))
   self.assertGreater(changed,0)
 def test_catalog_defaults_and_paths(self):
  defaults=json.loads((RU/'core/SKSE/Plugins/StorageUtilData/MMEAlerts/Localization/ru.catalog.json').read_text(encoding='utf-8'));cat=catalog()
  self.assertEqual(set(defaults),set(cat))
  for id,meta in cat.items():
   value=defaults[id]
   if meta['default'] is None:self.assertIsNone(value);continue
   self.assertEqual(type(value),type(meta['default']))
   if meta.get('optionalTier'):continue
   data=json.loads((RU/'core/SKSE/Plugins/StorageUtilData/MMEAlerts'/meta['file']).read_text(encoding='utf-8'))
   for key in meta['path']:data=data[key]
   self.assertEqual(data,value)
 def test_installer_optional_payloads(self):
  root=ET.parse(ROOT/'fomod/ModuleConfig.xml').getroot()
  group=root.find(".//group[@name='In-game language']");self.assertEqual(group.get('type'),'SelectExactlyOne')
  self.assertEqual(group.find("./plugins/plugin[@name='English']/typeDescriptor/type").get('name'),'Recommended')
  for pattern in root.findall('./conditionalFileInstalls/patterns/pattern'):
   folders=pattern.findall('./files/folder')
   for folder in folders:
    if 'russian' not in folder.get('source',''):continue
    deps=pattern.findall('./dependencies/flagDependency')
    self.assertEqual(len(deps),2);self.assertTrue(any(d.get('flag')=='mmeLanguage' and d.get('value')=='ru' for d in deps))
    self.assertGreaterEqual(int(folder.get('priority')),100)
    self.assertTrue((ROOT/folder.get('source')).is_dir())
 def test_no_personal_data_in_payload(self):
  for p in RU.rglob('*'):
   self.assertNotIn(p.name.lower(),['settings.json','narrationoverrides.json','task.md'])
   self.assertNotIn('presets',p.parts)
if __name__=='__main__':unittest.main()
