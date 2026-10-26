# Player-editable narration JSON: implementation preflight

Date: 2026-10-25. GO for implementation within the scope below. This preflight
supersedes the earlier authoring-folder-only proposal: the requested folder must
exist in the installed mod and contain the text players actually edit.
No gameplay, installer, archive, README or installed files changed in this audit.

## Target and boundaries

Players use a normal text editor to tune narration wording, style instructions,
reaction pools and lore in one folder:

    Data/SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/

The repository's canonical JSON source should mirror that installed folder.
Keep one authored copy; build-generated fallback code is an output, not a second
place to edit prose. No development setup or Papyrus compiler is required for
players. JSON tuning does not create new gameplay triggers or alter actor
selection, eligibility, milk quantities, conversion, probabilities, cooldowns,
event IDs, callback names, thread ownership or native API wiring.

This is broader than moving files. It requires extracting inline prose and
making the three existing Skyrim.Net prompt assets read JSON-backed text.
Overall implementation risk is moderate; it becomes low-risk to edit afterward
only with correct defaults, validation and unchanged gameplay boundaries.

## Verified inventory

MMEAlertsSkyrimNet.psc has 15 DirectNarration sites, six private player-generation
sites and five player-TTS sites. All narration transport already lives there.
Including context publication, 21 functions submit narration/event content.
docs/Narration-JSON-Route-Map.json maps every one exactly once to the proposed
files and records source line, settings keys, old paths and callback names.
The mapping check passed for all 21 functions; it is a scope inventory, not a
prototype or proof that the future output is equivalent.

Three additional assets contain editable prose outside that script:

- mme_wearer_self_comment.prompt: player-generation system instructions.
- 0260_mme_extensions_milkmaid.prompt: ambient Milk Maid/milk lore.
- 0950_mme_extensions_breastfeeding.prompt: breastfeeding speech guidance.

Six YAML actions and two inline RegisterAction descriptions define actions, not
narration. Keep action execution/eligibility and YAML separate in this change.
Technical event-schema metadata, function names and true/false/source/drinker
decorator return values remain code contracts, not prose customization keys.

## Proposed files and coverage

| File | Content |
| --- | --- |
| Common.json | Shared player-generation writing instructions; optional shared style text |
| MilkDrinking.json | NPC/player, ordinary/Milk Maid, restrained and chest-drink wording; drink context |
| Breastfeeding.json | Prompt-module breastfeeding guidance; semantic role remains code-owned |
| MilkMaidCreation.json | Normal/forced conversion instructions and creation context |
| Milking.json | Start/end context messages |
| Fullness.json | Half/full narration, restraint variants, milestones and periodic status wording |
| MilkCravings.json | Craving narration framing and player instructions |
| TentacleArmor.json | Confirmed milk/arousal outcome templates and instructions |
| DwemerArmor.json | Effects, suit/attachment profiles, first equip/re-equip and milking events |
| Armor.json | Generic equip/strip instructions and nearby equipment-status wording |
| Thoughts.json | Ordinary/bound thought narration framing |
| Lore.json | Ambient lore currently embedded in the Milk Maid prompt module |

Also ship EditingGuide.txt and a compact route/token reference in the same
folder. Filenames and stable route keys are explicit; extra arbitrary filenames
do not automatically add new narration routes. Keep Settings.json and SkyrimNet
enable flags/TTLs/cooldown state outside this folder. They are not text templates.

Shared HUD/story pools (Thoughts, MilkCravings, ForcedMilkMaidConversion,
Injection and other notifications) currently supply some text used by narration.
Do not move those wholesale or redirect their non-AI readers. The new files own
AI framing and, where needed, narration-only alternatives. Existing rendered
notification/story text can remain an available substitution token. Editing
narration must not silently change HUD notifications or local stories. When
splitting an existing dedicated narration file, retain every profile/outcome key.

## JSON/schema design

Use ordinary UTF-8 JSON, not JsonUtil's typed key/value storage layout. Example
shape for documentation, not a production default:

    {
      "schemaVersion": 1,
      "_help": "Edit text values; preserve keys and supported placeholders.",
      "routes": {
        "npc_ordinary": {
          "situation": "{actor} drank {milkName}.",
          "instructions": "Respond with playful humor about this situation."
        }
      }
    }

Read with verified GetPathStringValue/PathStringElements and type/path checks.
Keep instruction strings and situation templates distinct where that makes
editing clearer. Permit documented string pools for routes that support them;
do not add RNG draws to the default path or change existing chance-roll order.
Preserve existing pool behavior when importing legacy arrays. An empty template
does not disable gameplay/narration; use the existing MCM toggle to disable it.

