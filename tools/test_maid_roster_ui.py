"""Roster isolation, packaging, data-read and callback contracts; runtime UI is separate."""
from pathlib import Path
import hashlib,json,re,subprocess,unittest,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
CHOICE=ROOT/'fomod/choices/maid-roster-ui'
class RosterContracts(unittest.TestCase):
 def test_isolated_optional_install(self):
  root=ET.parse(ROOT/'fomod/ModuleConfig.xml').getroot();group=next(g for g in root.findall('.//group') if g.get('name')=='Optional Milk Maid UI')
  self.assertEqual(group.get('type'),'SelectAny');plugin=group.find('plugins/plugin');self.assertEqual(plugin.find('typeDescriptor/type').get('name'),'Optional');self.assertEqual(plugin.find('files/folder').get('source'),'fomod/choices/maid-roster-ui')
  mcm=(ROOT/'Source/Scripts/MMEAlertsMCM.psc').read_text(encoding='utf-8-sig');self.assertFalse(re.search(r'\bMagelight\.|\bMMEMaidRosterUI\b',re.sub(r'"(?:\\.|[^"\\])*"|;[^\n]*','',mcm)), 'Core MCM must not call optional UI types');self.assertIn('MMEExtensions_RosterOpen',mcm);self.assertIn('maidRosterMigration160',mcm);self.assertIn('AddKeyMapOption',mcm)
 def test_read_only_and_safe_identity(self):
  source=(CHOICE/'Source/Scripts/MMEMaidRosterUI.psc').read_text(encoding='utf-8-sig')
  self.assertNotRegex(source,r'\.Cast\(|\.Milking\(|setMilk|updateMilk|calculateMilk|RegisterFor(?:Single)?Update|Utility\.Wait|JsonUtil\.(?:Save|Set)')
  self.assertIn('Actor[] maids = milkController.MilkMaid',source);self.assertIn('seen.Find(candidate) < 0',source);self.assertIn('scanIndex < maids.Length',source);self.assertNotIn('MME_Storage.getMilkMaximum(candidate)',source);self.assertIn('StorageUtil.GetFloatValue(candidate, "MME.MilkMaid.MilkMaximum", 0.0)',source);self.assertIn('maids != None && maids.Length > 0',source)
  self.assertIn('requestGeneration == Generation && requestView == ViewId',source);self.assertIn('RegisterForMenu("Journal Menu")',source);self.assertIn('SKSE.GetPluginVersion("Magelight") < 0',source);self.assertIn('MMELog.MasterDiagnostic',source);self.assertIn('MMELog.Alarm',source)
  for script in ['MMEMaidRosterUI','MMEMaidRosterPlayerAlias']:
   pex=(CHOICE/f'Scripts/{script}.pex').read_bytes().lower()
   self.assertNotIn(b'sexlabframework',pex);self.assertNotIn(b'skyrimnetapi',pex)
 def test_manifest_pairs(self):
  data=json.loads((CHOICE/'BuildManifest.json').read_text(encoding='utf-8-sig'));self.assertFalse(data['runtimeValidated']);self.assertEqual(len(data['pairs']),2)
  for pair in data['pairs']:
   for folder,extension,field in [('Source/Scripts','psc','sourceSHA256'),('Scripts','pex','compiledSHA256')]:
    self.assertEqual(hashlib.sha256((CHOICE/f'{folder}/{pair["script"]}.{extension}').read_bytes()).hexdigest().lower(),pair[field].lower())
  self.assertEqual(hashlib.sha256((CHOICE/'MME Extensions - Maid Roster.esp').read_bytes()).hexdigest().lower(),data['pluginSHA256'].lower())
  self.assertEqual(hashlib.sha256((CHOICE/'Magelight/mmeextensions/views/roster/index.html').read_bytes()).hexdigest().lower(),data['pageSHA256'].lower())
  self.assertFalse(list((CHOICE/'Scripts').glob('Magelight.*')))
 def test_real_frontend(self):
  subprocess.run(['node',str(ROOT/'tools/test_maid_roster_page.cjs'),str(CHOICE/'Magelight/mmeextensions/views/roster/index.html')],check=True)
if __name__=='__main__':unittest.main()
