# Repository Instructions

## Environment & Tools

- **Workspace:** MME Extensions; `E:\SkyrimModDev\MMESkyrimNetBridge`, branch `main`.
- **MO2:** `E:\Mod Organizer 2\ModOrganizer.exe`
- **Instance/Profile:** `C:\Users\Donald\AppData\Local\ModOrganizer\VortexToMO2` / `Default`.
- **Game:** `E:\Steam\steamapps\common\Skyrim Special Edition`
- **MCP Tools:**
  - **houseCARL:** Records, scripts, assets and conflicts.
  - **Skyrim.Net:** Prompts and narration.
  - **SkyLink AI:** Engine and Papyrus.
  - **MO2 Agent Control:** Mod Organizer management.
- **In-game Tools:** Computer use/screenshots for game and MCM; Gameplayer for controls.
  - Use keyboard navigation for dialogue menus; confirmed workaround for unreliable mouse clicks.

## General

- **Concurrency:** Multiple agents may work on main.
  - Claim active work in local `TASK.md` before editing.
  - Review recent commits and local changes affecting the task.
- **Boundaries:** Edit `AGENTS.md` and `README.md` only when requested.
- **Changelog:** A separate changelog agent handles drafts and updates.

## MME Compatibility

- **Context:** Built on original MME. Read its implementation before changing dependent behavior.
- **Original Source:** Inspect original/installed MME before MilkQuest changes.
  - Verify signatures, property types and array syntax.
- **Actors:** Verify actor lookup and bounds before parallel-array access.
  - Never assume conventional or stable indices.
  - Prevent wrong targets, stale/unsynchronized arrays and accidental conversion.
- **Preserve:** Keep existing MME behavior unless explicitly changed.
  - Preserve maid slots, levels, capacity, conversion, milking and inventory behavior.
  - Reuse MME functions and calculations.

## General Mod Techniques

- **Optional Integrations:** Keep integrations optional unless designated required.
  - Absence must not break unrelated features.
  - Skyrim.Net, SexLab/P+, OStim, DD, Elsie LaVache, JUGS and supported armor mods.
- **Overrides:** Use only when necessary; isolate by target/FOMOD option.
- **Ownership:** Prefer focused scripts and reusable APIs.
- **Metadata and Comments:** Maintain existing authoring context and Magelight descriptions.
  - **Context:** Metadata helps humans and AI understand notifications and narrations.
  - **Reference:** Follow [narration-presentation.json](tools/narration-presentation.json).
  - **Type:** Distinguish notifications, narration prompts, stories, lore and actor context.
  - **Description:** Explain what the player edits and what the text should convey.

## Diagnostics

- **Traces:** Gate new/changed gameplay traces behind master Papyrus logging.
  - Use consistent subsystem prefixes.
  - Cover entry, actor, eligibility, result, cleanup and useful skips.
- **Alarms:** Log genuine failures, broken prerequisites and impossible states regardless of master logging.
  - Include subsystem, operation, relevant actor and reason.
  - Deduplicate or rate-limit.

---

# Workflow

## Plan

- **Define:** Specify the feature or bug fix and expected behavior.
- **Feasibility:** Check compatibility, risks and likely failure points.

## Preflight

- **Research:** Inspect affected code, dependencies and original MME behavior.
- **Regression Controls:** Identify before implementation:
  - **Traces:** Gated diagnostics needed for new code or fixes.
  - **Alarms:** Genuine failures needing ungated, deduplicated logging.
  - **Script Ownership:** Existing owner, or exact new filename and responsibility.
  - **Not Applicable:** Mark controls that do not apply as **NA**.

## Implementation

- **Changes:** Implement the agreed scope using the compatibility and diagnostics rules above.

## Verification

- **Checks:** Compile affected scripts and rebuild the package.
- **Results:** Record passed, failed and untested checks.

## Install in MO2

- **When:** After every implementation, once verification passes.
- **Install:** Use a separate test mod.
  - Verify the correct instance/profile, enabled state and file priority.

## Commit

- **Style:** Follow [structured shorthand](docs/structured-shorthand-markdown.md).
  - Summarize the main change and purpose.
  - Omit minor implementation details.

## Post-installation Report

- **Summary:** Concisely describe what was implemented.
- **Verification:** Report passed, failed and untested checks.
- **Status:** State whether commit and installation succeeded.

## In-game Testing

- **When:** Only when full testing or gameplay testing is requested.
- **Time Limit:** Stop gameplay testing at 20 minutes.
  - Report incomplete checks.
- **Coverage:** Run the smallest test covering changed behavior and likely regressions.
- **Data:** Gather necessary runtime data through MCP.
- **Cleanup:** Close the game if launched for testing.
- **Logs:** Review relevant logs for errors and unexpected behavior.

## Post-test Report

- **Coverage:** State what was tested and for how long.
- **Results:** Report in-game results and relevant MME Papyrus errors.
- **Status:** Pass, Fail or Needs attention.
