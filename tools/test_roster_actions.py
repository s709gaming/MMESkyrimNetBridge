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

    def test_original_mode_mirror_is_actor_scoped_and_has_no_gameplay_dispatch(self):
        text = source('MMEOriginalSettings')
        setter = text.split('Bool Function SetMilkingMode(', 1)[1].split('EndFunction', 1)[0]
        self.assertIn('requestedMode != 0 && requestedMode != 2', setter)
        self.assertIn('StorageUtil.SetIntValue(candidate, "MME.MilkMaid.MilkingMode", requestedMode)', setter)
        self.assertIn('actualMode == requestedMode', setter)
        self.assertIn('maids.Find(candidate) < 0', text)
        self.assertNotRegex(setter, r'Game.GetPlayer|AssignSlot|changeMilk|[.]Cast|RegisterFor|Utility.Wait')
        self.assertIn('MMELog.MasterDiagnostic', setter)
        self.assertIn('Failure("modeReadback." + candidate', setter)
        self.assertNotIn('Debug.Notification', setter)
        sdk = (ROOT / 'tools/maid-roster-sdk/MMEOriginalSettings.psc').read_text()
        for signature in ['Int Function GetMilkingMode(Actor candidate) Global', 'String Function MilkingModeBlockReason(Actor candidate) Global', 'Bool Function SetMilkingMode(Actor candidate, Int requestedMode) Global']:
            self.assertIn(signature, text)
            self.assertIn(signature, sdk)

    def test_mode_action_keeps_snapshot_guards_and_stays_in_roster(self):
        text = (ROOT / 'fomod/choices/maid-roster-ui/Source/Scripts/MMEMaidRosterUI.psc').read_text()
        action = text.split('Event OnActionClick(', 1)[1].split('EndEvent', 1)[0]
        mode = action.split('    If parts[2] == "mode_auto" || parts[2] == "mode_manual"', 1)[1]
        # The first occurrence is stale-snapshot recovery; select the setter branch.
        mode = action[action.index('        ; Configuration-only action:'):action.index('    PendingActor =')]
        self.assertIn('SnapshotActors[rowIndex] as Actor', mode)
        self.assertIn('MMEOriginalSettings.SetMilkingMode(modeActor, requestedMode)', mode)
        self.assertIn('ActionBusy = False', mode)
        self.assertIn('RefreshRoster()', mode)
        self.assertNotIn('CloseRoster(', mode)
        self.assertNotIn('RegisterForSingleUpdate', mode)
        self.assertLess(action.index('rowIndex >= SnapshotActors.Length'), action.index('MMEOriginalSettings.SetMilkingMode'))
        self.assertLess(action.index('rowToken[0] != (SnapshotRevision as String)'), action.index('MMEOriginalSettings.SetMilkingMode'))

if __name__ == '__main__': unittest.main()
