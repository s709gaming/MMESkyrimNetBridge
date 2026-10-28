# Optional dashboard arousal preflight

Status: ready for implementation; no gameplay or installed-file changes made. The approved mock preview is build/previews/milk-maid-arousal-preview.html. Baseline roster suite: 5 tests passed.

## Approved presentation

- Keep the compact Milk Capacity column, white proportional bar, amount/capacity above-right, percentage left.
- Add a milk-glass glyph beside Milk Capacity, matching the pink heart beside Arousal. Keep readable labels and accessible names; decorative glyphs aria-hidden.
- Add a separate muted-pink Arousal column. Show numeric percentage and a matching bar; its position should align with the milk bar, allowing for the milk amount line above it.
- Hide the entire column and its header when no supported reader is available. Reflow milk space without a blank gap. With a reader present but one actor value unknown, show N/A and an empty neutral track, never a fabricated zero.
- Preserve all action buttons, disabled explanations, snapshot tokens, hotkey and focus cleanup. Refresh milk and arousal together on open/Refresh, without polling. Retain narrow-window scrolling and test long names/tooltips.

## Verified integration and scope

Existing Source/Scripts/MMEArousalBridge.psc supplies IsAvailable() and Int GetCurrentArousal(Actor actorRef). IsAvailable currently checks SexLabAroused.esm. The getter returns -1 for unavailable/unreadable state, prefers the supported compatibility quest's GetActorArousal, then falls back to the compatibility faction rank, and caps valid values at 100.

Installed OSL Aroused FOMOD 2.9.3 source confirms int GetActorArousal(Actor akRef), rejecting None/child actors and forwarding to OSLAroused_ModInterface.GetArousal(akRef). Use the existing bridge, not faction-only duplication, exposure updates or a new arousal calculation. No SexLab.esm requirement is implied by the compatibility master's name.

The roster currently emits only milk, capacity, percent and action eligibility. This change needs a small optional roster PSC edit plus HTML, tests and compiled output. No public API version bump, MCM key, plugin master, new settings migration or gameplay behavior change is required. Keep the arousal effect/animation MCM toggles separate: they control effects, not whether an installed framework's value can be viewed.

Do not add SLA/OSL types to the roster. Add a build-only MMEArousalBridge signature stub to the roster SDK, matching the real facade; never ship that stub. Verify the built PEX has no direct SLA/OSL or SexLab framework type dependency. Keep existing compatibility dependencies isolated in the established bridge.

## Data plan

1. At each refresh, resolve support once: bridge availability plus a resolving compatibility reader quest or fallback faction. Plugin presence alone is not proof that all scripts/native services are healthy; partial installs can still yield N/A. Do not call an arousal reader at all when the framework is absent.
2. Add top-level numeric arousalAvailable (0/1), avoiding Papyrus boolean string interning. Add per-row arousal as a JSON number for a valid 0-100 result, or null for a negative/unreadable result. Frontend defaults missing fields to no column for older payloads.
3. Read once per eligible adult roster actor during the existing bounded, deduplicated scan. Skip dead/deleted/unavailable actors as appropriate and render N/A. Treat unloaded actors as framework-stored values, not a promise of real-time simulation. No waits, extra scans, inventory changes, arousal writes or additional timers.
4. Preserve request generation/view checks before publishing. Add the optional column in a single setRoster update, so headings and rows never disagree after refresh/load.

## Papyrus footprints and smoke alarms

Use existing master-gated [MME Maid Roster UI] Trace. Add refresh-boundary support status and readable/unreadable counts. Emit framework state transitions or one concise refresh summary, not a separate log on every actor or hover. Existing action entry/actor/eligibility/result/cleanup logs remain untouched.

Missing optional arousal, untracked actors and N/A are expected states, not smoke alarms. Keep existing genuine page serialization/callback failures and prerequisite alarms deduplicated. A display refresh must not trigger arousal reactions, animations or exposure updates.

## Regression and acceptance

