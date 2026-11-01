# Optional Milk Leaks

Requires Oninus Lactis NG 2.1 and its installed meshes/textures. The FOMOD
recommends this option when OninusLactis.esp is active. Detection in Body > Milk
Leaking reports plugin presence only. No original Oninus, DW or MME script or
record is overridden. The optional ESL-flagged plugin contains three owned
armor forms, six owned fixed-intensity armor addons and one lifecycle quest.
It references the original visual assets instead of redistributing them.

The player and nearby loaded adult MME Milk Maids can leak at the selected
MME fullness percentage (default 100). First observing an already-full actor
permits one burst. Going below the threshold rearms the actor. Save loading
cleans owned effects and rearms nearby actors. No milk, levels, inventory
rewards, animations, movement locks or Milk Maid conversion are changed.

Uncovered intensity defaults High: five seconds High, five Medium, five Low.
Medium starts at Medium and Low starts at Low. Timings are approximate Papyrus
deadlines; suspended menus or VM latency can delay changes. A body/chest item
in slot 32 caps the current stage at Low. Clothing leaks default On; disabling
them stops/prevents a covered leak. Removing clothes does not restart time.

Combat, scenes and active milking prevent our route. Native shared nearby
actor scans supply discovery, including a 15-second deadline when ordinary
capacity polling is disabled. One-second checks run only while owned bursts
are active, detecting clothing changes and external takeover. Up to 32 owned
bursts can be tracked. Leaving range/unloading ends owned bursts.

External Oninus sprays have priority. An external OLactis.Lactating request
reserves the actor briefly and ends only our own effect. It is not advertised
as an active spray until the original armor is equipped. We never invoke
Oninus cleanup or stop functions, change its model paths, or remove its armor.
Original nipple-position/scale preferences are read for our visual alignment.
DW's separate fallback shader is not tracked by this version. The optional
Oninus leak skin shader is not added by our route.

## Public API

MMEMilkLeakAPI.IsDetected(): plugin detection only.
IsLeaking(actor): currently equipped owned or external Oninus spray.
GetLeakSource(actor): 0 none, 1 Extensions, 2 External.
GetLeakIntensity(actor): 0 Low, 1 Medium, 2 High, -1 absent/external unknown.
GetLeakingActors(): fresh nearby loaded snapshot; fixed 128 slots, unused
entries are None. It does not identify external callers as DW without proof.
The API is available in the core; without the optional integration it returns
no tracked leaks. No global tracking of unloaded NPCs is claimed.

## Settings and editable text

Gameplay: SKSE/Plugins/StorageUtilData/MMEAlerts/Settings.json:
enableMilkLeaks=1; milkLeakThroughClothing=1; milkLeakIntensity=2;
milkLeakThreshold=100; milkLeakNarration=1; milkLeakNarrationCooldown=30.
Missing values are initialized without replacing existing user choices.

Narration: SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/MilkLeaks.json:
start and instructions. Both appear under Milk Leaking in the existing
Magelight narration editor; the Body-page link opens that feature. Personal
overrides use the existing editor storage and do not change gameplay settings.
Narration is requested once after confirmed owned equip, with a global
0–1200 real-second cooldown (default 30), to avoid simultaneous NPC chatter.
Skyrim.Net remains optional. Cooldown never delays or suppresses visuals.

## Diagnostics and acceptance

Routine footprints use [MME Milk Leaks], gated by the master Papyrus trace
toggle, for eligibility/skip changes, start, stage/clothing changes, external
requests, narration results and cleanup. Failures are deduplicated/rate-limited;
normal disabled/missing optional mod/busy/full-slot outcomes are not alarms.

Build/record/package checks cannot establish correct in-game alignment.
Live acceptance must check player/NPC, mixed intensities on multiple actors,
clothing on/off mid-burst, feature/master off, loaded-full save, threshold
rearm, combat/milking/scene entry, external takeover during setup and each
stage, dependency absence, narration cooldown, and quiet logging off.
Do not claim particles rendered merely because an armor equipped.

When removing the optional FOMOD option, use the mod manager's Replace install
to avoid stale plugin/source/compiled/SEQ files. Disable the feature and allow
owned bursts to clean up before removing the dependency in a live save.
