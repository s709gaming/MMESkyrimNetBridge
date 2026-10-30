"""Source/data integration guards; in-game acceptance is explicitly separate."""
import json,re,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class DashboardContracts(unittest.TestCase):
    def test_catalog_covers_authored_sources(self):
        header=(ROOT/'include/NarrationCatalog.h').read_text(encoding='utf-8')
        catalog=json.loads(''.join(re.findall(r'R"MMECATALOG\((.*?)\)MMECATALOG"',header,re.S)))['entries']
        self.assertEqual(len(catalog),131)
        self.assertEqual(sum(k.startswith('Pools.') for k in catalog),57)
        schema=json.loads((ROOT/'tools/narration-schema.json').read_text())
        self.assertEqual({k for k in catalog if not k.startswith('Pools.')},{f'{f}.{k}' for f,rs in schema.items() for k in rs})
        for key,meta in catalog.items():
            value=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts'/meta['file']).read_text(encoding='utf-8-sig'))
            for component in meta['path']:value=value[component]
            self.assertEqual(value,meta['default'],key)
            for template in value if isinstance(value,list) else [value]:
                self.assertLessEqual(len(template.encode('utf-8')),8192)
                seen={('actor' if meta['aliases'] and t in ('ACTOR','ActorName') else t) for t in re.findall(r'\{([^{}]+)\}',template)}
                self.assertTrue(set(meta['required'])<=seen<=set(meta['allowed']),key)
        self.assertFalse(any('openingStory' in k or 'closingStory' in k for k in catalog))
    def test_every_direct_pool_reader_is_integrated(self):
        for name in ('MMEThoughts','MMEMilkCravings','MMEArousalEffects','MMEBreastBounceEffects','MMEAlertsController','MMEDwemerEffects','MMETentacleEffects','MMENPCDrinkDialogue','MMEServiceArmorReminder'):
            text=(ROOT/f'Source/Scripts/{name}.psc').read_text(encoding='utf-8-sig')
            self.assertIn('MMENarrationOverrides.Pool(',text,name)
        for name in ('MMETextPool','MMEStoryPopup','MMETimedArmorLock'):
            self.assertIn('MMENarrationOverrides.PersonalPool(', (ROOT/f'Source/Scripts/{name}.psc').read_text(encoding='utf-8-sig'))
        native=(ROOT/'src/NarrationStore.cpp').read_text()
        self.assertIn('published_',native)
        body=native.split('std::vector<std::string> Store::Values',1)[1].split('bool Store::HasPools',1)[0]
        self.assertNotRegex(body,r'\bRead\(|Bases\(|FileLock|Commit\(')
    def test_diagnostics_are_gated_and_sparse(self):
        helper=(ROOT/'Source/Scripts/MMENarrationOverrides.psc').read_text()
        trace=helper.split('Function TraceSource',1)[1]
        self.assertIn('"enablePapyrusTrace", 0',trace)
        self.assertNotIn('enableVerbosePapyrusLogging',trace)
        self.assertIn('StorageUtil.GetStringValue(subject, reportKey',trace)
        self.assertIn('MMELog.MasterDiagnostic',trace)
        self.assertNotRegex(helper,r'Debug\.(Trace|Notification|MessageBox)|Utility.Wait|RegisterForUpdate')
        ui=(ROOT/'fomod/choices/maid-roster-ui/Source/Scripts/MMEMaidRosterUI.psc').read_text()
        self.assertIn('If summary != "transport"',ui)
        self.assertIn('EditorAlarm(summary, StringUtil.Substring(summary, failure))',ui)
    def test_no_optional_dependency_or_automatic_json_writer(self):
        helper=(ROOT/'Source/Scripts/MMENarrationOverrides.psc').read_text()
        self.assertNotRegex(helper,r'JsonUtil\.(?:Save|Set\w+|Unload|Load)\(|SkyrimNetApi|SexLabFramework|Magelight\.')
        declarations=(ROOT/'Source/Scripts/MMEExtensionsNative.psc').read_text()
        registrations=(ROOT/'src/Plugin.cpp').read_text()
        for name in ('GetNarrationOverrideValues','HasNarrationPoolOverrides','GetNarrationRevision'):
            self.assertIn(name,declarations);self.assertIn('"'+name+'", "MMEExtensionsNative"',registrations)
        page=(ROOT/'fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster/dashboard.js').read_text()
        self.assertNotRegex(page,r'\beval\(|innerHTML|setInterval\(|requestAnimationFrame\(')
        self.assertIn('4096',page);self.assertIn("rpc('saveBatch'",page)
if __name__=='__main__':unittest.main()
