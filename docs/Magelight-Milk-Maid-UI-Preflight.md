# Magelight Milk Maid roster - revised audit

Date: 2026-10-25. Audit only: no gameplay/code implementation, installation, or
release changes. Supersedes the host/SDK uncertainty in the earlier Sever Actions
UI audit. Scope assumption: reserve the Milk Self button but leave it disabled;
first implement the display, hotkey, MCM entry, Refresh and Close.

## Verified new reference

`Reference mods/magelightUI/SKSE/Plugins/Magelight/VERSION.txt` declares standalone
Magelight UI **1.5.0**, built 2026-10-24 23:35. This is newer than the **1.3.0** host
bundled in the local Sever Actions 4.5.0 reference. It includes the actual public
`Source/Scripts/Magelight.psc`, eliminating the previous dependence on decompiled
signatures and missing defaults. No native C++ source/header is needed for the
Papyrus path proposed here. This does not prove runtime support on this game yet.

Confirmed from that source:

| Need | Public API / contract |
|---|---|
| Register our own UI | `RegisterMod(modId, displayName)`; script-owned mods only |
| Load our HTML | `CreateView`; htmlPath relative to `Data/Magelight/<modId>/` |
| Fill screen responsively | w=h=0 means fullscreen; panel layer is supported |
| Toggle by key | `BindHotkey(view, dxScancode, action)`; 1 = UI toggle, 2 = paused UI toggle, 3 = visibility toggle, 0 = unbind |
| Input/focus | `RequestUIMode(view, pauseGame=false)`; cursor/keyboard to page and game controls suspended |
| Close | `ReleaseUIMode(modId)` plus appropriate visibility cleanup |
| Send snapshot | `Call(view, functionName, argument)` invokes our JS function |
| Refresh/Close clicks | `RegisterListener(view, name)` exposes window.name(payload), delivered as `Magelight_JS_<name>` |
| Lifecycle | DOM-ready, reload, destruction, focus/UI refusal, UI entered/exited and render-dead events |
| Idle resources | `SetHibernate`; hidden-view wakeup may reload and fire DOM-ready |
| Diagnostics | `IsReady`, `GetVersion*`, `GetLastError` |
| Network | file-only default; no internet service is needed |

The host's PageUp key (default DirectInput 201) cannot be bound by a mod. Escape
normally exits UI mode, but the page can take it, so implement consistent Close and
Escape handling rather than assume hiding a page releases all input. Register
ModEvents again after every load. Stored native view IDs must not be trusted across
save/load or host reload. Qualify each callback with our current view ID and each
host event with our unique mod slug. Use uniquely prefixed listener names.

## Current installed environment

Read-only houseCARL VFS check of Default still reports `Magelight.dll` and
`Scripts/Magelight.pex` absent; PrismaUI.dll is present. The new reference is not an
installed UI host. Do not copy it into the game as part of this audit. A runtime
smoke test requires installing/enabling standalone Magelight through the normal
mod-manager path first, and starting a new game process so its SKSE DLL can load.

## Minimal first UI

One original HTML/CSS/JavaScript page; no React, Node build, Sever Actions runtime,
Skyrim.Net call, or new native DLL feature is required by the proposed architecture.
Use the Sever Actions page only as a communication/layout reference. Its native
`requestPageData`/`actionRequested` messages are specific to that app; our listeners
will be much smaller. Keep our view under its own slug and directory.

- Header: Milk Maids; optional last-refresh state.
- Rows: name, current milk / maximum, fullness percentage, small progress bar.
- Reserve a disabled Milk Self button labelled unavailable/not implemented yet.
  Do not cast a spell or report success in this phase.
- Refresh and Close; readable empty roster and missing-framework states.
- No background dashboard widgets, maps, relationship system or actor scans.

Opening: configurable hotkey and Open Milk Maid Roster text button on the **General**
(first) MCM page. Existing SkyUI SDK provides AddKeyMapOption and
OnOptionKeyMapChange. Persist the key with a safe initially unassigned default and
an existing-save migration; unbind the old key on change. Bind a UI toggle rather
than a visibility-only hotkey so keyboard/mouse focus is acquired too.

