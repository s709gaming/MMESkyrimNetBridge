"""Check page ownership and SkyUI buffer positions for the current MCM layout.

This models drawing calls only, not Papyrus execution or live game behavior.
Flags do not change slot occupancy. Missing-MME helper alternatives are omitted
from the full/available layout, which exercises the largest control count.
"""
from localization_contract import unlocalize
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
MCM = unlocalize((ROOT / 'Source/Scripts/MMEAlertsMCM.psc').read_text())
FACADE = unlocalize((ROOT / 'Source/Scripts/MMEOriginalSettings.psc').read_text())


def function(source, name):
    match = re.search(r'(?m)^Function ' + name + r'\([^\n]*\)(?: Global)?\n(.*?)^EndFunction', source, re.S | re.M)
    assert match, name
    return match[1]


builders = dict(re.findall(r'(?ms)^Function (Draw\w+Page)\(\)\n(.*?)^EndFunction', MCM))
assert len(builders) == 11
pages = function(MCM, 'SetPageNames')
assert 'new String[11]' in pages and 'nimations' not in pages
assert '"Debug"' in pages and '"Armor Reactions"' in pages

homes = {
    'installedBackendOption': 'DrawGeneralPage',
    'masterEnableOption': 'DrawGeneralPage',
    'ostimStatusOption': 'DrawGeneralPage',
    'ostimBreastfeedingOption': 'DrawGeneralPage',
    'ostimBreastfeedingDurationOption': 'DrawMilkDrinkingPage',
    'playerDrinkAnimationOption': 'DrawMilkDrinkingPage',
    'npcDrinkAnimationOption': 'DrawMilkDrinkingPage',
    'capacityOption': 'DrawBodyPage',
    'pollingIntervalOption': 'DrawBodyPage',
    'playerFullSelfMilkAnimationOption': 'DrawBodyPage',
    'npcFullSelfMilkAnimationOption': 'DrawBodyPage',
    'breastBounceIntervalOption': 'DrawBodyPage',
    'timedArmorDurationOption': 'DrawArmorPage',
    'timedArmorReleaseOption': 'DrawTroubleshootPage',
    'elsieBreastfeedingTestOption': 'DrawTroubleshootPage',
    'estrusTestTypeOption': 'DrawTroubleshootPage',
    'estrusTestRunOption': 'DrawTroubleshootPage',
    'estrusTestResultOption': 'DrawTroubleshootPage',
    'runArmorInjectionCheckOption': 'DrawTroubleshootPage',
    'reverseApplyOption': 'DrawTroubleshootPage',
    'milkMaidThoughtsDebugOption': 'DrawDebugPage',
    'debugMilkReportOption': 'DrawDebugPage',
    'playerLivingArmorEquipAnimationOption': 'DrawArmorThoughtsPage',
}
assignments = {}
for page, text in builders.items():
    for option in re.findall(r'(?m)^\s*(\w+) = Add\w+Option\(', text):
        assert option not in assignments, f'Duplicate control: {option}'
        assignments[option] = page
for option, page in homes.items():
    assert assignments.get(option) == page, (option, assignments.get(option), page)
assert len(assignments) == 330
assert 'MMESexLabBreastfeedingBackend.GetBackendName()' in MCM
assert 'does not switch the installed' in MCM
assert 'Milk Mastery (Maid Slots)' in FACADE and 'unlocks more Milk Maid slots' in MCM


def draw(text, cursor, occupied, variables=None):
    variables = dict(variables or {})
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('While tierIndex < 4'):
            end = next(n for n in range(i + 1, len(lines)) if lines[n].strip() == 'EndWhile')
            for tier in range(4):
                cursor = draw('\n'.join(lines[i + 1:end]), cursor, occupied, dict(variables, tierIndex=tier))
            i = end + 1
            continue
        if 'DrawMilkLeakOptions()' in line:
            cursor = draw(function(MCM, 'DrawMilkLeakOptions'), cursor, occupied)
        elif 'MMEOriginalSettings.DrawBody(Self)' in line:
            cursor = draw(function(FACADE, 'DrawBody'), cursor, occupied)
        elif 'MMEOriginalSettings.DrawGeneralAt(Self,' in line:
            row = int(re.search(r'Self, (\d+)', line)[1])
            cursor = draw(function(FACADE, 'DrawGeneralAt'), cursor, occupied, {'firstRow': row})
        elif 'SetCursorPosition(' in line:
            expression = re.search(r'SetCursorPosition\((.*)\)', line)[1]
            assert re.fullmatch(r'[\w\s+*()]+', expression), expression
            cursor = eval(expression, {'__builtins__': {}}, variables)
        elif re.search(r'\bAdd\w+Option(?:ST)?\(', line):
            if '"Original MME settings", "Unavailable"' not in line:
                assert 0 <= cursor < 128, f'SkyUI buffer overflow: {cursor} {line}'
                assert cursor not in occupied, f'Overlapping controls at {cursor}: {occupied.get(cursor)} / {line}'
                occupied[cursor] = line
                cursor += 2
        i += 1
    return cursor


for page, text in builders.items():
    occupied = {}
    draw(text, 0, occupied)
    print(f'PASS: {page}: {len(occupied)} drawing slots; no overlap or buffer overflow')
print('PASS: 11 pages, 340 unique controls including Milk Leaking and completion narration, feature ownership and retained Debug modes')

