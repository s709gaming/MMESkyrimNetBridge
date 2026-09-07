"""Execute the production Papyrus check body against mocked MME storage.

This small translator covers ONLY the statements in LevelBase, CaptureBaseline,
and CheckProgress, failing on unsupported syntax. It is not a Papyrus VM or an
in-game concurrency test. Run: python tools/test_reverse_leveling.py
"""
import re
import unittest
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Source/Scripts/MMEReverseLevel.psc').read_text()


def expression(text):
    text = text.replace('&&', ' and ').replace('||', ' or ')
    text = re.sub(r'!(?!=)', 'not ', text)
    # Casts used by these functions: parenthesised expressions or bare calls.
    text = re.sub(r'\(level as Float\)', 'float(level)', text, flags=re.I)
    text = re.sub(r'\((StorageUtil.GetFloatValue\([^\n]+?\)) as Int\)', r'int(\1)', text, flags=re.I)
    text = re.sub(r'(StorageUtil.GetFloatValue\([^\n]+?\)) as Int', r'int(\1)', text, flags=re.I)
    if re.search(r'\bas\s+(Int|Float)', text, re.I):
        raise ValueError(f'Unsupported cast: {text}')
    return text


def translate(name, parameters):
    match = re.search(r'(?im)^(?:(?:Float|Int) )?(?:Function|Event) ' + name + r'\([^\n]*\).*?\n(.*?)^End(?:Function|Event)', SOURCE, re.S | re.M)
    if not match:
        raise ValueError(name)
    body = '\n'.join(line.split(';')[0] for line in match[1].splitlines())
    body = body.replace('\\\n', ' ')
    out = [f'def {name}({parameters}):',
           '    global baseline, baselineLevel, multiplier, candidateLevel, candidateProgress, candidateSince, milkingDone']
    indent = 1
    for line in body.splitlines():
        line = line.strip()
        if line.startswith("TraceState("):  # diagnostic string coercion is Papyrus-specific
            continue
        if not line:
            continue
        if line.lower() in ('endif', 'endwhile'):
            indent -= 1
            continue
        if line.lower().startswith('elseif '):
            indent -= 1
            out.append('    ' * indent + 'elif ' + expression(line[7:]) + ':')
            indent += 1
            continue
        if line.lower() == 'else':
            indent -= 1
            out.append('    ' * indent + 'else:')
            indent += 1
            continue
        for keyword in ('If', 'While'):
            if line.startswith(keyword + ' '):
                out.append('    ' * indent + keyword.lower() + ' ' + expression(line[len(keyword)+1:]) + ':')
                indent += 1
                break
        else:
            line = re.sub(r'^(Int|Float) ', '', line)
            line = re.sub(r'^Return\b', 'return', line)
            out.append('    ' * indent + expression(line))
    if indent != 1:
        raise ValueError('Unbalanced block')
    return '\n'.join(out)


class Harness:
    def __init__(self, level, progress, scale=10):
        self.level, self.progress = level, progress
        self.level_writes = []
        self.milking = False
        self.removed = False
        self.now = 1.0
        self.real = 0.0
        self.notifications = []
        self.q = SimpleNamespace(TimesMilkedMult=scale, BeingMilkedPassive=object())
        storage = SimpleNamespace(GetFloatValue=self.get, SetFloatValue=self.set)
        mme = SimpleNamespace(getMaidLevel=lambda _: self.level, setMaidLevel=self.set_level)
        self.env = dict(StorageUtil=storage, MME_Storage=mme, milkController=self.q,
                        playerActor=SimpleNamespace(HasSpell=lambda _: self.milking),
                        Utility=SimpleNamespace(GetCurrentGameTime=lambda: self.now, GetCurrentRealTime=lambda: self.real),
                        Debug=SimpleNamespace(Notification=self.notifications.append),
                        active=True, expiresAt=2.0, multiplier=scale,
                        progressKey='MME.MilkMaid.TimesMilked', RemoveReverseLeveling=self.remove,
                        RegisterForSingleUpdate=lambda _: None)
        for name, params in [('LevelBase', 'level, scale'), ('CaptureBaseline', ''), ('CheckProgress', ''),
                             ('OnMilkingDone', 'actorForm, bottles, boobgasmCount, cumCount'),
                             ('OnMilkCycleComplete', 'eventName, strArg, numArg, sender')]:
            exec(translate(name, params), self.env)
        self.env['CaptureBaseline']()

    def get(self, actor, key):
        return float(self.level) if key == 'MME.MilkMaid.Level' else self.progress

    def set(self, actor, key, value):
        assert key == 'MME.MilkMaid.TimesMilked'
        self.progress = value

    def set_level(self, actor, value):
        self.level_writes.append(value)
        self.level = value

    def remove(self, notify):
        self.removed = True
        self.env['active'] = False

    def sample(self, count=1):
        for _ in range(count):
            self.env['CheckProgress']()