Use a per-route token allowlist and supplied facts: actor, source/drinker where
relevant, item/armor name, confirmed effect description, fullness/status and the
existing rendered reaction/story as applicable. Instructions may omit optional
tokens; situation templates must retain enough required identity/fact tokens for
that route. Preserve supported legacy actor aliases, including {ACTOR} and
{ActorName}, when importing. Do not evaluate user text as Papyrus or as a second
Jinja template. Unknown/missing required tokens must not leak raw placeholders
into a request.

Render from the original template in one pass so a token-looking actor name is
not processed again as a template. Use native string-search/substrings around
placeholders rather than a Papyrus per-character scan. Keep JSON escaping at the
final structured API boundary: quotes, backslashes, CR/LF, tabs and Unicode must
survive once, without double escaping. Continue to supply actual actors through
the native arguments and confirmed outcomes through code; JSON does not select
or pretend to acknowledge a gameplay result.

## Loader, fallback and cache behavior

Add a small Skyrim.Net-independent MMENarrationText helper for file/key lookup,
validation and rendering. It must not import SkyrimNetApi, scan actors, register
timers, wait, alter gameplay or submit requests. Keep existing public Narrate*/
Send* signatures and the controller's six callback entry points unchanged.

Generate a compiled defaults helper from the canonical shipped JSON at build
time. Do not hand-maintain a second set of English defaults. Missing files/keys
or invalid user values fall back per feature/key to those defaults; one damaged
file cannot disable every narration feature. Unsupported schema versions also
fall back. Known-invalid values should be cached/reported once until reload,
rather than reparsed/logged for every status publication. No file polling.

Never Set*/Save narration files during ordinary use. Confirmed installed
JsonUtil.psc says modified files can be saved automatically when the game saves.
Read-only loading preserves players' formatting and prevents surprise rewrites.
Do not run the existing EnsureDefaults logic over these new content files.

Provide an explicit MCM Reload Narration JSON action, not a new timing setting.
Reload only the fixed narration filename list: Unload(file, False, False), then
Load/validate. **Unload's default saveChanges is True**, so omitting the False
argument can overwrite edits. A not-yet-loaded file is not a failure. Do not
unload Settings/SkyrimNet/shared gameplay JSON or discard their pending changes.
Malformed reloads use compiled fallback; retaining last-good user data would
require a separate snapshot mechanism and is not promised. Do not autosave or
rewrite the malformed file to repair it.

Game restart is a supported simpler workflow. An in-flight LLM request retains
the already submitted text; reloading does not resend it or change its callback.
No synchronous waiting for LLM completion is introduced.

## Exact APIs verified

houseCARL confirms JsonUtil.pex and both source paths currently win from the
PapyrusUtil mod. Installed source and the offline Papyrus reference agree on:

- Load(String FileName) -> Bool, native global.
- Unload(String FileName, Bool saveChanges=True, Bool minify=False) -> Bool.
- IsGood(String FileName) -> Bool; GetErrors(String FileName) -> String.
- JsonExists(String FileName) -> Bool.
- GetPathStringValue(String FileName, String Path, String missing="") -> String.
- PathStringElements(String FileName, String Path, String invalidType="") -> String[].
- IsPathString/IsPathArray and CanResolvePath are available in installed source.

The installed source documents StorageUtilData as the root, subfolder support,
automatic .json extension and ordinary paths such as .foo.bar[1]. Normalize new
helper paths to MMEAlerts/Narration/<file>, without an OS-absolute path.
Native cache/reload behavior still needs the implementation runtime test; API
declarations alone do not prove disk edits are picked up in a running game.

The shipped Skyrim.Net SDK verifies DirectNarration(content, originatorActor,
targetActor), SendCustomPromptToLLM(promptName, variant, contextJson, callbackQuest,
callbackScriptName, callbackFunctionName), TriggerPlayerTTS(dialogue), and
RegisterDecorator(decoratorID, sourceScript, functionName). Preserve the current
meaning of 0=accepted for direct/TTS and 1=queued for private generation.

## Adapting the prompt files

Keep .prompt files as thin installed Skyrim.Net adapters at their current paths;
players should not have to edit them. For private player generation, include the
selected Common/feature writing instructions in contextJson and render that field
in the existing wearer prompt. Keep role/output-format protocol and actor/fact
contracts intact. Preserve speaker/situation fields and all six callback names.

For ambient lore and breastfeeding guidance, add JSON-backed text decorators
using the same Actor-to-String pattern as existing decorators. The modules keep
their render_mode/valid-actor/eligibility checks and render the new text slots.
Keep the existing boolean/status/role decorators unchanged. This needs new
registration checks and tests: merely moving the three files would leave their
hard-coded prose outside the promised JSON compartment.

