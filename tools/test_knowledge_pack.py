"""Validate the shipped general lore and the boundary with legacy request text."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'SkyrimNet25/s709gaming.mme-extensions/knowledge/Skyrim_Milk_Maid_Lore.sknpack'


class KnowledgePack(unittest.TestCase):
    def test_single_global_semantic_entry(self):
        pack = json.loads(PACK.read_text(encoding='utf-8'))['skyrimnet_knowledge_pack']
        self.assertEqual(pack['format_version'], 3)
        self.assertEqual(pack['entry_count'], 1)
        self.assertEqual(len(pack['entries']), 1)
        self.assertEqual(pack['npc_groups'], [])
        entry = pack['entries'][0]
        self.assertEqual(entry['key'], 'skyrim_milk_maid_lore')
        self.assertEqual(entry['type'], 'KNOWLEDGE')
        self.assertEqual(entry['condition_expr'], '')
        self.assertFalse(entry['always_inject'])
        self.assertLessEqual(len(entry['content']), 4000)
        for label in ('Context', 'Tone', 'Milk', 'Society', 'Treatment', 'Becoming a Milk Maid',
                      'Enchanted Milking Armor', 'New Enchanted Milking Armor Reaction',
                      'Being Milked', 'Fullness Paradox'):
            self.assertIn('**' + label + ':**', entry['content'])
        self.assertIn('Silly, sexy, humorous.', entry['content'])
        self.assertNotIn('{actor}', entry['content'])

    def test_old_lore_no_longer_enters_requests(self):
        for file in ('MMEDialogueKnowledge', 'MMEAlertsSkyrimNet'):
            text = (ROOT / f'Source/Scripts/{file}.psc').read_text(encoding='utf-8')
            self.assertNotIn('GetRaw("Lore", "milk_lore")', text)
        bridge = (ROOT / 'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text(encoding='utf-8')
        self.assertIn('MMENarrationText.Text("Lore", "milkmaid_lore"', bridge)
        self.assertIn('"shared_guidance"', (ROOT / 'Source/Scripts/MMEDialogueKnowledge.psc').read_text())

    def test_editing_help_and_archive_owner(self):
        meta = json.loads((ROOT / 'tools/narration-presentation.json').read_text(encoding='utf-8'))['entries']['Lore.milk_lore']
        self.assertTrue(meta['readOnly'])
        self.assertIn('World Knowledge', meta['description'])
        self.assertIn('manual copying', meta['note'])
        build = (ROOT / 'build-package.ps1').read_text(encoding='utf-8')
        self.assertIn('Copy-Item -LiteralPath $knowledgeSource -Destination $skyrimNet25StageDir -Recurse', build)


if __name__ == '__main__':
    unittest.main()
