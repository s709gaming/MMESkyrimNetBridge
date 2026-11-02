"""Source/data integration guards; in-game acceptance is explicitly separate."""
import json,re,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class DashboardContracts(unittest.TestCase):
    def test_catalog_covers_authored_sources(self):
        header=(ROOT/'include/NarrationCatalog.h').read_text(encoding='utf-8')
        catalog=json.loads(''.join(re.findall(r'R"MMECATALOG\((.*?)\)MMECATALOG"',header,re.S)))['entries']
        self.assertEqual(len(catalog),185)
        self.assertEqual(sum(k.startswith('Pools.') for k in catalog),99)
        presentation=json.loads((ROOT/'tools/narration-presentation.json').read_text(encoding='utf-8'))
        self.assertEqual(set(presentation['entries']),set(catalog))
        visible=[m['presentation'] for m in catalog.values() if m['presentation']['visible']]
        self.assertEqual(sum(m['section']=='skyrimnet' for m in visible),63)
        self.assertEqual(sum(m['section']=='messages' for m in visible),86)
        self.assertFalse(catalog['Fullness.nearby_status_summary']['presentation']['visible'])
        self.assertFalse(catalog['MilkDrinking.narrate_n_p_c_milk_drink_3']['presentation']['visible'])
        self.assertEqual(catalog['Pools.MilkCravings.craving']['presentation']['section'],'messages')
        self.assertTrue(catalog['Pools.MilkCravings.craving']['presentation']['shared'])
        lore=sorted((m for m in catalog.items() if m[1]['presentation']['section']=='skyrimnet'),key=lambda row:(row[1]['presentation']['featureOrder'],row[1]['presentation']['order']))
        self.assertEqual([k for k,v in lore[:3]],['Lore.milk_lore','Lore.shared_guidance','Lore.milkmaid_lore'])
        schema=json.loads((ROOT/'tools/narration-schema.json').read_text())
        self.assertEqual({k for k in catalog if not k.startswith('Pools.')},{f'{f}.{k}' for f,rs in schema.items() for k in rs})
        for key,meta in catalog.items():
            if meta.get('optionalTier'):
                self.assertIn(meta['fallbackEntry'],catalog)
                continue
            value=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts'/meta['file']).read_text(encoding='utf-8-sig'))
            for component in meta['path']:value=value[component]
            self.assertEqual(value,meta['default'],key)
            for template in value if isinstance(value,list) else [value]:
                self.assertLessEqual(len(template.encode('utf-8')),8192)
                seen={('actor' if meta['aliases'] and t in ('ACTOR','ActorName') else t) for t in re.findall(r'\{([^{}]+)\}',template)}
                self.assertTrue(set(meta['required'])<=seen<=set(meta['allowed']),key)
        self.assertFalse(any('openingStory' in k or 'closingStory' in k for k in catalog))
    def test_player_facing_help(self):
        presentation=json.loads((ROOT/'tools/narration-presentation.json').read_text(encoding='utf-8'))
        for entry_id,meta in presentation['entries'].items():
            if not meta['visible']:continue
            copy=meta['description']+' '+meta.get('note','')
            self.assertNotRegex(copy,r'\b(?:HUD|caller|runtime|dispatch|branch|code-owned|chestCurseStories|renderedReaction|ReleaseInternal)\b',entry_id)
            self.assertNotIn('Customize the wording Skyrim.Net receives for:',copy,entry_id)
        dashboard=(ROOT/'fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster/dashboard.js').read_text(encoding='utf-8')
        self.assertNotIn('\u00c2',dashboard)
        self.assertNotIn('\u00e2\u20ac',dashboard)
        self.assertIn('Keep these placeholders:',dashboard)
        self.assertIn('Using shared text',dashboard)
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
