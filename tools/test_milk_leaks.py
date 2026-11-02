"""Safety contracts, not a substitute for live Papyrus/visual acceptance."""
from pathlib import Path
import json,re,unittest,xml.etree.ElementTree as ET
from types import SimpleNamespace as NS
from test_tentacle_tiers import translate
ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding='utf-8-sig')
class MilkLeakSafety(unittest.TestCase):
    def test_visual_leaks_allow_furniture_but_keep_busy_guards(self):
        service=read('Source/Scripts/MMEMilkLeaks.psc')
        self.assertNotIn('bInFurniture',service)
        for sit,furniture in [(0,None),(3,'chair'),(0,'leaning desk'),(4,'chair')]:
            flags={'combat':False,'scene':None,'framework':False,'milk':''}
            actor=NS(IsChild=lambda:False,IsDead=lambda:False,IsDisabled=lambda:False,
                     Is3DLoaded=lambda:True,GetDistance=lambda other:10,
                     IsInCombat=lambda:flags['combat'],GetCurrentScene=lambda:flags['scene'],
                     GetSitState=lambda:sit,GetFurnitureReference=lambda:furniture)
            ns={'Game':NS(GetPlayer=lambda:None),
                'MMEOStimIntegration':NS(IsActorBusy=lambda target:flags['framework']),
                'MMESelfMilking':NS(GetInvalidReason=lambda *args:flags['milk'])}
            exec(translate('BlockReason','target',service),ns)
            self.assertEqual(ns['BlockReason'](actor),'')
            flags['combat']=True;self.assertEqual(ns['BlockReason'](actor),'in combat');flags['combat']=False
            flags['scene']='scene';self.assertEqual(ns['BlockReason'](actor),'scene active');flags['scene']=None
            flags['framework']=True;self.assertEqual(ns['BlockReason'](actor),'framework scene');flags['framework']=False
            flags['milk']='actor is already milking';self.assertEqual(ns['BlockReason'](actor),flags['milk'])
    def test_eligibility_footprints_are_changed_only_and_master_gated(self):
        service=read('Source/Scripts/MMEMilkLeaks.psc')
        data={};master=[1];records=[]
        ns={'StorageUtil':NS(GetStringValue=lambda a,k,d:data.get((a,k),d),SetStringValue=lambda a,k,v:data.__setitem__((a,k),v)),
            'JsonUtil':NS(GetIntValue=lambda *args:master[0]),'settings':'settings','Record':lambda:records.append(True)}
        source=re.sub(r'(?m)^\s*Trace\("eligibility changed.*$', '        Record()',service)
        exec(translate('TraceEligibility','target,reason',source),ns)
        for _ in range(50):ns['TraceEligibility']('Hulda','')
        self.assertEqual(len(records),1)
        ns['TraceEligibility']('Hulda','scene active');self.assertEqual(len(records),2)
        master[0]=0;ns['TraceEligibility']('Player','in combat');self.assertEqual(len(records),2)
        self.assertIn('sitState=',service);self.assertIn('furniture=',service)
    def test_external_effects_are_never_modified(self):
        service=read('Source/Scripts/MMEMilkLeaks.psc')
        visual=read('fomod/choices/milk-leaks/Source/Scripts/MMELeakVisual.psc')
        self.assertNotRegex(service+visual,r'\.(?:StopNippleSquirt|ForceStopNippleSquirt|StopAllNippleSquirts|SetModelPath|SetLevel)\(')
        self.assertNotRegex(service,r'(?:UnequipItem|RemoveItem)\(ExternalArmor')
        for contract in ['existing spray','external spray pending','external request/disabled during setup','yield to external spray']:
            self.assertIn(contract,service)
        self.assertIn('IsEquipped(ExternalArmor)',service)
        self.assertIn('Form visualArmor = GetBaseObject()',visual)
        self.assertIn('!wearer.IsEquipped(visualArmor)',visual)
        self.assertNotIn('GetBaseObject()',visual.split('Utility.Wait(0.1)',1)[1])
    def test_no_milk_consumption_conversion_or_movement_lock(self):
        service=read('Source/Scripts/MMEMilkLeaks.psc')
        self.assertNotRegex(service,r'\.(?:setMilkCurrent|changeMilkCurrent|MilkMaidAdd|DisablePlayerControls|SetUnconscious|SetDontMove|SendAnimationEvent)\(')
        self.assertIn('MME_Storage.getMilkCurrent(target) / capacity',service)
        self.assertIn('MMEArmorScript.IsMMEMilkMaid(target, milk)',service)
        self.assertIn('target.IsChild()',service)
        self.assertIn('MMEOStimIntegration.IsActorBusy(target)',service)
        self.assertIn('MMESelfMilking.GetInvalidReason',service)
    def test_sustained_low_and_threshold_exit(self):
        service=read('Source/Scripts/MMEMilkLeaks.psc')
        advance=service.split('Function Advance(Int slot)',1)[1].split('EndFunction',1)[0]
        self.assertIn('If stage < 0\n        stage = 0',advance)
        self.assertIn('/ capacity < Threshold()',advance)
        self.assertIn('reason = "fullness below threshold"',advance)
        self.assertNotIn('sequence complete',advance)
        self.assertIn('If visibleStages[slot] != stage',advance)
        self.assertIn('started[slot] = started[slot] - 10.0',service)
        self.assertNotIn('Narrate(',service)
        self.assertNotIn('SkyrimNet',service)
        self.assertNotIn('RegisterForUpdate(',service)
        self.assertIn('Quest.GetQuest("OninusLactis")',read('fomod/choices/milk-leaks/Source/Scripts/MMELeakVisual.psc'))
        self.assertIn('rightOffset[0] = -offset[0]',read('fomod/choices/milk-leaks/Source/Scripts/MMELeakVisual.psc'))
    def test_optional_installation_and_defaults(self):
        api=read('Source/Scripts/MMEMilkLeakAPI.psc')
        self.assertIn('Game.GetModByName("MME Extensions - Milk Leaks.esp") == 255',api)
        self.assertNotIn('milkLeakIntensity',api)
        self.assertIn('maximumStages[slot] = 2',read('Source/Scripts/MMEMilkLeaks.psc'))
        self.assertIn('"milkLeakThreshold", 100.0',api)
        self.assertNotIn("milkLeakNarration",api)
        tree=ET.fromstring(read('fomod/ModuleConfig.xml'))
        option=tree.find(".//plugin[@name='Oninus Lactis milk leaking']")
        self.assertIsNotNone(option)
        self.assertEqual(option.find('.//fileDependency').attrib,{'file':'OninusLactis.esp','state':'Active'})
        self.assertEqual(option.find('.//pattern/type').attrib['name'],'Recommended')
        for node in option.findall('./files/*'):
            self.assertTrue((ROOT/node.attrib['source']).exists(),node.attrib)
    def test_shared_scheduler_and_master_logging(self):
        controller=read('Source/Scripts/MMEAlertsController.psc')
        # Scope to the actual function: presence elsewhere missed the original bug.
        scan=re.search(r'(?ms)^Function ScanNearbyMilkMaids\([^\n]*\)\n(.*?)^EndFunction',controller).group(1)
        self.assertEqual(controller.count('MMEMilkLeakAPI.Observe(nearbyActors)'),1)
        self.assertIn('MMEMilkLeakAPI.Observe(nearbyActors)',scan)
        self.assertLess(scan.index('MMEMilkLeakAPI.Observe'),scan.index('If !processReactions'))
        self.assertIn('If milkLeakDue || capacityDue',controller)
        polling=re.search(r'(?ms)^Function UpdatePolling\(\)\n(.*?)^EndFunction',controller).group(1)
        self.assertIn('If MMEMilkLeakAPI.Manager() != None\n        NextMilkLeakUpdate = now + 15.0',polling)
        service=read('Source/Scripts/MMEMilkLeaks.psc')
        self.assertIn('MMELog.MasterDiagnostic("[MME Milk Leaks]',service)
        self.assertIn('>= 60.0',service)
        self.assertNotIn('Debug.Notification',service)
        self.assertNotRegex(service,r'(tracked|visuals|started|maximumStages|visibleStages|busy)\s*==\s*None')
        self.assertIn('scanNow - lastScanTrace >= 60.0',service)
        self.assertIn('MMELeaks.ThresholdState',service)
    def test_simplified_mcm_and_array_guards(self):
        mcm=read('Source/Scripts/MMEAlertsMCM.psc')
        self.assertNotIn('AddSliderOptionST("LeakIntensity"',mcm)
        self.assertNotIn('AddTextOptionST("LeakEditor"',mcm)
        self.assertIn('AddToggleOptionST("LeakDetected"',mcm)
        facade=read('Source/Scripts/MMEOriginalSettings.psc')
        self.assertNotRegex(facade,r'(?:maids|milk.MilkMaid)\s*==\s*None')
        self.assertIn('maids.Find(candidate) < 0',facade)
        self.assertIn("'MMEOriginalSettings'",read('tools/Test-ScanArrayContracts.ps1'))
    def test_leak_narration_removed_fullness_preserved(self):
        schema=json.loads(read('tools/narration-schema.json'))
        self.assertNotIn('MilkLeaks',schema)
        self.assertIn('Fullness',schema)
        self.assertFalse((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/MilkLeaks.json').exists())
        mcm=read('Source/Scripts/MMEAlertsMCM.psc')
        self.assertNotIn('State LeakNarration',mcm)
        self.assertNotIn('State LeakCooldown',mcm)
        self.assertNotIn('openMilkLeaksEditor',read('fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster/dashboard.js'))
if __name__=='__main__':unittest.main()
