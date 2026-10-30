# Editable narration implementation

Player-editable AI wording lives in `SKSE/Plugins/StorageUtilData/MMEAlerts/Narration/`:
12 feature files, 72 routes, `EditingGuide.txt`, and generated `RouteReference.txt`.
The three `.prompt` files retain their structural conditions and consume JSON-backed
text. Action YAML stays separate. Existing shared HUD/story/thought pools and
runtime settings retain their original locations; narration can embed their rendered
text through documented placeholders.

The general `Lore.milk_lore` entry additionally supports the optional in-game
[editor proof](Narration-Editor-Proof.md). Its personal override is stored outside
installed mods and takes precedence over this base JSON. Other routes retain the
loader described below. The final runtime uses cached native text, refreshed by
a worker; drafts never enter JsonUtil's game-save writeback path.

`MMENarrationText` owns read-only loading, schema checks, complete-pool validation,
single-pass placeholder rendering, reload, and the explicit legacy import action.
`MMENarrationDefaults` is generated from the shipped JSON by
`tools/generate_narration_defaults.py`; it is not a second authored prose source.
Missing fields/files use compiled defaults. Invalid supplied data raises a
file-deduplicated smoke alarm; routine traces follow master Papyrus logging.
Reload validates every expected route without rolling random selection. Normal
reads and reload never call JSON setters/save. No new polling, waits, actor scans,
gameplay writes, plugin masters, or optional framework types were introduced.

MCM > Troubleshoot > Narration JSON provides Reload and Import Legacy Narration.
The internal SkyUI schema increases to 159 so existing saves refresh correctly;
this is not a release version. Controller initialization also reloads the files.
Import recognizes 20 old text fields, leaves old files untouched, skips edited
new destinations, saves explicitly, and verifies readback. Skyrim's case-insensitive
string interning means case-only edits cannot reliably be distinguished from
unchanged defaults: back up presets and import before customizing them. This
limitation does not affect the normal read-only path.

Actor selection, feature/master switches, chances, callbacks, transport arguments,
result-code conventions and cooldown writes remain in their existing routes.
Default strings are covered by pre-extraction SHA-256 fixtures and legacy-data
comparisons; all 72 routes are covered. The original 15 DirectNarration sites,
six private-generation sites, five TTS sites, event calls and callback arguments
are compared against the captured baseline. Two text decorators are added.
Generated OStim-only sources use the common data helper and retain the isolated
backend replacement.

Validation entry points:

- `python tools/generate_narration_defaults.py`
- `python -B tools/test_narration_json.py`
- `tools/Test-TentacleNarrationContracts.ps1`
- `tools/Test-DwemerEffectsContracts.ps1`
- `tools/Test-DwemerArmorContracts.ps1`
- `tools/Test-MilkCravingContracts.ps1`
- `build-package.ps1` (includes narration generation/tests and all existing suites)

The editor guide includes JSON examples, token rules, restore instructions,
backup/preset guidance, import caveats and native duplicate-key limitations.
The FOMOD's existing required SKSE/source/script folders install the common reader,
defaults, and complete Narration folder for every animation backend.

Runtime acceptance remains necessary after installing the rebuilt package:
edit/reload one NPC narration and one private player line; verify both new lore/
breastfeeding decorators render in actual Skyrim.Net prompts; test malformed,
missing and invalid-token presets and inspect deduplicated alarms; import a backed-up
legacy preset twice with customized destination conflicts; check reload after a
save/load and Skyrim.Net absent/master disabled. Compilation and source contract
checks cannot substitute for these in-game checks. No deployment is part of this
repository implementation.

Validation completed for this implementation: all existing build contract suites,
six narration regression tests, the full standard build, 24 isolated OStim-only
variants and the 65-script effective no-SexLab bytecode inventory passed. Final
recompilation of all five affected common scripts reported zero errors/warnings.
Archive inspection verified 12 JSON files/72 routes, guide/reference, all five
current source/PEX pairs, all 24 variant manifest pairs, current prompt adapters,
and no diagnostic/log/cache artifacts. The dialogue-check utility emitted existing
nullable-reference compiler warnings but all dialogue checks passed. Detailed logs
and package hashes are under ignored `build/diagnostics/narration-*`.
