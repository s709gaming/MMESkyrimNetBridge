# Repository instructions

- Do not modify `README.md`.
- Treat `README.md` as read-only unless the user explicitly requests changes to it.
- Preserve unrelated user changes in the worktree.
- Do not commit, publish, deploy to Skyrim, or modify installed MO2 mods, profiles, game-root files, or the retained Vortex installation unless the user explicitly requests it.
- Keep temporary diagnostics, test artifacts, and failed builds out of release packages.
- Name generated archives `MME Extensions.zip`. Leave release version numbers and versioned filenames to the user unless explicitly requested.

## Papyrus diagnostics

- New or substantially changed gameplay routes must include useful Papyrus trace footprints.
- Gate routine diagnostic traces behind the existing master Papyrus logging toggle.
- Use a consistent trace prefix that identifies the script or subsystem.
- At useful boundaries, trace entry, selected actor, eligibility result, action result, cleanup, and the reason for an important skip.
- Avoid high-volume traces inside polling loops unless state changes or a dedicated verbose/deep logging option is enabled.
- Do not expose routine diagnostic details as player-facing notifications.

## Smoke alarms

- Add smoke alarms for genuine failures, broken prerequisites, invalid state, or conditions that should be impossible.
- A smoke alarm should identify the subsystem, attempted operation, affected actor when applicable, and concrete failure reason.
- Rate-limit or deduplicate failures that could otherwise repeat.
- Expected outcomes such as a disabled feature, active cooldown, unavailable eligible target, optional dependency being absent, or an actor already being a Milk Maid are not smoke alarms. Record them only as gated traces when useful.

## Milk Mod Economy and MilkQuest

- Before modifying an interaction with `MilkQuest`, inspect the installed/original MME source and verify the exact function signature, property type, and array syntax. Do not guess from memory.
- Treat MME actor arrays and parallel arrays as framework-specific structures. Do not assume conventional indexing, generic array behavior, or that an actor's index is stable without verifying the original implementation.
- Verify actor lookup and bounds before every relevant parallel-array access.
- Preserve MME's Milk Maid slot, Milk Maid level, milk-capacity, conversion, milking, and inventory semantics unless the user explicitly requests a behavior change.
- Prefer MME's established functions and calculations over independent reimplementations.
- Test player and NPC routes independently.
- Specifically watch for wrong-actor targeting, stale or invalid indices, unsynchronized arrays, accidental Milk Maid conversion, and silent calls against the wrong actor.

## Optional dependencies

- Skyrim.Net, SexLab, SexLab P+, OStim, Devious Devices, Elsie LaVache, JUGS, and supported armor mods remain optional unless the user explicitly designates one as a hard requirement.
- Resolve optional plugins, forms, quests, and scripts dynamically and fail safely when they are unavailable.
- Do not accidentally introduce a compile-time script dependency or plugin master dependency on an optional mod.
- Test both dependency-present and dependency-absent behavior when changing an integration.
- Keep compatibility overrides isolated and clearly attributable to their target mod or FOMOD option.

## Papyrus and build discipline

- Compile every affected `.psc` file. Do not ship source-only gameplay changes.
- Confirm shipped `.psc` and `.pex` files represent the same revision.
- Treat overrides of original MME or third-party scripts as invasive. Use them only when necessary and document the reason in the appropriate compatibility changelog.
- Prefer isolated extension scripts and facade APIs when they can preserve behavior without duplicating a framework.
- Preserve save compatibility and existing MCM property names unless a migration is intentionally implemented.
- New MCM settings need safe defaults plus initialization and upgrade handling for existing saves.
- Rebuild the distributable after implementation and inspect the final mod-manager archive structure and contents for MO2 and retained Vortex compatibility.
- Generated packages, installed MO2 files, and retained Vortex files are outputs, not the source of truth. Make source changes in the repository.

## Regression testing

For each gameplay change, check all applicable cases:

1. Enabled success path.
2. Disabled MCM behavior.
3. Player target path.
4. NPC target path.
5. Repeated use and cleanup.
6. Cooldowns, delays, chance rolls, and random variation.
7. Combat, busy-animation, scene, and movement-lock guards.
8. Optional dependency present and absent.
9. Existing-save initialization or upgrade behavior.
10. Papyrus logs for errors, stack dumps, repeated noise, stale state, and wrong-actor selection.

## Environment

