"""Legacy entry point: retain notification coverage alongside four-route checks."""
import json,subprocess,unittest
from test_movement_routes import MovementRoutes,ROOT
class MovementSlapAssets(MovementRoutes):
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
