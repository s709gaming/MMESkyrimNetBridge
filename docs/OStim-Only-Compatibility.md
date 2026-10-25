# OStim-only MME compatibility

This FOMOD option is an experimental MME-only port for a separate **new-game**
profile. It does not support converting an existing SexLab save. Runtime approval
is pending; successful compilation does not establish gameplay compatibility.

Choose exactly one animation backend in the installer. Standard SexLab and SexLab
P+ retain their existing files. OStim-only installs a replacement MilkModNEW.esp
and isolated compiled scripts. The replacement retains all original MME FormIDs,
removes the SexLab quest binding, and substitutes a local keyword on the five
MME armors formerly protected by SexLabNoStrip. It has no SexLab master or links.
It is built from the installed MME Scripts 20220522 plugin; other MME revisions
require an explicit compatibility review. Original MME assets remain required.

## Installation

Keep the working profile and original mods. Create a separate MO2 profile and
use a separate installation of MME Extensions for this option. Reinstall with
Replace rather than Merge to avoid retaining P+ or standard-backend files.
Let the selected extension mod win its script and MilkModNEW.esp conflicts.
Do not enable both extension installations in the same profile.

OStim 7.2+ and the extension's scene assets are required. Enable OStim breastfeeding
in MME Extensions' MCM when testing that feature; a disabled setting remains
disabled. Keep MME's other prerequisites, including SKSE, PapyrusUtil, SkyUI and
the installed body/animation setup. This option does not regenerate behaviors.

Disable SexLab-dependent plugins in the test profile, including original Elsie,
JUGS, the Elsie compatibility patch and SLAnimLoader. Their OStim-only ports are
not included. Check other plugins for a SexLab master before disabling SexLab.
The experimental option also requires SexLab.esm and original DD Assets/
Integration plugins inactive or missing. Its MME_DDi bridge retains the public
MME signatures but reports integration unavailable and performs no DD actions.
This deliberately excludes original DD support from this choice; standard/P+
DD behavior is unchanged. It does not replace or patch OSL Aroused's zadlibs.
Deactivate the SexLab mod folders as well as the plugin, and inspect physical
Data and MO2 overwrite for leftover SexLab scripts/DLLs before claiming an
absent-dependency test. Optional arousal/body frameworks are separate integrations;
their names alone do not establish whether they require SexLab.

## Shared backend API

MMEFrameworkBackend uses actors/forms and simple results; it exposes no SexLab
thread types. It provides readiness, actor validation/activity, no-strip policy,
gender classification, milking reservation/release, scene-tag interpretation and
a breastfeeding request entry point. Existing MMEDebug/OStim lifecycle code owns
asynchronous startup, request tokens, participant order, completion and cleanup.
No synthetic SexLab plugin or framework scripts are installed. Reservations are
internal to this bridge: unrelated OStim callers must honor IsReserved to avoid
starting a scene during standalone MME milking.

Armor policy preserves MME's local protection, then delegates to OStim's verified
OUndress.CanUndress API, including its no-strip keyword and configured slots.
This is the OStim policy, not a claim that every SexLab stripping rule is identical.

MME's existing SOS and equipped-schlong checks remain in akActorSex. Without
SexLab's custom gender overrides, classification defaults to the actor-base sex;
an explicit integer StorageUtil override, MMEExtensions.Backend.Gender, supports
0/1/2 for male/female/beast classification. Existing SexLab override values are
not migrated. Creature support is limited by OStim's own actor validation.

Original milking, progression, slots, capacity and inventory calculations remain
in MME. Pump/lactacid/milking effects use backend actor validation. Original MME
breastfeeding requests delegate to the existing persistent OStim scene service.
The original MME orgasm calculation body is retained behind the verified
ostim_orgasm callback, with active-actor/current-scene checks and duplicate
suppression. Scene tags and known OStim actions map to the original MME categories;
unrecognized custom actions do not invent a matching category.

SexLab facial expressions, moans and legacy scene callbacks are intentionally
unused. OStim owns scene presentation. Elsie-only routes are unavailable in this
phase. MME gameplay must not call an unavailable native to discover availability.

## Diagnostics and testing

Enable the existing master Papyrus logging toggle (enablePapyrusTrace) for
[MME Extensions Backend] footprints. These cover initialization, source/drinker
roles, request IDs, eligibility, startup results, completion, ownership and cleanup.
No additional verbose toggle is required. Routine backend diagnostics do not
display player notifications. Unsupported presentation is a deduplicated skip.
Required-backend or local-keyword failures produce deduplicated smoke alarms.

Required runtime checks: new game with SexLab physically absent; player and NPC
source/drinker directions; pumps and standalone milking; lactacid conversion;
armor protections; DD absent plus installer rejection when DD is active; orgasm gameplay and custom scene
tags; repeated requests and duplicate events; interrupted scenes; save/load;
disabled MCM/master; logging off/on; and correct milk/inventory/controls cleanup.
Use normal Quit to Desktop. Identify manual dps dumps and Alt+F4 reports separately
from spontaneous failures. Do not overwrite a known-good save during testing.

The upstream MME records/scripts are invasive compatibility overrides. Preserve
upstream credits and check applicable redistribution permission before publishing;
this local build does not grant distribution rights.

## Follow-up fixes (2026-10-25)

The OStim conversion choice now uses its own default-off global 0008D0, plus an
authoritative player Milk Maid faction condition. Female NPC subjects must not
already be Milk Maids or slaves and must not be children. The action retains its
independent eligibility checks. General OStim drinking choices still use 00085A.
The controller refreshes the dedicated source gate at existing menu, lifecycle,
conversion and milking boundaries; the isolated MilkQUEST variant also refreshes
after MME's CurrentSize milk/size update. No new polling loop was added.

The isolated MME_zbf bridge now reads the original ZaZ gag (008A4D) and oral-permit
(019FDA) keywords dynamically. It preserves the original bridge function names
without depending on zbfBondageShell or its SexLab-related type chain. ZaZ's own
MCM/SexLab module is not ported: its missing-parent errors remain a separate
compatibility limitation. CBBE 3BA's MusSOSManagerSL binding failure likewise
belongs to its SexLab-specific physics adapter, separate from its OStim adapter.
Do not remove the whole ZaZ or physics plugin to hide those failures.

The isolated MME_MilkSuccubus override caches the original player-cell reference
count, uses index < count and rejects missing references before HasLOS. Target,
required quest and optional arousal prerequisites are checked. Original
transformation events, actor selection and +25 arousal semantics are retained.

New routine footprints use only the master enablePapyrusTrace toggle, under
[MME Extensions Dialogue Gate], [MME Extensions ZaZ Bridge],
[MME Extensions DD Bridge] and [MME Extensions Succubus]. Genuine failure alarms
are deduplicated/rate-limited. No routine player notifications were added.

Build verification now inspects all 65 effective MME scripts (original scripts
plus selected replacements), rather than only the 24 compiled variants. This
does not certify the internals of every third-party dependency. The runtime
evidence so far establishes player conversion and NG inflation on the previous
build; these new fixes require fresh tests, particularly NPC routes, shrinking
after milking, unregister cleanup and logging off/on. Experimental status remains.
