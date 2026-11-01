"""Check effective installer winners, compiled pairs and preservation of MME."""
from pathlib import Path
import hashlib
import json
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
CHOICE = ROOT / 'fomod/choices/estrus-unified'


class EstrusTests(unittest.TestCase):
    def test_installer_matrix(self):
        xml = ET.parse(ROOT / 'fomod/ModuleConfig.xml').getroot()
        choice = xml.find(".//plugin[@name='Estrus Unified pregnancy support']")
        self.assertIsNotNone(choice)
        self.assertEqual(choice.find('.//fileDependency').attrib,
                         {'file': 'EstrusUnified.esp', 'state': 'Active'})
        for backend in ('standard', 'pplus', 'ostim-only'):
            for enabled in (False, True):
                flags = {'mmeNoSexLab': str(backend == 'ostim-only').lower(),
                         'mmeEstrusUnified': 'true' if enabled else None}
                files = []
                for pattern in xml.findall('./conditionalFileInstalls/patterns/pattern'):
                    deps = pattern.findall('./dependencies/flagDependency')
                    if all(flags.get(d.get('flag')) == d.get('value') for d in deps):
                        files += pattern.findall('./files/file')
                with self.subTest(backend=backend, enabled=enabled):
                    self.assertEqual(len(files), 2 if enabled else 0)
                    for file in files:
                        self.assertTrue((ROOT / file.get('source')).is_file())
                        self.assertGreater(int(file.get('priority')), 40)
                        variant = 'ostim-only' if backend == 'ostim-only' else 'standard'
                        self.assertIn('/' + variant + '/', file.get('source'))
                    if enabled:
                        self.assertEqual({f.get('destination') for f in files},
                                         {'Scripts/MilkQUEST.pex', 'Source/Scripts/MilkQUEST.psc'})

    def test_preserved_behavior_and_bytecode(self):
        for variant, original in (
            ('standard', ROOT / 'Source/MMECompatibilityOverrides/MilkQUEST.psc'),
            ('ostim-only', ROOT / 'fomod/choices/ostim-only/Source/Scripts/MilkQUEST.psc'),
        ):
            base = original.read_text()
            patched = (CHOICE / variant / 'Source/Scripts/MilkQUEST.psc').read_text()
            entry = '\nbool Function isPregnant(Actor akActor)'
            self.assertNotIn('EstrusUnified', base)
            self.assertEqual(patched[:patched.index('; Estrus Unified compatibility,')],
                             base[:base.index(entry) + 1])
            marker = 'String akActorName = akActor.GetLeveledActorBase().GetName()'
            self.assertEqual(patched[patched.index(marker, patched.index(entry)):],
                             base[base.index(marker, base.index(entry)):])
            for call in ['EstrusUnifiedAPI.GetPregnancyType(akActor)',
                         'EstrusUnifiedAPI.IsReady()', 'SKSE.GetPluginVersion("EstrusUnified")']:
                self.assertIn(call, patched)
            pex = (CHOICE / variant / 'Scripts/MilkQUEST.pex').read_bytes().lower()
            self.assertIn(b'estrusunifiedapi', pex)
            self.assertNotIn(b'mmeestrusunified', pex)
            if variant == 'ostim-only':
                self.assertNotIn(b'sexlabframework', pex)
            default = ROOT / ('Scripts/MilkQUEST.pex' if variant == 'standard' else
                              'fomod/choices/ostim-only/Scripts/MilkQUEST.pex')
            data = default.read_bytes().lower()
            self.assertNotIn(b'estrusunifiedapi', data)
            self.assertNotIn(b'mmeestrusunified', data)

    def test_pairs_and_retirement(self):
        manifest = json.loads((CHOICE / 'BuildManifest.json').read_text(encoding='utf-8-sig'))
        self.assertEqual({p['backend'] for p in manifest['pairs']}, {'standard', 'ostim-only'})
        for pair in manifest['pairs']:
            for key, suffix in [('sourceSHA256', 'Source/Scripts/MilkQUEST.psc'),
                                ('compiledSHA256', 'Scripts/MilkQUEST.pex')]:
                digest = hashlib.sha256((CHOICE / pair['backend'] / suffix).read_bytes()).hexdigest()
                self.assertEqual(digest, pair[key].lower())
        for file in ['src/Plugin.cpp', 'Source/Scripts/MMEExtensionsNative.psc',
                     'build-package.ps1', 'tools/Build-OStimOnly.ps1']:
            text = (ROOT / file).read_text()
            self.assertNotIn('MMEEstrusUnified', text)
            self.assertNotIn('GetEstrusUnifiedPregnancyType', text)


if __name__ == '__main__':
    unittest.main()
