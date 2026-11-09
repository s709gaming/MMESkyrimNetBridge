# Repository Instructions

## Scope & Workflow

**Context:** Develop MME Extensions in one working directory.

**Workspace:** `E:\SkyrimModDev\MMESkyrimNetBridge`, branch `main`.
**Concurrency:** Multiple chats may investigate; one session implements, builds or controls testing.
**Worktrees:** Additional branches/worktrees only when requested.
**User Work:** Preserve unrelated changes.
**README:** Do not modify `README.md` unless explicitly requested.
**AGENTS.md:** Do not modify `AGENTS.md` without explicit user approval.
**Status:** Maintain local `TASK.md`; exclude from release packages.

**Authorization:** Implement within the user’s requested scope. Commits, publishing, deployment, installed MO2/profile/game-root changes and retained Vortex changes require explicit authorization. Live-state changes require an authorized test.
**Instructions:** Do not add, remove or materially reinterpret permanent repository rules without explicit approval.
**Communication:** Brief findings, plans and reports; distinguish verified results from assumptions.

## Preflight

**Context:** Investigate and prepare as needed before implementation; scale depth to the change.

**Investigation:** Review affected code, callers and related systems. Consult original MME/third-party sources, reference material and documentation as relevant. Verify APIs, assumptions, dependencies and compatibility boundaries.
**Plan:** Identify ownership, implementation approach, risks and applicable regression checks.
**Required Decisions:**

- **Master Papyrus Footprints — Yes/No:** Identify useful gated traces.
- **Smoke Alarms — Yes/No:** Identify genuine failures needing ungated, deduplicated alarms.
- **New Script — Yes/No:** Explain; name exact filename/responsibility or existing owner.

**Report:** Concise findings, unresolved questions, recommended plan and readiness.
**Boundary:** Preflight alone does not authorize implementation or builds. Do not add approval checkpoints for routine choices already authorized.

## MME & Integration Safety

**Context:** Preserve framework behavior and existing saves.

**Original Source:** Before changing MilkQuest interactions, inspect original/installed MME source. Verify exact signatures, property types and array syntax.
**Actor Arrays:** Framework-specific; never assume conventional indexing or stable actor indices. Verify actor lookup and bounds before relevant parallel-array access.
**Preserve:** Milk Maid slots, levels, capacity, conversion, milking and inventory semantics unless explicitly changed.
**Reuse:** Prefer established MME functions/calculations over independent implementations.
**Watch For:** Wrong actors, stale indices, unsynchronized arrays, accidental conversion and silent wrong-target calls.

**Optional Dependencies:** Skyrim.Net, SexLab/P+, OStim, Devious Devices, Elsie LaVache, JUGS and supported armor mods remain optional unless explicitly designated required. Absence must not break unrelated features.
**Compatibility:** Keep overrides isolated and attributable to their target mod/FOMOD option. Use original/third-party script overrides only when necessary; document why in the compatibility changelog.
**Organization:** Use focused owner scripts and reusable APIs where useful. Helper scripts are routine choices within authorized scope; avoid unnecessary layers. Native code needs concrete justification.
**Save Safety:** Preserve MCM property names unless intentionally migrated. New settings need safe defaults and existing-save initialization/upgrade handling.

## Diagnostics

**Context:** Make failures traceable without routine player-facing noise.

**Footprints:** New/substantially changed gameplay routes require useful traces behind existing master Papyrus logging. Use consistent subsystem prefixes.
**Boundaries:** Trace entry, selected actor, eligibility, action result, cleanup and important skips where useful.
**Volume:** Polling traces only on state changes or dedicated verbose/deep logging. No routine diagnostic notifications.

**Smoke Alarms:** Genuine failures, broken prerequisites or invalid/impossible state; independent of master logging. Include subsystem, operation, actor where applicable and concrete reason. Deduplicate/rate-limit.
**Expected Skips:** Disabled features, cooldowns, no eligible target, absent optional dependencies and existing Milk Maids are not alarms.

## Build & Verification

**Context:** Repository source is authoritative; packages and installed files are outputs.

**Compile:** Every affected `.psc`; never ship source-only gameplay changes. Shipped `.psc`/`.pex` must represent the same revision.
**Package:** Rebuild after implementation. Verify FOMOD source references, final archive contents and MO2/Vortex-compatible structure. Exclude temporary diagnostics, tests and failed builds.
**Naming:** Generate `MME Extensions.zip`; release numbers/versioned filenames remain user-controlled unless delegated.

**Regression:** Check applicable enabled/disabled behavior, player/NPC routes, repeated use/cleanup, timing/chance, combat/animation/scene/movement guards, dependencies present/absent and existing-save upgrades.
**Logs:** Check errors, stack dumps, repeated noise, stale state and wrong actors.
**Report:** State checks passed, failures and untested cases. Compilation/package checks do not establish live acceptance.

## Environment & Tools

**Context:** MO2 is active; retained Vortex staging is protected rollback material.

**Last Verified Paths:**

- MO2: `E:\Mod Organizer 2\ModOrganizer.exe`
- Instance: `C:\Users\Donald\AppData\Local\ModOrganizer\VortexToMO2`
- Profile: `Default`
- Game: `E:\Steam\steamapps\common\Skyrim Special Edition`
- Retained Vortex: `E:\Vortex Mods\skyrimse`

**Confirm:** Read `ModOrganizer.ini` before relying on current instance/profile/mods/overwrite paths. Preserve the separate older MO2 instance.
**VFS:** Launch SKSE/tools through the correct MO2 instance. Verify left-pane activation/file priorities and right-pane plugin activation independently; physical Data alone is insufficient.
**Live Profiles:** Do not externally edit MO2 configuration while open. For authorized changes, use supported controls/UI or close MO2; back up and verify persistence.
**SKSE:** Root files are separate from virtual Data; keep loader, runtime DLL and scripts matched.
**Layers:** Distinguish source, packages, installed mods, VFS, overwrite, unmanaged game files and retained Vortex staging.
**Generated Outputs:** Do not sort plugins or regenerate FNIS/Nemesis merely to complete migration.

**Tool Selection:**

- Static records, scripts, assets and conflicts → houseCARL.
- Skyrim.Net runtime, prompts and narration → Skyrim.Net MCP.
- General engine/Papyrus runtime → SkyLink AI MCP.
- MO2 management → MO2 Agent Control; prefer supported commands.
- Visual game/MCM inspection → computer use or screenshots.

**Tool Verification:** Confirm session availability and correct instance before relying on results. For Skyrim.Net investigations, identify available tools and run a harmless read query first.
**Runtime Boundary:** Environment/runtime inspection is read-only by default. Source describes intent; live queries establish loaded behavior. Report unavailable tools honestly.
