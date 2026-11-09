"""Protect the original MCM boundary and quick-settings integration contracts."""
from localization_contract import unlocalize
from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]
original = unlocalize((ROOT / 'Source/MMECompatibilityOverrides/MilkMCM.psc').read_text())
original = original.replace('\t\t\t\t\t; Fixed-mode preview shares the fuel-weighted bonus calculation.\n\t\t\t\t\tFinalMilkTick += MMEFixedLactacid.BonusMilk(MaidlistA[MaidIndex], MilkTick, LactacidCnt, 1)\n', '', 1)
restored = original.split('\n; MME Extensions: derive the original menu label')[0]
restored = restored.replace('\n\tMMEExtSyncDifficulty()', '', 1)
restored = restored.replace('\n\t\tMMEExtSyncDifficulty()', '', 1)
restored = restored.replace('MMEExtDifficultyLabel())', 'Preset[PresetIndex])', 1)
restored = restored.replace('\t\tIf index < 0 || index > 5\n\t\t\tReturn\n\t\tEndIf\n', '', 1)
assert hashlib.sha256(restored.encode()).hexdigest() == '6794ee1ce55782e804ccbaa8e44f5170858267cf4f57a2bfc922bbd45e101a62', 'Original MCM changed beyond the reviewed sync patch'

facade = unlocalize((ROOT / 'Source/Scripts/MMEOriginalSettings.psc').read_text())
mcm = unlocalize((ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text())
states = set(re.findall(r'Add\w+OptionST\("(OG\w+)"', facade))
assert len(states) == 14
for state in states:
    assert re.search(r'(?m)^State ' + state + r'\s*$', mcm), state
assert 'JsonUtil.Set' not in facade, 'MME values must not acquire a second authority'
assert not re.search(r'(?i)RegisterFor.*Update|Utility.Wait|AssignSlot|SetMilkCurrent', re.sub(r';[^\n]*', '', facade)), 'Quick settings must not poll, convert actors or replace milk calculations'
assert 'While index < maids.Length' in facade and 'Actor target = maids[index]' in facade
assert 'milk.PostMilk(target)' in facade and 'milk.CurrentSize(target)' in facade
assert 'milk.MilkE.InitializeMilkProperties()' in facade
assert not re.search(r'StorageUtil.SetFloatValue\((?!None, "MME.Progression.Level")', facade), 'Do not overwrite per-maid growth values'
assert 'Debug.Trace(' not in facade and 'MMELog.MasterDiagnostic(' in facade
assert 'MMEOriginalSettings.DrawBody(Self)' in mcm
assert mcm.index('MMEOriginalSettings.DrawGeneralAt(Self, 7)') < mcm.index('AddHeaderOption("Milk Maid Roster")')
generator = unlocalize((ROOT / 'tools/generate_ostim_only.py').read_text())
assert "variants['MilkMCM'] = (ROOT / 'Source/MMECompatibilityOverrides/MilkMCM.psc').read_text()" in generator
build = unlocalize((ROOT / 'build-package.ps1').read_text())
assert '$scriptNames += "MMEOriginalSettings"' in build
assert {"MilkQUEST", "MilkMCM"} <= set(re.findall(r'"([^"\n]+)"', re.search(r'\$mmeCompatibilityOverrideNames = @\(([^\n]+)\)', build).group(1)))
print('PASS: 14 mirrored controls; original MCM only has reviewed sync/bonus-preview changes; single authority, safe refresh boundaries and backend packaging wired')
