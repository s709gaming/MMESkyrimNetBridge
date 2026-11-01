"""Execute the shipped Papyrus arithmetic/branch subset against explicit cases.
Not a live VM test: engine storage, actor events and menu input need acceptance.
"""
from pathlib import Path
import hashlib
import math
import re
import unittest
import sys

ROOT = Path(__file__).resolve().parents[1]
HELPER = (ROOT / "Source/Scripts/MMEFixedLactacid.psc").read_text()
QUEST = (ROOT / "Source/MMECompatibilityOverrides/MilkQUEST.psc").read_text()
MCM = (ROOT / "Source/Scripts/MMEAlertsMCM.psc").read_text()


def evaluate(expression, values):
    expression = expression.replace("||", " or ").replace("&&", " and ")
    expression = re.sub(r"!(?!=)", " not ", expression)
    return eval(expression.strip(), {"__builtins__": {}}, values)


def execute(text, values):
    """Small strict interpreter: run source statements, never mirror formulas."""
    active = [True]
    for raw in text.splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line:
            continue
        if line.lower().startswith("if "):
            active.append(active[-1] and bool(evaluate(line[3:], values)))
        elif line.lower() == "endif":
            active.pop()
        elif not active[-1]:
            continue
        elif line.lower().startswith("return "):
            return evaluate(line[7:], values)
        elif re.match(r"(?:Failure|MMEFixedLactacid.TraceCycle)\(", line):
            continue  # Logging side effects are checked by contracts below.
        else:
            match = re.fullmatch(r"(?:(?:Float|Bool) )?(\w+) (\+=|-=|=) (.+)", line)
            assert match, "Unsupported source statement: " + line
            name, op, expression = match.groups()
            result = evaluate(expression, values)
            values[name] = result if op == "=" else values[name] + result * (1 if op == "+=" else -1)
    assert len(active) == 1


BONUS_BODY = re.search(r"Float Function BonusMilk\([^\n]+\n(.*?)EndFunction", HELPER, re.S)[1]
FIXED_BODY = QUEST.split("If MMEFixedLactacid.IsEnabled()", 1)[1].split("ElseIf LactacidDecayRate", 1)[0]


class Service:
    def __init__(self, enabled=True, percent=50):
        self.enabled, self.percent = enabled, percent

    def IsEnabled(self):
        return self.enabled

    def BonusMilk(self, target, normalMilk, lactacid, hours):
        return execute(BONUS_BODY, dict(target=target, normalMilk=normalMilk, lactacid=lactacid,
                                        hours=hours, IsEnabled=self.IsEnabled, BonusPercent=lambda: self.percent))


def cycle(total, fuel, hours, elapsed=None, percent=50, target="player"):
    service = Service(percent=percent)
    values = dict(akActor=target, MilkTick=total, LactacidCnt=fuel, t=hours,
                  MMEElapsedHours=hours if elapsed is None else elapsed, MMEFixedLactacid=service)
    execute(FIXED_BODY, values)
    return values["MilkTick"], values["LactacidCnt"]


class FixedLactacidTests(unittest.TestCase):
    def test_player_and_npc(self):
        for target in ("player", "npc"):
            self.assertAlmostEqual(cycle(0.4, 2, 1, target=target)[0], 0.6)
            self.assertEqual(cycle(0.4, 2, 1, target=target)[1], 1)

    def test_expiry_and_repeat(self):
        milk, fuel = cycle(0.4, 1, 1)
        self.assertAlmostEqual(milk, 0.6)
        self.assertEqual(cycle(0.4, fuel, 1), (0.4, 0))

    def test_sleep_splits_boosted_and_normal_hours(self):
        milk, fuel = cycle(4.8, 2, 12)
        self.assertAlmostEqual(milk, 5.2)
        self.assertEqual(fuel, 0)
        self.assertAlmostEqual(milk, sum(cycle(0.4, max(0, 2-i), 1)[0] for i in range(12)))

    def test_fractional_fuel(self):
        self.assertEqual(cycle(0.4, 0.5, 1), (0.5, 0))

    def test_fuel_changes_duration_not_strength(self):
        self.assertEqual(cycle(0.4, 1, 1)[0], cycle(0.4, 10, 1)[0])

    def test_percent_bounds_and_zero_production(self):
        self.assertEqual(cycle(0.4, 2, 1, percent=0), (0.4, 1))
        self.assertAlmostEqual(cycle(0.4, 2, 1, percent=200)[0], 1.2)
        self.assertEqual(cycle(0, 2, 1), (0, 1))

    def test_capacity_capped_catchup_still_expires_fuel(self):
        self.assertAlmostEqual(cycle(0.8, 3, 2, elapsed=12)[0], 1.2)
        self.assertEqual(cycle(0.8, 3, 2, elapsed=12)[1], 0)
        self.assertEqual(cycle(0, 3, 0, elapsed=12), (0, 0))

    def test_disabled_and_invalid_calculations_add_nothing(self):
        self.assertEqual(Service(enabled=False).BonusMilk("player", 0.4, 1, 1), 0)
        for args in ((None, 1, 1, 1), ("npc", -1, 1, 1), ("npc", 1, -1, 1), ("npc", 1, 1, -1)):
            self.assertEqual(Service().BonusMilk(*args), 0)

    def test_dynamic_unchanged_and_fixed_gate(self):
        dynamic = QUEST.split(";dynamic milk production", 1)[1].split("\n\tEndIf", 1)[0]
        self.assertEqual(hashlib.sha256(dynamic.encode()).hexdigest(), "c4bd21e070b403e3cdf885f44fda80d4c49f57fe1c253fe68974f5ff8665e1ef")
        self.assertIn("FixedMilkGen || (akActor != PlayerREF && FixedMilkGen4Followers )", QUEST)
        self.assertIn("ElseIf LactacidDecayRate > 0", QUEST)
        self.assertIn("elseif LactacidDecayRate == 0\n\t\t\tLactacidCnt -= MilkTick", QUEST)

    def test_defaults_logging_preview_and_packaging(self):
        self.assertIn('"enableFixedLactacidBoost", 1)', HELPER)
        self.assertIn('If !JsonUtil.HasIntValue', HELPER)
        self.assertIn('If !JsonUtil.HasFloatValue', HELPER)
        self.assertIn("MMEFixedLactacid.EnsureDefaults()", MCM)
        self.assertIn("Return 169", MCM)
        self.assertIn("MMELog.MasterDiagnostic", HELPER)
        self.assertIn("MMELog.Alarm", HELPER)
        self.assertIn('StorageUtil.GetIntValue(None, alarmKey, 0) == 0', HELPER)
        self.assertNotRegex(HELPER, r"RegisterFor|Utility.Wait|EquipItem|AssignSlot|changeLactacidCurrent")
        preview = (ROOT / "Source/MMECompatibilityOverrides/MilkMCM.psc").read_text()
        self.assertIn("MMEFixedLactacid.BonusMilk(MaidlistA[MaidIndex], MilkTick, LactacidCnt, 1)", preview)
        self.assertIn('$scriptNames += "MMEFixedLactacid"', (ROOT / "build-package.ps1").read_text())


if __name__ == "__main__":
    unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout))
