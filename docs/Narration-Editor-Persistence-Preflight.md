# Narration editor and persistent presets: pre-flight

Date: 2026-10-29. Status: research/design only; no implementation or deployment.

Follow-up, 2026-10-30: the general-lore proof now has verified in-game
Save/Reload/Reset results. See [the expansion pre-flight](Narration-Dashboard-Expansion-Preflight.md)
and [source inventory](Narration-Dashboard-Inventory.json) for the remaining
74-entry canonical catalog and 57 additional pools (131 total, including the proof).
The remainder of this document preserves the original broader design proposal.

## Recommendation and scope

Build one editor model and one native persistence service, with two front ends:
the optional Magelight roster's second tab and an optional localhost browser page.
Personal changes live outside the installed mod. Save writes them explicitly;
Export/Import provides portable backups. Updating the mod must require neither
exporting first nor importing afterwards.

Deliver in stages, but consider the feature complete only after persistence,
in-game editing, import/export, browser editing, logging, and runtime acceptance.
The browser service initially runs only while Skyrim is running. Editing with
Skyrim closed would need a separate companion executable and is deferred.

The second tab is **Narration & Lore**. Include the 12 canonical narration files
and all active authored story/thought/notification text pools after a consumer
inventory. Do not expose gameplay settings, armor form registries, generated
defaults, action YAML, or prompt control-flow code as editable narration.

## Verified repository and installed-source findings

- `MMENarrationText.psc` loads `MMEAlerts/Narration/<feature>`, checks schema 1,
  validates tokens and string/string-array templates, and renders once. Missing
  or invalid entries use generated compiled defaults. Normal loading is read-only.
- `tools/narration-schema.json` and `generate_narration_defaults.py` already provide
  the authoritative route/token inventory. The current schema has 74 routes in
  12 files; earlier implementation documented 72. Generate counts from the schema
  rather than hard-coding either count.
- `Lore.json` contains `milk_lore` and `milkmaid_lore`. The character-bio prompt
  calls `mme_milk_lore_text`; `MilkLoreText` adds maid-specific text only for
  confirmed MME maids. Preserve these conditions and the `{actor}` requirement.
- `ImportLegacy()` currently writes recognized old text into canonical files.
  It is not a general preset importer and must be integrated deliberately.
- `MMETextPool.psc` supports ordinary arrays and legacy `stringList` data.
  Other scripts also read pools directly; changing only this helper is insufficient.
- The roster is a single HTML page with four existing listener names. Its optional
  quest handles view ownership, focus, generation/session checks, and player-load
  setup. It explicitly does not yet expose editing or file writes.
- `MMELog.MasterDiagnostic` gates on `enablePapyrusTrace` alone. `Diagnostic`
  additionally requires verbose logging. `Alarm` currently bypasses both.
- The native DLL already registers `MMEExtensionsNative`; CMake pins the alandtse
  CommonLibSSE-NG lineage at v8.3.0 and targets SE/AE/VR. The project currently
  declares neither an HTTP library nor a JSON library as a direct dependency.

Static environment confirmation: `ModOrganizer.ini` and houseCARL identify
`C:/Users/Donald/AppData/Local/ModOrganizer/VortexToMO2`, profile `Default`, mods,
profiles, and overwrite beneath that instance. houseCARL resolves Magelight.dll
from `MagelightUI 1.5.0 193303 12 2026` and JsonUtil source/PEX from
`PapyrusUtil AE SE - Scripting Utility Functions`. Read the winning source header:
JsonUtil starts under Data/SKSE/Plugins/StorageUtilData, automatically saves dirty
files on a game save, and defaults Unload to saving changes. Its actual signatures
include `Save(string FileName, bool minify = false)` and
`Unload(string FileName, bool saveChanges = true, bool minify = false)`.

MO2 Agent Control `info` could not connect because its recorded MO2 process was
not running. No game or UI was launched. Skyrim.Net MCP tools are absent from this
session; SkyLink tools exist but were not needed or queried. Nothing here claims
runtime verification. The user subsequently authorized launching MO2 if helpful;
this does not authorize installing or deploying the feature.

## Content inventory and compatibility boundary

Generate an editor catalog with stable IDs, feature, label, help, source file/key,
kind, required tokens, allowed aliases, and actual consumer. Derive canonical route
metadata from the existing schema; labels/help can be separately authored metadata.
Generate the native validation catalog and UI catalog from the same source.

