from pathlib import Path
import re,unittest,sys
R=Path(__file__).resolve().parents[1]
def read(p):return (R/p).read_text(encoding='utf-8-sig')
def fn(s,n):
 m=re.search(r'(?ms)^(?:\w+ )?Function '+n+r'\([^\n]*\)(?: Global)?\n(.*?)^EndFunction',s)
 assert m,n
 return m[1]
class Contracts(unittest.TestCase):
 def test_old_publishers_are_inert_and_gameplay_remains(self):
  b=read('Source/Scripts/MMEAlertsSkyrimNet.psc');c=read('Source/Scripts/MMEAlertsController.psc')
  for n in ['SendCapacityMilestone','SendNearbyMilkStatuses','SendNearbyArmorStatuses']:
   self.assertNotIn('RegisterShortLivedEvent',fn(b,n));self.assertNotIn('.'+n+'(',c)
  self.assertNotIn('NextSkyrimNetUpdate = now',c)
  for token in ['UpdateCapacityState(candidate)','MMEMilkLeakAPI.Observe(nearbyActors)','QueueAutoSelfMilking(candidate)','PlayCapacityReaction(soundActor, soundKind)']:
   self.assertIn(token,c)
  self.assertNotIn('EvaluateMilkMaidFlavor(candidate)',fn(c,'ScanNearbyMilkMaids'))
 def test_read_only_framework_boundaries(self):
  s=read('Source/Scripts/MMEActorPromptState.psc')
  for token in ['GetNearbyActors','RegisterForUpdate','AddSpell','ForceRef','SetActorValue','DirectNarration','getMilkMaximum(','getMilkCurrent(']:self.assertNotIn(token,s)
  for token in ['MMEArmorScript.IsValidMilkMaid(target, milk)','ClassifyArmorQuiet(milk, worn, target)','GetDwemerPresentationProfile(worn)','MMEMilkLeakAPI.Manager() == None','MMEMilkLeakAPI.GetLeakSource(target)']:self.assertIn(token,s)
  self.assertNotRegex(s,r'StorageUtil\.(?:Set|Unset|Adjust)\w+Value\([^\n]*"MME\.MilkMaid\.')
  self.assertIn('MMELog.MasterDiagnostic',s);self.assertIn('MMELog.Alarm',s);self.assertNotIn('Debug.Notification',s)
 def test_settings_and_quiet_classification(self):
  s=read('Source/Scripts/MMEAlertsMCM.psc');a=read('Source/Scripts/MMEArmorScript.psc')
  self.assertNotIn('skyrimNetStatusIntervalOption = Add',s)
  for key in ['enableSkyrimNetMilkStatuses','enableNearbyMilkArmorStatus','skyrimNetStatusInterval']:self.assertIn(key,s)
  self.assertNotIn('Bool quiet',a.split('Int Function ClassifyArmor(',1)[1].split('\n',1)[0])
  self.assertNotIn('Bool quiet',a.split('Int Function ClassifyOriginalArmor(',1)[1].split('\n',1)[0])
  self.assertIn('!quiet && GetArmorLookupDiagnostic()',fn(a,'ClassifyOriginalArmorInternal'))
 def test_registration_and_render_time_native_reads(self):
  s=read('SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt')
  self.assertEqual(s,read('SKSE/Plugins/SkyrimNet/prompts/submodules/character_bio/0260_mme_extensions_milkmaid.prompt'))
  self.assertIn('mme_actor_milk_state(actorUUID)',s)
  for key in ['MME.MilkMaid.MilkCount','MME.MilkMaid.MilkMaximum']:self.assertIn('"'+key+'"',s)
  self.assertNotIn('!IsExtensionsEnabled()',fn(read('Source/Scripts/MMEAlertsSkyrimNet.psc'),'RegisterPromptDecorator'))
  self.assertIn('SkyrimNetApi.RegisterDecorator("mme_actor_milk_state", "MMEActorPromptState", "GetActorState")',read('Source/Scripts/MMEAlertsSkyrimNet.psc'))
  self.assertIn('$scriptNames += "MMEActorPromptState"',read('build-package.ps1'))
 def test_existing_save_load_restores_all_callbacks_before_master_off(self):
  controller=read('Source/Scripts/MMEAlertsController.psc')
  load=re.search(r'(?ms)^Event OnNativeLifecycle\([^\n]*\)\n(.*?)^EndEvent',controller).group(1)
  registration=load.index('MMEAlertsSkyrimNet.RegisterPromptDecorator()')
  self.assertLess(load.index('If reason == "load"'),registration)
  self.assertLess(load.index('If Game.GetModByName("SkyrimNet.esp") != 255'),registration)
  self.assertLess(registration,load.index('If !IsExtensionsEnabled()'))
  self.assertEqual(load.count('RegisterPromptDecorator()'),1)
  self.assertNotIn('InitializeController(',load)
  self.assertNotIn('ApplyDefaults(',load)
  self.assertNotIn('ScheduleTestSetup(',load)
  self.assertIn('MMELog.MasterDiagnostic("[MME Actor Prompt] save-load recovery entry',load)
  bridge=fn(read('Source/Scripts/MMEAlertsSkyrimNet.psc'),'RegisterPromptDecorator')
  self.assertEqual(bridge.count('SkyrimNetApi.RegisterDecorator('),6)
  self.assertNotIn('!IsExtensionsEnabled()',bridge)
  self.assertIn('MMELog.Alarm',bridge)
  self.assertIn('OtherRegistrationFailure',bridge)
  for name in ['mme_milkmaid_prompt_debug','mme_breastfeeding_role','mme_recent_milk_drinker','mme_actor_milk_state','mme_milk_lore_text','mme_breastfeeding_guidance_text']:
   self.assertIn('SkyrimNetApi.RegisterDecorator("'+name+'"',bridge)
 def test_narration_rechecks_before_submit(self):
  s=read('Source/Scripts/MMEAlertsSkyrimNet.psc')
  for name in ['NarrateMilkFull','NarrateMilkHalfFull']:
   body=fn(s,name);self.assertLess(body.index('GetFullnessState(milkMaid)'),body.index('SkyrimNetApi.DirectNarration'))
if __name__=='__main__':unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout))
