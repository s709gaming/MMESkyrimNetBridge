"""Verify every production service fragment publishes to the vendor-animation bus."""
import json
import unittest
from pathlib import Path

from add_service_completion_fragments import TARGETS, patch_plugin
from add_milk_dialogue_timing_fragment import patch_plugin as patch_milk_timing_fragment
from remove_give_milk_inventory_conditions import patch_plugin as patch_give_milk_inventory_conditions
from enable_universal_give_milk_dialogue import patch_plugin as patch_universal_give_milk_dialogue
from remove_give_milk_previous_dialog import patch_plugin as patch_give_milk_previous_dialog
from separate_give_milk_dialogue_topic import patch_plugin as patch_separate_give_milk_topic
from restrict_new_milkmaid_dialogue_to_females import patch_plugin as patch_female_new_milkmaid

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Source/Scripts/MMEBlacksmithDialogue.psc').read_text()


class ServiceTests(unittest.TestCase):
    def test_new_milkmaid_conversion_is_female_only_in_script_and_dialogue(self):
        source = (ROOT / 'Source/Scripts/MMENewMilkMaid.psc').read_text()
        self.assertIn('If candidateSex != 1', source)
        self.assertNotIn('milkController.MaleMaids', source)
        data = (ROOT / 'MMEAlert.esp').read_bytes()
        self.assertEqual(patch_female_new_milkmaid(data), data)

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

    def test_persistent_bus_starts_vendor_give_early_with_menu_close_fallback(self):
        bus = (ROOT / 'Source/Scripts/MMEDebug.psc').read_text()
        self.assertIn('RegisterForMenu("Dialogue Menu")', bus)
        self.assertIn('Event OnMenuClose(String menuName)', bus)
        self.assertIn('MMEMinorAnimations.StartGive(vendor, "VendorService.Give", True,', bus)
        self.assertIn('MMEMinorAnimations.Complete(vendor, "VendorService.Give"', bus)
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

    def test_milk_dialogue_queues_give_before_extension_effects(self):
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        self.assertIn('TestDialogueTarget(target, True)', dialogue)
        self.assertIn('Bool dialogueRequest = False', dialogue)
        self.assertIn('MMEDebug.QueueDialogueMilkAnimations(giver, target)', dialogue)
        branch = dialogue.rsplit('If dialogueRequest', 1)[1].split('Else', 1)[0]
        self.assertLess(branch.index('MMEDebug.QueueDialogueMilkAnimations'), branch.index('ApplyExtensionEffects'))
        alarm_lines = [line.strip() for line in dialogue.splitlines() if 'MMELog.Alarm' in line]
        self.assertGreaterEqual(len(alarm_lines), 1)
        for line in alarm_lines:
            self.assertIn('FAILURE:', line)

    def test_dialogue_receiver_drinks_before_native_consumption(self):
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        transaction = dialogue.split('Bool Function ProcessNativeConsumption(', 1)[1].split('EndFunction', 1)[0]
        self.assertIn('TraceDialogueTiming("04A receiver Drink dispatch"', transaction)
        self.assertIn('receiverDrinkStarted = StartDrinkAnimation(target, selectedItem, diagnostic)', transaction)
        self.assertIn('FinishDrinkAnimation(target, receiverDrinkStarted, diagnostic)', transaction)
        self.assertLess(transaction.index('StartDrinkAnimation(target, selectedItem'), transaction.index('target.EquipItem(selectedItem'))
        self.assertLess(transaction.index('FinishDrinkAnimation(target, receiverDrinkStarted'), transaction.index('target.EquipItem(selectedItem'))

    def test_milk_dialogue_timing_trace_is_opt_in_and_staged(self):
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        bus = (ROOT / 'Source/Scripts/MMEDebug.psc').read_text()
        mcm = (ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text()
        self.assertIn('Function Fragment_TimingBegin(ObjectReference akSpeakerRef)', dialogue)
        self.assertIn('INFO OnBegin (earliest Papyrus signal)', dialogue)
        self.assertIn('"enableMilkDialogueTimingTrace"', dialogue)
        self.assertIn('TraceDialogueTiming("02 INFO OnEnd"', dialogue)
        self.assertIn('TraceDialogueTiming("06 consumption verified"', dialogue)
        self.assertIn('MMEDebug.StartDialogueMilkGiveEarly(player, target)', dialogue)
        self.assertIn('MMEDebug.FinishDialogueMilkGiveEarly(Game.GetPlayer(), target)', dialogue)
        self.assertIn('TraceDialogueTiming("08 early Give dispatch"', bus)
        self.assertIn('TraceDialogueTiming("09 early Give PlayIdle accepted"', bus)
        self.assertIn('TraceDialogueTiming("07 Give queued"', bus)
        self.assertIn('TraceDialogueTiming("09 Give PlayIdle accepted"', bus)
        self.assertIn('milkDialogueTimingTraceOption = AddToggleOption("Milk Dialogue Timing"', mcm)
        self.assertGreater(mcm.index('milkDialogueTimingTraceOption = AddToggleOption'), mcm.index('vendorAnimationTraceOption = AddToggleOption'))

    def test_persistent_service_starts_give_early_and_retains_close_fallback(self):
        bus = (ROOT / 'Source/Scripts/MMEDebug.psc').read_text()
        self.assertIn('Bool Function StartDialogueMilkGiveEarly(Actor giver, Actor drinker) Global', bus)
        self.assertIn('Return service.StartDialogueMilkGiveEarlyInternal(giver, drinker)', bus)
        self.assertIn('Bool Function FinishDialogueMilkGiveEarly(Actor giver, Actor drinker) Global', bus)
        self.assertIn('ActiveDialogueMilkGiver == giver && ActiveDialogueMilkDrinker == drinker && ActiveDialogueMilkGiveStarted', bus)
        self.assertIn('early Give claimed by successful transaction', bus)
        self.assertIn('early Give completed at INFO OnEnd', bus)
        self.assertIn('If DialogueMilkAnimationPending && !VendorAnimationPending', bus)
        self.assertIn('UI.IsMenuOpen("Dialogue Menu")', bus)
        self.assertIn('MMEMinorAnimations.StartGive(giver, "DialogueMilk.Giver", False, False)', bus)
        self.assertNotIn('MMEMinorAnimations.StartDrink(drinker, "DialogueMilk.Drinker", True, False)', bus)
        self.assertEqual(bus.count('Utility.Wait(3.0)'), 1)
        self.assertIn('MMEMinorAnimations.Complete(giver, "DialogueMilk.Giver"', bus)
        self.assertNotIn('MMEMinorAnimations.Complete(drinker, "DialogueMilk.Drinker"', bus)
        self.assertIn('RecoverDialogueMilkAnimationsAfterLoad()', bus)

    def test_dialogue_give_watchdog_is_failure_only_and_reuses_shared_update(self):
        bus = (ROOT / 'Source/Scripts/MMEDebug.psc').read_text()
        self.assertIn('Event OnUpdate()', bus)
        self.assertIn('CheckDialogueMilkAnimationWatchdog()', bus)
        self.assertIn('FAILURE: dialogue closed but queued Give was never dispatched', bus)
        self.assertNotIn('RegisterForSingleUpdate(', bus)

    def test_minor_animation_smoke_alarms_are_failure_only(self):
        minor = (ROOT / 'Source/Scripts/MMEMinorAnimations.psc').read_text()
        alarm_lines = [line.strip() for line in minor.splitlines() if 'MMELog.Alarm' in line]
        self.assertGreaterEqual(len(alarm_lines), 2)
        for line in alarm_lines:
            self.assertIn('FAILURE:', line)

    def test_packaged_plugin_has_all_end_bindings(self):
        data = (ROOT / 'MMEAlert.esp').read_bytes()
        self.assertEqual(patch_plugin(data), data)
        self.assertEqual(patch_milk_timing_fragment(data), data)
        self.assertEqual(patch_give_milk_inventory_conditions(data), data)
        self.assertEqual(patch_universal_give_milk_dialogue(data), data)
        self.assertEqual(patch_give_milk_previous_dialog(data), data)
        self.assertEqual(patch_separate_give_milk_topic(data), data)

    def test_give_milk_info_has_no_pre_papyrus_conditions(self):
        data = (ROOT / 'MMEAlert.esp').read_bytes()
        self.assertEqual(patch_give_milk_inventory_conditions(data), data)
        self.assertEqual(patch_universal_give_milk_dialogue(data), data)
        self.assertEqual(patch_give_milk_previous_dialog(data), data)
        self.assertEqual(patch_separate_give_milk_topic(data), data)

    def test_give_milk_excludes_lactacid_and_has_default_on_easy_mode(self):
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        mcm = (ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text()
        selector = dialogue.split('Form Function FindFirstSupportedMilk(', 1)[1].split('EndFunction', 1)[0]
        self.assertNotIn('MME_Util_Potions', selector)
        self.assertIn('enableGiveMilkEasyMode", 1', dialogue)
        self.assertIn('Game.GetFormFromFile(0x003534, "HearthFires.esm")', dialogue)
        self.assertIn('Easy Mode temporary Jug', dialogue)
        self.assertIn('Return 116', mcm)
        self.assertIn('AddHeaderOption("Easy Mode")', mcm)
        self.assertIn('AddToggleOption("Free Jug for Give Milk"', mcm)
        self.assertIn('JsonUtil.SetIntValue(SettingsFile, "enableGiveMilkEasyMode", 1)', mcm)

    def test_universal_adult_non_milkmaid_route_is_isolated_and_configurable(self):
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        universal = (ROOT / 'Source/Scripts/MMENPCDrinkDialogue.psc').read_text()
        mcm = (ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text()
        config = (ROOT / 'SKSE/Plugins/StorageUtilData/MMEAlerts/NonMilkmaidDrinkNotifications.json').read_text()
        self.assertIn('MMENPCDrinkDialogue.IsEligible', dialogue)
        self.assertIn('target.IsChild()', universal)
        self.assertIn('ActorTypeNPC', universal)
        self.assertIn('enableNonMilkmaidMaleDrinking', universal)
        self.assertIn('enableNonMilkmaidFemaleDrinking', universal)
        self.assertNotIn('MME_Storage', universal)
        self.assertNotIn('MMEMilkBoost', universal)
        self.assertNotIn('SkyrimNetApi', universal)
        self.assertIn('ApplyArousalAmountForActor', universal)
        self.assertIn('arousalSent', universal)
        self.assertIn('JsonUtil.PathStringElements(configFile, pool)', universal)
        self.assertIn('11D non-Milkmaid reaction sound returned', universal)
        self.assertIn('11F non-Milkmaid notification complete', universal)
        self.assertIn('11E6 HUD notification returned', universal)
        renderer = universal.split('String Function RenderToken(', 1)[1].split('EndFunction', 1)[0]
        self.assertNotIn('While', renderer)
        self.assertIn('If tokenIndex < 0', renderer)
        for pool in ('male_generic', 'female_generic', 'male_aroused', 'female_aroused', 'female_milk', 'female_milk_arousal'):
            self.assertIn('"' + pool + '"', config)
        self.assertNotIn('{Actor}', config)
        self.assertNotIn('{Milk}', config)
        pools = json.loads(config)
        self.assertEqual(set(pools), {'male_generic', 'female_generic', 'male_aroused', 'female_aroused', 'female_milk', 'female_milk_arousal'})
        for pool, messages in pools.items():
            with self.subTest(pool=pool):
                self.assertEqual(len(messages), 6)
        self.assertIn('Utility.RandomInt(0, entries.Length - 1)', universal)
        self.assertIn('11E0A notification JSON validation', universal)
        self.assertIn('11E0C notification JSON entry selected', universal)
        self.assertIn('AddHeaderOption("Non-Milkmaid Drinking")', mcm)
        self.assertIn('universalNPCDrinkMigration115', mcm)

    def test_global_npc_drink_phase_two_is_universal_and_keeps_milkmaid_effects_isolated(self):
        tracker = (ROOT / 'Source/Scripts/MMEDrinkTracker.psc').read_text()
        diagnostics = (ROOT / 'Source/Scripts/MMEDiagnostics.psc').read_text()
        mcm = (ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text()
        native_handler = tracker.split('Function HandleNativeNPCDrink(', 1)[1].split('EndFunction', 1)[0]
        self.assertIn('drinker.IsChild()', native_handler)
        self.assertIn('ActorTypeNPC', native_handler)
        self.assertIn('enableNonMilkmaidMaleDrinking', native_handler)
        self.assertIn('enableNonMilkmaidFemaleDrinking', native_handler)
        self.assertIn('MMENPCDrinkDialogue.ApplyPostDrink', native_handler)
        self.assertIn('If !establishedMilkmaid', native_handler)
        self.assertEqual(native_handler.count('MMEMilkBoost.ApplyMilkDrinkBonusForActor'), 1)
        self.assertLess(native_handler.index('Return\n    EndIf\n\n    ; Established Milkmaids'), native_handler.index('MMEMilkBoost.ApplyMilkDrinkBonusForActor'))
        self.assertIn('dialogue duplicate suppressed', native_handler)
        self.assertIn('native duplicate suppressed', native_handler)
        self.assertIn('MMEExtensions.NPCDrink.LastStage', native_handler)
        self.assertIn('RunGlobalNPCDrinkTest', diagnostics)
        self.assertIn('Test Global NPC Milk Drink', mcm)
        self.assertIn('simulated post-consumption event', tracker)

    def test_global_npc_drink_phase_three_reuses_json_and_targets_skyrim_net_once(self):
        tracker = (ROOT / 'Source/Scripts/MMEDrinkTracker.psc').read_text()
        dialogue = (ROOT / 'Source/Scripts/MMENPCDialog.psc').read_text()
        bridge = (ROOT / 'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text()
        mcm = (ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text()
        native_handler = tracker.split('Function HandleNativeNPCDrink(', 1)[1].split('EndFunction', 1)[0]
        narrator = bridge.split('Function NarrateNPCMilkDrink(', 1)[1].split('EndFunction', 1)[0]
        lactacid_guard = native_handler.split('If drinkKind == 2 && !establishedMilkmaid', 1)[1].split('EndIf', 1)[0]
        self.assertIn('MME Lactacid conversion owned', lactacid_guard)
        self.assertNotIn('NarrateNPCMilkDrink', lactacid_guard)
        self.assertEqual(native_handler.count('MMEAlertsSkyrimNet.NarrateNPCMilkDrink'), 3)
        self.assertIn('NarrateNPCMilkDrink(drinker, False, genericReaction, diagnosticTest)', native_handler)
        self.assertIn('NarrateNPCMilkDrink(drinker, False, ordinaryReaction, diagnosticTest)', native_handler)
        self.assertIn('NarrateNPCMilkDrink(drinker, False, renderedReaction, diagnosticTest)', native_handler)
        self.assertLess(native_handler.index('03 COMPLETE | ordinary adult'), native_handler.index('NarrateNPCMilkDrink(drinker, False, ordinaryReaction'))
        self.assertIn('NarrateNPCMilkDrink(target, dialogueRequest, renderedReaction)', dialogue)
        self.assertIn('Bool diagnosticTest = False', bridge)
        self.assertIn('ResolveActorName(drinker, "The drinker")', narrator)
        self.assertIn('diagnosticTest ||', narrator)
        self.assertIn('If !diagnosticTest && last >= 0.0', narrator)
        self.assertIn('If !diagnosticTest\n            JsonUtil.SetFloatValue', narrator)
        self.assertEqual(narrator.count('SkyrimNetApi.DirectNarration('), 1)
        self.assertIn('short, humorous, suggestive, and playful reaction', narrator)
        self.assertIn('04 SKYRIM.NET DISPATCH', narrator)
        self.assertIn('05 SKYRIM.NET ACCEPTED', narrator)
        self.assertIn('Give Milk dialogue or globally detected adult NPC milk drinking', mcm)

    def test_opening_does_not_apply_or_gesture(self):
        body = SOURCE.split('Function Fragment_RefreshBlacksmithArmorState(', 1)[1].split('EndFunction', 1)[0]
        self.assertNotIn('PlayIdle', body)
        self.assertNotIn('TryApplyReverseLeveling', body)
        self.assertEqual(body.count('Parent.Fragment_00(akSpeakerRef)'), 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
