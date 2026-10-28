"""Curse routing, commit/cleanup, JSON and compatibility boundaries."""
from pathlib import Path
import json,re,unittest
ROOT=Path(__file__).resolve().parents[1]
def read(name):return (ROOT/'Source/Scripts'/f'{name}.psc').read_text(encoding='utf-8-sig')
class CurseContracts(unittest.TestCase):
 def test_surge_is_additive_uncapped_and_not_conversion(self):
  body=read('MMEMilkCurse').split('Bool Function ApplySurgeWithChestContext(',1)[1].split('EndFunction',1)[0]
  self.assertIn('maximum * percentage / 100.0',body)
  self.assertIn('changeMilkCurrent(target, addition, False)',body)
  self.assertLess(body.index('SetIntValue(None, commitKey, 1)'),body.index('changeMilkCurrent('))
  self.assertNotRegex(body,r'AssignSlot|changeLactacid|MarkPlayerDrinkAttempt|setMilkCurrent')
  self.assertIn('IsMMEMilkMaid(target, milkController)',body)
  self.assertIn('Return True',body)
 def test_chest_priority_and_one_shot(self):
  s=read('MMEDungeonChestConversion')
  self.assertLess(s.index('SelectTarget(targetActor, 2'),s.index('SelectTarget(targetActor, 4'))
  self.assertIn('pendingKey + ".Time"',s)
  self.assertIn('created || StorageUtil.GetIntValue(None, resolvedKey, 0) == 1',s)
  t=read('MMEChestTrapTargets');self.assertIn('mode == 2 || mode == 4',t)
  self.assertIn('ElseIf mode == 4\n        Return MMEExtensionsAPI.IsMilkMaid(candidate)',t)
 def test_presentation_has_owned_cleanup_and_no_conversion(self):
  s=read('MMEMilkCurse');owned=s.split('Bool Function PlayOwnedReaction(',1)[1].split('EndFunction',1)[0]
  self.assertIn('MMEAnimationSafety.Owns(target, owner)',owned)
  self.assertLess(owned.index('LockMovement('),owned.index('SendAnimationEvent('))
  self.assertIn('MMEReactionAnimation.Reset(target, owner',owned)
  self.assertNotRegex(owned,r'AssignSlot|SetUnconscious|DisablePlayerControls|EnablePlayerControls')
  self.assertNotRegex(s,r'SexLabFramework|SkyrimNetApi\.')
  self.assertIn('RestorePlayerMovementIfNeeded',read('MMEAlertsController'))
 def test_stories_and_context_do_not_stack(self):
  data=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/ForcedMilkMaidConversion.json').read_text(encoding='utf-8'))
  self.assertEqual(len(data['chestCurseStories']),5)
  for text in data['chestCurseStories']:self.assertEqual(set(re.findall(r'\{(.*?)\}',text)),{'actor'})
  self.assertIn('openingStory',data);self.assertIn('closingStory',data)
  s=read('MMENewMilkMaid');self.assertIn('TryCreateMilkMaidWithContext(candidate, False, "")',s)
  self.assertEqual(s.count('MMEMilkCurse.ShowStory(candidate)'),1)
  self.assertNotIn('Debug.MessageBox(openingStory)',s)
  self.assertNotIn('Debug.MessageBox(closingStory)',s)
  self.assertIn('target != Game.GetPlayer()',read('MMEMilkCurse'))
 def test_setting_migration_and_master_footprints(self):
  s=read('MMEAlertsMCM');self.assertIn('!JsonUtil.HasIntValue(SettingsFile, "milkMaidCurseSurgePercent")',s)
  slider=s.split('ElseIf option == milkMaidCurseSurgeOption',2)[2].split('ElseIf',1)[0]
  self.assertIn('SetSliderDialogDefaultValue(50.0)',slider);self.assertIn('SetSliderDialogInterval(5.0)',slider)
  self.assertIn('MMELog.MasterDiagnostic',read('MMEMilkCurse'))
  self.assertIn('now - prior >= 60.0',read('MMEMilkCurse'))
 def test_public_signatures_and_non_conversion_narration(self):
  api=read('MMEExtensionsAPI');self.assertIn('Bool Function PlayMilkMaidReaction(Actor target) Global',api)
  self.assertIn('Bool Function TryApplyMilkMaidCurse(Actor target, Float percentage = 50.0) Global',api)
  data=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/MilkMaidCreation.json').read_text(encoding='utf-8'))
  self.assertIn('already a Milk Maid',data['routes']['narrate_milk_maid_curse_1']['template'])
 def test_chest_master_is_separate_and_saved_settings_are_preserved(self):
  s=read('MMEAlertsMCM')
  self.assertIn('!JsonUtil.HasIntValue(SettingsFile, "enableMilkMaidCurseTrap")',s)
  self.assertIn('AddToggleOption("Enable Trap Armor Chest", JsonUtil.GetIntValue(SettingsFile, "enableChestArmorTrap"',s)
  self.assertIn('AddToggleOption("Enable Milk Maid Curse Trap"',s)
  self.assertNotIn('AddHeaderOption("Forced Conversion Feedback")',s)
  self.assertIn('Int dungeonChestChanceFlags = curseFlags',s)
  self.assertIn('Int regularChestChanceFlags = curseFlags',s)
  block=s.split('forcedMilkMaidNotificationOption = AddToggleOption',1)[1].split('AddHeaderOption',1)[0]
  for line in block.splitlines():
   if 'AddToggleOption' in line and 'chestCurseNarrationOption' not in line:
    self.assertNotIn('curseFlags',line);self.assertNotIn('chestNarrationFlags',line)
  for script in ('MMEDungeonChestConversion','MMENewMilkMaid','MMEMilkCurse'):
   self.assertIn('"enableMilkMaidCurseTrap", 1',read(script))
if __name__=='__main__':unittest.main()
