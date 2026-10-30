"""Roster isolation, packaging, data-read and callback contracts; runtime UI is separate."""
from pathlib import Path
import hashlib,json,re,subprocess,unittest,xml.etree.ElementTree as ET
import shutil,tempfile
ROOT=Path(__file__).resolve().parents[1]
CHOICE=ROOT/'fomod/choices/maid-roster-ui'
class RosterContracts(unittest.TestCase):
 def test_isolated_optional_install(self):
  root=ET.parse(ROOT/'fomod/ModuleConfig.xml').getroot();group=next(g for g in root.findall('.//group') if g.get('name')=='Optional Milk Maid UI')
  self.assertEqual(group.get('type'),'SelectAny');plugin=group.find('plugins/plugin');self.assertEqual(plugin.find('typeDescriptor/type').get('name'),'Optional');self.assertEqual(plugin.find('files/folder').get('source'),'fomod/choices/maid-roster-ui')
  mcm=(ROOT/'Source/Scripts/MMEAlertsMCM.psc').read_text(encoding='utf-8-sig');self.assertFalse(re.search(r'\bMagelight\.|\bMMEMaidRosterUI\b',re.sub(r'"(?:\\.|[^"\\])*"|;[^\n]*','',mcm)), 'Core MCM must not call optional UI types');self.assertIn('MMEExtensions_RosterOpen',mcm);self.assertIn('maidRosterMigration160',mcm);self.assertIn('AddKeyMapOption',mcm)
 def test_safe_actions_and_identity(self):
  mcm=(ROOT/'Source/Scripts/MMEAlertsMCM.psc').read_text(encoding='utf-8-sig')
  availability=mcm.split('Bool Function RosterUiAvailable()',1)[1].split('EndFunction',1)[0]
  self.assertIn('Game.GetModByName("MME Extensions - Maid Roster.esp") != 255',availability)
  source=(CHOICE/'Source/Scripts/MMEMaidRosterUI.psc').read_text(encoding='utf-8-sig')
  self.assertNotRegex(source,r'\.Cast\(|\.Milking\(|setMilk|updateMilk|calculateMilk|Utility\.Wait|JsonUtil\.(?:Save|Set)')
  self.assertIn('String playerJson = "0"',source);self.assertIn('String availableJson = "0"',source);self.assertNotRegex(source,r'(?:playerJson|availableJson) = "(?:true|false)"')
  self.assertIn('Magelight.BindHotkey(ViewId, BoundKey, 1)',source);self.assertIn('Magelight.BindHotkey(ViewId, BoundKey, 0)',source);self.assertIn('now - LastCloseTime < 0.35',source)
  self.assertIn('SnapshotActors[rowIndex] as Actor',source);self.assertIn('rowToken[0] != (SnapshotRevision as String)',source);self.assertIn('RegisterForSingleUpdate(0.1)',source)
  self.assertIn('Actor[] maids = milkController.MilkMaid',source);self.assertIn('seen.Find(candidate) < 0',source);self.assertIn('scanIndex < maids.Length',source);self.assertNotIn('MME_Storage.getMilkMaximum(candidate)',source);self.assertIn('StorageUtil.GetFloatValue(candidate, "MME.MilkMaid.MilkMaximum", 0.0)',source);self.assertIn('maids.Length > 0',source);self.assertNotIn('maids != None',source);self.assertNotIn('SnapshotActors == None',source)
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
  self.assertEqual(hashlib.sha256((CHOICE/'Magelight/mmeextensions/views/roster/dashboard.js').read_bytes()).hexdigest().lower(),data['dashboardSHA256'].lower())
  self.assertFalse(list((CHOICE/'Scripts').glob('Magelight.*')))
 def test_optional_arousal_read_boundary(self):
  source=(CHOICE/'Source/Scripts/MMEMaidRosterUI.psc').read_text(encoding='utf-8-sig')
  support=source.split('Bool Function ArousalReaderAvailable()',1)[1].split('EndFunction',1)[0]
  self.assertIn('If !MMEArousalBridge.IsAvailable()',support)
  self.assertIn('readerQuest != None || readerFaction != None',support)
  scan=source.split('String arousalJson = "null"',1)[1].split('rows +=',1)[0]
  self.assertIn('If arousalReadable',scan);self.assertIn('!candidate.IsDead() && !candidate.IsDisabled()',scan)
  self.assertEqual(source.count('MMEArousalBridge.GetCurrentArousal(candidate)'),1)
  self.assertIn('arousalKnown += 1',scan);self.assertIn('arousalUnknown += 1',scan)
  self.assertNotRegex(source,r'UpdateActorExposure|ApplyArousal|slaFrameworkScr|OSLArousedNative')
  pex=(CHOICE/'Scripts/MMEMaidRosterUI.pex').read_bytes().lower()
  self.assertIn(b'mmearousalbridge',pex)
  for dependency in [b'slaframeworkscr',b'oslarousednative',b'sexlabframework']:
   self.assertNotIn(dependency,pex)
  self.assertFalse((CHOICE/'Source/Scripts/MMEArousalBridge.psc').exists())
  self.assertFalse((CHOICE/'Scripts/MMEArousalBridge.pex').exists())
 def test_real_frontend(self):
  subprocess.run(['node',str(ROOT/'tools/test_maid_roster_page.cjs'),str(CHOICE/'Magelight/mmeextensions/views/roster/index.html')],check=True)
 def test_compiled_array_guards(self):
  assembler=Path('E:/Steam/steamapps/common/Skyrim Special Edition/Papyrus Compiler/PapyrusAssembler.exe')
  with tempfile.TemporaryDirectory(prefix='MME-Roster-Array-') as folder:
   shutil.copy2(CHOICE/'Scripts/MMEMaidRosterUI.pex',folder)
   subprocess.run([str(assembler),'MMEMaidRosterUI','-D','-Q'],cwd=folder,check=True,capture_output=True)
   arrays=set()
   for line in (Path(folder)/'MMEMaidRosterUI.disassemble.pas').read_text(encoding='utf-8-sig').splitlines():
    if re.match(r'\s*\.function\s',line):arrays=set()
    match=re.match(r'\s*\.(?:local|param)\s+(\S+)\s+\S+\[\]',line)
    if match:arrays.add(match[1])
    match=re.match(r'\s*Cast\s+(\S+)\s+None(?:\s|$)',line)
    if match:self.assertNotIn(match[1],arrays,line)
if __name__=='__main__':unittest.main()
