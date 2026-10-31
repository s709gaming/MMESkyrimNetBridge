# Narration dashboard live smoke test — October 30, 2026

Tested the installed build in the running Skyrim SE game, MO2 VortexToMO2 / Default, in Pinemoon Cave. This is a limited live smoke test, not full runtime acceptance.

## Passed

- houseCARL confirmed the active instance/profile and MME Extensions as the winning provider of the dashboard page, JavaScript, roster PEX, and native DLL. A physical Data DLL also exists but loses to the enabled mod.
- Installed dashboard JavaScript SHA256 matches repository source: `F37A863B7516CB47761C29B576B14ED70C365AA060D91805CE38E2DE172B23B9`.
- Numpad minus opens the roster; Narration & Lore loads 131 entries.
- Search updates results and finds `Lore.milk_lore` by stable ID. Opening its card loads the existing personal template.
- A temporary ` QA_TEST_1030` marker produces one unsaved entry and enables Save Changes.
- Save commits the marker to the actual personal JSON. Disk comparison confirms removing only that marker exactly reproduces the original template.
- Reload Saved, followed by reopening the card, displays the saved marker with zero unsaved entries.
- Restoring the original template through the editor and saving restores the entire active JSON exactly, including formatting and line breaks. Original/restored template length: 343 characters; document size: 469 bytes.
- Escape closes the dashboard; Papyrus records cleanup for Close/Escape and UI mode exit. The hotkey reopens the editor with zero unsaved changes.
- Observed editor log boundaries report successful entry, saveBatch, catalog, presets, and response delivery. The original revision returns after restoration: `36fe9601881980ae25ce71dbdd08e4bbe6a94587c663adb0e5c83974a756b06b`.

## Automation observations

Ordinary absolute cursor positioning/clicks did not operate the embedded UI reliably and sometimes caused foreground activation failures. Relative `mouse_delta` followed by mouse_down/mouse_up worked. Background Tab and text input worked for tab selection and search. Modifier chords needed a short delay after modifier-down and before modifier-up. Long injected text required short chunks and explicit Enter presses for line breaks. These are control-path observations, not established dashboard defects.

Keyboard traversal unexpectedly reached a preset export validation message while the preset section appeared collapsed. Investigate normal keyboard accessibility separately; this run does not establish the cause.

## Data and scope

The active personal override was restored exactly. Normal saves rotated `overrides.previous.json`, so that backup can contain the temporary test revision. Both original active and previous files were copied into `build/diagnostics/json-dashboard-qa/` before the first save. No installed mod, MO2 profile, game-root file, or retained Vortex file was edited; no game save was requested. The game remains running with the editor open.

Still outstanding: committed Reset behavior, a second field and atomic multi-entry save, validation/size limits, Unicode, presets/import/export, external revision conflicts and failed writes, new/old-save and game-restart persistence, actual player/NPC prompt injection, representative pool readers, optional-dependency absence, and the master/verbose logging matrix. No claim of complete log health or stable shutdown follows from these successful editor transactions.

## Follow-up: inventory drinking and an actual AI response

At the user's request, edited `MilkDrinking.narrate_player_milk_drink_1` through the live dashboard to: "The player just drank {milkName} from inventory. Have one nearby character make a short, friendly joke about a milk moustache."

- Existing settings already enabled player drink narration with 100% chance and a 60-second cooldown; these settings were not changed.
- Saved at 13:40:39, revision `67982ee855c66c9f995f9513f00914c5aca2295ef429c6d60fefe1f78621d7da`.
- Consumed an actual Jug of Milk from inventory at 13:41:48. The existing ordinary-milk conversion chance was 100%, so the first jug converted the player to a Milk Maid. The log correctly suppressed ordinary drink narration because conversion owned the reaction.
- After the conversion sequence finished, consumed a second jug at 13:43:16. Papyrus resolved the changed entry with `source=personal`, substituted the real item name, and recorded `Player drink DirectNarration result 0` with the exact test instruction.
- SkyrimNet.log at 13:43:17 records Master Vampire's generated response: "You've left a bit of a white moustache on your lip, little Nord. How quaint." It also records dialogue commit and subsequent context containing that response. This proves live personal text reached the AI and influenced an actual response, without restarting Skyrim or reloading Skyrim.Net content.
- Used Reset this entry and Save Changes at 13:45:17. The entire active personal JSON exactly matches the pre-test baseline; the original revision returned. This also passes committed per-entry Reset for a newly added override.

Live consequences remain in the running session: two Jugs of Milk consumed (three to one), player converted to a Milk Maid, and ordinary fullness/arousal/armor-strip routes ran. No save or rollback was requested. Skyrim.Net conversation history contains the test reaction; restoring the template does not erase it. Backup rotation can retain the temporary override in the previous file.

### Reopen issue observed

After closing and reopening while the Narration & Lore tab remains selected, a new draft could be edited but Save stayed disabled. No save request was issued. The page's session-change handler sets `state.uncertain` when a revision is already present; revision reconciliation normally runs on tab activation. Reload Saved cleared the condition, and the same valid draft then enabled Save and committed successfully. This is an observed UI issue with a source-supported explanation, not a fixed defect. No implementation or deployment was changed during this test.