Inventory these additional files and all their readers before exposing their text:

| Family | Repository files / examples | Required handling |
|---|---|---|
| Stories | ArmorIntroductionStories, DwemerArmorStories, ForcedMilkMaidConversion | Ordinary fields and legacy typed lists; preserve actual consumer behavior |
| Thoughts / cravings | Thoughts, MilkCravings | Preserve pool names, weighting, selection, and empty-entry behavior |
| Notifications | ArmorCheckReminders, ArousalEffects, BreastBounceNotifications, DwemerEffectNotifications, Injection, NonMilkmaidDrinkNotifications, TimedArmorNotifications | Text fields only; map every direct reader |
| Older narration | DwemerSuitNarration, DwemerAttachmentNarration, DwemerEffectNarration, TentacleEffectNarration, text fields in SkyrimNet | Distinguish active readers from legacy import aliases; no duplicate competing editor fields |
| Non-text data | CustomArmorRegistry, TimedArmorRegistry, numeric SkyrimNet settings | Exclude from this editor |

Do not impose canonical narration's nonblank/all-variants-valid rules indiscriminately
on older pools. Encode each consumer's verified semantics. Preserve array order,
duplicates, random selection, and all actor/token insertion behavior. No new MilkQUEST
calls or changes to actor selection, maid slots, conversion, inventory, or cooldowns.
If implementation unexpectedly needs a MilkQUEST change, inspect original installed
source and exact array semantics before proceeding.

## Storage ownership and Skyrim save behavior

Proposed root: the resolved game-specific SKSE user directory, sibling to the log,
under `MMEExtensions/Narration/`. On this SE installation that normally means:

```
Documents/My Games/Skyrim Special Edition/SKSE/MMEExtensions/Narration/
  profiles/default/overrides.json
  profiles/default/overrides.previous.json
  presets/<safe-name>.json
```

Resolve the actual runtime-specific user path; do not hard-code a username, drive,
SE folder for VR/GOG, or redirected Documents location. Prefer CommonLib's existing
SKSE path resolution; use Windows known-folder APIs only where necessary. An
unavailable/unwritable root makes saving unavailable with an actionable error;
never silently fall back to installed Data or a Vortex staging folder.

Initial scope is one explicitly named personal profile shared across characters
using that root. Explain that loading an older save does not roll back these files.
MO2 profiles/instances may share the same user directory: do not promise automatic
isolation. Offer explicit named editor profiles before supporting multiple active
personal configurations; do not infer identity from a process working directory.

Runtime resolution per registered entry:
**valid personal override -> effective shipped/third-party JSON -> compiled fallback**.
Keep existing VFS default overrides effective. Do not write a merged effective
document over shipped defaults. Treat malformed external overrides as a reported
failure while keeping the last good snapshot, or defaults on first start.

Personal files are not packaged, generated during installation, or removed on
upgrade. Browser cache/localStorage and Papyrus/StorageUtil save state are not the
authority. Explicit Save persists immediately; Skyrim quicksave must not commit
drafts. Reload/character load resets transient locks and reads current disk revision.

## Proposed format and transaction rules

One sparse overrides document gives all changes in a Save operation one commit
boundary. Example (proposed schema, not currently implemented):

```json
{
  "schemaVersion": 1,
  "profileId": "default",
  "overrides": {
    "Lore.milk_lore": { "template": "Personal world lore." },
    "Lore.milkmaid_lore": { "template": "{actor} is a Milk Maid." }
  }
}
```

IDs are catalog IDs, never arbitrary filesystem paths or executable expressions.
Pool entries use their catalog-declared representation. Removing an override
restores the current base value. Reset removes the override explicitly; never use
Papyrus string equality to decide whether something is customized. Preserve
unknown/deprecated IDs on an ordinary save, display them separately as inactive,
and exclude them from runtime resolution until a known migration applies. Reject
unsupported future schemas without overwriting them. Schema revisions are data
format revisions, not release version numbers.

Every read snapshot returns a revision derived from actual content. Save includes
the expected revision, profile, session, request ID, and changed entries/removals.
Check both user-file and base-catalog/default revisions. Reject stale requests;
offer reload/compare instead of last-writer-wins. Compare UTF-8 bytes natively,
including case. A second game process editing the same root needs an OS-level
named mutex/lock plus re-read inside the lock, not merely an in-process mutex.

