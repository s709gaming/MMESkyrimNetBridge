"""Execute production readiness guards with mocked engine boundaries; no runtime acceptance claim."""
from pathlib import Path
from types import SimpleNamespace as NS
import re
import unittest
from test_tentacle_tiers import translate, Memory
ROOT = Path(__file__).resolve().parents[1]
BRIDGE = (ROOT/'Source/Scripts/MMEArousalBridge.psc').read_text()
ELSIE = (ROOT/'Source/Scripts/MMEElsieBreastfeeding.psc').read_text()

class Store(Memory):
    UnsetIntValue = Memory.UnsetFloatValue

class Guards(unittest.TestCase):
    def setUp(self):
        self.mods = {'SexLabAroused.esm'}
        self.legacy = True
        self.now = 0.0
        self.session = 1
        self.lookups = []
        self.reads = []
        self.alarms = []
        self.traces = []
        self.framework = NS(slaArousalBlocked=object(), slaArousal=object(), slaExposure=object(),
                            GetActorArousal=lambda actor: self.reads.append(actor) or 65)
        self.ns = {'Game':NS(IsPluginInstalled=lambda mod:mod in self.mods, GetFormFromFile=self.form),
                   'Legacy':lambda framework:framework if self.legacy else None,
                   'Utility':NS(GetCurrentRealTime=lambda:self.now), 'StorageUtil':Store(),
                   'MMEExtensionsNative':NS(GetMovementSlapSession=lambda:self.session, GetArousalFrameworkKind=lambda framework:1 if self.legacy else 0),
                   'MMELog':NS(MasterDiagnostic=self.traces.append, Alarm=self.alarms.append)}
        source = BRIDGE.replace('framework as Quest','framework').replace('(framework) as slaUtilScr','Legacy(framework)').replace(' as slaFrameworkScr','').replace(' as Faction','')
        source = re.sub(r'(?m)^(\s*)(slaFrameworkScr|slaUtilScr|Faction) ',r'\1',source)
        source = source.replace('+ actorRef', '+ str(actorRef)')
        source = source.replace('+ StorageUtil.GetIntValue(None, healthKey, 0)', '+ str(StorageUtil.GetIntValue(None, healthKey, 0))')
        for name,args in [('IsAvailable',''),('IsReady','actorRef=None'),('GetCurrentArousal','actorRef')]:
            exec(translate(name,args,source),self.ns)
        exec(translate('IsDetected','',ELSIE),self.ns)
    def form(self, ident, mod):
        self.lookups.append((ident,mod))
        if mod not in self.mods: raise AssertionError('Missing plugin was queried')
        return self.framework
    def test_absent_optional_plugins_never_query_forms(self):
        self.mods.clear()
        self.assertFalse(self.ns['IsDetected']())
        self.assertEqual(-1,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual([],self.lookups)
        self.assertEqual([],self.alarms)
    def test_healthy_legacy_uses_authoritative_read(self):
        self.assertEqual(65,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual(['actor'],self.reads)
    def test_missing_legacy_property_backoff_alarm_and_recovery(self):
        self.framework.slaArousalBlocked = None
        for moment in (0,1,5,10,30,35,40):
            self.now = moment
            self.assertEqual(-1,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual([],self.reads)
        self.assertEqual(1,len(self.alarms))
        # One backoff request at t=1 did not re-resolve the third-party quest.
        self.assertEqual(6,len(self.lookups))
        self.framework.slaArousalBlocked = object()
        self.now = 45
        self.assertEqual(65,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual(1,len(self.alarms))
    def test_modern_osl_ng_do_not_touch_legacy_properties(self):
        self.legacy = False
        del self.framework.slaArousalBlocked
        del self.framework.slaArousal
        del self.framework.slaExposure
        self.assertEqual(65,self.ns['GetCurrentArousal']('actor'))
    def test_plugin_name_does_not_bypass_a_broken_legacy_script(self):
        self.mods.add('OSLAroused.esp')
        self.framework.slaArousalBlocked=None
        self.assertEqual(-1,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual([],self.reads)
    def test_missing_quest_does_not_try_an_event_or_read(self):
        self.framework = None
        self.assertEqual(-1,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual([],self.reads)
        mutation=BRIDGE.split('Bool Function ApplyArousalAmountForActor(',1)[1].split('EndFunction',1)[0]
        self.assertLess(mutation.index('!IsReady(target)'), mutation.index('framework.UpdateActorExposure'))
        self.assertNotIn('ModEvent.Create',mutation)
    def test_missing_exposure_and_arousal_are_blocked_before_api(self):
        for prop in ('slaExposure','slaArousal'):
            previous = getattr(self.framework,prop)
            setattr(self.framework,prop,None)
            self.session += 1
            self.assertEqual(-1,self.ns['GetCurrentArousal']('actor'))
            self.assertEqual([],self.reads)
            setattr(self.framework,prop,previous)
    def test_unknown_scan_clears_pending_and_rebaselines(self):
        source=(ROOT/'Source/Scripts/MMEArousalEffects.psc').read_text()
        branch=source.split('; Unknown arousal must not become zero',1)[1].split('EndIf',1)[0]
        self.assertIn('ClearPendingReaction(candidate)',branch)
        self.assertIn('UnsetIntValue(candidate, "MMEExtensions.ArousalEffects.Generation")',branch)
        self.assertIn('UnsetIntValue(candidate, "MMEExtensions.ArousalEffects.Tier")',branch)
    def test_unavailable_native_metadata_suspends_api(self):
        self.ns['MMEExtensionsNative'].GetArousalFrameworkKind=lambda framework:-1
        self.assertEqual(-1,self.ns['GetCurrentArousal']('actor'))
        self.assertEqual([],self.reads)
    def test_native_checks_framework_parent_not_quest_sibling(self):
        source=(ROOT/'src/Plugin.cpp').read_text().split('std::int32_t GetArousalFrameworkKind(',1)[1].split('enum class SocialVenueKind',1)[0]
        self.assertIn('FindBoundObject(handle, "slaFrameworkScr", framework)',source)
        self.assertIn('parent = type->GetParent()',source)
        self.assertNotIn('FindBoundObject(handle, "slaUtilScr"',source)
    def test_load_session_discards_backoff(self):
        self.framework.slaArousalBlocked=None
        self.ns['GetCurrentArousal']('actor')
        self.framework.slaArousalBlocked=object()
        self.session+=1
        self.assertEqual(65,self.ns['GetCurrentArousal']('actor'))
    def test_actual_armor_conditions_preserve_naked_and_special_routes(self):
        for path in ['Source/MMECompatibilityOverrides/MilkPlayerLoadGame.psc',
                     'fomod/choices/sexlab-pplus/Source/Scripts/MilkPlayerLoadGame.psc']:
            source=(ROOT/path).read_text().split('Function Orgasm(',1)[1].split('EndFunction',1)[0]
            first=source.split('if maidArmor != none &&',1)[1].split('if StorageUtil.GetIntValue',1)[0]
            first='maidArmor != none &&'+first
            second=source.split('elseif maidArmor != none &&',1)[1].split('MME_Storage.changeMilkCurrent',1)[0]
            second='maidArmor != none &&'+second
            def expression(text):
                text=text.replace('\\','').replace('&&',' and ').replace('||',' or ').replace(' as Armor','')
                return ' '.join(re.sub(r'\bnone\b','None',text,flags=re.I).split())
            # No armor is an ordinary milking route; SLSD remains independent of armor.
            for name,kind,slsd,expected in [('',0,False,(False,False)),('',0,True,(True,False)),
                                          ('Cow outfit',0,False,(True,False)),('robe',2,False,(False,True)),
                                          ('robe',3,False,(False,True)),('Tentacle Armor',0,False,(False,True))]:
                env={'maidArmor':None if name=='' else object(), 'maidArmorName':name, 'akActor':'actor',
                     'MilkQ':NS(MilkCuirass=object(),MilkCuirassFuta=object(),MMEExtSLSDCheck=lambda actor:slsd),
                     'MMEItemAttachments':NS(GetClassFast=lambda actor,armor:kind),
                     'StringUtil':NS(Find=lambda text,part:text.find(part))}
                actual=tuple(bool(eval(expression(text),{},env)) for text in (first,second))
                self.assertEqual(expected,actual,(path,name,kind,slsd))
    def test_both_orgasm_facades_guard_name_without_naked_return(self):
        for path in ['Source/MMECompatibilityOverrides/MilkPlayerLoadGame.psc',
                     'fomod/choices/sexlab-pplus/Source/Scripts/MilkPlayerLoadGame.psc']:
            source=(ROOT/path).read_text().split('Function Orgasm(',1)[1].split('EndFunction',1)[0]
            self.assertNotRegex(source,r'(?i)maidArmor\.getname\(\).*\\')
            fragment=source.split('String maidArmorName = ""',1)[1].split('if maidArmor != none',1)[0]
            self.assertRegex(fragment,r'(?s)If maidArmor != None\s+maidArmorName = maidArmor.GetName\(\)\s+Else')
            self.assertNotIn('Return',fragment)
            self.assertIn('MilkQ.PostMilk(akActor)',source)

if __name__=='__main__': unittest.main()

