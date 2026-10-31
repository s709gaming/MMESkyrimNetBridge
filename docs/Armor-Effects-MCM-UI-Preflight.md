# Armor Effects MCM presentation preflight

October 30, 2026. Planning only; no implementation or deployment authorized by this document.

## Verified findings

Inspected the desktop screenshot open in Paint and current repository MMEAlertsMCM.psc. The Armor Effects page is built in OnPageReset, currently at lines 2548–2593, using TOP_TO_BOTTOM fill and SetCursorPosition(1) for the right column. The bundled SkyUI SDK exposes that cursor API. This supports rearranging the existing controls without another editor, native UI, or plugin record changes.

Both armor families already expose enable, interval, variation, effect chance, notification visibility, notification sound, narration enable, player narration, narration chance, diagnostics, and an immediate production check. Living/Parasite's notification and narration controls are already on this page, below its eight intensity/duration sliders. They are not missing or located on another page. The differing insertion order explains the screenshot's uneven layout.

The four tier labels currently come from MMETentacleTiers.Name, which also serves machine-facing tier names. Change display capitalization locally in the MCM; do not change the helper's names or JSON identifiers.

## Proposed page

Keep the existing Armor Effects page and existing independent settings. Align the upper columns as follows:

| Row | Left | Right |
| --- | --- | --- |
| 1 | Living / Parasite Armor heading | Dwemer Armor heading |
| 2 | Enable Effects | Enable Effects |
| 3 | Base Effect Interval | Base Effect Interval |
| 4 | Interval Variation (+/-) | Interval Variation (+/-) |
| 5 | Effect Chance | Effect Chance |
| 6 | Notifications heading | Notifications heading |
| 7 | Show Effect Notifications | Show Effect Notifications |
| 8 | Notification Sound | Notification Sound |
| 9 | Skyrim.Net Narration heading | Skyrim.Net Narration heading |
| 10 | Enable Narration | Enable Narration |
| 11 | Enable Player Narration | Enable Player Narration |
| 12 | Narration Chance | Narration Chance |

Below that aligned block, use both columns for the Living/Parasite-only settings:

| Left heading: Living / Parasite Intensity | Right heading: Living / Parasite Animation |
| --- | --- |
| Low Chance | Low Duration |
| Medium Chance | Medium Duration |
| High Chance | High Duration |
| Extreme Chance | Extreme Duration |

Finish with aligned Living / Parasite Diagnostics and Dwemer Diagnostics sections, each retaining its existing diagnostic toggle and a consistently labeled Run Effect Check Now action. Keep these actions on this page to avoid touching another page's layout or making existing troubleshooting harder to find. Tooltips must identify that these run the real production route.

Use concise labels to fit the existing two-column SkyUI layout. Confirm headings fit visually; shorten to Living / Parasite Chances and Living / Parasite Durations if needed. Common labels are unambiguous because each column has a family heading. Tooltips retain injection semantics and explain that the lower tier block applies only to Living/Parasite. Do not add inactive Dwemer tier controls or new toggles for visual symmetry.

## Implementation boundaries

1. Rearrange only the Armor Effects construction block in Source/Scripts/MMEAlertsMCM.psc; explicitly anchor section starts with existing cursor APIs so both columns remain aligned. Preserve each option variable assignment.
2. Apply local display labels Low, Medium, High, Extreme; keep chance/duration option arrays indexed exactly as before. Align visible wording and relevant existing help text where needed.
3. Preserve every settings key, default, slider range/step, event handler, schedule refresh call, option reset, saved MCM property, and gameplay function. No migration is required because persisted settings are unchanged. Option IDs are rebuilt on page reset and must remain bound to their proper variables.
4. Leave scheduling, MilkQUEST, animations, JSON pools/editor, native DLLs, dependencies, other MCM pages, and README unchanged. No new gameplay traces or alarms are needed for rearranging controls.
5. Compile MMEAlertsMCM.psc and ship its matching source/PEX through the existing package pipeline. It is a common source, rather than an OStim-only generated MCM variant; verify the same updated MCM is included for standard and OStim-only choices. Rebuild dist/MME Extensions.zip and inspect contents. Do not deploy, commit, or alter installed mods without explicit instruction.

## Risks and validation

- Inspect the full page at ordinary and enlarged UI scales: heading/label clipping, row alignment, scroll reachability, and the boundary between shared settings and Living/Parasite tiers. The page will still scroll; the goal is predictable grouping, not promising all controls fit on one screen.
- Verify every pre-existing option appears exactly once and retains its original option variable and settings key. Confirm all four chance controls and all four duration controls remain reachable and correctly paired.
- Compile the affected script; run existing tier/MCM contracts and package checks relevant to the rearrangement. Do not add tests that merely reproduce the new row order.
- On a separately authorized runtime test, reopen MCM on an existing save and confirm previous values persist. Exercise both families' toggles/sliders independently, balanced chances, duration edits, page switching, close/reopen, and save/load. Restore test values afterward.
- Check tooltips and each run-check action's routing. Those actions mutate gameplay and should only be activated during an authorized test. Confirm logs contain no new MCM errors, stale option references, or accidental scheduling changes simply from opening the page.

Acceptance: both families' common controls align; all existing features remain available; the tier section clearly belongs to Living/Parasite; settings and runtime behavior are preserved. Implementation, packaging, and in-game visual acceptance remain pending.

## Implementation record

Implemented the proposed source layout after user approval. Both twelve-row common sections now align, followed by paired Living/Parasite Chances and Durations sections, then aligned family diagnostics. Display tier names use a local capitalized array; machine-facing names are unchanged. Existing option bindings, setting expressions, defaults, handlers, and slider behavior were retained. Updated the existing Dwemer contract's heading expectation to its new display label. Build and package verification are recorded in the task result; installed visual acceptance remains pending separately authorized deployment. No installed files or README were changed.
