# NPC movement sounds

Body → Movement Sounds includes NPC Movement Sounds (default on) and NPC Volume
Multiplier (default 100%, range 0–200%). NPCs share the player's four route
selections, route volumes, sneak multiplier and sound-master setting. The NPC
multiplier is applied before the final combined 200% cap. Existing custom
settings are preserved; missing new settings receive defaults.

Only established, loaded Milk Maids within 2000 units in the player's cell are
eligible. Each actor uses her own fullness, movement and scene state and owns a
separate sound instance. Discovery is cached for two seconds; movement checks
reuse the existing half-second scheduler. Stationary, swimming, mounted,
furniture, unloaded, out-of-range and scene/milking actors stop playback.
This feature never converts NPCs or modifies MME slots or milk values.

Actor-named movement notifications use the existing notification toggle and
per-actor game-hour cooldown, plus a ten-second NPC HUD throttle. They require
more than half fullness, matching player notifications. NPC text is editable in
the narration library under Breast Bounce Notifications.

Menu entry, feature disable, settings refresh and load discard or stop owned
instances. Numeric sound IDs from another native session are never stopped.
The original player native and Papyrus signatures remain unchanged.
Routine actor/start/stop traces follow the master Papyrus logging toggle;
missing sounds, failed playback and missing notification pools use deduplicated
failure alarms. Skyrim.Net and scene frameworks remain optional.


## Responsive native playback
Movement audio is owned by the native plugin per actor, rather than by the shared Papyrus timer. Engine footstep events trigger playback. **Movement Polling Fallback** in Body MCM defaults on and checks only registered actors (maximum 32) every 50 ms on the game thread; it performs no cell scans, milk calculations, JSON reads or routine logging. Only one timer task can be queued. Position displacement rejects stationary actors with stale direction flags and teleports.

Turning the fallback off removes periodic native movement checks. Footsteps start/renew a loop; a one-shot 0.85-second inactivity timeout stops it if no further step arrives. Very slow footsteps may therefore have audible gaps in event-only mode. This is not a claim that every animation setup emits footsteps. Menus and load transitions stop playback independently. Papyrus still updates eligibility/settings, and permission expires after eight seconds without renewal. The toggle does not disable other mod monitoring.

Both base flop WAVs received exactly 1.75x amplitude (+4.86 dB) without clipping, normalization, retiming or pitch changes. Slap WAVs and user volume preferences are unchanged. Runtime feel, event coverage and VR audio require in-game acceptance testing.