MCM opening is the main integration edge: queue the request until SkyUI has closed,
then acquire Magelight UI mode. The existing SDK exposes OnConfigClose. Verify
actual close/focus event ordering; do not grab input over an active SkyUI menu or
solve it with an indefinite wait loop. A non-pausing panel is the simplest first
choice while Papyrus refreshes the roster. No animation/action runs from it yet.

Refresh on initial DOM-ready/open, explicit Refresh, and optionally relevant MME
events while visible. No permanent polling loop. Reuse an existing view, and do
not repeatedly allocate new views when a hotkey is pressed. Publish only the newest
snapshot for the current view/session; discard late callbacks after close/load.

## Authoritative MME data

Original MME `MilkQUEST` declares `Actor[] Property MilkMaid Auto`. Enumerate its
actual current length, skip None/deleted references, deduplicate actor identity and
revalidate registration. MilkSlave is a separate list and is not silently merged.
Never persist a roster-array slot as a row's permanent identity.

Verified original function signatures:

- `float function getMilkCurrent(actor akActor) global`
- `float function getMilkMaximum(actor akActor) global`

Use these MME values, not an inventory bottle count or an independently maintained
counter. Percentage = current / maximum * 100 when maximum > 0; otherwise N/A.
Preserve over-capacity numeric values while clamping only the bar. Label quantities
as milk/framework units, not liters. Unloaded registered actors can remain listed
with MME's last stored values; do not load or move them or simulate their production.

The capacity getter lazily initializes missing old-save capacity through MME's own
calculation. Account for that framework-owned write or show unavailable when the
capacity is missing; do not silently introduce our own capacity calculation.
Original getter traces are not master-gated, reinforcing the choice of on-demand
refresh instead of rapid polling. Our own UI routine traces remain master-gated.

## Code/dependency boundary and packaging

A small Papyrus UI receiver/controller owns Magelight calls, lifecycle and snapshot
serialization. The existing core can request Open through a ModEvent so its common
scripts do not need Magelight types or native bindings. Before implementation,
choose the receiver's actual attachment/bootstrap: an isolated companion quest
with player-load handling is a straightforward option, but involves a small
optional plugin; do not assume a Hidden utility script receives events by itself.
Avoid overriding the full MCM separately just to attach optional framework types.

Check native host presence through verified `SKSE.GetPluginVersion(name)` (returns
-1 when not loaded), then Magelight readiness/version after presence is established.
Verify the registered SKSE plugin name in the smoke test. Calling Magelight.GetVersion
without its DLL explicitly logs a native-call error per its SDK, so that must not
be the sole normal absence-detection path.

Keep UI as an optional component with an explicit Magelight requirement; roster
statistics do not acquire a SexLab or Skyrim.Net dependency. Existing MME, MCM and
animation backends keep working when the UI host/option is absent. Compile affected
PSCs, preserve source/PEX pairs, package only our page/controller and any isolated
receiver plugin. Prefer a separately installed host over silently shipping its DLLs.
The host's MIT licence and third-party notices are supplied in the reference if
bundling is ever chosen; keep its runtime DLL names/files intact.

## Future narration JSON editor

Yes: the same window can later add a Narration tab. Our existing twelve feature
files, 72 routes, generated token metadata, ValidTemplate/ValidateRoute and ReloadAll
provide the data contract. The UI framework itself does not make page JavaScript a
filesystem editor. RegisterListener sends the edit to a backend; only a deliberate
Save action may update the known narration files.

Start with a structured editor, not an unrestricted raw-file textarea:

1. Choose feature/file and route; show required placeholders.
2. Edit template text or alternatives and show an illustrative preview.
3. Validate in both page and backend; the backend is authoritative.
4. Save, preserve a recoverable previous revision, verify readback, then ReloadAll.
5. Provide Cancel/Revert and clear save/failure state. Keep dirty changes in memory
   until Save; leaving the page must not auto-save.