Validate complete proposed state before writing. Reject malformed UTF-8, duplicate
JSON keys, wrong types, invalid/missing tokens, malformed braces, excessive size,
and invalid pool shapes. Set measured, documented document/entry/depth/pool limits
after inventorying the largest shipped assets. Preserve Unicode, case, whitespace,
newlines, array order, and duplicates; do not silently trim or normalize prose.

Write a temporary sibling, flush/close, reparse and verify, preserve the last good
backup, then replace the destination with Windows file-replacement primitives.
Handle first creation separately and handle ReplaceFileW's documented partial
failure states. Do not claim universal crash/power-loss guarantees from a rename.
Only publish a new immutable runtime snapshot after durable commit/readback;
report persisted/applied revisions separately if runtime publication fails.
Startup recovery must never promote an unvalidated abandoned temporary file.

## Native service and Papyrus bridge

Add isolated native modules for catalog, validation, profile store, snapshot
resolution, and optional HTTP transport. Keep the work out of the already large
Plugin.cpp except registration/lifecycle wiring. Use a pinned, licensed JSON
parser with explicit duplicate-key detection; nlohmann/json is a candidate, not
an existing dependency. Use the same validation and transaction service from both UIs.

Papyrus owns optional UI discovery/setup and sparse diagnostics. Native workers
own bounded disk/network work and immutable text snapshots. No HTTP worker may
call game objects, VM functions, MME, or Skyrim.Net directly. Marshal necessary
notifications to the appropriate game-thread boundary, without holding store locks.
No blocking disk operation on the render thread; bounded job queues and completion
responses must also function while the UI pauses Skyrim.

Important proof spike: Papyrus strings are case-insensitive/interned. Moving only
disk writing native does not prove case-exact edits if raw text traverses Papyrus.
Test an encoded transport (e.g. UTF-8 bytes encoded as fixed-case hex) end to end,
with native decode/validation and bounded chunks/acks if necessary. Encode before
the JS-to-Papyrus boundary and decode only native; use the same discipline for
native-to-page snapshots. Probe case-only edits of existing text, Unicode/non-BMP,
quotes, braces, and the largest pool. Preserve exact disk/export bytes independently
of the existing runtime renderer's limitations. Test actual Skyrim.Net output too;
if its Papyrus-facing path changes case, report that limitation or extend rendering
at the native boundary before promising full runtime fidelity.

Retain the roster's script-owned Magelight modId. Adopting it through the C++ API
would make the existing Papyrus control calls refused under current host ownership
rules. If a direct native UI bridge is needed instead, design that ownership
migration explicitly; do not accidentally break the roster while bypassing Papyrus.
Never concatenate edited prose into Eval code. Use serialized data/known callbacks.

## In-game design

Retain the roster as tab one. Tab two has feature filters, search, Modified Only,
and a scrollable list of collapsible cards. Match existing warm dark/brown/gold
styling, improve spacing/focus states, and use ordinary multiline textareas.
Friendly labels are primary; stable IDs and source details are secondary help.
Lore appears as a clear section; do not add another top-level tab just for two fields.

Each card shows the current value/source, required placeholder chips, editable
variants with add/remove/reorder controls where supported, inline validation,
modified state, and Reset to Default. Sample previews use sample identities and
deterministic text substitution; never trigger gameplay or an LLM request.

Fixed footer: Save Changes, Export Preset, Import Preset, Discard Changes, and a
concise status. Saving stays disabled until validation and backend readiness pass.
Distinguish saved-to-disk from pending runtime apply. Tab switching preserves
drafts. Close/Escape with dirty state offers Save/Discard/Cancel; forced host exit
cannot be trapped reliably, so store optional recovery drafts separately from
active overrides and offer recovery on reopen. Never silently apply recovered drafts.
Avoid whole-editor rerenders on roster refresh. Preserve scroll, focus, caret,
selection, and unsaved text. Verify typing does not activate roster/game hotkeys.

Re-register listeners per load, validate view/session/generation/request tokens,
reject stale callbacks, and clear transient pending operations after load/close.
No Utility.Wait in paused handlers. Keep Magelight optional; allow manual JSON
editing and the browser editor without the optional roster component.

## Export, import, and old customization migration

Export committed sparse overrides by default, with metadata identifying format,
catalog and profile; exclude credentials, actor IDs, settings, runtime state, and
machine-specific absolute paths. Warn about unsaved changes and offer Save then
Export. Optionally support an explicitly labeled full snapshot for reproducibility;
explain that full snapshots pin values and suppress later default improvements.