- The user now manages Skyrim through Mod Organizer 2 (MO2), migrated from Vortex using Mod Manager Migrator. Vortex staging is retained for rollback; do not redeploy or modify it without explicit authorization.
- Last verified MO2 executable: `E:\Mod Organizer 2\ModOrganizer.exe`.
- Last verified active instance: `C:\Users\Donald\AppData\Local\ModOrganizer\VortexToMO2`, profile `Default`. Read `ModOrganizer.ini` to confirm the current instance, profile, mods, profiles, and overwrite paths before relying on them. Preserve the separate older `Skyrim Special Edition` MO2 instance.
- Last verified game root: `E:\Steam\steamapps\common\Skyrim Special Edition`. Retained Vortex staging: `E:\Vortex Mods\skyrimse`.
- Launch SKSE and modding tools through the correct MO2 instance so they see its virtual filesystem. Absence from the physical game Data folder does not prove a mod file is missing.
- Verify both left-pane mod activation/file priorities and right-pane plugin activation/load order. A DLL can load from an enabled mod even when its required ESP is disabled. Script-only mods have no right-pane plugin.
- Do not edit MO2 profile/configuration files externally while MO2 is open; it can overwrite those changes. Use the UI or close MO2 before authorized file edits, back up the affected files, and verify persistence after reopening.
- Root-level SKSE files are separate from MO2's virtual Data files. Keep the runtime DLL, loader, and Papyrus scripts matched; do not assume a migration or Vortex purge preserves them. Do not regenerate FNIS/Nemesis outputs or sort plugins merely to complete a migration.
- Repository source, generated packages, installed MO2 mod folders, the effective MO2 virtual filesystem, overwrite outputs, retained Vortex staging, and physical game-root/Data files are distinct layers. State clearly which layer was inspected or changed; inspect overwrite and unmanaged files when diagnosing conflicting assets.

## Available Skyrim MCP tools

This project may use three complementary MCP servers. Confirm that a server's tools are present in the current Codex session before relying on it. A configured server is not necessarily loaded into an already-running chat.

### houseCARL

Use houseCARL primarily for static Skyrim data-layer work:

- Inspect plugins, records, scripts, assets, conflicts, and the load order.
- Inspect or author ESP/ESL records and dialogue.
- Compile or decompile Papyrus when supported.
- Inspect SKSE plugins and deployed asset winners.
- Verify exact forms, properties, and record relationships instead of guessing.

Use the verified active MO2 instance/profile for static winner inspection. Confirm houseCARL points to `VortexToMO2` before trusting its results; a configured older instance is not evidence of what the current game loads. Read-only inspection does not authorize patch creation, profile changes, or installation. Live runtime queries remain the authority for what the running game actually loaded.

### Skyrim.Net MCP

Skyrim.Net MCP is normally available only while Skyrim and Skyrim.Net are running and the MCP connection was loaded when the Codex session started.

Use it for live runtime and Skyrim.Net-specific work:

- Loaded plugins, quests, actors, player state, and quest script properties.
- Skyrim.Net actions, prompts, triggers, narration, validation, and configuration.
- Runtime confirmation of what Skyrim.Net currently sees.

At the beginning of a Skyrim.Net investigation:

1. Confirm tools from the `skyrimnet` MCP server are present.
2. List several of its tools.
3. Run one harmless read-only query.
4. Use read-only calls by default.
5. Do not execute console commands or mutate live game state unless the user's task authorizes that test.

### SkyLink AI MCP

SkyLink AI is a separate general Skyrim runtime MCP and may not yet be installed or connected. Verify availability before relying on it.

When available, use it for:

- Live actor, inventory, equipment, quest, cell, combat, and menu state.
- Papyrus function discovery and carefully scoped VM calls.
- Runtime event observation.
- General engine inspection that Skyrim.Net MCP does not expose.

Use read-only SkyLink tools by default. It exposes powerful mutation tools; do not alter quests, inventory, actors, saves, weather, position, or other live game state unless the user's request authorizes that operation.

### Tool selection

- Static records, assets, plugins, and conflicts: houseCARL.
- Skyrim.Net actions, narration, prompts, and live Skyrim.Net state: Skyrim.Net MCP.
- General live engine state and Papyrus runtime inspection: SkyLink AI MCP.
- Source files describe intended behavior; live MCP queries establish what is loaded and happening in the current game.
- If a tool is missing from the current session, report that clearly instead of implying it was queried.
- These MCP servers do not inherently provide a literal visual image of SkyUI's MCM. Visual MCM inspection requires a connected computer-use surface or user-provided screenshots.
