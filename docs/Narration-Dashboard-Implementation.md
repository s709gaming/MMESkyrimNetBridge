# Narration dashboard implementation

The optional roster's Narration & Lore tab now exposes 147 entries: 74 canonical
Skyrim.Net templates, 57 existing story/thought/notification pools, and 16 inherited
four-tier Tentacle Effects pools. The general-lore
proof file remains compatible. No installed mod, game file, MO2 profile or retained
Vortex installation is modified by the repository build.

The entry list has a draggable scrollbar, wheel scrolling and up/down viewport
buttons. Each multiline box scrolls independently and can be resized vertically.
Search/category/Modified Only controls filter metadata; expand a card to load its
values. Switching tabs or filtering keeps drafts. Save Changes validates and commits
all dirty entries together. Per-entry and Reset All actions are staged until Save.
Fields lock during requests so edits cannot be lost behind an in-flight Save.
Duplicate variants and their order are preserved; Move Up/Down changes ordering
without changing text. Arrays use 1-64 nonblank variants; each template is limited
to 8192 UTF-8 bytes, and personal documents to 256 KiB. Oversize/invalid changes
are rejected without partial application. Required placeholders appear on each card.

Presets live beside the personal profiles, outside the installed mod. Export writes
committed sparse overrides to a new named file and verifies readback. It refuses
to overwrite an existing name. Import previews counts/conflicts; Merge retains
existing personal entries, while Replace replaces the entire override set after
backup, including unknown entries. The confirmation states that scope explicitly.
Capture Edited Base Files and Import Legacy Text stage recognized differences for
review and Save; existing personal values and unsaved drafts are retained. Original
base/legacy files are not rewritten by these dashboard operations.

The existing MCM legacy-import action directs users to the dashboard when its
optional plugin and Magelight are available. Without that optional UI it retains
the earlier base-file import path for compatibility. Manual JSON editing remains
possible. Localhost access is a separate planned adapter and is not included.

`tools/generate_narration_catalog.py` generates `include/NarrationCatalog.h` from
the authored JSON and canonical token schema. The generated catalog defines file
paths, IDs, types, token contracts, labels and compiled source defaults. No runtime
filesystem path comes from a page request. Legacy-only copies and the two unused
opening/closing conversion-story fields are not duplicate editor controls.

`NarrationStore` validates sparse schema-1 overrides, keeps unknown IDs/metadata,
checks revisions over current personal/base/catalog data, uses the exclusive profile
lock, verifies/flushed temporary output, preserves the previous backup, replaces
and reads back before publishing. A batch with any invalid entry changes nothing.
Gameplay sees a single published override snapshot under a separate memory lock,
never the disk transaction lock. A pool is returned in one atomic bounded array:
type marker followed by templates. Each existing Papyrus reader still owns its
original Utility.RandomInt roll, actor/role decisions, renderer, fallback, timing,
eligibility, presentation and gameplay writes.

`MMENarrationText` resolves all canonical personal templates. The new common
`MMENarrationOverrides` facade adapts ordinary pools for thoughts, cravings,
arousal, bounce/movement, Dwemer/tentacle notifications, drink/breastfeeding and
service reminders. MMETextPool and MMEStoryPopup check cataloged personal pools
before their original ordinary/typed-list readers. Timed armor retains its typed
base reader and built-in fallback. Public API calls to uncataloged story files
continue through their existing reader. No MilkQUEST function/array semantics or
optional framework dependency is added.

The UI uses lowercase hex UTF-8 across Papyrus. Large requests upload in 4096-hex-
character chunks; large replies use acknowledged, ordered downloads. The native
queue accepts frames up to 12 KiB. Transfer state is bounded, expires after two
minutes, and is isolated by native epoch, view, generation and request ID. No partial
upload commits data. The page uses a 30-second operation timeout and requires a
reload after an uncertain result. Startup cache refresh returns metadata only,
so background work cannot leave unconsumed long-text download buffers behind.

All file I/O stays on the native worker. Completion is a one-shot game-task event;
there are no new Papyrus polling loops or latent waits. Transient state is rebuilt
after load. The UI remains unpaused as in the original roster; paused-host delivery
still requires runtime acceptance. Requests from old views/epochs are rejected.

Routine footprints use MMELog.MasterDiagnostic and `[MME Narration Editor]`:
completed load/catalog/entry/save/reset/import/export/capture results, counts,
revision, bounded validation reason, important skip and cleanup. Chunk acks/parts
are silent. Runtime personal/base/fallback selection logs once per entry/actor/
revision while the master toggle is on; verbose logging is not required. Turning
the master off suppresses routine traces. Genuine failures are deduplicated smoke
alarms; validation errors, conflicts and expected optional-host absence are not
alarms. Full prose and full preset payloads are not logged.

Drafts remain page memory: forced host exit, hibernation, reload or game exit can
lose unsaved edits. Save explicitly. Personal overrides are shared across saves
and MO2 profiles using the same SKSE user directory; loading an old save does not
undo them. Disk/editor preserve case and Unicode exactly. Final presentation still
crosses Papyrus, so verify case-only/Unicode text in actual Skyrim.Net prompts.

Validation entry points:

- `tools/Test-NarrationEditor.ps1`: actual native persistence/catalog/chunking tests, roster page and dashboard JavaScript tests.
- `build-native.ps1` and `build-native.ps1 -VR`: generated catalog and runtime builds.
- `tools/Build-MaidRosterUI.ps1`: optional source/PEX pairs and both page/script hashes.
- `build-package.ps1`: common/backend/optional compiles, existing regressions, dashboard tests and `MME Extensions.zip`.

Runtime acceptance still needs an authorized matching deployment: repeat the proof's
Save/Reload/Reset; test player and NPC prompt injection, representative direct pool
readers, large Unicode fields, restart/update persistence, conflicts/failed saves,
master off/on and optional dependencies absent. Verify actual narration and source
thought variants separately. The earlier crash signature is not diagnosed or fixed
by this expansion. Offline tests and successful builds are not claims of in-game
acceptance for the new dashboard.

## October 30 QA checkpoint

The expanded JSON editor exposes all 131 narration/lore entries, including 57
variant pools. It includes category/search filters, a draggable main scrollbar,
and individually scrolling/resizable text fields. Personal overrides, atomic
saves, presets and import previews keep player edits outside installed mod files.
Routine Papyrus footprints remain behind the existing master logging toggle.

Native AE and VR builds, affected Papyrus compilation, native persistence and
transport tests, JavaScript tests and package inspection completed successfully.
The archive was installed into MO2 VortexToMO2 / Default with existing FOMOD
choices preserved. The minimal two-field live save/reload test was stopped:
computer-control input moved the cursor but did not activate game controls or
the dashboard hotkey. No narration fields were changed, personal overrides were
verified unchanged, Skyrim was closed without saving, and the temporary global
AI setting was restored. Full dashboard runtime acceptance remains outstanding.
