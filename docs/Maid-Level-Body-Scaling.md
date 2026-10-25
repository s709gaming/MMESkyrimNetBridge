# Milk Maid level body morphs

Body MCM includes Level-Based Body Scaling, disabled by default for new and existing saves. The maximum scaling Maid level ranges from 10 to 100 and defaults to 100. Each morph slider selects a 0?100% contribution at that level. Progress is clamped to level / maximum; level zero contributes zero and levels above the maximum remain capped. This does not alter the real MME level, capacity, conversion, or breast calculations.

The curated morphs are Hips, Butt, Thighs, CalfSize, Waist, Belly, BigBelly, ChubbyArms, ChubbyLegs, and ChubbyWaist. Breasts are intentionally excluded. These are morph slider strengths, not physical dimensions. RaceMenu and matching body/outfit TRI morphs are needed to display changes. The existing actor-weight feature remains independent.

MMEMaidBodyScaling.psc owns settings, actor selection, progression, ownership, reconciliation, cleanup, and logging. The controller supplies lifecycle and MME event boundaries; the MCM supplies controls. The native bridge dynamically resolves RaceMenu's NiOverride functions, with no NiOverride Papyrus compile dependency or additional ESP master. Curse of Life, SLIF, and Prisma UI are not required.

Settings are stored in the existing /MMEAlerts/Settings JSON under enableMaidBodyScaling, maidBodyScalingMaxLevel, and maidBodyMorph<name>. MCM changes increment maidBodyScalingRevision and immediately reconcile player, nearby NPC Milk Maids, and previously managed actors. External JSON changes should be made with the game closed and loaded on the next session.

Only the RaceMenu key MMEExtensions.MaidLevel is cleared/replaced. Disabling body scaling or the Extensions master removes this contribution without clearing other keys. Stored morphs are also cleared for managed unloaded NPCs; their visible models update when loaded. Level changes, settings changes, creation, completed milking/production, venue/lifecycle events, and save load reconcile changes without a new polling loop.

Native operations execute in callback order: clear owned key, verify key absence, set each selected value and read it back, refresh model, send completion. Success requires finite stored values matching within 0.0001, or confirmed key absence for cleanup. This confirms stored morph data, not visible body/outfit compatibility. Papyrus does not wait in a latent stack. Per-actor ownership is recorded before dispatch; failed requests retain ownership for cleanup. Tokens reject stale completions, session changes discard pre-load native work, and save-load recovery resets interrupted requests. Missing optional RaceMenu is a gated skip, not an alarm.

Incoming morph names are matched case-insensitively against the curated list, including names whose spelling was changed by Papyrus string interning. Duplicate names, breast/unknown names, non-finite or out-of-range values, and invalid array shapes are rejected before clearing the owned key.

Routine footprints use [MME Extensions Maid Body] through the existing master Papyrus logging toggle. Calculations, actor eligibility, normalization mappings, request tokens, verified readbacks, stale completions, load recovery, and cleanup are recorded at request boundaries. Rejection and readback failure alarms carry the concrete reason. Failure alarms identify the actor, operation, and reason and deduplicate until a successful request or the next game session.

## Validation still requiring the game

Check player and NPC appearance independently, repeat updates without growth accumulation, change the cap, disable both feature and master, save/load during a request, and compare other mods' morph keys before/after cleanup. Test missing RaceMenu and missing outfit/body morph support. Observe Papyrus logs for wrong actors, stale requests, errors, and repeated noise. Build-time compilation and bytecode checks do not establish visual compatibility.

## Build-time regression checks

`tools/test_maid_morph_validation.cpp` compiles against the same validation header as the DLL. It exercises all 4,768 capitalization variants of the curated names, the observed lowercase hips/waist regression, exact canonical mappings, invalid/breast names, duplicate aliases, non-finite/out-of-range values, array lengths, full requests, and empty cleanup. Compile with MSVC C++20 (or newer), with outputs under build/diagnostics.

`tools/test_maid_body_scaling.py` exercises disassembled Papyrus progression bytecode and checks its native boundary for invalid array casts. The existing complete package build compiles the affected scripts and runs the project's regression checks.