In-game export uses a sanitized preset name beneath the owned presets directory.
In-game import lists that directory; do not promise an OS file picker. The browser
can download an export or upload a file, which still goes through server validation.
Both offer preview with added/changed/conflicting/unknown entries and explicit
Merge or Replace. Merge preserves nonconflicting existing overrides and requires
conflict choices. Replace replaces the override set, not shipped data, after backup.
No partial application when validation fails. Reset All is explicit and backed up.

Add an explicit Capture Existing Customizations preview for users who edited shipped
JSONs, preserving originals. Native exact comparison can capture case-only changes;
generated authored defaults provide the comparison baseline. Third-party overrides
may appear as differences: label provenance and let the user choose. Do not silently
copy every installed default. Rework existing Import Legacy to target this service
or clearly label its old behavior; avoid two competing writers.

## Optional localhost access

Choose an embedded, opt-in HTTP service in MMEExtensions.dll for the first browser
implementation. This reuses the same in-process store and sees MO2's VFS defaults.
A standalone companion is more packaging/lifecycle work and cannot assume those
defaults are visible outside MO2. Do not depend on an undocumented Skyrim.Net
dashboard extension/API or edit its configuration.

Serve the same editor assets with a transport adapter: Magelight messages in-game,
same-origin HTTP in a browser. Browser exposes narration only; no roster gameplay
actions. Extract shared JS/CSS to a common asset location installed independently
of the optional roster. No CDN or internet connection. Host and UI have a versioned
protocol and reject incompatible combinations.

Bind only 127.0.0.1 on an OS-assigned port; display the actual URL after successful
start. Disabled by default, with explicit Start/Stop/Open controls and safe existing-
save initialization. It may be enabled while narration is inactive, but must never
enable Skyrim.Net or gameplay implicitly. Game exit stops access. Test stop/restart
and shutdown cleanup; no detached unmanaged process or listener on all interfaces.

Candidate HTTP library: pinned cpp-httplib, with bounded requests, timeouts and
worker count. License/build/runtime compatibility still needs a spike. Require
session authorization, strict Host and Origin checks, no wildcard CORS, no state-
changing GETs, no arbitrary disk paths, and traversal-safe allowlisted assets.
Open an ephemeral launch token in the URL fragment, exchange for a scoped session,
then clear it; do not log credentials or put them in exported presets. These are
requirements of introducing a writable localhost endpoint, not a separate user
approval flow. Native HTTP handlers share store revision checks with the game UI.

Expose only catalog/snapshot, validate, commit, preset import/export, and status.
Return conflict and validation errors without mutation. Browser refresh can discard
drafts only after an unsaved-change warning/recovery policy; disconnected requests
must resolve by request ID/revision instead of blindly retrying a possible commit.

## Papyrus footprints and failures

All routine new Papyrus footprints use `MMELog.MasterDiagnostic` and prefix
`[MME Narration Editor]`. They require only the master `enablePapyrusTrace` toggle,
not verbose mode. Existing roster prefix remains valid for roster-specific events.
Trace sparse boundaries: open/init; backend and profile resolution; request received;
validation accepted/rejected; revision conflict/important skip; save/import/export
result; runtime apply; close/load cancellation; listener/focus cleanup. Include
request ID, operation, profile, entry count, revision and concrete reason. Actor is
N/A for text-only operations; preserve actor footprints on existing gameplay routes.

Do not log every keystroke, frame, field validation, full prompt/preset, or auth
token. Browser-triggered operations enqueue a compact completion summary for the
Papyrus coordinator when a loaded game/VM is available, without delaying disk save;
drain on an event-driven boundary and gate there. When no VM is available, do not
pretend a Papyrus trace happened. Native routine logging must honor the mirrored
master toggle (default off until initialized), including browser operations.

Per repository policy, genuine failures use deduplicated `MMELog.Alarm`: failed
disk prerequisites/write/readback, corrupt active data, broken expected catalog or
native bridge, impossible response state. Alarms remain the existing exception to
routine trace gating. User validation errors, conflicts, cancellations, absent
optional Magelight/Skyrim.Net, disabled HTTP, and no changes are ordinary results,
not smoke alarms. Return concise status in the editor; no routine HUD notifications.

## Implementation sequence and acceptance gates

