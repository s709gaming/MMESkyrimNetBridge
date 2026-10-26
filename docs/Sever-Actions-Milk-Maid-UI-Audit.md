# Sever Actions UI / Milk Maid dashboard audit

Audit date: 2026-10-25. Scope: local reference package and repository/MME sources;
static feasibility only. No gameplay, installed mods, profiles, or packages changed.

## Verdict

A small Milk Maid dashboard is feasible. A read-only roster is low complexity;
a manual self-milking button adds moderate gameplay validation/testing. Reuse MME's
roster and storage functions, and our existing self-milking infrastructure. Do not
build a second milk simulation or copy Sever Actions' large app.

The reference package declares **SeverActions 4.5.0** in `fomod/info.xml` and
`00 Core/SKSE/Plugins/SeverActionsNative.toml`. Its bundled version file declares
**Magelight UI 1.3.0**, built 2026-10-18. This establishes the local reference
version, not that it is the newest published release or newer than an unidentified
older copy. The FOMOD installs Magelight as required core content.

The main interface is now Magelight, not PrismaUI. The legacy
`SeverActions_PrismaUI.psc` explicitly says it is a no-op save-compatibility shim;
page gathering and routing moved into native components. The main HTML loads a
bundled React application. Its frontend sends named messages such as `uiReady`,
`requestPageData`, `actionRequested`, `settingChanged`, and `menuClosed` through
native-bound window functions. Native responses enter `window.receivePageData`.
Some pages refresh only while active; the inspected world page uses ten seconds.
These are Sever Actions' own message contracts, not a general Magelight API.

## Useful discovery: a smaller Papyrus integration exists

The bundled `Scripts/Magelight.pex` was decompiled read-only with houseCARL into
`build/diagnostics/sever-ui-audit/Magelight.psc`: 29 functions, all structured.
Its surviving docstring documents a general script-owned UI tier:

- `RegisterMod(modId, displayName)` and `CreateView(...)` create our own page.
- `RegisterListener(view, name)` binds a page's `window.<name>(payload)` call;
  Papyrus receives `Magelight_JS_<name>` with payload and view ID.
- `Call(view, functionName, argument)` sends JSON/text back to a page function.
- `ShowView`, `RequestUIMode`, `ReleaseUIMode`, `BindHotkey`, and `DestroyView`
  cover visibility, focus and lifecycle.
- `IsReady`, version accessors, and `GetLastError` support availability/errors.
- DOM-ready/load-failure/UI-mode events exist, and registrations must be renewed
  after every load. Script-owned mods cannot control another plugin's views.

Consequently an isolated Papyrus controller plus a plain HTML/CSS/JS page may
suffice. Adding new C++ functions to MMEExtensions.dll is not demonstrated to be
necessary. Do not drive Sever Actions' existing view or depend on its action
router. No need to make Sever Actions a requirement. A bespoke small page also
avoids a React toolchain and bundling unrelated assets.

The PEX lacks source comments/default parameter values beyond surviving docstrings.
Before implementation, obtain/verify the authoritative Magelight Papyrus SDK and
its view path, layout, hotkey action values, focus/pause and ownership contracts.
The recovered declarations establish feasibility, not successful runtime binding.

## Data contract

Verified original MME sources from the MO2 original MME script mod:

- `MilkQUEST`: `Actor[] Property MilkMaid Auto`; also a separate `MilkSlave` array.
- Original `Milkmaidinfo()` enumerates `MilkMaid` using `.Length` and `None` checks.
- `MME_Storage.getMilkCurrent(actor)` returns actor-keyed stored current milk.
- `MME_Storage.getMilkMaximum(actor)` returns actor-keyed capacity. It can lazily
  initialize a missing capacity on older saves using MME's calculation, so the
  getter is not strictly free of writes. Prefer this framework function over
  reproducing its formula; explicitly account for that initialization in tests.

Enumerate the live MME MilkMaid array, skip None/deleted references, deduplicate by
actor identity, and revalidate membership. Do not cache an array index between
refresh and click, and do not join parallel arrays by a remembered slot. MilkSlave
inclusion is a separate product choice; keep version one to MilkMaid as requested.

Each row needs actor identity, display name, current amount, capacity, percentage,
loaded/nearby/alive state and command availability/reason. Use MME's units, not
invented liters or a count of inventory bottles. Fullness is
`100 * current / maximum` only when maximum > 0; otherwise show unavailable.
Clamp a progress bar visually if necessary while preserving an over-capacity
numeric value. For unloaded actors, show MME's last stored values; do not force
load, teleport, or simulate their milk production.

