# Milk Maid story reader fix preflight

Audit date: 2026-10-27. No gameplay source, installed files, profiles or packages changed.

## Findings

The curse gameplay completed in the latest test: boss chest Skyrim.esm:0002B000, 100% chance, existing player Milk Maid, max 4, requested/actual addition 2, stored milk 0 to 2. Movement locked, reaction dispatched, movement unlocked, and chest completion was logged. The failing part is text selection: story index -1 indicates fallback rather than a selected configured entry.

The installed ForcedMilkMaidConversion.json matches repository bytes and contains five nonblank strings in each of the ordinary top-level arrays chestCurseStories and conversionMessages. houseCARL confirms the active VortexToMO2/Default winner is MME Extensions; Overwrite is not winning this file. JsonUtil PEX and PapyrusUtil.dll both win from PapyrusUtil AE SE - Scripting Utility Functions. This is not evidence of a missing or old JSON installation.

### Confirmed reader/schema mismatch

MMEMilkCurse.ShowStory calls JsonUtil.StringListCount/StringListGet. The canonical file uses an ordinary JSON array at .chestCurseStories. PapyrusUtil's typed list API instead delegates through List<BSFixedString>() = stringList and lowercases the list key, then reads root[type][key]. A plain top-level array is therefore invisible to this API. Its zero count exactly explains the -1 fallback.

Primary source evidence:

- https://github.com/eeveelo/PapyrusUtil/blob/master/External.h (List<BSFixedString> maps to stringList)
- https://github.com/eeveelo/PapyrusUtil/blob/master/External.cpp (ListCount/ListGet read the typed root member)
- https://github.com/eeveelo/PapyrusUtil/blob/master/JsonUtil.cpp (StringListCount dispatch)

Installed JsonUtil.psc explicitly documents ordinary JSON paths and declares PathCount, IsPathArray, IsPathString and GetPathStringValue. These are already used by the working narration JSON subsystem. Offline schema reproduction under ignored build/diagnostics/story-reader-preflight reports ordinary count 5 versus typed count 0 for both pools. This is a static reproduction against verified upstream semantics, not a live VM call; SkyLink currently reports disconnected and Skyrim.Net MCP tools are absent.

### Adjacent issue in the same configuration

MMEMilkCurse.Feedback and MMENewMilkMaid.PublishForcedConversionFeedback also use the typed reader for the ordinary conversionMessages array. They can silently select the fixed fallback notification instead of the five configured notifications. Fix these callers with the story reader so both pools behave consistently. Do not convert player JSON into typed storage or create duplicate maintained copies.

The generic MMEStoryPopup.ShowRandomStoryPopup also uses typed list APIs. Its callers/configuration deserve a separate compatibility audit; do not silently change every unrelated armor/story route as part of this focused fix. A new narrow helper can be hosted there without changing existing public behavior, or kept in a separate dependency-neutral text utility if that is clearer.

## Proposed implementation

1. Add a small shared read-only pool adapter and use it in the three affected readers. For canonical top-level arrays, validate IsPathArray(file, "." + pool), obtain PathCount and retrieve the selected string via GetPathStringValue(file, "." + pool + "[index]"). Verify types and nonblank text; preserve the existing {actor} rendering and one-story rule.
2. Support legacy typed stringList configuration only when the canonical ordinary member is absent. Canonical content wins when both exist. An explicitly empty, wrong-type or malformed canonical member must not silently select an older hidden pool. Preserve existing schema keys and user text. Do not add an API capability/release version just for this reader correction.
3. Keep normal reads free of JSON setters, Save, auto-migration and destructive cache reloads. JsonUtil loads files lazily. The wrong API explains this failure without a cache-reset workaround. A fresh game session is the acceptance baseline; any explicit reload must not save cached data over player edits (Unload defaults saveChanges=true, so use false if a reload path is added). Do not expand the current narration reload button's scope implicitly.
4. Validate missing file, parse failure, absent/empty pool, non-string/blank entries and selected-index bounds. Use a safe fallback and deduplicated/rate-limited alarms for genuine bad configuration. Story-disabled and NPC-popup skip remain expected outcomes. Keep NPCs free of blocking story boxes.
5. Add sparse master-only footprints: file, pool, ordinary/legacy source, usable count, selected index and fallback reason, plus actor/source where available. No routine diagnostic HUD notifications or full story text in logs. Valid shipped configuration must report count 5 and index 0–4; -1 should be accompanied by a concrete fallback reason.
6. Preserve all curse/chest chances, one-shot markers, milk amounts/overflow, registration/Lactacid, animation duration, movement ownership/recovery, narration speaker selection and public API signatures. This is a text-read correction, not a gameplay retest by rerolling an already resolved chest.

## Regression / build plan

- Test the actual shipped JSON shape against the adapter's semantics; previous tests confirmed JSON contents but did not establish that StringListCount could read them. Include an explicit negative fixture proving the old typed accessor sees zero for the canonical file.
- Canonical five stories and five notifications; edited text and a custom pool length; legacy-only typed pool; both shapes present; empty/missing/wrong-type canonical pool; malformed JSON; blank/non-string entries; Unicode/quotes/braces in actor names. Ensure selected entries come from the configured pool, without requiring every random draw to be unique.
- Player forced conversion, player surge and NPC routes; stories on/off; notifications on/off; narration on/off; exactly one player story and no NPC popup; no old opening/closing pair; notification pool correctly varies.
- Compile every affected PSC and regenerate the MMENewMilkMaid OStim-only variant. Run curse, canonical-story, narration, existing conversion and no-SexLab dependency checks. Inspect final matching source/PEX and untouched player-editable JSON schema in MME Extensions.zip. Keep diagnostics out of the archive.
- Live acceptance after user installation: use a fresh unresolved chest or separately authorized controlled API test, confirm configured count 5/index 0–4, supplied story text, exact milk delta and cleanup. Restore any test settings. No installation or live state mutation is authorized by this preflight.

## Crash assessment

The user confirmed the 19:20 exit was a quit/Alt+F4. Papyrus recorded freezing/frozen and Log closed at 19:20:52–53, after curse cleanup at 19:20:29–30. The crash report at 19:20:53 is a genuine native access violation, but the context is shutdown, not proof of a curse gameplay CTD.

All seven newest crash reports share SkyrimSE.exe+0199FC3, read address 0x1F8, with an actor/skeleton and ParentCell None. Several predate the curse work. The latest stack contains engine frames at the failure; the presence of MMEExtensions, Magelight or SkyrimNet in the loaded-module list does not attribute the crash to them. SkyrimNet also emits shutdown-time events, but that alone is not causal evidence.

Do not include speculative DLL, skeleton, animation, load-order, FNIS/Nemesis or exit fixes in the story patch. A separate authorized investigation could compare clean Quit to Desktop versus Alt+F4 and no-curse versus curse sessions with the same save, collecting Papyrus and crash reports. Only then isolate native modules if necessary. Preserve the current modlist during this preflight.

## Decision

Ready to implement the focused pool-reader correction with master-gated diagnostics. Root cause is established by schema, caller code, primary implementation and observed fallback. Live VM verification remains necessary after installation. The recurring exit crash is a separate issue without an established responsible module; it does not block the text fix and must not be represented as solved by it.
