"""Verify every production service fragment publishes to the vendor-animation bus."""
import unittest
from pathlib import Path

from add_service_completion_fragments import TARGETS, patch_plugin

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Source/Scripts/MMEBlacksmithDialogue.psc').read_text()


class ServiceTests(unittest.TestCase):
    def test_non_skyrim_net_startup_is_isolated_and_dialogue_alarm_is_error_only(self):
        controller = (ROOT / 'Source/Scripts/MMEAlertsController.psc').read_text()
        self.assertRegex(controller, r'If Game\.GetModByName\("SkyrimNet\.esp"\) != 255\s+MMEAlertsSkyrimNet\.RegisterPromptDecorator\(\)\s+MMESkyrimNetVoiceControls\.RegisterSelfMilkingAction\(\)\s+EndIf')
        self.assertIn('CheckOpeningDialogueHealth(Game.GetDialogueTarget() as Actor)', controller)
        self.assertIn('ElseIf !milkController.MilkQC.MME_DialogueMilking', controller)
        self.assertIn('MMEExtensionsNative.EvaluateTopicInfo(openingInfo, speaker, Game.GetPlayer())', controller)
        self.assertIn('MMEExtensionsNative.EvaluateTopicInfoConditions(openingInfo, speaker, Game.GetPlayer())', controller)
        self.assertIn('MMEExtensionsNative.DescribeTopicInfoConditions(openingInfo)', controller)
        self.assertIn('If !OpeningDialogueAlarmActive', controller)
        self.assertIn('MMELog.Alarm("[MME Extensions Dialogue] ROUTE CLOG', controller)

    def test_build_carries_optional_skyrim_net_compile_contract(self):
        build = (ROOT / 'build-package.ps1').read_text()
        sdk = (ROOT / 'tools/skyrimnet-sdk/SkyrimNetApi.psc').read_text()
        self.assertIn('$skyrimNetSdkSource', build)
        self.assertIn('tools\\skyrimnet-sdk', build)
        self.assertIn('Scriptname SkyrimNetApi Hidden', sdk)
        self.assertIn('Function RegisterAction(', sdk)
        self.assertIn('Function DirectNarration(', sdk)

    def test_every_service_routes_through_completion_bus(self):
        for action in TARGETS.values():
            with self.subTest(action=action):
                start = SOURCE.index('Function Fragment_' + action + '(')
                body = SOURCE[start:SOURCE.index('EndFunction', start)]
                self.assertIn('CompleteVendorService(akSpeakerRef,', body)
                self.assertIn('Try' + action + '(', body)

    def test_info_end_only_observes_and_clears_transient_result(self):
        start = SOURCE.index('Function Fragment_ServiceCompleted(')
        body = SOURCE[start:SOURCE.index('EndFunction', start)]
        self.assertIn('service.ObserveVendorServiceInfoEnd', body)
        self.assertIn('serviceSucceeded = False', body)
        self.assertNotIn('PlayIdle', body)
        self.assertNotIn('Utility.Wait', body)

    def test_persistent_bus_uses_menu_close_and_minor_animation_service(self):
        bus = (ROOT / 'Source/Scripts/MMEDebug.psc').read_text()
        self.assertIn('RegisterForMenu("Dialogue Menu")', bus)
        self.assertIn('Event OnMenuClose(String menuName)', bus)
        self.assertIn('MMEMinorAnimations.PlayGive(vendor, 3.0,', bus)
        self.assertIn('MMEMinorAnimations.Cancel(vendor, "MinorAnimation.Give"', bus)
        self.assertNotIn('vendor.PlayIdle', bus)
        self.assertNotIn('vendor.SetDontMove', bus)
        self.assertIn('"enablePapyrusTrace"', bus)
        self.assertIn('"enableVendorAnimationTrace"', bus)

    def test_minor_animation_service_owns_vanilla_idles_and_safety(self):
        minor = (ROOT / 'Source/Scripts/MMEMinorAnimations.psc').read_text()
        self.assertIn('0x0B5E20, "Skyrim.esm"', minor)
        self.assertIn('0x0FD68B, "Skyrim.esm"', minor)
        self.assertIn('0x10D9EE, "Skyrim.esm"', minor)
        self.assertIn('MMEAnimationSafety.GetStartBlockReason', minor)
        self.assertIn('MMEAnimationSafety.GetResetBlockReason', minor)
        self.assertIn('MMEAnimationSafety.TryAcquire', minor)
        self.assertIn('target.SetDontMove(True)', minor)
        self.assertIn('target.SetDontMove(False)', minor)
        self.assertIn('target.EvaluatePackage()', minor)
        self.assertIn('Float duration = 3.0', minor)

    def test_drink_adapter_uses_minor_animation_service(self):
        drink = (ROOT / 'Source/Scripts/MMEDrinkAnimation.psc').read_text()
        self.assertIn('MMEMinorAnimations.StartDrink', drink)
        self.assertIn('MMEMinorAnimations.Finish', drink)
        self.assertIn('MMEMinorAnimations.Complete', drink)
        self.assertNotIn('MMEReactionAnimation.', drink)

    def test_milk_dialogue_queues_paired_animation_after_success(self):
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        self.assertIn('TestDialogueTarget(target, True)', dialogue)
        self.assertIn('Bool dialogueRequest = False', dialogue)
        self.assertIn('MMEDebug.QueueDialogueMilkAnimations(giver, target)', dialogue)
        self.assertNotIn('MMELog.Alarm', dialogue)

    def test_persistent_service_runs_pair_after_dialogue_close(self):
        bus = (ROOT / 'Source/Scripts/MMEDebug.psc').read_text()
        self.assertIn('If DialogueMilkAnimationPending && !VendorAnimationPending', bus)
        self.assertIn('UI.IsMenuOpen("Dialogue Menu")', bus)
        self.assertIn('MMEMinorAnimations.StartGive(giver, "DialogueMilk.Giver", False, False)', bus)
        self.assertIn('MMEMinorAnimations.StartDrink(drinker, "DialogueMilk.Drinker", True, False)', bus)
        self.assertEqual(bus.count('Utility.Wait(3.0)'), 1)
        self.assertIn('MMEMinorAnimations.Complete(giver, "DialogueMilk.Giver"', bus)
        self.assertIn('MMEMinorAnimations.Complete(drinker, "DialogueMilk.Drinker"', bus)
        self.assertIn('RecoverDialogueMilkAnimationsAfterLoad()', bus)

    def test_minor_animation_smoke_alarms_are_failure_only(self):
        minor = (ROOT / 'Source/Scripts/MMEMinorAnimations.psc').read_text()
        alarm_lines = [line.strip() for line in minor.splitlines() if 'MMELog.Alarm' in line]
        self.assertGreaterEqual(len(alarm_lines), 2)
        for line in alarm_lines:
            self.assertIn('FAILURE:', line)

    def test_packaged_plugin_has_all_end_bindings(self):
        data = (ROOT / 'MMEAlert.esp').read_bytes()
        self.assertEqual(patch_plugin(data), data)

    def test_opening_does_not_apply_or_gesture(self):
        body = SOURCE.split('Function Fragment_RefreshBlacksmithArmorState(', 1)[1].split('EndFunction', 1)[0]
        self.assertNotIn('PlayIdle', body)
        self.assertNotIn('TryApplyReverseLeveling', body)
        self.assertEqual(body.count('Parent.Fragment_00(akSpeakerRef)'), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
