# Optional Milk Leaks

Requires Oninus Lactis NG 2.1 and its installed meshes/textures. The FOMOD
recommends this option when OninusLactis.esp is active. Detection in Body > Milk
Leaking reports plugin presence only. No original Oninus, DW or MME script or
record is overridden. The optional ESL-flagged plugin contains three owned
armor forms, six owned fixed-intensity armor addons and one lifecycle quest.
It references the original visual assets instead of redistributing them.

The player and nearby loaded adult MME Milk Maids can leak at the selected
MME fullness percentage (default 100). First observing an already-full actor
starts the taper, then Low continues at or above the threshold. Going below
the threshold stops the effect and rearms the actor. Save loading
cleans owned effects and rearms nearby actors. No milk, levels, inventory
rewards, animations, movement locks or Milk Maid conversion are changed.

Uncovered leaks use a fixed taper: five seconds High, five Medium, then sustained Low.
There is no intensity slider. Timings are approximate Papyrus
deadlines; suspended menus or VM latency can delay changes. A body/chest item
in slot 32 caps the current stage at Low. Clothing leaks default On; disabling
them stops/prevents a covered leak. Removing clothes does not restart time.

Combat, scenes and active milking prevent our route. Native shared nearby
actor scans supply discovery, including a 15-second deadline when ordinary
capacity polling is disabled. One-second checks run only while owned effects
are active, detecting clothing changes and external takeover. Up to 32 owned
effects can be tracked. Leaving range/unloading ends owned effects.

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
enableMilkLeaks=1; milkLeakThroughClothing=1; milkLeakThreshold=100.
Missing values are initialized without replacing existing user choices.

Leak-specific Skyrim.Net narration, MCM narration controls and Magelight entries
are removed. Existing milk-full narration remains authoritative. Legacy saved
milkLeakNarration/milkLeakNarrationCooldown values and personal text overrides
are preserved but unused. Install using Replace to remove the retired base JSON.
The editor retains unknown personal entries internally without making requests.

Sustained Low checks fullness/eligibility once per second while active; it does
not recreate the visual each tick. Hot checks read the verified original MME
storage keys without its unconditional getter traces; missing capacity still
uses the original MME initialization. Combat/scenes, milking, disabled features,
unloading/range exit and external effects still stop only our own visual.
Interrupted leaks resume Low on the next eligible shared scan if still full;
falling below threshold or loading a save permits a fresh taper. Exact threshold
continues leaking. No milk is consumed. Clothing rules still apply.

Visual positioning now resolves the verified OninusLactis quest editor ID
instead of the obsolete name in a commented-out reference script.

## Diagnostics and acceptance

Routine footprints use [MME Milk Leaks], gated by the master Papyrus trace
toggle, for eligibility/skip changes, start, stage/clothing changes, external
requests, threshold exit and cleanup. Failures are deduplicated/rate-limited;
normal disabled/missing optional mod/busy/full-slot outcomes are not alarms.

Build/record/package checks cannot establish correct in-game alignment.
Live acceptance must check player/NPC, mixed intensities on multiple actors,
clothing on/off mid-burst, feature/master off, loaded-full save, threshold
rearm, combat/milking/scene entry, external takeover during setup and each
stage, dependency absence, sustained Low and threshold exit/rearm, and quiet logging off.
Do not claim particles rendered merely because an armor equipped.

When removing the optional FOMOD option, use the mod manager's Replace install
to avoid stale plugin/source/compiled/SEQ files. Disable the feature and allow
owned effects to clean up before removing the dependency in a live save.

The legacy milkLeakIntensity JSON value is preserved but ignored. Scan delivery
is traced at most once per minute; threshold state changes get actor-specific
master-gated footprints. Discovery is in ScanNearbyMilkMaids, never conditional
on the tentacle injection timer.

Ordinary sitting and leaning are allowed for visual-only leaks. Furniture is
not a blocking condition; combat/scenes/framework milking guards remain.
Eligibility changes include actor, exact reason, sit state and furniture
reference only behind master logging, once per changed result. No animation
graph variable named bInFurniture is queried.