class ReverseTests(unittest.TestCase):
    def finish(self, h):
        h.env['OnMilkingDone'](h.env['playerActor'], 1, 0, 0)
        h.sample(2)

    def test_ten_to_nine_once_even_for_large_gain(self):
        h = Harness(10, 0)
        h.progress = 100000
        self.finish(h)
        h.env['milkingDone'] = True  # duplicate completion
        h.sample(5)
        self.assertEqual((h.level, h.progress), (9, 0))
        self.assertEqual(h.level_writes, [9])
        self.assertEqual(h.notifications, ['Your breasts feel lighter. Milk maid level decreased by 1.'])

    def test_no_decrement_during_multiple_gushes(self):
        h = Harness(10, 0)
        h.milking = True
        for gain in (1, 50, 2000):
            h.progress += gain
            h.sample(4)
        self.assertEqual(h.level_writes, [])
        h.milking = False
        self.finish(h)
        self.assertEqual(h.level, 9)

    def test_next_session_can_decrease_one_more(self):
        h = Harness(10, 0)
        h.progress = 5
        self.finish(h)
        h.progress = 20
        self.finish(h)
        self.assertEqual(h.level_writes, [9, 8])

    def test_level_up_during_milking_never_causes_multi_level_drop(self):
        h = Harness(5, 0)
        h.level, h.progress = 8, 30
        self.finish(h)
        self.assertEqual(h.level_writes, [7])

    def test_floor_no_false_notification(self):
        h = Harness(1, 0)
        h.progress = 5
        self.finish(h)
        self.assertEqual((h.level, h.progress), (0, 0))
        h.progress = 1
        self.finish(h)
        self.assertEqual((h.level, h.progress), (0, 0))
        self.assertEqual(len(h.notifications), 1)

    def test_stale_baseline_cannot_reset_high_level_to_zero(self):
        h = Harness(0, 0)
        h.level, h.progress = 10, 10
        self.finish(h)
        self.assertEqual(h.level, 9)

    def test_dialogue_and_eventless_gain_never_authorize_downgrade(self):
        h = Harness(10, 0)
        h.progress = 1
        h.sample()
        h.real = 8
        h.sample()
        self.assertEqual(h.level, 10)
        h.progress = 5
        h.sample()
        h.real = 17
        h.sample()
        self.assertEqual(h.level, 10)
        h.real = 18
        h.sample(3)
        h.real = 3600
        h.env['OnMilkCycleComplete']('MME_MilkCycleComplete', '', 0, None)
        h.sample(20)
        self.assertEqual(h.level_writes, [])
        self.assertEqual(h.progress, 5)
        self.assertEqual(h.notifications, [])

    def test_empty_or_other_actor_milking_cannot_authorize_downgrade(self):
        h = Harness(10, 0)
        h.progress = 20
        for actor, bottles in [(h.env['playerActor'], 0), (object(), 5)]:
            h.env['OnMilkingDone'](actor, bottles, 0, 0)
            h.real += 60
            h.sample(3)
        self.assertEqual(h.level_writes, [])
        self.finish(h)
        self.assertEqual(h.level_writes, [9])

    def test_external_loss_and_difficulty_change(self):
        h = Harness(5, 10)
        h.progress = 5
        self.finish(h)
        self.assertEqual(h.level_writes, [])
        h.q.TimesMilkedMult = 50
        h.sample(2)
        self.assertEqual((h.level, h.progress), (5, 5))
        h.q.TimesMilkedMult = 0
        h.sample()
        self.assertTrue(h.removed)

    def test_expired_or_removed_never_writes(self):
        for expired in (True, False):
            h = Harness(10, 0)
            h.progress = 20
            h.env['milkingDone'] = True
            h.sample()
            if expired:
                h.now = 2
            else:
                h.env['active'] = False
            h.sample()
            self.assertEqual(h.level_writes, [])

    def test_normalisation_without_gain(self):
        h = Harness(2, 35)
        h.level, h.progress = 3, 5
        self.finish(h)
        self.assertEqual(h.level_writes, [])

    def test_required_level_clamps(self):
        for configured, expected in [(-1,1),(0,1),(1,1),(5,5),(10,10),(11,10)]:
            env = {'JsonUtil': SimpleNamespace(GetIntValue=lambda *args: configured)}
            exec(translate('GetRequiredLevel', ''), env)
            self.assertEqual(env['GetRequiredLevel'](), expected)

    def test_mcm_threshold_is_not_a_player_level_setter(self):
        mcm=(ROOT/'Source/Scripts/MMEAlertsMCM.psc').read_text()
        mage=(ROOT/'Source/Scripts/MMEMageDialogue.psc').read_text()
        self.assertNotIn('SetPlayerMaidLevel',mcm)
        self.assertIn('>= MMEReverseLevel.GetRequiredLevel()',mage)
        self.assertIn('Pages[8] = "Misc"',mcm)
        self.assertIn('SetCursorPosition(1)\n        AddHeaderOption("Debug")',mcm)

    def test_all_levels_difficulties_and_gain_sizes(self):
        for scale in (10,25,50,75,100,150):
            for level in range(11):
                for gain in (0.25,scale,100000):
                    h=Harness(level,0,scale)
                    h.progress=gain
                    self.finish(h)
                    self.assertEqual((h.level,h.progress),(max(0,level-1),0))


if __name__ == '__main__':
    unittest.main(verbosity=2)