Minimal presentation (illustrative values):

| Milk Maid | Milk | Fullness | Action |
|---|---|---|---|
| Player | 12.5 / 20.0 | 62.5% | Milk Self |
| Hulda | 8.0 / 10.0 | 80.0% | Unavailable: not nearby |

Open + Refresh + Close is enough for the first version. Read on open and explicit
refresh; optionally refresh on MME start/end/production events while visible.
Avoid an always-running poller. Original MME getters contain unconditional traces,
so frequent roster polling could amplify framework log noise even with our master
logging toggle off. Do not fix that through a broad original-source override.

## Milk Self button: reuse with care

`MMESelfMilking.GetInvalidReason` already checks actor presence/life/load, optional
player/nearby constraints, MME controller/spell/membership, and active milking.
`StartExisting` validates then casts the existing `MilkSelf` spell; dispatch is not
proof that the scene actually started. MME start/end events confirm execution.

`StartCompatible` is the automatic route and is not a drop-in manual-button API:

- Living/Parasite armor: it returns True while intentionally suppressing ordinary
  MilkSelf to retain the armor. That cannot be shown as 'milking started'.
- Dwemer armor: it delegates to `TryCandidate`, which retains the 90% threshold and
  its own sequence locks. A below-threshold click will not start a sequence.
- Original `MME_StartMilking` can select a different mode in combat/on a mount.
  A manual UI should refuse those states before casting rather than relying on it.

Add an isolated manual-command adapter with an explicit result/reason; do not
change automatic scheduling or clear milk directly. Start conservatively with a
player button; a per-row NPC button is feasible for nearby loaded eligible maids.
For a low-cost first release, disable manual commands for special armor with a
clear reason rather than silently altering its established behavior.

Validate again at click execution: master/feature enabled, actor still on roster,
adult, alive/enabled/loaded, nearby for NPCs, positive milk/valid capacity, not in
combat/mounted, not owned by an MME/Extensions/SexLab/OStim scene or another action,
and applicable restraint/movement guards. Reuse existing safety APIs with their
standard and OStim-only variants; preserve all optional dependency behavior.
Close/release the UI pause/focus before dispatch. Deduplicate repeated clicks and
confirm startup through MME events, with gated traces for actor, validation,
dispatch, actual start/end and skips; genuine failures use deduplicated alarms.

## Installed environment versus reference

Read-only houseCARL VFS query on Default reported:

- `PrismaUI.dll` exists, winner `Prisma UI`.
- `Magelight.dll` and `SeverActionsNative.dll` absent in that resolved profile.
- `MME_Storage.pex` winner original MME script mod.
- `MilkQUEST.pex` and `MMESelfMilking.pex` winner MME Extensions.

This is static installed-file resolution, not proof of loaded runtime DLLs.
Thus the reference's Magelight design is not currently an available installed
host. Keep UI support optional and isolated from the core MME scripts. A Prisma
implementation is another feasible architecture, but the reference Prisma folder
only supplies the runtime and JS control-map typings, not the required native host
SDK; it does not establish an equivalent Papyrus view/listener tier. Existing
Prisma installation alone does not eliminate bridge development.

## Relative cost and next preflight

| Scope | Relative difficulty | Main work |
|---|---|---|
| Read-only list via Magelight Papyrus tier | Low, roughly 2/5 | View/controller lifecycle, roster snapshot and JSON |
| Guarded player Milk Self | Low to moderate, roughly 3/5 | Validation, armor policy, focus release and real start feedback |
| Per-row NPC commands | Moderate | Stale actors, proximity, animation ownership and cleanup |
| Prisma native integration | Higher initial setup | Verify SDK; native view, listener and game-thread bridge |

These ratings are engineering estimates from static inspection, not benchmarked
implementation times. Keep the first UI to one table with Refresh, Close, and an
optional player Milk Self button. It does not require Skyrim.Net or SexLab for
read-only MME statistics; animation routing still follows the chosen backend.

Before implementation: confirm chosen host/version and supported Skyrim runtimes;
verify the SDK and test one script-owned view's open/close/callback; isolate its
optional dependencies/package choice; agree special-armor command behavior; then
compile and test standard + OStim-only builds. Test player/NPC, sparse/changed
roster, zero/over capacity, unloaded/deleted actors, double clicks, all busy/disabled
states, save/load, focus/pause recovery, host absent and optional frameworks absent.
No full Sever Actions audit, latest-release verification, native source audit or
live UI test was performed; the reference ships DLLs and built frontend assets,
not the native implementation source.