1. **Inventory and proof spikes.** Enumerate current routes/pools/readers; verify
   the exact winning API signatures and native toolchain; prototype case-safe
   payload transport, paused completion, user-root resolution, crash-safe replacement,
   and localhost start/stop. Keep diagnostics under ignored build/diagnostics.
2. **Persistence core.** Generate shared catalog/validation/defaults; implement
   sparse store, revisions, locking, backups/recovery, native runtime lookup and
   fallback, and exact export/import. Unit-test without launching Skyrim.
3. **Runtime integration.** Route canonical and cataloged pool reads through the
   overlay while preserving consumer semantics and existing fallback. Integrate
   reload/load invalidation and legacy migration. Keep native declarations and
   registrations paired. No optional framework script dependency in core scripts.
4. **In-game editor.** Implement tabs, shared UI assets/adapter, catalog cards,
   drafts and validation, import preview, status, focus/escape and logging. Retain
   existing roster action/session behavior. Visual QA at small/large resolutions.
5. **Browser adapter.** Add optional server, start/stop/open controls, session
   protections, shared assets and conflict UI; verify simultaneous editing.
6. **Build and acceptance.** Compile every affected PSC including optional and
   OStim-only variants, build standard universal and VR validation DLLs, run existing
   narration/pool/roster/page/logging/backend suites plus meaningful new tests.
   Rebuild `dist/MME Extensions.zip`, inspect paths, source/PEX revision pairing,
   licenses and all FOMOD options for MO2/retained Vortex compatibility. Exclude
   personal data, drafts, temporary files, logs, tokens, mocks and diagnostics.

Required new tests: sparse precedence; malformed and duplicate keys; unknown and
future schemas; string/pool semantics; token aliases and inserted-token single-pass
behavior; case-only/Unicode round trips; first-save/replace/permission/disk-full
failure; interrupted write/recovery; revision conflicts across two UIs/processes;
reload after external edits; atomic whole-import and merge conflicts; backup restore;
old customization capture; update adding/removing routes without losing overrides;
manual edits preserved when save reads a stale base; no game-save draft persistence;
separate profile selection and multiple game edition roots.

Runtime matrix: new/existing saves, old-save reload, main menu/load/new-game
transitions, rapid reopen/repeated Save, forced close/hibernate/focus denial, master
logging off/on, Magelight present/absent, Skyrim.Net present/absent, editor enabled/
disabled, player and NPC narration separately, original guards/chances/cooldowns
unchanged. Inspect actual rendered Skyrim.Net prompt lore and narration, and Papyrus
logs for stale state, stacks, repeated noise, and wrong actors. Browser: unauthorized
origin/Host requests rejected, port conflicts handled, game exit/start/stop and dirty
draft reconnection safe. Verify no requests from text preview affect gameplay.

Before release, test an actual mod update/replacement with personal files retained,
MO2 VFS default precedence and overwrite behavior, and retained Vortex-compatible
archive installation layout without modifying the retained installation. Runtime
acceptance requires a separately authorized test deployment; source/compile tests
cannot establish in-game behavior.

## Research references and unresolved proof points

- [Magelight Papyrus API](https://raw.githubusercontent.com/Severause/MagelightUI/main/docs/PAPYRUS.md): callbacks, load lifecycle, ownership and network policies.
- [Magelight UI project](https://github.com/Severause/MagelightUI): HTML rendering/input architecture. Installed host is 1.5.0; do not assume newer upstream features exist locally.
- Winning installed `Source/Scripts/JsonUtil.psc` header and declarations, resolved
  by houseCARL as above: dirty-file saves and Unload defaults; cached SDK agrees.
- [Windows known-folder resolution](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath).
- [Windows ReplaceFileW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-replacefilew): backup/replacement and error-state handling.
- [cpp-httplib](https://github.com/yhirose/cpp-httplib): candidate embedded transport; not yet selected or added.
- [JSON parser documentation](https://json.nlohmann.me/features/parsing/parse_exceptions/): candidate parser; duplicate-key handling needs an explicit policy/test.

Open proof gates are payload limits/case fidelity, VM behavior while paused, exact
user-root selection across supported editions/profiles, reader-by-reader pool
semantics, native parser/HTTP dependency and shutdown tests, and live Skyrim.Net
prompt verification. These are implementation tasks with acceptance criteria,
not evidence that current code already provides this feature.
