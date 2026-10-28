"""Chest-source isolation, callback gates, editable prompt and factual delta contracts."""
from pathlib import Path
import json,re,unittest
ROOT=Path(__file__).resolve().parents[1]
def source(name):return (ROOT/f'Source/Scripts/{name}.psc').read_text(encoding='utf-8-sig')
class ChestNarrationTests(unittest.TestCase):
 def test_editable_prompt_has_magic_chest_and_variety(self):
  data=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/MilkMaidCreation.json').read_text(encoding='utf-8'))
  text=data['routes']['narrate_chest_milk_maid_curse_1']['template']
  self.assertEqual(set(re.findall(r'\{(.*?)\}',text)),{'actor','outcome','chest_kind','milk_added'})
  for phrase in ['magical Milk Maid curse','first person','playfully suspect','Vary the wording','Do not claim she drank anything','already one']:
   self.assertIn(phrase,text)
  values={'actor':'雪 "Hulda" {name}','outcome':'Already a Milk Maid; 2 milk added.','chest_kind':'boss treasure chest','milk_added':'2'}
  rendered=re.sub(r'\{([^{}]+)\}',lambda m:values[m[1]],text)
  self.assertIn(values['actor'],rendered)
  self.assertEqual(json.loads(json.dumps({'situation':rendered}))['situation'],rendered)
 def test_immutable_context_and_generic_suppression(self):
  chest=source('MMEDungeonChestConversion')
  self.assertIn('resolvedKey, chestKind, chestIdentity)',chest)
  curve=source('MMEMilkCurse')
  self.assertIn('FeedbackWithChestContext(target, False, chestKind, chestIdentity, afterMilk - beforeMilk)',curve)
  feedback=curve.split('Function FeedbackWithChestContext(',1)[1].split('EndFunction',1)[0]
  self.assertIn('If chestKind != "" || chestIdentity != ""',feedback)
  self.assertIn('MMEChestCurseNarration.Publish(target, converted, chestKind, chestIdentity, milkAdded)',feedback)
  self.assertIn('ElseIf converted',feedback)
  self.assertNotIn('StorageUtil.',feedback)
  self.assertLess(curve.index('MMEAnimationSafety.Release(target, owner)',curve.index('PlayOwnedReaction(target, owner)',curve.index('Bool Function ApplySurgeWithChestContext'))),curve.index('FeedbackWithChestContext(target, False'))
 def test_new_player_callback_and_no_npc_fallback(self):
  s=source('MMEChestCurseNarration')
  self.assertIn('"OnChestCursePlayerLine"',s)
  self.assertIn('Function OnChestCursePlayerLine(String response, Int success)',source('MMEAlertsController'))
  playback=s.split('Function PlayPlayerLine(',1)[1].split('EndFunction',1)[0]
  self.assertIn('BlockReason(target)',playback)
  self.assertIn('SkyrimNetApi.TriggerPlayerTTS(response)',playback)
  self.assertNotIn('DirectNarration',playback)
  self.assertIn('SkyrimNetApi.DirectNarration(prompt, target, Game.GetPlayer())',s)
 def test_settings_optional_guards_and_sparse_logs(self):
  s=source('MMEChestCurseNarration')
  for key in ['enableChestCurseNarration','enableForcedMilkMaidNarration','enableMilkMaidCurseTrap']:
   self.assertIn('"'+key+'", 1',s)
  self.assertIn('!MMEAlertsSkyrimNet.IsAvailable()',s)
  self.assertIn('MMELog.MasterDiagnostic',s)
  self.assertIn('now - prior >= 60.0',s)
  self.assertNotRegex(s,r'Debug.Notification|Utility.Wait|RegisterForUpdate')
  mcm=source('MMEAlertsMCM');self.assertIn('!JsonUtil.HasIntValue(SettingsFile, "enableChestCurseNarration")',mcm)
  self.assertIn('JsonUtil.SetIntValue(SettingsFile, "enableChestCurseNarration", 1)',mcm)
 def test_no_fullness_or_gameplay_changes_in_publication_service(self):
  s=source('MMEChestCurseNarration')
  self.assertNotRegex(s,r'changeMilk|AssignSlot|SetDontMove|SendAnimationEvent|NarrateMilkFull\(|NarrateMilkHalfFull\(')
  self.assertIn('milkAdded <= 0.0',s)
  self.assertIn('She has not become a Milk Maid again.',s)
  self.assertIn('not applicable: milk production newly awakened',s)
if __name__=='__main__':unittest.main()
