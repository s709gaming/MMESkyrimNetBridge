"""Exercise legacy wrappers and guard the saved-call argument contract."""
from pathlib import Path
import re
import sys
import shutil
import subprocess
import tempfile
import unittest
from test_tentacle_tiers import translate

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Source/Scripts/MMEArmorIntroduction.psc').read_text()

class SavedArmorCalls(unittest.TestCase):
    def test_compiled_original_argument_counts(self):
        assembler = Path('E:/Steam/steamapps/common/Skyrim Special Edition/Papyrus Compiler/PapyrusAssembler.exe')
        with tempfile.TemporaryDirectory(prefix='MME-Armor-ABI-') as folder:
            shutil.copy2(ROOT / 'Scripts/MMEArmorIntroduction.pex', folder)
            subprocess.run([str(assembler), 'MMEArmorIntroduction', '-D', '-Q'], cwd=folder, check=True, capture_output=True)
            compiled = (Path(folder) / 'MMEArmorIntroduction.disassemble.pas').read_text(encoding='utf-8-sig')
        for name, count in [('TryAutomatic', 2), ('TryTrapIntroduction', 3), ('TryPresentation', 5)]:
            body = re.search(r'\.function\s+' + name + r'\s+static\b(.*?)\.endFunction', compiled, re.S | re.I).group(1)
            self.assertEqual(len(re.findall(r'(?m)^\s*\.param\s+', body)), count, name)

    def test_original_argument_counts(self):
        for name, count in [('TryAutomatic', 2), ('TryTrapIntroduction', 3), ('TryPresentation', 5)]:
            declaration = re.search(r'Bool Function ' + name + r'\(([^)]*)\)', SOURCE).group(1)
            self.assertEqual(len(declaration.split(',')), count, name)

    def test_legacy_automatic_never_grants_initial_lock(self):
        calls = []
        ns = {'Report': lambda *_: None, 'TryAutomaticEquipContext': lambda *a: calls.append(a) or True}
        exec(translate('TryAutomatic', 'target, equippedArmor', SOURCE), ns)
        self.assertTrue(ns['TryAutomatic']('actor', 'armor'))
        self.assertEqual(calls, [('actor', 'armor', False)])

    def test_legacy_trap_passes_through_guarded_legacy_presentation(self):
        calls = []
        ns = {'TryPresentation': lambda *a: calls.append(a) or False}
        exec(translate('TryTrapIntroduction', 'target, equippedArmor, sourceLabel', SOURCE), ns)
        self.assertFalse(ns['TryTrapIntroduction']('actor', 'armor', 'legacy'))
        self.assertEqual(calls, [('actor', 'armor', 'legacy', True, 1)])

    def test_legacy_presentation_keeps_lock_guard(self):
        calls = []
        ns = {'TryPresentationContext': lambda *a: calls.append(a) or False}
        exec(translate('TryPresentation', 'target, equippedArmor, sourceLabel, allowRepeat, storyMode', SOURCE), ns)
        self.assertFalse(ns['TryPresentation']('actor', 'armor', 'legacy', True, 2))
        self.assertEqual(calls, [('actor', 'armor', 'legacy', True, 2, False)])

    def test_controller_uses_distinct_context_entries(self):
        for path in [ROOT / 'Source/Scripts/MMEAlertsController.psc', ROOT / 'fomod/choices/ostim-only/Source/Scripts/MMEAlertsController.psc']:
            source = path.read_text()
            self.assertIn('TryAutomaticEquipContext(wearer, equippedArmor, initialLock)', source)
            self.assertIn('TryTrapEquipContext(wearer, equippedArmor, "Automatic Trap Equip", initialLock)', source)
            self.assertNotRegex(source, r'MMEArmorIntroduction\.TryAutomatic\(')
            self.assertNotRegex(source, r'MMEArmorIntroduction\.TryTrapIntroduction\(')

if __name__ == '__main__':
    unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout))
