# Milk Maid Roster implementation

The optional FOMOD choice installs `MME Extensions - Maid Roster.esp` (ESL-flagged),
its two matching Papyrus source/PEX pairs, and one local page under
`Magelight/mmeextensions/views/roster/index.html`. It has only Skyrim.esm and
MMEAlert.esp masters. No core/third-party plugin is edited and no Magelight runtime
is bundled. The build-only Magelight SDK is vendored with its MIT licence.

The common MCM adds an optional enable toggle, Open button and initially unassigned
keyboard hotkey on General, with internal schema migration 160. It checks plugin/
DLL presence by name and communicates through ModEvents, with no Magelight types
or native calls in common scripts. The optional quest defers MCM opening until
Journal Menu closes; it owns hotkey registration, per-load initialization, view
creation, callbacks, focus, close and snapshot requests. Save/load resets serialized
transient locks and resolves views by owned name, not a stored native handle.

The page displays MME's deduplicated registered MilkMaid array; no proximity scan
or parallel array joins are used. Current milk uses MME's read-only getter. Capacity
uses the original getter's verified `MME.MilkMaid.MilkMaximum` stored value directly
with a zero/missing fallback: calling the framework capacity getter after a separate
HasFloatValue check would still race its lazy initialization if MME removed the
field between Papyrus calls. This direct read duplicates no formula and guarantees
that refresh never invokes that write branch. Unknown capacity displays N/A.
Unloaded maids retain last stored values; over-capacity numbers remain visible.
Refresh remains observational. Actions now delegate to the public API (internal revision 18).

NPC Give Milk and player Drink honor the Free Jug cheat and prefer owned Lactacid
only for confirmed Milk Maids. Self Milk dispatches the guarded native MME route;
MME start/end events confirm actual progress separately. Per-snapshot actor tokens
prevent stale row targeting. Actions release focus and execute on a single update;
busy requests and old sessions are rejected. A second Narration & Lore tab now
offers a single-field general-lore editor with native-worker Save/Reload/Reset,
external personal JSON, backups, and revision checks. See
[the proof implementation](Narration-Editor-Proof.md) for scope and remaining runtime
acceptance. The page has Refresh, Close and Escape and assigns names through DOM
textContent. Rendering validates shape and finite display values, and clamps only
the visual progress bar. Page rejection reports a deduplicated backend smoke alarm.
Close/Refresh work before the first data payload; generation/view checks reject
stale requests and stale refresh results. Refreshes are on-demand with no poller.

Routine `[MME Maid Roster UI]` footprints go through MMELog.MasterDiagnostic.
Failures use deduplicated MMELog.Alarm. Host absent, disabled feature, another view
owning focus and empty roster are expected skips. The native registered host name
`Magelight` was verified from the reference DLL's static SKSEPlugin_Version export,
without loading the DLL.

Validation completed:

- Full existing build/contract pipeline, standard scripts and 24 OStim-only variants.
- Effective 65-script no-SexLab bytecode checks and existing dialogue checks.
- New quest/alias/masters/ESL round-trip checks; VMAD player-alias metadata compared
  against original MME (version 5, object format 2, extra bind version 2, quest
  form version 46), and stable generated FormID allocation.
- Final two UI scripts compiled with zero errors/warnings.
- Four roster contract tests including execution of actual page JS with a DOM test
  harness: Unicode/HTML-as-text names, unknown capacity, over-capacity bar/number,
  repeated/empty/malformed data, disabled action and callback/initial Close/Escape.
- Browser-rendered mock-data preview visually inspected at 1440 x 1000.
- Existing Vortex 1:39 negative control/fixed XML and FOMOD backend cases retained.

Three old tests that capped MCM migration matching at 159 now parse its version and
check the original minimums instead, retaining all associated feature assertions.
The existing dialogue utility emits nullable-reference build warnings; its checks
still passed. No native MMEExtensions DLL changes were required.

The full build's final optional-component files are refreshed after the final
narrow compile and rechecked in the archive. Artifact hashes and logs are under
ignored `build/diagnostics/magelight-preflight/`. Mock UI previews and compiler
probes are not shipped. The distributable remains `dist/MME Extensions.zip`; older
versioned hotfix ZIPs are not modified.

The user installed the baseline roster and supplied an in-game screenshot showing
Prisoner with 0.0 / 4.0 milk and 0.0% fullness. The new action routes still require
live player/NPC, inventory, focus, event, host-absent and save/load acceptance tests.
This work changes repository/package outputs only. README, installed mods, MO2
profiles and retained Vortex files are untouched.
