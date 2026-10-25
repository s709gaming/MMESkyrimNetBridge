"""Audio gain, plugin isolation and collision regression checks (no game writes)."""
import array
import json
import struct
import subprocess
import unittest
import wave

from prepare_movement_slap import ROOT, DESCRIPTOR, MARKER, SOUND_PATH, build_plugin, records, subrecords


class MovementSlapAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = subprocess.check_output(["git", "show", "HEAD:MMEAlert.esp"], cwd=ROOT)
        cls.plugin = (ROOT / "MMEAlert.esp").read_bytes()
        cls.baseline = list(records(cls.original))
        cls.current = list(records(cls.plugin))

    def test_only_two_new_records_and_header_metadata(self):
        baseline = {r[12:16]: r for r in self.baseline if r[:4] != b"TES4"}
        current = {r[12:16]: r for r in self.current if r[:4] != b"TES4"}
        self.assertEqual(len(current), len(baseline) + 2)
        for form, record in baseline.items():
            self.assertEqual(current[form], record, f"Unrelated record changed: {form.hex()}")
        old_header = dict(subrecords(self.baseline[0][24:]))
        new_header = dict(subrecords(self.current[0][24:]))
        self.assertEqual(old_header.keys(), new_header.keys())
        for tag in old_header.keys() - {b"HEDR"}:
            self.assertEqual(old_header[tag], new_header[tag])
        self.assertEqual(struct.unpack_from("<I", new_header[b"HEDR"], 4)[0],
                         struct.unpack_from("<I", old_header[b"HEDR"], 4)[0] + 2)

    def test_marker_resolves_to_loop_and_packaged_path(self):
        local = {struct.unpack_from("<I", r, 12)[0] & 0xFFFFFF: r for r in self.current}
        descriptor = dict(subrecords(local[DESCRIPTOR][24:]))
        marker = dict(subrecords(local[MARKER][24:]))
        self.assertEqual(local[DESCRIPTOR][:4], b"SNDR")
        self.assertEqual(local[MARKER][:4], b"SOUN")
        self.assertEqual(marker[b"SDSC"], local[DESCRIPTOR][12:16])
        self.assertEqual(descriptor[b"LNAM"][1] & 0x38, 0x08)
        self.assertEqual(descriptor[b"ANAM"], SOUND_PATH)
        relative = SOUND_PATH.rstrip(b"\0").decode().replace("\\", "/")
        self.assertTrue((ROOT / "assets/sounds" / relative.removeprefix("fx/MMESkyrimNetBridge/")).is_file())

    def test_gain_restores_original_at_100_percent_without_clipping(self):
        folder = ROOT / "assets/sounds/Tit Slap Sounds"
        def read(name):
            with wave.open(str(folder / name), "rb") as stream:
                return stream.getparams(), array.array("h", stream.readframes(stream.getnframes()))
        original_params, original = read("tit slap sound loop.wav")
        boosted_params, boosted = read("movement slap 2x.wav")
        self.assertEqual(original_params, boosted_params)
        self.assertEqual(list(boosted), [sample * 2 for sample in original])
        self.assertLessEqual(max(abs(sample) for sample in boosted), 32767)
        self.assertEqual([sample * 0.5 for sample in boosted], list(original))
        self.assertTrue(all(sample * 0 == 0 for sample in boosted))

    def test_patch_is_repeatable_and_refuses_occupied_ids(self):
        self.assertEqual(build_plugin(self.original), self.plugin)
        self.assertEqual(build_plugin(self.plugin), self.plugin)
        # A valid but differently named occupant must never be overwritten.
        collision = self.plugin.replace(b"MMEAlerts_SNDR_MovementSlap", b"MMEAlerts_SNDR_ConflictingX")
        self.assertEqual(len(collision), len(self.plugin))
        with self.assertRaisesRegex(AssertionError, "collision"):
            build_plugin(collision)

    def test_player_messages_preserve_existing_npc_pools(self):
        relative = "SKSE/Plugins/StorageUtilData/MMEAlerts/BreastBounceNotifications.json"
        current = json.loads((ROOT / relative).read_text())
        original = json.loads(subprocess.check_output(["git", "show", "HEAD:" + relative], cwd=ROOT))
        self.assertEqual(current["low"], original["low"])
        self.assertEqual(current["high"], original["high"])
        self.assertEqual(current["movement"], [
            "Your bouncing bounty keeps clapping along to your footsteps.",
            "Your pendulous pair keeps smacking together with every step.",
            "Your hefty melons give each other a hearty smack with every stride.",
            "Your swinging hills collide with a rather enthusiastic clap.",
            "Your weighty twins keep bumping together, applauding your every step.",
        ])


if __name__ == "__main__":
    unittest.main()
