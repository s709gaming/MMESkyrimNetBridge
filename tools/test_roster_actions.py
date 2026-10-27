"""Safety boundaries for the public inventory and manual roster routes."""
from pathlib import Path
import re, unittest
ROOT = Path(__file__).resolve().parents[1]
def source(name):
    return (ROOT / 'Source/Scripts' / (name + '.psc')).read_text(encoding='utf-8-sig')
class ActionContracts(unittest.TestCase):
    def test_recipient_selection_and_commit_guard(self):
        dialog = source('MMENPCDialog')
        selector = dialog.split('Form Function FindFirstMilkForRecipient(', 1)[1].split('EndFunction', 1)[0]
        self.assertIn('IsMMEMilkMaid(recipient, milkController)', selector)
        self.assertLess(selector.index('Return lactacid'), selector.index('Return FindFirstSupportedMilk'))
        self.assertIn('owner.GetItemCount(lactacid) > 0', selector)
        for script in ['MMENPCDialog', 'MMEAvailableMilkTransaction']:
            text = source(script)
            self.assertIn('selectedType == "Lactacid" && !MMEArmorScript.IsMMEMilkMaid', text)
            self.assertNotIn('changeLactacidCurrent(', text)

    def test_player_uses_owned_items_and_cheat_without_double_effects(self):
        own = source('MMEAvailableMilkTransaction').split('Bool Function DrinkAvailableMilk(', 1)[1]
        self.assertIn('"enableGiveMilkEasyMode", 1', own)
        self.assertIn('0x003534, "HearthFires.esm"', own)
        self.assertIn('beforeCount - 1', own)
        self.assertIn('CleanupFallback(drinker, selectedItem, supplied)', own)
        self.assertNotRegex(own, r'ApplyExtensionEffects|HandlePlayerDrink|PublishDrinkEvent|ForceMilkDrink\(')
        self.assertIn('MMEActorDrinkTransaction.Release(drinker, token)', own)

    def test_manual_keeps_framework_authority(self):
        manual = source('MMESelfMilking').split('String Function GetManualBlockReason(', 1)[1]
        self.assertIn('GetStartBlockReason(candidate, milkController, True)', manual)
        self.assertIn('armorClass == 2 || armorClass == 3 || armorClass == 4', manual)
        self.assertIn('StartExisting(candidate, True, False, True)', manual)
        self.assertNotRegex(manual, r'changeMilk|AssignSlot|SetPlayerControls')
        self.assertIn('MMELog.MasterDiagnostic', manual)

    def test_routine_api_footprints_need_master_only(self):
        text = source('MMEAvailableMilkTransaction')
        report = text.split('Function Report(', 1)[1].split('EndFunction', 1)[0]
        self.assertIn('MMELog.MasterDiagnostic', report)
        self.assertNotIn('Debug.Notification', report)
        self.assertIn('consume | giver=', text)

if __name__ == '__main__': unittest.main()
