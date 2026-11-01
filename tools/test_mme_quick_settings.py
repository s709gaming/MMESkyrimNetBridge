"""Protect the original MCM boundary and quick-settings integration contracts."""
from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]
original = (ROOT / 'Source/MMECompatibilityOverrides/MilkMCM.psc').read_text()
restored = original.split('\n; MME Extensions: derive the original menu label')[0]
restored = restored.replace('\n\tMMEExtSyncDifficulty()', '', 1)
restored = restored.replace('\n\t\tMMEExtSyncDifficulty()', '', 1)
restored = restored.replace('MMEExtDifficultyLabel())', 'Preset[PresetIndex])', 1)
restored = restored.replace('\t\tIf index < 0 || index > 5\n\t\t\tReturn\n\t\tEndIf\n', '', 1)
assert hashlib.sha256(restored.encode()).hexdigest() == '6794ee1ce55782e804ccbaa8e44f5170858267cf4f57a2bfc922bbd45e101a62', 'Original MCM changed beyond the reviewed sync patch'

facade = (ROOT / 'Source/Scripts/MMEOriginalSettings.psc').read_text()
mcm = (ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text()
states = set(re.findall(r'Add\w+OptionST\("(OG\w+)"', facade))
assert len(states) == 13
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
generator = (ROOT / 'tools/generate_ostim_only.py').read_text()
assert "variants['MilkMCM'] = (ROOT / 'Source/MMECompatibilityOverrides/MilkMCM.psc').read_text()" in generator
build = (ROOT / 'build-package.ps1').read_text()
assert '$scriptNames += "MMEOriginalSettings"' in build
assert '$mmeCompatibilityOverrideNames = @("MilkQUEST", "MilkMCM")' in build
print('PASS: 13 mirrored controls; original MCM only has reviewed sync changes; single authority, safe refresh boundaries and backend packaging wired')
