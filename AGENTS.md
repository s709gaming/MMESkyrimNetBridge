# Repository Instructions

## Workflow

- **Workspace:** MME Extensions; `E:\SkyrimModDev\MMESkyrimNetBridge`, branch `main`.
- **Concurrency:** Multiple agents may work on main.
  - Claim active work in local `TASK.md` before editing to prevent overlap.
- **Boundaries:** Edit `AGENTS.md` and `README.md` only when requested.

## Preflight Meaning

- **Context:** Research and plan enough to implement safely; scale depth to the change.
- **Implementation Decisions:**
  - **Master Papyrus Footprints — Yes/NA:** Identify gated traces for new code/fixes.
  - **Smoke Alarms — Yes/NA:** Identify genuine failures needing ungated, deduplicated alarms.
  - **New Script — Yes/NA:** Name the exact file and responsibility, or existing owner.

## MME Safety

- **Original Source:** Inspect original/installed MME before MilkQuest changes.
  - Verify signatures, property types and array syntax.
- **Actors:** Verify lookup and bounds before parallel-array access; never assume conventional or stable indices.
  - Prevent wrong targets, stale/unsynchronized arrays and accidental conversion.
- **Preserve:** Keep existing MME behavior unless explicitly changed.
  - Maid slots, levels and capacity.
  - Conversion, milking and inventory behavior.
  - Reuse MME functions/calculations.

## General Mod Techniques

- **Everything Optional:** Integrations remain optional unless designated required; absence must not break unrelated features.
  - Skyrim.Net, SexLab/P+, OStim and DD.
  - Elsie LaVache, JUGS and supported armor mods.
- **Overrides:** Use only when necessary; isolate by target/FOMOD option.
- **Ownership:** Prefer focused scripts and reusable APIs.

## Diagnostics

- **Footprints:** Gate new/changed gameplay traces behind master Papyrus logging; use consistent subsystem prefixes.
  - Cover entry, actor and eligibility.
  - Cover result, cleanup and useful skips.
- **Volume:** Polling traces only on state changes or verbose/deep logging. No routine diagnostic notifications.
- **Alarms:** Log genuine failures, broken prerequisites and impossible states regardless of master logging.
  - Include subsystem, operation, actor if relevant and reason.
  - Deduplicate/rate-limit.
- **Skips:** Expected skips and missing optional integrations are not alarms.

## Verification

- **Checks:** Compile affected scripts, rebuild the package, and report passed, failed and untested checks.

## Environment & Tools

- **MO2:** `E:\Mod Organizer 2\ModOrganizer.exe`
- **Instance/Profile:** `C:\Users\Donald\AppData\Local\ModOrganizer\VortexToMO2` / `Default`.
- **Game:** `E:\Steam\steamapps\common\Skyrim Special Edition`
- **Confirm:** Read `ModOrganizer.ini` before trusting paths.
  - Launch SKSE/tools through the correct instance.
  - Verify mod/file priorities and plugin activation separately; physical Data is insufficient.
- **Layers:** Distinguish source from outputs and runtime files.
  - Packages, installed mods, VFS and overwrite.
  - Unmanaged game files and Vortex staging.
  - Keep root SKSE loader/runtime/scripts matched.
- **Static Data:** houseCARL for records, scripts, assets and conflicts.
- **Runtime:**
  - Skyrim.Net MCP for prompts/narration.
  - SkyLink AI MCP for engine/Papyrus.
- **Management/Visuals:**
  - MO2 Agent Control supported commands.
  - Computer use/screenshots for game/MCM.