Use a fixed allowlist of narration files/routes, preserve schema/metadata/unrelated
fields, reject unsupported tokens, malformed/empty values and invalid arrays.
Backends must not accept arbitrary filesystem paths or JavaScript to evaluate.
Use normal JSON serialization plus DOM text/value assignment, not string-built
Eval or unescaped HTML. Include size bounds, Unicode/escape handling, stale-edit
conflict detection and save/load invalidation of pending edits.

JsonUtil supplies per-path setters, SetRawPathValue and explicit Save, but its
normal cache may autosave pending edits on a game save. Therefore validate incoming
edits before mutating the live file cache; do not rely on 'not calling Save' as a
transaction or Cancel mechanism. JSON payload parsing/staging, backup/restore and
atomic-write guarantees need a separate save-path preflight. No such guarantees
have been demonstrated by the UI API. Keep MMENarrationText's ordinary read path
read-only and introduce an explicit editor writer, not new setters in GetRaw.

No runtime compiler is needed for player-edited JSON. Editing the shipped defaults
in the source repository still requires regenerating fallback code for releases.
The editor is separate from MCM game settings and Skyrim.Net action YAML.

## Cost and acceptance

Bare-bones roster: **about 2/5**, now that real Papyrus SDK signatures and defaults
are supplied. UI focus/lifecycle and optional receiver bootstrap are the main work,
not drawing a table. Future narration editor: **about 3/5**, with most effort in
validation, backups and cache-safe writes. Milk Self remains a separate gameplay
change and retains the earlier audit's scene/special-armor caveats.

Before implementation: decide the optional controller attachment, obtain a working
host installation for runtime validation, compile a minimal owned view, and verify
open/close plus one refresh callback. Then wire roster and MCM/hotkey migrations.

Acceptance: hotkey/MCM open; close/Escape/focus return; another UI owning input;
empty/sparse/deduplicated roster; names/Unicode/JSON escapes; valid/zero/missing/
over capacity; unloaded actors; repeated open/refresh; save/load/recreated views;
resolution scaling; disabled master/feature; absent host; standard and OStim-only
script builds; no routine background spam or new milk-state mutation.

This audit did not install the host, compile UI code, or perform an in-game UI test.

## Final preflight decisions (2026-10-25)

Ready for repository implementation with the following bounded scope; no further
product preference is required to begin. Installing or changing MO2 remains a
separate step, and live validation is pending.

### Attachment and dependency plan

Use a small **optional ESL-flagged companion ESP** for the roster controller quest
and player-load alias. Its reference to the base controller makes MMEAlert.esp a
real required master of the add-on; the base plugin gains no UI master/dependency.
This avoids patching the base quest's VMAD merely to bootstrap the UI, and avoids
putting Magelight native declarations/types into the common core scripts. Validate
new quest/alias schema and generated records during implementation; no plugin was
authored in this preflight.

Compile the dedicated UI scripts against the supplied Magelight.psc as a build SDK.
Do not ship an overriding copy of the host's Magelight.pex/PSC in our add-on.
The host remains separately installed. The shared MCM communicates with the add-on
using namespaced ModEvents; it neither calls Magelight natives nor casts to the
optional UI script. The companion owns callbacks, roster serialization and focus.
Use a live per-session view ID plus a load generation to reject stale requests.

Core MCM General page gets Open Milk Maid Roster and a key mapping. Use initial
settings `maidRosterUiEnabled=1` and `maidRosterHotkey=-1` (unassigned), append-only
MCM initialization/migration and option-ID resets. An installed-component/host
absence disables opening with a concise explanation rather than an alarm. The
master Extensions enable state and UI enable setting gate open/refresh; Close and
cleanup always remain allowed. Settings changes notify the optional controller.

