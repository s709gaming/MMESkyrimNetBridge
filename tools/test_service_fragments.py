"""Exercise production service fragment sequencing with mocked vendors/services."""
import re
import unittest
from pathlib import Path
from types import SimpleNamespace

from add_service_completion_fragments import TARGETS, patch_plugin

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Source/Scripts/MMEBlacksmithDialogue.psc').read_text()


def fragment(name, env):
    body = re.search(r'Function Fragment_' + name + r'\([^\n]*\)\n(.*?)EndFunction', SOURCE, re.S)[1]
    output = ['def run(akSpeakerRef):', '    global serviceSucceeded']
    indent = 1
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith(';'):
            continue
        line = re.sub(r' as (Actor|Idle)\b', '', line)
        line = re.sub(r'^(Actor|Idle) ', '', line)
        line = line.replace('&&', ' and ')
        line = re.sub(r'!(?!=)', 'not ', line)
        if line == 'EndIf':
            indent -= 1
            continue
        if line.startswith('If '):
            output.append('    ' * indent + 'if ' + line[3:] + ':')
            indent += 1
        else:
            output.append('    ' * indent + re.sub(r'^Return\b', 'return', line))
    exec('\n'.join(output), env)
    return env['run']


class ServiceTests(unittest.TestCase):
    def test_only_successful_end_gestures_once_for_each_service(self):
        for action in TARGETS.values():
            for success in (True, False):
                with self.subTest(action=action, success=success):
                    played = []
                    idle = object()
                    vendor = SimpleNamespace(IsDead=lambda: False, Is3DLoaded=lambda: True,
                                             PlayIdle=played.append)
                    api = SimpleNamespace(**{'Try' + x: lambda *args: success for x in TARGETS.values()})
                    env = dict(serviceSucceeded=True, MMEAlchemistDialogue=api, MMEMageDialogue=api,
                               TryAddMilkArmor=api.TryAddMilkArmor, TryRemoveMilkArmor=api.TryRemoveMilkArmor,
                               MMEExt_AlchemistLivingArmorState=None, MMEExt_MageParasiteArmorState=None,
                               Game=SimpleNamespace(GetFormFromFile=lambda form, plugin: idle
                                   if (form, plugin) == (0x0B5E20, 'Skyrim.esm') else None))
                    begin = fragment(action, env)
                    end = fragment('ServiceCompleted', env)
                    begin(vendor)
                    self.assertEqual(played, [])
                    end(vendor)
                    end(vendor)
                    self.assertEqual(played, [idle] if success else [])

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