The manifest and six YAML actions keep their identifiers, paths and execution
wiring. No new LLM calls are added. Verify templates with the available Skyrim.Net
content validator or actual renderer before claiming runtime equivalence.

## Migration and protecting player edits

Old dedicated narration inputs are TentacleEffectNarration, DwemerEffectNarration,
DwemerSuitNarration and DwemerAttachmentNarration. SkyrimNet.json also contains
start/end/drink/creation messages alongside settings. New narration files become
the authoritative editing location; leave settings and shared local pools alone.

Provide an explicit Import Legacy Narration action with a fixed mapping of
recognized text keys into the new files. Preserve old files and gameplay state.
Do not silently replace an already-customized new route; import only missing or
unchanged-default destinations, report conflicts in the user-requested summary,
and require a separate explicit choice for any overwrite. Validate old ordinary
JSON paths and legacy typed/string-versus-array shapes rather than assuming one
getter reads every representation. Import is the deliberate exception to the
new files' normal read-only rule. Verify writes/readbacks and report the imported
file/route count. No blanket settings reset or save conversion is involved.

Replacing/reinstalling a mod can erase files before scripts run. No runtime
migration can recover already-deleted custom text. EditingGuide must explain
backing up the folder before updates and keeping a personal narration-preset mod
that wins file conflicts. MO2 users can open that mod's folder; Vortex users can
manage the same preset files through their normal mod deployment. Neither needs
a coding setup. Missing future keys use compiled defaults, so older sparse
presets continue working without requiring a full reset.

## Diagnostics and user experience

Keep normal footprints under the master Papyrus logging toggle, with a consistent
[MME Narration JSON] prefix: file, route, load/render result and fallback reason.
No full payload dumps or repeated polling traces at routine level. Missing
optional customization is a fallback/trace, not a smoke alarm. Malformed or
unsupported supplied data and genuine failed import/write prerequisites get
actionable, deduplicated failures. Preserve existing route traces and cooldowns.
User-requested Reload/Import may show a concise MCM result; do not emit automatic
gameplay notifications for every file read or expected skip.

Guide: open the narration folder, edit with a plain-text editor, preserve UTF-8,
quotes/commas/escapes and keys, then Reload or restart. Include copyable examples,
a restore-defaults procedure and per-file/per-route token lists. JSON has no
comments; use documented _help fields. Build validation should reject duplicate
keys, while runtime validation must not claim it can detect duplicates if the
native parser silently accepts them.

## Implementation order and acceptance

1. Capture existing default payload fixtures and all route-specific selection,
   callback, cooldown and duplicate-suppression behavior. Create the 12 JSON files,
   strict build validator and generated defaults helper from that baseline.
2. Implement the pure data loader/renderer and explicit Reload/Import controls,
   preserving MCM settings/property names and initializing any internal upgrade
   markers safely. Internal SkyUI schema updates are not release version changes.
3. Convert all 15 narration routes and six context-publication functions, including
   helper-generated restrained/fullness/equipment status text. Keep backend calls
   and route authorization in place. Split shared flavor only at the AI boundary.
4. Convert the three prompt assets to JSON-backed adapters and test decorators.
5. Compile affected PSCs, regenerate the OStim-only main-script variant, and
   include helper PSC/PEX pairs for all backends. Update existing literal-based
   contract tests to assert payload/behavior rather than accidental source layout.
6. Package the folder and EditingGuide through both source/build and FOMOD paths;
   check archive contents/hashes and emit only MME Extensions.zip. Do not change
   release version numbers, README or installed files without separate scope.

Required checks: every inventory route has a documented JSON key/default; JSON
alone changes each requested writing surface; baseline payload text is preserved
or every intentional difference is reviewed. Test empty/missing/wrong-type/bad
syntax/unknown schema, token aliases/repeats/unknowns, token-looking actor names,
Unicode and JSON escapes, legacy imports and conflict handling. Test player vs
NPC speech, actor-role targeting, optional Skyrim.Net absent, master/feature off,
settings changed during queued generation, request rejection, overlapping
requests, unchanged cooldown writes and no duplicate token-using calls. Verify
shared local stories/notifications remain unchanged. Test live reload and restart,
including MO2 file winners and Vortex's deployed paths. Observe real renderer
output for both new text decorators; static compilation is insufficient.

Known remaining runtime acceptance work is not a design blocker: JsonUtil reload,
the new decorators and preset persistence must be tested after implementation.
Baseline tests from the prior audit passed for TentacleNarration, DwemerEffects,
DwemerArmor and MilkCraving, but those do not substitute for this expanded matrix.
