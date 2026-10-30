# General Milk Maid lore editor proof

Historical first-stage implementation. The [full dashboard](Narration-Dashboard-Implementation.md)
now expands this store and UI to the remaining catalog; its general-lore personal
files remain compatible. The limits and behaviors below describe the proof stage.

This proof edits only `Lore.milk_lore`, the general milk/milking-armor text
injected by the existing Milk Maid character-bio prompt. The prompt's conditions,
actor-specific `milkmaid_lore`, gameplay, and all other narration are preserved.

Open the optional Milk Maid roster and select **Narration & Lore**. The single
field accepts nonblank plain text, up to 8192 UTF-8 bytes. It has no placeholders;
braces/control characters are rejected. Save Changes writes a personal override
and activates it for subsequent prompts. Reload Saved reads disk explicitly.
Use Default Lore deletes only this override, preserving other document entries.

The exact personal file path is shown in the editor. It is beneath the runtime's
SKSE user directory at `MMEExtensions/Narration/profiles/default/overrides.json`,
outside the installed mod. Subsequent saves retain `overrides.previous.json`.
No personal file is supplied in the installer. It is shared across saves and MO2
profiles using that user root. Loading an old save does not roll it back. Existing
conversation context is not erased by changing future prompt text.

Save uses native UTF-8 JSON validation, exact revisions over personal data and
base text, an exclusive file lock shared across processes, flushed temporary
files, precommit validation, replacement, and committed readback. Unknown entries
and metadata survive saves. Future schemas and corrupt active files are refused,
not rewritten. Restore the previous backup manually if an active file is corrupt;
automatic recovery/import/export UI is outside this proof.

JS/native requests and responses are lowercase hexadecimal UTF-8 before crossing
Papyrus, including JSON values, so case-only edits and Unicode are preserved on
disk and in the editor. The final Skyrim.Net decorator still returns a Papyrus
string. Exact casing in actual prompts needs runtime verification; persistence
tests do not prove the VM's final presentation behavior.

The existing script-owned Magelight host and roster callbacks remain in place.
Each request checks generation, view, focus, readiness, and enabled state; stale
responses are dropped. The editor prevents duplicate requests and protects drafts
against normal tab/roster refreshes and failed saves. Drafts are page memory only:
forced close, hibernation/reload, and exit can lose them. Save before leaving.
This proof queues bounded file work on a native worker and returns completion
through a one-shot game-task ModEvent. The gameplay getter reads only the published
snapshot and never waits on the transaction's disk lock. There is no new polling
or latent stack. Native epochs reject callbacks from earlier game loads. The roster
requests unpaused UI mode, as before. Paused host behavior
and long filesystem stalls remain explicit runtime acceptance cases.

Routine footprints use `MMELog.MasterDiagnostic` with `[MME Narration Editor]`:
request entry, selected operation/request ID, success/validation/conflict result,
response delivery, stale skip/cleanup, and cache reload. Master logging off
suppresses these without requiring verbose mode. Genuine failures use the existing
deduplicated alarm path, keyed by failure reason rather than changing request IDs.
No full lore text is logged and no routine player notifications are added.

Build/validation entry points:

- `build-native.ps1` generates the native fallback from authored Lore.json, then builds the universal DLL.
- `tools/Test-NarrationEditor.ps1` builds/runs the isolated native persistence tests and actual-page JS tests.
- `tools/Build-MaidRosterUI.ps1` compiles the optional scripts and updates their manifest.
- `build-package.ps1` compiles common and OStim-only scripts, runs existing/new checks, and builds `dist/MME Extensions.zip`.

The JSON dependency is nlohmann/json, pinned by the existing vcpkg baseline;
its license is included under docs/licenses. No HTTP service/dependency is added.
The transport/store interfaces and sparse stable entry IDs allow later expansion
without replacing the personal-file model.

Before runtime acceptance, install a matching DLL/common PEX/UI PEX/page revision
through a separately authorized deployment. Test player/NPC lore injection and
Skyrim.Net absent, host absent, disabled toggles, repeated save/reset/reopen,
Unicode/case-only edits, old-save load, game restart, personal file permissions,
external edit conflict, host focus/typing/Escape, and master logging off/on.
Verify the personal file survives replacing the installed mod. Do not treat a
clean compile or browser mock as a successful in-game save test.
