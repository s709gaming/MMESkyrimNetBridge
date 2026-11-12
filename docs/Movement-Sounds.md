# Movement sounds

Player-only movement audio uses the existing Extensions, reaction-sound and movement-sound toggles. Mining is excluded. Standing still, menus, mounts, swimming, incompatible scenes and existing movement guards remain silent.

| Fullness | Walking, normal running or sneaking | Sprinting |
|---|---|---|
| Below 50% | Slow slaps | Fast slaps |
| 50% or higher | Slow flops | Fast flops |

Four dropdowns allow any of the four sounds or None per route. Each route has a 0–200% volume slider in 5% steps. Missing route volumes inherit the previous movementSlapVolume value (100% when absent); an explicitly chosen zero remains zero. Dropdown defaults are the table above. Reset defaults are 100% per route, 50% for the sneak multiplier. No save reset is needed.

The existing reactionSoundVolume remains a shared multiplier. Sneaking always uses the walking route and applies movementSoundSneakVolume (default 50%). All factors combined cap at 200%. Playback assets represent the 200% reference; at 100% the sound instance uses half amplitude. This provides 200% relative to the new default without exceeding Skyrim's 0–1 instance-volume clamp or digitally clipping the supplied PCM. It does not promise the old recording's absolute loudness. Final perceived balance needs in-game listening.

The four mono PCM WAVs under assets/sounds/Movement Loops are 44.1 kHz / 16-bit. Slap loops last 4.275 seconds with 5/10 hits; flop loops last 4.4 seconds with 4/8 hits. Individual hits retain their pitch. Seams fall between hits with tiny segment fades. Flop base WAVs have an additional 1.3x amplitude gain (30%) relative to the previously matched average levels, without clipping. Perceived loudness remains a listening check.

MMEMovementSounds.psc owns selection, record resolution and volume calculations. MMEAlertsController.psc remains the single playback owner and stops the previous sound before replacing it. Existing generation/session cleanup and master-gated traces remain. Missing selected records and failed playback use deduplicated alarms. Notifications retain their original above-50% eligibility and cooldown independently of the expanded low-fullness audio.

Sound records retain old movement SOUN 0008C5 / SNDR 0008C4 for fast flops. New pairs are 0008D3/0008D4 (slow slaps), 0008D5/0008D6 (fast slaps), 0008D7/0008D8 (slow flops). Existing record identities are preserved, with no new ESP master. tools/prepare_movement_routes.py is repeatable and rejects occupied IDs. It changes only the sound groups and record-count metadata. The legacy preparation/test entry points now delegate to this system.

Verification: behavioral route/default/gain checks, record isolation and repeatability, marker links, PCM format, duration, clipping and seam endpoints. Papyrus compilation, optional-backend generation and archive validation are separate checks. Live walk/run/sneak switching, menu/load interruptions and listening are required for live acceptance; static checks do not establish it.
