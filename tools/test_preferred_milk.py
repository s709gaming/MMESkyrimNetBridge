"""Execute the actual settings/default branches; not a live bottle-output test."""
from pathlib import Path
from types import SimpleNamespace as NS
import re
import unittest
from test_tentacle_tiers import translate

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Source/Scripts/MMEOriginalSettings.psc').read_text(encoding='utf-8')
KEY = 'MMEExtensions.PreferredMilk.DefaultApplied'


class Store:
    def __init__(self): self.values = {}
    def GetIntValue(self, actor, key, default=0): return self.values.get(key, default)
    def SetIntValue(self, actor, key, value): self.values[key] = value


class PreferredMilk(unittest.TestCase):
    def setUp(self):
        self.store = Store()
        self.milk = NS(MilkFlag=True, MilkQC=NS(MME_SimpleMilkPotions=False))
        self.enabled = True
        self.failures = []
        self.resets = 0
        self.menu = NS(ForcePageReset=self.reset)
        self.ns = dict(StorageUtil=self.store, Quest=NS(GetQuest=lambda _: self.milk),
                       MMEAlertsController=NS(IsExtensionsEnabled=lambda: self.enabled),
                       Resolve=lambda: self.milk,
                       Failure=lambda key, failed, *a: self.failures.append(key) if failed else None)
        source = re.sub(r'(?m)^([ \t]*)Spell ', r'\1Actor ', SOURCE)
        source = re.sub(r'^\s*MMELog\.MasterDiagnostic\([^\n]*\n', '', source, flags=re.M)
        for name, args in [('EnsurePreferredMilkDefault', ''), ('Toggle', 'menu, settingName')]:
            exec(translate(name, args, source), self.ns)

    def reset(self): self.resets += 1

    def test_new_and_existing_save_default_once(self):
        self.assertTrue(self.ns['EnsurePreferredMilkDefault']())
        self.assertTrue(self.milk.MilkQC.MME_SimpleMilkPotions)
        self.milk.MilkQC.MME_SimpleMilkPotions = False  # Original MCM edit.
        self.assertTrue(self.ns['EnsurePreferredMilkDefault']())
        self.assertFalse(self.milk.MilkQC.MME_SimpleMilkPotions)

    def test_initialization_waits_then_retries(self):
        self.milk.MilkFlag = False
        self.assertFalse(self.ns['EnsurePreferredMilkDefault']())
        self.assertNotIn(KEY, self.store.values)
        self.milk.MilkFlag = True
        self.assertTrue(self.ns['EnsurePreferredMilkDefault']())

    def test_disabled_and_missing_startup_prerequisites_are_quiet(self):
        self.enabled = False
        self.assertFalse(self.ns['EnsurePreferredMilkDefault']())
        self.enabled = True
        self.milk.MilkQC = None
        self.assertFalse(self.ns['EnsurePreferredMilkDefault']())
        self.milk = None
        self.assertFalse(self.ns['EnsurePreferredMilkDefault']())
        self.assertEqual(self.failures, [])
        self.assertNotIn(KEY, self.store.values)

    def test_menu_changes_original_setting_and_survives_reload(self):
        self.ns['EnsurePreferredMilkDefault']()
        self.ns['Toggle'](self.menu, 'PreferredMilk')
        self.assertFalse(self.milk.MilkQC.MME_SimpleMilkPotions)
        self.ns['EnsurePreferredMilkDefault']()
        self.assertFalse(self.milk.MilkQC.MME_SimpleMilkPotions)
        self.ns['Toggle'](self.menu, 'PreferredMilk')
        self.assertTrue(self.milk.MilkQC.MME_SimpleMilkPotions)
        self.assertEqual(self.resets, 2)

    def test_failed_write_does_not_complete_migration(self):
        class Refusing:
            MME_SimpleMilkPotions = property(lambda _: False, lambda *_: None)
        self.milk.MilkQC = Refusing()
        self.assertFalse(self.ns['EnsurePreferredMilkDefault']())
        self.assertNotIn(KEY, self.store.values)
        self.assertIn('preferredMilkDefault', self.failures)

    def test_menu_failure_and_pending_startup(self):
        self.milk.MilkQC = None
        self.ns['Toggle'](self.menu, 'PreferredMilk')
        self.assertIn('preferredMilkConditions', self.failures)
        self.milk.MilkQC = NS(MME_SimpleMilkPotions=False)
        self.milk.MilkFlag = False
        self.ns['Toggle'](self.menu, 'PreferredMilk')
        self.assertFalse(self.milk.MilkQC.MME_SimpleMilkPotions)
        self.assertNotIn(KEY, self.store.values)


if __name__ == '__main__': unittest.main()