The controller uses SKSE/Papyrus RegisterForKey rather than a second native key
binding owner, so it can check master/feature/menu/text-entry state before opening.
Accept keyboard mappings in the first version, with no forced default key. An
already-open own view can always close before unrelated-menu guards apply.
Unregister the previous mapping on change and renew key/menu/ModEvent registrations
on load. Do not hardcode Home or take Magelight's reserved PageUp toggle key.

Open from the MCM is deferred until Journal Menu closes. The existing core already
handles that exact menu name. Verify actual focus ordering; a request must be
canceled on disable/load instead of becoming a delayed surprise open. If another
view owns input, refuse this open cleanly; never steal another mod's UI mode.

### Data and display policy

One plain page, full-screen transparent outer layout with a readable panel. Use
non-pausing UI mode initially, Refresh and Close/Escape. The roster refreshes on
open/DOM-ready and explicit Refresh, with request coalescing and no idle poller.
Keep an informational disabled Milk Self button; no action dispatch, spells,
actor conversion, armor handling or milk modification is part of this phase.

Use the real MilkMaid array, current length, None/deleted/invalid references and
identity deduplication. Do not include MilkSlave silently or retain array indices
as identities. No nearby scan or persistent copied roster. Render each name safely
as text; data and UI state pass as properly escaped JSON.

To make the initial UI strictly observational, check whether MME's capacity storage
exists before calling getMilkMaximum. If missing, display N/A and let MME initialize
it through normal gameplay; do not trigger the getter's migration-write branch.
When present, use the framework getters. Do not call update/calculate/set milk APIs.
Record invalid-capacity skips as gated diagnostic counts, not recurring smoke
alarms or notifications. Preserve exact underlying values and round only display.

### Diagnostics and acceptance

Use `[MME Maid Roster UI]` for master-gated open source, eligibility, host readiness,
view reuse/creation, focus result, refresh result/counts, skip reason and cleanup.
No per-frame or per-row routine spam. Deduplicated smoke alarms cover a present
host failing registration/page load, malformed internally generated payloads or a
lost owned-view lifecycle invariant. Missing host/add-on, feature disabled,
empty roster and another UI's focus ownership are expected skips.

Build/source checks: compile all changed core and isolated UI PSCs; compile the
OStim-only MCM/controller derivatives as applicable; verify same-revision PEXs;
check optional add-on masters/quest/alias and ESL validity; validate FOMOD/XML for
both MO2 and Vortex including the 1:39 regression; inspect final archive paths and
exclude all probe/diagnostic artifacts. Keep generic archive filename; no new
release number is assigned by this work.

Runtime checks after host installation/restart: hotkey and deferred MCM open;
close/Escape/focus return; repeated open/refresh; another UI; empty and multi-actor
rosters including player/NPC/unloaded actors; missing/zero/over capacity; name
escaping; master/UI disabled; save/load/recreated views; no background activity;
standard and OStim-only optional-dependency behavior. Core host-absent behavior is
also required. Do not claim full acceptance from compilation alone.

### Concrete compile result and remaining prerequisite

A compile-only `MMEMagelightPreflight.psc` probe was compiled against the actual
1.5.0 reference SDK plus installed vanilla/SKSE sources. It checks signatures for
host readiness, RegisterMod/CreateView/RegisterListener/Call, UI focus/release,
visibility/destruction, and receiver ModEvent/menu/key registration. Result:
**one script succeeded, zero errors and zero warnings**. It was never executed or
installed. Probe and log live only under ignored
`build/diagnostics/magelight-preflight/`.

A fresh houseCARL file-resolution check still found no Magelight.dll, Magelight.pex
or Magelight source in the active profile. This does not block implementation or
compilation, but **install/enable Magelight and restart Skyrim before live UI
acceptance**. Verify its registered SKSE name/version from that actual launch.
No deployment authorization was inferred from this preflight request.

Future JSON editing stays out of this implementation. The proposed UI-to-backend
boundary leaves room for a Narration tab later; its explicit validated save,
backup/readback/conflict handling and cache-safe reload require their own change.