- Dependency absent: no reader calls, no empty arousal column, milk/actions fully usable.
- Dependency present: player and NPC values, zero/half/full arousal, negative sentinel -> N/A, malformed/null/frontend missing fields, out-of-range presentation safely bounded.
- Compare displayed player/NPC numbers with the framework reader; do not equate exposure or faction rank with authoritative arousal where the direct API works.
- Check partial install/reader forms missing, stored unloaded actor values, empty roster and repeated open/Refresh. Re-evaluate support after load rather than persisting it in a save.
- Verify milk proportional values and overflow unchanged, milk/heart glyphs, narrow layout and long names, icon labels, keyboard/disabled tooltips, Escape/hotkey close, duplicate-click and stale token guards.
- Check Extensions/roster disabled, combat/busy self-milk guards and unchanged Drink/Give/Self dispatch. No gameplay changes should be introduced by reading the dashboard.
- Compile affected roster PSC, verify PSC/PEX hashes and optional manifest. Run roster JS/isolation/array tests and new support/read-only serialization contracts. Inspect compiled dependency names and build-only stub exclusion.
- Package MME Extensions.zip retaining the body-description fix and latest roster layout. Verify source/PEX/HTML/manifest parity, optional FOMOD placement, archive integrity and MO2/Vortex XML checks. No version numbering, README edit or installation.
- Live smoke test after user installation: support present and absent, player/NPC values, master logging on/off, no VM errors or repeat noise. Source tests cannot prove Magelight glyph appearance or native reader readiness.

## Concerns

Supported scope is the existing SLA/OSL compatibility boundary, not arbitrary arousal frameworks. Native getter behavior varies by fork; reuse the existing API and treat unsupported/unreadable state explicitly. Verify that no reader initializes gameplay state or triggers events before integrating it. The UI remains snapshot-based. Milk glass rendering has already been visually demonstrated; heart and new layout still need live acceptance.

Verdict: small, bounded UI/data addition with existing API reuse. No blocking concern found for the installed OSL path. Do not broaden this into arousal gameplay or continuous live polling.

## Implementation completed, 2026-10-28

Optional roster source/PEX and page now emit/read numeric arousalAvailable plus numeric-or-null row arousal. Support is re-evaluated once per refresh with plugin/facade and quest/faction checks; absent support never calls the actor getter. Dead/disabled actors produce unknown values. The existing bridge remains unchanged. A build-only signature stub isolates roster compilation from framework types and is excluded from the distributable.

Milk-glass/heart headings, cream/pink bars, unknown values, backward-compatible payload defaults and whole-column removal are implemented. Existing actions, session tokens, focus/hotkey and master logging gates remain unchanged. One refresh summary includes support and known/unknown counts. No new MCM settings, public API version, plugin masters, gameplay mutations or polling.

Both roster scripts compiled with zero errors/warnings. Six roster tests pass, including actual page tests for presence/absence transitions, zero/half/full/invalid values, old payloads and existing action contracts. Compiled output has no direct SLA/OSL/SexLab framework type dependency; the stub is absent from the optional component. Source/PEX/HTML/plugin manifest hashes match. Generic archive rebuilt retaining prior body-description fix and current layout; archive integrity and normal/Vortex XML checks verified. Installed files untouched. Real player/NPC arousal comparisons, Magelight glyph/layout/focus and logging-on/off smoke tests remain pending user installation.

### Follow-up: MCM entry and row divider

Corrected RosterUiAvailable to compare GetModByName against the absent sentinel 255, rather than rejecting every index >=255. SKSE returns lightIndex+256 for active light plugins, which made the ESL-flagged roster's MCM Open row disabled while its own hotkey continued working. Existing master/feature/host gates and queued MCM-close handoff remain unchanged. MMEAlertsMCM compiled with zero errors/warnings; matching source/PEX are packaged.

Kept the Action td as a table cell and moved display:flex to an inner div, preserving the shared row border baseline. Page tests verify the wrapper and unchanged action callbacks/duplicate-click guards, including arousal present/absent. Existing master-gated MCM request and roster cleanup footprints are unchanged. Six roster tests and archive/XML checks pass; live MCM selection/close handoff and visual divider alignment remain acceptance checks after reinstall. No installed files changed.
